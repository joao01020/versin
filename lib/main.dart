import 'package:flutter/foundation.dart'; 
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Importação das fábricas FFI para compatibilidade com Desktop/Linux
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; 

// Importação do seu widget de inicialização centralizado
import 'package:versin/app/my_app.dart';

// Importação do serviço de sincronização
import 'package:versin/core/services/sync_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🛡️ INICIALIZAÇÃO DO SQFLITE PROTEGIDA CONTRA O WEB
  if (!kIsWeb) {
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

  // Roda o aplicativo chamando a sua classe centralizada de configuração
  runApp(const MyApp());
}