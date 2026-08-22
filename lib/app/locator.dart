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
// MATCH
// ============================================================

import '../modules/match/data/repositories/match_repository.dart';

import 'package:versin/modules/match/availability/services/match_availability_service.dart';

// ============================================================
// PUBLIC PROFILE / PRESENCE
// ============================================================

import 'package:versin/modules/public_profile/data/repositories/public_profile_repository_impl.dart';
import 'package:versin/modules/public_profile/repositories/public_profile_repository.dart';
import 'package:versin/modules/profile/services/presence/user_presence_service.dart';

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
  // PUBLIC PROFILE / PRESENCE MODULE
  // ==========================================================
  //
  // PublicProfileRepository
  //        ↓
  // PublicProfileRepositoryImpl
  //        ↓
  // PublicProfileRemoteDatasource
  //        ↓
  // Supabase
  //
  // UserPresenceService usa a mesma instância do repository
  // para enviar heartbeat através de updateMyPresence().
  //
  // ==========================================================

  sl.registerLazySingleton<
    PublicProfileRepository
  >(
    () => PublicProfileRepositoryImpl(),
  );

  sl.registerLazySingleton<
    UserPresenceService
  >(
    () => UserPresenceService(
      repository:
          sl<
            PublicProfileRepository
          >(),
    ),
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
  //
  // MatchRepository
  //
  // Responsável por:
  //
  // - descobrir candidatos;
  // - compatibilidade por habilidade;
  // - próximos;
  // - disponíveis agora;
  // - presença real;
  // - ordenação.
  //
  // MatchAvailabilityService
  //
  // Responsável por:
  //
  // - ativar "Disponíveis agora";
  // - 30 minutos;
  // - 1 hora;
  // - 2 horas;
  // - encerrar disponibilidade;
  // - carregar tempo restante.
  //
  // MatchController
  //
  // Continua sendo Factory porque cada tela/sessão pode possuir
  // seu próprio estado de Match.
  //
  // ==========================================================

  sl.registerLazySingleton<
    MatchRepository
  >(
    () => MatchRepository(),
  );

  sl.registerLazySingleton<
    MatchAvailabilityService
  >(
    () => MatchAvailabilityService(),
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
