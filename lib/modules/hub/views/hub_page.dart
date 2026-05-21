import 'package:flutter/material.dart';
import 'package:versin/app/routes/app_routes.dart'; // Importação das rotas
import '../controllers/hub_telemetry_controller.dart';
import '../widgets/master_search_card.dart';
import '../widgets/navigation_hub_card.dart';
import '../widgets/hub_telemetry_grid.dart';
import '../widgets/anti_tamper_card.dart';
import '../widgets/chassi_components_list.dart';
import '../widgets/integrity_spectrum_card.dart';

class HubPage extends StatefulWidget {
  // Rota estática definida para referência centralizada
  static const String routeName = AppRoutes.hub;

  const HubPage({super.key});

  @override
  State<HubPage> createState() => _HubPageState();
}

class _HubPageState extends State<HubPage> with TickerProviderStateMixin {
  final HubTelemetryController _controller = HubTelemetryController();

  @override
  void initState() {
    super.initState();
    _controller.initControllers(vsync: this);
    _controller.barramentoScanController.addListener(() => setState(() {}));
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
              // Extração de variáveis de estado da telemetria
              bool estaOnlineDeVerdade = false;
              String mensagemStatus = "Hardware desconectado";
              String trafegoText = "0.0 KB/s";
              String latenciaText = "---";
              int sinalReal = 0;

              if (!forcedOffline && snapshot.hasData && snapshot.data!.isNotEmpty) {
                final dadosHardware = snapshot.data!.first;
                final String statusReal = dadosHardware['status'] ?? 'offline';
                sinalReal = dadosHardware['sinal'] ?? 0;

                if (statusReal == 'online' && dadosHardware['updated_at'] != null) {
                  final DateTime updatedAt = DateTime.parse(dadosHardware['updated_at']).toUtc();
                  final int diferencaSegundos = DateTime.now().toUtc().difference(updatedAt).inSeconds.abs();

                  if (diferencaSegundos < 600) {
                    estaOnlineDeVerdade = true;
                    mensagemStatus = "Hub conectado via Apolo-system";
                    trafegoText = "1.4 KB/s";
                    latenciaText = "${(diferencaSegundos % 15) + 12} ms";
                  } else {
                    mensagemStatus = "Último sinal há $diferencaSegundos segundos";
                  }
                } else if (statusReal == 'offline') {
                  mensagemStatus = "Hardware em modo passivo";
                }
              } else if (forcedOffline) {
                mensagemStatus = "Hardware desconectado manualmente";
              }

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    MasterSearchCard(
                      controller: _controller,
                      online: estaOnlineDeVerdade,
                      mensagemSub: mensagemStatus,
                    ),
                    const SizedBox(height: 16),
                    NavigationHubCard(online: estaOnlineDeVerdade),
                    const SizedBox(height: 20),
                    HubTelemetryGrid(
                      online: estaOnlineDeVerdade,
                      trafego: trafegoText,
                      latencia: latenciaText,
                      sinal: sinalReal,
                    ),
                    const SizedBox(height: 24),
                    const AntiTamperCard(),
                    const SizedBox(height: 24),
                    ChassiComponentsList(
                      controller: _controller,
                      online: estaOnlineDeVerdade,
                    ),
                    const SizedBox(height: 24),
                    IntegritySpectrumCard(
                      controller: _controller,
                      online: estaOnlineDeVerdade,
                    ),
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
}