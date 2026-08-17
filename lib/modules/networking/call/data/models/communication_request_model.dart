import '../../types/communication_request_status.dart';
import '../../types/communication_request_type.dart';

// ============================================================
// COMMUNICATION REQUEST MODEL
// ============================================================
//
// Representa um pedido de consentimento entre usuários.
//
// Exemplos:
//
// video_unlock
// ------------------------------------------------------------
// Solicitação para liberar vídeo entre dois membros.
//
// video_upgrade
// ------------------------------------------------------------
// Durante uma chamada de áudio, solicita habilitação de vídeo.
//
// NOVO FLUXO:
//
// 1ª tentativa
// -> attemptNumber = 1
//
// recusou
// -> cooldown 2 dias
//
// 2ª tentativa
// -> attemptNumber = 2
//
// recusou
// -> cooldown 4 dias
//
// 3ª tentativa
// -> attemptNumber = 3
//
// recusou
// -> bloqueio até o target liberar nova tentativa.
//
// IMPORTANTE:
//
// O estado de cooldown/bloqueio NÃO fica neste model.
//
// Ele fica em:
//
// CommunicationVideoInviteStateModel
//
// ============================================================

class CommunicationRequestModel {
  // ==========================================================
  // IDENTIFICAÇÃO
  // ==========================================================

  final String id;

  final String projectId;

  // ==========================================================
  // USERS
  // ==========================================================

  final String senderId;

  final String targetUserId;

  // ==========================================================
  // CALL
  // ==========================================================

  final String? callId;

  // ==========================================================
  // VIDEO PERMISSION RELATION
  // ==========================================================
  //
  // Referência para:
  //
  // communication_video_permissions.id
  //
  // Dessa forma o request sabe exatamente qual relação
  // bilateral será liberada caso seja aceito.
  //
  // ==========================================================

  final String? videoPermissionId;

  // ==========================================================
  // REQUEST
  // ==========================================================

  final CommunicationRequestType type;

  final CommunicationRequestStatus status;

  // ==========================================================
  // TENTATIVA
  // ==========================================================

  final int attemptNumber;

  // ==========================================================
  // DATAS
  // ==========================================================

  final DateTime? createdAt;

  final DateTime? respondedAt;

  final DateTime? expiresAt;

  // ==========================================================
  // CONSTRUCTOR
  // ==========================================================

  const CommunicationRequestModel({
    required this.id,
    required this.projectId,
    required this.senderId,
    required this.targetUserId,
    required this.type,
    required this.status,
    this.callId,
    this.videoPermissionId,
    this.attemptNumber = 1,
    this.createdAt,
    this.respondedAt,
    this.expiresAt,
  });

  // ==========================================================
  // FROM MAP
  // ==========================================================

  factory CommunicationRequestModel.fromMap(
    Map<
      String,
      dynamic
    >
    map,
  ) {
    return CommunicationRequestModel(
      id: _readString(
        map['id'],
      ),

      projectId: _readString(
        map['project_id'],
      ),

      senderId: _readString(
        map['sender_id'],
      ),

      targetUserId: _readString(
        map['target_user_id'],
      ),

      callId: _readNullableString(
        map['call_id'],
      ),

      videoPermissionId: _readNullableString(
        map['video_permission_id'],
      ),

      type: CommunicationRequestType.fromString(
        _readString(
          map['type'],
        ),
      ),

      status: CommunicationRequestStatus.fromString(
        _readString(
          map['status'],
        ),
      ),

      attemptNumber: _readInt(
        map['attempt_number'],
        fallback: 1,
      ),

      createdAt: _readDateTime(
        map['created_at'],
      ),

      respondedAt: _readDateTime(
        map['responded_at'],
      ),

      expiresAt: _readDateTime(
        map['expires_at'],
      ),
    );
  }

  // ==========================================================
  // TO MAP
  // ==========================================================

  Map<
    String,
    dynamic
  >
  toMap() {
    return {
      'id': id,

      'project_id': projectId,

      'sender_id': senderId,

      'target_user_id': targetUserId,

      'call_id': callId,

      'video_permission_id': videoPermissionId,

      'type': type.value,

      'status': status.value,

      'attempt_number': attemptNumber,

      'created_at': createdAt?.toUtc().toIso8601String(),

      'responded_at': respondedAt?.toUtc().toIso8601String(),

      'expires_at': expiresAt?.toUtc().toIso8601String(),
    };
  }

  // ==========================================================
  // COPY WITH
  // ==========================================================

  CommunicationRequestModel copyWith({
    String? id,
    String? projectId,
    String? senderId,
    String? targetUserId,
    String? callId,
    String? videoPermissionId,
    CommunicationRequestType? type,
    CommunicationRequestStatus? status,
    int? attemptNumber,
    DateTime? createdAt,
    DateTime? respondedAt,
    DateTime? expiresAt,
  }) {
    return CommunicationRequestModel(
      id:
          id ??
          this.id,

      projectId:
          projectId ??
          this.projectId,

      senderId:
          senderId ??
          this.senderId,

      targetUserId:
          targetUserId ??
          this.targetUserId,

      callId:
          callId ??
          this.callId,

      videoPermissionId:
          videoPermissionId ??
          this.videoPermissionId,

      type:
          type ??
          this.type,

      status:
          status ??
          this.status,

      attemptNumber:
          attemptNumber ??
          this.attemptNumber,

      createdAt:
          createdAt ??
          this.createdAt,

      respondedAt:
          respondedAt ??
          this.respondedAt,

      expiresAt:
          expiresAt ??
          this.expiresAt,
    );
  }

  // ==========================================================
  // STATUS
  // ==========================================================

  bool get isPending => status.isPending;

  bool get isAccepted => status.isAccepted;

  bool get isRejected => status.isRejected;

  bool get isCancelled => status.isCancelled;

  bool get isExpiredStatus => status.isExpired;

  bool get isFinal => status.isFinal;

  // ==========================================================
  // EXPIRAÇÃO
  // ==========================================================

  bool get hasExpired {
    final expiration = expiresAt;

    if (expiration ==
        null) {
      return false;
    }

    return DateTime.now().isAfter(
      expiration,
    );
  }

  // ==========================================================
  // CAN RESPOND
  // ==========================================================

  bool get canRespond {
    if (!status.canRespond) {
      return false;
    }

    if (hasExpired) {
      return false;
    }

    return true;
  }

  // ==========================================================
  // TYPES
  // ==========================================================

  bool get isVideoUnlockRequest => type.isVideoUnlock;

  bool get isVideoUpgradeRequest => type.isVideoUpgrade;

  bool get isVideoRequest =>
      isVideoUnlockRequest ||
      isVideoUpgradeRequest;

  // ==========================================================
  // CALL REQUIREMENT
  // ==========================================================

  bool get requiresCall => type.requiresCall;

  // ==========================================================
  // PERSISTENT PERMISSION
  // ==========================================================

  bool get changesPersistentPermission => type.changesPersistentPermission;

  // ==========================================================
  // VALID CALL REFERENCE
  // ==========================================================

  bool get hasValidCallReference {
    if (!requiresCall) {
      return true;
    }

    final value = callId?.trim();

    return value !=
            null &&
        value.isNotEmpty;
  }

  // ==========================================================
  // VIDEO PERMISSION REFERENCE
  // ==========================================================

  bool get hasVideoPermissionReference {
    final value = videoPermissionId?.trim();

    return value !=
            null &&
        value.isNotEmpty;
  }

  // ==========================================================
  // ATTEMPT
  // ==========================================================

  bool get isFirstAttempt =>
      attemptNumber ==
      1;

  bool get isSecondAttempt =>
      attemptNumber ==
      2;

  bool get isThirdAttempt =>
      attemptNumber >=
      3;

  bool get isLastAutomaticAttempt => isThirdAttempt;

  int get remainingAttempts {
    final remaining =
        3 -
        attemptNumber;

    if (remaining <
        0) {
      return 0;
    }

    return remaining;
  }

  String get attemptLabel {
    if (attemptNumber <=
        1) {
      return '1ª tentativa';
    }

    if (attemptNumber ==
        2) {
      return '2ª tentativa';
    }

    return '3ª tentativa';
  }

  // ==========================================================
  // USER HELPERS
  // ==========================================================

  bool wasSentBy(
    String userId,
  ) {
    final normalized = userId.trim();

    if (normalized.isEmpty) {
      return false;
    }

    return senderId ==
        normalized;
  }

  bool wasSentTo(
    String userId,
  ) {
    final normalized = userId.trim();

    if (normalized.isEmpty) {
      return false;
    }

    return targetUserId ==
        normalized;
  }

  // ==========================================================
  // INVOLVES USER
  // ==========================================================

  bool involvesUser(
    String userId,
  ) {
    final normalized = userId.trim();

    if (normalized.isEmpty) {
      return false;
    }

    return senderId ==
            normalized ||
        targetUserId ==
            normalized;
  }

  // ==========================================================
  // OTHER USER
  // ==========================================================

  String? otherUserId(
    String currentUserId,
  ) {
    final normalized = currentUserId.trim();

    if (normalized.isEmpty) {
      return null;
    }

    if (senderId ==
        normalized) {
      return targetUserId;
    }

    if (targetUserId ==
        normalized) {
      return senderId;
    }

    return null;
  }

  // ==========================================================
  // RECEIVED
  // ==========================================================

  bool isReceivedBy(
    String userId,
  ) {
    return wasSentTo(
      userId,
    );
  }

  // ==========================================================
  // SENT
  // ==========================================================

  bool isSentBy(
    String userId,
  ) {
    return wasSentBy(
      userId,
    );
  }

  // ==========================================================
  // VALID ATTEMPT
  // ==========================================================

  bool get hasValidAttemptNumber =>
      attemptNumber >=
          1 &&
      attemptNumber <=
          3;

  // ==========================================================
  // VALID
  // ==========================================================

  bool get isValid {
    if (id.isEmpty) {
      return false;
    }

    if (projectId.isEmpty) {
      return false;
    }

    if (senderId.isEmpty) {
      return false;
    }

    if (targetUserId.isEmpty) {
      return false;
    }

    if (senderId ==
        targetUserId) {
      return false;
    }

    if (!hasValidCallReference) {
      return false;
    }

    if (!hasValidAttemptNumber) {
      return false;
    }

    return true;
  }

  // ==========================================================
  // PARSERS
  // ==========================================================

  static String _readString(
    dynamic value,
  ) {
    return value?.toString().trim() ??
        '';
  }

  static String? _readNullableString(
    dynamic value,
  ) {
    final normalized = value?.toString().trim();

    if (normalized ==
            null ||
        normalized.isEmpty) {
      return null;
    }

    return normalized;
  }

  static int _readInt(
    dynamic value, {
    int fallback = 0,
  }) {
    if (value
        is int) {
      return value;
    }

    if (value
        is num) {
      return value.toInt();
    }

    if (value
        is String) {
      return int.tryParse(
            value.trim(),
          ) ??
          fallback;
    }

    return fallback;
  }

  static DateTime? _readDateTime(
    dynamic value,
  ) {
    if (value ==
        null) {
      return null;
    }

    if (value
        is DateTime) {
      return value.toLocal();
    }

    final parsed = DateTime.tryParse(
      value.toString(),
    );

    return parsed?.toLocal();
  }

  // ==========================================================
  // EQUALITY
  // ==========================================================

  @override
  bool operator ==(
    Object other,
  ) {
    if (identical(
      this,
      other,
    )) {
      return true;
    }

    return other
            is CommunicationRequestModel &&
        other.id ==
            id;
  }

  // ==========================================================
  // HASH CODE
  // ==========================================================

  @override
  int get hashCode => id.hashCode;

  // ==========================================================
  // OBJECT
  // ==========================================================

  @override
  String toString() {
    return 'CommunicationRequestModel('
        'id: $id, '
        'projectId: $projectId, '
        'senderId: $senderId, '
        'targetUserId: $targetUserId, '
        'callId: $callId, '
        'videoPermissionId: $videoPermissionId, '
        'type: ${type.value}, '
        'status: ${status.value}, '
        'attemptNumber: $attemptNumber'
        ')';
  }
}
