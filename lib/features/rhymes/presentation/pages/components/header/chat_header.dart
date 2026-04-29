import 'package:flutter/material.dart';
import 'package:versin/features/rhymes/presentation/controller/rhymes_controller.dart';
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
    // O ListenableBuilder garante que o header se atualize apenas quando necessário
    return ListenableBuilder(
      listenable: rhymesController,
      builder: (context, _) {
        return Container(
          // Definimos largura total para evitar problemas de alinhamento no Column pai
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Widget de feedback visual (Termômetro/Estrelas)
              ThermometerFeedback(
                starProgress: rhymesController.starProgress,
                fireProgress: rhymesController.fireProgress,
                feedbackText: rhymesController.currentFeedback,
              ),
              const SizedBox(height: 8),
              // Linha sutil de instrução para o usuário, respeitando o design mobile
              Text(
                "Comece a escrever para analisar sua letra...",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
