import 'package:flutter/material.dart';
import 'package:versin/features/rimas/presentation/controller/rimas_controller.dart';
import 'package:versin/features/rimas/presentation/widgets/thermometer_gamification/thermometer_widget.dart';

class ChatHeader extends StatelessWidget {
  final Color activeColor;
  final RimasController rimasController;
  final bool isRhymeMode, isComporMode, isListarMode, isMarketingMode;

  const ChatHeader({
    super.key,
    required this.activeColor,
    required this.rimasController,
    required this.isRhymeMode,
    required this.isComporMode,
    required this.isListarMode,
    required this.isMarketingMode,
  });

  @override
  Widget build(BuildContext context) {
    String modeText = "FREE MODE";
    if (isRhymeMode) modeText = "RHYME MODE";
    else if (isComporMode) modeText = "COMPOR MODE";
    else if (isListarMode) modeText = "LISTAR MODE";
    else if (isMarketingMode) modeText = "MARKETING MODE";

    return Column(
      children: [
        Text(
          "Versin",
          style: TextStyle(
            color: activeColor.withOpacity(0.8),
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        Text(
          modeText,
          style: TextStyle(
            color: activeColor.withOpacity(0.8),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ListenableBuilder(
            listenable: rimasController,
            builder: (context, _) => TermometroFeedback(
              progressoEstrelas: rimasController.progressoEstrelas,
              progressoFogos: rimasController.progressoFogos,
              feedbackMentor: rimasController.feedbackMentor,
            ),
          ),
        ),
      ],
    );
  }
}