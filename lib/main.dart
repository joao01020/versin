import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import necessário para o .env
import 'package:versin/features/rimas/presentation/pages/chat_page.dart';

void main() async {
  // 1. Garante que os widgets do Flutter estejam inicializados antes de rodar o app
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Carrega as variáveis de ambiente do arquivo .env (Raiz do projeto)
  await dotenv.load(fileName: ".env");

  // 3. Inicializa o Supabase do Versin Genesis usando o dotenv
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  // linha temporariamente para deslogar sessão lixo no cache (remover depois dos testes)
  // Agora está DEPOIS do initialize, o que evita o erro de Assertion
  await Supabase.instance.client.auth.signOut();

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