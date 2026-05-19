import 'package:flutter/material.dart';

class HubTelemetryGrid extends StatelessWidget {
  final bool online;
  final String trafego;
  final String latencia;
  final int sinal;

  const HubTelemetryGrid({
    super.key,
    required this.online,
    required this.trafego,
    required this.latencia,
    required this.sinal,
  });

  @override
  Widget build(BuildContext context) {
    const Color accentNeon = Color(0xFFE040FB);

    return Column(
      children: [
        Row(
          children: [
            _buildStatCard(
              title: "TRÁFEGO DE REDE",
              value: online ? trafego : "0.0 KB/s",
              subtitleWidget: Row(
                children: [
                  Icon(Icons.wifi_tethering, color: accentNeon.withOpacity(0.5), size: 10),
                  const SizedBox(width: 4),
                  Text(
                    online ? "Sinal Wi-Fi: $sinal%" : "Ancoragem Wi-Fi Local", 
                    style: const TextStyle(color: Colors.white30, fontSize: 10),
                  ),
                ],
              ),
              icon: Icons.grid_view_rounded,
            ),
            const SizedBox(width: 14),
            _buildStatCard(
              title: "LATÊNCIA HARDWARE",
              value: online ? latencia : "---",
              subtitleWidget: Text(
                online ? "Barramento estável" : "Sem resposta do barramento", 
                style: const TextStyle(color: Colors.white24, fontSize: 10),
              ),
              icon: Icons.bolt_outlined,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _buildStatCard(
              title: "TEMPERATURA DO CORE",
              value: online ? "41 °C" : "-- °C",
              subtitleWidget: Text(
                online ? "Sensor térmico operational" : "Sensor térmico interno offline", 
                style: const TextStyle(color: Colors.white24, fontSize: 10),
              ),
              icon: Icons.thermostat_outlined,
            ),
            const SizedBox(width: 14),
            _buildStatCard(
              title: "ARMAZENAMENTO INTERNO",
              value: online ? "4.2 / 16 MB" : "0 / 16 MB",
              subtitleWidget: Text(
                online ? "SPIFFS montada com sucesso" : "Partição SPIFFS desmontada", 
                style: const TextStyle(color: Colors.white24, fontSize: 10),
              ),
              icon: Icons.storage_outlined,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
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
                Text(
                  title, 
                  style: const TextStyle(
                    color: Colors.white38, 
                    fontSize: 9, 
                    fontWeight: FontWeight.bold, 
                    letterSpacing: 0.5
                  ),
                ),
                Icon(icon, color: Colors.white12, size: 16),
              ],
            ),
            Text(
              value, 
              style: const TextStyle(
                color: Colors.white60, 
                fontSize: 20, 
                fontWeight: FontWeight.bold
              ),
            ),
            subtitleWidget,
          ],
        ),
      ),
    );
  }
}