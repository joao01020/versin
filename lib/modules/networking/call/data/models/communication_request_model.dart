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
// → desbloquear permanentemente o vídeo no projeto.
//
// video_upgrade
// → durante uma chamada de áudio, solicitar mudança para vídeo.
//
// ============================================================

class CommunicationRequestModel {
  // ==========================================================
  // IDENTIFICAÇÃO
  // ==========================================================

  final String id;

  final String projectId;

  final String senderId;

  final String targetUserId;

  final String? callId;

  // ==========================================================
  // REQUEST
  // ==========================================================

  final CommunicationRequestType type;

  final CommunicationRequestStatus status;

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

      'type': type.value,

      'status': status.value,

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
    CommunicationRequestType? type,
    CommunicationRequestStatus? status,
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

      type:
          type ??
          this.type,

      status:
          status ??
          this.status,

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
  // EXPIRAÇÃO REAL
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
  // PODE RESPONDER?
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

  // ==========================================================
  // PRECISA DE CALL ID?
  // ==========================================================

  bool get requiresCall => type.requiresCall;

  // ==========================================================
  // ALTERA PERMISSÃO PERMANENTE?
  // ==========================================================

  bool get changesPersistentPermission => type.changesPersistentPermission;

  // ==========================================================
  // VALIDAR CALL ID
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
  // ENVOLVE USUÁRIO?
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
  // OUTRO USUÁRIO
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
  // É RECEBIDO?
  // ==========================================================

  bool isReceivedBy(
    String userId,
  ) {
    return wasSentTo(
      userId,
    );
  }

  // ==========================================================
  // É ENVIADO?
  // ==========================================================

  bool isSentBy(
    String userId,
  ) {
    return wasSentBy(
      userId,
    );
  }

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
        'type: ${type.value}, '
        'status: ${status.value}'
        ')';
  }
}
