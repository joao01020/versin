import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:versin/modules/dashboard/views/dashboard_page.dart';
import 'package:versin/modules/login/login_page.dart'; // Importação da nova página de login

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  User? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // 1. Checa a sessão atual assim que o chassi inicializa
    _checkInitialSession();

    // 2. Escuta mudanças de autenticação (Login, Logout, etc.)
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (mounted) {
        setState(() {
          _currentUser = data.session?.user;
          _isLoading = false;
        });
      }
    });
  }

  void _checkInitialSession() {
    final session = Supabase.instance.client.auth.currentSession;
    if (mounted) {
      setState(() {
        _currentUser = session?.user;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tela de carregamento hacker enquanto o Supabase responde
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

    // Se o usuário estiver autenticado no Supabase, abre o Dashboard.
    // Caso contrário, joga para a nova LoginPage estruturada.
    return _currentUser != null ? const DashboardPage() : const LoginPage();
  }
}