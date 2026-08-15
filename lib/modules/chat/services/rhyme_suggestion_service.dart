import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:versin/core/models/rhyme_model.dart';
import 'package:versin/modules/chat/views/components/suggestion_balloon/controllers/suggestion_controller.dart';

// ============================================================
// RHYME SUGGESTION SERVICE
// ============================================================
//
// Responsável pela lógica de sugestão enquanto o usuário
// escreve.
//
// Retira do RhymesController:
//
// - debounce;
// - normalização do texto;
// - identificação da última palavra;
// - cálculo do sufixo;
// - busca no vocabulário;
// - merge de sugestões.
//
// ============================================================

class RhymeSuggestionService {
  // ============================================================
  // CONTROLLER
  // ============================================================

  final SuggestionController suggestionController;

  // ============================================================
  // TIMER
  // ============================================================

  Timer? _debounce;

  // ============================================================
  // DEBOUNCE
  // ============================================================

  final Duration debounceDuration;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  RhymeSuggestionService({
    required this.suggestionController,
    this.debounceDuration = const Duration(
      milliseconds: 300,
    ),
  });

  // ============================================================
  // TEXTO ALTERADO
  // ============================================================

  void onTextChanged({
    required String text,
    required Iterable<
      Rhyme
    >
    vocabulary,
    VoidCallback? onChanged,
  }) {
    _debounce?.cancel();

    // ==========================================================
    // SUGESTION CONTROLLER PRINCIPAL
    // ==========================================================

    suggestionController.updateFromText(
      text,
    );

    // ==========================================================
    // DEBOUNCE LOCAL
    // ==========================================================

    _debounce = Timer(
      debounceDuration,
      () {
        _processLocalSuggestions(
          text: text,

          vocabulary: vocabulary,

          onChanged: onChanged,
        );
      },
    );
  }

  // ============================================================
  // PROCESSAR SUGESTÕES LOCAIS
  // ============================================================

  void _processLocalSuggestions({
    required String text,
    required Iterable<
      Rhyme
    >
    vocabulary,
    VoidCallback? onChanged,
  }) {
    final normalized = text.trim().toLowerCase();

    // ==========================================================
    // TEXTO VAZIO
    // ==========================================================

    if (normalized.isEmpty) {
      suggestionController.clearSuggestions();

      onChanged?.call();

      return;
    }

    // ==========================================================
    // PALAVRAS
    // ==========================================================

    final words = normalized.split(
      RegExp(
        r'\s+',
      ),
    );

    if (words.isEmpty) {
      return;
    }

    final lastWord = words.last;

    // ==========================================================
    // PALAVRA MUITO CURTA
    // ==========================================================

    if (lastWord.length <
        2) {
      if (suggestionController.suggestions.isEmpty) {
        suggestionController.clearSuggestions();
      }

      onChanged?.call();

      return;
    }

    // ==========================================================
    // SUFIXO
    // ==========================================================

    final suffix = lastWord.substring(
      lastWord.length -
          2,
    );

    // ==========================================================
    // SUGESTÕES DO VOCABULÁRIO
    // ==========================================================

    final localSuggestions = vocabulary
        .map(
          (
            item,
          ) => item.word.trim().toLowerCase(),
        )
        .where(
          (
            word,
          ) {
            if (word.isEmpty) {
              return false;
            }

            if (word ==
                lastWord) {
              return false;
            }

            return word.endsWith(
                  suffix,
                ) ||
                word.startsWith(
                  lastWord,
                );
          },
        )
        .toList();

    if (localSuggestions.isEmpty) {
      onChanged?.call();

      return;
    }

    // ==========================================================
    // MERGE
    // ==========================================================
    //
    // Set remove duplicados mantendo uma implementação simples.
    //
    // ==========================================================

    final combined =
        <
              String
            >{
              ...suggestionController.suggestions,
              ...localSuggestions,
            }
            .toList();

    suggestionController.setSuggestions(
      combined,
    );

    onChanged?.call();
  }

  // ============================================================
  // SUGESTÕES
  // ============================================================

  List<
    String
  >
  get suggestions => suggestionController.suggestions;

  // ============================================================
  // POSSUI SUGESTÕES?
  // ============================================================

  bool get hasSuggestions => suggestionController.suggestions.isNotEmpty;

  // ============================================================
  // LIMPAR
  // ============================================================

  void clear({
    VoidCallback? onChanged,
  }) {
    _debounce?.cancel();

    suggestionController.clearSuggestions();

    onChanged?.call();
  }

  // ============================================================
  // CANCELAR DEBOUNCE
  // ============================================================

  void cancelPending() {
    _debounce?.cancel();

    _debounce = null;
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  void dispose() {
    _debounce?.cancel();

    _debounce = null;
  }
}
