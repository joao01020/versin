import 'package:flutter/material.dart';

import 'package:versin/modules/chat/views/components/chat/list/chat_message_bubble.dart';
import 'package:versin/modules/chat/views/components/chat/message/animated_chat_message.dart';
import 'package:versin/modules/chat/views/components/chat/message/typing_indicator.dart';
import 'package:versin/modules/chat/views/widgets/chat_welcome_card.dart';

// ============================================================
// CHAT LIST VIEW
// ============================================================

class ChatListView
    extends
        StatelessWidget {
  final bool isInitializing;

  final List<
    Map<
      String,
      dynamic
    >
  >
  messages;

  final bool isAiTyping;

  final ScrollController scrollController;

  final Color activeColor;

  final int secondsActive;

  // ============================================================
  // ADICIONAR RIMA
  // ============================================================

  final ValueChanged<
    String
  >
  onAddRhyme;

  // ============================================================
  // METRÔNOMO
  // ============================================================

  final bool isBpmPlaying;

  final int currentBpm;

  final VoidCallback onToggleBpm;

  const ChatListView({
    super.key,
    required this.isInitializing,
    required this.messages,
    required this.isAiTyping,
    required this.scrollController,
    required this.activeColor,
    required this.onAddRhyme,
    required this.isBpmPlaying,
    required this.currentBpm,
    required this.onToggleBpm,
    this.secondsActive = 0,
  });

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    if (isInitializing ||
        (messages.isEmpty &&
            !isAiTyping)) {
      return ChatWelcomeCard(
        activeColor: activeColor,
      );
    }

    return ListView.builder(
      controller: scrollController,

      clipBehavior: Clip.hardEdge,

      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),

      padding: const EdgeInsets.fromLTRB(
        16,
        5,
        16,
        120,
      ),

      itemCount:
          messages.length +
          (isAiTyping
              ? 1
              : 0),

      itemBuilder:
          (
            context,
            index,
          ) {
            // ======================================================
            // IA DIGITANDO
            // ======================================================

            if (isAiTyping &&
                index ==
                    messages.length) {
              return _buildTypingIndicator();
            }

            // ======================================================
            // MENSAGEM
            // ======================================================

            final message = messages[index];

            final role =
                message['role']?.toString() ??
                'assistant';

            final isUser =
                role ==
                'user';

            final customWidget =
                message['customWidget']
                    as Widget?;

            // ======================================================
            // KEY ESTÁVEL
            // ======================================================

            final messageKey = ValueKey(
              '${message['timestamp'] ?? index}'
              '-${message['content']}',
            );

            return AnimatedChatMessage(
              key: messageKey,

              isUser: isUser,

              child: Padding(
                padding: const EdgeInsets.only(
                  bottom: 12,
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  mainAxisSize: MainAxisSize.min,

                  children: [
                    // =================================================
                    // BOLHA DA MENSAGEM
                    // =================================================
                    ChatMessageBubble(
                      message: {
                        'role': role,

                        'content':
                            message['content']?.toString() ??
                            '',
                      },

                      activeColor: activeColor,

                      // ===============================================
                      // ADICIONAR RIMA
                      // ===============================================
                      onAddRhyme: onAddRhyme,

                      // ===============================================
                      // METRÔNOMO
                      // ===============================================
                      isBpmPlaying: isBpmPlaying,

                      currentBpm: currentBpm,

                      onToggleBpm: onToggleBpm,
                    ),

                    // =================================================
                    // WIDGET CUSTOMIZADO
                    // =================================================
                    if (customWidget !=
                        null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          8,
                          12,
                          8,
                          8,
                        ),

                        child: customWidget,
                      ),
                  ],
                ),
              ),
            );
          },
    );
  }

  // ============================================================
  // INDICADOR DA IA
  // ============================================================

  Widget _buildTypingIndicator() {
    final isSlow =
        secondsActive >
        5;

    final mainMessage = isSlow
        ? 'Servidor acordando...'
        : 'Versin analisando...';

    final subMessage = isSlow
        ? 'Otimizando rimas (Tempo: ${secondsActive}s)...'
        : 'processando métrica e rimas...';

    return AnimatedChatMessage(
      isUser: false,

      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,

          vertical: 12,
        ),

        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,

          children: [
            // ==================================================
            // TRÊS PONTOS
            // ==================================================
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 11,

                vertical: 10,
              ),

              decoration: BoxDecoration(
                color: Colors.white.withValues(
                  alpha: 0.05,
                ),

                borderRadius: BorderRadius.circular(
                  12,
                ),

                border: Border.all(
                  color: activeColor.withValues(
                    alpha: 0.08,
                  ),
                ),
              ),

              child: TypingIndicator(
                color: activeColor,
              ),
            ),

            const SizedBox(
              width: 12,
            ),

            // ==================================================
            // TEXTO
            // ==================================================
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                mainAxisSize: MainAxisSize.min,

                children: [
                  NeonGlintText(
                    text: mainMessage,

                    baseColor: Colors.white.withValues(
                      alpha: 0.85,
                    ),

                    glintColor: activeColor,
                  ),

                  const SizedBox(
                    height: 2,
                  ),

                  Text(
                    subMessage,

                    maxLines: 1,

                    overflow: TextOverflow.ellipsis,

                    style: const TextStyle(
                      color: Colors.white38,

                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// NEON GLINT TEXT
// ============================================================

class NeonGlintText
    extends
        StatefulWidget {
  final String text;

  final Color baseColor;

  final Color glintColor;

  const NeonGlintText({
    super.key,
    required this.text,
    required this.baseColor,
    required this.glintColor,
  });

  @override
  State<
    NeonGlintText
  >
  createState() => _NeonGlintTextState();
}

// ============================================================
// NEON GLINT TEXT STATE
// ============================================================

class _NeonGlintTextState
    extends
        State<
          NeonGlintText
        >
    with
        SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,

      duration: const Duration(
        milliseconds: 2200,
      ),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();

    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return AnimatedBuilder(
      animation: _animationController,

      builder:
          (
            context,
            child,
          ) {
            final value = _animationController.value;

            final start =
                (value -
                        0.3)
                    .clamp(
                      0.0,
                      1.0,
                    );

            final middle = value.clamp(
              0.0,
              1.0,
            );

            final end =
                (value +
                        0.3)
                    .clamp(
                      0.0,
                      1.0,
                    );

            return ShaderMask(
              blendMode: BlendMode.srcIn,

              shaderCallback:
                  (
                    bounds,
                  ) {
                    return LinearGradient(
                      begin: Alignment.topLeft,

                      end: Alignment.bottomRight,

                      stops: [
                        start,
                        middle,
                        end,
                      ],

                      colors: [
                        widget.baseColor,

                        widget.glintColor,

                        widget.baseColor,
                      ],
                    ).createShader(
                      bounds,
                    );
                  },

              child: Text(
                widget.text,

                style: const TextStyle(
                  fontSize: 13,

                  fontWeight: FontWeight.w600,

                  letterSpacing: 0.3,
                ),
              ),
            );
          },
    );
  }
}
