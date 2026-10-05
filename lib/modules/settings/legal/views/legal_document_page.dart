import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class LegalDocumentPage extends StatelessWidget {
  final String title;
  final String markdown;

  const LegalDocumentPage({
    super.key,
    required this.title,
    required this.markdown,
  });

  static const Color _background = Color(0xFF0D0B1F);
  static const Color _surface = Color(0xFF17132D);
  static const Color _accent = Color(0xFFE040FB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              decoration: BoxDecoration(
                color: _surface.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
              ),
              child: Markdown(
                data: markdown,
                selectable: true,
                padding: const EdgeInsets.fromLTRB(26, 24, 26, 32),
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.65,
                  ),
                  h1: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                  h2: const TextStyle(
                    color: _accent,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    height: 1.45,
                  ),
                  h3: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  strong: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  listBullet: const TextStyle(color: _accent, fontSize: 14),
                  blockquote: TextStyle(
                    color: Colors.white.withValues(alpha: 0.64),
                    fontSize: 13,
                    height: 1.55,
                  ),
                  code: TextStyle(
                    color: _accent,
                    backgroundColor: Colors.black.withValues(alpha: 0.22),
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
