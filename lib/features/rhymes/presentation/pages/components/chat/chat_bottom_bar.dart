import 'package:flutter/material.dart';
import 'package:versin/features/rhymes/presentation/controller/rhymes_controller.dart';
import 'package:versin/features/rhymes/presentation/widgets/suggestion_balloon/suggestion_balloon.dart';
import 'package:versin/features/rhymes/presentation/widgets/chat/chat_input_area.dart';

class ChatBottomBar extends StatelessWidget {
  final TextEditingController messageController;
  final RhymesController rhymesController;
  final Color activeColor;
  final bool isRhymeMode;
  final VoidCallback onSend;
  final int currentSuggestionIndex;
  final Function(int) onUpdateSuggestionIndex;
  final Function(String)? onAddRhyme;

  const ChatBottomBar({
    super.key,
    required this.messageController,
    required this.rhymesController,
    required this.activeColor,
    required this.isRhymeMode,
    required this.onSend,
    required this.currentSuggestionIndex,
    required this.onUpdateSuggestionIndex,
    this.onAddRhyme,
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
          // Mantendo a estética clean para o foco na escrita dos versos
          activeColor: Colors.white70, 
          hintText: isRhymeMode
              ? "Filtrando vocabulário..."
              : "Escreva seus versos...",
          onAddRhyme: onAddRhyme,
          // Nota técnica: keyboardType e maxLines foram movidos para a 
          // ChatInputArea para evitar erros de parâmetros não definidos.
        ),
      ],
    );
  }

  Widget _buildSuggestionBalloon() {
    return ListenableBuilder(
      listenable: rhymesController,
      builder: (context, _) {
        final rimas = rhymesController.suggestionsList;
        if (rimas.isEmpty) return const SizedBox.shrink();

        final safeIndex = currentSuggestionIndex >= rimas.length
            ? 0
            : currentSuggestionIndex;

        return SuggestionBalloon(
          suggestion: rimas[safeIndex],
          isLoading: rhymesController.isLoading,
          onTap: () {
            if (onAddRhyme != null) {
              onAddRhyme!(rimas[safeIndex]);
            } else {
              final currentText = messageController.text;
              // Adiciona a sugestão e posiciona o cursor ao final para compor
              messageController.text = "$currentText ${rimas[safeIndex]} ";
              messageController.selection = TextSelection.fromPosition(
                TextPosition(offset: messageController.text.length),
              );
            }
            rhymesController.clearSuggestions();
          },
          onNext: rimas.length > 1
              ? () {
                  final nextIndex = (safeIndex + 1) % rimas.length;
                  onUpdateSuggestionIndex(nextIndex);
                }
              : null,
          onPrevious: rimas.length > 1
              ? () {
                  final prevIndex = (safeIndex - 1 < 0)
                      ? rimas.length - 1
                      : safeIndex - 1;
                  onUpdateSuggestionIndex(prevIndex);
                }
              : null,
          onDismiss: () => rhymesController.clearSuggestions(),
        );
      },
    );
  }
}