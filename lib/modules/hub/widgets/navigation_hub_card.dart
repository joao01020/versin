import 'package:flutter/material.dart';
import '../views/hub_panel_page.dart';

class NavigationHubCard extends StatelessWidget {
  final bool online;

  const NavigationHubCard({super.key, required this.online});

  @override
  Widget build(BuildContext context) {
    const Color primaryPurple = Color(0xFF6A1B9A);
    const Color accentNeon = Color(0xFFE040FB);

    return GestureDetector(
      onTap: () {
        if (online) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HubPanelPage()),
          );
        } else {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Color(0xFFFF2A6D),
              content: Row(
                children: [
                  Icon(Icons.gavel_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 10),
                  Text(
                    "Acesso Negado: Sincronize o Versin Hub primeiro.",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: online ? primaryPurple.withOpacity(0.1) : Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: online ? accentNeon.withOpacity(0.4) : Colors.white.withOpacity(0.05),
            width: online ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  online ? Icons.dashboard_customize : Icons.lock_outline,
                  color: online ? accentNeon : Colors.white24,
                  size: 18,
                ),
                const SizedBox(width: 12),
                Text(
                  "Acessar Painel Central do Hub",
                  style: TextStyle(
                    color: online ? Colors.white : Colors.white30,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Icon(Icons.arrow_forward_ios, color: online ? accentNeon : Colors.white10, size: 14),
          ],
        ),
      ),
    );
  }
}