import 'package:flutter/material.dart';
import 'package:versin/features/rhymes/presentation/widgets/chat/welcome_card/chat_welcome_card.dart';
import 'package:versin/features/rhymes/presentation/widgets/chat/chat_message_bubble.dart';

class ChatListView extends StatelessWidget {
  final bool isInitializing;
  final List<Map<String, dynamic>> messages;
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
  Widget build(BuildContext context) {
    // Exibe o card de boas-vindas se estiver inicializando ou se o chat estiver vazio
    if (isInitializing || (messages.isEmpty && !isAiTyping)) {
      return ChatWelcomeCard(activeColor: activeColor);
    }

    return ListView.builder(
      controller: scrollController,
      // clipBehavior hardEdge garante que a lista respeite os limites do SafeAre/Expanded
      clipBehavior: Clip.hardEdge,
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      // Padding bottom de 120 para garantir que a última linha da letra não fique coberta pela BottomBar
      padding: const EdgeInsets.fromLTRB(16, 5, 16, 120),
      itemCount: messages.length + (isAiTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == messages.length) {
          return _buildTypingIndicator(activeColor);
        }

        final message = messages[index];
        final Widget? customWidget = message['customWidget'];

        return Padding(
          // Espaçamento vertical entre blocos de mensagens e versos
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ChatMessageBubble(
                message: {
                  "role": message["role"] ?? "assistant",
                  // Garante que o conteúdo preserve as quebras de linha (\n) do editor
                  "content": message["content"]?.toString() ?? "",
                },
                activeColor: activeColor,
              ),
              if (customWidget != null)
                Padding(
                  // Margem específica para widgets injetados (ex: MoodSelectorSlider)
                  padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
                  child: customWidget,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTypingIndicator(Color color) {
    // Feedback dinâmico para o usuário enquanto a IA processa os versos
    String mainMessage = "Versin analisando...";
    String subMessage = "processando métrica e rimas...";

    if (secondsActive > 5) {
      mainMessage = "Servidor acordando...";
      subMessage = "Otimizando rimas (Tempo: ${secondsActive}s)...";
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white24),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                mainMessage,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                subMessage,
                style: const TextStyle(color: Colors.white38, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}