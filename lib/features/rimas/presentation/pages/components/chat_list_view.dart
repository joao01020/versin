import 'package:flutter/material.dart';
// Importes corrigidos para apontar para a pasta de widgets global da feature
import 'package:versin/features/rimas/presentation/widgets/chat_welcome_card.dart';
import 'package:versin/features/rimas/presentation/widgets/chat_message_bubble.dart';

class ChatListView extends StatelessWidget {
  final bool isInitializing;
  final List<Map<String, String>> messages;
  final bool isAiTyping;
  final ScrollController scrollController;
  final Color activeColor;

  const ChatListView({
    super.key,
    required this.isInitializing,
    required this.messages,
    required this.isAiTyping,
    required this.scrollController,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    if (isInitializing) {
      return ChatWelcomeCard(activeColor: activeColor);
    }

    if (messages.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: messages.length + (isAiTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == messages.length) {
          return _buildTypingIndicator(activeColor);
        }
        return ChatMessageBubble(
          message: messages[index],
          activeColor: activeColor,
        );
      },
    );
  }

  Widget _buildTypingIndicator(Color color) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2, color: color),
          ),
          const SizedBox(width: 10),
          Text(
            "Versin analisando...",
            style: TextStyle(color: color.withOpacity(0.7), fontSize: 13),
          )
        ],
      ),
    );
  }
}