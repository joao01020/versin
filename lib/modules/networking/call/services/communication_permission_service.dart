import '../data/models/communication_permission_model.dart';
import '../data/models/communication_request_model.dart';

import '../data/repositories/communication_permission_repository_impl.dart';

import '../repositories/communication_permission_repository.dart';

// ============================================================
// COMMUNICATION PERMISSION SERVICE
// ============================================================
//
// Camada de regra de negócio para:
//
// - áudio;
// - vídeo;
// - consentimento;
// - pedidos de desbloqueio.
//
// Controller
//     ↓
// Service
//     ↓
// Repository
//     ↓
// Supabase
//
// ============================================================

class CommunicationPermissionService {
  // ==========================================================
  // REPOSITORY
  // ==========================================================

  final CommunicationPermissionRepository _repository;

  // ==========================================================
  // CONSTRUCTOR
  // ==========================================================

  CommunicationPermissionService({
    CommunicationPermissionRepository? repository,
  }) : _repository =
           repository ??
           CommunicationPermissionRepositoryImpl();

  // ==========================================================
  // CURRENT USER
  // ==========================================================

  String get currentUserId => _repository.currentUserId;

  // ==========================================================
  // GET PERMISSION
  // ==========================================================

  Future<
    CommunicationPermissionModel?
  >
  getPermission({
    required String projectId,
    required String userId,
  }) {
    return _repository.getPermission(
      projectId: _required(
        projectId,
        'projectId',
      ),

      userId: _required(
        userId,
        'userId',
      ),
    );
  }

  // ==========================================================
  // CURRENT PERMISSION
  // ==========================================================

  Future<
    CommunicationPermissionModel?
  >
  getCurrentUserPermission({
    required String projectId,
  }) {
    return _repository.getCurrentUserPermission(
      projectId: _required(
        projectId,
        'projectId',
      ),
    );
  }

  // ==========================================================
  // PROJECT PERMISSIONS
  // ==========================================================

  Future<
    List<
      CommunicationPermissionModel
    >
  >
  getProjectPermissions({
    required String projectId,
  }) {
    return _repository.getProjectPermissions(
      projectId: _required(
        projectId,
        'projectId',
      ),
    );
  }

  // ==========================================================
  // STREAM PERMISSIONS
  // ==========================================================

  Stream<
    List<
      CommunicationPermissionModel
    >
  >
  streamProjectPermissions({
    required String projectId,
  }) {
    return _repository.streamProjectPermissions(
      projectId: _required(
        projectId,
        'projectId',
      ),
    );
  }

  // ==========================================================
  // CAN USE AUDIO
  // ==========================================================

  Future<
    bool
  >
  canUseAudio({
    required String projectId,
    String? userId,
  }) async {
    final targetUserId =
        userId?.trim().isNotEmpty ==
            true
        ? userId!.trim()
        : currentUserId;

    return _repository.isAudioAllowed(
      projectId: _required(
        projectId,
        'projectId',
      ),

      userId: targetUserId,
    );
  }

  // ==========================================================
  // CAN USE VIDEO
  // ==========================================================

  Future<
    bool
  >
  canUseVideo({
    required String projectId,
    String? userId,
  }) async {
    final targetUserId =
        userId?.trim().isNotEmpty ==
            true
        ? userId!.trim()
        : currentUserId;

    return _repository.isVideoAllowed(
      projectId: _required(
        projectId,
        'projectId',
      ),

      userId: targetUserId,
    );
  }

  // ==========================================================
  // REQUEST VIDEO
  // ==========================================================

  Future<
    CommunicationRequestModel
  >
  requestVideo({
    required String projectId,
    required String targetUserId,
  }) {
    final normalizedTarget = _required(
      targetUserId,
      'targetUserId',
    );

    if (normalizedTarget ==
        currentUserId) {
      throw ArgumentError(
        'Não é possível solicitar vídeo para si mesmo.',
      );
    }

    return _repository.requestVideo(
      projectId: _required(
        projectId,
        'projectId',
      ),

      targetUserId: normalizedTarget,
    );
  }

  // ==========================================================
  // ACCEPT
  // ==========================================================

  Future<
    CommunicationRequestModel
  >
  acceptRequest({
    required CommunicationRequestModel request,
  }) {
    _validateRequestForCurrentUser(
      request,
    );

    if (!request.canRespond) {
      throw StateError(
        'Essa solicitação não pode mais ser aceita.',
      );
    }

    return _repository.acceptVideoRequest(
      requestId: request.id,
    );
  }

  // ==========================================================
  // REJECT
  // ==========================================================

  Future<
    CommunicationRequestModel
  >
  rejectRequest({
    required CommunicationRequestModel request,
  }) {
    _validateRequestForCurrentUser(
      request,
    );

    if (!request.canRespond) {
      throw StateError(
        'Essa solicitação não pode mais ser recusada.',
      );
    }

    return _repository.rejectVideoRequest(
      requestId: request.id,
    );
  }

  // ==========================================================
  // RECEIVED REQUESTS
  // ==========================================================

  Future<
    List<
      CommunicationRequestModel
    >
  >
  getReceivedRequests({
    required String projectId,
  }) {
    return _repository.getReceivedRequests(
      projectId: _required(
        projectId,
        'projectId',
      ),
    );
  }

  // ==========================================================
  // STREAM REQUESTS
  // ==========================================================

  Stream<
    List<
      CommunicationRequestModel
    >
  >
  streamReceivedRequests({
    required String projectId,
  }) {
    return _repository.streamReceivedRequests(
      projectId: _required(
        projectId,
        'projectId',
      ),
    );
  }

  // ==========================================================
  // PENDING VIDEO REQUEST
  // ==========================================================

  Future<
    CommunicationRequestModel?
  >
  findPendingVideoRequest({
    required String projectId,
    required String senderId,
  }) async {
    final normalizedSender = _required(
      senderId,
      'senderId',
    );

    final requests = await getReceivedRequests(
      projectId: projectId,
    );

    for (final request in requests) {
      if (!request.canRespond) {
        continue;
      }

      if (!request.isVideoUnlockRequest &&
          !request.isVideoUpgradeRequest) {
        continue;
      }

      if (request.senderId ==
          normalizedSender) {
        return request;
      }
    }

    return null;
  }

  // ==========================================================
  // VALIDATE REQUEST
  // ==========================================================

  void _validateRequestForCurrentUser(
    CommunicationRequestModel request,
  ) {
    if (!request.isValid) {
      throw ArgumentError(
        'Solicitação de comunicação inválida.',
      );
    }

    if (!request.wasSentTo(
      currentUserId,
    )) {
      throw StateError(
        'A solicitação não pertence ao usuário autenticado.',
      );
    }
  }

  // ==========================================================
  // REQUIRED
  // ==========================================================

  String _required(
    String value,
    String field,
  ) {
    final normalized = value.trim();

    if (normalized.isEmpty) {
      throw ArgumentError(
        '$field não pode ser vazio.',
      );
    }

    return normalized;
  }
}
