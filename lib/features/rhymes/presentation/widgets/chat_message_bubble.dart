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
  // Lista para controlar quais rimas já foram adicionadas e devem sumir
  final Set<String> _addedWords = {};

  @override
  Widget build(BuildContext context) {
    final isUser = widget.message['role'] == 'user';
    final content = widget.message['content'] ?? "";

    // Se for o indicador de modo, renderizamos um Badge elegante em vez de uma bolha
    if (content.contains("MODO RIMA")) {
      return _buildModeBadge();
    }

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
              builders: {
                'word': RhymeTagBuilder(
                  activeColor: widget.activeColor, 
                  addedWords: _addedWords,
                  onTap: (word) {
                    setState(() => _addedWords.add(word)); // Faz sumir da tela
                    widget.onAddRhyme?.call(word);
                  },
                ),
              },
              inlineSyntaxes: [RhymeSyntax()],
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(
                  color: widget.activeColor.withOpacity(0.9), 
                  fontSize: 16, 
                  fontFamily: 'monospace'
                ),
              ),
            ),
      ),
    );
  }

  // Widget para o "Badge" de modo que resolve o bug visual da imagem
  Widget _buildModeBadge() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: widget.activeColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: widget.activeColor.withOpacity(0.3)),
        ),
        child: Text(
          "• MODO MINERAÇÃO ATIVO •",
          style: TextStyle(
            color: widget.activeColor,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
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
  final Set<String> addedWords;
  final Function(String) onTap;

  RhymeTagBuilder({
    required this.activeColor, 
    required this.addedWords,
    required this.onTap
  });

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final textContent = element.textContent;
    
    // Separa a rima do significado (Ex: Arroz --> Cereal)
    final parts = textContent.split('-->');
    final word = parts[0].trim();
    final meaning = parts.length > 1 ? parts[1].trim() : "";

    // Se a palavra já foi clicada, ela some (SizedBox.shrink)
    if (addedWords.contains(word)) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ActionChip(
            avatar: const Icon(Icons.add, size: 14, color: Colors.black),
            label: Text(word, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            backgroundColor: activeColor,
            onPressed: () => onTap(word),
          ),
          if (meaning.isNotEmpty) ...[
            const SizedBox(width: 8),
            Icon(Icons.arrow_right_alt, size: 18, color: activeColor.withOpacity(0.5)),
            const SizedBox(width: 4),
            Text(
              meaning,
              style: TextStyle(
                color: activeColor.withOpacity(0.6),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}