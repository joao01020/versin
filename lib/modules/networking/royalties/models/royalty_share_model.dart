// ============================================================
// ROYALTY SHARE MODEL
// ============================================================
//
// Representa a porcentagem atribuída a um participante dentro
// de uma versão específica do acordo.
//
// Exemplo:
//
// João
// Produtor
// 30%
//
// IMPORTANTE:
//
// roleSnapshot e displayNameSnapshot representam os valores no
// momento da criação do acordo.
//
// Assim, alterações futuras no perfil do usuário não modificam
// o significado histórico de um acordo já criado.
//
// ============================================================

class RoyaltyShareModel {
  final String id;

  final String agreementId;

  final String userId;

  final double percentage;

  final String? roleSnapshot;

  final String? displayNameSnapshot;

  final DateTime createdAt;

  const RoyaltyShareModel({
    required this.id,
    required this.agreementId,
    required this.userId,
    required this.percentage,
    required this.createdAt,
    this.roleSnapshot,
    this.displayNameSnapshot,
  });

  // ============================================================
  // FROM MAP
  // ============================================================

  factory RoyaltyShareModel.fromMap(
    Map<
      String,
      dynamic
    >
    map,
  ) {
    return RoyaltyShareModel(
      id: _stringValue(
        map['id'],
      ),
      agreementId: _stringValue(
        map['agreement_id'],
      ),
      userId: _stringValue(
        map['user_id'],
      ),
      percentage: _doubleValue(
        map['percentage'],
      ),
      roleSnapshot: _nullableString(
        map['role_snapshot'],
      ),
      displayNameSnapshot: _nullableString(
        map['display_name_snapshot'],
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
      'agreement_id': agreementId,
      'user_id': userId,
      'percentage': percentage,
      'role_snapshot': roleSnapshot,
      'display_name_snapshot': displayNameSnapshot,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // ============================================================
  // RPC MAP
  // ============================================================
  //
  // Formato esperado por:
  //
  // propose_royalty_distribution(...)
  //
  // ============================================================

  Map<
    String,
    dynamic
  >
  toProposalMap() {
    return {
      'user_id': userId,
      'percentage': percentage,
      'role_snapshot': roleSnapshot,
      'display_name_snapshot': displayNameSnapshot,
    };
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  RoyaltyShareModel copyWith({
    String? id,
    String? agreementId,
    String? userId,
    double? percentage,
    String? roleSnapshot,
    bool clearRoleSnapshot = false,
    String? displayNameSnapshot,
    bool clearDisplayNameSnapshot = false,
    DateTime? createdAt,
  }) {
    return RoyaltyShareModel(
      id:
          id ??
          this.id,
      agreementId:
          agreementId ??
          this.agreementId,
      userId:
          userId ??
          this.userId,
      percentage:
          percentage ??
          this.percentage,
      roleSnapshot: clearRoleSnapshot
          ? null
          : roleSnapshot ??
                this.roleSnapshot,
      displayNameSnapshot: clearDisplayNameSnapshot
          ? null
          : displayNameSnapshot ??
                this.displayNameSnapshot,
      createdAt:
          createdAt ??
          this.createdAt,
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  bool get hasValidPercentage {
    return percentage >=
            0 &&
        percentage <=
            100;
  }

  String get formattedPercentage {
    final hasDecimals =
        percentage !=
        percentage.roundToDouble();

    if (hasDecimals) {
      return '${percentage.toStringAsFixed(2)}%';
    }

    return '${percentage.toStringAsFixed(0)}%';
  }

  String get displayName {
    final value =
        displayNameSnapshot?.trim() ??
        '';

    if (value.isEmpty) {
      return 'Participante';
    }

    return value;
  }

  String get role {
    final value =
        roleSnapshot?.trim() ??
        '';

    if (value.isEmpty) {
      return 'Membro';
    }

    return value;
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

  static double _doubleValue(
    dynamic value,
  ) {
    if (value
        is double) {
      return value;
    }

    if (value
        is num) {
      return value.toDouble();
    }

    return double.tryParse(
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
}
