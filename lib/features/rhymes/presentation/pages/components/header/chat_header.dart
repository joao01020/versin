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
    // O header agora foca apenas no feedback visual da gamificação
    return ListenableBuilder(
      listenable: rhymesController,
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ThermometerFeedback(
            // Sincroniza o progresso das estrelas e do fogo com o controller
            starProgress: rhymesController.starProgress,
            fireProgress: rhymesController.fireProgress,
            feedbackText: rhymesController.currentFeedback,
          ),
        );
      },
    );
  }
}