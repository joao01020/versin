import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:versin/modules/match/data/repositories/match_repository.dart';
import 'package:versin/modules/match/models/match_search_state.dart';

// ============================================================
// MATCH SEARCH CONTROLLER
// ============================================================
//
// Controller responsável exclusivamente pela pesquisa manual
// de usuários dentro do módulo Match.
//
// Responsabilidades:
//
// - receber texto pesquisado;
// - aplicar debounce;
// - executar busca no repository;
// - evitar resultado antigo;
// - controlar loading;
// - controlar erro;
// - controlar resultados;
// - limpar pesquisa.
//
// Este controller NÃO:
//
// - controla Discovery;
// - controla recomendações;
// - inicia sessão Match;
// - acessa BuildContext;
// - desenha widgets;
// - navega entre páginas.
//
// Fluxo:
//
// MatchPage
//    ↓
// MatchSearchController
//    ↓
// MatchRepository
//    ↓
// MatchRemoteDatasource
//    ↓
// Supabase
//
// ============================================================

class MatchSearchController
    extends
        ChangeNotifier {
  // ============================================================
  // CONFIGURAÇÃO
  // ============================================================

  static const Duration _debounceDuration = Duration(
    milliseconds: 350,
  );

  // ============================================================
  // DEPENDÊNCIAS
  // ============================================================

  final MatchRepository _repository;

  final String? Function() _currentUserIdProvider;

  // ============================================================
  // ESTADO
  // ============================================================

  MatchSearchState _state = const MatchSearchState.initial();

  // ============================================================
  // DEBOUNCE
  // ============================================================

  Timer? _debounce;

  // ============================================================
  // CONTROLE DE REQUEST
  // ============================================================

  int _requestVersion = 0;

  // ============================================================
  // DISPOSE
  // ============================================================

  bool _disposed = false;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  MatchSearchController({
    required MatchRepository repository,
    required String? Function() currentUserIdProvider,
  }) : _repository = repository,
       _currentUserIdProvider = currentUserIdProvider;

  // ============================================================
  // GETTERS
  // ============================================================

  MatchSearchState get state => _state;

  bool get isActive => _state.isActive;

  bool get isSearching => _state.isSearching;

  bool get hasResults => _state.hasResults;

  bool get hasError => _state.hasError;

  bool get isEmpty => _state.isEmpty;

  String get query => _state.query;

  String? get errorMessage => _state.errorMessage;

  int get resultCount => _state.resultCount;

  // ============================================================
  // ALTERAÇÃO DO TEXTO
  // ============================================================

  void onQueryChanged(
    String value,
  ) {
    if (_disposed) {
      return;
    }

    // ==========================================================
    // CANCELAR DEBOUNCE ANTERIOR
    // ==========================================================

    _debounce?.cancel();

    _debounce = null;

    // ==========================================================
    // NORMALIZAR
    // ==========================================================

    final normalized = _normalizeQuery(
      value,
    );

    // ==========================================================
    // CAMPO VAZIO
    // ==========================================================

    if (normalized.isEmpty) {
      clear();

      return;
    }

    // ==========================================================
    // ATIVAR ESTADO
    // ==========================================================

    _state = _state.activate(
      query: normalized,
    );

    _notify();

    // ==========================================================
    // DEBOUNCE
    // ==========================================================

    _debounce = Timer(
      _debounceDuration,
      () {
        unawaited(
          search(
            normalized,
          ),
        );
      },
    );
  }

  // ============================================================
  // PESQUISAR
  // ============================================================

  Future<
    void
  >
  search(
    String value,
  ) async {
    if (_disposed) {
      return;
    }

    // ==========================================================
    // NORMALIZAR
    // ==========================================================

    final normalizedQuery = _normalizeQuery(
      value,
    );

    if (normalizedQuery.isEmpty) {
      clear();

      return;
    }

    // ==========================================================
    // REQUEST VERSION
    // ==========================================================
    //
    // Cada pesquisa recebe uma versão.
    //
    // Se:
    //
    // usuário digita "jo"
    // usuário digita "joao"
    //
    // e a resposta de "jo" chega por último,
    // ela não pode sobrescrever "joao".
    //
    // ==========================================================

    final requestVersion = ++_requestVersion;

    // ==========================================================
    // LOADING
    // ==========================================================

    _state = _state.startLoading(
      query: normalizedQuery,
    );

    _notify();

    // ==========================================================
    // LOG
    // ==========================================================

    debugPrint(
      '[MATCH SEARCH] '
      'Pesquisando: $normalizedQuery',
    );

    try {
      // ========================================================
      // USER ID
      // ========================================================

      final currentUserId = _currentUserIdProvider()?.trim();

      // ========================================================
      // REPOSITORY
      // ========================================================

      final users = await _repository.searchUsers(
        query: normalizedQuery,
        currentUserId: currentUserId,
      );

      // ========================================================
      // CONTROLLER ENCERRADO
      // ========================================================

      if (_disposed) {
        return;
      }

      // ========================================================
      // REQUEST ANTIGA
      // ========================================================

      if (requestVersion !=
          _requestVersion) {
        debugPrint(
          '[MATCH SEARCH] '
          'Resultado antigo ignorado: '
          '$normalizedQuery',
        );

        return;
      }

      // ========================================================
      // QUERY MUDOU
      // ========================================================

      if (_state.query !=
          normalizedQuery) {
        return;
      }

      // ========================================================
      // SUCESSO
      // ========================================================

      _state = _state.success(
        query: normalizedQuery,
        results: users,
      );

      _notify();

      debugPrint(
        '[MATCH SEARCH] '
        '${users.length} resultado(s).',
      );
    } catch (
      error,
      stackTrace
    ) {
      if (_disposed) {
        return;
      }

      // ========================================================
      // REQUEST ANTIGA
      // ========================================================

      if (requestVersion !=
          _requestVersion) {
        return;
      }

      // ========================================================
      // LOG
      // ========================================================

      debugPrint(
        '[MATCH SEARCH] '
        'Erro na pesquisa: $error',
      );

      debugPrint(
        '[MATCH SEARCH] '
        'StackTrace: $stackTrace',
      );

      // ========================================================
      // ESTADO DE ERRO
      // ========================================================

      _state = _state.failure(
        query: normalizedQuery,
        message: 'Não foi possível pesquisar usuários.',
      );

      _notify();
    }
  }

  // ============================================================
  // PESQUISAR IMEDIATAMENTE
  // ============================================================
  //
  // Útil caso posteriormente você queira executar a busca ao
  // pressionar ENTER sem aguardar o debounce.
  //
  // ============================================================

  Future<
    void
  >
  searchImmediately(
    String value,
  ) async {
    if (_disposed) {
      return;
    }

    _debounce?.cancel();

    _debounce = null;

    await search(
      value,
    );
  }

  // ============================================================
  // LIMPAR
  // ============================================================

  void clear() {
    if (_disposed) {
      return;
    }

    // ==========================================================
    // CANCELAR DEBOUNCE
    // ==========================================================

    _debounce?.cancel();

    _debounce = null;

    // ==========================================================
    // INVALIDAR REQUEST EM ANDAMENTO
    // ==========================================================

    _requestVersion++;

    // ==========================================================
    // ESTADO INICIAL
    // ==========================================================

    _state = const MatchSearchState.initial();

    _notify();

    debugPrint(
      '[MATCH SEARCH] '
      'Pesquisa limpa.',
    );
  }

  // ============================================================
  // CANCELAR PESQUISA
  // ============================================================
  //
  // Diferente de clear(), este método existe semanticamente para
  // fechar o painel de pesquisa.
  //
  // Atualmente ambos resultam no mesmo estado.
  //
  // ============================================================

  void cancel() {
    clear();
  }

  // ============================================================
  // RETRY
  // ============================================================

  Future<
    void
  >
  retry() async {
    if (_disposed) {
      return;
    }

    final currentQuery = _state.query.trim();

    if (currentQuery.isEmpty) {
      return;
    }

    await search(
      currentQuery,
    );
  }

  // ============================================================
  // NORMALIZAR QUERY
  // ============================================================
  //
  // O repository / datasource também pode normalizar por
  // segurança, mas fazemos isso aqui porque o estado da UI deve
  // trabalhar sempre com uma query consistente.
  //
  // Exemplos:
  //
  // " João "
  //      ↓
  // "joão"
  //
  // "@astryvo"
  //      ↓
  // "astryvo"
  //
  // ============================================================

  String _normalizeQuery(
    String value,
  ) {
    return value.trim().toLowerCase().replaceFirst(
      RegExp(
        r'^@+',
      ),
      '',
    );
  }

  // ============================================================
  // NOTIFY
  // ============================================================

  void _notify() {
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
    if (_disposed) {
      return;
    }

    _disposed = true;

    // ==========================================================
    // DEBOUNCE
    // ==========================================================

    _debounce?.cancel();

    _debounce = null;

    // ==========================================================
    // INVALIDAR REQUEST
    // ==========================================================

    _requestVersion++;

    super.dispose();
  }
}
