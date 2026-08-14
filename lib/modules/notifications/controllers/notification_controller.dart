import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/repositories/notification_repository_impl.dart';
import '../models/system_notification_model.dart';
import '../repositories/notification_repository.dart';

// ============================================================
// NOTIFICATION CONTROLLER
// ============================================================

class NotificationController
    extends
        ChangeNotifier {
  // ============================================================
  // REPOSITORY
  // ============================================================

  final NotificationRepository _repository;

  // ============================================================
  // STREAM
  // ============================================================

  StreamSubscription<
    List<
      SystemNotificationModel
    >
  >?
  _notificationsSubscription;

  // ============================================================
  // ESTADO
  // ============================================================

  List<
    SystemNotificationModel
  >
  _notifications =
      <
        SystemNotificationModel
      >[];

  bool _isLoading = false;

  bool _isInitialized = false;

  bool _isListening = false;

  bool _isDisposed = false;

  String? _errorMessage;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  NotificationController({
    NotificationRepository? repository,
  }) : _repository =
           repository ??
           NotificationRepositoryImpl();

  // ============================================================
  // GETTERS
  // ============================================================

  List<
    SystemNotificationModel
  >
  get notifications {
    return List<
      SystemNotificationModel
    >.unmodifiable(
      _notifications,
    );
  }

  bool get isLoading {
    return _isLoading;
  }

  bool get isInitialized {
    return _isInitialized;
  }

  bool get isListening {
    return _isListening;
  }

  String? get errorMessage {
    return _errorMessage;
  }

  bool get hasError {
    return _errorMessage !=
        null;
  }

  bool get hasNotifications {
    return _notifications.isNotEmpty;
  }

  int get totalCount {
    return _notifications.length;
  }

  // ============================================================
  // NÃO LIDAS
  // ============================================================

  int get unreadCount {
    var count = 0;

    for (final notification in _notifications) {
      if (notification.isUnread) {
        count++;
      }
    }

    return count;
  }

  bool get hasUnreadNotifications {
    return unreadCount >
        0;
  }

  List<
    SystemNotificationModel
  >
  get unreadNotifications {
    return _notifications.where(
      (
        notification,
      ) {
        return notification.isUnread;
      },
    ).toList();
  }

  // ============================================================
  // LIDAS
  // ============================================================

  List<
    SystemNotificationModel
  >
  get readNotifications {
    return _notifications.where(
      (
        notification,
      ) {
        return notification.isRead;
      },
    ).toList();
  }

  // ============================================================
  // ÚLTIMA NOTIFICAÇÃO
  // ============================================================

  SystemNotificationModel? get latestNotification {
    if (_notifications.isEmpty) {
      return null;
    }

    return _notifications.first;
  }

  // ============================================================
  // ATUALIZAÇÕES
  // ============================================================

  List<
    SystemNotificationModel
  >
  get updateNotifications {
    return _notifications.where(
      (
        notification,
      ) {
        return notification.type ==
            SystemNotificationType.update;
      },
    ).toList();
  }

  bool get hasUpdateNotifications {
    return updateNotifications.isNotEmpty;
  }

  SystemNotificationModel? get latestUpdateNotification {
    final updates = updateNotifications;

    if (updates.isEmpty) {
      return null;
    }

    return updates.first;
  }

  // ============================================================
  // INICIALIZAR
  // ============================================================

  Future<
    void
  >
  init() async {
    if (_isDisposed) {
      return;
    }

    if (_isInitialized) {
      return;
    }

    _isInitialized = true;

    // ==========================================================
    // PRIMEIRA CARGA
    // ==========================================================

    await load();

    if (_isDisposed) {
      return;
    }

    // ==========================================================
    // REALTIME
    // ==========================================================
    //
    // O Datasource ignora o primeiro snapshot do Supabase,
    // porque a carga inicial já aconteceu acima.
    //
    // ==========================================================

    startListening();
  }

  // ============================================================
  // CARREGAR
  // ============================================================

  Future<
    void
  >
  load() async {
    if (_isDisposed) {
      return;
    }

    if (_isLoading) {
      return;
    }

    _isLoading = true;

    _errorMessage = null;

    _safeNotify();

    try {
      final result = await _repository.getNotifications();

      if (_isDisposed) {
        return;
      }

      _setNotifications(
        result,
      );

      debugPrint(
        '[NOTIFICATION CONTROLLER] '
        '${_notifications.length} '
        'notificação(ões) carregada(s).',
      );

      debugPrint(
        '[NOTIFICATION CONTROLLER] '
        'Não lidas: $unreadCount',
      );
    } catch (
      error
    ) {
      if (_isDisposed) {
        return;
      }

      _errorMessage = 'Não foi possível carregar as notificações.';

      debugPrint(
        '[NOTIFICATION CONTROLLER] '
        'Erro ao carregar: $error',
      );
    } finally {
      if (!_isDisposed) {
        _isLoading = false;

        _safeNotify();
      }
    }
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<
    void
  >
  refresh() async {
    if (_isDisposed) {
      return;
    }

    try {
      final result = await _repository.getNotifications();

      if (_isDisposed) {
        return;
      }

      _errorMessage = null;

      _setNotifications(
        result,
      );

      debugPrint(
        '[NOTIFICATION CONTROLLER] '
        'Notificações atualizadas.',
      );
    } catch (
      error
    ) {
      if (_isDisposed) {
        return;
      }

      _errorMessage = 'Não foi possível atualizar as notificações.';

      debugPrint(
        '[NOTIFICATION CONTROLLER] '
        'Erro no refresh: $error',
      );

      _safeNotify();
    }
  }

  // ============================================================
  // REALTIME
  // ============================================================

  void startListening() {
    if (_isDisposed) {
      return;
    }

    if (_isListening) {
      return;
    }

    _isListening = true;

    _notificationsSubscription?.cancel();

    _notificationsSubscription = _repository.watchNotifications().listen(
      (
        List<
          SystemNotificationModel
        >
        notifications,
      ) {
        if (_isDisposed) {
          return;
        }

        _errorMessage = null;

        // ======================================================
        // SUBSTITUIR ESTADO
        // ======================================================
        //
        // _setNotifications também elimina IDs duplicados.
        //
        // ======================================================

        _setNotifications(
          notifications,
        );

        debugPrint(
          '[NOTIFICATION CONTROLLER] '
          'Realtime atualizado.',
        );

        debugPrint(
          '[NOTIFICATION CONTROLLER] '
          'Total: ${_notifications.length}',
        );

        debugPrint(
          '[NOTIFICATION CONTROLLER] '
          'Não lidas: $unreadCount',
        );
      },
      onError:
          (
            Object error,
          ) {
            if (_isDisposed) {
              return;
            }

            _errorMessage =
                'Não foi possível receber '
                'atualizações de notificações.';

            debugPrint(
              '[NOTIFICATION CONTROLLER] '
              'Erro realtime: $error',
            );

            _safeNotify();
          },
    );
  }

  // ============================================================
  // PARAR REALTIME
  // ============================================================

  Future<
    void
  >
  stopListening() async {
    await _notificationsSubscription?.cancel();

    _notificationsSubscription = null;

    _isListening = false;

    _safeNotify();
  }

  // ============================================================
  // BUSCAR LOCALMENTE
  // ============================================================

  SystemNotificationModel? findById(
    String notificationId,
  ) {
    final normalizedId = notificationId.trim();

    if (normalizedId.isEmpty) {
      return null;
    }

    for (final notification in _notifications) {
      if (notification.id ==
          normalizedId) {
        return notification;
      }
    }

    return null;
  }

  // ============================================================
  // EXISTE
  // ============================================================

  bool containsNotification(
    String notificationId,
  ) {
    return findById(
          notificationId,
        ) !=
        null;
  }

  // ============================================================
  // BUSCAR REMOTAMENTE
  // ============================================================

  Future<
    SystemNotificationModel?
  >
  loadNotificationById(
    String notificationId,
  ) async {
    final normalizedId = notificationId.trim();

    if (normalizedId.isEmpty) {
      return null;
    }

    try {
      final notification = await _repository.getNotificationById(
        normalizedId,
      );

      if (notification ==
          null) {
        return null;
      }

      if (_isDisposed) {
        return notification;
      }

      _upsertLocalNotification(
        notification,
      );

      _sortNotifications();

      _safeNotify();

      return notification;
    } catch (
      error
    ) {
      if (!_isDisposed) {
        _errorMessage = 'Não foi possível carregar a notificação.';

        _safeNotify();
      }

      debugPrint(
        '[NOTIFICATION CONTROLLER] '
        'Erro ao carregar notificação: '
        '$error',
      );

      return null;
    }
  }

  // ============================================================
  // MARCAR COMO LIDA
  // ============================================================

  Future<
    bool
  >
  markAsRead(
    String notificationId,
  ) async {
    final normalizedId = notificationId.trim();

    if (normalizedId.isEmpty) {
      return false;
    }

    final index = _notifications.indexWhere(
      (
        notification,
      ) {
        return notification.id ==
            normalizedId;
      },
    );

    if (index <
        0) {
      return false;
    }

    final current = _notifications[index];

    if (current.isRead) {
      return true;
    }

    // ==========================================================
    // UPDATE OTIMISTA
    // ==========================================================

    _notifications[index] = current.markAsRead();

    _safeNotify();

    try {
      await _repository.markAsRead(
        normalizedId,
      );

      debugPrint(
        '[NOTIFICATION CONTROLLER] '
        'Notificação marcada como lida: '
        '$normalizedId',
      );

      return true;
    } catch (
      error
    ) {
      // ========================================================
      // ROLLBACK
      // ========================================================

      if (!_isDisposed) {
        final rollbackIndex = _notifications.indexWhere(
          (
            notification,
          ) {
            return notification.id ==
                normalizedId;
          },
        );

        if (rollbackIndex >=
            0) {
          _notifications[rollbackIndex] = current;
        }

        _errorMessage =
            'Não foi possível marcar '
            'a notificação como lida.';

        _safeNotify();
      }

      debugPrint(
        '[NOTIFICATION CONTROLLER] '
        'Erro ao marcar como lida: '
        '$error',
      );

      return false;
    }
  }

  // ============================================================
  // MARCAR TODAS COMO LIDAS
  // ============================================================

  Future<
    bool
  >
  markAllAsRead() async {
    if (_notifications.isEmpty) {
      return true;
    }

    if (unreadCount ==
        0) {
      return true;
    }

    final previous =
        List<
          SystemNotificationModel
        >.from(
          _notifications,
        );

    // ==========================================================
    // UPDATE OTIMISTA
    // ==========================================================

    _notifications = _notifications.map(
      (
        notification,
      ) {
        return notification.markAsRead();
      },
    ).toList();

    _safeNotify();

    try {
      await _repository.markAllAsRead();

      debugPrint(
        '[NOTIFICATION CONTROLLER] '
        'Todas marcadas como lidas.',
      );

      return true;
    } catch (
      error
    ) {
      if (!_isDisposed) {
        _notifications = previous;

        _errorMessage =
            'Não foi possível marcar '
            'todas como lidas.';

        _safeNotify();
      }

      debugPrint(
        '[NOTIFICATION CONTROLLER] '
        'Erro ao marcar todas como lidas: '
        '$error',
      );

      return false;
    }
  }

  // ============================================================
  // PUBLICAR NOTIFICAÇÃO
  // ============================================================

  Future<
    SystemNotificationModel?
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
    try {
      final notification = await _repository.publishNotification(
        title: title,
        message: message,
        type: type,
        targetUserId: targetUserId,
        expiresAt: expiresAt,
        progress: progress,
        status: status,
        progressMessage: progressMessage,
      );

      if (_isDisposed) {
        return notification;
      }

      // ========================================================
      // UPSERT
      // ========================================================
      //
      // Caso o Realtime entregue o mesmo registro depois,
      // continuaremos com somente um item porque o estado
      // local é indexado logicamente pelo ID.
      //
      // ========================================================

      _upsertLocalNotification(
        notification,
      );

      _sortNotifications();

      _safeNotify();

      debugPrint(
        '[NOTIFICATION CONTROLLER] '
        'Publicada: ${notification.id}',
      );

      return notification;
    } catch (
      error
    ) {
      if (!_isDisposed) {
        _errorMessage = 'Não foi possível publicar a notificação.';

        _safeNotify();
      }

      debugPrint(
        '[NOTIFICATION CONTROLLER] '
        'Erro ao publicar: $error',
      );

      return null;
    }
  }

  // ============================================================
  // ATUALIZAR PROGRESSO
  // ============================================================

  Future<
    bool
  >
  updateProgress({
    required String notificationId,
    required int progress,
    required SystemNotificationStatus status,
    String? progressMessage,
  }) async {
    final normalizedId = notificationId.trim();

    if (normalizedId.isEmpty) {
      return false;
    }

    final normalizedProgress = _normalizeProgress(
      progress,
    );

    final finalProgress =
        status ==
            SystemNotificationStatus.completed
        ? 100
        : normalizedProgress;

    try {
      await _repository.updateProgress(
        notificationId: normalizedId,
        progress: finalProgress,
        status: status,
        progressMessage: progressMessage,
      );

      if (_isDisposed) {
        return true;
      }

      // ========================================================
      // ATUALIZAÇÃO LOCAL IMEDIATA
      // ========================================================

      final current = findById(
        normalizedId,
      );

      if (current !=
          null) {
        final updated = current.copyWith(
          progress: finalProgress,
          status: status,
          progressMessage: progressMessage,
        );

        _upsertLocalNotification(
          updated,
        );

        _safeNotify();
      }

      debugPrint(
        '[NOTIFICATION CONTROLLER] '
        'Progresso atualizado: '
        '$finalProgress% | '
        '${status.key} | '
        '$normalizedId',
      );

      return true;
    } catch (
      error
    ) {
      if (!_isDisposed) {
        _errorMessage =
            'Não foi possível atualizar '
            'o progresso da atualização.';

        _safeNotify();
      }

      debugPrint(
        '[NOTIFICATION CONTROLLER] '
        'Erro ao atualizar progresso: '
        '$error',
      );

      return false;
    }
  }

  // ============================================================
  // PENDENTE
  // ============================================================

  Future<
    bool
  >
  setUpdatePending({
    required String notificationId,
    String? message,
  }) {
    return updateProgress(
      notificationId: notificationId,
      progress: 0,
      status: SystemNotificationStatus.pending,
      progressMessage: message,
    );
  }

  // ============================================================
  // DOWNLOAD
  // ============================================================

  Future<
    bool
  >
  setUpdateDownloading({
    required String notificationId,
    required int progress,
    String? message,
  }) {
    return updateProgress(
      notificationId: notificationId,
      progress: progress,
      status: SystemNotificationStatus.downloading,
      progressMessage: message,
    );
  }

  // ============================================================
  // INSTALAÇÃO
  // ============================================================

  Future<
    bool
  >
  setUpdateInstalling({
    required String notificationId,
    required int progress,
    String? message,
  }) {
    return updateProgress(
      notificationId: notificationId,
      progress: progress,
      status: SystemNotificationStatus.installing,
      progressMessage: message,
    );
  }

  // ============================================================
  // CONCLUÍDA
  // ============================================================

  Future<
    bool
  >
  setUpdateCompleted({
    required String notificationId,
    String? message,
  }) {
    return updateProgress(
      notificationId: notificationId,
      progress: 100,
      status: SystemNotificationStatus.completed,
      progressMessage:
          message ??
          'Atualização concluída.',
    );
  }

  // ============================================================
  // FALHA
  // ============================================================

  Future<
    bool
  >
  setUpdateFailed({
    required String notificationId,
    required int progress,
    String? message,
  }) {
    return updateProgress(
      notificationId: notificationId,
      progress: progress,
      status: SystemNotificationStatus.failed,
      progressMessage:
          message ??
          'Não foi possível concluir a atualização.',
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
  // DESATIVAR
  // ============================================================

  Future<
    bool
  >
  deactivateNotification(
    String notificationId,
  ) async {
    final normalizedId = notificationId.trim();

    if (normalizedId.isEmpty) {
      return false;
    }

    try {
      await _repository.deactivateNotification(
        normalizedId,
      );

      if (_isDisposed) {
        return true;
      }

      _notifications.removeWhere(
        (
          notification,
        ) {
          return notification.id ==
              normalizedId;
        },
      );

      _safeNotify();

      return true;
    } catch (
      error
    ) {
      if (!_isDisposed) {
        _errorMessage =
            'Não foi possível desativar '
            'a notificação.';

        _safeNotify();
      }

      debugPrint(
        '[NOTIFICATION CONTROLLER] '
        'Erro ao desativar: $error',
      );

      return false;
    }
  }

  // ============================================================
  // ATIVAR
  // ============================================================

  Future<
    bool
  >
  activateNotification(
    String notificationId,
  ) async {
    final normalizedId = notificationId.trim();

    if (normalizedId.isEmpty) {
      return false;
    }

    try {
      await _repository.activateNotification(
        normalizedId,
      );

      await refresh();

      return true;
    } catch (
      error
    ) {
      if (!_isDisposed) {
        _errorMessage =
            'Não foi possível ativar '
            'a notificação.';

        _safeNotify();
      }

      debugPrint(
        '[NOTIFICATION CONTROLLER] '
        'Erro ao ativar: $error',
      );

      return false;
    }
  }

  // ============================================================
  // REMOVER
  // ============================================================

  Future<
    bool
  >
  deleteNotification(
    String notificationId,
  ) async {
    final normalizedId = notificationId.trim();

    if (normalizedId.isEmpty) {
      return false;
    }

    try {
      await _repository.deleteNotification(
        normalizedId,
      );

      if (_isDisposed) {
        return true;
      }

      _notifications.removeWhere(
        (
          notification,
        ) {
          return notification.id ==
              normalizedId;
        },
      );

      _safeNotify();

      debugPrint(
        '[NOTIFICATION CONTROLLER] '
        'Notificação removida: '
        '$normalizedId',
      );

      return true;
    } catch (
      error
    ) {
      if (!_isDisposed) {
        _errorMessage =
            'Não foi possível remover '
            'a notificação.';

        _safeNotify();
      }

      debugPrint(
        '[NOTIFICATION CONTROLLER] '
        'Erro ao remover: $error',
      );

      return false;
    }
  }

  // ============================================================
  // UPSERT LOCAL
  // ============================================================

  void _upsertLocalNotification(
    SystemNotificationModel notification,
  ) {
    final id = notification.id.trim();

    if (id.isEmpty) {
      return;
    }

    final index = _notifications.indexWhere(
      (
        item,
      ) {
        return item.id ==
            id;
      },
    );

    // ==========================================================
    // NOVA
    // ==========================================================

    if (index <
        0) {
      if (notification.canDisplay) {
        _notifications.add(
          notification,
        );
      }

      return;
    }

    // ==========================================================
    // NÃO DEVE MAIS SER EXIBIDA
    // ==========================================================

    if (!notification.canDisplay) {
      _notifications.removeAt(
        index,
      );

      return;
    }

    // ==========================================================
    // ATUALIZAR EXISTENTE
    // ==========================================================

    _notifications[index] = notification;
  }

  // ============================================================
  // LIMPAR ERRO
  // ============================================================

  void clearError() {
    if (_errorMessage ==
        null) {
      return;
    }

    _errorMessage = null;

    _safeNotify();
  }

  // ============================================================
  // DEFINIR NOTIFICAÇÕES
  // ============================================================

  void _setNotifications(
    Iterable<
      SystemNotificationModel
    >
    notifications,
  ) {
    // ==========================================================
    // MAP POR ID
    // ==========================================================
    //
    // Esta etapa garante que mesmo se por algum motivo a fonte
    // fornecer duas entradas com o mesmo UUID, apenas uma ficará
    // no estado utilizado pelo Dashboard.
    //
    // ==========================================================

    final byId =
        <
          String,
          SystemNotificationModel
        >{};

    for (final notification in notifications) {
      final id = notification.id.trim();

      if (id.isEmpty) {
        continue;
      }

      if (!notification.canDisplay) {
        continue;
      }

      byId[id] = notification;
    }

    _notifications = byId.values.toList();

    _sortNotifications();

    _safeNotify();
  }

  // ============================================================
  // ORDENAR
  // ============================================================

  void _sortNotifications() {
    _notifications.sort(
      (
        a,
        b,
      ) {
        return b.createdAt.compareTo(
          a.createdAt,
        );
      },
    );
  }

  // ============================================================
  // SAFE NOTIFY
  // ============================================================

  void _safeNotify() {
    if (_isDisposed) {
      return;
    }

    notifyListeners();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    if (_isDisposed) {
      return;
    }

    _isDisposed = true;

    _notificationsSubscription?.cancel();

    _notificationsSubscription = null;

    _isListening = false;

    unawaited(
      _repository.dispose(),
    );

    super.dispose();
  }
}
