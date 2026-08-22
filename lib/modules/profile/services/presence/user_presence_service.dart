import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'package:versin/modules/public_profile/repositories/public_profile_repository.dart';

// ============================================================
// USER PRESENCE SERVICE
// ============================================================
//
// Responsável por manter a presença REAL do usuário.
//
// Conceito:
//
// is_online
//   = preferência do usuário.
//
// last_seen_at
//   = último heartbeat recebido pelo backend.
//
// Usuário realmente online:
//
// is_online == true
// &&
// last_seen_at recente
//
// Este service:
//
// - envia heartbeat periódico;
// - pausa heartbeat quando o app sai de foreground;
// - volta a enviar quando o app retorna;
// - respeita a preferência ONLINE/OFFLINE;
// - não depende do app conseguir executar código ao fechar;
// - não altera diretamente tabelas do Supabase.
//
// Backend:
//
// PublicProfileRepository
//        ↓
// PublicProfileRemoteDatasource
//        ↓
// RPC update_my_presence()
//        ↓
// public.profiles.last_seen_at
//
// ============================================================

class UserPresenceService
    with
        WidgetsBindingObserver {
  // ============================================================
  // CONFIGURAÇÃO
  // ============================================================
  //
  // Backend considera presença válida por 90 segundos.
  //
  // Heartbeat a cada 30 segundos deixa uma margem confortável
  // para atrasos de rede e suspensão momentânea.
  //
  // ============================================================

  static const Duration heartbeatInterval = Duration(
    seconds: 30,
  );

  // ============================================================
  // DEPENDÊNCIAS
  // ============================================================

  final PublicProfileRepository _repository;

  // ============================================================
  // TIMER
  // ============================================================

  Timer? _heartbeatTimer;

  // ============================================================
  // ESTADO
  // ============================================================

  bool _started = false;

  bool _disposed = false;

  bool _userWantsToAppearOnline = false;

  bool _appIsActive = true;

  bool _heartbeatInProgress = false;

  DateTime? _lastHeartbeatAt;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  UserPresenceService({
    required PublicProfileRepository repository,
  }) : _repository = repository;

  // ============================================================
  // GETTERS
  // ============================================================

  bool get isStarted => _started;

  bool get isDisposed => _disposed;

  bool get userWantsToAppearOnline => _userWantsToAppearOnline;

  bool get appIsActive => _appIsActive;

  bool get heartbeatInProgress => _heartbeatInProgress;

  DateTime? get lastHeartbeatAt => _lastHeartbeatAt;

  bool get shouldSendHeartbeat =>
      !_disposed &&
      _started &&
      _userWantsToAppearOnline &&
      _appIsActive;

  // ============================================================
  // START
  // ============================================================
  //
  // Deve ser chamado depois que:
  //
  // - usuário autenticou;
  // - perfil foi carregado;
  // - sabemos o valor atual de is_online.
  //
  // Exemplo:
  //
  // await presenceService.start(
  //   wantsToAppearOnline: profile.isOnline,
  // );
  //
  // ============================================================

  Future<
    void
  >
  start({
    required bool wantsToAppearOnline,
  }) async {
    if (_disposed) {
      return;
    }

    _userWantsToAppearOnline = wantsToAppearOnline;

    if (!_started) {
      _started = true;

      WidgetsBinding.instance.addObserver(
        this,
      );
    }

    _appIsActive = _resolveCurrentAppActiveState();

    _restartHeartbeatTimer();

    if (shouldSendHeartbeat) {
      await sendHeartbeat();
    }

    debugPrint(
      '[PRESENCE] Service iniciado. '
      'Preferência online: $_userWantsToAppearOnline | '
      'App ativo: $_appIsActive',
    );
  }

  // ============================================================
  // ATUALIZAR PREFERÊNCIA
  // ============================================================
  //
  // Deve ser chamado sempre que o usuário usar:
  //
  // "Deixar perfil online"
  // "Deixar perfil offline"
  //
  // IMPORTANTE:
  //
  // O Controller/Repository continua responsável por persistir
  // is_online através de set_my_online_preference().
  //
  // Este service apenas acompanha o novo estado.
  //
  // ============================================================

  Future<
    void
  >
  setOnlinePreference(
    bool value,
  ) async {
    if (_disposed) {
      return;
    }

    if (_userWantsToAppearOnline ==
        value) {
      if (value &&
          shouldSendHeartbeat) {
        await sendHeartbeat();
      }

      return;
    }

    _userWantsToAppearOnline = value;

    debugPrint(
      '[PRESENCE] '
      'Preferência alterada para '
      '${value ? 'ONLINE' : 'OFFLINE'}.',
    );

    // ==========================================================
    // OFFLINE
    // ==========================================================
    //
    // O banco já deve ter recebido:
    //
    // set_my_online_preference(false)
    //
    // que limpa last_seen_at.
    //
    // Aqui simplesmente paramos o heartbeat.
    //
    // ==========================================================

    if (!value) {
      _cancelHeartbeatTimer();

      return;
    }

    // ==========================================================
    // ONLINE
    // ==========================================================

    _restartHeartbeatTimer();

    if (shouldSendHeartbeat) {
      await sendHeartbeat();
    }
  }

  // ============================================================
  // HEARTBEAT
  // ============================================================

  Future<
    void
  >
  sendHeartbeat() async {
    if (!shouldSendHeartbeat) {
      return;
    }

    // ==========================================================
    // EVITAR HEARTBEAT CONCORRENTE
    // ==========================================================

    if (_heartbeatInProgress) {
      return;
    }

    _heartbeatInProgress = true;

    try {
      final serverTime = await _repository.updateMyPresence();

      if (_disposed) {
        return;
      }

      _lastHeartbeatAt = serverTime.toUtc();

      debugPrint(
        '[PRESENCE] Heartbeat enviado: '
        '${_lastHeartbeatAt!.toIso8601String()}',
      );
    } catch (
      error,
      stackTrace
    ) {
      // ========================================================
      // IMPORTANTE
      // ========================================================
      //
      // Uma falha de heartbeat não deve derrubar o aplicativo.
      //
      // Se a rede cair, o backend simplesmente deixará
      // last_seen_at envelhecer.
      //
      // Depois de 90 segundos o usuário será considerado offline.
      //
      // ========================================================

      debugPrint(
        '[PRESENCE] '
        'Falha ao atualizar presença: $error',
      );

      debugPrint(
        '[PRESENCE] '
        'StackTrace: $stackTrace',
      );
    } finally {
      _heartbeatInProgress = false;
    }
  }

  // ============================================================
  // TIMER
  // ============================================================

  void _restartHeartbeatTimer() {
    _cancelHeartbeatTimer();

    if (!shouldSendHeartbeat) {
      return;
    }

    _heartbeatTimer = Timer.periodic(
      heartbeatInterval,
      (
        _,
      ) {
        sendHeartbeat();
      },
    );
  }

  void _cancelHeartbeatTimer() {
    _heartbeatTimer?.cancel();

    _heartbeatTimer = null;
  }

  // ============================================================
  // APP LIFECYCLE
  // ============================================================
  //
  // Quando o app:
  //
  // resumed
  //   -> volta a enviar heartbeat.
  //
  // inactive/paused/hidden/detached
  //   -> interrompe heartbeat.
  //
  // Não tentamos obrigatoriamente marcar offline ao sair.
  //
  // Isso é proposital:
  //
  // se o processo for morto abruptamente, o Flutter pode não
  // conseguir executar uma atualização final.
  //
  // O timeout de 90 segundos resolve esse problema.
  //
  // ============================================================

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    if (_disposed ||
        !_started) {
      return;
    }

    switch (state) {
      case AppLifecycleState.resumed:
        _handleAppResumed();
        break;

      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _handleAppInactive();
        break;
    }
  }

  // ============================================================
  // RESUMED
  // ============================================================

  void _handleAppResumed() {
    _appIsActive = true;

    debugPrint(
      '[PRESENCE] '
      'Aplicativo voltou ao foreground.',
    );

    _restartHeartbeatTimer();

    if (shouldSendHeartbeat) {
      sendHeartbeat();
    }
  }

  // ============================================================
  // INACTIVE
  // ============================================================

  void _handleAppInactive() {
    if (!_appIsActive) {
      return;
    }

    _appIsActive = false;

    debugPrint(
      '[PRESENCE] '
      'Aplicativo saiu do foreground. '
      'Heartbeat pausado.',
    );

    _cancelHeartbeatTimer();
  }

  // ============================================================
  // RESOLVER ESTADO ATUAL DO APP
  // ============================================================

  bool _resolveCurrentAppActiveState() {
    final lifecycleState = WidgetsBinding.instance.lifecycleState;

    if (lifecycleState ==
        null) {
      return true;
    }

    return lifecycleState ==
        AppLifecycleState.resumed;
  }

  // ============================================================
  // STOP
  // ============================================================
  //
  // Pode ser usado em logout/troca de sessão.
  //
  // Não altera a preferência salva no banco.
  //
  // ============================================================

  void stop() {
    if (_disposed) {
      return;
    }

    _cancelHeartbeatTimer();

    if (_started) {
      WidgetsBinding.instance.removeObserver(
        this,
      );
    }

    _started = false;

    _userWantsToAppearOnline = false;

    _heartbeatInProgress = false;

    _lastHeartbeatAt = null;

    debugPrint(
      '[PRESENCE] Service parado.',
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  void dispose() {
    if (_disposed) {
      return;
    }

    _disposed = true;

    _cancelHeartbeatTimer();

    if (_started) {
      WidgetsBinding.instance.removeObserver(
        this,
      );
    }

    _started = false;

    _heartbeatInProgress = false;

    _lastHeartbeatAt = null;

    debugPrint(
      '[PRESENCE] Service descartado.',
    );
  }
}
