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
// PROJECT INVITATIONS
// ============================================================

import 'package:versin/modules/networking/invitations/controllers/project_invitation_controller.dart';
import 'package:versin/modules/networking/invitations/services/project_invitation_service.dart';

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
import 'package:versin/modules/storage/data/repositories/supabase_storage_repository.dart';

import 'package:versin/modules/storage/services/beat_storage_service.dart';
import 'package:versin/modules/storage/services/storage_file_service.dart';
import 'package:versin/modules/storage/services/storage_hash_service.dart';
import 'package:versin/modules/storage/services/work_storage_service.dart';

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
  // PROJECT INVITATIONS MODULE
  // ==========================================================
  //
  // Uma única instância é compartilhada por:
  //
  // - Dashboard;
  // - badge de convites;
  // - banner global;
  // - lista de convites;
  // - demais telas que acompanham convites em realtime.
  //
  // ==========================================================

  sl.registerLazySingleton<
    ProjectInvitationService
  >(
    () => ProjectInvitationService(),
  );

  sl.registerLazySingleton<
    ProjectInvitationController
  >(
    () => ProjectInvitationController(
      service:
          sl<
            ProjectInvitationService
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
  //
  // FLUXO:
  //
  // StorageHashService
  //        ↓
  // SupabaseStorageRepository
  //        ↓
  // StorageController
  //
  // E:
  //
  // BeatStorageService
  //        ↓
  // WorkStorageService
  //        ↓
  // R2 + Supabase
  //
  // ==========================================================

  // ==========================================================
  // STORAGE HASH SERVICE
  // ==========================================================
  //
  // IMPORTANTE:
  //
  // Deve ser registrado ANTES do StorageRepository.
  //
  // Dessa forma:
  //
  // - telas;
  // - WorkStorageService;
  // - SupabaseStorageRepository;
  //
  // utilizam a mesma instância.
  //
  // ==========================================================

  sl.registerLazySingleton<
    StorageHashService
  >(
    () => StorageHashService(),
  );

  // ==========================================================
  // STORAGE FILE SERVICE
  // ==========================================================
  //
  // Continua responsável por:
  //
  // - selecionar arquivo;
  // - drag & drop;
  // - inspecionar arquivo;
  // - nome;
  // - extensão;
  // - MIME;
  // - tamanho.
  //
  // O arquivo permanente do beat fica no R2.
  //
  // ==========================================================

  sl.registerLazySingleton<
    StorageFileService
  >(
    () => StorageFileService(),
  );

  // ==========================================================
  // STORAGE REPOSITORY
  // ==========================================================
  //
  // Persistência real:
  //
  // SupabaseStorageRepository
  //        ↓
  // public.stored_works
  //
  // O repository também valida:
  //
  // - contentHash;
  // - SHA-256;
  // - proprietário;
  // - conteúdo de letras;
  // - metadados dos beats.
  //
  // ==========================================================

  sl.registerLazySingleton<
    StorageRepository
  >(
    () => SupabaseStorageRepository(
      hashService:
          sl<
            StorageHashService
          >(),
    ),
  );

  // ==========================================================
  // BEAT STORAGE SERVICE
  // ==========================================================
  //
  // Responsável por:
  //
  // Flutter
  //    ↓
  // Edge Function
  //    ↓
  // URL assinada
  //    ↓
  // Cloudflare R2
  //
  // ==========================================================

  sl.registerLazySingleton<
    BeatStorageService
  >(
    () => BeatStorageService(),
  );

  // ==========================================================
  // WORK STORAGE SERVICE
  // ==========================================================
  //
  // Coordena a persistência completa:
  //
  // LETRA
  //
  // conteúdo
  //    ↓
  // SHA-256
  //    ↓
  // stored_works
  //
  //
  // BEAT
  //
  // arquivo
  //    ↓
  // SHA-256
  //    ↓
  // Cloudflare R2
  //    ↓
  // objectKey
  //    ↓
  // stored_works.file_path
  //
  // ==========================================================

  sl.registerLazySingleton<
    WorkStorageService
  >(
    () => WorkStorageService(
      repository:
          sl<
            StorageRepository
          >(),

      beatStorageService:
          sl<
            BeatStorageService
          >(),
    ),
  );

  // ==========================================================
  // STORAGE CONTROLLER
  // ==========================================================
  //
  // A UI acessa principalmente este controller para:
  //
  // - carregar obras;
  // - listar;
  // - pesquisar;
  // - excluir;
  // - transferir;
  // - atualizar estado.
  //
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
