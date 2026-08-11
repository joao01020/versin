import 'package:flutter/material.dart';

import 'package:versin/modules/chat/controllers/chat_controller.dart';

class ChatBottomBar
    extends
        StatelessWidget {
  final TextEditingController messageController;
  final dynamic rhymesController;
  final Color activeColor;

  final ChatCreationStage creationStage;

  final ValueChanged<
    String
  >
  onSend;

  final int currentSuggestionIndex;
  final ValueChanged<
    int
  >
  onUpdateSuggestionIndex;
  final ValueChanged<
    String
  >
  onAddRhyme;

  final VoidCallback? onMicPressed;

  const ChatBottomBar({
    super.key,
    required this.messageController,
    required this.rhymesController,
    required this.activeColor,
    required this.creationStage,
    required this.onSend,
    required this.currentSuggestionIndex,
    required this.onUpdateSuggestionIndex,
    required this.onAddRhyme,
    this.onMicPressed,
  });

  bool get _isImagination =>
      creationStage ==
      ChatCreationStage.imagination;

  String get _hintText {
    if (_isImagination) {
      return 'Descreva a cena, sensação ou palavras soltas...';
    }

    return 'Escreva sua letra...';
  }

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
          // =====================================================
          // CAMPO DE TEXTO
          // =====================================================
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
                  color: _isImagination
                      ? activeColor.withValues(
                          alpha: 0.12,
                        )
                      : Colors.white.withValues(
                          alpha: 0.05,
                        ),
                ),
              ),
              child: TextField(
                controller: messageController,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                maxLines: 1,
                onChanged:
                    (
                      text,
                    ) {
                      // Durante a descrição inicial não precisamos
                      // procurar rimas/autocomplete.
                      if (_isImagination) {
                        return;
                      }

                      rhymesController.onTextChanged(
                        text,
                      );
                    },
                onSubmitted:
                    (
                      _,
                    ) {
                      _sendMessage();
                    },
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: _hintText,
                  hintStyle: TextStyle(
                    color: _isImagination
                        ? Colors.white38
                        : Colors.white30,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),

          // =====================================================
          // BOTÕES
          // =====================================================
          Padding(
            padding: const EdgeInsets.only(
              left: 8,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // =================================================
                // MICROFONE
                // =================================================
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

                // =================================================
                // ESPAÇO DO METRÔNOMO
                // =================================================
                const SizedBox(
                  width: 50,
                ),

                // =================================================
                // ENVIAR
                // =================================================
                IconButton(
                  icon: Icon(
                    _isImagination
                        ? Icons.arrow_forward_rounded
                        : Icons.send_rounded,
                  ),
                  color: activeColor,
                  iconSize: 28,
                  tooltip: _isImagination
                      ? 'Continuar'
                      : 'Enviar',
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // ENVIAR MENSAGEM
  // =============================================================

  void _sendMessage() {
    final text = messageController.text.trim();

    if (text.isEmpty) {
      return;
    }

    onSend(
      text,
    );

    messageController.clear();

    if (!_isImagination) {
      rhymesController.clearSuggestions();
    }
  }
}
