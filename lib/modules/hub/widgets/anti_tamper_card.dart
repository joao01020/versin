import 'package:flutter/material.dart';

class AntiTamperCard extends StatefulWidget {
  const AntiTamperCard({super.key});

  @override
  State<AntiTamperCard> createState() => _AntiTamperCardState();
}

class _AntiTamperCardState extends State<AntiTamperCard> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    const Color accentNeon = Color(0xFFE040FB);
    const Color hardwareRed = Color(0xFFFF2A6D);
    const Color hackerGreen = Color(0xFF00FF66);

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
            onTap: () => setState(() => _revealed = !_revealed),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _revealed ? hackerGreen.withOpacity(0.3) : Colors.white.withOpacity(0.04),
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
                          color: _revealed ? hackerGreen : Colors.white30,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (!_revealed)
                        Row(
                          children: [
                            Icon(Icons.lock_outline, color: accentNeon.withOpacity(0.6), size: 12),
                            const SizedBox(width: 4),
                            const Text("REVELAR", style: TextStyle(color: accentNeon, fontSize: 9, fontWeight: FontWeight.bold)),
                          ],
                        )
                      else
                        const Icon(Icons.lock_open, color: hackerGreen, size: 12),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _revealed ? internalSigningKey : "••••••••••••••••••••••••••••••••••••••••••••••••",
                    style: TextStyle(
                      color: _revealed ? Colors.white70 : Colors.white10,
                      fontSize: 11,
                      fontFamily: 'monospace',
                      letterSpacing: _revealed ? 0.0 : 2.0,
                    ),
                  ),
                  if (_revealed) ...[
                    const SizedBox(height: 10),
                    Divider(color: Colors.white.withOpacity(0.05)),
                    const SizedBox(height: 4),
                    Text("HASH DO ECOSSISTEMA", style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 8, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(secureHashSeed, style: const TextStyle(color: Colors.white38, fontSize: 9, fontFamily: 'monospace')),
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}