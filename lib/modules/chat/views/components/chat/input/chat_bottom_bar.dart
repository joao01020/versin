import 'package:flutter/material.dart';

import 'package:versin/modules/chat/conversation/controllers/chat_controller.dart';

// ============================================================
// CHAT BOTTOM BAR
// ============================================================

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

  // ============================================================
  // SUGESTÃO
  // ============================================================

  final bool showSuggestion;

  final Widget? suggestionWidget;

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
    this.showSuggestion = false,
    this.suggestionWidget,
  });

  // ============================================================
  // ETAPA
  // ============================================================

  bool get _isImagination =>
      creationStage ==
      ChatCreationStage.imagination;

  // ============================================================
  // POSSUI SUGESTÃO?
  // ============================================================

  bool get _hasSuggestion =>
      showSuggestion &&
      suggestionWidget !=
          null &&
      !_isImagination;

  // ============================================================
  // HINT
  // ============================================================

  String get _hintText {
    if (_isImagination) {
      return 'Descreva a cena, sensação ou palavras soltas...';
    }

    return 'Escreva sua letra...';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
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
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // ====================================================
          // CAMPO DE TEXTO + SUGESTÃO
          // ====================================================
          Expanded(
            child: AnimatedSize(
              duration: const Duration(
                milliseconds: 220,
              ),
              curve: Curves.easeOutCubic,
              alignment: Alignment.bottomCenter,
              child: AnimatedContainer(
                duration: const Duration(
                  milliseconds: 180,
                ),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.fromLTRB(
                  14,
                  _hasSuggestion
                      ? 8
                      : 0,
                  14,
                  0,
                ),
                decoration: BoxDecoration(
                  color: const Color(
                    0xFF1A1A1A,
                  ),
                  borderRadius: BorderRadius.circular(
                    24,
                  ),
                  border: Border.all(
                    color: _fieldBorderColor,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ==========================================
                    // SUGESTÃO DENTRO DO CAMPO
                    // ==========================================
                    AnimatedSwitcher(
                      duration: const Duration(
                        milliseconds: 180,
                      ),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder:
                          (
                            child,
                            animation,
                          ) {
                            final slide =
                                Tween<
                                      Offset
                                    >(
                                      begin: const Offset(
                                        0,
                                        0.15,
                                      ),
                                      end: Offset.zero,
                                    )
                                    .animate(
                                      CurvedAnimation(
                                        parent: animation,
                                        curve: Curves.easeOutCubic,
                                      ),
                                    );

                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: slide,
                                child: child,
                              ),
                            );
                          },
                      child: _hasSuggestion
                          ? Column(
                              key: const ValueKey(
                                'suggestion-visible',
                              ),
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                suggestionWidget!,

                                const SizedBox(
                                  height: 6,
                                ),

                                Container(
                                  height: 1,
                                  color: Colors.white.withValues(
                                    alpha: 0.045,
                                  ),
                                ),
                              ],
                            )
                          : const SizedBox(
                              key: ValueKey(
                                'suggestion-hidden',
                              ),
                            ),
                    ),

                    // ==========================================
                    // TEXTO
                    // ==========================================
                    TextField(
                      controller: messageController,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      minLines: 1,
                      maxLines: 4,
                      onChanged:
                          (
                            text,
                          ) {
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
                        height: 1.35,
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
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ====================================================
          // BOTÕES
          // ====================================================
          Padding(
            padding: const EdgeInsets.only(
              left: 8,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // ==============================================
                // MICROFONE
                // ==============================================
                if (onMicPressed !=
                    null)
                  _buildActionButton(
                    tooltip: 'Gravar voz',
                    icon: Icons.mic_none_rounded,
                    color: Colors.white54,
                    onPressed: onMicPressed!,
                  ),

                // ==============================================
                // ESPAÇO DO METRÔNOMO
                // ==============================================
                const SizedBox(
                  width: 50,
                ),

                // ==============================================
                // ENVIAR
                // ==============================================
                _buildActionButton(
                  tooltip: _isImagination
                      ? 'Continuar'
                      : 'Enviar',
                  icon: _isImagination
                      ? Icons.arrow_forward_rounded
                      : Icons.send_rounded,
                  color: activeColor,
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COR DA BORDA
  // ============================================================

  Color get _fieldBorderColor {
    if (_isImagination) {
      return activeColor.withValues(
        alpha: 0.12,
      );
    }

    if (_hasSuggestion) {
      return activeColor.withValues(
        alpha: 0.16,
      );
    }

    return Colors.white.withValues(
      alpha: 0.05,
    );
  }

  // ============================================================
  // BOTÃO DE AÇÃO
  // ============================================================

  Widget _buildActionButton({
    required String tooltip,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(
            22,
          ),
          child: SizedBox(
            width: 44,
            height: 48,
            child: Icon(
              icon,
              color: color,
              size: 27,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ENVIAR MENSAGEM
  // ============================================================

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
