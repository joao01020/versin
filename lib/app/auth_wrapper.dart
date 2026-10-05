import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:versin/modules/dashboard/views/dashboard_page.dart';
import 'package:versin/modules/login/recovery/views/reset_password_page.dart';
import 'package:versin/modules/login/views/login_page.dart';

// ============================================================
// AUTH WRAPPER
// ============================================================
//
// Responsável por decidir qual fluxo principal deve ser exibido:
//
// - Login;
// - Dashboard;
// - Recuperação de senha.
//
// IMPORTANTE:
//
// Uma sessão de recuperação também possui usuário autenticado.
//
// Portanto:
//
// currentUser != null
//
// NÃO significa automaticamente que devemos abrir o Dashboard.
//
// O evento:
//
// AuthChangeEvent.passwordRecovery
//
// sempre possui prioridade.
//
// ============================================================

class AuthWrapper extends StatefulWidget {
  // ==========================================================
  // DEEP LINK INICIAL
  // ==========================================================
  //
  // Usado principalmente no Desktop.
  //
  // Exemplo:
  //
  // versin://auth/reset-password#access_token=...
  //
  // No Web, o Supabase Flutter normalmente processa a URL
  // recebida pelo navegador durante a inicialização.
  //
  // ==========================================================

  final Uri? initialDeepLink;

  const AuthWrapper({super.key, this.initialDeepLink});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

// ============================================================
// STATE
// ============================================================

class _AuthWrapperState extends State<AuthWrapper> {
  // ==========================================================
  // SUPABASE
  // ==========================================================

  SupabaseClient get _supabase => Supabase.instance.client;

  // ==========================================================
  // AUTH STATE
  // ==========================================================

  User? _currentUser;

  bool _isLoading = true;

  bool _isPasswordRecovery = false;

  bool _initialDeepLinkProcessed = false;

  // ==========================================================
  // AUTH SUBSCRIPTION
  // ==========================================================

  StreamSubscription<AuthState>? _authSubscription;

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    // ========================================================
    // ORDEM IMPORTANTE
    // ========================================================
    //
    // Primeiro registramos o listener.
    //
    // Depois verificamos a sessão existente.
    //
    // Só então processamos um deep link inicial do Desktop.
    //
    // Isso evita perder:
    //
    // AuthChangeEvent.passwordRecovery
    //
    // ========================================================

    _listenToAuthChanges();

    _checkInitialSession();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processInitialDeepLink();
    });
  }

  // ==========================================================
  // INITIAL SESSION
  // ==========================================================

  void _checkInitialSession() {
    final session = _supabase.auth.currentSession;

    _currentUser = session?.user;

    _isLoading = false;

    debugPrint(
      '[AUTH WRAPPER] '
      'Sessão inicial: '
      '${session != null ? 'encontrada' : 'ausente'}',
    );
  }

  // ==========================================================
  // AUTH LISTENER
  // ==========================================================

  void _listenToAuthChanges() {
    _authSubscription = _supabase.auth.onAuthStateChange.listen(
      (data) {
        if (!mounted) {
          return;
        }

        final event = data.event;

        final session = data.session;

        debugPrint(
          '[AUTH WRAPPER] '
          'Evento: $event',
        );

        // ====================================================
        // PASSWORD RECOVERY
        // ====================================================
        //
        // PRIORIDADE MÁXIMA.
        //
        // Mesmo que session.user exista, o Dashboard não deve
        // ser aberto durante esse fluxo.
        //
        // ====================================================

        if (event == AuthChangeEvent.passwordRecovery) {
          debugPrint(
            '[AUTH WRAPPER] '
            'Sessão de recuperação detectada.',
          );

          setState(() {
            _currentUser = session?.user;

            _isPasswordRecovery = true;

            _isLoading = false;
          });

          return;
        }

        // ====================================================
        // SIGNED OUT
        // ====================================================

        if (event == AuthChangeEvent.signedOut) {
          debugPrint(
            '[AUTH WRAPPER] '
            'Usuário desconectado.',
          );

          setState(() {
            _currentUser = null;

            _isPasswordRecovery = false;

            _isLoading = false;
          });

          return;
        }

        // ====================================================
        // USER UPDATED
        // ====================================================
        //
        // Depois que a nova senha é salva, o Supabase pode
        // emitir userUpdated.
        //
        // Não saímos imediatamente do fluxo de recovery.
        //
        // A ResetPasswordPage continua responsável por exibir
        // a confirmação e permitir que o usuário vá ao login.
        //
        // ====================================================

        if (event == AuthChangeEvent.userUpdated && _isPasswordRecovery) {
          debugPrint(
            '[AUTH WRAPPER] '
            'Usuário atualizado durante recuperação.',
          );

          setState(() {
            _currentUser = session?.user;

            _isLoading = false;
          });

          return;
        }

        // ====================================================
        // NORMAL AUTH STATE
        // ====================================================

        setState(() {
          _currentUser = session?.user;

          _isLoading = false;
        });
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint(
          '[AUTH WRAPPER] '
          'Erro no listener de autenticação: '
          '$error',
        );

        debugPrint(
          '[AUTH WRAPPER] '
          'Stack trace: '
          '$stackTrace',
        );
      },
    );
  }

  // ==========================================================
  // PROCESS INITIAL DEEP LINK
  // ==========================================================
  //
  // Este método é necessário principalmente no Desktop.
  //
  // No Linux:
  //
  // versin://...
  //
  // chega em:
  //
  // main(List<String> args)
  //
  // e é repassado para cá.
  //
  // No Web:
  //
  // o Supabase Flutter normalmente processa a URL atual
  // durante a inicialização.
  //
  // ==========================================================

  Future<void> _processInitialDeepLink() async {
    if (_initialDeepLinkProcessed) {
      return;
    }

    _initialDeepLinkProcessed = true;

    final uri = widget.initialDeepLink;

    // ========================================================
    // SEM DEEP LINK
    // ========================================================

    if (uri == null) {
      debugPrint(
        '[AUTH WRAPPER] '
        'Nenhum deep link inicial recebido.',
      );

      return;
    }

    // ========================================================
    // WEB
    // ========================================================
    //
    // Não processamos manualmente o initialDeepLink aqui no
    // Web.
    //
    // O Supabase Flutter já possui integração própria com a URL
    // do navegador.
    //
    // ========================================================

    if (kIsWeb) {
      debugPrint(
        '[AUTH WRAPPER] '
        'Deep link inicial ignorado manualmente no Web: '
        '$uri',
      );

      return;
    }

    // ========================================================
    // PROTOCOLO DESKTOP
    // ========================================================

    if (uri.scheme != 'versin') {
      debugPrint(
        '[AUTH WRAPPER] '
        'Deep link ignorado. '
        'Scheme não suportado: '
        '${uri.scheme}',
      );

      return;
    }

    debugPrint(
      '[AUTH WRAPPER] '
      'Processando deep link Desktop: '
      '$uri',
    );

    try {
      // ======================================================
      // SUPABASE
      // ======================================================

      await _supabase.auth.getSessionFromUrl(uri);

      debugPrint(
        '[AUTH WRAPPER] '
        'Deep link processado pelo Supabase.',
      );
    } on AuthException catch (error, stackTrace) {
      debugPrint(
        '[AUTH WRAPPER] '
        'AuthException ao processar deep link: '
        '${error.message}',
      );

      debugPrint(
        '[AUTH WRAPPER] '
        'Stack trace: '
        '$stackTrace',
      );

      _handleInvalidRecoveryLink();
    } catch (error, stackTrace) {
      debugPrint(
        '[AUTH WRAPPER] '
        'Falha ao processar deep link: '
        '$error',
      );

      debugPrint(
        '[AUTH WRAPPER] '
        'Stack trace: '
        '$stackTrace',
      );

      _handleInvalidRecoveryLink();
    }
  }

  // ==========================================================
  // INVALID RECOVERY LINK
  // ==========================================================

  void _handleInvalidRecoveryLink() {
    if (!mounted) {
      return;
    }

    setState(() {
      _isPasswordRecovery = false;

      _currentUser = _supabase.auth.currentUser;

      _isLoading = false;
    });
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    // ========================================================
    // LOADING
    // ========================================================

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D0B1F),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE040FB)),
          ),
        ),
      );
    }

    // ========================================================
    // PASSWORD RECOVERY
    // ========================================================
    //
    // Sempre vem antes do usuário autenticado.
    //
    // ========================================================

    if (_isPasswordRecovery) {
      return const ResetPasswordPage();
    }

    // ========================================================
    // AUTHENTICATED
    // ========================================================

    if (_currentUser != null) {
      return const DashboardPage();
    }

    // ========================================================
    // LOGIN
    // ========================================================

    return const LoginPage();
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _authSubscription?.cancel();

    _authSubscription = null;

    super.dispose();
  }
}
