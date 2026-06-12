import 'package:flutter/material.dart';

class ActionButtonWidget extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const ActionButtonWidget({
    super.key,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // EN: Using Material + InkWell to provide native production-ready touch feedback inside the strict circle decoration
    // PT: Usando Material + InkWell para fornecer feedback de toque nativo de produção dentro da decoração circular estrita
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(), // EN: Keeps the splash effect perfectly circular | PT: Mantém o efeito de splash perfeitamente circular
        splashColor: color.withOpacity(0.1),
        highlightColor: color.withOpacity(0.05),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }
}