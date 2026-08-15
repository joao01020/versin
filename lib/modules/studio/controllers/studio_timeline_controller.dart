import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:versin/features/rhymes/presentation/controller/rhymes_controller.dart';
import 'package:versin/modules/studio/models/song_project.dart';

// ============================================================
// STUDIO TIMELINE CONTROLLER
// ============================================================
//
// Responsável por:
//
// - timeline de palavras do projeto;
// - biblioteca global de rimas;
// - sincronização RhymesController -> SongProject;
// - adicionar/remover palavras da timeline;
// - sincronizar palavras usadas no Studio com a biblioteca.
//
// Não conhece widgets.
//
// ============================================================

class StudioTimelineController
    extends
        ChangeNotifier {
  // ============================================================
  // DEPENDÊNCIAS
  // ============================================================

  final RhymesController rhymesController;

  final SongProject Function() _projectProvider;

  final VoidCallback _markChanged;

  bool _isDisposed = false;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  StudioTimelineController({
    required this.rhymesController,
    required SongProject Function() projectProvider,
    required VoidCallback markChanged,
  }) : _projectProvider = projectProvider,
       _markChanged = markChanged {
    rhymesController.addListener(
      _onRhymesChanged,
    );

    _syncGlobalRhymesToTimeline(
      notify: false,
      markChanged: false,
    );
  }

  // ============================================================
  // PROJETO
  // ============================================================

  SongProject get _project => _projectProvider();

  // ============================================================
  // GETTERS
  // ============================================================

  List<
    String
  >
  get timelineWords => List.unmodifiable(
    _project.timelineWords,
  );

  bool get hasTimelineWords => _project.timelineWords.isNotEmpty;

  List<
    String
  >
  get rhymeLibrary {
    return List<
      String
    >.unmodifiable(
      rhymesController.vocabulary
          .map(
            (
              rhyme,
            ) => rhyme.word.trim(),
          )
          .where(
            (
              word,
            ) => word.isNotEmpty,
          ),
    );
  }

  // ============================================================
  // BIBLIOTECA
  // ============================================================

  bool hasLibraryWord(
    String word,
  ) {
    final normalized = _normalizeWord(
      word,
    );

    if (normalized.isEmpty) {
      return false;
    }

    return rhymesController.vocabulary.any(
      (
        rhyme,
      ) =>
          _normalizeWord(
            rhyme.word,
          ) ==
          normalized,
    );
  }

  // ============================================================
  // ALTERAÇÃO NO BANCO GLOBAL
  // ============================================================

  void _onRhymesChanged() {
    if (_isDisposed) {
      return;
    }

    _syncGlobalRhymesToTimeline(
      notify: false,
      markChanged: false,
    );

    // Mesmo que nenhuma palavra seja adicionada à timeline,
    // a biblioteca global pode ter mudado.
    notifyListeners();
  }

  // ============================================================
  // SINCRONIZAR BANCO GLOBAL -> TIMELINE
  // ============================================================

  bool _syncGlobalRhymesToTimeline({
    bool notify = true,
    bool markChanged = true,
  }) {
    bool changed = false;

    for (final rhyme in rhymesController.vocabulary) {
      final word = rhyme.word.trim();

      if (word.isEmpty) {
        continue;
      }

      if (_project.hasTimelineWord(
        word,
      )) {
        continue;
      }

      final added = _project.addTimelineWord(
        word,
      );

      if (added) {
        changed = true;
      }
    }

    if (!changed) {
      return false;
    }

    if (markChanged) {
      _markChanged();
    }

    if (notify &&
        !_isDisposed) {
      notifyListeners();
    }

    return true;
  }

  // ============================================================
  // SINCRONIZAÇÃO MANUAL
  // ============================================================

  void syncGlobalRhymesToTimeline() {
    _syncGlobalRhymesToTimeline();
  }

  // ============================================================
  // ADICIONAR À TIMELINE
  // ============================================================

  bool addTimelineWord(
    String word,
  ) {
    final normalized = word.trim();

    if (normalized.isEmpty) {
      return false;
    }

    final added = _project.addTimelineWord(
      normalized,
    );

    // Toda palavra usada no Studio também entra na
    // biblioteca global compartilhada com Chat/Biblioteca.
    unawaited(
      _ensureWordInGlobalLibrary(
        normalized,
      ),
    );

    if (!added) {
      return false;
    }

    _markChanged();

    notifyListeners();

    return true;
  }

  // ============================================================
  // GARANTIR PALAVRA NA BIBLIOTECA GLOBAL
  // ============================================================

  Future<
    void
  >
  _ensureWordInGlobalLibrary(
    String word,
  ) async {
    final normalized = word.trim();

    if (normalized.isEmpty ||
        hasLibraryWord(
          normalized,
        )) {
      return;
    }

    try {
      await rhymesController.addWord(
        normalized,
        false,
      );
    } catch (
      error
    ) {
      debugPrint(
        'Erro ao sincronizar palavra do Studio '
        'com a biblioteca: $error',
      );
    }
  }

  // ============================================================
  // BIBLIOTECA -> TIMELINE
  // ============================================================

  bool addLibraryWordToTimeline(
    String word,
  ) {
    return addTimelineWord(
      word,
    );
  }

  // ============================================================
  // REMOVER DA TIMELINE
  // ============================================================

  bool removeTimelineWord(
    String word,
  ) {
    final removed = _project.removeTimelineWord(
      word,
    );

    if (!removed) {
      return false;
    }

    _markChanged();

    notifyListeners();

    return true;
  }

  // ============================================================
  // POSSUI PALAVRA
  // ============================================================

  bool hasTimelineWord(
    String word,
  ) {
    return _project.hasTimelineWord(
      word,
    );
  }

  // ============================================================
  // PALAVRA UTILIZADA
  // ============================================================

  bool isTimelineWordUsed(
    String word,
  ) {
    return _project.isTimelineWordUsed(
      word,
    );
  }

  // ============================================================
  // LIMPAR TIMELINE
  // ============================================================

  void clearTimeline() {
    if (_project.timelineWords.isEmpty) {
      return;
    }

    _project.clearTimeline();

    _markChanged();

    notifyListeners();
  }

  // ============================================================
  // NORMALIZAR
  // ============================================================

  String _normalizeWord(
    String value,
  ) {
    return value.trim().toLowerCase();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _isDisposed = true;

    rhymesController.removeListener(
      _onRhymesChanged,
    );

    super.dispose();
  }
}
