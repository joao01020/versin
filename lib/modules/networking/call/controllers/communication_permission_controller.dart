import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/models/communication_permission_model.dart';
import '../data/models/communication_request_model.dart';

import '../data/repositories/communication_permission_repository_impl.dart';

import '../repositories/communication_permission_repository.dart';

// ============================================================
// COMMUNICATION PERMISSION CONTROLLER
// ============================================================
//
// Responsável pelo estado de:
//
// - permissões de áudio;
// - permissões de vídeo;
// - pedidos de desbloqueio de vídeo;
// - aceite / rejeição;
// - sincronização Realtime.
//
// Fluxo:
//
// UI
//  ↓
// CommunicationPermissionController
//  ↓
// CommunicationPermissionRepository
//  ↓
// Supabase
//
// IMPORTANTE:
//
// O Controller NÃO conhece:
// - tabelas;
// - SQL;
// - RPC;
// - RLS.
//
// Essas responsabilidades ficam no repository.
//
// ============================================================

class CommunicationPermissionController
    with
        ChangeNotifier {
  // ==========================================================
  // PROJECT
  // ==========================================================

  final String projectId;

  // ==========================================================
  // REPOSITORY
  // ==========================================================

  final CommunicationPermissionRepository _repository;

  // ==========================================================
  // SUBSCRIPTIONS
  // ==========================================================

  StreamSubscription<
    List<
      CommunicationPermissionModel
    >
  >?
  _permissionsSubscription;

  StreamSubscription<
    List<
      CommunicationRequestModel
    >
  >?
  _requestsSubscription;

  // ==========================================================
  // STATE
  // ==========================================================

  List<
    CommunicationPermissionModel
  >
  _permissions =
      const <
        CommunicationPermissionModel
      >[];

  List<
    CommunicationRequestModel
  >
  _receivedRequests =
      const <
        CommunicationRequestModel
      >[];

  bool _isLoading = false;

  bool _isProcessing = false;

  bool _disposed = false;

  String? _errorMessage;

  // ==========================================================
  // CONSTRUCTOR
  // ==========================================================

  CommunicationPermissionController({
    required String projectId,
    CommunicationPermissionRepository? repository,
  }) : projectId = _requiredProjectId(
         projectId,
       ),
       _repository =
           repository ??
           CommunicationPermissionRepositoryImpl();

  // ==========================================================
  // GETTERS
  // ==========================================================

  List<
    CommunicationPermissionModel
  >
  get permissions => _permissions;

  List<
    CommunicationRequestModel
  >
  get receivedRequests => _receivedRequests;

  bool get isLoading => _isLoading;

  bool get isProcessing => _isProcessing;

  bool get hasError =>
      _errorMessage !=
      null;

  String? get errorMessage => _errorMessage;

  bool get hasPendingRequests => pendingRequests.isNotEmpty;

  // ==========================================================
  // CURRENT USER
  // ==========================================================

  String get currentUserId => _repository.currentUserId;

  // ==========================================================
  // PENDING REQUESTS
  // ==========================================================

  List<
    CommunicationRequestModel
  >
  get pendingRequests {
    final result = _receivedRequests
        .where(
          (
            request,
          ) => request.canRespond,
        )
        .toList(
          growable: false,
        );

    return result;
  }

  // ==========================================================
  // INIT
  // ==========================================================

  Future<
    void
  >
  init() async {
    if (_disposed) {
      return;
    }

    _isLoading = true;

    _errorMessage = null;

    _safeNotify();

    try {
      await _stopSubscriptions();

      // ======================================================
      // PERMISSIONS REALTIME
      // ======================================================

      _permissionsSubscription = _repository
          .streamProjectPermissions(
            projectId: projectId,
          )
          .listen(
            _handlePermissions,

            onError: _handlePermissionsError,
          );

      // ======================================================
      // REQUESTS REALTIME
      // ======================================================

      _requestsSubscription = _repository
          .streamReceivedRequests(
            projectId: projectId,
          )
          .listen(
            _handleRequests,

            onError: _handleRequestsError,
          );

      // ======================================================
      // INITIAL LOAD
      // ======================================================

      final initialPermissions = await _repository.getProjectPermissions(
        projectId: projectId,
      );

      final initialRequests = await _repository.getReceivedRequests(
        projectId: projectId,
      );

      if (_disposed) {
        return;
      }

      _permissions =
          List<
            CommunicationPermissionModel
          >.unmodifiable(
            initialPermissions,
          );

      _receivedRequests =
          List<
            CommunicationRequestModel
          >.unmodifiable(
            initialRequests,
          );

      _isLoading = false;

      _errorMessage = null;

      _safeNotify();
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[COMMUNICATION PERMISSION CONTROLLER] '
        'Erro no init: '
        '$error',
      );

      debugPrint(
        '[COMMUNICATION PERMISSION CONTROLLER] '
        'StackTrace: '
        '$stackTrace',
      );

      if (_disposed) {
        return;
      }

      _isLoading = false;

      _errorMessage = 'Não foi possível carregar as permissões de comunicação.';

      _safeNotify();
    }
  }

  // ==========================================================
  // HANDLE PERMISSIONS
  // ==========================================================

  void _handlePermissions(
    List<
      CommunicationPermissionModel
    >
    permissions,
  ) {
    if (_disposed) {
      return;
    }

    _permissions =
        List<
          CommunicationPermissionModel
        >.unmodifiable(
          permissions,
        );

    _isLoading = false;

    _safeNotify();
  }

  // ==========================================================
  // HANDLE REQUESTS
  // ==========================================================

  void _handleRequests(
    List<
      CommunicationRequestModel
    >
    requests,
  ) {
    if (_disposed) {
      return;
    }

    _receivedRequests =
        List<
          CommunicationRequestModel
        >.unmodifiable(
          requests,
        );

    _safeNotify();
  }

  // ==========================================================
  // STREAM ERROR
  // ==========================================================

  void _handlePermissionsError(
    Object error,
    StackTrace stackTrace,
  ) {
    debugPrint(
      '[COMMUNICATION PERMISSION CONTROLLER] '
      'Erro Realtime permissions: '
      '$error',
    );

    debugPrint(
      '$stackTrace',
    );

    if (_disposed) {
      return;
    }

    _errorMessage = 'Erro ao atualizar permissões.';

    _safeNotify();
  }

  void _handleRequestsError(
    Object error,
    StackTrace stackTrace,
  ) {
    debugPrint(
      '[COMMUNICATION PERMISSION CONTROLLER] '
      'Erro Realtime requests: '
      '$error',
    );

    debugPrint(
      '$stackTrace',
    );

    if (_disposed) {
      return;
    }

    _errorMessage = 'Erro ao atualizar solicitações.';

    _safeNotify();
  }

  // ==========================================================
  // PERMISSION BY USER
  // ==========================================================

  CommunicationPermissionModel? permissionForUser(
    String userId,
  ) {
    final normalized = userId.trim();

    if (normalized.isEmpty) {
      return null;
    }

    for (final permission in _permissions) {
      if (permission.userId ==
          normalized) {
        return permission;
      }
    }

    return null;
  }

  // ==========================================================
  // CURRENT USER PERMISSION
  // ==========================================================

  CommunicationPermissionModel? get currentUserPermission {
    return permissionForUser(
      currentUserId,
    );
  }

  // ==========================================================
  // AUDIO
  // ==========================================================

  bool isAudioAllowedFor(
    String userId,
  ) {
    final permission = permissionForUser(
      userId,
    );

    return permission?.audioAllowed ??
        false;
  }

  bool get currentUserAudioAllowed =>
      currentUserPermission?.audioAllowed ??
      false;

  // ==========================================================
  // VIDEO
  // ==========================================================

  bool isVideoAllowedFor(
    String userId,
  ) {
    final permission = permissionForUser(
      userId,
    );

    return permission?.videoAllowed ??
        false;
  }

  bool get currentUserVideoAllowed =>
      currentUserPermission?.videoAllowed ??
      false;

  // ==========================================================
  // REQUEST VIDEO
  // ==========================================================

  Future<
    CommunicationRequestModel?
  >
  requestVideo({
    required String targetUserId,
  }) async {
    if (_disposed ||
        _isProcessing) {
      return null;
    }

    final normalizedTarget = targetUserId.trim();

    if (normalizedTarget.isEmpty) {
      _setError(
        'Usuário inválido.',
      );

      return null;
    }

    if (normalizedTarget ==
        currentUserId) {
      _setError(
        'Você não pode solicitar vídeo para si mesmo.',
      );

      return null;
    }

    _isProcessing = true;

    _errorMessage = null;

    _safeNotify();

    try {
      final request = await _repository.requestVideo(
        projectId: projectId,

        targetUserId: normalizedTarget,
      );

      return request;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[COMMUNICATION PERMISSION CONTROLLER] '
        'Erro ao solicitar vídeo: '
        '$error',
      );

      debugPrint(
        '$stackTrace',
      );

      _errorMessage = 'Não foi possível enviar o convite de vídeo.';

      return null;
    } finally {
      if (!_disposed) {
        _isProcessing = false;

        _safeNotify();
      }
    }
  }

  // ==========================================================
  // ACCEPT REQUEST
  // ==========================================================

  Future<
    bool
  >
  acceptRequest(
    CommunicationRequestModel request,
  ) async {
    if (_disposed ||
        _isProcessing) {
      return false;
    }

    if (!request.canRespond) {
      _setError(
        'Essa solicitação não pode mais ser respondida.',
      );

      return false;
    }

    if (!request.wasSentTo(
      currentUserId,
    )) {
      _setError(
        'Essa solicitação não pertence ao usuário atual.',
      );

      return false;
    }

    _isProcessing = true;

    _errorMessage = null;

    _safeNotify();

    try {
      await _repository.acceptVideoRequest(
        requestId: request.id,
      );

      await refresh();

      return true;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[COMMUNICATION PERMISSION CONTROLLER] '
        'Erro ao aceitar solicitação: '
        '$error',
      );

      debugPrint(
        '$stackTrace',
      );

      _errorMessage = 'Não foi possível aceitar a solicitação.';

      return false;
    } finally {
      if (!_disposed) {
        _isProcessing = false;

        _safeNotify();
      }
    }
  }

  // ==========================================================
  // REJECT REQUEST
  // ==========================================================

  Future<
    bool
  >
  rejectRequest(
    CommunicationRequestModel request,
  ) async {
    if (_disposed ||
        _isProcessing) {
      return false;
    }

    if (!request.canRespond) {
      _setError(
        'Essa solicitação não pode mais ser respondida.',
      );

      return false;
    }

    if (!request.wasSentTo(
      currentUserId,
    )) {
      _setError(
        'Essa solicitação não pertence ao usuário atual.',
      );

      return false;
    }

    _isProcessing = true;

    _errorMessage = null;

    _safeNotify();

    try {
      await _repository.rejectVideoRequest(
        requestId: request.id,
      );

      await refresh();

      return true;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[COMMUNICATION PERMISSION CONTROLLER] '
        'Erro ao recusar solicitação: '
        '$error',
      );

      debugPrint(
        '$stackTrace',
      );

      _errorMessage = 'Não foi possível recusar a solicitação.';

      return false;
    } finally {
      if (!_disposed) {
        _isProcessing = false;

        _safeNotify();
      }
    }
  }

  // ==========================================================
  // REQUEST BY USER
  // ==========================================================

  CommunicationRequestModel? pendingRequestFrom(
    String senderId,
  ) {
    final normalized = senderId.trim();

    if (normalized.isEmpty) {
      return null;
    }

    for (final request in pendingRequests) {
      if (request.senderId ==
          normalized) {
        return request;
      }
    }

    return null;
  }

  // ==========================================================
  // REFRESH
  // ==========================================================

  Future<
    void
  >
  refresh() async {
    if (_disposed) {
      return;
    }

    try {
      final permissions = await _repository.getProjectPermissions(
        projectId: projectId,
      );

      final requests = await _repository.getReceivedRequests(
        projectId: projectId,
      );

      if (_disposed) {
        return;
      }

      _permissions =
          List<
            CommunicationPermissionModel
          >.unmodifiable(
            permissions,
          );

      _receivedRequests =
          List<
            CommunicationRequestModel
          >.unmodifiable(
            requests,
          );

      _errorMessage = null;

      _safeNotify();
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[COMMUNICATION PERMISSION CONTROLLER] '
        'Erro no refresh: '
        '$error',
      );

      debugPrint(
        '$stackTrace',
      );

      _setError(
        'Não foi possível atualizar as permissões.',
      );
    }
  }

  // ==========================================================
  // CLEAR ERROR
  // ==========================================================

  void clearError() {
    if (_disposed ||
        _errorMessage ==
            null) {
      return;
    }

    _errorMessage = null;

    _safeNotify();
  }

  // ==========================================================
  // SET ERROR
  // ==========================================================

  void _setError(
    String message,
  ) {
    if (_disposed) {
      return;
    }

    _errorMessage = message;

    _safeNotify();
  }

  // ==========================================================
  // STOP SUBSCRIPTIONS
  // ==========================================================

  Future<
    void
  >
  _stopSubscriptions() async {
    await _permissionsSubscription?.cancel();

    await _requestsSubscription?.cancel();

    _permissionsSubscription = null;

    _requestsSubscription = null;
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
  // PROJECT ID
  // ==========================================================

  static String _requiredProjectId(
    String value,
  ) {
    final normalized = value.trim();

    if (normalized.isEmpty) {
      throw ArgumentError(
        'projectId não pode ser vazio.',
      );
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

    unawaited(
      _stopSubscriptions(),
    );

    super.dispose();
  }
}
