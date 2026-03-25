import 'package:flutter/material.dart';
import 'package:versin/features/rimas/presentation/controller/rimas_controller.dart';
// Importes corrigidos
import 'package:versin/features/rimas/presentation/widgets/ai_suggestion/ai_suggestion_balloon.dart';
import 'package:versin/features/rimas/presentation/widgets/chat_input_area.dart';

class ChatBottomBar extends StatelessWidget {
  final TextEditingController messageController;
  final RimasController rimasController;
  final Color activeColor;
  final bool isRhymeMode;
  final VoidCallback onSend;
  final int currentSuggestionIndex;
  final Function(int) onUpdateSuggestionIndex; // Nome corrigido aqui

  const ChatBottomBar({
    super.key,
    required this.messageController,
    required this.rimasController,
    required this.activeColor,
    required this.isRhymeMode,
    required this.onSend,
    required this.currentSuggestionIndex,
    required this.onUpdateSuggestionIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSuggestionBalloon(),
        const SizedBox(height: 10),
        ChatInputArea(
          controller: messageController,
          onSend: onSend,
          activeColor: activeColor,
          hintText: isRhymeMode ? "Buscar rima..." : "Manda o sentimento...",
        ),
      ],
    );
  }

  Widget _buildSuggestionBalloon() {
    return ListenableBuilder(
      listenable: rimasController,
      builder: (context, _) {
        final rimas = rimasController.listaSugestoes;
        if (rimas.isEmpty) return const SizedBox.shrink();

        return AiSuggestionBalloon(
          suggestion: rimas[currentSuggestionIndex],
          isLoading: rimasController.carregando,
          onTap: () {
            messageController.text =
                "${messageController.text} ${rimas[currentSuggestionIndex]} "
                    .trimLeft();
            messageController.selection = TextSelection.fromPosition(
              TextPosition(offset: messageController.text.length),
            );
            rimasController.registrarRimaUsada(rimas[currentSuggestionIndex]);
          },
          onNext: rimas.length > 1
              ? () => onUpdateSuggestionIndex((currentSuggestionIndex + 1) % rimas.length)
              : null,
          onDismiss: () => rimasController.limparSugestao(),
        );
      },
    );
  }
}