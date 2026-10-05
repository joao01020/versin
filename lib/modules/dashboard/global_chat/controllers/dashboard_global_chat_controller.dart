import 'package:flutter/foundation.dart';

import 'package:versin/modules/networking/chat/controllers/global_chat_controller.dart';
import 'package:versin/modules/profile/services/profile_name_cache_service.dart';

// ============================================================
// DASHBOARD GLOBAL CHAT CONTROLLER
// ============================================================
//
// Camada de adaptação entre:
//
// GlobalChatController
//
// e
//
// Dashboard.
//
// Responsabilidades:
//
// - inicializar o GlobalChatController;
// - expor estado do banner global;
// - resolver nome do remetente;
// - marcar projeto como lido;
// - informar quando um chat está visível;
// - fechar/dismissar o banner.
//
// NÃO:
//
// - conhece BuildContext;
// - navega;
// - abre ChatView;
// - mostra SnackBar;
// - acessa Supabase diretamente.
//
// ============================================================

class DashboardGlobalChatController
    extends
        ChangeNotifier {
  // ============================================================
  // GLOBAL CHAT
  // ============================================================

  final GlobalChatController globalChatController;

  // ============================================================
  // PROFILE NAME CACHE
  // ============================================================

  final ProfileNameCacheService profileNameCacheService;

  // ============================================================
  // STATE
  // ============================================================

  bool _initialized = false;

  bool _disposed = false;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  DashboardGlobalChatController({
    GlobalChatController? globalChatController,

    ProfileNameCacheService? profileNameCacheService,
  }) : globalChatController =
           globalChatController ??
           GlobalChatController(),
       profileNameCacheService =
           profileNameCacheService ??
           ProfileNameCacheService();

  // ============================================================
  // INITIALIZED
  // ============================================================

  bool get initialized {
    return _initialized;
  }

  // ============================================================
  // HAS NOTIFICATION
  // ============================================================

  bool get hasNotification {
    return globalChatController.hasNotification;
  }

  // ============================================================
  // PROJECT ID
  // ============================================================

  String? get latestProjectId {
    final value = globalChatController.latestProjectId?.trim();

    if (value ==
            null ||
        value.isEmpty) {
      return null;
    }

    return value;
  }

  // ============================================================
  // HAS PROJECT
  // ============================================================

  bool get hasProject {
    final projectId = latestProjectId;

    return projectId !=
            null &&
        projectId.isNotEmpty;
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  dynamic get latestMessage {
    return globalChatController.latestMessage;
  }

  // ============================================================
  // HAS MESSAGE
  // ============================================================

  bool get hasMessage {
    return latestMessage !=
        null;
  }

  // ============================================================
  // AUDIO
  // ============================================================

  bool get latestIsAudio {
    return globalChatController.latestIsAudio;
  }

  // ============================================================
  // PREVIEW
  // ============================================================

  String get preview {
    return globalChatController.preview;
  }

  // ============================================================
  // UNREAD COUNT
  // ============================================================

  int get unreadCount {
    return globalChatController.unreadCount;
  }

  // ============================================================
  // FALLBACK SENDER NAME
  // ============================================================

  String get senderName {
    final value = globalChatController.senderName.trim();

    if (value.isNotEmpty) {
      return value;
    }

    return 'Membro';
  }

  // ============================================================
  // SENDER ID
  // ============================================================

  String get senderId {
    final message = latestMessage;

    if (message ==
        null) {
      return '';
    }

    try {
      final value = message.senderId.toString().trim();

      return value;
    } catch (
      _
    ) {
      return '';
    }
  }

  // ============================================================
  // INITIALIZE
  // ============================================================

  void init() {
    if (_initialized ||
        _disposed) {
      return;
    }

    _initialized = true;

    globalChatController.addListener(
      _handleGlobalChatChanged,
    );

    globalChatController.init();

    debugPrint(
      '[DASHBOARD GLOBAL CHAT] '
      'Controller inicializado.',
    );
  }

  // ============================================================
  // GLOBAL CHAT CHANGED
  // ============================================================

  void _handleGlobalChatChanged() {
    if (_disposed) {
      return;
    }

    notifyListeners();
  }

  // ============================================================
  // RESOLVE SENDER NAME
  // ============================================================

  Future<
    String
  >
  resolveSenderName() async {
    final normalizedUserId = senderId.trim();

    // ==========================================================
    // SEM ID
    // ==========================================================

    if (normalizedUserId.isEmpty) {
      return senderName;
    }

    // ==========================================================
    // CACHE
    // ==========================================================

    try {
      final resolvedName = await profileNameCacheService.getName(
        normalizedUserId,
      );

      final normalizedName = resolvedName.trim();

      if (normalizedName.isNotEmpty &&
          normalizedName !=
              'Membro') {
        return normalizedName;
      }
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[DASHBOARD GLOBAL CHAT] '
        'Erro ao resolver nome do remetente: '
        '$error',
      );

      debugPrint(
        '$stackTrace',
      );
    }

    // ==========================================================
    // FALLBACK DO GLOBAL CONTROLLER
    // ==========================================================

    final fallback = globalChatController.senderName.trim();

    if (fallback.isNotEmpty &&
        fallback !=
            'Membro') {
      return fallback;
    }

    return 'Membro';
  }

  // ============================================================
  // MARK PROJECT AS READ
  // ============================================================

  void markProjectAsRead(
    String projectId,
  ) {
    final normalizedProjectId = projectId.trim();

    if (normalizedProjectId.isEmpty) {
      return;
    }

    globalChatController.markProjectAsRead(
      normalizedProjectId,
    );
  }

  // ============================================================
  // CHAT VISIBLE
  // ============================================================

  void setChatVisible(
    bool visible, {
    String? projectId,
  }) {
    final normalizedProjectId = projectId?.trim();

    if (visible &&
        normalizedProjectId !=
            null &&
        normalizedProjectId.isNotEmpty) {
      globalChatController.setChatVisible(
        true,
        projectId: normalizedProjectId,
      );

      return;
    }

    globalChatController.setChatVisible(
      false,
    );
  }

  // ============================================================
  // PREPARE OPEN
  // ============================================================
  //
  // Executado antes de navegar para ChatView.
  //
  // Preserva o comportamento antigo:
  //
  // - marca somente aquele projeto como lido;
  // - informa que o chat daquele projeto está visível.
  //
  // ============================================================

  bool prepareOpen(
    String projectId,
  ) {
    final normalizedProjectId = projectId.trim();

    if (normalizedProjectId.isEmpty) {
      return false;
    }

    markProjectAsRead(
      normalizedProjectId,
    );

    setChatVisible(
      true,
      projectId: normalizedProjectId,
    );

    return true;
  }

  // ============================================================
  // FINISH OPEN
  // ============================================================
  //
  // Deve ser chamado no finally depois que ChatView fechar.
  //
  // ============================================================

  void finishOpen() {
    setChatVisible(
      false,
    );
  }

  // ============================================================
  // DISMISS BANNER
  // ============================================================

  void dismissBanner() {
    globalChatController.dismissBanner();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    if (_disposed) {
      return;
    }

    _disposed = true;

    globalChatController.removeListener(
      _handleGlobalChatChanged,
    );

    globalChatController.dispose();

    super.dispose();
  }
}
