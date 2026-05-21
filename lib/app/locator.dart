import 'package:get_it/get_it.dart';
import '../modules/dashboard/controllers/dashboard_controller.dart';

final sl = GetIt.instance; // 'sl' de Service Locator

void setupLocator() {
  // Registra como singleton (uma única instância para o app todo)
  sl.registerLazySingleton<DashboardController>(() => DashboardController());
}