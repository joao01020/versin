// ============================================================
// ROYALTY EVENT TYPE
// ============================================================

enum RoyaltyEventType {
  agreementProposed,
  agreementApproved,
  agreementConfirmed,
  agreementSuperseded,
  unknown,
}

// ============================================================
// ROYALTY EVENT MODEL
// ============================================================
//
// Representa um evento histórico do acordo.
//
// Exemplos:
//
// agreement.proposed
// agreement.approved
// agreement.confirmed
//
// Os eventos permitem construir:
//
// - timeline;
// - auditoria;
// - histórico;
// - prova de sequência;
// - cadeia de integridade futuramente.
//
// ============================================================

class RoyaltyEventModel {
  final String id;

  final String projectId;

  final String? agreementId;

  final String? actorUserId;

  final RoyaltyEventType type;

  final String rawEventType;

  final Map<
    String,
    dynamic
  >
  payload;

  final String? payloadHash;

  final String? previousEventHash;

  final String? eventHash;

  final DateTime createdAt;

  const RoyaltyEventModel({
    required this.id,
    required this.projectId,
    required this.type,
    required this.rawEventType,
    required this.payload,
    required this.createdAt,
    this.agreementId,
    this.actorUserId,
    this.payloadHash,
    this.previousEventHash,
    this.eventHash,
  });

  // ============================================================
  // FROM MAP
  // ============================================================

  factory RoyaltyEventModel.fromMap(
    Map<
      String,
      dynamic
    >
    map,
  ) {
    final rawEventType = _stringValue(
      map['event_type'],
    );

    return RoyaltyEventModel(
      id: _stringValue(
        map['id'],
      ),
      projectId: _stringValue(
        map['project_id'],
      ),
      agreementId: _nullableString(
        map['agreement_id'],
      ),
      actorUserId: _nullableString(
        map['actor_user_id'],
      ),
      type: _eventTypeFromValue(
        rawEventType,
      ),
      rawEventType: rawEventType,
      payload: _mapValue(
        map['payload'],
      ),
      payloadHash: _nullableString(
        map['payload_hash'],
      ),
      previousEventHash: _nullableString(
        map['previous_event_hash'],
      ),
      eventHash: _nullableString(
        map['event_hash'],
      ),
      createdAt: _dateTimeValue(
        map['created_at'],
      ),
    );
  }

  // ============================================================
  // TO MAP
  // ============================================================

  Map<
    String,
    dynamic
  >
  toMap() {
    return {
      'id': id,
      'project_id': projectId,
      'agreement_id': agreementId,
      'actor_user_id': actorUserId,
      'event_type': rawEventType,
      'payload': payload,
      'payload_hash': payloadHash,
      'previous_event_hash': previousEventHash,
      'event_hash': eventHash,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  RoyaltyEventModel copyWith({
    String? id,
    String? projectId,
    String? agreementId,
    bool clearAgreementId = false,
    String? actorUserId,
    bool clearActorUserId = false,
    RoyaltyEventType? type,
    String? rawEventType,
    Map<
      String,
      dynamic
    >?
    payload,
    String? payloadHash,
    bool clearPayloadHash = false,
    String? previousEventHash,
    bool clearPreviousEventHash = false,
    String? eventHash,
    bool clearEventHash = false,
    DateTime? createdAt,
  }) {
    return RoyaltyEventModel(
      id:
          id ??
          this.id,
      projectId:
          projectId ??
          this.projectId,
      agreementId: clearAgreementId
          ? null
          : agreementId ??
                this.agreementId,
      actorUserId: clearActorUserId
          ? null
          : actorUserId ??
                this.actorUserId,
      type:
          type ??
          this.type,
      rawEventType:
          rawEventType ??
          this.rawEventType,
      payload:
          payload ==
              null
          ? Map<
              String,
              dynamic
            >.from(
              this.payload,
            )
          : Map<
              String,
              dynamic
            >.from(
              payload,
            ),
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
  // HELPERS
  // ============================================================

  bool get isProposal {
    return type ==
        RoyaltyEventType.agreementProposed;
  }

  bool get isApproval {
    return type ==
        RoyaltyEventType.agreementApproved;
  }

  bool get isConfirmation {
    return type ==
        RoyaltyEventType.agreementConfirmed;
  }

  bool get hasIntegrityChain {
    return eventHash?.trim().isNotEmpty ==
        true;
  }

  int? get agreementVersion {
    final value = payload['version'];

    if (value
        is int) {
      return value;
    }

    if (value
        is num) {
      return value.toInt();
    }

    return int.tryParse(
      value?.toString() ??
          '',
    );
  }

  // ============================================================
  // EVENT TYPE
  // ============================================================

  static RoyaltyEventType _eventTypeFromValue(
    String value,
  ) {
    switch (value.trim().toLowerCase()) {
      case 'agreement.proposed':
        return RoyaltyEventType.agreementProposed;

      case 'agreement.approved':
        return RoyaltyEventType.agreementApproved;

      case 'agreement.confirmed':
        return RoyaltyEventType.agreementConfirmed;

      case 'agreement.superseded':
        return RoyaltyEventType.agreementSuperseded;

      default:
        return RoyaltyEventType.unknown;
    }
  }

  // ============================================================
  // STRING
  // ============================================================

  static String _stringValue(
    dynamic value,
  ) {
    return value?.toString().trim() ??
        '';
  }

  // ============================================================
  // NULLABLE STRING
  // ============================================================

  static String? _nullableString(
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

  // ============================================================
  // MAP
  // ============================================================

  static Map<
    String,
    dynamic
  >
  _mapValue(
    dynamic value,
  ) {
    if (value
        is Map<
          String,
          dynamic
        >) {
      return Map<
        String,
        dynamic
      >.from(
        value,
      );
    }

    if (value
        is Map) {
      return Map<
        String,
        dynamic
      >.from(
        value,
      );
    }

    return {};
  }

  // ============================================================
  // DATETIME
  // ============================================================

  static DateTime _dateTimeValue(
    dynamic value,
  ) {
    if (value
        is DateTime) {
      return value;
    }

    return DateTime.tryParse(
          value?.toString() ??
              '',
        ) ??
        DateTime.fromMillisecondsSinceEpoch(
          0,
          isUtc: true,
        );
  }
}
