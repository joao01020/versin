import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Importação do novo Dashboard que agora gerencia os módulos
import 'package:versin/modules/dashboard/dashboard_page.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();

    // Escuta mudanças de auth e atualiza apenas este widget
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn) {
        // Se houver modal aberto (AuthModal), o Wrapper fecha
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      }
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    // Agora o ponto de entrada logado é o Dashboard universal.
    // O Dashboard cuidará de carregar o ChatPage internamente.
    return const DashboardPage();
  }
}