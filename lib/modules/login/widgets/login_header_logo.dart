import 'package:flutter/material.dart';

class LoginHeaderLogo extends StatelessWidget {
  final Color primaryPurple;
  final Color accentNeon;

  const LoginHeaderLogo({
    super.key,
    required this.primaryPurple,
    required this.accentNeon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Hero(
          tag: 'versin_logo',
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryPurple.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: accentNeon.withOpacity(0.3), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: accentNeon.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 2,
                )
              ],
            ),
            child: Icon(Icons.all_inclusive_rounded, color: accentNeon, size: 42),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          "VERSIN",
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 4.0,
          ),
        ),
        const Text(
          "Ecossistema Descentralizado",
          style: TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 0.5),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}