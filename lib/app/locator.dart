import 'package:get_it/get_it.dart';

// ============================================================
// CONTROLLERS
// ============================================================

import '../modules/dashboard/controllers/dashboard_controller.dart';
import '../modules/match/controllers/match_controllers.dart';
import '../modules/profile/controllers/professional_profile_controller.dart';
import '../modules/wallet/controllers/royalties_controller.dart';
import '../modules/wallet/controllers/wallet_controller.dart';

// ============================================================
// ACTIVITIES
// ============================================================

import 'package:versin/modules/activities/controllers/recent_activity_controller.dart';
import 'package:versin/modules/activities/data/repositories/recent_activity_repository_impl.dart';
import 'package:versin/modules/activities/repositories/recent_activity_repository.dart';
import 'package:versin/modules/activities/services/recent_activity_service.dart';

// ============================================================
// NOTIFICATIONS
// ============================================================

import 'package:versin/modules/notifications/controllers/notification_controller.dart';
import 'package:versin/modules/notifications/data/repositories/notification_repository_impl.dart';
import 'package:versin/modules/notifications/repositories/notification_repository.dart';

// ============================================================
// BRAIN & RHYMES
// ============================================================

import 'package:versin/features/rhymes/presentation/controller/rhymes_controller.dart';
import 'package:versin/modules/brain/controller/brain_controller.dart';

// ============================================================
// STUDIO
// ============================================================

import 'package:versin/modules/studio/controllers/studio_controller.dart';

// ============================================================
// STORAGE
// ============================================================

import 'package:versin/modules/storage/controllers/storage_controller.dart';
import 'package:versin/modules/storage/data/repositories/storage_repository.dart';
import 'package:versin/modules/storage/services/storage_file_service.dart';
import 'package:versin/modules/storage/services/storage_hash_service.dart';

// ============================================================
// REPOSITÓRIOS
// ============================================================

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
  // PROFESSIONAL PROFILE MODULE
  // ==========================================================

  sl.registerLazySingleton<
    ProfessionalProfileController
  >(
    () => ProfessionalProfileController(),
  );

  // ==========================================================
  // ACTIVITIES MODULE
  // ==========================================================
  //
  // Fluxo:
  //
  // Dashboard / Outros módulos
  //              ↓
  // RecentActivityService
  //              ↓
  // RecentActivityController
  //              ↓
  // RecentActivityRepository
  //              ↓
  // RecentActivityRepositoryImpl
  //              ↓
  // RecentActivityRemoteDatasource
  //              ↓
  // Supabase
  //
  // IMPORTANTE:
  //
  // RecentActivityRepository precisa ser registrado antes do
  // RecentActivityController.
  //
  // RecentActivityController é LazySingleton porque:
  //
  // - Dashboard;
  // - Realtime;
  // - Service;
  // - outros módulos;
  //
  // precisam compartilhar a mesma instância e o mesmo estado.
  //
  // RecentActivityService também é LazySingleton porque deve
  // sempre utilizar esse mesmo Controller.
  //
  // ==========================================================

  sl.registerLazySingleton<
    RecentActivityRepository
  >(
    () => RecentActivityRepositoryImpl(),
  );

  sl.registerLazySingleton<
    RecentActivityController
  >(
    () => RecentActivityController(
      repository:
          sl<
            RecentActivityRepository
          >(),
    ),
  );

  sl.registerLazySingleton<
    RecentActivityService
  >(
    () => RecentActivityService(
      controller:
          sl<
            RecentActivityController
          >(),
    ),
  );

  // ==========================================================
  // NOTIFICATIONS MODULE
  // ==========================================================

  sl.registerLazySingleton<
    NotificationRepository
  >(
    () => NotificationRepositoryImpl(),
  );

  sl.registerLazySingleton<
    NotificationController
  >(
    () => NotificationController(
      repository:
          sl<
            NotificationRepository
          >(),
    ),
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
  // STUDIO MODULE
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

  // ==========================================================
  // STORAGE MODULE
  // ==========================================================

  sl.registerLazySingleton<
    StorageRepository
  >(
    () => InMemoryStorageRepository(),
  );

  // ==========================================================
  // STORAGE HASH SERVICE
  // ==========================================================

  sl.registerLazySingleton<
    StorageHashService
  >(
    () => StorageHashService(),
  );

  // ==========================================================
  // STORAGE FILE SERVICE
  // ==========================================================

  sl.registerLazySingleton<
    StorageFileService
  >(
    () => StorageFileService(),
  );

  // ==========================================================
  // STORAGE CONTROLLER
  // ==========================================================

  sl.registerLazySingleton<
    StorageController
  >(
    () => StorageController(
      repository:
          sl<
            StorageRepository
          >(),
    ),
  );
}
