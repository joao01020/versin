import 'package:flutter/material.dart';
import '../controllers/wallet_controller.dart';

class QuickActionButtonWidget extends StatelessWidget {
  final WalletController controller;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const QuickActionButtonWidget({
    super.key,
    required this.controller,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            splashColor: controller.accentNeon.withOpacity(0.15),
            highlightColor: controller.accentNeon.withOpacity(0.05),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Icon(icon, color: controller.accentNeon, size: 24),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}