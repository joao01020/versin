// ============================================================
// PROJECT RECORD EVENT TYPE
// ============================================================
//
// Eventos relevantes para a trilha da colaboração.
//
// Não precisamos registrar cada clique.
//
// Registramos acontecimentos que possuem significado para
// reconstruir a história do projeto.
//
// ============================================================

enum ProjectRecordEventType {
  contributionCreated,
  contributionUpdated,
  contributionProposed,
  contributionApproved,
  contributionLocked,
  contributionStarted,

  deliverySubmitted,
  deliveryApproved,
  deliveryRejected,
  deliveryValidated,

  deadlineProposed,
  deadlineApproved,

  memberJoined,
  memberLeft,

  projectFinalized,
}

// ============================================================
// PROJECT RECORD EVENT MODEL
// ============================================================
//
// Representa um acontecimento importante do projeto.
//
// Exemplo:
//
// Ana enviou:
// vocal_final.wav
//
// projectId:
// ...
//
// actorUserId:
// Ana
//
// eventType:
// deliverySubmitted
//
// entityType:
// delivery
//
// entityId:
// ...
//
// payloadHash:
// ...
//
// previousEventHash:
// ...
//
// eventHash:
// ...
//
// Dessa forma o Versin pode construir uma trilha cronológica
// de colaboração.
//
// ============================================================

class ProjectRecordEventModel {
  // ============================================================
  // IDENTIDADE
  // ============================================================

  final String id;

  final String projectId;

  // ============================================================
  // ACTOR
  // ============================================================

  final String? actorUserId;

  // ============================================================
  // EVENT
  // ============================================================

  final ProjectRecordEventType eventType;

  // ============================================================
  // ENTITY
  // ============================================================

  final String? entityType;

  final String? entityId;

  // ============================================================
  // PAYLOAD
  // ============================================================
  //
  // Snapshot mínimo necessário para descrever o acontecimento.
  //
  // Exemplo:
  //
  // {
  //   "file_name": "beat_master.wav",
  //   "version": 1,
  //   "sha256": "..."
  // }
  //
  // ============================================================

  final Map<
    String,
    dynamic
  >
  payload;

  // ============================================================
  // INTEGRITY
  // ============================================================

  final String? payloadHash;

  final String? previousEventHash;

  final String? eventHash;

  // ============================================================
  // TIMESTAMP
  // ============================================================

  final DateTime createdAt;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  const ProjectRecordEventModel({
    required this.id,
    required this.projectId,
    required this.eventType,
    required this.payload,
    required this.createdAt,
    this.actorUserId,
    this.entityType,
    this.entityId,
    this.payloadHash,
    this.previousEventHash,
    this.eventHash,
  });

  // ============================================================
  // HELPERS
  // ============================================================

  bool get hasActor {
    return actorUserId?.trim().isNotEmpty ==
        true;
  }

  bool get hasEntity {
    return entityType?.trim().isNotEmpty ==
            true &&
        entityId?.trim().isNotEmpty ==
            true;
  }

  bool get hasPayload {
    return payload.isNotEmpty;
  }

  bool get hasPayloadHash {
    return payloadHash?.trim().isNotEmpty ==
        true;
  }

  bool get hasPreviousEventHash {
    return previousEventHash?.trim().isNotEmpty ==
        true;
  }

  bool get hasEventHash {
    return eventHash?.trim().isNotEmpty ==
        true;
  }

  bool get hasIntegrityRecord {
    return hasPayloadHash &&
        hasEventHash;
  }

  // ============================================================
  // EVENT DATABASE VALUE
  // ============================================================

  String get eventDatabaseValue {
    switch (eventType) {
      case ProjectRecordEventType.contributionCreated:
        return 'contribution.created';

      case ProjectRecordEventType.contributionUpdated:
        return 'contribution.updated';

      case ProjectRecordEventType.contributionProposed:
        return 'contribution.proposed';

      case ProjectRecordEventType.contributionApproved:
        return 'contribution.approved';

      case ProjectRecordEventType.contributionLocked:
        return 'contribution.locked';

      case ProjectRecordEventType.contributionStarted:
        return 'contribution.started';

      case ProjectRecordEventType.deliverySubmitted:
        return 'delivery.submitted';

      case ProjectRecordEventType.deliveryApproved:
        return 'delivery.approved';

      case ProjectRecordEventType.deliveryRejected:
        return 'delivery.rejected';

      case ProjectRecordEventType.deliveryValidated:
        return 'delivery.validated';

      case ProjectRecordEventType.deadlineProposed:
        return 'deadline.proposed';

      case ProjectRecordEventType.deadlineApproved:
        return 'deadline.approved';

      case ProjectRecordEventType.memberJoined:
        return 'member.joined';

      case ProjectRecordEventType.memberLeft:
        return 'member.left';

      case ProjectRecordEventType.projectFinalized:
        return 'project.finalized';
    }
  }

  // ============================================================
  // EVENT FROM DATABASE
  // ============================================================

  static ProjectRecordEventType eventFromDatabase(
    String? value,
  ) {
    switch (value?.trim().toLowerCase()) {
      case 'contribution.updated':
        return ProjectRecordEventType.contributionUpdated;

      case 'contribution.proposed':
        return ProjectRecordEventType.contributionProposed;

      case 'contribution.approved':
        return ProjectRecordEventType.contributionApproved;

      case 'contribution.locked':
        return ProjectRecordEventType.contributionLocked;

      case 'contribution.started':
        return ProjectRecordEventType.contributionStarted;

      case 'delivery.submitted':
        return ProjectRecordEventType.deliverySubmitted;

      case 'delivery.approved':
        return ProjectRecordEventType.deliveryApproved;

      case 'delivery.rejected':
        return ProjectRecordEventType.deliveryRejected;

      case 'delivery.validated':
        return ProjectRecordEventType.deliveryValidated;

      case 'deadline.proposed':
        return ProjectRecordEventType.deadlineProposed;

      case 'deadline.approved':
        return ProjectRecordEventType.deadlineApproved;

      case 'member.joined':
        return ProjectRecordEventType.memberJoined;

      case 'member.left':
        return ProjectRecordEventType.memberLeft;

      case 'project.finalized':
        return ProjectRecordEventType.projectFinalized;

      case 'contribution.created':
      default:
        return ProjectRecordEventType.contributionCreated;
    }
  }

  // ============================================================
  // SHORT EVENT HASH
  // ============================================================

  String get shortEventHash {
    final hash =
        eventHash?.trim() ??
        '';

    if (hash.isEmpty) {
      return '';
    }

    if (hash.length <=
        16) {
      return hash;
    }

    return '${hash.substring(0, 8)}'
        '...'
        '${hash.substring(hash.length - 8)}';
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  ProjectRecordEventModel copyWith({
    String? id,
    String? projectId,
    String? actorUserId,
    ProjectRecordEventType? eventType,
    String? entityType,
    String? entityId,
    Map<
      String,
      dynamic
    >?
    payload,
    String? payloadHash,
    String? previousEventHash,
    String? eventHash,
    DateTime? createdAt,
    bool clearActorUserId = false,
    bool clearEntity = false,
    bool clearPayloadHash = false,
    bool clearPreviousEventHash = false,
    bool clearEventHash = false,
  }) {
    return ProjectRecordEventModel(
      id:
          id ??
          this.id,
      projectId:
          projectId ??
          this.projectId,
      actorUserId: clearActorUserId
          ? null
          : actorUserId ??
                this.actorUserId,
      eventType:
          eventType ??
          this.eventType,
      entityType: clearEntity
          ? null
          : entityType ??
                this.entityType,
      entityId: clearEntity
          ? null
          : entityId ??
                this.entityId,
      payload:
          payload ??
          this.payload,
      payloadHash: clearPayloadHash
          ? null
          : payloadHash ??
                this.payloadHash,
      previousEventHash: clearPreviousEventHash
          ? null
          : previousEventHash ??
                this.previousEventHash,
      eventHash: clearEventHash
          ? null
          : eventHash ??
                this.eventHash,
      createdAt:
          createdAt ??
          this.createdAt,
    );
  }

  // ============================================================
  // EQUALITY
  // ============================================================

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
            is ProjectRecordEventModel &&
        other.id ==
            id;
  }

  @override
  int get hashCode => id.hashCode;

  // ============================================================
  // TO STRING
  // ============================================================

  @override
  String toString() {
    return 'ProjectRecordEventModel('
        'id: $id, '
        'projectId: $projectId, '
        'eventType: $eventDatabaseValue, '
        'entityType: $entityType, '
        'entityId: $entityId'
        ')';
  }
}
