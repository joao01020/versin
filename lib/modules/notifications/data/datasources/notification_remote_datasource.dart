import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/system_notification_model.dart';

// ============================================================
// NOTIFICATION REMOTE DATASOURCE
// ============================================================

abstract class NotificationRemoteDatasource {
  // ============================================================
  // BUSCAR
  // ============================================================

  Future<
    List<
      SystemNotificationModel
    >
  >
  getNotifications();

  Future<
    List<
      SystemNotificationModel
    >
  >
  getUnreadNotifications();

  Future<
    int
  >
  getUnreadCount();

  Future<
    SystemNotificationModel?
  >
  getNotificationById(
    String notificationId,
  );

  // ============================================================
  // REALTIME
  // ============================================================

  Stream<
    List<
      SystemNotificationModel
    >
  >
  watchNotifications();

  // ============================================================
  // LEITURA
  // ============================================================

  Future<
    void
  >
  markAsRead(
    String notificationId,
  );

  Future<
    void
  >
  markAllAsRead();

  // ============================================================
  // ADMINISTRAÇÃO
  // ============================================================

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

  Future<
    void
  >
  deactivateNotification(
    String notificationId,
  );

  Future<
    void
  >
  activateNotification(
    String notificationId,
  );

  Future<
    void
  >
  deleteNotification(
    String notificationId,
  );

  // ============================================================
  // PROGRESSO
  // ============================================================

  Future<
    void
  >
  updateProgress({
    required String notificationId,
    required int progress,
    required SystemNotificationStatus status,
    String? progressMessage,
  });

  // ============================================================
  // DISPOSE
  // ============================================================

  Future<
    void
  >
  dispose();
}

// ============================================================
// IMPLEMENTAÇÃO SUPABASE
// ============================================================

class NotificationRemoteDatasourceImpl
    implements
        NotificationRemoteDatasource {
  // ============================================================
  // TABELAS
  // ============================================================

  static const String _notificationsTable = 'system_notifications';

  static const String _readsTable = 'notification_reads';

  // ============================================================
  // SELECT
  // ============================================================

  static const String _notificationSelect = '''
    id,
    title,
    message,
    type,
    is_active,
    target_user_id,
    progress,
    status,
    progress_message,
    created_at,
    expires_at
  ''';

  // ============================================================
  // SUPABASE
  // ============================================================

  final SupabaseClient _supabase;

  // ============================================================
  // STREAM
  // ============================================================

  StreamSubscription<
    List<
      Map<
        String,
        dynamic
      >
    >
  >?
  _notificationSubscription;

  final StreamController<
    List<
      SystemNotificationModel
    >
  >
  _streamController =
      StreamController<
        List<
          SystemNotificationModel
        >
      >.broadcast();

  bool _isListening = false;

  bool _isDisposed = false;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  NotificationRemoteDatasourceImpl({
    SupabaseClient? supabase,
  }) : _supabase =
           supabase ??
           Supabase.instance.client;

  // ============================================================
  // USER ID
  // ============================================================

  String? get _currentUserId {
    return _supabase.auth.currentUser?.id;
  }

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
    try {
      final response = await _supabase
          .from(
            _notificationsTable,
          )
          .select(
            _notificationSelect,
          )
          .eq(
            'is_active',
            true,
          )
          .order(
            'created_at',
            ascending: false,
          );

      final rows =
          List<
            Map<
              String,
              dynamic
            >
          >.from(
            response,
          );

      // ========================================================
      // IDS JÁ LIDOS
      // ========================================================

      final readIds = await _loadReadNotificationIds();

      final currentUserId = _currentUserId;

      final notifications =
          <
            SystemNotificationModel
          >[];

      // ========================================================
      // MAPEAR
      // ========================================================

      for (final row in rows) {
        final notificationId = row['id']?.toString().trim();

        if (notificationId ==
                null ||
            notificationId.isEmpty) {
          continue;
        }

        final notification =
            SystemNotificationModel.fromMap(
              row,
            ).copyWith(
              isRead: readIds.contains(
                notificationId,
              ),
            );

        // ======================================================
        // VISIBILIDADE
        // ======================================================

        if (!notification.isVisibleForUser(
          currentUserId,
        )) {
          continue;
        }

        // ======================================================
        // ATIVA / EXPIRAÇÃO
        // ======================================================

        if (!notification.canDisplay) {
          continue;
        }

        notifications.add(
          notification,
        );
      }

      // ========================================================
      // ORDENAR
      // ========================================================

      notifications.sort(
        (
          a,
          b,
        ) {
          return b.createdAt.compareTo(
            a.createdAt,
          );
        },
      );

      debugPrint(
        '[NOTIFICATION REMOTE] '
        '${notifications.length} '
        'notificação(ões) carregada(s).',
      );

      return notifications;
    } on PostgrestException catch (
      error
    ) {
      debugPrint(
        '[NOTIFICATION REMOTE] '
        'Erro Supabase ao carregar: '
        '${error.message}',
      );

      rethrow;
    } catch (
      error
    ) {
      debugPrint(
        '[NOTIFICATION REMOTE] '
        'Erro ao carregar notificações: '
        '$error',
      );

      rethrow;
    }
  }

  // ============================================================
  // NÃO LIDAS
  // ============================================================

  @override
  Future<
    List<
      SystemNotificationModel
    >
  >
  getUnreadNotifications() async {
    final notifications = await getNotifications();

    return notifications
        .where(
          (
            notification,
          ) => notification.isUnread,
        )
        .toList();
  }

  // ============================================================
  // CONTAGEM NÃO LIDA
  // ============================================================

  @override
  Future<
    int
  >
  getUnreadCount() async {
    final notifications = await getUnreadNotifications();

    return notifications.length;
  }

  // ============================================================
  // POR ID
  // ============================================================

  @override
  Future<
    SystemNotificationModel?
  >
  getNotificationById(
    String notificationId,
  ) async {
    final id = notificationId.trim();

    if (id.isEmpty) {
      return null;
    }

    try {
      final response = await _supabase
          .from(
            _notificationsTable,
          )
          .select(
            _notificationSelect,
          )
          .eq(
            'id',
            id,
          )
          .maybeSingle();

      if (response ==
          null) {
        return null;
      }

      final readIds = await _loadReadNotificationIds();

      final notification =
          SystemNotificationModel.fromMap(
            response,
          ).copyWith(
            isRead: readIds.contains(
              id,
            ),
          );

      if (!notification.isVisibleForUser(
        _currentUserId,
      )) {
        return null;
      }

      if (!notification.canDisplay) {
        return null;
      }

      return notification;
    } on PostgrestException catch (
      error
    ) {
      debugPrint(
        '[NOTIFICATION REMOTE] '
        'Erro ao buscar por ID: '
        '${error.message}',
      );

      rethrow;
    }
  }

  // ============================================================
  // REALTIME
  // ============================================================

  @override
  Stream<
    List<
      SystemNotificationModel
    >
  >
  watchNotifications() {
    _startRealtime();

    return _streamController.stream;
  }

  // ============================================================
  // INICIAR REALTIME
  // ============================================================

  void _startRealtime() {
    if (_isDisposed ||
        _isListening) {
      return;
    }

    _isListening = true;

    _notificationSubscription = _supabase
        .from(
          _notificationsTable,
        )
        .stream(
          primaryKey: [
            'id',
          ],
        )
        .listen(
          (
            _,
          ) async {
            if (_isDisposed) {
              return;
            }

            try {
              final notifications = await getNotifications();

              if (_isDisposed ||
                  _streamController.isClosed) {
                return;
              }

              _streamController.add(
                notifications,
              );
            } catch (
              error
            ) {
              if (_isDisposed ||
                  _streamController.isClosed) {
                return;
              }

              _streamController.addError(
                error,
              );
            }
          },
          onError:
              (
                Object error,
              ) {
                if (_isDisposed ||
                    _streamController.isClosed) {
                  return;
                }

                debugPrint(
                  '[NOTIFICATION REMOTE] '
                  'Erro realtime: '
                  '$error',
                );

                _streamController.addError(
                  error,
                );
              },
        );

    // ==========================================================
    // ESTADO INICIAL
    // ==========================================================

    unawaited(
      _emitCurrentState(),
    );
  }

  // ============================================================
  // EMITIR ESTADO
  // ============================================================

  Future<
    void
  >
  _emitCurrentState() async {
    try {
      final notifications = await getNotifications();

      if (_isDisposed ||
          _streamController.isClosed) {
        return;
      }

      _streamController.add(
        notifications,
      );
    } catch (
      error
    ) {
      if (_isDisposed ||
          _streamController.isClosed) {
        return;
      }

      _streamController.addError(
        error,
      );
    }
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
    final userId = _currentUserId;

    if (userId ==
        null) {
      throw const AuthException(
        'Usuário não autenticado.',
      );
    }

    final id = notificationId.trim();

    if (id.isEmpty) {
      return;
    }

    await _supabase
        .from(
          _readsTable,
        )
        .upsert(
          {
            'user_id': userId,

            'notification_id': id,

            'read_at': DateTime.now().toUtc().toIso8601String(),
          },
          onConflict: 'user_id,notification_id',
        );

    debugPrint(
      '[NOTIFICATION REMOTE] '
      'Marcada como lida: '
      '$id',
    );
  }

  // ============================================================
  // MARCAR TODAS
  // ============================================================

  @override
  Future<
    void
  >
  markAllAsRead() async {
    final userId = _currentUserId;

    if (userId ==
        null) {
      throw const AuthException(
        'Usuário não autenticado.',
      );
    }

    final unread = await getUnreadNotifications();

    if (unread.isEmpty) {
      return;
    }

    final now = DateTime.now().toUtc().toIso8601String();

    final data = unread
        .map(
          (
            notification,
          ) => {
            'user_id': userId,

            'notification_id': notification.id,

            'read_at': now,
          },
        )
        .toList();

    await _supabase
        .from(
          _readsTable,
        )
        .upsert(
          data,
          onConflict: 'user_id,notification_id',
        );

    debugPrint(
      '[NOTIFICATION REMOTE] '
      'Todas as notificações foram '
      'marcadas como lidas.',
    );
  }

  // ============================================================
  // IDS LIDOS
  // ============================================================

  Future<
    Set<
      String
    >
  >
  _loadReadNotificationIds() async {
    final userId = _currentUserId;

    if (userId ==
        null) {
      return <
        String
      >{};
    }

    final response = await _supabase
        .from(
          _readsTable,
        )
        .select(
          'notification_id',
        )
        .eq(
          'user_id',
          userId,
        );

    final rows =
        List<
          Map<
            String,
            dynamic
          >
        >.from(
          response,
        );

    final ids =
        <
          String
        >{};

    for (final row in rows) {
      final id = row['notification_id']?.toString().trim();

      if (id !=
              null &&
          id.isNotEmpty) {
        ids.add(
          id,
        );
      }
    }

    return ids;
  }

  // ============================================================
  // PUBLICAR
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
    final normalizedTitle = title.trim();

    final normalizedMessage = message.trim();

    final normalizedTarget = targetUserId?.trim();

    final normalizedProgressMessage = progressMessage?.trim();

    if (normalizedTitle.isEmpty) {
      throw ArgumentError(
        'O título não pode ser vazio.',
      );
    }

    if (normalizedMessage.isEmpty) {
      throw ArgumentError(
        'A mensagem não pode ser vazia.',
      );
    }

    final safeProgress = _normalizeProgress(
      progress,
    );

    final response = await _supabase
        .from(
          _notificationsTable,
        )
        .insert(
          {
            'title': normalizedTitle,

            'message': normalizedMessage,

            'type': type.key,

            'target_user_id':
                normalizedTarget ==
                        null ||
                    normalizedTarget.isEmpty
                ? null
                : normalizedTarget,

            'is_active': true,

            'progress': safeProgress,

            'status': status.key,

            'progress_message':
                normalizedProgressMessage ==
                        null ||
                    normalizedProgressMessage.isEmpty
                ? null
                : normalizedProgressMessage,

            'expires_at': expiresAt?.toUtc().toIso8601String(),
          },
        )
        .select(
          _notificationSelect,
        )
        .single();

    final notification = SystemNotificationModel.fromMap(
      response,
    );

    debugPrint(
      '[NOTIFICATION REMOTE] '
      'Notificação publicada: '
      '${notification.id}',
    );

    return notification;
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
    final id = notificationId.trim();

    if (id.isEmpty) {
      return;
    }

    final normalizedMessage = progressMessage?.trim();

    final safeProgress = _normalizeProgress(
      progress,
    );

    await _supabase
        .from(
          _notificationsTable,
        )
        .update(
          {
            'progress': safeProgress,

            'status': status.key,

            'progress_message':
                normalizedMessage ==
                        null ||
                    normalizedMessage.isEmpty
                ? null
                : normalizedMessage,
          },
        )
        .eq(
          'id',
          id,
        );

    debugPrint(
      '[NOTIFICATION REMOTE] '
      'Progresso atualizado: '
      '$safeProgress% | '
      '${status.key} | '
      '$id',
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

  @override
  Future<
    void
  >
  deactivateNotification(
    String notificationId,
  ) async {
    await _setActive(
      notificationId: notificationId,
      active: false,
    );
  }

  // ============================================================
  // ATIVAR
  // ============================================================

  @override
  Future<
    void
  >
  activateNotification(
    String notificationId,
  ) async {
    await _setActive(
      notificationId: notificationId,
      active: true,
    );
  }

  // ============================================================
  // ALTERAR ACTIVE
  // ============================================================

  Future<
    void
  >
  _setActive({
    required String notificationId,
    required bool active,
  }) async {
    final id = notificationId.trim();

    if (id.isEmpty) {
      return;
    }

    await _supabase
        .from(
          _notificationsTable,
        )
        .update(
          {
            'is_active': active,
          },
        )
        .eq(
          'id',
          id,
        );

    debugPrint(
      '[NOTIFICATION REMOTE] '
      'Notificação $id '
      '${active ? 'ativada' : 'desativada'}.',
    );
  }

  // ============================================================
  // DELETE
  // ============================================================

  @override
  Future<
    void
  >
  deleteNotification(
    String notificationId,
  ) async {
    final id = notificationId.trim();

    if (id.isEmpty) {
      return;
    }

    await _supabase
        .from(
          _notificationsTable,
        )
        .delete()
        .eq(
          'id',
          id,
        );

    debugPrint(
      '[NOTIFICATION REMOTE] '
      'Notificação removida: '
      '$id',
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
    if (_isDisposed) {
      return;
    }

    _isDisposed = true;

    await _notificationSubscription?.cancel();

    _notificationSubscription = null;

    _isListening = false;

    if (!_streamController.isClosed) {
      await _streamController.close();
    }
  }
}
