import 'package:versin/core/models/rhyme_model.dart';
import 'package:versin/features/rhymes/data/repositories/rhymes_repository.dart';

// ============================================================
// VOCABULARY SERVICE
// ============================================================
//
// Responsável exclusivamente pela comunicação entre o
// vocabulário e o repository.
//
// Este service:
//
// - carrega palavras;
// - salva palavras;
// - remove palavras.
//
// Ele NÃO:
//
// - controla estado de UI;
// - chama notifyListeners();
// - conhece widgets;
// - possui lógica de seleção.
//
// ============================================================

class VocabularyService {
  // ============================================================
  // REPOSITORY
  // ============================================================

  final RhymesRepository repository;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  VocabularyService({
    RhymesRepository? repository,
  }) : repository =
           repository ??
           RhymesRepository();

  // ============================================================
  // CARREGAR VOCABULÁRIO
  // ============================================================

  Future<
    List<
      Rhyme
    >
  >
  loadVocabulary() async {
    final result = await repository.fetchVocabulary();

    return result;
  }

  // ============================================================
  // SALVAR PALAVRA
  // ============================================================

  Future<
    void
  >
  saveWord(
    String word,
  ) async {
    final normalized = word.trim().toLowerCase();

    if (normalized.isEmpty) {
      return;
    }

    await repository.saveWord(
      normalized,
    );
  }

  // ============================================================
  // REMOVER PALAVRA
  // ============================================================

  Future<
    void
  >
  deleteWord(
    String word,
  ) async {
    final normalized = word.trim().toLowerCase();

    if (normalized.isEmpty) {
      return;
    }

    await repository.deleteWord(
      normalized,
    );
  }
}
