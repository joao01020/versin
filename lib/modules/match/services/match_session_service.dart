import 'package:flutter/foundation.dart';

import 'package:versin/modules/match/controllers/match_controllers.dart';
import 'package:versin/modules/match/data/repositories/match_repository.dart';
import 'package:versin/modules/match/models/match_discovery_mode.dart';
import 'package:versin/modules/match/services/match_location_service.dart';

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
// - alterar modo de descoberta;
// - capturar localização ao entrar em nearby;
// - salvar latitude/longitude antes do stream nearby;
// - reiniciar o stream ao trocar o modo;
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

  final MatchLocationService _matchLocationService;

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
    MatchLocationService? matchLocationService,
  }) : _matchController = matchController,
       _matchRepository = matchRepository,
       _professionalProfileController = professionalProfileController,
       _matchLocationService = matchLocationService ?? MatchLocationService();

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

  Future<void> initialize() async {
    if (_isDisposed || _isInitializing || _isInitialized) {
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
      // LOCALIZAÇÃO
      // ========================================================

      final locationReady = await _prepareLocationForCurrentMode();

      if (_isDisposed) {
        return;
      }

      if (!locationReady) {
        debugPrint(
          '[MATCH SESSION] '
          'Stream não iniciado: localização necessária indisponível.',
        );

        _matchController.clearMatchResults();

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
    } catch (error, stackTrace) {
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

  Future<void> restart() async {
    if (_isDisposed || _isRestarting) {
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
      // LOCALIZAÇÃO
      // ========================================================

      final locationReady = await _prepareLocationForCurrentMode();

      if (_isDisposed) {
        return;
      }

      if (!locationReady) {
        debugPrint(
          '[MATCH SESSION] '
          'Reinício interrompido: localização necessária indisponível.',
        );

        _matchController.clearMatchResults();

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
    } catch (error, stackTrace) {
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
  // ALTERAR MODO DE DESCOBERTA
  // ============================================================
  //
  // Fluxo:
  //
  // UI
  //   ↓
  // changeDiscoveryMode()
  //   ↓
  // MatchController.setDiscoveryMode()
  //   ↓
  // parar stream atual
  //   ↓
  // iniciar novo stream
  //   ↓
  // Repository lê controller.discoveryMode
  //
  // ============================================================

  Future<void> changeDiscoveryMode(MatchDiscoveryMode mode) async {
    if (_isDisposed || _isRestarting) {
      return;
    }

    final currentMode = _matchController.discoveryMode;

    final sameMode = currentMode == mode;

    // ==========================================================
    // MESMO MODO
    // ==========================================================
    //
    // Para compatible/global não há nada a refazer.
    //
    // Para nearby NÃO podemos simplesmente retornar:
    //
    // - a localização pode ainda não ter sido capturada;
    // - a permissão pode ter sido concedida depois;
    // - latitude/longitude podem estar nulas ou antigas.
    //
    // Por isso nearby sempre força uma nova tentativa de captura.
    //
    // ==========================================================

    if (sameMode && mode != MatchDiscoveryMode.nearby) {
      return;
    }

    _isRestarting = true;

    _logSeparator();

    debugPrint(
      '[MATCH SESSION] '
      '${sameMode ? "Revalidando" : "Alterando"} '
      'modo de descoberta: ${mode.name}',
    );

    try {
      // ========================================================
      // PARAR STREAM ATUAL
      // ========================================================

      await _matchRepository.stopStreaming();

      if (_isDisposed) {
        return;
      }

      // ========================================================
      // ALTERAR MODO
      // ========================================================

      if (!sameMode) {
        _matchController.setDiscoveryMode(mode);
      }

      if (_isDisposed) {
        return;
      }

      // ========================================================
      // PREPARAR LOCALIZAÇÃO
      // ========================================================

      final locationReady = await _prepareLocationForCurrentMode();

      if (_isDisposed) {
        return;
      }

      // ========================================================
      // NEARBY SEM LOCALIZAÇÃO
      // ========================================================
      //
      // Não iniciamos o Repository com latitude/longitude nulas.
      //
      // Isso evita exatamente o estado:
      //
      // Location enabled: false
      // Latitude: null
      // Longitude: null
      //
      // ========================================================

      if (!locationReady) {
        debugPrint(
          '[MATCH SESSION] '
          'Modo nearby não pôde ser iniciado.',
        );

        debugPrint(
          '[MATCH SESSION] '
          'A localização atual não está disponível.',
        );

        _matchController.clearMatchResults();

        _isInitialized = true;

        return;
      }

      // ========================================================
      // INICIAR NOVO STREAM
      // ========================================================

      _startMatchStream();

      _isInitialized = true;

      debugPrint(
        '[MATCH SESSION] '
        'Modo ativo: '
        '${_matchController.discoveryMode.name}',
      );
    } catch (error, stackTrace) {
      _logError(
        operation: 'alterar modo de descoberta',
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

  Future<void> refreshProfileAndRestart() async {
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

  Future<void> stop() async {
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
    } catch (error, stackTrace) {
      _logError(
        operation: 'parar sessão',
        error: error,
        stackTrace: stackTrace,
      );

      rethrow;
    }
  }

  // ============================================================
  // PREPARAR LOCALIZAÇÃO PARA O MODO ATUAL
  // ============================================================
  //
  // A localização só é necessária no modo nearby.
  //
  // Nos modos compatible e global este método não faz nada.
  //
  // ============================================================

  Future<bool> _prepareLocationForCurrentMode() async {
    if (_isDisposed) {
      return false;
    }

    // ==========================================================
    // OUTROS MODOS
    // ==========================================================

    if (_matchController.discoveryMode != MatchDiscoveryMode.nearby) {
      return true;
    }

    // ==========================================================
    // NEARBY
    // ==========================================================

    debugPrint(
      '[MATCH SESSION] '
      'Modo nearby: iniciando captura de localização.',
    );

    try {
      // ========================================================
      // CAPTURAR E SALVAR
      // ========================================================
      //
      // updateCurrentLocation():
      //
      // - verifica serviço de localização;
      // - verifica/solicita permissão;
      // - obtém a posição;
      // - salva latitude;
      // - salva longitude;
      // - define location_enabled = true;
      // - atualiza location_updated_at.
      //
      // ========================================================

      final position = await _matchLocationService.updateCurrentLocation();

      if (_isDisposed) {
        return false;
      }

      // ========================================================
      // FALHA
      // ========================================================

      if (position == null) {
        debugPrint(
          '[MATCH SESSION] '
          'Falha ao capturar localização para nearby.',
        );

        debugPrint(
          '[MATCH SESSION] '
          'Verifique serviço de localização e permissões.',
        );

        return false;
      }

      // ========================================================
      // SUCESSO
      // ========================================================

      debugPrint(
        '[MATCH SESSION] '
        'Localização capturada e salva.',
      );

      debugPrint(
        '[MATCH SESSION] '
        'Latitude: ${position.latitude}',
      );

      debugPrint(
        '[MATCH SESSION] '
        'Longitude: ${position.longitude}',
      );

      debugPrint(
        '[MATCH SESSION] '
        'Precisão: ${position.accuracy.toStringAsFixed(1)} m',
      );

      return true;
    } catch (error, stackTrace) {
      debugPrint(
        '[MATCH SESSION] '
        'Erro ao preparar localização para nearby: $error',
      );

      debugPrint(
        '[MATCH SESSION] '
        'StackTrace: $stackTrace',
      );

      return false;
    }
  }

  // ============================================================
  // INICIAR STREAM
  // ============================================================

  void _startMatchStream() {
    if (_isDisposed) {
      return;
    }

    debugPrint(
      '[MATCH SESSION] '
      'Iniciando stream no modo '
      '${_matchController.discoveryMode.name}.',
    );

    _matchRepository.streamCrossRoleMatches(_matchController);
  }

  // ============================================================
  // LOG PERFIL PROFISSIONAL
  // ============================================================

  void _logProfessionalProfile() {
    if (_isDisposed) {
      return;
    }

    final primaryRole =
        _professionalProfileController.primaryRole?.key ?? 'não informado';

    final roles = _professionalProfileController.selectedRoles
        .map((role) {
          return role.key;
        })
        .toList(growable: false);

    final lookingFor = _professionalProfileController.lookingForRoles
        .map((role) {
          return role.key;
        })
        .toList(growable: false);

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

  Future<void> dispose() async {
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
    } catch (error) {
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
