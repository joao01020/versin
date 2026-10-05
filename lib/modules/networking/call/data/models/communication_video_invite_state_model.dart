// ============================================================
// COMMUNICATION VIDEO INVITE STATE MODEL
// ============================================================
//
// Representa o estado DIRECIONAL dos convites de vídeo.
//
// IMPORTANTE:
//
// A permissão de vídeo:
//
// João <-> Artista
//
// é bilateral.
//
// Porém o controle de convites:
//
// João -> Artista
//
// é direcional.
//
// Isso permite aplicar corretamente:
//
// 1ª recusa
// -> bloqueio por 2 dias
//
// 2ª recusa
// -> bloqueio por 4 dias
//
// 3ª recusa
// -> bloqueio até o destinatário permitir novo convite.
//
// ============================================================

class CommunicationVideoInviteStateModel {
  // ==========================================================
  // IDENTIFICAÇÃO
  // ==========================================================

  final String id;

  final String projectId;

  // ==========================================================
  // DIREÇÃO DO CONVITE
  // ==========================================================

  final String requesterId;

  final String targetUserId;

  // ==========================================================
  // RECUSAS
  // ==========================================================

  final int rejectionCount;

  // ==========================================================
  // COOLDOWN
  // ==========================================================

  final DateTime? cooldownUntil;

  // ==========================================================
  // BLOQUEIO
  // ==========================================================

  final bool blockedAfterLimit;

  // ==========================================================
  // HISTÓRICO
  // ==========================================================

  final DateTime? lastRequestAt;

  final DateTime? lastRejectedAt;

  // ==========================================================
  // REABERTURA
  // ==========================================================

  final DateTime? reopenedAt;

  final String? reopenedBy;

  // ==========================================================
  // AUDITORIA
  // ==========================================================

  final DateTime? createdAt;

  final DateTime? updatedAt;

  // ==========================================================
  // CONSTRUCTOR
  // ==========================================================

  const CommunicationVideoInviteStateModel({
    required this.id,
    required this.projectId,
    required this.requesterId,
    required this.targetUserId,
    this.rejectionCount = 0,
    this.cooldownUntil,
    this.blockedAfterLimit = false,
    this.lastRequestAt,
    this.lastRejectedAt,
    this.reopenedAt,
    this.reopenedBy,
    this.createdAt,
    this.updatedAt,
  });

  // ==========================================================
  // FROM MAP
  // ==========================================================

  factory CommunicationVideoInviteStateModel.fromMap(
    Map<
      String,
      dynamic
    >
    map,
  ) {
    return CommunicationVideoInviteStateModel(
      id: _readString(
        map['id'],
      ),
      projectId: _readString(
        map['project_id'],
      ),
      requesterId: _readString(
        map['requester_id'],
      ),
      targetUserId: _readString(
        map['target_user_id'],
      ),
      rejectionCount: _readInt(
        map['rejection_count'],
      ),
      cooldownUntil: _readDateTime(
        map['cooldown_until'],
      ),
      blockedAfterLimit: _readBool(
        map['blocked_after_limit'],
      ),
      lastRequestAt: _readDateTime(
        map['last_request_at'],
      ),
      lastRejectedAt: _readDateTime(
        map['last_rejected_at'],
      ),
      reopenedAt: _readDateTime(
        map['reopened_at'],
      ),
      reopenedBy: _readNullableString(
        map['reopened_by'],
      ),
      createdAt: _readDateTime(
        map['created_at'],
      ),
      updatedAt: _readDateTime(
        map['updated_at'],
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
      'requester_id': requesterId,
      'target_user_id': targetUserId,
      'rejection_count': rejectionCount,
      'cooldown_until': cooldownUntil?.toIso8601String(),
      'blocked_after_limit': blockedAfterLimit,
      'last_request_at': lastRequestAt?.toIso8601String(),
      'last_rejected_at': lastRejectedAt?.toIso8601String(),
      'reopened_at': reopenedAt?.toIso8601String(),
      'reopened_by': reopenedBy,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // ==========================================================
  // COPY WITH
  // ==========================================================

  CommunicationVideoInviteStateModel copyWith({
    String? id,
    String? projectId,
    String? requesterId,
    String? targetUserId,
    int? rejectionCount,
    DateTime? cooldownUntil,
    bool? blockedAfterLimit,
    DateTime? lastRequestAt,
    DateTime? lastRejectedAt,
    DateTime? reopenedAt,
    String? reopenedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CommunicationVideoInviteStateModel(
      id:
          id ??
          this.id,
      projectId:
          projectId ??
          this.projectId,
      requesterId:
          requesterId ??
          this.requesterId,
      targetUserId:
          targetUserId ??
          this.targetUserId,
      rejectionCount:
          rejectionCount ??
          this.rejectionCount,
      cooldownUntil:
          cooldownUntil ??
          this.cooldownUntil,
      blockedAfterLimit:
          blockedAfterLimit ??
          this.blockedAfterLimit,
      lastRequestAt:
          lastRequestAt ??
          this.lastRequestAt,
      lastRejectedAt:
          lastRejectedAt ??
          this.lastRejectedAt,
      reopenedAt:
          reopenedAt ??
          this.reopenedAt,
      reopenedBy:
          reopenedBy ??
          this.reopenedBy,
      createdAt:
          createdAt ??
          this.createdAt,
      updatedAt:
          updatedAt ??
          this.updatedAt,
    );
  }

  // ==========================================================
  // STATUS
  // ==========================================================

  bool get hasRejections =>
      rejectionCount >
      0;

  bool get hasReachedLimit =>
      rejectionCount >=
          3 ||
      blockedAfterLimit;

  // ==========================================================
  // COOLDOWN
  // ==========================================================

  bool get hasCooldown {
    final until = cooldownUntil;

    if (until ==
        null) {
      return false;
    }

    return DateTime.now().isBefore(
      until,
    );
  }

  bool get cooldownFinished {
    final until = cooldownUntil;

    if (until ==
        null) {
      return true;
    }

    return !DateTime.now().isBefore(
      until,
    );
  }

  Duration? get cooldownRemaining {
    final until = cooldownUntil;

    if (until ==
        null) {
      return null;
    }

    final now = DateTime.now();

    if (!now.isBefore(
      until,
    )) {
      return Duration.zero;
    }

    return until.difference(
      now,
    );
  }

  // ==========================================================
  // CAN REQUEST
  // ==========================================================

  bool get canRequestVideo {
    if (blockedAfterLimit) {
      return false;
    }

    if (hasCooldown) {
      return false;
    }

    return true;
  }

  // ==========================================================
  // NEXT ATTEMPT
  // ==========================================================

  int get nextAttempt {
    final attempt =
        rejectionCount +
        1;

    if (attempt >
        3) {
      return 3;
    }

    return attempt;
  }

  // ==========================================================
  // IS FIRST ATTEMPT
  // ==========================================================

  bool get isFirstAttempt =>
      rejectionCount ==
      0;

  // ==========================================================
  // IS SECOND ATTEMPT
  // ==========================================================

  bool get isSecondAttempt =>
      rejectionCount ==
      1;

  // ==========================================================
  // IS THIRD ATTEMPT
  // ==========================================================

  bool get isThirdAttempt =>
      rejectionCount ==
      2;

  // ==========================================================
  // REQUESTER
  // ==========================================================

  bool wasRequestedBy(
    String userId,
  ) {
    final normalized = userId.trim();

    if (normalized.isEmpty) {
      return false;
    }

    return requesterId ==
        normalized;
  }

  // ==========================================================
  // TARGET
  // ==========================================================

  bool targets(
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
  // RELATION
  // ==========================================================

  bool matchesDirection({
    required String requesterUserId,
    required String targetUserId,
  }) {
    final requester = requesterUserId.trim();

    final target = targetUserId.trim();

    if (requester.isEmpty ||
        target.isEmpty) {
      return false;
    }

    return requesterId ==
            requester &&
        this.targetUserId ==
            target;
  }

  // ==========================================================
  // REOPENED
  // ==========================================================

  bool get wasReopened =>
      reopenedAt !=
      null;

  bool wasReopenedBy(
    String userId,
  ) {
    final reopenedUserId = reopenedBy?.trim();

    final normalized = userId.trim();

    if (reopenedUserId ==
            null ||
        reopenedUserId.isEmpty ||
        normalized.isEmpty) {
      return false;
    }

    return reopenedUserId ==
        normalized;
  }

  // ==========================================================
  // STATUS LABEL
  // ==========================================================

  String get statusLabel {
    if (blockedAfterLimit) {
      return 'Bloqueado';
    }

    if (hasCooldown) {
      return 'Aguardando cooldown';
    }

    if (rejectionCount ==
        0) {
      return 'Disponível';
    }

    return 'Pode convidar novamente';
  }

  // ==========================================================
  // COOLDOWN LABEL
  // ==========================================================

  String get cooldownLabel {
    if (blockedAfterLimit) {
      return 'Convites bloqueados';
    }

    final remaining = cooldownRemaining;

    if (remaining ==
            null ||
        remaining ==
            Duration.zero) {
      return '';
    }

    final days = remaining.inDays;

    final hours =
        remaining.inHours %
        24;

    if (days >
        0) {
      if (hours >
          0) {
        return '${days}d ${hours}h';
      }

      return '${days}d';
    }

    final minutes =
        remaining.inMinutes %
        60;

    if (remaining.inHours >
        0) {
      return '${remaining.inHours}h ${minutes}min';
    }

    if (remaining.inMinutes >
        0) {
      return '${remaining.inMinutes}min';
    }

    return '< 1min';
  }

  // ==========================================================
  // IS VALID
  // ==========================================================

  bool get isValid {
    if (id.isEmpty ||
        projectId.isEmpty ||
        requesterId.isEmpty ||
        targetUserId.isEmpty) {
      return false;
    }

    if (requesterId ==
        targetUserId) {
      return false;
    }

    if (rejectionCount <
            0 ||
        rejectionCount >
            3) {
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

  static bool _readBool(
    dynamic value, {
    bool fallback = false,
  }) {
    if (value
        is bool) {
      return value;
    }

    if (value
        is num) {
      return value !=
          0;
    }

    if (value
        is String) {
      switch (value.trim().toLowerCase()) {
        case 'true':
        case '1':
          return true;

        case 'false':
        case '0':
          return false;
      }
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
      return value;
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }

  // ==========================================================
  // OBJECT
  // ==========================================================

  @override
  String toString() {
    return 'CommunicationVideoInviteStateModel('
        'projectId: $projectId, '
        'requesterId: $requesterId, '
        'targetUserId: $targetUserId, '
        'rejectionCount: $rejectionCount, '
        'blockedAfterLimit: $blockedAfterLimit, '
        'cooldownUntil: $cooldownUntil'
        ')';
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
            is CommunicationVideoInviteStateModel &&
        other.id ==
            id &&
        other.projectId ==
            projectId &&
        other.requesterId ==
            requesterId &&
        other.targetUserId ==
            targetUserId &&
        other.rejectionCount ==
            rejectionCount &&
        other.cooldownUntil ==
            cooldownUntil &&
        other.blockedAfterLimit ==
            blockedAfterLimit &&
        other.lastRequestAt ==
            lastRequestAt &&
        other.lastRejectedAt ==
            lastRejectedAt &&
        other.reopenedAt ==
            reopenedAt &&
        other.reopenedBy ==
            reopenedBy;
  }

  // ==========================================================
  // HASH CODE
  // ==========================================================

  @override
  int get hashCode => Object.hash(
    id,
    projectId,
    requesterId,
    targetUserId,
    rejectionCount,
    cooldownUntil,
    blockedAfterLimit,
    lastRequestAt,
    lastRejectedAt,
    reopenedAt,
    reopenedBy,
  );
}
