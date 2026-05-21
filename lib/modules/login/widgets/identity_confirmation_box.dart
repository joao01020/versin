import 'package:flutter/material.dart';

class IdentityConfirmationBox extends StatelessWidget {
  final bool isNameRepresented;
  final String walletAddress;
  final Color primaryPurple;
  final Color accentNeon;
  final Function(bool?) onChanged;

  const IdentityConfirmationBox({
    super.key,
    required this.isNameRepresented,
    required this.walletAddress,
    required this.primaryPurple,
    required this.accentNeon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primaryPurple.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isNameRepresented ? accentNeon.withOpacity(0.3) : Colors.white.withOpacity(0.05)
        ),
      ),
      child: Row(
        children: [
          Theme(
            data: ThemeData(unselectedWidgetColor: Colors.white24),
            child: Checkbox(
              value: isNameRepresented,
              activeColor: accentNeon,
              checkColor: Colors.black,
              onChanged: onChanged,
            ),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                children: [
                  const TextSpan(text: "Seu pseudônimo vai ser "),
                  TextSpan(
                    text: walletAddress,
                    style: TextStyle(color: accentNeon, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                  ),
                  const TextSpan(text: " , esse nome te representa?"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}