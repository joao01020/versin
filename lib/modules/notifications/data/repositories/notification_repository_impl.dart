import 'package:versin/modules/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:versin/modules/notifications/models/system_notification_model.dart';
import 'package:versin/modules/notifications/repositories/notification_repository.dart';

// ============================================================
// NOTIFICATION REPOSITORY IMPLEMENTATION
// ============================================================
//
// Implementação concreta do:
//
// NotificationRepository
//
// Responsabilidades:
//
// - receber operações vindas do Controller;
// - validar dados;
// - normalizar informações;
// - encaminhar operações para o Datasource;
// - manter o Controller independente do Supabase.
//
// Fluxo:
//
// Dashboard / Widgets
//        ↓
// NotificationController
//        ↓
// NotificationRepository
//        ↓
// NotificationRepositoryImpl
//        ↓
// NotificationRemoteDatasource
//        ↓
// Supabase
//
// ============================================================

class NotificationRepositoryImpl
    implements
        NotificationRepository {
  // ============================================================
  // DEPENDÊNCIA
  // ============================================================

  final NotificationRemoteDatasource _remoteDatasource;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  NotificationRepositoryImpl({
    NotificationRemoteDatasource? remoteDatasource,
  }) : _remoteDatasource =
           remoteDatasource ??
           NotificationRemoteDatasourceImpl();

  // ============================================================
  // BUSCAR NOTIFICAÇÕES
  // ============================================================

  @override
  Future<
    List<
      SystemNotificationModel
    >
  >
  getNotifications() async {
    return await _remoteDatasource.getNotifications();
  }

  // ============================================================
  // BUSCAR NÃO LIDAS
  // ============================================================

  @override
  Future<
    List<
      SystemNotificationModel
    >
  >
  getUnreadNotifications() async {
    return await _remoteDatasource.getUnreadNotifications();
  }

  // ============================================================
  // QUANTIDADE DE NÃO LIDAS
  // ============================================================

  @override
  Future<
    int
  >
  getUnreadCount() async {
    return await _remoteDatasource.getUnreadCount();
  }

  // ============================================================
  // OBSERVAR NOTIFICAÇÕES
  // ============================================================

  @override
  Stream<
    List<
      SystemNotificationModel
    >
  >
  watchNotifications() {
    return _remoteDatasource.watchNotifications();
  }

  // ============================================================
  // BUSCAR POR ID
  // ============================================================

  @override
  Future<
    SystemNotificationModel?
  >
  getNotificationById(
    String notificationId,
  ) async {
    final normalizedId = notificationId.trim();

    if (normalizedId.isEmpty) {
      return null;
    }

    return await _remoteDatasource.getNotificationById(
      normalizedId,
    );
  }

  // ============================================================
  // MARCAR COMO LIDA
  // ============================================================

  @override
  Future<
    void
  >
  markAsRead(
    String notificationId,
  ) async {
    final normalizedId = notificationId.trim();

    if (normalizedId.isEmpty) {
      return;
    }

    await _remoteDatasource.markAsRead(
      normalizedId,
    );
  }

  // ============================================================
  // MARCAR TODAS COMO LIDAS
  // ============================================================

  @override
  Future<
    void
  >
  markAllAsRead() async {
    await _remoteDatasource.markAllAsRead();
  }

  // ============================================================
  // PUBLICAR NOTIFICAÇÃO
  // ============================================================

  @override
  Future<
    SystemNotificationModel
  >
  publishNotification({
    required String title,
    required String message,
    required SystemNotificationType type,
    String? targetUserId,
    DateTime? expiresAt,
    int progress = 0,
    SystemNotificationStatus status = SystemNotificationStatus.pending,
    String? progressMessage,
  }) async {
    // ==========================================================
    // NORMALIZAR
    // ==========================================================

    final normalizedTitle = title.trim();

    final normalizedMessage = message.trim();

    final normalizedTargetUserId = targetUserId?.trim();

    final normalizedProgressMessage = progressMessage?.trim();

    // ==========================================================
    // VALIDAR TÍTULO
    // ==========================================================

    if (normalizedTitle.isEmpty) {
      throw ArgumentError(
        'O título da notificação não pode ser vazio.',
      );
    }

    // ==========================================================
    // VALIDAR MENSAGEM
    // ==========================================================

    if (normalizedMessage.isEmpty) {
      throw ArgumentError(
        'A mensagem da notificação não pode ser vazia.',
      );
    }

    // ==========================================================
    // VALIDAR EXPIRAÇÃO
    // ==========================================================

    if (expiresAt !=
            null &&
        !expiresAt.isAfter(
          DateTime.now(),
        )) {
      throw ArgumentError(
        'A data de expiração precisa estar no futuro.',
      );
    }

    // ==========================================================
    // NORMALIZAR PROGRESSO
    // ==========================================================

    final normalizedProgress = _normalizeProgress(
      progress,
    );

    // ==========================================================
    // VALIDAÇÃO DE STATUS
    // ==========================================================
    //
    // completed:
    // progresso obrigatoriamente vira 100.
    //
    // pending:
    // pode começar em 0.
    //
    // failed:
    // mantém o progresso em que ocorreu a falha.
    //
    // ==========================================================

    final finalProgress =
        status ==
            SystemNotificationStatus.completed
        ? 100
        : normalizedProgress;

    // ==========================================================
    // PUBLICAR
    // ==========================================================

    return await _remoteDatasource.publishNotification(
      title: normalizedTitle,

      message: normalizedMessage,

      type: type,

      targetUserId:
          normalizedTargetUserId ==
                  null ||
              normalizedTargetUserId.isEmpty
          ? null
          : normalizedTargetUserId,

      expiresAt: expiresAt,

      progress: finalProgress,

      status: status,

      progressMessage:
          normalizedProgressMessage ==
                  null ||
              normalizedProgressMessage.isEmpty
          ? null
          : normalizedProgressMessage,
    );
  }

  // ============================================================
  // ATUALIZAR PROGRESSO
  // ============================================================

  @override
  Future<
    void
  >
  updateProgress({
    required String notificationId,
    required int progress,
    required SystemNotificationStatus status,
    String? progressMessage,
  }) async {
    final normalizedId = notificationId.trim();

    if (normalizedId.isEmpty) {
      return;
    }

    final normalizedMessage = progressMessage?.trim();

    final normalizedProgress = _normalizeProgress(
      progress,
    );

    final finalProgress =
        status ==
            SystemNotificationStatus.completed
        ? 100
        : normalizedProgress;

    await _remoteDatasource.updateProgress(
      notificationId: normalizedId,

      progress: finalProgress,

      status: status,

      progressMessage:
          normalizedMessage ==
                  null ||
              normalizedMessage.isEmpty
          ? null
          : normalizedMessage,
    );
  }

  // ============================================================
  // NORMALIZAR PROGRESSO
  // ============================================================

  int _normalizeProgress(
    int progress,
  ) {
    if (progress <
        0) {
      return 0;
    }

    if (progress >
        100) {
      return 100;
    }

    return progress;
  }

  // ============================================================
  // DESATIVAR NOTIFICAÇÃO
  // ============================================================

  @override
  Future<
    void
  >
  deactivateNotification(
    String notificationId,
  ) async {
    final normalizedId = notificationId.trim();

    if (normalizedId.isEmpty) {
      return;
    }

    await _remoteDatasource.deactivateNotification(
      normalizedId,
    );
  }

  // ============================================================
  // ATIVAR NOTIFICAÇÃO
  // ============================================================

  @override
  Future<
    void
  >
  activateNotification(
    String notificationId,
  ) async {
    final normalizedId = notificationId.trim();

    if (normalizedId.isEmpty) {
      return;
    }

    await _remoteDatasource.activateNotification(
      normalizedId,
    );
  }

  // ============================================================
  // REMOVER NOTIFICAÇÃO
  // ============================================================

  @override
  Future<
    void
  >
  deleteNotification(
    String notificationId,
  ) async {
    final normalizedId = notificationId.trim();

    if (normalizedId.isEmpty) {
      return;
    }

    await _remoteDatasource.deleteNotification(
      normalizedId,
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  Future<
    void
  >
  dispose() async {
    await _remoteDatasource.dispose();
  }
}
