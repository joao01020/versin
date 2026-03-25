import 'package:flutter/material.dart';
import 'package:versin/features/rimas/presentation/pages/chat_page.dart';

void main() {
  // Garante que os widgets do Flutter estejam inicializados antes de rodar o app
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Versin',
      debugShowCheckedModeBanner: false,
      // Tema escuro total para combinar com a interface do Versin
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.purpleAccent,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const ChatPage(),
    );
  }
}