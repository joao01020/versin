import 'package:get_it/get_it.dart';

// --- CONTROLLERS ---
import '../modules/dashboard/controllers/dashboard_controller.dart';
import '../modules/match/controllers/match_controllers.dart';
import '../modules/wallet/controllers/wallet_controller.dart';
import '../modules/wallet/controllers/royalties_controller.dart';

// Importe a hierarquia de rimas e o BrainController
import 'package:versin/features/rhymes/presentation/controller/rhymes_controller.dart';
import 'package:versin/modules/brain/controller/brain_controller.dart';

// --- REPOSITÓRIOS ---
import '../modules/match/data/repositories/match_repository.dart';

final sl = GetIt.instance;

void
setupLocator() {
  // --- CORE & DASHBOARD ---
  sl.registerLazySingleton<
    DashboardController
  >(
    () => DashboardController(),
  );

  // --- MATCH MODULE ---
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

  // --- WALLET MODULE ---
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

  // --- BRAIN & RHYMES MODULE (Hierarquia de Injeção) ---

  // 1. Registra o BrainController como o Singleton principal.
  // Ele é o dono da lógica avançada e da sincronização com o Vault.
  sl.registerLazySingleton<
    BrainController
  >(
    () => BrainController(),
  );

  // 2. Registra o RhymesController para apontar para a mesma instância do BrainController.
  // Isso resolve o conflito de tipo: quem pedir RhymesController receberá o BrainController,
  // permitindo que telas simples acessem a lógica completa sem causar erros de "subtype".
  sl.registerLazySingleton<
    RhymesController
  >(
    () =>
        sl<
          BrainController
        >(),
  );
}
