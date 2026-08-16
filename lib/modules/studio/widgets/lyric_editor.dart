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
  // CICLO DE VIDA
  // ============================================================
  //
  // O texto pertence ao TextEditingController recebido do
  // StudioController.
  //
  // O LyricEditor não mantém uma cópia própria da letra.
  // Assim, ao sair do Studio e voltar, o mesmo controller pode
  // ser reutilizado e o texto continua exatamente onde estava.
  //
  // ============================================================

  @override
  void initState() {
    super.initState();

    widget.controller.addListener(
      _handleControllerChanged,
    );

    WidgetsBinding.instance.addPostFrameCallback(
      (
        _,
      ) {
        if (!mounted) {
          return;
        }

        _updateSelection();
      },
    );
  }

  @override
  void didUpdateWidget(
    covariant LyricEditor oldWidget,
  ) {
    super.didUpdateWidget(
      oldWidget,
    );

    if (identical(
      oldWidget.controller,
      widget.controller,
    )) {
      return;
    }

    oldWidget.controller.removeListener(
      _handleControllerChanged,
    );

    widget.controller.addListener(
      _handleControllerChanged,
    );

    _selectedText = '';

    WidgetsBinding.instance.addPostFrameCallback(
      (
        _,
      ) {
        if (!mounted) {
          return;
        }

        _updateSelection();
      },
    );
  }

  @override
  void dispose() {
    widget.controller.removeListener(
      _handleControllerChanged,
    );

    super.dispose();
  }

  void _handleControllerChanged() {
    if (!mounted) {
      return;
    }

    _updateSelection();
  }

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
                      WidgetsBinding.instance.addPostFrameCallback(
                        (
                          _,
                        ) {
                          if (!mounted) {
                            return;
                          }

                          _updateSelection();
                        },
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
                  onChanged:
                      (
                        _,
                      ) {
                        // O StudioController já escuta este mesmo
                        // TextEditingController e salva a letra no
                        // SongProject da sessão.
                        //
                        // Aqui apenas mantemos a seleção visual
                        // sincronizada após alterações no texto.
                        _updateSelection();
                      },
                  onTap: () {
                    WidgetsBinding.instance.addPostFrameCallback(
                      (
                        _,
                      ) {
                        if (!mounted) {
                          return;
                        }

                        _updateSelection();
                      },
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
