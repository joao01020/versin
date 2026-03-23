import 'package:flutter/material.dart';

class AiSuggestionBalloon extends StatelessWidget {
  final String suggestion;
  final VoidCallback onTap;
  final bool isLoading;

  const AiSuggestionBalloon({
    super.key,
    required this.suggestion,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    // Se estiver carregando, mostra o indicador, senão mostra a rima
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(15),
            topRight: Radius.circular(15),
            bottomRight: Radius.circular(15),
            bottomLeft: Radius.circular(2),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 5, offset: const Offset(0, 2))
          ],
        ),
        child: isLoading 
          ? const SizedBox(
              width: 15, height: 15,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.purpleAccent),
            )
          : Text(
              suggestion,
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
            ),
      ),
    );
  }
}