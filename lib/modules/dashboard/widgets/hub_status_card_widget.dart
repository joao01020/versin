import 'package:flutter/material.dart';

import '../controllers/dashboard_controller.dart';
import '../data/models/hardware_status_model.dart';

/// [HubStatusCardWidget] displays the realtime connection status
/// of the Versin physical hardware.
///
/// [HubStatusCardWidget] exibe o status de conexão em tempo real
/// do hardware físico do Versin.
class HubStatusCardWidget
    extends
        StatelessWidget {
  final DashboardController controller;

  const HubStatusCardWidget({
    super.key,
    required this.controller,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return StreamBuilder<
      List<
        HardwareStatusModel
      >
    >(
      stream: controller.hardwareStatusStream,

      builder:
          (
            context,
            snapshot,
          ) {
            // ========================================================
            // ESTADO PADRÃO
            // ========================================================

            bool estaOnlineDeVerdade = false;

            String mensagemStatus = "Hardware desconectado";

            Color statusColor = Colors.redAccent;

            // ========================================================
            // STATUS DO HARDWARE
            // ========================================================

            if (snapshot.hasData &&
                snapshot.data!.isNotEmpty) {
              final dadosHardware = snapshot.data!.first;

              estaOnlineDeVerdade = dadosHardware.isOnline;

              if (estaOnlineDeVerdade) {
                mensagemStatus =
                    "Hub conectado via Apolo-system "
                    "(${dadosHardware.machineName})";

                statusColor = controller.hackerGreen;
              } else {
                mensagemStatus =
                    "Último sinal pendente no terminal "
                    "(${dadosHardware.machineName})";
              }
            }

            // ========================================================
            // CARD
            // ========================================================

            return Container(
              height: 140,

              padding: const EdgeInsets.all(
                20,
              ),

              decoration: BoxDecoration(
                // ====================================================
                // GRADIENTE
                // ====================================================
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,

                  end: Alignment.bottomRight,

                  colors: [
                    Color(
                      0xFF4A148C,
                    ),
                    Color(
                      0xFF2E1A47,
                    ),
                  ],
                ),

                // ====================================================
                // BORDAS
                // ====================================================
                borderRadius: BorderRadius.circular(
                  20,
                ),

                // ====================================================
                // SOMBRA
                // ====================================================
                boxShadow: [
                  BoxShadow(
                    color:
                        const Color(
                          0xFF7B1FA2,
                        ).withValues(
                          alpha: 0.3,
                        ),

                    blurRadius: 10,

                    offset: const Offset(
                      0,
                      4,
                    ),
                  ),
                ],
              ),

              // ======================================================
              // CONTEÚDO
              // ======================================================
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                mainAxisAlignment: MainAxisAlignment.spaceBetween,

                children: [
                  // ==================================================
                  // HEADER
                  // ==================================================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,

                    children: [
                      const Text(
                        "VERSIN HUB",

                        style: TextStyle(
                          color: Colors.white70,

                          fontSize: 10,

                          fontWeight: FontWeight.bold,

                          letterSpacing: 0.5,
                        ),
                      ),

                      Icon(
                        estaOnlineDeVerdade
                            ? Icons.sensors
                            : Icons.sensors_off,

                        color: Colors.white30,

                        size: 18,
                      ),
                    ],
                  ),

                  // ==================================================
                  // STATUS
                  // ==================================================
                  Row(
                    children: [
                      // ==============================================
                      // INDICADOR
                      // ==============================================
                      Container(
                        width: 10,

                        height: 10,

                        decoration: BoxDecoration(
                          color: statusColor,

                          shape: BoxShape.circle,

                          boxShadow: [
                            BoxShadow(
                              color: statusColor,

                              blurRadius: 8,

                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        width: 10,
                      ),

                      // ==============================================
                      // ONLINE / OFFLINE
                      // ==============================================
                      Text(
                        estaOnlineDeVerdade
                            ? "Online"
                            : "Offline",

                        style: const TextStyle(
                          color: Colors.white,

                          fontSize: 18,

                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  // ==================================================
                  // DESCRIÇÃO
                  // ==================================================
                  Text(
                    mensagemStatus,

                    style: const TextStyle(
                      color: Colors.white54,

                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            );
          },
    );
  }
}
