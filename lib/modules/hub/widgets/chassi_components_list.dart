import 'package:flutter/material.dart';
import '../controllers/hub_telemetry_controller.dart';

class ChassiComponentsList extends StatelessWidget {
  final HubTelemetryController controller;
  final bool online;

  ChassiComponentsList({
    super.key,
    required this.controller,
    required this.online,
  });

  final List<Map<String, dynamic>> _hardwareComponents = [
    {"name": "Anel de Feedback LED (NeoPixel)", "icon": Icons.blur_circular_outlined, "desc": "Sinalização visual de BPM e gravação"},
    {"name": "Sensores Touch Capacitivos", "icon": Icons.touch_app_outlined, "desc": "Atalhos rápidos e controle gestual de efeitos"},
    {"name": "Cápsula de Microfone (I2S)", "icon": Icons.mic_none_outlined, "desc": "Captação analógica e conversão digital de rimas"},
    {"name": "Matriz de Teclas Mecânicas", "icon": Icons.keyboard_alt_outlined, "desc": "Gatilhos rápidos para modo Studio e Rhyme"},
    {"name": "Display Gráfico OLED 128x64", "icon": Icons.screenshot_monitor, "desc": "Retorno visual de metadados e espectro de áudio"},
  ];

  @override
  Widget build(BuildContext context) {
    const Color primaryPurple = Color(0xFF6A1B9A);
    const Color accentNeon = Color(0xFFE040FB);
    const Color hackerGreen = Color(0xFF00FF66);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Mapeamento do Chassi".toUpperCase(),
                  style: const TextStyle(color: accentNeon, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                ),
                const SizedBox(height: 2),
                const Text("Componentes e transdutores integrados de fábrica", style: TextStyle(color: Colors.white30, fontSize: 11)),
              ],
            ),
            ValueListenableBuilder<bool>(
              valueListenable: controller.isScanning,
              builder: (context, scanning, _) {
                return ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: scanning ? hackerGreen.withOpacity(0.1) : primaryPurple.withOpacity(0.15),
                    foregroundColor: scanning ? hackerGreen : accentNeon,
                    side: BorderSide(color: scanning ? hackerGreen.withOpacity(0.4) : accentNeon.withOpacity(0.3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onPressed: controller.toggleScan,
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
          valueListenable: controller.isScanning,
          builder: (context, scanning, _) {
            if (!scanning) return const SizedBox.shrink();
            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: hackerGreen.withOpacity(0.02),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: hackerGreen.withOpacity(0.2)),
              ),
              child: const Row(
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
          },
        ),
        Column(
          children: List.generate(_hardwareComponents.length, (index) {
            final comp = _hardwareComponents[index];
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
          }),
        ),
      ],
    );
  }
}