import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

class ChatMessageBubble extends StatefulWidget {
  final Map<String, dynamic> message;
  final Color activeColor;
  final Function(String word)? onAddRhyme;
  
  // Parâmetros mantidos no construtor para evitar erros de compilação na ChatPage
  final bool isBpmPlaying;
  final int currentBpm;
  final VoidCallback onToggleBpm;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.activeColor,
    required this.isBpmPlaying,
    required this.currentBpm,
    required this.onToggleBpm,
    this.onAddRhyme,
  });

  @override
  State<ChatMessageBubble> createState() => _ChatMessageBubbleState();
}

class _ChatMessageBubbleState extends State<ChatMessageBubble> {
  @override
  Widget build(BuildContext context) {
    final isUser = widget.message['role'] == 'user';
    final content = widget.message['content'] ?? "";

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        decoration: BoxDecoration(
          // Fundo para o usuário, transparente para a IA conforme seu estilo original
          color: isUser ? const Color(0xFF2D2D2D) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            isUser
                ? Text(
                    content,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  )
                : MarkdownBody(
                    data: content,
                    builders: {
                      'word': RhymeTagBuilder(
                        activeColor: widget.activeColor,
                        onTap: (word) => widget.onAddRhyme?.call(word),
                      ),
                    },
                    inlineSyntaxes: [RhymeSyntax()],
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class RhymeSyntax extends md.InlineSyntax {
  RhymeSyntax() : super(r'\[WORD:(.*?)\]');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final word = match.group(1);
    if (word != null) {
      parser.addNode(md.Element.text('word', word));
    }
    return true;
  }
}

class RhymeTagBuilder extends MarkdownElementBuilder {
  final Color activeColor;
  final Function(String) onTap;

  RhymeTagBuilder({required this.activeColor, required this.onTap});

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final textContent = element.textContent;
    final parts = textContent.split('-->');
    final word = parts[0].trim();

    return InkWell(
      onTap: () => onTap(word),
      borderRadius: BorderRadius.circular(4),
      child: Text(
        word,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          decoration: TextDecoration.underline,
          decorationColor: Colors.white24,
        ),
      ),
    );
  }
}