import 'package:flutter/material.dart';
import 'package:versin/features/rhymes/presentation/controller/rhymes_controller.dart';
import 'package:versin/features/rhymes/presentation/widgets/thermometer_gamification/thermometer_widget.dart';

class ChatHeader extends StatelessWidget {
  final Color activeColor;
  final RhymesController rhymesController;
  final bool isRhymeMode, isComposeMode, isListMode, isMarketingMode;

  const ChatHeader({
    super.key,
    required this.activeColor,
    required this.rhymesController,
    required this.isRhymeMode,
    required this.isComposeMode,
    required this.isListMode,
    required this.isMarketingMode,
  });

  @override
  Widget build(BuildContext context) {
    // Texto do modo exibido no cabeçalho (Interface em Português)
    String modeText = "MODO LIVRE";
    if (isRhymeMode) modeText = "MODO RIMA";
    else if (isComposeMode) modeText = "MODO COMPOR";
    else if (isListMode) modeText = "MODO LISTAR";
    else if (isMarketingMode) modeText = "MODO MARKETING";

    return Column(
      children: [
        const Text(
          "Versin",
          style: TextStyle(
            color: Colors.white,
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
            listenable: rhymesController,
            builder: (context, _) => ThermometerFeedback(
              // Variáveis em inglês sincronizadas com o RhymesController e o Widget de Termômetro
              starProgress: rhymesController.starProgress,
              fireProgress: rhymesController.fireProgress,
              mentorFeedback: rhymesController.mentorFeedback,
            ),
          ),
        ),
      ],
    );
  }
}