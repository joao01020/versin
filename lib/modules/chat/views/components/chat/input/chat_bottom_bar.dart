import 'package:flutter/material.dart';

class ChatBottomBar
    extends
        StatelessWidget {
  final TextEditingController messageController;
  final dynamic rhymesController;
  final Color activeColor;
  // CORREÇÃO: Variável isRhymeMode removida daqui
  final Function(
    String,
  )
  onSend;
  final int currentSuggestionIndex;
  final Function(
    int,
  )
  onUpdateSuggestionIndex;
  final Function(
    String,
  )
  onAddRhyme;
  final VoidCallback? onMicPressed;

  const ChatBottomBar({
    super.key,
    required this.messageController,
    required this.rhymesController,
    required this.activeColor,
    // CORREÇÃO: Removido o required this.isRhymeMode daqui
    required this.onSend,
    required this.currentSuggestionIndex,
    required this.onUpdateSuggestionIndex,
    required this.onAddRhyme,
    this.onMicPressed,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: const BoxDecoration(
        color: Color(
          0xFF141414,
        ),
        border: Border(
          top: BorderSide(
            color: Colors.white10,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Campo de Texto Principal
          Expanded(
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              decoration: BoxDecoration(
                color: const Color(
                  0xFF1A1A1A,
                ),
                borderRadius: BorderRadius.circular(
                  24,
                ),
                border: Border.all(
                  color: Colors.white.withValues(
                    alpha: 0.05,
                  ),
                ),
              ),
              child: TextField(
                controller: messageController,
                // Agora o campo avisa o controller sobre qualquer texto digitado!
                onChanged:
                    (
                      text,
                    ) {
                      rhymesController.onTextChanged(
                        text,
                      );
                    },
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                ),
                decoration: const InputDecoration(
                  hintText: "Escreva sua rima...",
                  hintStyle: TextStyle(
                    color: Colors.white30,
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),

          // GRUPO DE BOTÕES
          Padding(
            padding: const EdgeInsets.only(
              left: 8,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Microfone
                if (onMicPressed !=
                    null)
                  IconButton(
                    icon: const Icon(
                      Icons.mic_none_rounded,
                    ),
                    color: Colors.white54,
                    iconSize: 28,
                    onPressed: onMicPressed,
                  ),

                // 2. ESPAÇO RESERVADO PARA O METRÔNOMO
                const SizedBox(
                  width: 50,
                ),

                // 3. Botão de Enviar
                IconButton(
                  icon: const Icon(
                    Icons.send_rounded,
                  ),
                  color: activeColor,
                  iconSize: 28,
                  onPressed: () {
                    final text = messageController.text.trim();
                    if (text.isNotEmpty) {
                      onSend(
                        text,
                      );
                      messageController.clear();
                      // Limpa as sugestões quando a mensagem é enviada
                      rhymesController.clearSuggestions();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
