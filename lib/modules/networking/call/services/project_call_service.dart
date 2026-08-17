import '../data/models/project_call_model.dart';

import '../data/repositories/project_call_repository_impl.dart';

import '../repositories/project_call_repository.dart';

import '../types/call_media_type.dart';

// ============================================================
// PROJECT CALL SERVICE
// ============================================================
//
// Regras de negócio relacionadas ao ciclo de vida da chamada.
//
// Controller
//      ↓
// ProjectCallService
//      ↓
// ProjectCallRepository
//      ↓
// Supabase
//
// ============================================================

class ProjectCallService {
  // ==========================================================
  // REPOSITORY
  // ==========================================================

  final ProjectCallRepository _repository;

  // ==========================================================
  // CONSTRUCTOR
  // ==========================================================

  ProjectCallService({
    ProjectCallRepository? repository,
  }) : _repository =
           repository ??
           ProjectCallRepositoryImpl();

  // ==========================================================
  // CURRENT USER
  // ==========================================================

  String get currentUserId => _repository.currentUserId;

  // ==========================================================
  // GET CALL
  // ==========================================================

  Future<
    ProjectCallModel?
  >
  getCall({
    required String callId,
  }) {
    return _repository.getCallById(
      callId: _required(
        callId,
        'callId',
      ),
    );
  }

  // ==========================================================
  // PROJECT CALLS
  // ==========================================================

  Future<
    List<
      ProjectCallModel
    >
  >
  getProjectCalls({
    required String projectId,
  }) {
    return _repository.getProjectCalls(
      projectId: _required(
        projectId,
        'projectId',
      ),
    );
  }

  // ==========================================================
  // ACTIVE CALL
  // ==========================================================

  Future<
    ProjectCallModel?
  >
  getActiveCall({
    required String projectId,
  }) {
    return _repository.getActiveCall(
      projectId: _required(
        projectId,
        'projectId',
      ),
    );
  }

  // ==========================================================
  // STREAM PROJECT
  // ==========================================================

  Stream<
    List<
      ProjectCallModel
    >
  >
  streamProjectCalls({
    required String projectId,
  }) {
    return _repository.streamProjectCalls(
      projectId: _required(
        projectId,
        'projectId',
      ),
    );
  }

  // ==========================================================
  // STREAM CALL
  // ==========================================================

  Stream<
    ProjectCallModel?
  >
  streamCall({
    required String callId,
  }) {
    return _repository.streamCall(
      callId: _required(
        callId,
        'callId',
      ),
    );
  }

  // ==========================================================
  // START AUDIO
  // ==========================================================

  Future<
    ProjectCallModel
  >
  startAudioCall({
    required String projectId,
    String? targetUserId,
  }) {
    return startCall(
      projectId: projectId,

      mediaType: CallMediaType.audio,

      targetUserId: targetUserId,
    );
  }

  // ==========================================================
  // START VIDEO
  // ==========================================================

  Future<
    ProjectCallModel
  >
  startVideoCall({
    required String projectId,
    String? targetUserId,
  }) {
    return startCall(
      projectId: projectId,

      mediaType: CallMediaType.video,

      targetUserId: targetUserId,
    );
  }

  // ==========================================================
  // START
  // ==========================================================

  Future<
    ProjectCallModel
  >
  startCall({
    required String projectId,
    required CallMediaType mediaType,
    String? targetUserId,
  }) async {
    final normalizedProjectId = _required(
      projectId,
      'projectId',
    );

    final normalizedTarget = _nullable(
      targetUserId,
    );

    if (normalizedTarget ==
        currentUserId) {
      throw ArgumentError(
        'Não é possível ligar para si mesmo.',
      );
    }

    final existing = await _repository.getActiveCall(
      projectId: normalizedProjectId,
    );

    if (existing !=
            null &&
        !existing.isFinished) {
      throw StateError(
        'Já existe uma chamada ativa nesse projeto.',
      );
    }

    return _repository.createCall(
      projectId: normalizedProjectId,

      mediaType: mediaType,

      targetUserId: normalizedTarget,
    );
  }

  // ==========================================================
  // ACCEPT
  // ==========================================================

  Future<
    ProjectCallModel
  >
  acceptCall({
    required ProjectCallModel call,
  }) {
    if (!call.isValid) {
      throw ArgumentError(
        'Chamada inválida.',
      );
    }

    if (!call.canAccept) {
      throw StateError(
        'A chamada não pode mais ser aceita.',
      );
    }

    return _repository.acceptCall(
      callId: call.id,
    );
  }

  // ==========================================================
  // REJECT
  // ==========================================================

  Future<
    ProjectCallModel
  >
  rejectCall({
    required ProjectCallModel call,
  }) {
    if (!call.isValid) {
      throw ArgumentError(
        'Chamada inválida.',
      );
    }

    if (!call.canReject) {
      throw StateError(
        'A chamada não pode mais ser recusada.',
      );
    }

    return _repository.rejectCall(
      callId: call.id,
    );
  }

  // ==========================================================
  // END
  // ==========================================================

  Future<
    ProjectCallModel
  >
  endCall({
    required ProjectCallModel call,
  }) {
    if (!call.isValid) {
      throw ArgumentError(
        'Chamada inválida.',
      );
    }

    if (!call.canEnd) {
      throw StateError(
        'A chamada já foi finalizada.',
      );
    }

    return _repository.endCall(
      callId: call.id,
    );
  }

  // ==========================================================
  // IS INCOMING
  // ==========================================================

  bool isIncomingCall(
    ProjectCallModel call,
  ) {
    if (!call.isRinging) {
      return false;
    }

    return call.targets(
      currentUserId,
    );
  }

  // ==========================================================
  // IS OUTGOING
  // ==========================================================

  bool isOutgoingCall(
    ProjectCallModel call,
  ) {
    return call.wasCreatedBy(
      currentUserId,
    );
  }

  // ==========================================================
  // ACTIVE
  // ==========================================================

  Future<
    bool
  >
  hasActiveCall({
    required String projectId,
  }) {
    return _repository.hasActiveCall(
      projectId: _required(
        projectId,
        'projectId',
      ),
    );
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

  // ==========================================================
  // NULLABLE
  // ==========================================================

  String? _nullable(
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
}
