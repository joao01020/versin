import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ChatMessageBubble extends StatelessWidget {
  final Map<String, String> message;
  final Color activeColor;

  const ChatMessageBubble({
    super.key, 
    required this.message, 
    required this.activeColor
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message['role'] == 'user';
    final content = message['content'] ?? "";

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF2D2D2D) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: isUser 
          ? Text(content, style: const TextStyle(color: Colors.white, fontSize: 15))
          : MarkdownBody(
              data: content,
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(color: activeColor.withOpacity(0.9), fontSize: 16, fontFamily: 'monospace'),
                strong: TextStyle(color: activeColor, fontWeight: FontWeight.bold),
              ),
            ),
      ),
    );
  }
}