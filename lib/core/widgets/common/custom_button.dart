import 'package:flutter/material.dart';
import 'package:versin/features/rhymes/presentation/controller/rhymes_controller.dart';

// Componentes agora organizados no módulo de Chat
import 'suggestion_balloon/suggestion_balloon.dart';
import 'chat_input_area.dart';

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
          activeColor: Colors.white70,
          hintText: isRhymeMode ? "Filtrando vocabulário..." : "Escreva seus versos...",
          onAddRhyme: onAddRhyme,
        ),
      ],
    );
  }

  Widget _buildSuggestionBalloon() {
    return ListenableBuilder(
      listenable: rhymesController,
      builder: (context, _) {
        final rimas = rhymesController.suggestions;
        
        if (rimas.isEmpty) return const SizedBox.shrink();

        final safeIndex = currentSuggestionIndex % rimas.length;

        return SuggestionBalloon(
          suggestion: rimas[safeIndex],
          onTap: () {
            // DELEGAÇÃO PURA: A view não decide como o texto é inserido
            onAddRhyme?.call(rimas[safeIndex]);
            rhymesController.clearSuggestions();
          },
          onNext: () {
            onUpdateSuggestionIndex((safeIndex + 1) % rimas.length);
          },
          onPrevious: () {
            final prevIndex = (safeIndex - 1 + rimas.length) % rimas.length;
            onUpdateSuggestionIndex(prevIndex);
          },
          onDismiss: () => rhymesController.clearSuggestions(),
          onAddCommand: () {
            // Implementar conforme necessário no Controller
          },
        );
      },
    );
  }
}