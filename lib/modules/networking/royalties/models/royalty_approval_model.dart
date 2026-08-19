// ============================================================
// ROYALTY APPROVAL MODEL
// ============================================================
//
// Representa a aprovação individual de um participante.
//
// Uma aprovação pertence SEMPRE a uma versão específica do
// acordo.
//
// Portanto:
//
// usuário aprova v1
//
// não significa:
//
// usuário aprovou v2.
//
// ============================================================

class RoyaltyApprovalModel {
  final String id;

  final String agreementId;

  final String userId;

  final DateTime approvedAt;

  const RoyaltyApprovalModel({
    required this.id,
    required this.agreementId,
    required this.userId,
    required this.approvedAt,
  });

  // ============================================================
  // FROM MAP
  // ============================================================

  factory RoyaltyApprovalModel.fromMap(
    Map<
      String,
      dynamic
    >
    map,
  ) {
    return RoyaltyApprovalModel(
      id: _stringValue(
        map['id'],
      ),
      agreementId: _stringValue(
        map['agreement_id'],
      ),
      userId: _stringValue(
        map['user_id'],
      ),
      approvedAt: _dateTimeValue(
        map['approved_at'],
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
      'agreement_id': agreementId,
      'user_id': userId,
      'approved_at': approvedAt.toIso8601String(),
    };
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  RoyaltyApprovalModel copyWith({
    String? id,
    String? agreementId,
    String? userId,
    DateTime? approvedAt,
  }) {
    return RoyaltyApprovalModel(
      id:
          id ??
          this.id,
      agreementId:
          agreementId ??
          this.agreementId,
      userId:
          userId ??
          this.userId,
      approvedAt:
          approvedAt ??
          this.approvedAt,
    );
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
