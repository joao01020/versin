import 'package:flutter/material.dart';

import 'package:versin/app/auth_wrapper.dart';
import 'package:versin/app/routes/app_routes.dart';

// ============================================================
// MY APP
// ============================================================
//
// Widget raiz da aplicação principal.
//
// Responsabilidades:
//
// - configurar o MaterialApp;
// - definir o tema global;
// - disponibilizar as rotas;
// - iniciar o AuthWrapper;
// - encaminhar o deep link inicial recebido pelo sistema.
//
// O processamento do deep link NÃO acontece aqui.
//
// O fluxo é:
//
// main.dart
//     ↓
// captura versin://...
//     ↓
// MyApp
//     ↓
// AuthWrapper
//     ↓
// Supabase getSessionFromUrl()
//     ↓
// AuthChangeEvent.passwordRecovery
//     ↓
// ResetPasswordPage
//
// ============================================================

class MyApp extends StatelessWidget {
  // ==========================================================
  // DEEP LINK INICIAL
  // ==========================================================
  //
  // Exemplo:
  //
  // versin://auth/reset-password#access_token=...
  //
  // O main.dart é responsável apenas por capturar o URI.
  //
  // O AuthWrapper será responsável por processá-lo.
  //
  // ==========================================================

  final Uri? initialDeepLink;

  // ==========================================================
  // CONSTRUTOR
  // ==========================================================

  const MyApp({super.key, this.initialDeepLink});

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // ======================================================
      // IDENTIDADE
      // ======================================================
      title: 'Versin',

      debugShowCheckedModeBanner: false,

      // ======================================================
      // TEMA
      // ======================================================
      theme: ThemeData(
        useMaterial3: true,

        brightness: Brightness.dark,

        scaffoldBackgroundColor: const Color(0xFF0D0B1F),

        primaryColor: const Color(0xFFE040FB),

        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE040FB),

          secondary: Color(0xFF00E5FF),

          surface: Color(0xFF0D0B1F),
        ),
      ),

      // ======================================================
      // AUTH GATE
      // ======================================================
      //
      // O AuthWrapper decide entre:
      //
      // - LoginPage;
      // - DashboardPage;
      // - ResetPasswordPage.
      //
      // Se o aplicativo foi iniciado através de um deep link,
      // ele também será entregue ao AuthWrapper.
      //
      // ======================================================
      home: AuthWrapper(initialDeepLink: initialDeepLink),

      // ======================================================
      // ROTAS
      // ======================================================
      routes: AppRoutes.routes,
    );
  }
}
