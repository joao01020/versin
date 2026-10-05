import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================================
// SUPABASE SESSION MANAGER
// ============================================================
//
// Responsável por:
//
// - validar a sessão restaurada pelo Supabase;
// - renovar JWT expirado antes do Realtime iniciar;
// - acompanhar alterações de autenticação;
// - acompanhar tokenRefreshed;
// - evitar múltiplos refreshes simultâneos.
//
// IMPORTANTE:
//
// Supabase Flutter v2:
//
// Supabase.initialize()
//        ↓
// restaura a sessão local
//        ↓
// a sessão pode já estar expirada
//
// Por isso:
//
// initialize()
//        ↓
// ensureValidSession()
//        ↓
// refreshSession() se necessário
//        ↓
// somente depois iniciar Realtime.
//
// ============================================================

class SupabaseSessionManager {
  // ============================================================
  // SINGLETON
  // ============================================================

  SupabaseSessionManager._();

  static final SupabaseSessionManager instance = SupabaseSessionManager._();

  // ============================================================
  // SUPABASE
  // ============================================================

  SupabaseClient get _supabase => Supabase.instance.client;

  // ============================================================
  // AUTH LISTENER
  // ============================================================

  StreamSubscription<
    AuthState
  >?
  _authSubscription;

  // ============================================================
  // STATE
  // ============================================================

  bool _initialized = false;

  bool _isRefreshing = false;

  Future<
    bool
  >?
  _refreshFuture;

  // ============================================================
  // GETTERS
  // ============================================================

  bool get isInitialized => _initialized;

  bool get isRefreshing => _isRefreshing;

  Session? get currentSession => _supabase.auth.currentSession;

  User? get currentUser => _supabase.auth.currentUser;

  bool get hasSession =>
      currentSession !=
      null;

  bool get hasAuthenticatedUser =>
      currentUser !=
      null;

  bool get isSessionExpired {
    final session = currentSession;

    if (session ==
        null) {
      return false;
    }

    return session.isExpired;
  }

  // ============================================================
  // INITIALIZE
  // ============================================================
  //
  // Deve ser chamado APÓS:
  //
  // Supabase.initialize(...)
  //
  // e ANTES de iniciar serviços Realtime.
  //
  // ============================================================

  Future<
    bool
  >
  initialize() async {
    if (_initialized) {
      return ensureValidSession();
    }

    debugPrint(
      '[SUPABASE SESSION] '
      'Inicializando gerenciador de sessão.',
    );

    _listenAuthChanges();

    final valid = await ensureValidSession();

    _initialized = true;

    debugPrint(
      '[SUPABASE SESSION] '
      'Inicialização concluída. '
      'Sessão válida: $valid',
    );

    return valid;
  }

  // ============================================================
  // ENSURE VALID SESSION
  // ============================================================

  Future<
    bool
  >
  ensureValidSession() async {
    final session = _supabase.auth.currentSession;

    // ==========================================================
    // SEM SESSÃO
    // ==========================================================

    if (session ==
        null) {
      debugPrint(
        '[SUPABASE SESSION] '
        'Nenhuma sessão autenticada encontrada.',
      );

      return false;
    }

    // ==========================================================
    // SESSÃO VÁLIDA
    // ==========================================================

    if (!session.isExpired) {
      debugPrint(
        '[SUPABASE SESSION] '
        'Sessão atual válida.',
      );

      return true;
    }

    // ==========================================================
    // SESSÃO EXPIRADA
    // ==========================================================

    debugPrint(
      '[SUPABASE SESSION] '
      'Sessão expirada. Renovando token...',
    );

    return refreshSession();
  }

  // ============================================================
  // REFRESH SESSION
  // ============================================================
  //
  // Evita dois refreshes simultâneos.
  //
  // Exemplo:
  //
  // Chat
  // Notifications
  // Invitations
  //
  // podem detectar o JWT vencido ao mesmo tempo.
  //
  // Todos aguardam o mesmo Future.
  //
  // ============================================================

  Future<
    bool
  >
  refreshSession() {
    final activeRefresh = _refreshFuture;

    if (activeRefresh !=
        null) {
      return activeRefresh;
    }

    final future = _performRefresh();

    _refreshFuture = future;

    return future;
  }

  // ============================================================
  // PERFORM REFRESH
  // ============================================================

  Future<
    bool
  >
  _performRefresh() async {
    _isRefreshing = true;

    try {
      final current = _supabase.auth.currentSession;

      if (current ==
          null) {
        debugPrint(
          '[SUPABASE SESSION] '
          'Refresh cancelado: sessão inexistente.',
        );

        return false;
      }

      final response = await _supabase.auth.refreshSession();

      final refreshedSession = response.session;

      if (refreshedSession ==
          null) {
        debugPrint(
          '[SUPABASE SESSION] '
          'Refresh não retornou uma sessão.',
        );

        return false;
      }

      if (refreshedSession.isExpired) {
        debugPrint(
          '[SUPABASE SESSION] '
          'Refresh retornou uma sessão expirada.',
        );

        return false;
      }

      debugPrint(
        '[SUPABASE SESSION] '
        'Sessão renovada com sucesso.',
      );

      return true;
    } on AuthException catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[SUPABASE SESSION] '
        'Erro Auth ao renovar sessão: '
        '${error.message}',
      );

      debugPrint(
        '$stackTrace',
      );

      return false;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[SUPABASE SESSION] '
        'Erro inesperado ao renovar sessão: '
        '$error',
      );

      debugPrint(
        '$stackTrace',
      );

      return false;
    } finally {
      _isRefreshing = false;

      _refreshFuture = null;
    }
  }

  // ============================================================
  // AUTH STATE CHANGES
  // ============================================================

  void _listenAuthChanges() {
    if (_authSubscription !=
        null) {
      return;
    }

    _authSubscription = _supabase.auth.onAuthStateChange.listen(
      _handleAuthStateChange,

      onError:
          (
            Object error,
            StackTrace stackTrace,
          ) {
            debugPrint(
              '[SUPABASE SESSION] '
              'Erro no AuthStateChange: '
              '$error',
            );

            debugPrint(
              '$stackTrace',
            );
          },
    );
  }

  // ============================================================
  // HANDLE AUTH STATE
  // ============================================================

  void _handleAuthStateChange(
    AuthState state,
  ) {
    final event = state.event;

    final session = state.session;

    switch (event) {
      // ========================================================
      // INITIAL SESSION
      // ========================================================

      case AuthChangeEvent.initialSession:
        debugPrint(
          '[SUPABASE SESSION] '
          'Sessão inicial recebida. '
          'Autenticado: ${session != null}',
        );

        break;

      // ========================================================
      // SIGNED IN
      // ========================================================

      case AuthChangeEvent.signedIn:
        debugPrint(
          '[SUPABASE SESSION] '
          'Usuário autenticado.',
        );

        break;

      // ========================================================
      // TOKEN REFRESHED
      // ========================================================

      case AuthChangeEvent.tokenRefreshed:
        debugPrint(
          '[SUPABASE SESSION] '
          'Token renovado.',
        );

        break;

      // ========================================================
      // SIGNED OUT
      // ========================================================

      case AuthChangeEvent.signedOut:
        debugPrint(
          '[SUPABASE SESSION] '
          'Usuário desconectado.',
        );

        break;

      // ========================================================
      // PASSWORD RECOVERY
      // ========================================================

      case AuthChangeEvent.passwordRecovery:
        debugPrint(
          '[SUPABASE SESSION] '
          'Recuperação de senha iniciada.',
        );

        break;

      // ========================================================
      // USER UPDATED
      // ========================================================

      case AuthChangeEvent.userUpdated:
        debugPrint(
          '[SUPABASE SESSION] '
          'Usuário atualizado.',
        );

        break;

      // ========================================================
      // MFA
      // ========================================================

      case AuthChangeEvent.mfaChallengeVerified:
        debugPrint(
          '[SUPABASE SESSION] '
          'MFA validado.',
        );

        break;

      // ========================================================
      // USER DELETED
      // ========================================================

      case AuthChangeEvent.userDeleted:
        debugPrint(
          '[SUPABASE SESSION] '
          'Usuário removido.',
        );

        break;
    }
  }

  // ============================================================
  // FORCE VALID SESSION
  // ============================================================
  //
  // Pode ser chamado por um serviço antes de recriar um
  // listener Realtime após InvalidJWTToken.
  //
  // ============================================================

  Future<
    bool
  >
  forceRefresh() async {
    final session = _supabase.auth.currentSession;

    if (session ==
        null) {
      return false;
    }

    debugPrint(
      '[SUPABASE SESSION] '
      'Refresh manual solicitado.',
    );

    return refreshSession();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  Future<
    void
  >
  dispose() async {
    await _authSubscription?.cancel();

    _authSubscription = null;

    _initialized = false;

    _isRefreshing = false;

    _refreshFuture = null;

    debugPrint(
      '[SUPABASE SESSION] '
      'Gerenciador encerrado.',
    );
  }
}
