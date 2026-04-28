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
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      itemCount: messages.length + (isAiTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == messages.length) {
          return _buildTypingIndicator(activeColor);
        }

        final message = messages[index];
        
        // REMOVIDO: A lógica que injetava customWidgets (botões roxos) foi ignorada aqui
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ChatMessageBubble(
              message: message.map((k, v) => MapEntry(k, v is String ? v : v.toString())),
              activeColor: activeColor,
            ),
            // O espaço reservado para o customWidget foi removido para manter o chat limpo
          ],
        );
      },
    );
  }

  Widget _buildTypingIndicator(Color color) {
    String mainMessage = "Versin analisando...";
    String subMessage = "processando métrica e rimas...";

    if (secondsActive > 5) {
      mainMessage = "Acordando servidor...";
      subMessage = "O Render está subindo, aguarde (${secondsActive}s)...";
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
              // Cor neutra para o fundo do loading
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2, 
                // Cor do carregamento mais discreta
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
                style: TextStyle(
                  color: Colors.white70, 
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                subMessage,
                style: TextStyle(
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