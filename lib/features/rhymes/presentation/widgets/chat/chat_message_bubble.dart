import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

class ChatMessageBubble extends StatefulWidget {
  final Map<String, String> message;
  final Color activeColor;
  final Function(String word)? onAddRhyme;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.activeColor,
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
          // Fundo escuro para o usuário e transparente para a IA (estilo clean)
          color: isUser ? const Color(0xFF2D2D2D) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: isUser
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
      ),
    );
  }
}

// O Syntax continua existindo para não quebrar o Markdown, mas o Builder mudou
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

    // Limpa a palavra caso venha com o significado (ex: amor --> afeto)
    final parts = textContent.split('-->');
    final word = parts[0].trim();

    // RETIRADO: ActionChip, Ícone de "+" e Fundo Roxo.
    // AGORA: Apenas um texto clicável e elegante.
    return InkWell(
      onTap: () => onTap(word),
      borderRadius: BorderRadius.circular(4),
      child: Text(
        word,
        style: const TextStyle(
          color: Colors.white, // Texto branco
          fontWeight: FontWeight.bold,
          decoration: TextDecoration
              .underline, // Sublinhado discreto para indicar clique
          decorationColor: Colors.white24,
        ),
      ),
    );
  }
}
