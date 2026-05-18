// lib/modules/hub/dashboard/dashboard_hub_page.dart

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardHubPage extends StatefulWidget {
  const DashboardHubPage({super.key});

  @override
  State<DashboardHubPage> createState() => _DashboardHubPageState();
}

class _DashboardHubPageState extends State<DashboardHubPage> {
  // PALETA DE CORES CRIPTOGRÁFICA VERSIN
  final Color primaryPurple = const Color(0xFF6A1B9A);
  final Color accentNeon = const Color(0xFFE040FB);
  final Color deepBg = const Color(0xFF0D0B1F);
  final Color hardwareRed = const Color(0xFFFF2A6D);
  final Color hackerGreen = const Color(0xFF00FF66);

  // Estados de Controle de Comandos de Modo
  String _currentActiveMode = "IDLE";
  bool _isSendingCommand = false;

  // Controladores para o input dinâmico da carteira do artista
  final TextEditingController _walletController = TextEditingController();

  // Nós de Operação Filtrados e Atualizados - Apenas Canais Essenciais
  final List<Map<String, dynamic>> _hubModes = [
    {
      "title": "Studio Mode",
      "subtitle": "Interface minimalista ativa - Ícone Vinil",
      "icon": Icons.album_outlined,
      "modeKey": "STUDIO",
      "command": "CMD_SET_MODE:STUDIO",
    },
    {
      "title": "Modo Contrato",
      "subtitle": "Trava display em modo de assinatura e business",
      "icon": Icons.description_outlined,
      "modeKey": "CONTRACT",
      "command": "CMD_SET_MODE:CONTRACT",
    },
    {
      "title": "Vincular Artista",
      "subtitle": "Varredura local e ondas de pareamento RF",
      "icon": Icons.sensors,
      "modeKey": "ARTIST_LINK",
      "command": "CMD_SET_MODE:ARTIST_LINK",
    },
  ];

  @override
  void dispose() {
    _walletController.dispose();
    super.dispose();
  }

  // Transmissão assíncrona limpa (Sem alertas visuais / Pronta para o Supabase)
  Future<void> _sendCommandToHub(String command, String modeName) async {
    if (_isSendingCommand) return;

    setState(() {
      _isSendingCommand = true;
    });

    try {
      debugPrint("Transmitindo barramento serial para o chassi: $command");
      await Future.delayed(const Duration(milliseconds: 300));

      setState(() {
        _currentActiveMode = modeName;
      });
    } catch (e) {
      debugPrint("Falha ao comunicar modo com barramento local: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isSendingCommand = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: deepBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "VERSIN CONSOLE HUB",
          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            // CARD DO STATUS ATUAL DO ECOSSISTEMA ATUALIZADO
            _buildChassiLiveStatusCard(),

            const SizedBox(height: 28),

            _buildSectionTitle("Trilhas de Controle Operacional"),
            const SizedBox(height: 4),
            const Text(
              "Ative um canal de barramento para injetar dados no display físico",
              style: TextStyle(color: Colors.white30, fontSize: 11),
            ),
            const SizedBox(height: 20),

            // LISTA DE COMANDOS SEGMENTADOS COM SUB-MENUS SELECIONÁVEIS
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _hubModes.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final mode = _hubModes[index];
                return _buildConsoleRowItem(
                  title: mode["title"],
                  subtitle: mode["subtitle"],
                  icon: mode["icon"],
                  modeKey: mode["modeKey"],
                  command: mode["command"],
                );
              },
            ),
            const SizedBox(height: 24),
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

  // CARD DE MONITORAMENTO ATUALIZADO COM OPÇÃO DE TEXTO E VERDE HACKER
  Widget _buildChassiLiveStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryPurple.withOpacity(0.12), Colors.transparent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryPurple.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: hackerGreen.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.display_settings_rounded, color: hackerGreen, size: 18),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "BARRAMENTO DE DISPLAY ATIVO",
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Text("Canal Atual: ", style: TextStyle(color: Colors.white30, fontSize: 11)),
                      Text(
                        "/dev/nodes/$_currentActiveMode",
                        style: TextStyle(color: accentNeon, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          
          // PONTO DE NEON VERDE HACKER PULSANTE / CONECTADO
          Row(
            children: [
              if (_isSendingCommand)
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 1.5, color: accentNeon),
                )
              else
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: hackerGreen,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: hackerGreen.withOpacity(0.8), blurRadius: 8, spreadRadius: 2)
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ELEMENTO INTERATIVO COM EXPANSÃO DINÂMICA DE OPÇÕES AVANÇADAS
  Widget _buildConsoleRowItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required String modeKey,
    required String command,
  }) {
    final bool isSelected = _currentActiveMode == modeKey;

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _sendCommandToHub(command, modeKey),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isSelected ? primaryPurple.withOpacity(0.08) : Colors.white.withOpacity(0.01),
                borderRadius: isSelected 
                    ? const BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14))
                    : BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? accentNeon.withOpacity(0.5) : Colors.white.withOpacity(0.03),
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 4,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isSelected ? accentNeon : Colors.transparent,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: isSelected
                          ? [BoxShadow(color: accentNeon.withOpacity(0.6), blurRadius: 6, spreadRadius: 1)]
                          : [],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(icon, color: isSelected ? accentNeon : Colors.white30, size: 22),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white60,
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: isSelected ? Colors.white30 : Colors.white24,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? accentNeon.withOpacity(0.4) : Colors.white.withOpacity(0.05),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? accentNeon : Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // INJEÇÃO DOS SUB-PAINÉIS DE EXPANSÃO CONTEXTUAIS
          if (isSelected) _buildAdvancedSubPanel(modeKey),
        ],
      ),
    );
  }

  // GERENCIADOR DE SUB-PAINÉIS BASEADO NO MODO SELECIONADO
  Widget _buildAdvancedSubPanel(String modeKey) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.005),
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(14), bottomRight: Radius.circular(14)),
        border: Border(
          left: BorderSide(color: accentNeon.withOpacity(0.5)),
          right: BorderSide(color: accentNeon.withOpacity(0.5)),
          bottom: BorderSide(color: accentNeon.withOpacity(0.5)),
        ),
      ),
      child: _getSubPanelContent(modeKey),
    );
  }

  Widget _getSubPanelContent(String modeKey) {
    switch (modeKey) {
      case "STUDIO":
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "AÇÃO DE COMPILAÇÃO E INTEGRALIZAÇÃO",
              style: TextStyle(color: accentNeon, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.03)),
              ),
              child: Column(
                children: [
                  Icon(Icons.cloud_upload_outlined, color: accentNeon, size: 28),
                  const SizedBox(height: 8),
                  const Text(
                    "No upload você consegue enviar a música criando já um contrato marcando o artista correspondente.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  
                  // Entrada interativa para a tag da carteira do artista
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryPurple.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: accentNeon.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Text(
                          "wallet@\"",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontFamily: 'Courier',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _walletController,
                            style: TextStyle(
                              color: hackerGreen,
                              fontFamily: 'Courier',
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                            cursorColor: accentNeon,
                            decoration: const InputDecoration(
                              hintText: "nome_da_carteira",
                              hintStyle: TextStyle(color: Colors.white12, fontSize: 13),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 4),
                            ),
                          ),
                        ),
                        Text(
                          "\"",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontFamily: 'Courier',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

      case "CONTRACT":
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "DIRETRIZES DE SEGURANÇA DO CONTRATO",
              style: TextStyle(color: accentNeon, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.02)),
              ),
              child: const Text(
                "O ecossistema divide as assinaturas e transferências de dados físicos em três modos. Conexões sem fio operam em malhas de criptografia padrão, enquanto o pareamento por aproximação magnética oferece barreira física isolada contra interceptações.",
                style: TextStyle(color: Colors.white60, fontSize: 11, height: 1.4),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "CANAIS DE TRANSMISSÃO DE DADOS DISPONÍVEIS:",
              style: TextStyle(color: Colors.white30, fontSize: 9, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildHardwareChannelBadge(Icons.bluetooth, "Bluetooth", "Segurança Mediana", false),
                const SizedBox(width: 8),
                _buildHardwareChannelBadge(Icons.wifi, "Wi-Fi", "Segurança Mediana", false),
                const SizedBox(width: 8),
                _buildHardwareChannelBadge(Icons.contactless_outlined, "NFC", "Segurança Avançada", true),
              ],
            ),
          ],
        );

      case "ARTIST_LINK":
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "EMISSÃO DE CONVITE E EMPARELHAMENTO DE REDE",
              style: TextStyle(color: accentNeon, fontSize: 9, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: const Center(
                    child: Icon(Icons.qr_code_2_rounded, color: Colors.white30, size: 40),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Ondas de pareamento ativas", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 6),
                      Row(
                        children: List.generate(4, (index) {
                          return Container(
                            margin: const EdgeInsets.only(right: 4),
                            width: 16 + (index * 4).toDouble(),
                            height: 3,
                            decoration: BoxDecoration(
                              color: hackerGreen.withOpacity(1.0 - (index * 0.2)),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 4),
                      const Text("Aguardando resposta do chassi externo...", style: TextStyle(color: Colors.white24, fontSize: 10)),
                    ],
                  ),
                )
              ],
            ),
          ],
        );

      default:
        return const Text(
          "Canal de transmission limpo e sem sub-instruções anexadas.",
          style: TextStyle(color: Colors.white24, fontSize: 11),
        );
    }
  }

  Widget _buildHardwareChannelBadge(IconData icon, String label, String securityLevel, bool isAdvanced) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: isAdvanced ? hackerGreen.withOpacity(0.02) : Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isAdvanced ? hackerGreen.withOpacity(0.2) : Colors.white.withOpacity(0.04),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon, 
              color: isAdvanced ? hackerGreen : accentNeon.withOpacity(0.8), 
              size: 18
            ),
            const SizedBox(height: 6),
            Text(
              label, 
              style: TextStyle(
                color: isAdvanced ? Colors.white : Colors.white60, 
                fontSize: 10, 
                fontWeight: isAdvanced ? FontWeight.bold : FontWeight.normal
              )
            ),
            const SizedBox(height: 4),
            Text(
              securityLevel,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isAdvanced ? hackerGreen.withOpacity(0.8) : Colors.white30,
                fontSize: 8,
                fontWeight: isAdvanced ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}