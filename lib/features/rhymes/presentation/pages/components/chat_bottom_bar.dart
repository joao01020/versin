import 'package:flutter/material.dart';
import 'package:versin/features/rhymes/presentation/controller/rhymes_controller.dart';
import 'package:versin/features/rhymes/presentation/widgets/ai_suggestion/ai_suggestion_balloon.dart';
import 'package:versin/features/rhymes/presentation/widgets/chat_input_area.dart';

class ChatBottomBar extends StatelessWidget {
  final TextEditingController messageController;
  final RhymesController rhymesController;
  final Color activeColor;
  final bool isRhymeMode;
  final VoidCallback onSend;
  final int currentSuggestionIndex;
  final Function(int) onUpdateSuggestionIndex;

  const ChatBottomBar({
    super.key,
    required this.messageController,
    required this.rhymesController,
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
      listenable: rhymesController,
      builder: (context, _) {
        // Sincronizado com: List<String> get suggestionsList
        final rimas = rhymesController.suggestionsList; 
        if (rimas.isEmpty) return const SizedBox.shrink();

        // Garante que o índice não estoure a lista se ela diminuir
        final safeIndex = currentSuggestionIndex >= rimas.length ? 0 : currentSuggestionIndex;

        return AiSuggestionBalloon(
          suggestion: rimas[safeIndex],
          isLoading: rhymesController.isLoading, // Sincronizado com: bool get isLoading
          onTap: () {
            messageController.text =
                "${messageController.text} ${rimas[safeIndex]} "
                    .trimLeft();
            messageController.selection = TextSelection.fromPosition(
              TextPosition(offset: messageController.text.length),
            );
            // Sincronizado com: void registerUsedRhyme(String rhyme)
            rhymesController.registerUsedRhyme(rimas[safeIndex]);
          },
          onNext: rimas.length > 1
              ? () {
                  final nextIndex = (safeIndex + 1) % rimas.length;
                  onUpdateSuggestionIndex(nextIndex); // Removido toInt() pois length é int
                }
              : null,
          onDismiss: () => rhymesController.clearSuggestions(), // Sincronizado com: void clearSuggestions()
        );
      },
    );
  }
}