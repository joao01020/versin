import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_web_plugins/url_strategy.dart'; // Importação para URLs limpas (sem #)

// Importação das fábricas FFI para compatibilidade com Desktop/Linux
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; 

// Importação da configuração do GetIt (Localizador de serviços)
import 'package:versin/app/locator.dart'; 

// Importação do seu widget de inicialização centralizado
import 'package:versin/app/my_app.dart';

// Importação do serviço de sincronização
import 'package:versin/core/services/sync_manager.dart';

// Importação do controller para checagem de segurança
import 'package:versin/modules/dashboard/controllers/dashboard_controller.dart';

void main() async {
  // Inicialização essencial do framework
  WidgetsFlutterBinding.ensureInitialized();

  // 0. Configura estratégia de URL para remover o # da Web
  usePathUrlStrategy();

  // 1. Inicializa o Gerenciador de Dependências (GetIt) com proteção contra duplicidade
  if (!GetIt.instance.isRegistered<DashboardController>()) {
    setupLocator();
  }

  // 2. 🛡️ INICIALIZAÇÃO DO SQFLITE PROTEGIDA CONTRA O WEB
  if (!kIsWeb) {
    if (defaultTargetPlatform == TargetPlatform.linux || 
        defaultTargetPlatform == TargetPlatform.windows || 
        defaultTargetPlatform == TargetPlatform.macOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  // 3. Inicializa o ambiente
  await dotenv.load(fileName: ".env");

  // 4. Configura o Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.implicit,
    ),
  );

  // 5. Inicializa o monitor de persistência offline
  SyncManager().watchConnection();

  // Roda o aplicativo chamando a sua classe centralizada de configuração
  runApp(const MyApp());
}