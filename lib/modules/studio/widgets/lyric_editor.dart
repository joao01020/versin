import 'package:flutter/material.dart';

class LyricEditor
    extends
        StatefulWidget {
  final TextEditingController controller;

  final Color activeColor;

  final ValueChanged<
    String
  >
  onSelectionChanged;

  final ValueChanged<
    String
  >
  onAddToMap;

  final ValueChanged<
    String
  >
  onAddToTimeline;

  final ValueChanged<
    String
  >
  onAskChat;

  const LyricEditor({
    super.key,
    required this.controller,
    required this.activeColor,
    required this.onSelectionChanged,
    required this.onAddToMap,
    required this.onAddToTimeline,
    required this.onAskChat,
  });

  @override
  State<
    LyricEditor
  >
  createState() => _LyricEditorState();
}

class _LyricEditorState
    extends
        State<
          LyricEditor
        > {
  String _selectedText = '';

  // ============================================================
  // SELEÇÃO
  // ============================================================

  void _updateSelection() {
    final selection = widget.controller.selection;

    if (!selection.isValid ||
        selection.isCollapsed) {
      if (_selectedText.isNotEmpty) {
        setState(
          () {
            _selectedText = '';
          },
        );

        widget.onSelectionChanged(
          '',
        );
      }

      return;
    }

    final text = widget.controller.text;

    if (selection.start <
            0 ||
        selection.end >
            text.length) {
      return;
    }

    final selected = text
        .substring(
          selection.start,
          selection.end,
        )
        .trim();

    if (selected ==
        _selectedText) {
      return;
    }

    setState(
      () {
        _selectedText = selected;
      },
    );

    widget.onSelectionChanged(
      selected,
    );
  }

  // ============================================================
  // AÇÕES
  // ============================================================

  void _addToMap() {
    final text = _selectedText.trim();

    if (text.isEmpty) {
      return;
    }

    widget.onAddToMap(
      text,
    );
  }

  void _addToTimeline() {
    final text = _selectedText.trim();

    if (text.isEmpty) {
      return;
    }

    widget.onAddToTimeline(
      text,
    );
  }

  void _askChat() {
    final text = _selectedText.trim();

    if (text.isEmpty) {
      return;
    }

    widget.onAskChat(
      text,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(
          0xFF111111,
        ),
        borderRadius: BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.05,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ====================================================
          // HEADER
          // ====================================================
          Padding(
            padding: const EdgeInsets.fromLTRB(
              18,
              16,
              18,
              10,
            ),
            child: Row(
              children: [
                const Text(
                  'LETRA',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.4,
                  ),
                ),

                const Spacer(),

                if (_selectedText.isNotEmpty)
                  Text(
                    'Trecho selecionado',
                    style: TextStyle(
                      color: widget.activeColor.withValues(
                        alpha: 0.7,
                      ),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),

          const Divider(
            height: 1,
            color: Colors.white10,
          ),

          // ====================================================
          // EDITOR
          // ====================================================
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(
                18,
              ),
              child: Listener(
                onPointerUp:
                    (
                      _,
                    ) {
                      Future.delayed(
                        const Duration(
                          milliseconds: 30,
                        ),
                        _updateSelection,
                      );
                    },
                child: TextField(
                  controller: widget.controller,
                  expands: true,
                  maxLines: null,
                  minLines: null,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  textAlignVertical: TextAlignVertical.top,
                  cursorColor: widget.activeColor,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    height: 1.8,
                    letterSpacing: 0.15,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Comece a escrever sua música...',
                    hintStyle: TextStyle(
                      color: Colors.white24,
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    isCollapsed: true,
                  ),
                  onTap: () {
                    Future.delayed(
                      const Duration(
                        milliseconds: 30,
                      ),
                      _updateSelection,
                    );
                  },
                ),
              ),
            ),
          ),

          // ====================================================
          // BARRA DE AÇÕES DA SELEÇÃO
          // ====================================================
          AnimatedSwitcher(
            duration: const Duration(
              milliseconds: 200,
            ),
            child: _selectedText.isEmpty
                ? const SizedBox.shrink()
                : Container(
                    key: ValueKey(
                      _selectedText,
                    ),
                    padding: const EdgeInsets.fromLTRB(
                      14,
                      10,
                      14,
                      14,
                    ),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Colors.white10,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ======================================
                        // TEXTO SELECIONADO
                        // ======================================
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: widget.activeColor.withValues(
                              alpha: 0.06,
                            ),
                            borderRadius: BorderRadius.circular(
                              10,
                            ),
                          ),
                          child: Text(
                            '"$_selectedText"',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 10,
                        ),

                        // ======================================
                        // BOTÕES
                        // ======================================
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _SelectionAction(
                              icon: Icons.account_tree_outlined,
                              label: 'MAPA',
                              activeColor: widget.activeColor,
                              onTap: _addToMap,
                            ),

                            _SelectionAction(
                              icon: Icons.timeline_rounded,
                              label: 'TIMELINE',
                              activeColor: widget.activeColor,
                              onTap: _addToTimeline,
                            ),

                            _SelectionAction(
                              icon: Icons.auto_awesome_outlined,
                              label: 'CHAT',
                              activeColor: widget.activeColor,
                              onTap: _askChat,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// BOTÃO DE AÇÃO
// ============================================================

class _SelectionAction
    extends
        StatelessWidget {
  final IconData icon;
  final String label;
  final Color activeColor;
  final VoidCallback onTap;

  const _SelectionAction({
    required this.icon,
    required this.label,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(
          10,
        ),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: activeColor.withValues(
              alpha: 0.08,
            ),
            borderRadius: BorderRadius.circular(
              10,
            ),
            border: Border.all(
              color: activeColor.withValues(
                alpha: 0.18,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: activeColor,
              ),

              const SizedBox(
                width: 6,
              ),

              Text(
                label,
                style: TextStyle(
                  color: activeColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
