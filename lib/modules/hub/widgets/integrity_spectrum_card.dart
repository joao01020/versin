import 'package:flutter/material.dart';
import '../controllers/hub_telemetry_controller.dart';

class IntegritySpectrumCard extends StatelessWidget {
  final HubTelemetryController controller;
  final bool online;

  const IntegritySpectrumCard({
    super.key,
    required this.controller,
    required this.online,
  });

  @override
  Widget build(BuildContext context) {
    const Color hardwareRed = Color(0xFFFF2A6D);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.01),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "STATUS E CONEXÃO LOCAL", 
                  style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  online ? "Firmware rodando em ambiente seguro estável" : "Aguardando sincronia via cabo/barramento local",
                  style: const TextStyle(color: Colors.white24, fontSize: 9),
                ),
              ],
            ),
          ),
          if (online)
            ValueListenableBuilder<bool>(
              valueListenable: controller.isDisconnecting,
              builder: (context, disconnecting, _) {
                return TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: hardwareRed),
                  onPressed: () {
                    // 🔥 Dispara a Solução 2: Limpa animações, conexões locais e joga offline no Supabase
                    controller.triggerManualDisconnect();
                  },
                  icon: disconnecting 
                      ? const SizedBox(
                          width: 12, 
                          height: 12, 
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5, 
                            valueColor: AlwaysStoppedAnimation(Colors.redAccent),
                          ),
                        )
                      : const Icon(Icons.power_settings_new, size: 14),
                  label: const Text(
                    "FORÇAR OFFLINE", 
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}