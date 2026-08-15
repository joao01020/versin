import 'package:versin/modules/match/models/match_user_entity.dart';

// ============================================================
// MATCH SEARCH STATE
// ============================================================
//
// Estado imutável da pesquisa de usuários.
//
// Responsabilidades:
//
// - armazenar query atual;
// - informar se a pesquisa está ativa;
// - informar se está carregando;
// - armazenar erro;
// - armazenar resultados.
//
// Este model NÃO:
//
// - executa pesquisa;
// - acessa Supabase;
// - possui debounce;
// - conhece BuildContext;
// - conhece widgets.
//
// Fluxo:
//
// MatchSearchController
//        ↓
// MatchSearchState
//        ↓
// MatchSearchPanelWidget
// MatchSearchResultsWidget
//
// ============================================================

class MatchSearchState {
  // ============================================================
  // QUERY
  // ============================================================

  final String query;

  // ============================================================
  // ESTADOS
  // ============================================================

  final bool isActive;

  final bool isSearching;

  // ============================================================
  // ERRO
  // ============================================================

  final String? errorMessage;

  // ============================================================
  // RESULTADOS
  // ============================================================

  final List<
    MatchUserEntity
  >
  results;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  const MatchSearchState({
    this.query = '',
    this.isActive = false,
    this.isSearching = false,
    this.errorMessage,
    this.results =
        const <
          MatchUserEntity
        >[],
  });

  // ============================================================
  // ESTADO INICIAL
  // ============================================================

  const MatchSearchState.initial()
    : query =
          '',
      isActive = false,
      isSearching = false,
      errorMessage = null,
      results =
          const <
            MatchUserEntity
          >[];

  // ============================================================
  // GETTERS
  // ============================================================

  bool get hasQuery {
    return query.trim().isNotEmpty;
  }

  bool get hasResults {
    return results.isNotEmpty;
  }

  bool get hasError {
    return errorMessage !=
            null &&
        errorMessage!.trim().isNotEmpty;
  }

  bool get isEmpty {
    return isActive &&
        !isSearching &&
        !hasError &&
        results.isEmpty;
  }

  int get resultCount {
    return results.length;
  }

  // ============================================================
  // COPY WITH
  // ============================================================
  //
  // clearError:
  //
  // true
  // → força errorMessage = null
  //
  // false
  // → mantém o valor atual quando errorMessage não é informado.
  //
  // ============================================================

  MatchSearchState copyWith({
    String? query,
    bool? isActive,
    bool? isSearching,
    String? errorMessage,
    bool clearError = false,
    List<
      MatchUserEntity
    >?
    results,
  }) {
    return MatchSearchState(
      query:
          query ??
          this.query,
      isActive:
          isActive ??
          this.isActive,
      isSearching:
          isSearching ??
          this.isSearching,
      errorMessage: clearError
          ? null
          : errorMessage ??
                this.errorMessage,
      results:
          results ??
          this.results,
    );
  }

  // ============================================================
  // ATIVAR PESQUISA
  // ============================================================

  MatchSearchState activate({
    required String query,
  }) {
    return copyWith(
      query: query.trim(),
      isActive: true,
      isSearching: false,
      clearError: true,
    );
  }

  // ============================================================
  // INICIAR LOADING
  // ============================================================

  MatchSearchState startLoading({
    String? query,
  }) {
    return copyWith(
      query: query?.trim(),
      isActive: true,
      isSearching: true,
      clearError: true,
    );
  }

  // ============================================================
  // SUCESSO
  // ============================================================

  MatchSearchState success({
    required String query,
    required List<
      MatchUserEntity
    >
    results,
  }) {
    return MatchSearchState(
      query: query.trim(),
      isActive: true,
      isSearching: false,
      errorMessage: null,
      results:
          List<
            MatchUserEntity
          >.unmodifiable(
            results,
          ),
    );
  }

  // ============================================================
  // ERRO
  // ============================================================

  MatchSearchState failure({
    required String query,
    required String message,
  }) {
    return MatchSearchState(
      query: query.trim(),
      isActive: true,
      isSearching: false,
      errorMessage: message.trim(),
      results:
          const <
            MatchUserEntity
          >[],
    );
  }

  // ============================================================
  // LIMPAR
  // ============================================================

  MatchSearchState clear() {
    return const MatchSearchState.initial();
  }

  // ============================================================
  // DEBUG
  // ============================================================

  @override
  String toString() {
    return 'MatchSearchState('
        'query: $query, '
        'isActive: $isActive, '
        'isSearching: $isSearching, '
        'hasError: $hasError, '
        'resultCount: $resultCount'
        ')';
  }
}
