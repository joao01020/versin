import 'package:get_it/get_it.dart';

// --- CONTROLLERS ---
import '../modules/dashboard/controllers/dashboard_controller.dart';
import '../modules/match/controllers/match_controllers.dart';
import '../modules/wallet/controllers/wallet_controller.dart';
import '../modules/wallet/controllers/royalties_controller.dart';

// ============================================================
// BRAIN & RHYMES
// ============================================================

import 'package:versin/features/rhymes/presentation/controller/rhymes_controller.dart';
import 'package:versin/modules/brain/controller/brain_controller.dart';

// ============================================================
// STUDIO
// ============================================================

import 'package:versin/modules/studio/controllers/studio_controller.dart';

// --- REPOSITÓRIOS ---
import '../modules/match/data/repositories/match_repository.dart';

// ============================================================
// SERVICE LOCATOR
// ============================================================

final sl = GetIt.instance;

// ============================================================
// SETUP
// ============================================================

void
setupLocator() {
  // ==========================================================
  // CORE & DASHBOARD
  // ==========================================================

  sl.registerLazySingleton<
    DashboardController
  >(
    () => DashboardController(),
  );

  // ==========================================================
  // MATCH MODULE
  // ==========================================================

  sl.registerLazySingleton<
    MatchRepository
  >(
    () => MatchRepository(),
  );

  sl.registerFactory<
    MatchController
  >(
    () => MatchController(),
  );

  // ==========================================================
  // WALLET MODULE
  // ==========================================================

  sl.registerLazySingleton<
    WalletController
  >(
    () => WalletController(),
  );

  sl.registerLazySingleton<
    RoyaltiesController
  >(
    () => RoyaltiesController(),
  );

  // ==========================================================
  // BRAIN & RHYMES MODULE
  // ==========================================================
  //
  // BrainController é a instância principal.
  //
  // RhymesController aponta para exatamente a mesma instância.
  //
  // Isso significa:
  //
  // BrainController
  //        │
  //        └── RhymesController
  //
  // Não existem dois bancos de rimas separados.
  //
  // ==========================================================

  sl.registerLazySingleton<
    BrainController
  >(
    () => BrainController(),
  );

  sl.registerLazySingleton<
    RhymesController
  >(
    () =>
        sl<
          BrainController
        >(),
  );

  // ==========================================================
  // STUDIO MODULE — ESTADO DA SESSÃO
  // ==========================================================
  //
  // IMPORTANTE:
  //
  // StudioController é LazySingleton.
  //
  // Portanto ele é criado somente uma vez enquanto o app
  // estiver aberto.
  //
  // Isso mantém:
  //
  // - título da música
  // - letra
  // - BPM
  // - vibe
  // - técnica
  // - Timeline
  // - mapa mental
  // - nós
  // - posição dos nós
  // - conexões do mapa
  //
  // mesmo se o usuário sair do Studio e voltar.
  //
  // ==========================================================

  sl.registerLazySingleton<
    StudioController
  >(
    () => StudioController(
      rhymesController:
          sl<
            BrainController
          >(),
    ),
  );
}
