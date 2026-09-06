import 'package:flutter/material.dart';

import 'package:versin/modules/studio/controllers/studio_timeline_controller.dart';

class StudioTimelineLibraryDialog extends StatefulWidget {
  final StudioTimelineController timelineController;

  final Color activeColor;

  const StudioTimelineLibraryDialog({
    required this.timelineController,
    required this.activeColor,
  });

  @override
  State<StudioTimelineLibraryDialog> createState() =>
      _StudioTimelineLibraryDialogState();
}

class _StudioTimelineLibraryDialogState
    extends State<StudioTimelineLibraryDialog> {
  late final TextEditingController _searchController;

  String _search = '';

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _searchController = TextEditingController();

    widget.timelineController.addListener(_handleLibraryChanged);
  }

  // ============================================================
  // CONTROLLER ALTERADO
  // ============================================================

  void _handleLibraryChanged() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    widget.timelineController.removeListener(_handleLibraryChanged);

    _searchController.dispose();

    super.dispose();
  }

  // ============================================================
  // TIMELINE NORMALIZADA
  // ============================================================

  Set<String> get _timelineWords {
    return widget.timelineController.timelineWords
        .map((word) => word.trim().toLowerCase())
        .where((word) => word.isNotEmpty)
        .toSet();
  }

  // ============================================================
  // PALAVRAS FILTRADAS
  // ============================================================
  //
  // IMPORTANTE:
  //
  // Não removemos mais palavras que já estão na Timeline.
  //
  // O comportamento antigo fazia:
  //
  // biblioteca = [vida, linda]
  // timeline    = [vida, linda]
  //
  // resultado:
  // biblioteca visível = []
  //
  // Por isso o modal mostrava BIBLIOTECA 0 mesmo com o banco
  // carregado corretamente.
  //
  // Agora todas as palavras da biblioteca permanecem visíveis.
  // As que já estão na Timeline recebem um indicador visual.
  //
  // ============================================================

  List<String> get _filteredWords {
    final query = _search.trim().toLowerCase();

    final seen = <String>{};

    return widget.timelineController.rhymeLibrary.where((word) {
      final normalized = word.trim().toLowerCase();

      if (normalized.isEmpty) {
        return false;
      }

      if (!seen.add(normalized)) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      return normalized.contains(query);
    }).toList();
  }

  // ============================================================
  // FECHAR COM RESULTADO
  // ============================================================

  void _finish(String word) {
    final normalized = word.trim();

    if (normalized.isEmpty) {
      return;
    }

    Navigator.of(context).pop(normalized);
  }

  // ============================================================
  // LIMPAR BUSCA
  // ============================================================

  void _clearSearch() {
    _searchController.clear();

    setState(() {
      _search = '';
    });
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final libraryWords = _filteredWords;

    final timelineWords = _timelineWords;

    final hasSearch = _search.trim().isNotEmpty;

    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      title: const Text(
        'Adicionar à Timeline',
        style: TextStyle(color: Colors.white),
      ),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================================================
            // BUSCA
            // ==================================================
            TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              onChanged: (value) {
                setState(() {
                  _search = value;
                });
              },
              onSubmitted: _finish,
              decoration: InputDecoration(
                hintText: 'Buscar na biblioteca ou criar uma palavra...',
                hintStyle: const TextStyle(color: Colors.white30),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Colors.white30,
                ),
                suffixIcon: !hasSearch
                    ? null
                    : IconButton(
                        onPressed: _clearSearch,
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white30,
                        ),
                      ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.04),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: widget.activeColor),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // ==================================================
            // CABEÇALHO DA BIBLIOTECA
            // ==================================================
            Row(
              children: [
                const Text(
                  'BIBLIOTECA',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),

                const SizedBox(width: 8),

                Text(
                  '${libraryWords.length}',
                  style: const TextStyle(color: Colors.white24, fontSize: 10),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ==================================================
            // LISTA
            // ==================================================
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: libraryWords.isEmpty
                  ? _buildEmptyState()
                  : SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: libraryWords.map((word) {
                          final normalized = word.trim().toLowerCase();

                          final alreadyInTimeline = timelineWords.contains(
                            normalized,
                          );

                          return Tooltip(
                            message: alreadyInTimeline
                                ? 'Já está na Timeline'
                                : 'Adicionar à Timeline',
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: alreadyInTimeline
                                  ? null
                                  : () {
                                      _finish(word);
                                    },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: widget.activeColor.withValues(
                                    alpha: alreadyInTimeline ? 0.035 : 0.08,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: widget.activeColor.withValues(
                                      alpha: alreadyInTimeline ? 0.10 : 0.20,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      alreadyInTimeline
                                          ? Icons.check_rounded
                                          : Icons.add_rounded,
                                      color: alreadyInTimeline
                                          ? Colors.white24
                                          : widget.activeColor,
                                      size: 15,
                                    ),

                                    const SizedBox(width: 5),

                                    Text(
                                      word,
                                      style: TextStyle(
                                        color: alreadyInTimeline
                                            ? Colors.white30
                                            : Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
            ),

            // ==================================================
            // CRIAR NOVA PALAVRA
            // ==================================================
            if (hasSearch) ...[
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _finish(_search);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: widget.activeColor,
                    side: BorderSide(
                      color: widget.activeColor.withValues(alpha: 0.35),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 17),
                  label: Text(
                    'CRIAR "${_search.trim()}"',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('CANCELAR'),
        ),
      ],
    );
  }

  // ============================================================
  // ESTADO VAZIO
  // ============================================================

  Widget _buildEmptyState() {
    final hasSearch = _search.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.library_books_outlined,
            color: Colors.white24,
            size: 28,
          ),

          const SizedBox(height: 10),

          Text(
            hasSearch
                ? 'Nenhuma palavra encontrada.'
                : 'Nenhuma palavra disponível na biblioteca.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white30, fontSize: 11),
          ),

          if (hasSearch) ...[
            const SizedBox(height: 6),

            Text(
              'Você pode criar "${_search.trim()}" usando o botão abaixo.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white24, fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }
}
