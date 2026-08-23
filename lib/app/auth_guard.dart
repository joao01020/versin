import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:versin/modules/login/views/login_page.dart';

// ============================================================
// AUTH GUARD
// ============================================================
//
// Protege páginas que exigem autenticação.
//
// Evita que o usuário abra diretamente:
//
// /dashboard
// /chat
// /settings
// /wallet
// ...
//
// sem possuir uma sessão Supabase válida.
//
// ============================================================

class AuthGuard
    extends
        StatefulWidget {
  final Widget child;

  const AuthGuard({
    super.key,
    required this.child,
  });

  @override
  State<
    AuthGuard
  >
  createState() => _AuthGuardState();
}

class _AuthGuardState
    extends
        State<
          AuthGuard
        > {
  final SupabaseClient _supabase = Supabase.instance.client;

  StreamSubscription<
    AuthState
  >?
  _authSubscription;

  bool _isLoading = true;

  User? _currentUser;

  @override
  void initState() {
    super.initState();

    _currentUser = _supabase.auth.currentUser;

    _isLoading = false;

    _authSubscription = _supabase.auth.onAuthStateChange.listen(
      (
        data,
      ) {
        if (!mounted) {
          return;
        }

        setState(
          () {
            _currentUser = data.session?.user;

            _isLoading = false;
          },
        );
      },
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(
          0xFF0D0B1F,
        ),
        body: Center(
          child: CircularProgressIndicator(
            valueColor:
                AlwaysStoppedAnimation<
                  Color
                >(
                  Color(
                    0xFFE040FB,
                  ),
                ),
          ),
        ),
      );
    }

    if (_currentUser ==
        null) {
      return const LoginPage();
    }

    return widget.child;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();

    super.dispose();
  }
}
