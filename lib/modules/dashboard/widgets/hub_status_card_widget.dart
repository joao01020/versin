import 'package:flutter/material.dart';
import '../controllers/dashboard_controller.dart';
import '../data/models/hardware_status_model.dart';

/// [HubStatusCardWidget] displays the realtime connection status of the Versin physical hardware.
/// [HubStatusCardWidget] exibe o status de conexão em tempo real do hardware físico do Versin.
class HubStatusCardWidget extends StatelessWidget {
  final DashboardController controller;

  const HubStatusCardWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<HardwareStatusModel>>(
      stream: controller.hardwareStatusStream,
      builder: (context, snapshot) {
        bool estaOnlineDeVerdade = false;
        String mensagemStatus = "Hardware desconectado";
        Color statusColor = Colors.redAccent;

        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final dadosHardware = snapshot.data!.first;
          
          // ⚡ ENCAIXE PERFEITO: Usando as propriedades reais que existem no seu HardwareStatusModel
          estaOnlineDeVerdade = dadosHardware.isOnline;

          if (estaOnlineDeVerdade) {
            mensagemStatus = "Hub conectado via Apolo-system (${dadosHardware.machineName})";
            statusColor = controller.hackerGreen;
          } else {
            mensagemStatus = "Último sinal pendente no terminal (${dadosHardware.machineName})";
          }
        }

        return Container(
          padding: const EdgeInsets.all(20),
          height: 140,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF4A148C), Color(0xFF2E1A47)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7B1FA2).withOpacity(0.3), 
                blurRadius: 10, 
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("VERSIN HUB", style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  Icon(
                    estaOnlineDeVerdade ? Icons.sensors : Icons.sensors_off, 
                    color: Colors.white30, 
                    size: 18,
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: statusColor, blurRadius: 8, spreadRadius: 2),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    estaOnlineDeVerdade ? "Online" : "Offline", 
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Text(mensagemStatus, style: const TextStyle(color: Colors.white54, fontSize: 10)),
            ],
          ),
        );
      },
    );
  }
}