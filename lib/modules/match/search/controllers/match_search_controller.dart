import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:versin/modules/match/data/repositories/match_repository.dart';
import 'package:versin/modules/match/models/match_user_entity.dart';

// ============================================================
// MATCH SEARCH STATE
// ============================================================
//
// Estado isolado da pesquisa do Match.
//
// Contém:
//
// - texto pesquisado;
// - loading;
// - resultados;
// - erro;
// - estado ativo.
//
// NÃO:
//
// - conhece Widgets;
// - acessa Supabase diretamente;
// - controla FocusNode;
// - controla TextEditingController.
//
// ============================================================

class MatchSearchState {
  // ============================================================
  // QUERY
  // ============================================================

  final String query;

  // ============================================================
  // SEARCHING
  // ============================================================

  final bool isSearching;

  // ============================================================
  // RESULTS
  // ============================================================

  final List<
    MatchUserEntity
  >
  results;

  // ============================================================
  // ERROR
  // ============================================================

  final String? errorMessage;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  const MatchSearchState({
    required this.query,
    required this.isSearching,
    required this.results,
    required this.errorMessage,
  });

  // ============================================================
  // INITIAL
  // ============================================================

  const MatchSearchState.initial()
    : query = '',
      isSearching = false,
      results =
          const <
            MatchUserEntity
          >[],
      errorMessage = null;

  // ============================================================
  // ACTIVE
  // ============================================================

  bool get isActive {
    return query.trim().isNotEmpty;
  }

  // ============================================================
  // HAS RESULTS
  // ============================================================

  bool get hasResults {
    return results.isNotEmpty;
  }

  // ============================================================
  // HAS ERROR
  // ============================================================

  bool get hasError {
    final value = errorMessage?.trim();

    return value !=
            null &&
        value.isNotEmpty;
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  MatchSearchState copyWith({
    String? query,
    bool? isSearching,
    List<
      MatchUserEntity
    >?
    results,
    String? errorMessage,
    bool clearError = false,
  }) {
    return MatchSearchState(
      query:
          query ??
          this.query,

      isSearching:
          isSearching ??
          this.isSearching,

      results:
          results ??
          this.results,

      errorMessage: clearError
          ? null
          : errorMessage ??
                this.errorMessage,
    );
  }

  // ============================================================
  // TO STRING
  // ============================================================

  @override
  String toString() {
    return 'MatchSearchState('
        'query: $query, '
        'isSearching: $isSearching, '
        'results: ${results.length}, '
        'errorMessage: $errorMessage'
        ')';
  }
}

// ============================================================
// MATCH SEARCH CONTROLLER
// ============================================================
//
// Responsável exclusivamente pela pesquisa de usuários.
//
// Fluxo:
//
// campo de pesquisa
//      ↓
// MatchSearchController
//      ↓
// MatchRepository.searchUsers()
//      ↓
// MatchUserEntity
//      ↓
// MatchSearchState
//
// O repository continua sendo responsável pela consulta e
// ordenação dos resultados.
//
// ============================================================

class MatchSearchController
    extends
        ChangeNotifier {
  // ============================================================
  // DEPENDENCIES
  // ============================================================

  final MatchRepository repository;

  final String? Function() currentUserIdProvider;

  // ============================================================
  // CONFIG
  // ============================================================

  static const Duration debounceDuration = Duration(
    milliseconds: 350,
  );

  // ============================================================
  // STATE
  // ============================================================

  MatchSearchState _state = const MatchSearchState.initial();

  MatchSearchState get state {
    return _state;
  }

  // ============================================================
  // DEBOUNCE
  // ============================================================

  Timer? _debounce;

  // ============================================================
  // REQUEST VERSION
  // ============================================================
  //
  // Evita que uma pesquisa antiga sobrescreva uma pesquisa nova.
  //
  // Exemplo:
  //
  // "jo"
  //   ↓
  // request lento
  //
  // "joao"
  //   ↓
  // request rápido
  //
  // Se "jo" terminar depois, não pode substituir "joao".
  //
  // ============================================================

  int _requestVersion = 0;

  // ============================================================
  // DISPOSED
  // ============================================================

  bool _disposed = false;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  MatchSearchController({
    required this.repository,
    required this.currentUserIdProvider,
  });

  // ============================================================
  // GETTERS
  // ============================================================

  bool get isActive {
    return _state.isActive;
  }

  bool get isSearching {
    return _state.isSearching;
  }

  String get query {
    return _state.query;
  }

  String? get errorMessage {
    return _state.errorMessage;
  }

  List<
    MatchUserEntity
  >
  get results {
    return _state.results;
  }

  // ============================================================
  // QUERY CHANGED
  // ============================================================

  void onQueryChanged(
    String value,
  ) {
    final normalized = _normalizeInput(
      value,
    );

    // ==========================================================
    // CANCELAR DEBOUNCE ANTERIOR
    // ==========================================================

    _debounce?.cancel();

    // ==========================================================
    // NOVA VERSÃO
    // ==========================================================

    _requestVersion++;

    // ==========================================================
    // VAZIO
    // ==========================================================

    if (normalized.isEmpty) {
      _state = const MatchSearchState.initial();

      _safeNotify();

      return;
    }

    // ==========================================================
    // ATUALIZAR QUERY IMEDIATAMENTE
    // ==========================================================

    _state = MatchSearchState(
      query: normalized,
      isSearching: false,
      results:
          const <
            MatchUserEntity
          >[],
      errorMessage: null,
    );

    _safeNotify();

    // ==========================================================
    // DEBOUNCE
    // ==========================================================

    final version = _requestVersion;

    _debounce = Timer(
      debounceDuration,
      () {
        unawaited(
          _search(
            normalized,
            version: version,
          ),
        );
      },
    );
  }

  // ============================================================
  // SEARCH NOW
  // ============================================================
  //
  // Útil caso futuramente você queira executar a pesquisa
  // imediatamente sem esperar o debounce.
  //
  // ============================================================

  Future<
    void
  >
  searchNow(
    String value,
  ) async {
    _debounce?.cancel();

    final normalized = _normalizeInput(
      value,
    );

    _requestVersion++;

    final version = _requestVersion;

    if (normalized.isEmpty) {
      clear();

      return;
    }

    _state = _state.copyWith(
      query: normalized,
      clearError: true,
    );

    _safeNotify();

    await _search(
      normalized,
      version: version,
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Future<
    void
  >
  _search(
    String query, {
    required int version,
  }) async {
    if (_disposed) {
      return;
    }

    // ==========================================================
    // REQUEST OBSOLETA
    // ==========================================================

    if (version !=
        _requestVersion) {
      return;
    }

    // ==========================================================
    // LOADING
    // ==========================================================

    _state = _state.copyWith(
      query: query,
      isSearching: true,
      results:
          const <
            MatchUserEntity
          >[],
      clearError: true,
    );

    _safeNotify();

    try {
      final currentUserId = currentUserIdProvider()?.trim();

      debugPrint(
        '[MATCH SEARCH] '
        'Pesquisando: '
        '"$query"',
      );

      // ========================================================
      // REPOSITORY
      // ========================================================

      final foundUsers = await repository.searchUsers(
        query: query,
        currentUserId: currentUserId,
      );

      // ========================================================
      // CONTROLLER ENCERRADO
      // ========================================================

      if (_disposed) {
        return;
      }

      // ========================================================
      // REQUEST OBSOLETA
      // ========================================================

      if (version !=
          _requestVersion) {
        debugPrint(
          '[MATCH SEARCH] '
          'Resultado ignorado porque existe '
          'uma pesquisa mais recente.',
        );

        return;
      }

      // ========================================================
      // RESULT
      // ========================================================

      _state = MatchSearchState(
        query: query,
        isSearching: false,
        results:
            List<
              MatchUserEntity
            >.unmodifiable(
              foundUsers,
            ),
        errorMessage: null,
      );

      debugPrint(
        '[MATCH SEARCH] '
        '${foundUsers.length} '
        'resultado(s) encontrado(s).',
      );

      _safeNotify();
    } catch (
      error,
      stackTrace
    ) {
      if (_disposed ||
          version !=
              _requestVersion) {
        return;
      }

      debugPrint(
        '[MATCH SEARCH] '
        'Erro ao pesquisar usuários: '
        '$error',
      );

      debugPrint(
        '[MATCH SEARCH] '
        'Stack trace: '
        '$stackTrace',
      );

      _state = MatchSearchState(
        query: query,
        isSearching: false,
        results:
            const <
              MatchUserEntity
            >[],
        errorMessage: 'Não foi possível realizar a pesquisa.',
      );

      _safeNotify();
    }
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<
    void
  >
  refresh() async {
    final currentQuery = _state.query.trim();

    if (currentQuery.isEmpty) {
      return;
    }

    _debounce?.cancel();

    _requestVersion++;

    await _search(
      currentQuery,
      version: _requestVersion,
    );
  }

  // ============================================================
  // CLEAR
  // ============================================================

  void clear() {
    _debounce?.cancel();

    _debounce = null;

    _requestVersion++;

    _state = const MatchSearchState.initial();

    _safeNotify();
  }

  // ============================================================
  // NORMALIZE
  // ============================================================

  String _normalizeInput(
    String value,
  ) {
    return value.trim();
  }

  // ============================================================
  // SAFE NOTIFY
  // ============================================================

  void _safeNotify() {
    if (_disposed) {
      return;
    }

    notifyListeners();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _disposed = true;

    _debounce?.cancel();

    _debounce = null;

    super.dispose();
  }
}
