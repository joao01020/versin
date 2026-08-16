import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

// ============================================================
// CHAT MESSAGE BUBBLE
// ============================================================

class ChatMessageBubble
    extends
        StatefulWidget {
  final Map<
    String,
    dynamic
  >
  message;

  final Color activeColor;

  final Function(
    String word,
  )?
  onAddRhyme;

  // ============================================================
  // METRÔNOMO
  // ============================================================

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
  State<
    ChatMessageBubble
  >
  createState() => _ChatMessageBubbleState();
}

// ============================================================
// STATE
// ============================================================

class _ChatMessageBubbleState
    extends
        State<
          ChatMessageBubble
        > {
  String _selectedText = '';

  // ============================================================
  // HELPERS
  // ============================================================

  bool get _isUser =>
      widget.message['role'] ==
      'user';

  String get _content =>
      widget.message['content']?.toString() ??
      '';

  bool get _canAddSelection =>
      !_isUser &&
      widget.onAddRhyme !=
          null &&
      _selectedText.trim().isNotEmpty;

  // ============================================================
  // NORMALIZAR TEXTO
  // ============================================================

  String _normalizeSelectedText(
    String value,
  ) {
    var normalized = value
        .replaceAll(
          RegExp(
            r'\s+',
          ),
          ' ',
        )
        .trim();

    // Remove pontuação somente das extremidades.
    //
    // Exemplos:
    //
    // "amor," -> amor
    // "(vida)" -> vida

    normalized = normalized.replaceAll(
      RegExp(
        r'^[\s\p{P}]+|[\s\p{P}]+$',
        unicode: true,
      ),
      '',
    );

    return normalized.trim();
  }

  // ============================================================
  // SELEÇÃO
  // ============================================================

  void _handleSelectionChanged(
    SelectedContent? selectedContent,
  ) {
    final selected = _normalizeSelectedText(
      selectedContent?.plainText ??
          '',
    );

    if (_selectedText ==
        selected) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(
      () {
        _selectedText = selected;
      },
    );
  }

  // ============================================================
  // ADICIONAR TEXTO SELECIONADO
  // ============================================================

  void _addSelectedText(
    BuildContext context,
  ) {
    if (!_canAddSelection) {
      return;
    }

    final selected = _normalizeSelectedText(
      _selectedText,
    );

    if (selected.isEmpty) {
      return;
    }

    widget.onAddRhyme?.call(
      selected,
    );

    ContextMenuController.removeAny();

    _showAddedMessage(
      context,
      selected,
    );

    if (mounted) {
      setState(
        () {
          _selectedText = '';
        },
      );
    }
  }

  // ============================================================
  // ADICIONAR TAG [WORD:]
  // ============================================================

  void _addRhymeTag(
    BuildContext context,
    String word,
  ) {
    final normalized = _normalizeSelectedText(
      word,
    );

    if (normalized.isEmpty ||
        widget.onAddRhyme ==
            null) {
      return;
    }

    widget.onAddRhyme?.call(
      normalized,
    );

    _showAddedMessage(
      context,
      normalized,
    );
  }

  // ============================================================
  // FEEDBACK
  // ============================================================

  void _showAddedMessage(
    BuildContext context,
    String value,
  ) {
    if (!mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.maybeOf(
      context,
    );

    if (messenger ==
        null) {
      return;
    }

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(
            milliseconds: 1100,
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(
            0xFF1B1B1B,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              12,
            ),
          ),
          content: Row(
            children: [
              Icon(
                Icons.add_circle_outline_rounded,
                color: widget.activeColor,
                size: 17,
              ),

              const SizedBox(
                width: 8,
              ),

              Expanded(
                child: Text(
                  '"$value" adicionado à lista',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  // ============================================================
  // MENU DO BOTÃO DIREITO
  // ============================================================

  Widget _buildContextMenu(
    BuildContext context,
    SelectableRegionState selectionState,
  ) {
    final items =
        List<
          ContextMenuButtonItem
        >.from(
          selectionState.contextMenuButtonItems,
        );

    if (_canAddSelection) {
      items.insert(
        0,
        ContextMenuButtonItem(
          label: '+ Adicionar à lista',
          onPressed: () {
            _addSelectedText(
              context,
            );
          },
        ),
      );
    }

    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: selectionState.contextMenuAnchors,
      buttonItems: items,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Align(
      alignment: _isUser
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(
          vertical: 8,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        constraints: BoxConstraints(
          maxWidth:
              MediaQuery.of(
                context,
              ).size.width *
              0.85,
        ),
        decoration: BoxDecoration(
          color: _isUser
              ? const Color(
                  0xFF2D2D2D,
                )
              : Colors.transparent,
          borderRadius: BorderRadius.circular(
            18,
          ),
        ),
        child: _isUser
            ? _buildUserContent()
            : _buildAiContent(
                context,
              ),
      ),
    );
  }

  // ============================================================
  // MENSAGEM DO USUÁRIO
  // ============================================================

  Widget _buildUserContent() {
    return Text(
      _content,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        height: 1.45,
      ),
    );
  }

  // ============================================================
  // MENSAGEM DA IA
  // ============================================================

  Widget _buildAiContent(
    BuildContext context,
  ) {
    return SelectionArea(
      onSelectionChanged: _handleSelectionChanged,

      contextMenuBuilder:
          (
            context,
            selectionState,
          ) {
            return _buildContextMenu(
              context,
              selectionState,
            );
          },

      child: MarkdownBody(
        data: _content,

        builders: {
          'word': RhymeTagBuilder(
            activeColor: widget.activeColor,
            onTap:
                (
                  word,
                ) {
                  _addRhymeTag(
                    context,
                    word,
                  );
                },
          ),
        },

        inlineSyntaxes: [
          RhymeSyntax(),
        ],

        styleSheet: MarkdownStyleSheet(
          p: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            height: 1.5,
          ),

          strong: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),

          em: const TextStyle(
            color: Colors.white70,
            fontStyle: FontStyle.italic,
          ),

          code: TextStyle(
            color: widget.activeColor,
            backgroundColor: Colors.white.withValues(
              alpha: 0.05,
            ),
            fontSize: 13,
          ),

          blockquote: const TextStyle(
            color: Colors.white60,
            fontSize: 15,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// RHYME SYNTAX
// ============================================================
//
// Converte:
//
// [WORD:amor]
//
// em um elemento Markdown customizado.
//
// ============================================================

class RhymeSyntax
    extends
        md.InlineSyntax {
  RhymeSyntax()
    : super(
        r'\[WORD:(.*?)\]',
      );

  @override
  bool onMatch(
    md.InlineParser parser,
    Match match,
  ) {
    final word = match.group(
      1,
    );

    if (word !=
        null) {
      parser.addNode(
        md.Element.text(
          'word',
          word,
        ),
      );
    }

    return true;
  }
}

// ============================================================
// RHYME TAG BUILDER
// ============================================================

class RhymeTagBuilder
    extends
        MarkdownElementBuilder {
  final Color activeColor;

  final Function(
    String,
  )
  onTap;

  RhymeTagBuilder({
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget? visitElementAfter(
    md.Element element,
    TextStyle? preferredStyle,
  ) {
    final textContent = element.textContent;

    final parts = textContent.split(
      '-->',
    );

    final word = parts.first.trim();

    if (word.isEmpty) {
      return null;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          onTap(
            word,
          );
        },
        borderRadius: BorderRadius.circular(
          5,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 2,
            vertical: 1,
          ),
          child: Text(
            word,
            style: TextStyle(
              color: activeColor,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
              decorationColor: activeColor.withValues(
                alpha: 0.5,
              ),
              decorationThickness: 1.3,
            ),
          ),
        ),
      ),
    );
  }
}
