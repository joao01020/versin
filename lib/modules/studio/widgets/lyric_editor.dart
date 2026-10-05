import 'package:flutter/material.dart';

import 'package:versin/modules/chat/views/components/suggestion_balloon/controllers/suggestion_controller.dart';
import 'package:versin/modules/chat/views/components/suggestion_balloon/suggestion_balloon.dart';

class LyricEditor
    extends
        StatefulWidget {
  final TextEditingController controller;

  final SuggestionController suggestionController;

  final List<
    String
  >
  rhymeLibrary;

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
    required this.suggestionController,
    required this.rhymeLibrary,
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

    widget.suggestionController.addListener(
      _handleSuggestionChanged,
    );

    _updateSuggestionsFromText(
      widget.controller.text,
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

    if (!identical(
      oldWidget.controller,
      widget.controller,
    )) {
      oldWidget.controller.removeListener(
        _handleControllerChanged,
      );

      widget.controller.addListener(
        _handleControllerChanged,
      );

      _selectedText = '';

      _updateSuggestionsFromText(
        widget.controller.text,
      );
    }

    if (!identical(
      oldWidget.suggestionController,
      widget.suggestionController,
    )) {
      oldWidget.suggestionController.removeListener(
        _handleSuggestionChanged,
      );

      widget.suggestionController.addListener(
        _handleSuggestionChanged,
      );

      _updateSuggestionsFromText(
        widget.controller.text,
      );
    }

    // ==========================================================
    // BIBLIOTECA ALTERADA
    // ==========================================================
    //
    // O Studio pode terminar de carregar o vocabulário depois
    // que o LyricEditor já foi montado.
    //
    // Nesse caso o TextEditingController e o SuggestionController
    // continuam sendo as mesmas instâncias, mas rhymeLibrary muda.
    //
    // Recalculamos as sugestões para que o balão passe a funcionar
    // assim que o vocabulário real chegar.
    //
    // ==========================================================

    if (!_sameRhymeLibrary(
      oldWidget.rhymeLibrary,
      widget.rhymeLibrary,
    )) {
      _updateSuggestionsFromText(
        widget.controller.text,
      );
    }

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

    widget.suggestionController.removeListener(
      _handleSuggestionChanged,
    );

    // O SuggestionController pertence ao BrainController.
    // Não fazemos dispose dele neste widget.
    super.dispose();
  }

  void _handleControllerChanged() {
    if (!mounted) {
      return;
    }

    _updateSelection();

    _updateSuggestionsFromText(
      widget.controller.text,
    );
  }

  void _handleSuggestionChanged() {
    if (!mounted) {
      return;
    }

    setState(
      () {},
    );
  }

  bool _sameRhymeLibrary(
    List<
      String
    >
    previous,
    List<
      String
    >
    current,
  ) {
    if (identical(
      previous,
      current,
    )) {
      return true;
    }

    if (previous.length !=
        current.length) {
      return false;
    }

    for (
      var index = 0;
      index <
          previous.length;
      index++
    ) {
      if (previous[index].trim().toLowerCase() !=
          current[index].trim().toLowerCase()) {
        return false;
      }
    }

    return true;
  }

  // ============================================================
  // ATUALIZAR SUGESTÕES A PARTIR DA BIBLIOTECA
  // ============================================================
  //
  // O SuggestionController é usado como estado visual/navegação.
  //
  // A fonte das palavras, porém, é o vocabulário real do
  // BrainController recebido em rhymeLibrary.
  //
  // Isso elimina a dependência do mapa interno _rhymes do
  // SuggestionController, que anteriormente não era alimentado
  // pelo Studio.
  //
  // ============================================================

  void _updateSuggestionsFromText(
    String text,
  ) {
    final baseWord = _extractLastWord(
      text,
    );

    if (baseWord.isEmpty) {
      widget.suggestionController.setSuggestions(
        const <
          String
        >[],
      );

      return;
    }

    final normalizedBase = _normalizeWord(
      baseWord,
    );

    if (normalizedBase.isEmpty) {
      widget.suggestionController.setSuggestions(
        const <
          String
        >[],
      );

      return;
    }

    final baseEnding = _rhymeEnding(
      normalizedBase,
    );

    final seen =
        <
          String
        >{};

    final suggestions =
        <
          String
        >[];

    for (final rawWord in widget.rhymeLibrary) {
      final word = rawWord.trim();

      if (word.isEmpty) {
        continue;
      }

      final normalizedWord = _normalizeWord(
        word,
      );

      if (normalizedWord.isEmpty ||
          normalizedWord ==
              normalizedBase) {
        continue;
      }

      final sameEnding =
          _rhymeEnding(
            normalizedWord,
          ) ==
          baseEnding;

      final startsWithBase = normalizedWord.startsWith(
        normalizedBase,
      );

      // Mesma regra utilizada pelo RhymeSuggestionService:
      //
      // - termina com o mesmo sufixo;
      // - OU começa com a palavra digitada.
      if (!sameEnding &&
          !startsWithBase) {
        continue;
      }

      if (!seen.add(
        normalizedWord,
      )) {
        continue;
      }

      suggestions.add(
        word,
      );

      if (suggestions.length >=
          40) {
        break;
      }
    }

    widget.suggestionController.setSuggestions(
      suggestions,
    );
  }

  String _extractLastWord(
    String text,
  ) {
    if (text.trim().isEmpty) {
      return '';
    }

    final selection = widget.controller.selection;

    var cursorOffset = selection.isValid
        ? selection.extentOffset
        : text.length;

    if (cursorOffset <
            0 ||
        cursorOffset >
            text.length) {
      cursorOffset = text.length;
    }

    final beforeCursor = text.substring(
      0,
      cursorOffset,
    );

    final match =
        RegExp(
          r"[A-Za-zÀ-ÖØ-öø-ÿ0-9_'-]+$",
        ).firstMatch(
          beforeCursor,
        );

    return match
            ?.group(
              0,
            )
            ?.trim() ??
        '';
  }

  String _normalizeWord(
    String value,
  ) {
    var normalized = value.trim().toLowerCase();

    const source = 'áàãâäéèêëíìîïóòõôöúùûüç';

    const target = 'aaaaaeeeeiiiiooooouuuuc';

    for (
      var index = 0;
      index <
          source.length;
      index++
    ) {
      normalized = normalized.replaceAll(
        source[index],
        target[index],
      );
    }

    normalized = normalized.replaceAll(
      RegExp(
        r'[^a-z0-9]',
      ),
      '',
    );

    return normalized;
  }

  String _rhymeEnding(
    String word,
  ) {
    if (word.length <=
        2) {
      return word;
    }

    return word.substring(
      word.length -
          2,
    );
  }

  // ============================================================
  // SUGESTÕES
  // ============================================================

  void _dismissSuggestion() {
    widget.suggestionController.setSuggestions(
      const <
        String
      >[],
    );
  }

  void _acceptSuggestion() {
    final suggestion = widget.suggestionController.currentSuggestion.trim();

    if (suggestion.isEmpty) {
      return;
    }

    final value = widget.controller.value;
    final text = value.text;

    var cursorOffset = value.selection.isValid
        ? value.selection.extentOffset
        : text.length;

    if (cursorOffset <
            0 ||
        cursorOffset >
            text.length) {
      cursorOffset = text.length;
    }

    final beforeCursor = text.substring(
      0,
      cursorOffset,
    );

    final afterCursor = text.substring(
      cursorOffset,
    );

    final match =
        RegExp(
          r"[A-Za-zÀ-ÖØ-öø-ÿ0-9_'-]+$",
        ).firstMatch(
          beforeCursor,
        );

    final replaceStart =
        match?.start ??
        cursorOffset;

    final newText =
        beforeCursor.substring(
          0,
          replaceStart,
        ) +
        suggestion +
        afterCursor;

    final newCursorOffset =
        replaceStart +
        suggestion.length;

    widget.controller.value = value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(
        offset: newCursorOffset,
      ),
      composing: TextRange.empty,
    );

    // Fecha o balão após aplicar a sugestão.
    //
    // Limpamos somente as sugestões visíveis.
    //
    // Não destruímos o SuggestionController porque ele pertence
    // ao BrainController compartilhado.
    widget.suggestionController.setSuggestions(
      const <
        String
      >[],
    );
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
              child: Stack(
                children: [
                  Listener(
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
                            value,
                          ) {
                            _updateSuggestionsFromText(
                              value,
                            );

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

                            _updateSuggestionsFromText(
                              widget.controller.text,
                            );
                          },
                        );
                      },
                    ),
                  ),

                  if (widget.suggestionController.isLoading ||
                      widget.suggestionController.currentSuggestion.trim().isNotEmpty)
                    Positioned(
                      left: 0,
                      bottom: 8,
                      child: SuggestionBalloon(
                        controller: widget.suggestionController,
                        suggestion: widget.suggestionController.currentSuggestion,
                        onTap: _acceptSuggestion,
                        onDismiss: _dismissSuggestion,
                      ),
                    ),
                ],
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
