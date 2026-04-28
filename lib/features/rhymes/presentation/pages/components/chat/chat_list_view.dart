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
    if (isInitializing) {
      return ChatWelcomeCard(activeColor: activeColor);
    }

    if (messages.isEmpty && !isAiTyping) {
      return ChatWelcomeCard(activeColor: activeColor);
    }

    return ListView.builder(
      controller: scrollController,
      // AJUSTE CRÍTICO 1: clipBehavior none permite que o "X" flutuante apareça
      clipBehavior: Clip.none, 
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 80), // Aumentado o bottom para mais respiro
      itemCount: messages.length + (isAiTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == messages.length) {
          return _buildTypingIndicator(activeColor);
        }

        final message = messages[index];
        final Widget? customWidget = message['customWidget'];
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          // AJUSTE CRÍTICO 2: Column também deve permitir transbordamento
          mainAxisSize: MainAxisSize.min,
          children: [
            ChatMessageBubble(
              message: {
                "role": message["role"] ?? "assistant",
                "content": message["content"]?.toString() ?? "",
              },
              activeColor: activeColor,
            ),
            if (customWidget != null) 
              Padding(
                // AJUSTE CRÍTICO 3: Padding lateral para garantir que o widget customizado 
                // não encoste na borda da tela e o Stack tenha espaço para respirar
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
                child: customWidget,
              ),
          ],
        );
      },
    );
  }

  Widget _buildTypingIndicator(Color color) {
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
                style: const TextStyle(
                  color: Colors.white38, 
                  fontSize: 10,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}