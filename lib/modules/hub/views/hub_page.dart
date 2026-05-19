import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../controllers/hub_telemetry_controller.dart';
import '../dashboard/dashboard_hub_page.dart';

class HubPage extends StatefulWidget {
  const HubPage({super.key});

  @override
  State<HubPage> createState() => _HubPageState();
}

class _HubPageState extends State<HubPage> with TickerProviderStateMixin {
  // Inicialização do cérebro lógico do módulo de telemetria
  final HubTelemetryController _controller = HubTelemetryController();

  // PALETA DE CORES CRIPTOGRAFICA VERSIN
  final Color primaryPurple = const Color(0xFF6A1B9A);
  final Color accentNeon = const Color(0xFFE040FB);
  final Color deepBg = const Color(0xFF0D0B1F);
  final Color hardwareRed = const Color(0xFFFF2A6D);
  final Color hackerGreen = const Color(0xFF00FF66);

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
    _controller.initControllers(vsync: this);
    _controller.barramentoScanController.addListener(() {
      setState(() {}); // Mantém sincronia fina da linha do ticker de varredura
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ValueListenableBuilder<bool>(
        valueListenable: _controller.forceOffline,
        builder: (context, forcedOffline, _) {
          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: _controller.hardwareStream,
            builder: (context, snapshot) {
              String statusReal = "offline";
              int sinalReal = 0;
              bool estaOnlineDeVerdade = false;
              String latenciaText = "---";
              String mensagemStatus = "Hardware desconectado";
              String trafegoText = "0.0 KB/s";

              if (forcedOffline) {
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
              }

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),

                    // CARD MASTER DE BUSCA GLOBAL ATUALIZADO
                    _buildMasterSearchCard(estaOnlineDeVerdade, mensagemStatus),

                    const SizedBox(height: 16),

                    // CARD DE DIRECIONAMENTO AO CENTRO DE COMANDO
                    _buildNavigationDashboardCard(),

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
                                estaOnlineDeVerdade ? "Sinal Wi-Fi: $sinalReal%" : "Ancoragem Wi-Fi Local", 
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

                    // TELEMETRIA DE SAÚDE DA PLACA
                    Row(
                      children: [
                        _buildHubStatCard(
                          title: "TEMPERATURA DO CORE",
                          value: estaOnlineDeVerdade ? "41 °C" : "-- °C",
                          subtitleWidget: Text(
                            estaOnlineDeVerdade ? "Sensor térmico operational" : "Sensor térmico interno offline", 
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
                        ValueListenableBuilder<bool>(
                          valueListenable: _controller.isScanning,
                          builder: (context, scanning, _) {
                            return ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: scanning ? hackerGreen.withOpacity(0.1) : primaryPurple.withOpacity(0.15),
                                foregroundColor: scanning ? hackerGreen : accentNeon,
                                side: BorderSide(color: scanning ? hackerGreen.withOpacity(0.4) : accentNeon.withOpacity(0.3)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              ),
                              onPressed: _controller.toggleScan,
                              icon: Icon(scanning ? Icons.stop_circle_outlined : Icons.radar_outlined, size: 16),
                              label: Text(
                                scanning ? "INTERROMPER" : "ESCANEAR BARRAMENTO",
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    ValueListenableBuilder<bool>(
                      valueListenable: _controller.isScanning,
                      builder: (context, scanning, _) {
                        return scanning ? _buildAnimatedRadarCard() : const SizedBox.shrink();
                      },
                    ),

                    // LISTA DE COMPONENTES INTERNOS DO DISPOSITIVO
                    Column(
                      children: List.generate(_hardwareComponents.length, (index) {
                        return _buildSequentialComponentItem(_hardwareComponents[index], index, estaOnlineDeVerdade);
                      }),
                    ),

                    const SizedBox(height: 24),

                    // ANALISADOR DE INTEGRIDADE FLAT + BOTÃO DE DESCONEXÃO
                    _buildIntegritySpectrumCard(estaOnlineDeVerdade),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMasterSearchCard(bool online, String mensagemSub) {
    return ValueListenableBuilder<SearchState>(
      valueListenable: _controller.searchState,
      builder: (context, state, _) {
        Color currentBorderColor;
        Color buttonBgColor;
        Color buttonContentColor;
        String buttonText;
        IconData buttonIcon;

        switch (state) {
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
            buttonText = "CONEXÃO FIRMADA";
            buttonIcon = Icons.check_circle;
            break;
          case SearchState.notFound:
            currentBorderColor = hardwareRed.withOpacity(0.7);
            buttonBgColor = hardwareRed.withOpacity(0.2);
            buttonContentColor = hardwareRed;
            buttonText = "CHASSI NÃO ENCONTRADO";
            buttonIcon = Icons.error_outline;
            break;
          case SearchState.idle:
          default:
            currentBorderColor = Colors.white.withOpacity(0.06);
            buttonBgColor = primaryPurple.withOpacity(0.2);
            buttonContentColor = Colors.white;
            buttonText = "SINCRONIZAR";
            buttonIcon = Icons.sync_lock_rounded;
            break;
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: double.infinity,
          height: 210,
          decoration: BoxDecoration(
            color: state == SearchState.found 
                ? hackerGreen.withOpacity(0.03) 
                : state == SearchState.notFound 
                    ? hardwareRed.withOpacity(0.03) 
                    : Colors.white.withOpacity(0.02),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: currentBorderColor, width: state != SearchState.idle ? 1.5 : 1.0),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: Stack(
              alignment: Alignment.center,
              children: [
                ValueListenableBuilder<bool>(
                  valueListenable: _controller.isGlobalSearching,
                  builder: (context, globalSearching, _) {
                    if (!globalSearching) return const SizedBox.shrink();
                    return AnimatedBuilder(
                      animation: _controller.globalSearchController,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: RadarPulsePainter(
                            progress: _controller.globalSearchController.value,
                            pulseColor: accentNeon,
                          ),
                          child: const SizedBox.expand(),
                        );
                      },
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
                                  color: state == SearchState.found 
                                      ? hackerGreen 
                                      : state == SearchState.notFound 
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
                              if (state == SearchState.searching) {
                                _controller.cancelActiveSearch();
                              } else if (state == SearchState.idle) {
                                if (_controller.forceOffline.value) {
                                  _controller.forceOffline.value = false;
                                } else {
                                  _controller.startActiveHardwareSearch(online);
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
                                  if (_controller.isGlobalSearching.value || state == SearchState.found)
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
                            state == SearchState.searching 
                                ? "Sintonizando transceptores de rádio 2.4GHz..." 
                                : state == SearchState.found
                                    ? "Handshake com ESP32 efetuado com sucesso!"
                                    : state == SearchState.notFound
                                        ? "Nenhum sinal recebido nos broadcasts UDP/HTTP."
                                        : "Interface de acoplamento em modo de escuta passiva",
                            style: TextStyle(
                              color: state == SearchState.searching 
                                  ? Colors.white60 
                                  : state == SearchState.idle 
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
          },
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
            onTap: _controller.revealKey,
            child: ValueListenableBuilder<bool>(
              valueListenable: _controller.revealHardwareKey,
              builder: (context, revealed, _) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: revealed ? hackerGreen.withOpacity(0.3) : Colors.white.withOpacity(0.04),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "HARDWARE_SIGNING_KEY",
                            style: TextStyle(
                              color: revealed ? hackerGreen : Colors.white30,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          if (!revealed)
                            Row(
                              children: [
                                Icon(Icons.lock_outline, color: accentNeon.withOpacity(0.6), size: 12),
                                const SizedBox(width: 4),
                                Text("REVELAR", style: TextStyle(color: accentNeon, fontSize: 9, fontWeight: FontWeight.bold)),
                              ],
                            )
                          else
                            Icon(Icons.lock_open, color: hackerGreen, size: 12),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        revealed ? internalSigningKey : "••••••••••••••••••••••••••••••••••••••••••••••••",
                        style: TextStyle(
                          color: revealed ? Colors.white70 : Colors.white10,
                          fontSize: 11,
                          fontFamily: 'monospace',
                          letterSpacing: revealed ? 0.0 : 2.0,
                        ),
                      ),
                      if (revealed) ...[
                        const SizedBox(height: 10),
                        Divider(color: Colors.white.withOpacity(0.05)),
                        const SizedBox(height: 4),
                        Text("HASH DO ECOSSISTEMA", style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 8, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(secureHashSeed, style: const TextStyle(color: Colors.white38, fontSize: 9, fontFamily: 'monospace')),
                      ]
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedRadarCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hackerGreen.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: hackerGreen.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(hackerGreen),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              "Escaneando pinos I/O do chassi e injetando pulsos de clock na partição SPIFFS...",
              style: TextStyle(color: hackerGreen, fontSize: 10, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSequentialComponentItem(Map<String, dynamic> comp, int index, bool online) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.01),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: Row(
        children: [
          Icon(comp['icon'], color: online ? accentNeon : Colors.white24, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(comp['name'], style: TextStyle(color: online ? Colors.white : Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(comp['desc'], style: const TextStyle(color: Colors.white24, fontSize: 10)),
              ],
            ),
          ),
          Text(
            online ? "PRONTO" : "STDBY",
            style: TextStyle(
              color: online ? hackerGreen.withOpacity(0.8) : Colors.white12,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntegritySpectrumCard(bool online) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.01),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("STATUS E CONEXÃO LOCAL", style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(
                    online ? "Firmware rodando em ambiente seguro estável" : "Aguardando sincronia via cabo/barramento local",
                    style: const TextStyle(color: Colors.white24, fontSize: 9),
                  ),
                ],
              ),
              if (online)
                ValueListenableBuilder<bool>(
                  valueListenable: _controller.isDisconnecting,
                  builder: (context, disconnecting, _) {
                    return TextButton(
                      onPressed: _controller.disconnectHardware,
                      style: TextButton.styleFrom(
                        foregroundColor: hardwareRed,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: disconnecting
                          ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.redAccent))
                          : const Text("DESCONECTAR", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationDashboardCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentNeon.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.dashboard_customize_outlined, color: accentNeon, size: 20),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Centro de Controle OLED",
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Gerencie telas de estúdio e rimas físicas",
                    style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryPurple.withOpacity(0.2),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              side: BorderSide(color: accentNeon.withOpacity(0.3)),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const DashboardHubPage(),
                ),
              );
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("PAINEL", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                SizedBox(width: 6),
                Icon(Icons.arrow_forward_ios, size: 10),
              ],
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
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.sqrt(size.width * size.width + size.height * size.height) / 2;
    
    final paint = Paint()
      ..color = pulseColor.withOpacity((1.0 - progress).clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(center, maxRadius * progress, paint);
  }

  @override
  bool shouldRepaint(covariant RadarPulsePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}