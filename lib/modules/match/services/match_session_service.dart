import 'package:flutter/foundation.dart';

import 'package:versin/modules/match/controllers/match_controllers.dart';
import 'package:versin/modules/match/data/repositories/match_repository.dart';

import 'package:versin/modules/profile/controllers/professional_profile_controller.dart';

// ============================================================
// MATCH SESSION SERVICE
// ============================================================
//
// Orquestra o ciclo de vida da sessão do Match.
//
// Responsabilidades:
//
// - carregar perfil profissional;
// - inicializar MatchController;
// - iniciar stream de candidatos;
// - reiniciar sessão;
// - atualizar perfil profissional;
// - interromper stream;
// - impedir execuções concorrentes.
//
// NÃO:
//
// - controla UI;
// - usa BuildContext;
// - acessa Cloudflare R2;
// - reproduz demos;
// - controla perfil público;
// - navega entre páginas.
//
// ============================================================

class MatchSessionService {
  // ============================================================
  // DEPENDÊNCIAS
  // ============================================================

  final MatchController _matchController;

  final MatchRepository _matchRepository;

  final ProfessionalProfileController _professionalProfileController;

  // ============================================================
  // ESTADO
  // ============================================================

  bool _isInitializing = false;

  bool _isInitialized = false;

  bool _isRestarting = false;

  bool _isDisposed = false;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  MatchSessionService({
    required MatchController matchController,
    required MatchRepository matchRepository,
    required ProfessionalProfileController professionalProfileController,
  }) : _matchController = matchController,
       _matchRepository = matchRepository,
       _professionalProfileController = professionalProfileController;

  // ============================================================
  // GETTERS
  // ============================================================

  bool get isInitializing => _isInitializing;

  bool get isInitialized => _isInitialized;

  bool get isRestarting => _isRestarting;

  bool get isDisposed => _isDisposed;

  // ============================================================
  // INICIALIZAR
  // ============================================================
  //
  // Fluxo:
  //
  // perfil profissional
  //      ↓
  // MatchController
  //      ↓
  // stream de candidatos
  //
  // ============================================================

  Future<
    void
  >
  initialize() async {
    if (_isDisposed ||
        _isInitializing ||
        _isInitialized) {
      return;
    }

    _isInitializing = true;

    _logSeparator();

    debugPrint(
      '[MATCH SESSION] '
      'Inicializando sessão.',
    );

    try {
      // ========================================================
      // PERFIL PROFISSIONAL
      // ========================================================

      await _professionalProfileController.load();

      if (_isDisposed) {
        return;
      }

      _logProfessionalProfile();

      // ========================================================
      // MATCH CONTROLLER
      // ========================================================

      await _matchController.initMatchSession();

      if (_isDisposed) {
        return;
      }

      // ========================================================
      // STREAM
      // ========================================================

      _startMatchStream();

      _isInitialized = true;

      debugPrint(
        '[MATCH SESSION] '
        'Sessão inicializada.',
      );
    } catch (
      error,
      stackTrace
    ) {
      _isInitialized = false;

      _logError(
        operation: 'inicializar sessão',
        error: error,
        stackTrace: stackTrace,
      );

      rethrow;
    } finally {
      _isInitializing = false;

      _logSeparator();
    }
  }

  // ============================================================
  // REINICIAR
  // ============================================================
  //
  // Usado quando dados que influenciam o Match mudam:
  //
  // - função principal;
  // - funções profissionais;
  // - profissionais procurados.
  //
  // ============================================================

  Future<
    void
  >
  restart() async {
    if (_isDisposed ||
        _isRestarting) {
      return;
    }

    _isRestarting = true;

    _logSeparator();

    debugPrint(
      '[MATCH SESSION] '
      'Reiniciando sessão.',
    );

    try {
      // ========================================================
      // PARAR STREAM
      // ========================================================

      await _matchRepository.stopStreaming();

      if (_isDisposed) {
        return;
      }

      // ========================================================
      // LIMPAR RESULTADOS
      // ========================================================

      _matchController.clearMatchResults();

      // ========================================================
      // REINICIAR CONTROLLER
      // ========================================================

      await _matchController.initMatchSession();

      if (_isDisposed) {
        return;
      }

      // ========================================================
      // NOVO STREAM
      // ========================================================

      _startMatchStream();

      _isInitialized = true;

      debugPrint(
        '[MATCH SESSION] '
        'Sessão reiniciada.',
      );
    } catch (
      error,
      stackTrace
    ) {
      _isInitialized = false;

      _logError(
        operation: 'reiniciar sessão',
        error: error,
        stackTrace: stackTrace,
      );

      rethrow;
    } finally {
      _isRestarting = false;

      _logSeparator();
    }
  }

  // ============================================================
  // ATUALIZAR PERFIL E REINICIAR
  // ============================================================
  //
  // Fluxo:
  //
  // ProfessionalProfileSettingsPage
  //            ↓
  // refresh()
  //            ↓
  // restart()
  //
  // ============================================================

  Future<
    void
  >
  refreshProfileAndRestart() async {
    if (_isDisposed) {
      return;
    }

    debugPrint(
      '[MATCH SESSION] '
      'Atualizando perfil profissional.',
    );

    // ==========================================================
    // PERFIL
    // ==========================================================

    await _professionalProfileController.refresh();

    if (_isDisposed) {
      return;
    }

    _logProfessionalProfile();

    // ==========================================================
    // MATCH
    // ==========================================================

    await restart();
  }

  // ============================================================
  // PARAR
  // ============================================================

  Future<
    void
  >
  stop() async {
    if (_isDisposed) {
      return;
    }

    debugPrint(
      '[MATCH SESSION] '
      'Parando sessão.',
    );

    try {
      await _matchRepository.stopStreaming();

      _isInitialized = false;

      debugPrint(
        '[MATCH SESSION] '
        'Sessão parada.',
      );
    } catch (
      error,
      stackTrace
    ) {
      _logError(
        operation: 'parar sessão',
        error: error,
        stackTrace: stackTrace,
      );

      rethrow;
    }
  }

  // ============================================================
  // INICIAR STREAM
  // ============================================================

  void _startMatchStream() {
    if (_isDisposed) {
      return;
    }

    _matchRepository.streamCrossRoleMatches(
      _matchController,
    );
  }

  // ============================================================
  // LOG PERFIL PROFISSIONAL
  // ============================================================

  void _logProfessionalProfile() {
    if (_isDisposed) {
      return;
    }

    final primaryRole =
        _professionalProfileController.primaryRole?.key ??
        'não informado';

    final roles = _professionalProfileController.selectedRoles
        .map(
          (
            role,
          ) {
            return role.key;
          },
        )
        .toList(
          growable: false,
        );

    final lookingFor = _professionalProfileController.lookingForRoles
        .map(
          (
            role,
          ) {
            return role.key;
          },
        )
        .toList(
          growable: false,
        );

    debugPrint(
      '[MATCH SESSION] '
      'Função principal: '
      '$primaryRole',
    );

    debugPrint(
      '[MATCH SESSION] '
      'Funções: '
      '$roles',
    );

    debugPrint(
      '[MATCH SESSION] '
      'Procura: '
      '$lookingFor',
    );
  }

  // ============================================================
  // LOG ERROR
  // ============================================================

  void _logError({
    required String operation,
    required Object error,
    required StackTrace stackTrace,
  }) {
    debugPrint(
      '[MATCH SESSION] '
      'Erro ao $operation: '
      '$error',
    );

    debugPrint(
      '[MATCH SESSION] '
      'StackTrace: '
      '$stackTrace',
    );
  }

  // ============================================================
  // SEPARATOR
  // ============================================================

  void _logSeparator() {
    debugPrint(
      '[MATCH SESSION] '
      '========================================',
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================
  //
  // Este service encerra apenas o que ele coordena.
  //
  // NÃO chama:
  //
  // _matchController.dispose()
  //
  // Quem criou o controller decide quando destruí-lo.
  //
  // ============================================================

  Future<
    void
  >
  dispose() async {
    if (_isDisposed) {
      return;
    }

    // ==========================================================
    // MARCAR COMO ENCERRADO
    // ==========================================================

    _isDisposed = true;

    // ==========================================================
    // PARAR STREAM
    // ==========================================================

    try {
      await _matchRepository.stopStreaming();
    } catch (
      error
    ) {
      debugPrint(
        '[MATCH SESSION] '
        'Erro ao encerrar stream: '
        '$error',
      );
    }

    // ==========================================================
    // LIMPAR ESTADO
    // ==========================================================

    _isInitializing = false;

    _isRestarting = false;

    _isInitialized = false;

    debugPrint(
      '[MATCH SESSION] '
      'Service encerrado.',
    );
  }
}
