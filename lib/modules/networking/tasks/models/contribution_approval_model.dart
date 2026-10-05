// ============================================================
// CONTRIBUTION APPROVAL MODEL
// ============================================================
//
// Representa a confirmação de UM participante sobre UMA versão
// específica de uma contribuição.
//
// Exemplo:
//
// contribuição:
//
// Ana
// "Composição + vocais"
// versão 2
//
// aprovações:
//
// João  ✓
// Lucas ✓
// Ana   ✓
//
// IMPORTANTE:
//
// Não usamos:
//
// approvals = 3
//
// como fonte de verdade.
//
// Cada aprovação é um registro individual.
//
// Isso permite saber:
//
// - quem aprovou;
// - quando aprovou;
// - qual versão aprovou;
// - impedir aprovação duplicada.
//
// ============================================================

class ContributionApprovalModel {
  // ============================================================
  // IDENTIDADE
  // ============================================================

  final String id;

  // ============================================================
  // CONTRIBUTION
  // ============================================================

  final String contributionId;

  // ============================================================
  // USER
  // ============================================================

  final String userId;

  // ============================================================
  // VERSION
  // ============================================================
  //
  // Muito importante.
  //
  // Se João aprovou:
  //
  // versão 1
  //
  // e Ana alterar a contribuição:
  //
  // versão 2
  //
  // a aprovação anterior NÃO vale para a versão nova.
  //
  // ============================================================

  final int contributionVersion;

  // ============================================================
  // TIMESTAMP
  // ============================================================

  final DateTime approvedAt;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  const ContributionApprovalModel({
    required this.id,
    required this.contributionId,
    required this.userId,
    required this.contributionVersion,
    required this.approvedAt,
  });

  // ============================================================
  // VALIDATION HELPERS
  // ============================================================

  bool get hasValidId {
    return id.trim().isNotEmpty;
  }

  bool get hasValidContributionId {
    return contributionId.trim().isNotEmpty;
  }

  bool get hasValidUserId {
    return userId.trim().isNotEmpty;
  }

  bool get hasValidVersion {
    return contributionVersion >
        0;
  }

  bool get isValid {
    return hasValidId &&
        hasValidContributionId &&
        hasValidUserId &&
        hasValidVersion;
  }

  // ============================================================
  // MATCH VERSION
  // ============================================================

  bool belongsToVersion(
    int version,
  ) {
    return contributionVersion ==
        version;
  }

  // ============================================================
  // APPROVED BY
  // ============================================================

  bool wasApprovedBy(
    String userId,
  ) {
    final normalizedUserId = userId.trim();

    if (normalizedUserId.isEmpty) {
      return false;
    }

    return this.userId ==
        normalizedUserId;
  }

  // ============================================================
  // APPROVES
  // ============================================================
  //
  // Helper útil para verificar contribuição + versão + usuário
  // em uma única operação.
  //
  // ============================================================

  bool approves({
    required String contributionId,
    required String userId,
    required int version,
  }) {
    return this.contributionId ==
            contributionId.trim() &&
        this.userId ==
            userId.trim() &&
        contributionVersion ==
            version;
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  ContributionApprovalModel copyWith({
    String? id,
    String? contributionId,
    String? userId,
    int? contributionVersion,
    DateTime? approvedAt,
  }) {
    return ContributionApprovalModel(
      id:
          id ??
          this.id,
      contributionId:
          contributionId ??
          this.contributionId,
      userId:
          userId ??
          this.userId,
      contributionVersion:
          contributionVersion ??
          this.contributionVersion,
      approvedAt:
          approvedAt ??
          this.approvedAt,
    );
  }

  // ============================================================
  // EQUALITY
  // ============================================================
  //
  // Um usuário só pode possuir uma aprovação para cada:
  //
  // contribuição + versão.
  //
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
            is ContributionApprovalModel &&
        other.contributionId ==
            contributionId &&
        other.userId ==
            userId &&
        other.contributionVersion ==
            contributionVersion;
  }

  @override
  int get hashCode {
    return Object.hash(
      contributionId,
      userId,
      contributionVersion,
    );
  }

  // ============================================================
  // TO STRING
  // ============================================================

  @override
  String toString() {
    return 'ContributionApprovalModel('
        'id: $id, '
        'contributionId: $contributionId, '
        'userId: $userId, '
        'version: $contributionVersion, '
        'approvedAt: $approvedAt'
        ')';
  }
}
