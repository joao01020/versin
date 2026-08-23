import 'package:flutter/foundation.dart';

import 'package:versin/core/models/rhyme_model.dart';

import '../services/vocabulary_service.dart';

// ============================================================
// VOCABULARY CONTROLLER
// ============================================================
//
// Responsável pelo estado do vocabulário.
//
// Este controller gerencia:
//
// - lista de palavras;
// - carregamento;
// - verificação de palavra existente;
// - adicionar palavra;
// - adicionar várias palavras;
// - remover palavra;
// - normalização;
// - remoção de duplicados.
//
// ============================================================

class VocabularyController
    extends
        ChangeNotifier {
  // ============================================================
  // SERVICE
  // ============================================================

  final VocabularyService service;

  // ============================================================
  // ESTADO
  // ============================================================

  List<
    Rhyme
  >
  _vocabulary = [];

  bool _isLoading = false;

  String? _errorMessage;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  VocabularyController({
    VocabularyService? service,
  }) : service =
           service ??
           VocabularyService();

  // ============================================================
  // GETTERS
  // ============================================================

  List<
    Rhyme
  >
  get vocabulary => List.unmodifiable(
    _vocabulary,
  );

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  bool get hasError =>
      _errorMessage !=
      null;

  int get vocabularyCount => _vocabulary.length;

  // ============================================================
  // PALAVRAS
  // ============================================================

  List<
    String
  >
  get vocabularyWords {
    return _vocabulary
        .map(
          (
            rhyme,
          ) => rhyme.word,
        )
        .toList(
          growable: false,
        );
  }

  // ============================================================
  // NORMALIZAR
  // ============================================================

  String _normalizeWord(
    String word,
  ) {
    return word.trim().toLowerCase();
  }

  // ============================================================
  // CONTÉM PALAVRA?
  // ============================================================

  bool containsWord(
    String word,
  ) {
    final normalized = _normalizeWord(
      word,
    );

    if (normalized.isEmpty) {
      return false;
    }

    return _vocabulary.any(
      (
        rhyme,
      ) {
        return _normalizeWord(
              rhyme.word,
            ) ==
            normalized;
      },
    );
  }

  // ============================================================
  // BUSCAR PALAVRA
  // ============================================================

  Rhyme? findWord(
    String word,
  ) {
    final normalized = _normalizeWord(
      word,
    );

    if (normalized.isEmpty) {
      return null;
    }

    for (final rhyme in _vocabulary) {
      if (_normalizeWord(
            rhyme.word,
          ) ==
          normalized) {
        return rhyme;
      }
    }

    return null;
  }

  // ============================================================
  // CARREGAR VOCABULÁRIO
  // ============================================================

  Future<
    void
  >
  load() async {
    if (_isLoading) {
      return;
    }

    _isLoading = true;

    _errorMessage = null;

    notifyListeners();

    try {
      final loadedVocabulary = await service.loadVocabulary();

      // ========================================================
      // REMOVER DUPLICADOS
      // ========================================================

      final unique =
          <
            String,
            Rhyme
          >{};

      for (final rhyme in loadedVocabulary) {
        final normalized = _normalizeWord(
          rhyme.word,
        );

        if (normalized.isEmpty) {
          continue;
        }

        unique[normalized] = Rhyme(
          word: normalized,

          isPriority: rhyme.isPriority,
        );
      }

      _vocabulary = unique.values.toList();

      debugPrint(
        '[VOCABULARY] '
        '${_vocabulary.length} palavras carregadas.',
      );
    } catch (
      error,
      stackTrace
    ) {
      _errorMessage = 'Não foi possível carregar o vocabulário.';

      debugPrint(
        '[VOCABULARY] '
        'Erro ao carregar: $error',
      );

      debugPrint(
        '[VOCABULARY] '
        'Stack trace: $stackTrace',
      );
    } finally {
      _isLoading = false;

      notifyListeners();
    }
  }

  // ============================================================
  // ADICIONAR PALAVRA
  // ============================================================

  Future<
    bool
  >
  addWord(
    String word,
    bool priority,
  ) async {
    final normalized = _normalizeWord(
      word,
    );

    if (normalized.isEmpty) {
      return false;
    }

    if (containsWord(
      normalized,
    )) {
      return false;
    }

    final rhyme = Rhyme(
      word: normalized,

      isPriority: priority,
    );

    // ========================================================
    // OTIMISTA
    // ========================================================
    //
    // Atualizamos a interface antes da resposta do repository.
    //
    // Se falhar, removemos novamente.
    //
    // ========================================================

    _vocabulary.insert(
      0,
      rhyme,
    );

    notifyListeners();

    try {
      await service.saveWord(
        normalized,
      );

      debugPrint(
        '[VOCABULARY] '
        'Palavra adicionada: $normalized',
      );

      return true;
    } catch (
      error,
      stackTrace
    ) {
      _vocabulary.removeWhere(
        (
          item,
        ) {
          return _normalizeWord(
                item.word,
              ) ==
              normalized;
        },
      );

      _errorMessage = 'Não foi possível salvar a palavra.';

      notifyListeners();

      debugPrint(
        '[VOCABULARY] '
        'Erro ao adicionar "$normalized": $error',
      );

      debugPrint(
        '[VOCABULARY] '
        'Stack trace: $stackTrace',
      );

      return false;
    }
  }

  // ============================================================
  // ADICIONAR VÁRIAS PALAVRAS
  // ============================================================

  Future<
    int
  >
  addWords(
    Iterable<
      String
    >
    words, {
    bool priority = false,
  }) async {
    int addedCount = 0;

    final uniqueWords =
        <
          String
        >{};

    // ========================================================
    // NORMALIZAR
    // ========================================================

    for (final rawWord in words) {
      final normalized = _normalizeWord(
        rawWord,
      );

      if (normalized.isEmpty) {
        continue;
      }

      uniqueWords.add(
        normalized,
      );
    }

    // ========================================================
    // ADICIONAR
    // ========================================================

    for (final word in uniqueWords) {
      if (containsWord(
        word,
      )) {
        continue;
      }

      final added = await addWord(
        word,
        priority,
      );

      if (added) {
        addedCount++;
      }
    }

    return addedCount;
  }

  // ============================================================
  // REMOVER POR ÍNDICE
  // ============================================================

  Future<
    bool
  >
  removeWord(
    int index,
  ) async {
    if (index <
            0 ||
        index >=
            _vocabulary.length) {
      return false;
    }

    final removed = _vocabulary[index];

    final word = _normalizeWord(
      removed.word,
    );

    // ========================================================
    // REMOVER LOCALMENTE
    // ========================================================

    _vocabulary.removeAt(
      index,
    );

    notifyListeners();

    try {
      await service.deleteWord(
        word,
      );

      debugPrint(
        '[VOCABULARY] '
        'Palavra removida: $word',
      );

      return true;
    } catch (
      error,
      stackTrace
    ) {
      // ======================================================
      // ROLLBACK
      // ======================================================

      final safeIndex = index.clamp(
        0,
        _vocabulary.length,
      );

      _vocabulary.insert(
        safeIndex,
        removed,
      );

      _errorMessage = 'Não foi possível remover a palavra.';

      notifyListeners();

      debugPrint(
        '[VOCABULARY] '
        'Erro ao remover "$word": $error',
      );

      debugPrint(
        '[VOCABULARY] '
        'Stack trace: $stackTrace',
      );

      return false;
    }
  }

  // ============================================================
  // REMOVER PELO TEXTO
  // ============================================================

  Future<
    bool
  >
  removeWordByValue(
    String word,
  ) async {
    final normalized = _normalizeWord(
      word,
    );

    if (normalized.isEmpty) {
      return false;
    }

    final index = _vocabulary.indexWhere(
      (
        rhyme,
      ) {
        return _normalizeWord(
              rhyme.word,
            ) ==
            normalized;
      },
    );

    if (index ==
        -1) {
      return false;
    }

    return removeWord(
      index,
    );
  }

  // ============================================================
  // REORDENAR VOCABULÁRIO
  // ============================================================
  //
  // IMPORTANTE:
  //
  // A reordenação acontece diretamente em `_vocabulary`,
  // que é a lista mutável interna deste controller.
  //
  // O getter público `vocabulary` continua retornando
  // List.unmodifiable(...), protegendo o estado contra alterações
  // externas.
  //
  // ============================================================

  bool reorder(
    int oldIndex,
    int newIndex,
  ) {
    if (_vocabulary.isEmpty) {
      return false;
    }

    if (oldIndex <
            0 ||
        oldIndex >=
            _vocabulary.length) {
      return false;
    }

    if (newIndex <
            0 ||
        newIndex >
            _vocabulary.length) {
      return false;
    }

    // ========================================================
    // AJUSTAR ÍNDICE
    // ========================================================
    //
    // O ReorderableListView/SliverReorderableList informa
    // newIndex considerando a posição original do item.
    //
    // Ao remover o item, os índices à direita deslocam uma
    // posição.
    //
    // ========================================================

    if (oldIndex <
        newIndex) {
      newIndex--;
    }

    if (oldIndex ==
        newIndex) {
      return false;
    }

    final item = _vocabulary.removeAt(
      oldIndex,
    );

    final safeIndex = newIndex.clamp(
      0,
      _vocabulary.length,
    );

    _vocabulary.insert(
      safeIndex,
      item,
    );

    debugPrint(
      '[VOCABULARY] '
      'Ordem alterada: $oldIndex -> $safeIndex',
    );

    notifyListeners();

    return true;
  }

  // ============================================================
  // SUBSTITUIR LISTA
  // ============================================================

  void setVocabulary(
    Iterable<
      Rhyme
    >
    vocabulary,
  ) {
    final unique =
        <
          String,
          Rhyme
        >{};

    for (final rhyme in vocabulary) {
      final normalized = _normalizeWord(
        rhyme.word,
      );

      if (normalized.isEmpty) {
        continue;
      }

      unique[normalized] = Rhyme(
        word: normalized,

        isPriority: rhyme.isPriority,
      );
    }

    _vocabulary = unique.values.toList();

    notifyListeners();
  }

  // ============================================================
  // LIMPAR VOCABULÁRIO LOCAL
  // ============================================================
  //
  // Não remove palavras do banco.
  //
  // Apenas limpa o estado em memória.
  //
  // ============================================================

  void clearLocal() {
    if (_vocabulary.isEmpty) {
      return;
    }

    _vocabulary = [];

    notifyListeners();
  }

  // ============================================================
  // LIMPAR ERRO
  // ============================================================

  void clearError() {
    if (_errorMessage ==
        null) {
      return;
    }

    _errorMessage = null;

    notifyListeners();
  }
}
