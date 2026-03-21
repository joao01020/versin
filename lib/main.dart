import 'package:flutter/material.dart';
// Importação da sua página de chat
import 'features/rimas/presentation/pages/chat_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Versin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // A linha 'home' agora está no lugar correto, dentro do MaterialApp
      home: const ChatPage(),
    );
  }
}