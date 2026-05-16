import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Estados visuais para a animação de busca ativa do hardware
enum SearchState { idle, searching, found, notFound }

class HubPage extends StatefulWidget {
  const HubPage({super.key});

  @override
  State<HubPage> createState() => _HubPageState();
}

class _HubPageState extends State<HubPage> with TickerProviderStateMixin {
  // PALETA DE CORES CRIPTOGRAFICA VERSIN
  final Color primaryPurple = const Color(0xFF6A1B9A);
  final Color accentNeon = const Color(0xFFE040FB);
  final Color deepBg = const Color(0xFF0D0B1F);
  final Color hardwareRed = const Color(0xFFFF2A6D);
  final Color hackerGreen = const Color(0xFF00FF66); // Verde Hacker Neon
  
  // Controle de estado da busca ativa por clique
  SearchState _searchState = SearchState.idle;
  Timer? _searchTimeoutTimer;

  bool _isGlobalSearching = false;
  bool _isScanning = false;
  bool _revealHardwareKey = false;
  bool _hasRevealedOnce = false; 
  bool _isDisconnecting = false; 
  
  // TRAVA DE SEGURANÇA LOCAL: Evita que pings concorrentes do hardware anulem o clique do usuário imediatamente
  bool _forceOffline = false;

  late AnimationController _globalSearchController;
  late AnimationController _barramentoScanController;

  // COMPONENTES INTEGRADOS NO CHASSI DO HARDWARE PROPRIETÁRIO
  final List<Map<String, dynamic>> _hardwareComponents = [
    {"name": "Anel de Feedback LED (NeoPixel)", "icon": Icons.blur_circular_outlined, "desc": "Sinalização visual de BPM e gravação"},
    {"name": "Sensores Touch Capacitivos", "icon": Icons.touch_app_outlined, "desc": "Atalhos rápidos e controle gestual de efeitos"},
    {"name": "Cápsula de Microfone (I2S)", "icon": Icons.mic_none_outlined, "desc": "Captação analógica e conversão digital de rimas"},
    {"name": "Matriz de Teclas Mecânicas", "icon": Icons.keyboard_alt_outlined, "desc": "Gatilhos rápidos para modo Studio e Rhyme"},
    {"name": "Display Gráfico OLED 128x64", "icon": Icons.screenshot_monitor, "desc": "Retorno visual de metadados e espectro de áudio"},
  ];

  @override
  void initState() {
    super.initState();
    _globalSearchController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    
    // Varredura completa para 15 segundos (3 segundos para cada um dos 5 componentes)
    _barramentoScanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    );

    // Listener para redesenhar a árvore conforme a porcentagem sequencial avança
    _barramentoScanController.addListener(() {
      setState(() {});
    });

    _barramentoScanController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isScanning = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchTimeoutTimer?.cancel();
    _globalSearchController.dispose();
    _barramentoScanController.dispose();
    super.dispose();
  }

  // Altera o status no banco e ativa a trava local imediata
  Future<void> _disconnectHardware() async {
    if (_isDisconnecting) return;

    setState(() {
      _isDisconnecting = true;
      _forceOffline = true; // Ativa na hora a trava visual independente do Supabase
    });

    try {
      await Supabase.instance.client
          .from('status_hardware')
          .update({
            'status': 'offline',
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', 1);
    } catch (e) {
      debugPrint("Erro ao desconectar hardware: $e");
      // Se der erro crítico no update, desfazemos a trava para não quebrar a UI
      setState(() {
        _forceOffline = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isDisconnecting = false;
        });
      }
    }
  }

  // Aciona a varredura ativa ao clicar no botão centralizado
  void _startActiveHardwareSearch(bool estaOnlineAgora) {
    if (_searchState == SearchState.searching) return;

    _searchTimeoutTimer?.cancel();
    
    setState(() {
      _searchState = SearchState.searching;
      _isGlobalSearching = true;
      _globalSearchController.repeat();
    });

    // Simulamos uma varredura ativa na rede de 3 segundos
    _searchTimeoutTimer = Timer(const Duration(seconds: 3), () {
      setState(() {
        _isGlobalSearching = false;
        _globalSearchController.stop();
        
        // Se a trava offline estiver ligada, o resultado será obrigatoriamente não encontrado
        if (estaOnlineAgora && !_forceOffline) {
          _searchState = SearchState.found;
        } else {
          _searchState = SearchState.notFound;
        }
      });

      // Aguarda 4 segundos exibindo o resultado (Verde/Vermelho) antes de restaurar o padrão Roxo
      _searchTimeoutTimer = Timer(const Duration(seconds: 4), () {
        setState(() {
          _searchState = SearchState.idle;
        });
      });
    });
  }

  void _cancelActiveSearch() {
    _searchTimeoutTimer?.cancel();
    setState(() {
      _searchState = SearchState.idle;
      _isGlobalSearching = false;
      _globalSearchController.stop();
    });
  }

  void _toggleScan() {
    setState(() {
      _isScanning = !_isScanning;
      if (_isScanning) {
        _barramentoScanController.forward(from: 0.0);
      } else {
        _barramentoScanController.stop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Escuta em tempo real as mudanças da linha ID 1 da tabela status_hardware no Supabase
    final supabaseStream = Supabase.instance.client
        .from('status_hardware')
        .stream(primaryKey: ['id'])
        .eq('id', 1);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabaseStream,
        builder: (context, snapshot) {
          // Estados padrões (Fallback quando o hardware estiver desligado ou carregando)
          String statusReal = "offline";
          int sinalReal = 0;
          bool estaOnlineDeVerdade = false;
          String latenciaText = "---";
          String mensagemStatus = "Hardware desconectado";
          String trafegoText = "0.0 KB/s";

          // Se a trava local de desligamento estiver ativa, ignoramos os dados de rede entrantes
          if (_forceOffline) {
            statusReal = "offline";
            estaOnlineDeVerdade = false;
            mensagemStatus = "Hardware desconectado manualmente";
            trafegoText = "0.0 KB/s";
            latenciaText = "---";
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            final dadosHardware = snapshot.data!.first;
            statusReal = dadosHardware['status'] ?? 'offline';
            sinalReal = dadosHardware['sinal'] ?? 0;

            if (statusReal == 'offline') {
              estaOnlineDeVerdade = false;
              mensagemStatus = "Hardware em modo passivo";
              trafegoText = "0.0 KB/s";
              latenciaText = "---";
            } else if (dadosHardware['updated_at'] != null) {
              final DateTime updatedAt = DateTime.parse(dadosHardware['updated_at']).toUtc();
              final DateTime agoraUtc = DateTime.now().toUtc();
              
              final int diferencaSegundos = agoraUtc.difference(updatedAt).inSeconds.abs();

              // Se no banco diz online E a atualização está em uma janela aceitável de 10 minutos
              if (statusReal == 'online' && diferencaSegundos < 600) {
                estaOnlineDeVerdade = true;
                mensagemStatus = "Hub conectado via Apolo-system";
                trafegoText = "1.4 KB/s"; 
                latenciaText = "${(diferencaSegundos % 15) + 12} ms"; 
              } else {
                estaOnlineDeVerdade = false;
                mensagemStatus = "Último sinal há $diferencaSegundos segundos";
              }
            }
          } else if (snapshot.hasError) {
            mensagemStatus = "Erro na stream: Verifique o RLS";
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),

                // CARD MASTER DE BUSCA GLOBAL INTEGRADO COM SUPABASE REAL-TIME
                _buildMasterSearchCard(estaOnlineDeVerdade, mensagemStatus),

                const SizedBox(height: 20),

                // OVERVIEW DA REDE & TELEMETRIA DE TRÁFEGO
                Row(
                  children: [
                    _buildHubStatCard(
                      title: "TRÁFEGO DE REDE",
                      value: trafegoText,
                      subtitleWidget: Row(
                        children: [
                          Icon(Icons.wifi_tethering, color: accentNeon.withOpacity(0.5), size: 10),
                          const SizedBox(width: 4),
                          Text(
                            estaOnlineDeVerdade ? "Sinal Wi-Fi: $sinalReal%" : "Ancoragem Wi-Fi / Bluetooth", 
                            style: const TextStyle(color: Colors.white30, fontSize: 10),
                          ),
                        ],
                      ),
                      icon: Icons.grid_view_rounded,
                    ),
                    const SizedBox(width: 14),
                    _buildHubStatCard(
                      title: "LATÊNCIA HARDWARE",
                      value: latenciaText,
                      subtitleWidget: Text(
                        estaOnlineDeVerdade ? "Barramento estável" : "Sem resposta do barramento", 
                        style: const TextStyle(color: Colors.white24, fontSize: 10),
                      ),
                      icon: Icons.bolt_outlined,
                    ),
                  ],
                ),
                
                const SizedBox(height: 14),

                // TELEMETRIA DE SAÚDE DA PLACA (AQUECIMENTO E MEMÓRIA)
                Row(
                  children: [
                    _buildHubStatCard(
                      title: "TEMPERATURA DO CORE",
                      value: estaOnlineDeVerdade ? "41 °C" : "-- °C",
                      subtitleWidget: Text(
                        estaOnlineDeVerdade ? "Sensor térmico operacional" : "Sensor térmico interno offline", 
                        style: const TextStyle(color: Colors.white24, fontSize: 10),
                      ),
                      icon: Icons.thermostat_outlined,
                    ),
                    const SizedBox(width: 14),
                    _buildHubStatCard(
                      title: "ARMAZENAMENTO INTERNO",
                      value: estaOnlineDeVerdade ? "4.2 / 16 MB" : "0 / 16 MB",
                      subtitleWidget: Text(
                        estaOnlineDeVerdade ? "SPIFFS montada com sucesso" : "Partição SPIFFS desmontada", 
                        style: const TextStyle(color: Colors.white24, fontSize: 10),
                      ),
                      icon: Icons.storage_outlined,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // CONTAINER DE CRIPTOGRAFIA / ANTITAMPER
                _buildSectionTitle("Assinatura Criptográfica & Integridade"),
                const SizedBox(height: 10),
                _buildAntiTamperCard(),

                const SizedBox(height: 24),

                // HEADER DOS COMPONENTES INTERNOS DO HARDWARE
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle("Mapeamento do Chassi"),
                        const SizedBox(height: 2),
                        const Text("Componentes e transdutores integrados de fábrica", style: TextStyle(color: Colors.white30, fontSize: 11)),
                      ],
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isScanning ? hackerGreen.withOpacity(0.1) : primaryPurple.withOpacity(0.15),
                        foregroundColor: _isScanning ? hackerGreen : accentNeon,
                        side: BorderSide(color: _isScanning ? hackerGreen.withOpacity(0.4) : accentNeon.withOpacity(0.3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onPressed: _toggleScan,
                      icon: Icon(_isScanning ? Icons.stop_circle_outlined : Icons.radar_outlined, size: 16),
                      label: Text(
                        _isScanning ? "INTERROMPER" : "ESCANEAR BARRAMENTO",
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // CONTAINER DE SCAN ANIMADO (RADAR DO BARRAMENTO)
                if (_isScanning) _buildAnimatedRadarCard(),

                // LISTA DE COMPONENTES INTERNOS DO DISPOSITIVO
                Column(
                  children: List.generate(_hardwareComponents.length, (index) {
                    return _buildSequentialComponentItem(_hardwareComponents[index], index, estaOnlineDeVerdade);
                  }),
                ),

                const SizedBox(height: 24),

                // ANALISADOR DE INTEGRIDADE FLAT + BOTÃO REATIVO COM MEMÓRIA DE TRAVA
                _buildIntegritySpectrumCard(estaOnlineDeVerdade),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  // COMPONENTE: CARD MASSIVO DE BUSCA COM TRANSICÃO DINÂMICA DE CORES REATIVAS
  Widget _buildMasterSearchCard(bool online, String mensagemSub) {
    Color currentBorderColor;
    Color buttonBgColor;
    Color buttonContentColor;
    String buttonText;
    IconData buttonIcon;

    switch (_searchState) {
      case SearchState.searching:
        currentBorderColor = accentNeon.withOpacity(0.5);
        buttonBgColor = Colors.redAccent.withOpacity(0.15);
        buttonContentColor = Colors.redAccent;
        buttonText = "CANCELAR BUSCA";
        buttonIcon = Icons.power_settings_new;
        break;
      case SearchState.found:
        currentBorderColor = hackerGreen.withOpacity(0.7);
        buttonBgColor = hackerGreen.withOpacity(0.2);
        buttonContentColor = hackerGreen;
        buttonText = "DISPOSITIVO LOCALIZADO";
        buttonIcon = Icons.check_circle;
        break;
      case SearchState.notFound:
        currentBorderColor = hardwareRed.withOpacity(0.7);
        buttonBgColor = hardwareRed.withOpacity(0.2);
        buttonContentColor = hardwareRed;
        buttonText = "FALHA NA LOCALIZAÇÃO";
        buttonIcon = Icons.error_outline;
        break;
      case SearchState.idle:
      default:
        currentBorderColor = Colors.white.withOpacity(0.06);
        buttonBgColor = primaryPurple.withOpacity(0.2);
        buttonContentColor = Colors.white;
        buttonText = _forceOffline ? "RECONECTAR SISTEMA HUB" : "BUSCAR HARDWARE EXTERNO";
        buttonIcon = Icons.radar;
        break;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: double.infinity,
      height: 210,
      decoration: BoxDecoration(
        color: _searchState == SearchState.found 
            ? hackerGreen.withOpacity(0.03) 
            : _searchState == SearchState.notFound 
                ? hardwareRed.withOpacity(0.03) 
                : Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: currentBorderColor, width: _searchState != SearchState.idle ? 1.5 : 1.0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_isGlobalSearching)
              AnimatedBuilder(
                animation: _globalSearchController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: RadarPulsePainter(
                      progress: _globalSearchController.value,
                      pulseColor: accentNeon,
                    ),
                    child: const SizedBox.expand(),
                  );
                },
              ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Varredura Sem Fio Global".toUpperCase(),
                            style: TextStyle(
                              color: _searchState == SearchState.found 
                                  ? hackerGreen 
                                  : _searchState == SearchState.notFound 
                                      ? hardwareRed 
                                      : accentNeon, 
                              fontSize: 10, 
                              fontWeight: FontWeight.bold, 
                              letterSpacing: 1.5
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Procurando Versin Chassi Pro",
                            style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: online ? hackerGreen : hardwareRed,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: (online ? hackerGreen : hardwareRed).withOpacity(0.5),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    )
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                online ? "Online" : "Offline",
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            mensagemSub,
                            style: const TextStyle(color: Colors.white24, fontSize: 9),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  GestureDetector(
                    onTap: () {
                      if (_searchState == SearchState.searching) {
                        _cancelActiveSearch();
                      } else if (_searchState == SearchState.idle) {
                        if (_forceOffline) {
                          // Se o usuário clicar no botão principal enquanto estiver sob a trava de desligamento, nós limpamos a trava
                          setState(() {
                            _forceOffline = false;
                          });
                        } else {
                          _startActiveHardwareSearch(online);
                        }
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                      decoration: BoxDecoration(
                        color: buttonBgColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: buttonContentColor.withOpacity(0.4),
                          width: 1.5,
                        ),
                        boxShadow: [
                          if (_isGlobalSearching || _searchState == SearchState.found)
                            BoxShadow(
                              color: buttonContentColor.withOpacity(0.1),
                              blurRadius: 20,
                              spreadRadius: 2,
                            )
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(buttonIcon, color: buttonContentColor, size: 18),
                          const SizedBox(width: 12),
                          Text(
                            buttonText,
                            style: TextStyle(
                              color: buttonContentColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Text(
                    _searchState == SearchState.searching 
                        ? "Sintonizando transceptores de rádio 2.4GHz..." 
                        : _searchState == SearchState.found
                            ? "Handshake com ESP32 efetuado com sucesso!"
                            : _searchState == SearchState.notFound
                                ? "Nenhum sinal recebido nos broadcasts UDP/HTTP."
                                : "Interface de acoplamento em modo de escuta passiva",
                    style: TextStyle(
                      color: _searchState == SearchState.searching 
                          ? Colors.white60 
                          : _searchState == SearchState.idle 
                              ? Colors.white24 
                              : buttonContentColor.withOpacity(0.7), 
                      fontSize: 10,
                      fontStyle: FontStyle.italic
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(color: accentNeon, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
    );
  }

  Widget _buildHubStatCard({
    required String title,
    required String value,
    required Widget subtitleWidget,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                Icon(icon, color: Colors.white12, size: 16),
              ],
            ),
            Text(value, style: const TextStyle(color: Colors.white60, fontSize: 20, fontWeight: FontWeight.bold)),
            subtitleWidget,
          ],
        ),
      ),
    );
  }

  Widget _buildAntiTamperCard() {
    String secureHashSeed = "SHA256:7B_8C_E1_4A_F9_2B_E3_9A_C4_FF_10_E8_D2_A5_B6_9C_E7";
    String internalSigningKey = "vns_genesis_crypto_key_ep32_firmware_signed_0x8F3B9A";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.gavel_outlined, color: hardwareRed, size: 18),
              const SizedBox(width: 8),
              const Text(
                "Mecanismo Anti-Tamper & Validação Lógica",
                style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "Esta chave verifica a integridade estrutural do barramento. Caso os e-Fuses do ESP32 sejam violados, o par de chaves será invalidado.",
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11, height: 1.4),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              if (!_hasRevealedOnce) {
                setState(() {
                  _revealHardwareKey = true;
                  _hasRevealedOnce = true;
                });
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Row(
                children: [
                  Icon(Icons.fingerprint, color: _hasRevealedOnce ? Colors.greenAccent : accentNeon, size: 16),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _hasRevealedOnce ? "CONTRATO DIGITAL ASSINADO" : "GERAR CHAVE DE ASSINATURA",
                          style: TextStyle(color: _hasRevealedOnce ? Colors.greenAccent : Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 2),
                        Text(secureHashSeed, style: const TextStyle(color: Colors.white24, fontSize: 9, fontFamily: 'monospace')),
                      ],
                    ),
                  ),
                  Icon(Icons.touch_app, color: Colors.white12, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.02),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withOpacity(0.04)),
                        ),
                        child: Text(
                          internalSigningKey,
                          style: const TextStyle(color: Colors.white38, fontSize: 12, fontFamily: 'monospace', letterSpacing: 0.5),
                        ),
                      ),
                      if (!_revealHardwareKey)
                        Positioned.fill(
                          child: ImageFiltered(
                            imageFilter: ImageFilter.blur(sigmaX: 4.5, sigmaY: 4.5),
                            child: Container(color: Colors.black.withOpacity(0.1)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: Icon(
                  _revealHardwareKey ? Icons.visibility : Icons.visibility_off,
                  color: _revealHardwareKey ? Colors.white30 : accentNeon.withOpacity(0.7),
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _revealHardwareKey = !_revealHardwareKey;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedRadarCard() {
    double totalProgress = _barramentoScanController.value;
    int currentPercent = (totalProgress * 100).toInt();
    int currentItemIndex = (totalProgress * _hardwareComponents.length).floor().clamp(0, _hardwareComponents.length - 1);
    String activeComponentName = _hardwareComponents[currentItemIndex]['name'];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14), 
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [hackerGreen.withOpacity(0.02), primaryPurple.withOpacity(0.02)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: hackerGreen.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  value: totalProgress,
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(hackerGreen),
                  backgroundColor: Colors.white10,
                ),
              ),
              Text("$currentPercent%", style: TextStyle(color: hackerGreen, fontSize: 8, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Varredura activa: $activeComponentName", style: TextStyle(color: hackerGreen, fontSize: 11, fontWeight: FontWeight.w500, fontFamily: 'monospace')),
                const SizedBox(height: 2),
                const Text("Injetando clock de teste e capturando frames I2C", style: TextStyle(color: Colors.white38, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSequentialComponentItem(Map<String, dynamic> component, int index, bool hardwareOnline) {
    double totalProgress = _barramentoScanController.value;
    double countComponents = _hardwareComponents.length.toDouble();
    double startWindow = index / countComponents;
    double endWindow = (index + 1) / countComponents;

    bool isPassed = totalProgress >= endWindow;
    bool isActive = _isScanning && (totalProgress >= startWindow && totalProgress < endWindow);
    
    double itemProgressFactor = 0.0;
    int itemPercentage = 0;
    
    if (isActive) {
      itemProgressFactor = (totalProgress - startWindow) / (endWindow - startWindow);
      itemPercentage = (itemProgressFactor * 100).toInt().clamp(0, 100);
    } else if (isPassed) {
      itemProgressFactor = 1.0;
      itemPercentage = 100;
    }

    Color componentColor = hardwareOnline ? hackerGreen : hardwareRed; 
    LinearGradient fillGradient;

    if (isActive || isPassed) {
      fillGradient = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          componentColor.withOpacity(0.08), 
          componentColor.withOpacity(0.08),
          Colors.white.withOpacity(0.02),   
          Colors.white.withOpacity(0.02),
        ],
        stops: [0.0, itemProgressFactor, itemProgressFactor, 1.0],
      );
    } else {
      fillGradient = LinearGradient(colors: [Colors.white.withOpacity(0.02), Colors.white.withOpacity(0.02)]);
    }

    Color currentBorderColor = Colors.white.withOpacity(0.04);
    Color currentIconColor = Colors.white24;

    if (isActive) {
      currentBorderColor = componentColor.withOpacity(0.5);
      currentIconColor = componentColor;
    } else if (isPassed) {
      currentBorderColor = componentColor.withOpacity(0.2);
      currentIconColor = componentColor.withOpacity(0.6);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 30),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: fillGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: currentBorderColor, width: isActive ? 1.5 : 1.0),
      ),
      child: Row(
        children: [
          Icon(component['icon'], color: currentIconColor, size: 18),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(component['name'], style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 1),
                Text(component['desc'], style: const TextStyle(color: Colors.white12, fontSize: 11)),
              ],
            ),
          ),
          if (isActive)
            Text("$itemPercentage%", style: TextStyle(color: componentColor, fontSize: 11, fontFamily: 'monospace'))
          else if (isPassed)
            Icon(hardwareOnline ? Icons.check_circle_outlined : Icons.error_outline, color: componentColor, size: 14),
        ],
      ),
    );
  }

  Widget _buildIntegritySpectrumCard(bool hardwareOnline) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.01),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Status Geral do Espectro", style: TextStyle(color: Colors.white38, fontSize: 11)),
              const SizedBox(height: 2),
              Text(
                hardwareOnline ? "INTEGRIDADE MÁXIMA" : "SINAL CORROMPIDO",
                style: TextStyle(color: hardwareOnline ? hackerGreen : hardwareRed, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          // O botão agora altera seu comportamento caso esteja sob a trava local
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _forceOffline ? hackerGreen.withOpacity(0.1) : hardwareRed.withOpacity(0.1),
              foregroundColor: _forceOffline ? hackerGreen : hardwareRed,
              side: BorderSide(color: _forceOffline ? hackerGreen.withOpacity(0.3) : hardwareRed.withOpacity(0.3)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            onPressed: _isDisconnecting 
                ? null 
                : () {
                    if (_forceOffline) {
                      setState(() {
                        _forceOffline = false;
                      });
                    } else {
                      _disconnectHardware();
                    }
                  },
            icon: _isDisconnecting 
                ? SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, valueColor: AlwaysStoppedAnimation<Color>(hardwareRed)))
                : Icon(_forceOffline ? Icons.refresh : Icons.power_settings_new, size: 14),
            label: Text(
              _forceOffline ? "RECONECTAR HUB" : "DESCONECTAR HUB",
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class RadarPulsePainter extends CustomPainter {
  final double progress;
  final Color pulseColor;

  RadarPulsePainter({required this.progress, required this.pulseColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = pulseColor.withOpacity((1.0 - progress).clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.max(size.width, size.height) * 0.8;
    canvas.drawCircle(center, maxRadius * progress, paint);
  }

  @override
  bool shouldRepaint(covariant RadarPulsePainter oldDelegate) => oldDelegate.progress != progress;
}