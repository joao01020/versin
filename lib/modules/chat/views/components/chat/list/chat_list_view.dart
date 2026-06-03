import 'package:flutter/material.dart';

import 'package:versin/modules/chat/views/components/chat/list/chat_message_bubble.dart';

import 'package:versin/modules/chat/views/widgets/chat_welcome_card.dart';

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

  const ChatListView({
    super.key,
    required this.isInitializing,
    required this.messages,
    required this.isAiTyping,
    required this.scrollController,
    required this.activeColor,
    this.secondsActive = 0,
  });

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
            if (index ==
                messages.length) {
              return _buildTypingIndicator();
            }

            final message = messages[index];
            final Widget? customWidget = message['customWidget'];

            return Padding(
              padding: const EdgeInsets.only(
                bottom: 12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ChatMessageBubble(
                    message: {
                      "role":
                          message["role"]?.toString() ??
                          "assistant",
                      "content":
                          message["content"]?.toString() ??
                          "",
                    },
                    activeColor: activeColor,
                    onAddRhyme:
                        (
                          word,
                        ) {
                          // Lógica de callback aqui
                        },
                  ),
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
            );
          },
    );
  }

  Widget _buildTypingIndicator() {
    String mainMessage = "Versin analisando...";
    String subMessage = "processando métrica e rimas...";

    if (secondsActive >
        5) {
      mainMessage = "Servidor acordando...";
      subMessage = "Otimizando rimas (Tempo: ${secondsActive}s)...";
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(
              8,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(
                0.05,
              ),
              borderRadius: BorderRadius.circular(
                12,
              ),
            ),
            child: SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor:
                    AlwaysStoppedAnimation<
                      Color
                    >(
                      activeColor.withOpacity(
                        0.4,
                      ),
                    ),
              ),
            ),
          ),
          const SizedBox(
            width: 12,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SÊNIOR: Efeito aplicado cirurgicamente apenas na palavra principal durante o loading
              NeonGlintText(
                text: mainMessage,
                baseColor: Colors.white.withOpacity(
                  0.85,
                ),
                glintColor: activeColor, // Usa o roxo neon dinâmico do estúdio
              ),
              const SizedBox(
                height: 2,
              ),
              Text(
                subMessage,
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- COMPONENTE SÊNIOR: NEON GLINT TEXT (EFEITO CHATGPT STYLE) ---

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
    // Controla a velocidade do ciclo do feixe de luz passando pela palavra (2.2 segundos para suavidade sutil)
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 2200,
      ),
    )..repeat(); // Repete infinitamente enquanto o loading estiver ativo
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
            return ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback:
                  (
                    bounds,
                  ) {
                    return LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      // Sênior: Mapeamento de paradas do gradiente que cria o feixe de luz passando da esquerda para a direita
                      stops: [
                        _animationController.value -
                            0.3,
                        _animationController.value,
                        _animationController.value +
                            0.3,
                      ],
                      colors: [
                        widget.baseColor,
                        widget.glintColor, // O reflexo roxo neon brilha no centro do feixe
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
