import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:versin/features/rhymes/presentation/pages/chat_page.dart';

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
    final session = Supabase.instance.client.auth.currentSession;

    // Aqui você pode decidir: se não tiver sessão, mostra Login.
    // Como seu app abre no Chat e o Login é um Modal, retornamos o ChatPage.
    return const ChatPage();
  }
}