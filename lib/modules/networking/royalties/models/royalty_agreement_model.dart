// ============================================================
// ROYALTY AGREEMENT STATUS
// ============================================================

enum RoyaltyAgreementStatus {
  draft,
  proposed,
  confirmed,
  superseded,
}

// ============================================================
// ROYALTY AGREEMENT MODEL
// ============================================================
//
// Representa uma versão de um acordo de royalties.
//
// Cada alteração relevante na divisão deve gerar uma nova
// versão.
//
// Estados:
//
// draft
//      ↓
// proposed
//      ↓
// confirmed
//
// Uma proposta antiga também pode se tornar:
//
// superseded
//
// IMPORTANTE:
//
// Um acordo confirmado representa um snapshot histórico e não
// deve ser alterado diretamente.
//
// ============================================================

class RoyaltyAgreementModel {
  final String id;

  final String projectId;

  final int version;

  final RoyaltyAgreementStatus status;

  final String createdBy;

  final String? integrityHash;

  final String? previousAgreementId;

  final DateTime createdAt;

  final DateTime? confirmedAt;

  const RoyaltyAgreementModel({
    required this.id,
    required this.projectId,
    required this.version,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    this.integrityHash,
    this.previousAgreementId,
    this.confirmedAt,
  });

  // ============================================================
  // FACTORY FROM MAP
  // ============================================================

  factory RoyaltyAgreementModel.fromMap(
    Map<
      String,
      dynamic
    >
    map,
  ) {
    return RoyaltyAgreementModel(
      id: _stringValue(
        map['id'],
      ),
      projectId: _stringValue(
        map['project_id'],
      ),
      version: _intValue(
        map['version'],
      ),
      status: _statusFromValue(
        map['status'],
      ),
      createdBy: _stringValue(
        map['created_by'],
      ),
      integrityHash: _nullableString(
        map['integrity_hash'],
      ),
      previousAgreementId: _nullableString(
        map['previous_agreement_id'],
      ),
      createdAt: _dateTimeValue(
        map['created_at'],
      ),
      confirmedAt: _nullableDateTime(
        map['confirmed_at'],
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
      'version': version,
      'status': status.databaseValue,
      'created_by': createdBy,
      'integrity_hash': integrityHash,
      'previous_agreement_id': previousAgreementId,
      'created_at': createdAt.toIso8601String(),
      'confirmed_at': confirmedAt?.toIso8601String(),
    };
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  RoyaltyAgreementModel copyWith({
    String? id,
    String? projectId,
    int? version,
    RoyaltyAgreementStatus? status,
    String? createdBy,
    String? integrityHash,
    bool clearIntegrityHash = false,
    String? previousAgreementId,
    bool clearPreviousAgreementId = false,
    DateTime? createdAt,
    DateTime? confirmedAt,
    bool clearConfirmedAt = false,
  }) {
    return RoyaltyAgreementModel(
      id:
          id ??
          this.id,
      projectId:
          projectId ??
          this.projectId,
      version:
          version ??
          this.version,
      status:
          status ??
          this.status,
      createdBy:
          createdBy ??
          this.createdBy,
      integrityHash: clearIntegrityHash
          ? null
          : integrityHash ??
                this.integrityHash,
      previousAgreementId: clearPreviousAgreementId
          ? null
          : previousAgreementId ??
                this.previousAgreementId,
      createdAt:
          createdAt ??
          this.createdAt,
      confirmedAt: clearConfirmedAt
          ? null
          : confirmedAt ??
                this.confirmedAt,
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  bool get isDraft {
    return status ==
        RoyaltyAgreementStatus.draft;
  }

  bool get isProposed {
    return status ==
        RoyaltyAgreementStatus.proposed;
  }

  bool get isConfirmed {
    return status ==
        RoyaltyAgreementStatus.confirmed;
  }

  bool get isSuperseded {
    return status ==
        RoyaltyAgreementStatus.superseded;
  }

  bool get isLocked {
    return isConfirmed;
  }

  bool get hasIntegrityHash {
    return integrityHash?.trim().isNotEmpty ==
        true;
  }

  // ============================================================
  // PARSERS
  // ============================================================

  static String _stringValue(
    dynamic value,
  ) {
    return value?.toString().trim() ??
        '';
  }

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

  static int _intValue(
    dynamic value,
  ) {
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
        ) ??
        0;
  }

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

  static DateTime? _nullableDateTime(
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

  static RoyaltyAgreementStatus _statusFromValue(
    dynamic value,
  ) {
    switch (value?.toString().trim().toLowerCase()) {
      case 'draft':
        return RoyaltyAgreementStatus.draft;

      case 'confirmed':
        return RoyaltyAgreementStatus.confirmed;

      case 'superseded':
        return RoyaltyAgreementStatus.superseded;

      case 'proposed':
      default:
        return RoyaltyAgreementStatus.proposed;
    }
  }
}

// ============================================================
// DATABASE VALUE
// ============================================================

extension RoyaltyAgreementStatusDatabaseValue
    on
        RoyaltyAgreementStatus {
  String get databaseValue {
    switch (this) {
      case RoyaltyAgreementStatus.draft:
        return 'draft';

      case RoyaltyAgreementStatus.proposed:
        return 'proposed';

      case RoyaltyAgreementStatus.confirmed:
        return 'confirmed';

      case RoyaltyAgreementStatus.superseded:
        return 'superseded';
    }
  }
}
