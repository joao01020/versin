import 'package:get_it/get_it.dart';
import '../modules/dashboard/controllers/dashboard_controller.dart';
import '../modules/match/controllers/match_controllers.dart';
import '../modules/match/data/repositories/match_repository.dart';
import '../modules/wallet/controllers/wallet_controller.dart';
import '../modules/wallet/controllers/royalties_controller.dart'; // Importação adicionada

final sl = GetIt.instance;

void setupLocator() {
  sl.registerLazySingleton<DashboardController>(() => DashboardController());
  
  // Registrar o repositório do algoritmo como Singleton
  sl.registerLazySingleton<MatchRepository>(() => MatchRepository());

  sl.registerFactory<MatchController>(() => MatchController());

  // Registro do Controller da Carteira
  sl.registerLazySingleton<WalletController>(() => WalletController());

  // Registro do Controller de Royalties
  sl.registerLazySingleton<RoyaltiesController>(() => RoyaltiesController());
}