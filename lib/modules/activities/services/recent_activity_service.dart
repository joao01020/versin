import '../controllers/recent_activity_controller.dart';
import '../models/recent_activity_model.dart';
import '../models/recent_activity_type.dart';

// ============================================================
// RECENT ACTIVITY SERVICE
// ============================================================
//
// Facade responsável por registrar atividades de negócio.
//
// Os outros módulos não precisam conhecer:
//
// - títulos;
// - descrições;
// - keys de metadata;
// - detalhes de RecentActivityType.
//
// IMPORTANTE:
//
// A atividade:
//
// Bem-vindo ao Versin
//
// NÃO é criada por este Service.
//
// Ela será criada pelo Supabase após aproximadamente
// 10 minutos do cadastro/perfil do usuário.
//
// Fluxo da boas-vindas:
//
// usuário criado
//      ↓
// profiles.welcome_activity_due_at
//      ↓
// Supabase Cron
//      ↓
// process_welcome_activities()
//      ↓
// recent_activities
//      ↓
// Realtime
//      ↓
// RecentActivityController
//      ↓
// Dashboard
//
// Demais atividades:
//
// ProfileController
//      ↓
// RecentActivityService.registerProfileUpdated()
//
// MatchController
//      ↓
// RecentActivityService.registerConnection()
//
// StorageController
//      ↓
// RecentActivityService.registerFileAdded()
//
// ============================================================

class RecentActivityService {
  // ============================================================
  // CONTROLLER
  // ============================================================

  final RecentActivityController _controller;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  RecentActivityService({
    required RecentActivityController controller,
  }) : _controller = controller;

  // ============================================================
  // PERFIL PROFISSIONAL ATUALIZADO
  // ============================================================

  Future<
    RecentActivityModel?
  >
  registerProfileUpdated({
    required String primaryRoleLabel,
  }) {
    final normalizedRole = primaryRoleLabel.trim();

    if (normalizedRole.isEmpty) {
      return Future<
        RecentActivityModel?
      >.value(
        null,
      );
    }

    return _controller.createActivity(
      type: RecentActivityType.profileUpdated,

      title: 'Perfil profissional atualizado',

      description: 'Função principal definida como $normalizedRole.',

      metadata:
          <
            String,
            dynamic
          >{
            'primary_role_label': normalizedRole,

            'source': 'professional_profile',
          },
    );
  }

  // ============================================================
  // NOVA CONEXÃO
  // ============================================================

  Future<
    RecentActivityModel?
  >
  registerConnection({
    required String targetUserId,
    required String targetName,
  }) {
    final normalizedUserId = targetUserId.trim();

    final normalizedName = targetName.trim();

    if (normalizedUserId.isEmpty ||
        normalizedName.isEmpty) {
      return Future<
        RecentActivityModel?
      >.value(
        null,
      );
    }

    return _controller.createActivity(
      type: RecentActivityType.connection,

      title: 'Nova conexão',

      description: 'Você se conectou com $normalizedName.',

      metadata:
          <
            String,
            dynamic
          >{
            'target_user_id': normalizedUserId,

            'target_name': normalizedName,

            'source': 'match',
          },
    );
  }

  // ============================================================
  // PERFIL FAVORITADO
  // ============================================================

  Future<
    RecentActivityModel?
  >
  registerFavorite({
    required String targetUserId,
    required String targetName,
    String? targetRoleLabel,
  }) {
    final normalizedUserId = targetUserId.trim();

    final normalizedName = targetName.trim();

    final normalizedRole = targetRoleLabel?.trim();

    if (normalizedUserId.isEmpty ||
        normalizedName.isEmpty) {
      return Future<
        RecentActivityModel?
      >.value(
        null,
      );
    }

    final description =
        normalizedRole !=
                null &&
            normalizedRole.isNotEmpty
        ? 'Você demonstrou interesse em um $normalizedRole.'
        : 'Você demonstrou interesse em $normalizedName.';

    return _controller.createActivity(
      type: RecentActivityType.favorite,

      title: 'Perfil favoritado',

      description: description,

      metadata:
          <
            String,
            dynamic
          >{
            'target_user_id': normalizedUserId,

            'target_name': normalizedName,

            if (normalizedRole !=
                    null &&
                normalizedRole.isNotEmpty)
              'target_role_label': normalizedRole,

            'source': 'match',
          },
    );
  }

  // ============================================================
  // ARQUIVO ADICIONADO
  // ============================================================

  Future<
    RecentActivityModel?
  >
  registerFileAdded({
    required String fileName,
    String? fileId,
    String? mimeType,
    int? fileSize,
  }) {
    final normalizedFileName = fileName.trim();

    final normalizedFileId = fileId?.trim();

    final normalizedMimeType = mimeType?.trim();

    if (normalizedFileName.isEmpty) {
      return Future<
        RecentActivityModel?
      >.value(
        null,
      );
    }

    return _controller.createActivity(
      type: RecentActivityType.fileAdded,

      title: 'Arquivo adicionado',

      description: '$normalizedFileName foi enviado ao Storage.',

      metadata:
          <
            String,
            dynamic
          >{
            'file_name': normalizedFileName,

            if (normalizedFileId !=
                    null &&
                normalizedFileId.isNotEmpty)
              'file_id': normalizedFileId,

            if (normalizedMimeType !=
                    null &&
                normalizedMimeType.isNotEmpty)
              'mime_type': normalizedMimeType,

            if (fileSize !=
                    null &&
                fileSize >=
                    0)
              'file_size': fileSize,

            'source': 'storage',
          },
    );
  }

  // ============================================================
  // ATIVIDADE GENÉRICA
  // ============================================================

  Future<
    RecentActivityModel?
  >
  registerCustom({
    required RecentActivityType type,
    required String title,
    required String description,
    Map<
      String,
      dynamic
    >?
    metadata,
  }) {
    final normalizedTitle = title.trim();

    final normalizedDescription = description.trim();

    if (normalizedTitle.isEmpty ||
        normalizedDescription.isEmpty) {
      return Future<
        RecentActivityModel?
      >.value(
        null,
      );
    }

    return _controller.createActivity(
      type: type,

      title: normalizedTitle,

      description: normalizedDescription,

      metadata:
          metadata ==
              null
          ? <
              String,
              dynamic
            >{
              'source': 'custom',
            }
          : <
              String,
              dynamic
            >{
              ...metadata,
              'source':
                  metadata['source'] ??
                  'custom',
            },
    );
  }
}
