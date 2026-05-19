// 🚨 REMOVEMOS o 'import:dart:io' que quebrava o Web e usamos o kIsWeb do foundation
import 'package:flutter/foundation.dart'; 
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Importação das fábricas FFI para compatibilidade com Desktop/Linux
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; 

// 🌐 CAMINHO ATUALIZADO: Apontando para a raiz da pasta app
import 'package:versin/app/auth_wrapper.dart';

// Importação do novo serviço de sincronização
import 'package:versin/core/services/sync_manager.dart';

// Importações dos módulos para suporte a rotas nomeadas no Web
import 'package:versin/modules/login/login_page.dart';

// 📂 CAMINHO ATUALIZADO: Apontando para a nova estrutura de views do Dashboard
import 'package:versin/modules/dashboard/views/dashboard_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🛡️ INICIALIZAÇÃO DO SQFLITE PROTEGIDA CONTRA O WEB
  // Se for Web, ignoramos o FFI por completo (o navegador usa sua própria camada de persistência se houver)
  if (!kIsWeb) {
    // Agora que sabemos que não é Web, podemos usar condicionais de Desktop sem quebrar
    if (defaultTargetPlatform == TargetPlatform.linux || 
        defaultTargetPlatform == TargetPlatform.windows || 
        defaultTargetPlatform == TargetPlatform.macOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  // 1. Inicializa o ambiente
  await dotenv.load(fileName: ".env");

  // 2. Configura o Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.implicit,
    ),
  );

  // 3. Inicializa o monitor de persistência offline
  SyncManager().watchConnection();

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
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.purpleAccent,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      
      // O AuthWrapper no lugar certo para verificar sessões ativas
      home: const AuthWrapper(),

      // Mapeamento de rotas corrigido
      routes: {
        '/login': (context) => const LoginPage(),
        '/dashboard': (context) => const DashboardPage(),
      },
    );
  }
}