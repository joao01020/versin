import 'package:flutter/material.dart';

import 'package:versin/features/rhymes/presentation/widgets/chat/welcome_card/chat_welcome_card.dart';
import 'package:versin/features/rhymes/presentation/widgets/chat/chat_message_bubble.dart';
class ChatListView extends StatelessWidget {
  final bool isInitializing;
  final List<Map<String, dynamic>> messages;
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

        final message = messages[index];
        
        // CORREÇÃO: Verificação segura para saber se o campo realmente contém um Widget
        final dynamic customData = message['customWidget'];
        final Widget? customWidget = (customData is Widget) ? customData : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ChatMessageBubble(
              // Convertemos os valores para String para o Bubble, exceto campos complexos
              message: message.map((k, v) => MapEntry(k, v is String ? v : v.toString())),
              activeColor: activeColor,
            ),
            // Só renderiza se for de fato um Widget, evitando o erro de cast
            if (customWidget != null) 
              Padding(
                padding: const EdgeInsets.only(left: 45, top: 8, bottom: 12),
                child: customWidget,
              ),
          ],
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