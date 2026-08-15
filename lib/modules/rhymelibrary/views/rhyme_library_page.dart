import 'package:flutter/material.dart';

import 'package:versin/core/models/rhyme_model.dart';
import 'package:versin/features/rhymes/presentation/controller/rhymes_controller.dart';

import '../data/rhyme_library_manager.dart';

class RhymeLibraryPage
    extends
        StatefulWidget {
  final RhymesController controller;

  const RhymeLibraryPage({
    super.key,
    required this.controller,
  });

  @override
  State<
    RhymeLibraryPage
  >
  createState() => _RhymeLibraryPageState();
}

class _RhymeLibraryPageState
    extends
        State<
          RhymeLibraryPage
        > {
  static const Color _background = Color(
    0xFF0D0B16,
  );
  static const Color _surface = Color(
    0xFF171321,
  );
  static const Color _surfaceSoft = Color(
    0xFF1D172A,
  );
  static const Color _accent = Color(
    0xFFE040FB,
  );

  final TextEditingController _wordController = TextEditingController();

  final TextEditingController _searchController = TextEditingController();

  String _search = '';

  bool _isImporting = false;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();

    _searchController.addListener(
      _onSearchChanged,
    );
  }

  @override
  void dispose() {
    _searchController.removeListener(
      _onSearchChanged,
    );

    _searchController.dispose();
    _wordController.dispose();

    super.dispose();
  }

  void _reorderWords(
    int oldIndex,
    int newIndex,
  ) {
    if (_search.isNotEmpty) {
      return;
    }

    widget.controller.reorderVocabulary(
      oldIndex,
      newIndex,
    );
  }

  void _onSearchChanged() {
    final value = _normalizeSearchText(
      _searchController.text,
    );

    if (_search ==
        value) {
      return;
    }

    setState(
      () {
        _search = value;
      },
    );
  }

  String _normalizeSearchText(
    String value,
  ) {
    var normalized = value.trim().toLowerCase();

    const replacements = {
      'á': 'a',
      'à': 'a',
      'â': 'a',
      'ã': 'a',
      'ä': 'a',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'í': 'i',
      'ì': 'i',
      'î': 'i',
      'ï': 'i',
      'ó': 'o',
      'ò': 'o',
      'ô': 'o',
      'õ': 'o',
      'ö': 'o',
      'ú': 'u',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'ç': 'c',
    };

    replacements.forEach(
      (
        accented,
        plain,
      ) {
        normalized = normalized.replaceAll(
          accented,
          plain,
        );
      },
    );

    return normalized;
  }

  List<
    Rhyme
  >
  _searchSuggestions(
    List<
      Rhyme
    >
    vocabulary,
  ) {
    if (_search.isEmpty) {
      return [];
    }

    final matches = vocabulary.where(
      (
        rhyme,
      ) {
        final normalizedWord = _normalizeSearchText(
          rhyme.word,
        );

        return normalizedWord.contains(
          _search,
        );
      },
    ).toList();

    matches.sort(
      (
        a,
        b,
      ) {
        final aText = _normalizeSearchText(
          a.word,
        );
        final bText = _normalizeSearchText(
          b.word,
        );

        final aStarts = aText.startsWith(
          _search,
        );
        final bStarts = bText.startsWith(
          _search,
        );

        if (aStarts &&
            !bStarts) {
          return -1;
        }

        if (!aStarts &&
            bStarts) {
          return 1;
        }

        return aText.compareTo(
          bText,
        );
      },
    );

    return matches
        .take(
          6,
        )
        .toList();
  }

  Future<
    void
  >
  _importLibrary() async {
    if (_isImporting) {
      return;
    }

    setState(
      () {
        _isImporting = true;
      },
    );

    try {
      final words = await RhymeLibraryManager.importFromFile();

      if (words.isEmpty) {
        if (!mounted) {
          return;
        }

        _showMessage(
          'Nenhuma rima encontrada no arquivo.',
          Colors.orangeAccent,
        );

        return;
      }

      int added = 0;

      for (final word in words) {
        final normalized = word.trim().toLowerCase();

        if (normalized.isEmpty ||
            widget.controller.containsWord(
              normalized,
            )) {
          continue;
        }

        await widget.controller.addWord(
          normalized,
          false,
        );

        added++;
      }

      if (!mounted) {
        return;
      }

      _showMessage(
        added ==
                0
            ? 'Nenhuma rima nova encontrada.'
            : '$added rimas importadas.',
        added ==
                0
            ? Colors.orangeAccent
            : Colors.greenAccent,
      );
    } catch (
      error
    ) {
      debugPrint(
        'Erro ao importar biblioteca: $error',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Erro ao importar biblioteca.',
        Colors.redAccent,
      );
    } finally {
      if (mounted) {
        setState(
          () {
            _isImporting = false;
          },
        );
      }
    }
  }

  Future<
    void
  >
  _exportLibrary() async {
    if (_isExporting) {
      return;
    }

    setState(
      () {
        _isExporting = true;
      },
    );

    try {
      final path = await RhymeLibraryManager.exportToBackup(
        widget.controller.vocabulary,
      );

      if (!mounted) {
        return;
      }

      if (path ==
          null) {
        _showMessage(
          'Erro ao exportar biblioteca.',
          Colors.redAccent,
        );

        return;
      }

      _showMessage(
        'Biblioteca exportada.',
        Colors.greenAccent,
      );
    } catch (
      error
    ) {
      debugPrint(
        'Erro ao exportar biblioteca: $error',
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Erro ao exportar biblioteca.',
        Colors.redAccent,
      );
    } finally {
      if (mounted) {
        setState(
          () {
            _isExporting = false;
          },
        );
      }
    }
  }

  Future<
    void
  >
  _addWord() async {
    final normalized = _wordController.text.trim().toLowerCase();

    if (normalized.isEmpty) {
      return;
    }

    if (widget.controller.containsWord(
      normalized,
    )) {
      _showMessage(
        'Essa rima já está salva.',
        Colors.orangeAccent,
      );

      return;
    }

    await widget.controller.addWord(
      normalized,
      false,
    );

    if (!mounted) {
      return;
    }

    _wordController.clear();

    FocusScope.of(
      context,
    ).unfocus();

    _showMessage(
      'Rima adicionada.',
      Colors.greenAccent,
    );
  }

  Future<
    void
  >
  _removeWord(
    int index,
  ) async {
    if (index <
            0 ||
        index >=
            widget.controller.vocabulary.length) {
      return;
    }

    await widget.controller.removeWord(
      index,
    );
  }

  void _showMessage(
    String message,
    Color color,
  ) {
    final messenger = ScaffoldMessenger.of(
      context,
    );

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: _surfaceSoft,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              14,
            ),
            side: BorderSide(
              color: color.withValues(
                alpha: 0.3,
              ),
            ),
          ),
          content: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: Text(
                  message,
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

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            _buildNavigation(),

            Expanded(
              child: ListenableBuilder(
                listenable: widget.controller,
                builder:
                    (
                      context,
                      _,
                    ) {
                      final vocabulary = widget.controller.vocabulary;

                      final filtered = _filteredWords(
                        vocabulary,
                      );

                      return CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(
                            child: _buildOverview(
                              vocabulary.length,
                            ),
                          ),

                          SliverToBoxAdapter(
                            child: _buildActions(),
                          ),

                          SliverToBoxAdapter(
                            child: _buildSearch(
                              vocabulary,
                            ),
                          ),

                          SliverToBoxAdapter(
                            child: _buildListHeader(
                              filtered.length,
                            ),
                          ),

                          if (filtered.isEmpty)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: _buildEmptyState(
                                vocabulary.isNotEmpty,
                              ),
                            )
                          else
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(
                                18,
                                0,
                                18,
                                130,
                              ),
                              sliver: _search.isEmpty
                                  ? SliverReorderableList(
                                      itemCount: vocabulary.length,
                                      onReorder: _reorderWords,
                                      itemBuilder:
                                          (
                                            context,
                                            index,
                                          ) {
                                            final rhyme = vocabulary[index];

                                            return Padding(
                                              key: ValueKey(
                                                'rhyme-${rhyme.word}',
                                              ),
                                              padding: const EdgeInsets.only(
                                                bottom: 7,
                                              ),
                                              child: _buildWordCard(
                                                rhyme: rhyme,
                                                originalIndex: index,
                                                displayIndex: index,
                                                reorderIndex: index,
                                              ),
                                            );
                                          },
                                    )
                                  : SliverList.separated(
                                      itemCount: filtered.length,
                                      separatorBuilder:
                                          (
                                            _,
                                            __,
                                          ) => const SizedBox(
                                            height: 7,
                                          ),
                                      itemBuilder:
                                          (
                                            context,
                                            index,
                                          ) {
                                            final item = filtered[index];

                                            return _buildWordCard(
                                              rhyme: item.rhyme,
                                              originalIndex: item.index,
                                              displayIndex: index,
                                            );
                                          },
                                    ),
                            ),
                        ],
                      );
                    },
              ),
            ),

            _buildComposer(),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigation() {
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
      ),
      child: Row(
        children: [
          _iconButton(
            icon: Icons.arrow_back_rounded,
            tooltip: 'Voltar',
            onTap: () => Navigator.pop(
              context,
            ),
          ),

          const SizedBox(
            width: 10,
          ),

          const Expanded(
            child: Text(
              'Biblioteca de rimas',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: _accent.withValues(
                alpha: 0.08,
              ),
              borderRadius: BorderRadius.circular(
                30,
              ),
              border: Border.all(
                color: _accent.withValues(
                  alpha: 0.15,
                ),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  color: _accent,
                  size: 13,
                ),
                SizedBox(
                  width: 5,
                ),
                Text(
                  'VERSIN',
                  style: TextStyle(
                    color: _accent,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverview(
    int total,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        18,
        12,
        18,
        14,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(
          20,
        ),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(
            22,
          ),
          border: Border.all(
            color: Colors.white.withValues(
              alpha: 0.06,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    total ==
                            1
                        ? '1 palavra salva'
                        : '$total palavras salvas',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.6,
                    ),
                  ),

                  const SizedBox(
                    height: 5,
                  ),

                  const Text(
                    'Seu vocabulário para composição',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _accent.withValues(
                      alpha: 0.28,
                    ),
                    const Color(
                      0xFF7C4DFF,
                    ).withValues(
                      alpha: 0.12,
                    ),
                  ],
                ),
                borderRadius: BorderRadius.circular(
                  16,
                ),
              ),
              child: const Icon(
                Icons.library_music_rounded,
                color: _accent,
                size: 23,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
      ),
      child: Row(
        children: [
          Expanded(
            child: _actionCard(
              icon: Icons.upload_file_rounded,
              title: 'Importar',
              subtitle: '.txt ou .md',
              loading: _isImporting,
              onTap: _isImporting
                  ? null
                  : _importLibrary,
            ),
          ),

          const SizedBox(
            width: 10,
          ),

          Expanded(
            child: _actionCard(
              icon: Icons.download_rounded,
              title: 'Exportar',
              subtitle: 'Criar backup',
              loading: _isExporting,
              onTap: _isExporting
                  ? null
                  : _exportLibrary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool loading,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          16,
        ),
        child: Ink(
          padding: const EdgeInsets.all(
            14,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(
              alpha: 0.035,
            ),
            borderRadius: BorderRadius.circular(
              16,
            ),
            border: Border.all(
              color: Colors.white.withValues(
                alpha: 0.055,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 37,
                height: 37,
                decoration: BoxDecoration(
                  color: _accent.withValues(
                    alpha: 0.09,
                  ),
                  borderRadius: BorderRadius.circular(
                    11,
                  ),
                ),
                child: loading
                    ? const Padding(
                        padding: EdgeInsets.all(
                          10,
                        ),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _accent,
                        ),
                      )
                    : Icon(
                        icon,
                        color: _accent,
                        size: 19,
                      ),
              ),

              const SizedBox(
                width: 10,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(
                      height: 2,
                    ),

                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white30,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearch(
    List<
      Rhyme
    >
    vocabulary,
  ) {
    final suggestions = _searchSuggestions(
      vocabulary,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        18,
        14,
        18,
        0,
      ),
      child: Column(
        children: [
          Container(
            height: 46,
            decoration: BoxDecoration(
              color: Colors.black.withValues(
                alpha: 0.16,
              ),
              borderRadius: BorderRadius.circular(
                14,
              ),
              border: Border.all(
                color: _search.isEmpty
                    ? Colors.white.withValues(
                        alpha: 0.05,
                      )
                    : _accent.withValues(
                        alpha: 0.22,
                      ),
              ),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Pesquisar palavra...',
                hintStyle: const TextStyle(
                  color: Colors.white24,
                  fontSize: 12,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Colors.white30,
                  size: 19,
                ),
                suffixIcon: _search.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Limpar',
                        onPressed: _searchController.clear,
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white30,
                          size: 17,
                        ),
                      ),
              ),
            ),
          ),

          if (_search.isNotEmpty)
            AnimatedSwitcher(
              duration: const Duration(
                milliseconds: 180,
              ),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: suggestions.isEmpty
                  ? _buildNoSearchResults()
                  : _buildSearchResults(
                      suggestions,
                    ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(
    List<
      Rhyme
    >
    suggestions,
  ) {
    return Container(
      key: ValueKey(
        'search-results-${_searchController.text}',
      ),
      margin: const EdgeInsets.only(
        top: 6,
      ),
      decoration: BoxDecoration(
        color: _surfaceSoft,
        borderRadius: BorderRadius.circular(
          14,
        ),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.055,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.28,
            ),
            blurRadius: 18,
            offset: const Offset(
              0,
              8,
            ),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          14,
        ),
        child: Column(
          children: List.generate(
            suggestions.length,
            (
              index,
            ) {
              final rhyme = suggestions[index];

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        _selectSearchSuggestion(
                          rhyme.word,
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 11,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: _accent.withValues(
                                  alpha: 0.08,
                                ),
                                borderRadius: BorderRadius.circular(
                                  9,
                                ),
                              ),
                              child: const Icon(
                                Icons.search_rounded,
                                color: _accent,
                                size: 15,
                              ),
                            ),

                            const SizedBox(
                              width: 10,
                            ),

                            Expanded(
                              child: Text(
                                rhyme.word,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),

                            const SizedBox(
                              width: 8,
                            ),

                            Icon(
                              Icons.north_west_rounded,
                              color: Colors.white.withValues(
                                alpha: 0.18,
                              ),
                              size: 15,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  if (index <
                      suggestions.length -
                          1)
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.white.withValues(
                        alpha: 0.035,
                      ),
                      indent: 54,
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNoSearchResults() {
    return Container(
      key: ValueKey(
        'no-search-results-${_searchController.text}',
      ),
      width: double.infinity,
      margin: const EdgeInsets.only(
        top: 6,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: _surfaceSoft,
        borderRadius: BorderRadius.circular(
          14,
        ),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.05,
          ),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.search_off_rounded,
            color: Colors.white24,
            size: 17,
          ),

          SizedBox(
            width: 10,
          ),

          Text(
            'Nenhuma rima encontrada',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  void _selectSearchSuggestion(
    String word,
  ) {
    _searchController.value = TextEditingValue(
      text: word,
      selection: TextSelection.collapsed(
        offset: word.length,
      ),
    );

    FocusScope.of(
      context,
    ).unfocus();
  }

  Widget _buildListHeader(
    int count,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        10,
      ),
      child: Row(
        children: [
          Text(
            _search.isEmpty
                ? 'PALAVRAS · ARRASTE PARA ORGANIZAR'
                : 'RESULTADOS',
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.3,
            ),
          ),

          const Spacer(),

          Text(
            '$count',
            style: const TextStyle(
              color: Colors.white24,
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordCard({
    required Rhyme rhyme,
    required int originalIndex,
    required int displayIndex,
    int? reorderIndex,
  }) {
    final word = rhyme.word.trim();

    return Container(
      height: 55,
      padding: const EdgeInsets.only(
        left: 12,
        right: 5,
      ),
      decoration: BoxDecoration(
        color: _surface.withValues(
          alpha: 0.72,
        ),
        borderRadius: BorderRadius.circular(
          14,
        ),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.045,
          ),
        ),
      ),
      child: Row(
        children: [
          if (reorderIndex !=
              null) ...[
            ReorderableDragStartListener(
              index: reorderIndex,
              child: Tooltip(
                message: 'Arrastar para reorganizar',
                child: SizedBox(
                  width: 30,
                  height: 40,
                  child: Icon(
                    Icons.drag_indicator_rounded,
                    color: _accent.withValues(
                      alpha: 0.55,
                    ),
                    size: 18,
                  ),
                ),
              ),
            ),

            const SizedBox(
              width: 2,
            ),
          ],

          SizedBox(
            width: 32,
            child: Text(
              '${displayIndex + 1}'.padLeft(
                2,
                '0',
              ),
              style: const TextStyle(
                color: Colors.white24,
                fontSize: 10,
                fontFamily: 'monospace',
              ),
            ),
          ),

          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: _accent.withValues(
                alpha: 0.65,
              ),
              borderRadius: BorderRadius.circular(
                10,
              ),
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child: Text(
              word,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          IconButton(
            tooltip: 'Remover',
            onPressed: () => _removeWord(
              originalIndex,
            ),
            icon: Icon(
              Icons.close_rounded,
              color: Colors.white.withValues(
                alpha: 0.20,
              ),
              size: 17,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    bool hasWords,
  ) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasWords
                ? Icons.search_off_rounded
                : Icons.music_note_rounded,
            color: _accent.withValues(
              alpha: 0.28,
            ),
            size: 42,
          ),

          const SizedBox(
            height: 12,
          ),

          Text(
            hasWords
                ? 'Nenhum resultado'
                : 'Nenhuma rima salva',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(
            height: 4,
          ),

          Text(
            hasWords
                ? 'Tente outro termo.'
                : 'Comece adicionando uma palavra.',
            style: const TextStyle(
              color: Colors.white24,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComposer() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        14,
        10,
        14,
        MediaQuery.paddingOf(
              context,
            ).bottom +
            12,
      ),
      decoration: BoxDecoration(
        color: const Color(
          0xFF110E19,
        ),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(
              alpha: 0.05,
            ),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(
                  alpha: 0.045,
                ),
                borderRadius: BorderRadius.circular(
                  15,
                ),
              ),
              child: TextField(
                controller: _wordController,
                textInputAction: TextInputAction.done,
                onSubmitted:
                    (
                      _,
                    ) => _addWord(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Nova rima...',
                  hintStyle: TextStyle(
                    color: Colors.white24,
                    fontSize: 12,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(
            width: 8,
          ),

          Material(
            color: _accent,
            borderRadius: BorderRadius.circular(
              15,
            ),
            child: InkWell(
              onTap: _addWord,
              borderRadius: BorderRadius.circular(
                15,
              ),
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Icon(
                  Icons.arrow_upward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          12,
        ),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(
              alpha: 0.04,
            ),
            borderRadius: BorderRadius.circular(
              12,
            ),
          ),
          child: Icon(
            icon,
            color: Colors.white70,
            size: 20,
          ),
        ),
      ),
    );
  }

  List<
    _FilteredRhyme
  >
  _filteredWords(
    List<
      Rhyme
    >
    vocabulary,
  ) {
    final result =
        <
          _FilteredRhyme
        >[];

    for (
      int i = 0;
      i <
          vocabulary.length;
      i++
    ) {
      final rhyme = vocabulary[i];

      final normalizedWord = _normalizeSearchText(
        rhyme.word,
      );

      if (_search.isNotEmpty &&
          !normalizedWord.contains(
            _search,
          )) {
        continue;
      }

      result.add(
        _FilteredRhyme(
          rhyme: rhyme,
          index: i,
        ),
      );
    }

    return result;
  }
}

class _FilteredRhyme {
  final Rhyme rhyme;
  final int index;

  const _FilteredRhyme({
    required this.rhyme,
    required this.index,
  });
}
