import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

class ChatMessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final Color activeColor;
  final Function(String word)? onAddRhyme;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.activeColor,
    this.onAddRhyme,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message['role'] == 'user';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF2D2D2D) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: isUser ? _buildUserContent() : _buildAiContent(),
      ),
    );
  }

  Widget _buildUserContent() {
    return Text(
      message['content'] ?? "",
      style: const TextStyle(color: Colors.white, fontSize: 15),
    );
  }

  Widget _buildAiContent() {
    return MarkdownBody(
      data: message['content'] ?? "",
      builders: {
        'word': RhymeTagBuilder(
          activeColor: activeColor,
          onTap: (word) => onAddRhyme?.call(word),
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
    );
  }
}

// --- Lógica de Parsing (Mantida pois é correta) ---

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
    final word = element.textContent.trim();
    return InkWell(
      onTap: () => onTap(word),
      borderRadius: BorderRadius.circular(4),
      child: Text(
        word,
        style: TextStyle(
          color: activeColor,
          fontWeight: FontWeight.bold,
          decoration: TextDecoration.underline,
          decorationColor: activeColor.withOpacity(0.5),
        ),
      ),
    );
  }
}