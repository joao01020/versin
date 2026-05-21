import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:versin/modules/login/views/login_page.dart'; // CAMINHO CORRIGIDO AQUI
import 'package:versin/modules/dashboard/views/dashboard_page.dart';

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
    _checkInitialSession();
    _listenToAuthChanges();
  }

  void _checkInitialSession() {
    final session = Supabase.instance.client.auth.currentSession;
    setState(() {
      _currentUser = session?.user;
      _isLoading = false;
    });
  }

  void _listenToAuthChanges() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (mounted) {
        setState(() {
          _currentUser = data.session?.user;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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

    // CORREÇÃO: Removido o 'const' de LoginPage() pois agora ela é um StatefulWidget
    return _currentUser != null ? const DashboardPage() : LoginPage();
  }
}