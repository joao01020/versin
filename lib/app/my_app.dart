import 'package:flutter/material.dart';
import 'package:versin/app/app_routes.dart'; // IMPORTAÇÃO QUE FALTAVA ADICIONADA AQUI
import 'package:versin/app/auth_wrapper.dart';

/// [MyApp] é o chassi e orquestrador global da interface do aplicativo.
/// Ele define as configurações básicas de inicialização, identidade visual
/// e o ecossistema de navegação por rotas nomeadas.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Versin',
      
      // Remove a bandeira de debug no canto superior direito para um visual limpo
      debugShowCheckedModeBanner: false,
      
      // Configuração base do Tema (Identidade Visual)
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D0B1F), // Fundo padrão unificado
        primaryColor: const Color(0xFFE040FB), // Cor primária (Roxo Hacker)
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE040FB),
          secondary: Color(0xFF00E5FF),
          surface: Color(0xFF0D0B1F),
        ),
      ),

      // Ponto de Entrada Seguro: O app sempre inicia validando o estado
      // de autenticação do usuário através do AuthWrapper.
      home: const AuthWrapper(),

      // Tabela descentralizada de caminhos de navegação (Rotas Nomeadas)
      routes: AppRoutes.routes,
    );
  }
}