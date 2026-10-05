import '../models/royalty_agreement_model.dart';
import '../models/royalty_approval_model.dart';
import '../models/royalty_event_model.dart';
import '../models/royalty_member_model.dart';
import '../models/royalty_share_model.dart';

// ============================================================
// ROYALTIES REPOSITORY
// ============================================================
//
// Contrato principal do módulo de Royalties.
//
// LEITURA:
//
// Flutter
//   ↓
// Repository
//   ↓
// SELECT protegido por RLS
//
// ALTERAÇÕES:
//
// Flutter
//   ↓
// Repository
//   ↓
// RPC PostgreSQL
//   ↓
// autorização + transação + histórico
//
// O cliente NÃO altera diretamente:
//
// - royalty_agreements;
// - royalty_shares;
// - royalty_approvals;
// - royalty_events.
//
// ============================================================

abstract class RoyaltiesRepository {
  // ============================================================
  // PROJECT
  // ============================================================

  Future<
    bool
  >
  projectExists({
    required String projectId,
  });

  Future<
    bool
  >
  isProjectMember({
    required String projectId,
    required String userId,
  });

  // ============================================================
  // MEMBERS
  // ============================================================

  Future<
    List<
      RoyaltyMemberModel
    >
  >
  getProjectMembers({
    required String projectId,
  });

  // ============================================================
  // CURRENT AGREEMENT
  // ============================================================

  Future<
    RoyaltyAgreementModel?
  >
  getCurrentAgreement({
    required String projectId,
  });

  // ============================================================
  // AGREEMENTS
  // ============================================================

  Future<
    List<
      RoyaltyAgreementModel
    >
  >
  getAgreements({
    required String projectId,
  });

  // ============================================================
  // SHARES
  // ============================================================

  Future<
    List<
      RoyaltyShareModel
    >
  >
  getShares({
    required String agreementId,
  });

  // ============================================================
  // APPROVALS
  // ============================================================

  Future<
    List<
      RoyaltyApprovalModel
    >
  >
  getApprovals({
    required String agreementId,
  });

  // ============================================================
  // EVENTS
  // ============================================================

  Future<
    List<
      RoyaltyEventModel
    >
  >
  getEvents({
    required String projectId,
  });

  // ============================================================
  // HAS USER APPROVED
  // ============================================================

  Future<
    bool
  >
  hasUserApproved({
    required String agreementId,
    required String userId,
  });

  // ============================================================
  // PROPOSE DISTRIBUTION
  // ============================================================

  Future<
    String
  >
  proposeDistribution({
    required String projectId,
    required List<
      RoyaltyShareProposal
    >
    shares,
  });

  // ============================================================
  // APPROVE AGREEMENT
  // ============================================================
  //
  // A própria RPC:
  //
  // approve_royalty_agreement(...)
  //
  // registra a aprovação e, se este for o último participante:
  //
  // - confirma o acordo;
  // - calcula SHA-256;
  // - registra o evento final.
  //
  // ============================================================

  Future<
    RoyaltyApprovalResult
  >
  approveAgreement({
    required String agreementId,
  });

  // ============================================================
  // REALTIME
  // ============================================================

  Stream<
    List<
      RoyaltyAgreementModel
    >
  >
  watchAgreements({
    required String projectId,
  });

  Stream<
    List<
      RoyaltyShareModel
    >
  >
  watchShares({
    required String agreementId,
  });

  Stream<
    List<
      RoyaltyApprovalModel
    >
  >
  watchApprovals({
    required String agreementId,
  });

  Stream<
    List<
      RoyaltyEventModel
    >
  >
  watchEvents({
    required String projectId,
  });
}

// ============================================================
// ROYALTY SHARE PROPOSAL
// ============================================================
//
// DTO enviado para:
//
// propose_royalty_distribution(...)
//
// ============================================================

class RoyaltyShareProposal {
  final String userId;

  final double percentage;

  final String? roleSnapshot;

  final String? displayNameSnapshot;

  const RoyaltyShareProposal({
    required this.userId,
    required this.percentage,
    this.roleSnapshot,
    this.displayNameSnapshot,
  });

  // ============================================================
  // VALID
  // ============================================================

  bool get isValid {
    return userId.trim().isNotEmpty &&
        percentage >=
            0 &&
        percentage <=
            100;
  }

  // ============================================================
  // RPC MAP
  // ============================================================

  Map<
    String,
    dynamic
  >
  toRpcMap() {
    return {
      'user_id': userId.trim(),
      'percentage': percentage,
      'role_snapshot': _emptyToNull(
        roleSnapshot,
      ),
      'display_name_snapshot': _emptyToNull(
        displayNameSnapshot,
      ),
    };
  }

  // ============================================================
  // EMPTY TO NULL
  // ============================================================

  static String? _emptyToNull(
    String? value,
  ) {
    final normalized =
        value?.trim() ??
        '';

    if (normalized.isEmpty) {
      return null;
    }

    return normalized;
  }
}

// ============================================================
// ROYALTY APPROVAL RESULT
// ============================================================
//
// Resultado retornado pela RPC:
//
// approve_royalty_agreement(...)
//
// Exemplos:
//
// PRIMEIRA / INTERMEDIÁRIA:
//
// {
//   "agreement_id": "...",
//   "status": "proposed",
//   "approved_count": 2,
//   "required_count": 3,
//   "completed": false
// }
//
// ÚLTIMA:
//
// {
//   "agreement_id": "...",
//   "status": "confirmed",
//   "approved_count": 3,
//   "required_count": 3,
//   "completed": true,
//   "integrity_hash": "..."
// }
//
// ============================================================

class RoyaltyApprovalResult {
  final String agreementId;

  final String status;

  final int approvedCount;

  final int requiredCount;

  final bool completed;

  final bool alreadyConfirmed;

  final String? integrityHash;

  const RoyaltyApprovalResult({
    required this.agreementId,
    required this.status,
    required this.approvedCount,
    required this.requiredCount,
    required this.completed,
    this.alreadyConfirmed = false,
    this.integrityHash,
  });

  // ============================================================
  // FROM MAP
  // ============================================================

  factory RoyaltyApprovalResult.fromMap(
    Map<
      String,
      dynamic
    >
    map,
  ) {
    return RoyaltyApprovalResult(
      agreementId: _stringValue(
        map['agreement_id'],
      ),
      status: _stringValue(
        map['status'],
      ),
      approvedCount: _intValue(
        map['approved_count'],
      ),
      requiredCount: _intValue(
        map['required_count'],
      ),
      completed: _boolValue(
        map['completed'],
      ),
      alreadyConfirmed: _boolValue(
        map['already_confirmed'],
      ),
      integrityHash: _nullableString(
        map['integrity_hash'],
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  bool get isConfirmed {
    return status.trim().toLowerCase() ==
        'confirmed';
  }

  bool get isProposed {
    return status.trim().toLowerCase() ==
        'proposed';
  }

  bool get hasIntegrityHash {
    return integrityHash?.trim().isNotEmpty ==
        true;
  }

  bool get waitingForOthers {
    return !completed &&
        !alreadyConfirmed;
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
    final normalized =
        value?.toString().trim() ??
        '';

    if (normalized.isEmpty) {
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

  static bool _boolValue(
    dynamic value,
  ) {
    if (value
        is bool) {
      return value;
    }

    if (value
        is num) {
      return value !=
          0;
    }

    final normalized = value?.toString().trim().toLowerCase();

    return normalized ==
            'true' ||
        normalized ==
            '1';
  }
}
