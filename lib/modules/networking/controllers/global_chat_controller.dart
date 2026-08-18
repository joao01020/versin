import 'dart:async';

import 'package:flutter/foundation.dart';
import '../data/models/project_message_model.dart';
import '../services/global_chat_service.dart';

// ============================================================
// GLOBAL CHAT CONTROLLER
// ============================================================
//
// Observa mensagens mesmo quando a ChatView não está aberta.
//
// Pode operar em dois modos:
//
// 1. Studio Session específica:
//
//    GlobalChatController(
//      projectId: projectId,
//    )
//
// 2. Global:
//
//    GlobalChatController()
//
// No modo global, acompanha todas as Studio Sessions que a RLS
// permite ao usuário visualizar.
//
// Responsabilidades:
//
// - ouvir project_messages em Realtime;
// - ignorar o histórico inicial;
// - detectar apenas mensagens NOVAS;
// - ignorar mensagens enviadas pelo próprio usuário;
// - manter última mensagem recebida;
// - contar mensagens não lidas;
// - resolver o nome do remetente;
// - distinguir texto / áudio;
// - não mostrar banner enquanto o ChatView estiver aberto;
// - permitir marcar mensagens como lidas;
// - permitir dispensar somente o banner.
//
// IMPORTANTE:
//
// Este controller NÃO substitui o ProjectChatController.
//
// ProjectChatController
// -> controla a tela completa do chat.
//
// GlobalChatController
// -> controla somente a experiência global de novas mensagens.
//
// GlobalChatService
// -> centraliza Realtime, usuário atual e resolução de perfis.
//
// ============================================================

class GlobalChatController
    with
        ChangeNotifier {
  // ==========================================================
  // PROJECT
  // ==========================================================

  final String? projectId;

  // ==========================================================
  // SERVICES
  // ==========================================================

  final GlobalChatService _chatService;

  // ==========================================================
  // SUBSCRIPTION
  // ==========================================================

  StreamSubscription<
    List<
      ProjectMessageModel
    >
  >?
  _messagesSubscription;

  // ==========================================================
  // MESSAGE STATE
  // ==========================================================

  ProjectMessageModel? _latestMessage;

  int _unreadCount = 0;

  final Map<
    String,
    int
  >
  _unreadByProject =
      <
        String,
        int
      >{};

  bool _chatVisible = false;

  String? _visibleProjectId;

  bool _initialized = false;

  bool _initialSnapshotReceived = false;

  bool _disposed = false;

  bool _isLoading = false;

  String? _errorMessage;

  // ==========================================================
  // KNOWN MESSAGE IDS
  // ==========================================================

  final Set<
    String
  >
  _knownMessageIds =
      <
        String
      >{};

  // ==========================================================
  // SENDER CACHE
  // ==========================================================

  final Map<
    String,
    String
  >
  _senderNameCache =
      <
        String,
        String
      >{};

  final Set<
    String
  >
  _senderNameLoading =
      <
        String
      >{};

  String _latestSenderName = 'Membro';

  // ==========================================================
  // BANNER
  // ==========================================================

  bool _bannerDismissed = false;

  // ==========================================================
  // CONSTRUCTOR
  // ==========================================================

  GlobalChatController({
    String? projectId,
    GlobalChatService? chatService,
  }) : projectId = _normalizeOptionalProjectId(
         projectId,
       ),
       _chatService =
           chatService ??
           GlobalChatService();

  // ==========================================================
  // GETTERS
  // ==========================================================

  ProjectMessageModel? get latestMessage => _latestMessage;

  int get unreadCount => _unreadCount;

  bool get chatVisible => _chatVisible;

  bool get initialized => _initialized;

  bool get isLoading => _isLoading;

  bool get hasError =>
      _errorMessage !=
      null;

  String? get errorMessage => _errorMessage;

  String get senderName => _latestSenderName;

  String? get currentUserId => _chatService.currentUserId?.trim();

  bool get isGlobalMode =>
      projectId ==
      null;

  String? get latestProjectId {
    final value = _latestMessage?.projectId.trim();

    if (value ==
            null ||
        value.isEmpty) {
      return null;
    }

    return value;
  }

  String? get visibleProjectId => _visibleProjectId;

  bool get hasUnreadMessages =>
      _unreadCount >
      0;

  int unreadCountForProject(
    String projectId,
  ) {
    final normalizedProjectId = projectId.trim();

    if (normalizedProjectId.isEmpty) {
      return 0;
    }

    return _unreadByProject[normalizedProjectId] ??
        0;
  }

  bool get hasNotification {
    final message = _latestMessage;

    if (message ==
            null ||
        _bannerDismissed ||
        _unreadCount <=
            0) {
      return false;
    }

    // Se o chat aberto é exatamente o projeto da mensagem,
    // não mostramos o banner para aquela mensagem.
    if (_chatVisible) {
      final messageProjectId = message.projectId.trim();

      final visibleProjectId = _visibleProjectId?.trim();

      if (visibleProjectId !=
              null &&
          visibleProjectId.isNotEmpty &&
          visibleProjectId ==
              messageProjectId) {
        return false;
      }

      // Controller específico de uma única Studio Session.
      if (!isGlobalMode) {
        return false;
      }
    }

    return true;
  }

  bool get latestIsAudio {
    final message = _latestMessage;

    if (message ==
        null) {
      return false;
    }

    return message.isAudio;
  }

  String get preview {
    final message = _latestMessage;

    if (message ==
        null) {
      return '';
    }

    if (message.isAudio) {
      return 'Enviou uma mensagem de áudio';
    }

    final content = message.content.trim();

    if (content.isEmpty) {
      return 'Nova mensagem';
    }

    return _compactPreview(
      content,
    );
  }

  // ==========================================================
  // INIT
  // ==========================================================

  Future<
    void
  >
  init() async {
    if (_disposed ||
        _initialized) {
      return;
    }

    _initialized = true;

    _isLoading = true;

    _errorMessage = null;

    _safeNotify();

    final userId = currentUserId;

    if (userId ==
            null ||
        userId.isEmpty) {
      _isLoading = false;

      _errorMessage = 'Usuário não autenticado.';

      _safeNotify();

      return;
    }

    await _startRealtime();
  }

  // ==========================================================
  // REALTIME
  // ==========================================================

  Future<
    void
  >
  _startRealtime() async {
    await _messagesSubscription?.cancel();

    _messagesSubscription = null;

    try {
      final stream = isGlobalMode
          ? _chatService.streamAllMessages()
          : _chatService.streamMessages(
              projectId: projectId!,
            );

      _messagesSubscription = stream.listen(
        _handleMessages,
        onError: _handleRealtimeError,
      );

      debugPrint(
        isGlobalMode
            ? '[GLOBAL CHAT] Realtime global iniciado.'
            : '[GLOBAL CHAT] Realtime iniciado para '
                  '$projectId.',
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[GLOBAL CHAT] '
        'Erro ao iniciar Realtime: '
        '$error',
      );

      debugPrint(
        '[GLOBAL CHAT] '
        '$stackTrace',
      );

      if (_disposed) {
        return;
      }

      _isLoading = false;

      _errorMessage = 'Não foi possível acompanhar novas mensagens.';

      _safeNotify();
    }
  }

  // ==========================================================
  // HANDLE MESSAGES
  // ==========================================================

  void _handleMessages(
    List<
      ProjectMessageModel
    >
    messages,
  ) {
    if (_disposed) {
      return;
    }

    final validMessages =
        messages.where(
          (
            message,
          ) {
            if (message.id.trim().isEmpty) {
              return false;
            }

            final messageProjectId = message.projectId.trim();

            if (messageProjectId.isEmpty) {
              return false;
            }

            if (isGlobalMode) {
              return true;
            }

            return messageProjectId ==
                projectId;
          },
        ).toList()..sort(
          (
            a,
            b,
          ) => a.createdAt.compareTo(
            b.createdAt,
          ),
        );

    // ========================================================
    // INITIAL SNAPSHOT
    // ========================================================
    //
    // O primeiro snapshot contém o histórico existente.
    //
    // Ele é usado somente como baseline para não abrir um
    // banner de "nova mensagem" para mensagens antigas.
    //
    // ========================================================

    if (!_initialSnapshotReceived) {
      _knownMessageIds
        ..clear()
        ..addAll(
          validMessages.map(
            (
              message,
            ) => message.id,
          ),
        );

      _initialSnapshotReceived = true;

      _isLoading = false;

      _errorMessage = null;

      _safeNotify();

      debugPrint(
        '[GLOBAL CHAT] '
        'Baseline criado com '
        '${_knownMessageIds.length} mensagem(ns).',
      );

      return;
    }

    // ========================================================
    // NEW MESSAGES
    // ========================================================

    final newMessages =
        <
          ProjectMessageModel
        >[];

    for (final message in validMessages) {
      if (_knownMessageIds.add(
        message.id,
      )) {
        newMessages.add(
          message,
        );
      }
    }

    if (newMessages.isEmpty) {
      return;
    }

    final userId = currentUserId;

    if (userId ==
            null ||
        userId.isEmpty) {
      return;
    }

    final incoming = newMessages
        .where(
          (
            message,
          ) =>
              message.senderId.trim() !=
              userId,
        )
        .toList();

    if (incoming.isEmpty) {
      return;
    }

    final latest = incoming.last;

    _latestMessage = latest;

    _bannerDismissed = false;

    // ========================================================
    // UNREAD POR PROJETO
    // ========================================================

    for (final message in incoming) {
      final messageProjectId = message.projectId.trim();

      if (messageProjectId.isEmpty) {
        continue;
      }

      final isVisibleProject =
          _chatVisible &&
          _visibleProjectId ==
              messageProjectId;

      if (isVisibleProject) {
        continue;
      }

      _unreadByProject.update(
        messageProjectId,
        (
          value,
        ) =>
            value +
            1,
        ifAbsent: () => 1,
      );
    }

    _recalculateUnreadCount();

    _safeNotify();

    unawaited(
      _resolveSenderName(
        latest.senderId,
      ),
    );

    debugPrint(
      '[GLOBAL CHAT] '
      '${incoming.length} nova(s) mensagem(ns). '
      'Não lidas: $_unreadCount.',
    );
  }

  // ==========================================================
  // CHAT VISIBILITY
  // ==========================================================

  void setChatVisible(
    bool visible, {
    String? projectId,
  }) {
    if (_disposed) {
      return;
    }

    final normalizedProjectId = _normalizeOptionalProjectId(
      projectId,
    );

    _chatVisible = visible;

    _visibleProjectId = visible
        ? normalizedProjectId ??
              this.projectId
        : null;

    if (visible) {
      final visibleId = _visibleProjectId;

      if (visibleId !=
          null) {
        _unreadByProject.remove(
          visibleId,
        );

        _recalculateUnreadCount();
      } else if (!isGlobalMode) {
        _unreadByProject.clear();

        _unreadCount = 0;
      }

      _bannerDismissed = true;
    }

    _safeNotify();
  }

  // ==========================================================
  // MARK ALL AS READ
  // ==========================================================

  void markAsRead() {
    if (_disposed) {
      return;
    }

    _unreadByProject.clear();

    _unreadCount = 0;

    _bannerDismissed = true;

    _safeNotify();
  }

  // ==========================================================
  // MARK PROJECT AS READ
  // ==========================================================

  void markProjectAsRead(
    String projectId,
  ) {
    if (_disposed) {
      return;
    }

    final normalizedProjectId = projectId.trim();

    if (normalizedProjectId.isEmpty) {
      return;
    }

    _unreadByProject.remove(
      normalizedProjectId,
    );

    _recalculateUnreadCount();

    final latestId = latestProjectId;

    if (latestId ==
        normalizedProjectId) {
      _bannerDismissed = true;
    }

    _safeNotify();
  }

  // ==========================================================
  // DISMISS BANNER
  // ==========================================================
  //
  // Diferente de markAsRead():
  //
  // - esconde o banner;
  // - mantém a contagem de não lidas.
  //
  // Assim o app pode futuramente mostrar um badge no menu.
  //
  // ==========================================================

  void dismissBanner() {
    if (_disposed) {
      return;
    }

    _bannerDismissed = true;

    _safeNotify();
  }

  // ==========================================================
  // SHOW BANNER AGAIN
  // ==========================================================

  void restoreBanner() {
    if (_disposed ||
        _unreadCount <=
            0) {
      return;
    }

    _bannerDismissed = false;

    _safeNotify();
  }

  // ==========================================================
  // CLEAR
  // ==========================================================

  void clear() {
    if (_disposed) {
      return;
    }

    _latestMessage = null;

    _latestSenderName = 'Membro';

    _unreadByProject.clear();

    _unreadCount = 0;

    _visibleProjectId = null;

    _bannerDismissed = false;

    _safeNotify();
  }

  // ==========================================================
  // RESOLVE SENDER
  // ==========================================================

  Future<
    void
  >
  _resolveSenderName(
    String userId,
  ) async {
    final normalizedUserId = userId.trim();

    if (normalizedUserId.isEmpty) {
      return;
    }

    // ========================================================
    // CACHE
    // ========================================================

    final cached = _senderNameCache[normalizedUserId];

    if (cached !=
        null) {
      if (_latestMessage?.senderId.trim() ==
          normalizedUserId) {
        _latestSenderName = cached;

        _safeNotify();
      }

      return;
    }

    // ========================================================
    // JÁ BUSCANDO
    // ========================================================

    if (_senderNameLoading.contains(
      normalizedUserId,
    )) {
      return;
    }

    _senderNameLoading.add(
      normalizedUserId,
    );

    try {
      final name = await _chatService.resolveSenderName(
        userId: normalizedUserId,
      );

      _senderNameCache[normalizedUserId] = name;

      if (_disposed) {
        return;
      }

      if (_latestMessage?.senderId.trim() ==
          normalizedUserId) {
        _latestSenderName = name;

        _safeNotify();
      }
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[GLOBAL CHAT] '
        'Erro ao resolver remetente '
        '$normalizedUserId: '
        '$error',
      );

      debugPrint(
        '[GLOBAL CHAT] '
        '$stackTrace',
      );

      _senderNameCache[normalizedUserId] = 'Membro';

      if (!_disposed &&
          _latestMessage?.senderId.trim() ==
              normalizedUserId) {
        _latestSenderName = 'Membro';

        _safeNotify();
      }
    } finally {
      _senderNameLoading.remove(
        normalizedUserId,
      );
    }
  }

  // ==========================================================
  // RECALCULATE UNREAD
  // ==========================================================

  void _recalculateUnreadCount() {
    var total = 0;

    for (final value in _unreadByProject.values) {
      total += value;
    }

    _unreadCount = total;
  }

  // ==========================================================
  // PREVIEW
  // ==========================================================

  String _compactPreview(
    String value,
  ) {
    final normalized = value
        .replaceAll(
          RegExp(
            r'\s+',
          ),
          ' ',
        )
        .trim();

    const maxLength = 90;

    if (normalized.length <=
        maxLength) {
      return normalized;
    }

    return '${normalized.substring(0, maxLength - 1)}…';
  }

  // ==========================================================
  // ERROR
  // ==========================================================

  void _handleRealtimeError(
    Object error,
    StackTrace stackTrace,
  ) {
    debugPrint(
      '[GLOBAL CHAT] '
      'Erro Realtime: '
      '$error',
    );

    debugPrint(
      '[GLOBAL CHAT] '
      '$stackTrace',
    );

    if (_disposed) {
      return;
    }

    _isLoading = false;

    _errorMessage = 'Não foi possível acompanhar novas mensagens.';

    _safeNotify();
  }

  // ==========================================================
  // SAFE NOTIFY
  // ==========================================================

  void _safeNotify() {
    if (_disposed ||
        !hasListeners) {
      return;
    }

    notifyListeners();
  }

  // ==========================================================
  // NORMALIZE OPTIONAL PROJECT ID
  // ==========================================================

  static String? _normalizeOptionalProjectId(
    String? value,
  ) {
    final normalized = value?.trim();

    if (normalized ==
            null ||
        normalized.isEmpty) {
      return null;
    }

    return normalized;
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    if (_disposed) {
      return;
    }

    _disposed = true;

    final subscription = _messagesSubscription;

    _messagesSubscription = null;

    if (subscription !=
        null) {
      unawaited(
        subscription.cancel(),
      );
    }

    _knownMessageIds.clear();

    _unreadByProject.clear();

    _visibleProjectId = null;

    _senderNameCache.clear();

    _senderNameLoading.clear();

    super.dispose();
  }
}
