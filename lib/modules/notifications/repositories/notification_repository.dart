import 'package:versin/modules/notifications/models/system_notification_model.dart';

// ============================================================
// NOTIFICATION REPOSITORY
// ============================================================
//
// Contrato central do módulo de notificações.
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

abstract class NotificationRepository {
  // ==========================================================
  // BUSCAR NOTIFICAÇÕES
  // ==========================================================

  Future<
    List<
      SystemNotificationModel
    >
  >
  getNotifications();

  // ==========================================================
  // BUSCAR NÃO LIDAS
  // ==========================================================

  Future<
    List<
      SystemNotificationModel
    >
  >
  getUnreadNotifications();

  // ==========================================================
  // QUANTIDADE DE NÃO LIDAS
  // ==========================================================

  Future<
    int
  >
  getUnreadCount();

  // ==========================================================
  // BUSCAR POR ID
  // ==========================================================

  Future<
    SystemNotificationModel?
  >
  getNotificationById(
    String notificationId,
  );

  // ==========================================================
  // REALTIME
  // ==========================================================
  //
  // Mantém:
  //
  // - painel de notificações;
  // - badge;
  // - modal;
  // - progresso de atualização;
  //
  // sincronizados com o Supabase.
  //
  // ==========================================================

  Stream<
    List<
      SystemNotificationModel
    >
  >
  watchNotifications();

  // ==========================================================
  // MARCAR COMO LIDA
  // ==========================================================

  Future<
    void
  >
  markAsRead(
    String notificationId,
  );

  // ==========================================================
  // MARCAR TODAS COMO LIDAS
  // ==========================================================

  Future<
    void
  >
  markAllAsRead();

  // ==========================================================
  // PUBLICAR NOTIFICAÇÃO
  // ==========================================================
  //
  // Para notificações normais:
  //
  // progress = 0
  // status = pending
  //
  // Para atualização:
  //
  // type = update
  // progress = 0
  // status = pending
  // progressMessage = "Atualização disponível"
  //
  // ==========================================================

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
  });

  // ==========================================================
  // ATUALIZAR PROGRESSO
  // ==========================================================
  //
  // Utilizado principalmente pelas notificações do tipo:
  //
  // SystemNotificationType.update
  //
  // Exemplo:
  //
  // 0%
  // pending
  //
  // 20%
  // downloading
  //
  // 80%
  // installing
  //
  // 100%
  // completed
  //
  // O Realtime do Supabase propaga essa alteração para o
  // NotificationController e posteriormente para o modal.
  //
  // ==========================================================

  Future<
    void
  >
  updateProgress({
    required String notificationId,
    required int progress,
    required SystemNotificationStatus status,
    String? progressMessage,
  });

  // ==========================================================
  // DESATIVAR
  // ==========================================================

  Future<
    void
  >
  deactivateNotification(
    String notificationId,
  );

  // ==========================================================
  // REATIVAR
  // ==========================================================

  Future<
    void
  >
  activateNotification(
    String notificationId,
  );

  // ==========================================================
  // REMOVER
  // ==========================================================

  Future<
    void
  >
  deleteNotification(
    String notificationId,
  );

  // ==========================================================
  // DISPOSE
  // ==========================================================

  Future<
    void
  >
  dispose();
}
