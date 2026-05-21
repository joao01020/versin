import 'package:flutter/material.dart';
import 'package:versin/features/rhymes/presentation/controller/rhymes_controller.dart';
// Mova este componente para lib/core/widgets/gamification/ se ele for usado em outros lugares
import 'package:versin/features/rhymes/presentation/widgets/thermometer_gamification/thermometer_widget.dart';

class ChatHeader extends StatelessWidget {
  final Color activeColor;
  final RhymesController rhymesController;

  const ChatHeader({
    super.key,
    required this.activeColor,
    required this.rhymesController,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: rhymesController,
      builder: (context, _) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: const BoxDecoration(color: Color(0xFF0F0F0F)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo centralizado (Menu removido conforme solicitado)
              _buildBranding(),
              const SizedBox(height: 12),
              
              ThermometerFeedback(
                starProgress: rhymesController.starProgress,
                fireProgress: rhymesController.fireProgress,
                feedbackText: rhymesController.currentFeedback,
              ),
              
              const SizedBox(height: 8),
              
              Text(
                "Comece a escrever para analisar sua letra...",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 11,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBranding() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "VERSIN",
          style: TextStyle(
            color: activeColor,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
          ),
        ),
        const Text(
          "GENESIS",
          style: TextStyle(
            color: Colors.white38,
            fontSize: 8,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}