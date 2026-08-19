import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/royalty_agreement_model.dart';
import '../../models/royalty_approval_model.dart';
import '../../models/royalty_event_model.dart';
import '../../models/royalty_member_model.dart';
import '../../models/royalty_share_model.dart';
import '../../repositories/royalties_repository.dart';

// ============================================================
// PROFESSIONAL ROLE RESOLVER
// ============================================================
//
// Resolve a função/habilidade profissional usada pelo Match.
//
// O módulo de Royalties não deve inventar uma segunda fonte.
//
// ============================================================

typedef RoyaltyProfessionalRoleResolver =
    Future<
      String?
    >
    Function(
      String userId,
    );

// ============================================================
// ROYALTIES REPOSITORY IMPLEMENTATION
// ============================================================
//
// LEITURA:
//
// SELECT protegido por RLS.
//
// ALTERAÇÃO:
//
// RPC PostgreSQL.
//
// Não fazemos:
//
// .insert()
// .update()
// .delete()
//
// diretamente nas tabelas de royalties.
//
// ============================================================

class RoyaltiesRepositoryImpl
    implements
        RoyaltiesRepository {
  // ============================================================
  // TABLES
  // ============================================================

  static const String _projectsTable = 'projects';

  static const String _profilesTable = 'profiles';

  static const String _agreementsTable = 'royalty_agreements';

  static const String _sharesTable = 'royalty_shares';

  static const String _approvalsTable = 'royalty_approvals';

  static const String _eventsTable = 'royalty_events';

  // ============================================================
  // RPC
  // ============================================================

  static const String _proposeRpc = 'propose_royalty_distribution';

  static const String _approveRpc = 'approve_royalty_agreement';

  // ============================================================
  // DEPENDENCIES
  // ============================================================

  final SupabaseClient _supabase;

  final RoyaltyProfessionalRoleResolver _professionalRoleResolver;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  RoyaltiesRepositoryImpl({
    SupabaseClient? supabase,
    required RoyaltyProfessionalRoleResolver professionalRoleResolver,
  }) : _supabase =
           supabase ??
           Supabase.instance.client,
       _professionalRoleResolver = professionalRoleResolver;

  // ============================================================
  // PROJECT EXISTS
  // ============================================================

  @override
  Future<
    bool
  >
  projectExists({
    required String projectId,
  }) async {
    final normalizedProjectId = _require(
      projectId,
      fieldName: 'projectId',
    );

    final row = await _supabase
        .from(
          _projectsTable,
        )
        .select(
          'id',
        )
        .eq(
          'id',
          normalizedProjectId,
        )
        .maybeSingle();

    return row !=
        null;
  }

  // ============================================================
  // IS PROJECT MEMBER
  // ============================================================

  @override
  Future<
    bool
  >
  isProjectMember({
    required String projectId,
    required String userId,
  }) async {
    final normalizedProjectId = _require(
      projectId,
      fieldName: 'projectId',
    );

    final normalizedUserId = _require(
      userId,
      fieldName: 'userId',
    );

    final row = await _supabase
        .from(
          _projectsTable,
        )
        .select(
          'members',
        )
        .eq(
          'id',
          normalizedProjectId,
        )
        .maybeSingle();

    if (row ==
        null) {
      return false;
    }

    return _readStringArray(
      row['members'],
    ).contains(
      normalizedUserId,
    );
  }

  // ============================================================
  // PROJECT MEMBERS
  // ============================================================

  @override
  Future<
    List<
      RoyaltyMemberModel
    >
  >
  getProjectMembers({
    required String projectId,
  }) async {
    final normalizedProjectId = _require(
      projectId,
      fieldName: 'projectId',
    );

    // ==========================================================
    // PROJECT
    // ==========================================================

    final project = await _supabase
        .from(
          _projectsTable,
        )
        .select(
          'id, members, founders',
        )
        .eq(
          'id',
          normalizedProjectId,
        )
        .maybeSingle();

    if (project ==
        null) {
      return const <
        RoyaltyMemberModel
      >[];
    }

    final memberIds = _readStringArray(
      project['members'],
    );

    if (memberIds.isEmpty) {
      return const <
        RoyaltyMemberModel
      >[];
    }

    final founderIds = _readStringArray(
      project['founders'],
    ).toSet();

    // ==========================================================
    // PROFILES
    // ==========================================================

    final response = await _supabase
        .from(
          _profilesTable,
        )
        .select(
          'id, artist_name, name, username, avatar_url',
        )
        .inFilter(
          'id',
          memberIds,
        );

    final rows = _rows(
      response,
    );

    final profileById =
        <
          String,
          Map<
            String,
            dynamic
          >
        >{};

    for (final row in rows) {
      final id = _nullableString(
        row['id'],
      );

      if (id ==
          null) {
        continue;
      }

      profileById[id] = row;
    }

    // ==========================================================
    // BUILD MEMBERS
    // ==========================================================

    final result =
        <
          RoyaltyMemberModel
        >[];

    for (final userId in memberIds) {
      final profile = profileById[userId];

      final role = await _resolveProfessionalRole(
        userId,
      );

      result.add(
        RoyaltyMemberModel(
          userId: userId,
          displayName: _resolveDisplayName(
            profile,
          ),
          username: _nullableString(
            profile?['username'],
          ),
          avatarUrl: _nullableString(
            profile?['avatar_url'],
          ),
          role: role,
          isFounder: founderIds.contains(
            userId,
          ),
        ),
      );
    }

    // ==========================================================
    // ORDER
    // ==========================================================

    result.sort(
      (
        a,
        b,
      ) {
        if (a.isFounder !=
            b.isFounder) {
          return a.isFounder
              ? -1
              : 1;
        }

        return a.displayName.toLowerCase().compareTo(
          b.displayName.toLowerCase(),
        );
      },
    );

    return result;
  }

  // ============================================================
  // CURRENT AGREEMENT
  // ============================================================

  @override
  Future<
    RoyaltyAgreementModel?
  >
  getCurrentAgreement({
    required String projectId,
  }) async {
    final agreements = await getAgreements(
      projectId: projectId,
    );

    if (agreements.isEmpty) {
      return null;
    }

    // ==========================================================
    // PROPOSED FIRST
    // ==========================================================

    for (final agreement in agreements) {
      if (agreement.isProposed) {
        return agreement;
      }
    }

    // ==========================================================
    // CONFIRMED
    // ==========================================================

    for (final agreement in agreements) {
      if (agreement.isConfirmed) {
        return agreement;
      }
    }

    // ==========================================================
    // DRAFT
    // ==========================================================

    for (final agreement in agreements) {
      if (agreement.isDraft) {
        return agreement;
      }
    }

    return agreements.first;
  }

  // ============================================================
  // AGREEMENTS
  // ============================================================

  @override
  Future<
    List<
      RoyaltyAgreementModel
    >
  >
  getAgreements({
    required String projectId,
  }) async {
    final normalizedProjectId = _require(
      projectId,
      fieldName: 'projectId',
    );

    final response = await _supabase
        .from(
          _agreementsTable,
        )
        .select()
        .eq(
          'project_id',
          normalizedProjectId,
        )
        .order(
          'version',
          ascending: false,
        );

    return _rows(
          response,
        )
        .map(
          RoyaltyAgreementModel.fromMap,
        )
        .toList();
  }

  // ============================================================
  // SHARES
  // ============================================================

  @override
  Future<
    List<
      RoyaltyShareModel
    >
  >
  getShares({
    required String agreementId,
  }) async {
    final normalizedAgreementId = _require(
      agreementId,
      fieldName: 'agreementId',
    );

    final response = await _supabase
        .from(
          _sharesTable,
        )
        .select()
        .eq(
          'agreement_id',
          normalizedAgreementId,
        )
        .order(
          'created_at',
          ascending: true,
        );

    return _rows(
          response,
        )
        .map(
          RoyaltyShareModel.fromMap,
        )
        .toList();
  }

  // ============================================================
  // APPROVALS
  // ============================================================

  @override
  Future<
    List<
      RoyaltyApprovalModel
    >
  >
  getApprovals({
    required String agreementId,
  }) async {
    final normalizedAgreementId = _require(
      agreementId,
      fieldName: 'agreementId',
    );

    final response = await _supabase
        .from(
          _approvalsTable,
        )
        .select()
        .eq(
          'agreement_id',
          normalizedAgreementId,
        )
        .order(
          'approved_at',
          ascending: true,
        );

    return _rows(
          response,
        )
        .map(
          RoyaltyApprovalModel.fromMap,
        )
        .toList();
  }

  // ============================================================
  // EVENTS
  // ============================================================

  @override
  Future<
    List<
      RoyaltyEventModel
    >
  >
  getEvents({
    required String projectId,
  }) async {
    final normalizedProjectId = _require(
      projectId,
      fieldName: 'projectId',
    );

    final response = await _supabase
        .from(
          _eventsTable,
        )
        .select()
        .eq(
          'project_id',
          normalizedProjectId,
        )
        .order(
          'created_at',
          ascending: false,
        );

    return _rows(
          response,
        )
        .map(
          RoyaltyEventModel.fromMap,
        )
        .toList();
  }

  // ============================================================
  // HAS USER APPROVED
  // ============================================================

  @override
  Future<
    bool
  >
  hasUserApproved({
    required String agreementId,
    required String userId,
  }) async {
    final normalizedAgreementId = _require(
      agreementId,
      fieldName: 'agreementId',
    );

    final normalizedUserId = _require(
      userId,
      fieldName: 'userId',
    );

    final row = await _supabase
        .from(
          _approvalsTable,
        )
        .select(
          'id',
        )
        .eq(
          'agreement_id',
          normalizedAgreementId,
        )
        .eq(
          'user_id',
          normalizedUserId,
        )
        .maybeSingle();

    return row !=
        null;
  }

  // ============================================================
  // PROPOSE DISTRIBUTION
  // ============================================================

  @override
  Future<
    String
  >
  proposeDistribution({
    required String projectId,
    required List<
      RoyaltyShareProposal
    >
    shares,
  }) async {
    final normalizedProjectId = _require(
      projectId,
      fieldName: 'projectId',
    );

    if (shares.isEmpty) {
      throw ArgumentError(
        'A proposta precisa possuir participantes.',
      );
    }

    // ==========================================================
    // VALIDATE SHARES
    // ==========================================================

    for (final share in shares) {
      if (!share.isValid) {
        throw ArgumentError(
          'Existe uma participação inválida.',
        );
      }
    }

    // ==========================================================
    // TOTAL
    // ==========================================================

    final total =
        shares.fold<
          double
        >(
          0,
          (
            value,
            share,
          ) {
            return value +
                share.percentage;
          },
        );

    if ((total -
                100)
            .abs() >
        0.0001) {
      throw ArgumentError(
        'A divisão precisa totalizar exatamente 100%.',
      );
    }

    // ==========================================================
    // DUPLICATE USERS
    // ==========================================================

    final uniqueUsers = shares.map(
      (
        share,
      ) {
        return share.userId.trim();
      },
    ).toSet();

    if (uniqueUsers.length !=
        shares.length) {
      throw ArgumentError(
        'Um participante aparece mais de uma vez na divisão.',
      );
    }

    debugPrint(
      '[ROYALTIES] '
      'Criando proposta para projeto: '
      '$normalizedProjectId',
    );

    // ==========================================================
    // RPC
    // ==========================================================

    final response = await _supabase.rpc(
      _proposeRpc,
      params: {
        'p_project_id': normalizedProjectId,
        'p_shares': shares.map(
          (
            share,
          ) {
            return share.toRpcMap();
          },
        ).toList(),
      },
    );

    final agreementId =
        response?.toString().trim() ??
        '';

    if (agreementId.isEmpty) {
      throw StateError(
        'A RPC não retornou o ID do acordo criado.',
      );
    }

    debugPrint(
      '[ROYALTIES] '
      'Proposta criada: '
      '$agreementId',
    );

    return agreementId;
  }

  // ============================================================
  // APPROVE AGREEMENT
  // ============================================================
  //
  // IMPORTANTE:
  //
  // A RPC pode:
  //
  // - apenas registrar o voto;
  //
  // OU
  //
  // - registrar o último voto;
  // - confirmar o acordo;
  // - calcular SHA-256;
  // - registrar o evento final.
  //
  // ============================================================

  @override
  Future<
    RoyaltyApprovalResult
  >
  approveAgreement({
    required String agreementId,
  }) async {
    final normalizedAgreementId = _require(
      agreementId,
      fieldName: 'agreementId',
    );

    debugPrint(
      '[ROYALTIES] '
      'Aprovando acordo: '
      '$normalizedAgreementId',
    );

    final response = await _supabase.rpc(
      _approveRpc,
      params: {
        'p_agreement_id': normalizedAgreementId,
      },
    );

    // ==========================================================
    // MAP
    // ==========================================================

    if (response
        is Map) {
      final result = RoyaltyApprovalResult.fromMap(
        Map<
          String,
          dynamic
        >.from(
          response,
        ),
      );

      _logApprovalResult(
        result,
      );

      return result;
    }

    // ==========================================================
    // ITERABLE
    // ==========================================================
    //
    // Normalmente jsonb volta como Map.
    //
    // Mantemos fallback para não quebrar caso o PostgREST
    // entregue uma coleção em algum cenário.
    //
    // ==========================================================

    if (response
        is Iterable) {
      final rows = _rows(
        response,
      );

      if (rows.isNotEmpty) {
        final result = RoyaltyApprovalResult.fromMap(
          rows.first,
        );

        _logApprovalResult(
          result,
        );

        return result;
      }
    }

    throw StateError(
      'A RPC de aprovação retornou uma resposta inválida.',
    );
  }

  // ============================================================
  // WATCH AGREEMENTS
  // ============================================================

  @override
  Stream<
    List<
      RoyaltyAgreementModel
    >
  >
  watchAgreements({
    required String projectId,
  }) {
    final normalizedProjectId = _require(
      projectId,
      fieldName: 'projectId',
    );

    return _supabase
        .from(
          _agreementsTable,
        )
        .stream(
          primaryKey: const [
            'id',
          ],
        )
        .eq(
          'project_id',
          normalizedProjectId,
        )
        .order(
          'version',
          ascending: false,
        )
        .map(
          (
            rows,
          ) {
            return rows.map(
              (
                row,
              ) {
                return RoyaltyAgreementModel.fromMap(
                  Map<
                    String,
                    dynamic
                  >.from(
                    row,
                  ),
                );
              },
            ).toList();
          },
        );
  }

  // ============================================================
  // WATCH SHARES
  // ============================================================

  @override
  Stream<
    List<
      RoyaltyShareModel
    >
  >
  watchShares({
    required String agreementId,
  }) {
    final normalizedAgreementId = _require(
      agreementId,
      fieldName: 'agreementId',
    );

    return _supabase
        .from(
          _sharesTable,
        )
        .stream(
          primaryKey: const [
            'id',
          ],
        )
        .eq(
          'agreement_id',
          normalizedAgreementId,
        )
        .order(
          'created_at',
          ascending: true,
        )
        .map(
          (
            rows,
          ) {
            return rows.map(
              (
                row,
              ) {
                return RoyaltyShareModel.fromMap(
                  Map<
                    String,
                    dynamic
                  >.from(
                    row,
                  ),
                );
              },
            ).toList();
          },
        );
  }

  // ============================================================
  // WATCH APPROVALS
  // ============================================================

  @override
  Stream<
    List<
      RoyaltyApprovalModel
    >
  >
  watchApprovals({
    required String agreementId,
  }) {
    final normalizedAgreementId = _require(
      agreementId,
      fieldName: 'agreementId',
    );

    return _supabase
        .from(
          _approvalsTable,
        )
        .stream(
          primaryKey: const [
            'id',
          ],
        )
        .eq(
          'agreement_id',
          normalizedAgreementId,
        )
        .order(
          'approved_at',
          ascending: true,
        )
        .map(
          (
            rows,
          ) {
            return rows.map(
              (
                row,
              ) {
                return RoyaltyApprovalModel.fromMap(
                  Map<
                    String,
                    dynamic
                  >.from(
                    row,
                  ),
                );
              },
            ).toList();
          },
        );
  }

  // ============================================================
  // WATCH EVENTS
  // ============================================================

  @override
  Stream<
    List<
      RoyaltyEventModel
    >
  >
  watchEvents({
    required String projectId,
  }) {
    final normalizedProjectId = _require(
      projectId,
      fieldName: 'projectId',
    );

    return _supabase
        .from(
          _eventsTable,
        )
        .stream(
          primaryKey: const [
            'id',
          ],
        )
        .eq(
          'project_id',
          normalizedProjectId,
        )
        .order(
          'created_at',
          ascending: false,
        )
        .map(
          (
            rows,
          ) {
            return rows.map(
              (
                row,
              ) {
                return RoyaltyEventModel.fromMap(
                  Map<
                    String,
                    dynamic
                  >.from(
                    row,
                  ),
                );
              },
            ).toList();
          },
        );
  }

  // ============================================================
  // LOG APPROVAL RESULT
  // ============================================================

  void _logApprovalResult(
    RoyaltyApprovalResult result,
  ) {
    debugPrint(
      '[ROYALTIES] '
      'Aprovação processada. '
      'Status: ${result.status} | '
      'Aprovados: ${result.approvedCount}/'
      '${result.requiredCount} | '
      'Finalizado: ${result.completed}',
    );

    if (result.hasIntegrityHash) {
      debugPrint(
        '[ROYALTIES] '
        'Hash final recebido do banco: '
        '${result.integrityHash}',
      );
    }
  }

  // ============================================================
  // RESOLVE PROFESSIONAL ROLE
  // ============================================================

  Future<
    String
  >
  _resolveProfessionalRole(
    String userId,
  ) async {
    try {
      final role = await _professionalRoleResolver(
        userId,
      );

      final normalized =
          role?.trim() ??
          '';

      if (normalized.isNotEmpty) {
        return normalized;
      }
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[ROYALTIES] '
        'Erro ao resolver função profissional '
        'de $userId: '
        '$error',
      );

      debugPrint(
        '$stackTrace',
      );
    }

    return 'Membro';
  }

  // ============================================================
  // DISPLAY NAME
  // ============================================================

  String _resolveDisplayName(
    Map<
      String,
      dynamic
    >?
    profile,
  ) {
    if (profile ==
        null) {
      return 'Participante';
    }

    final artistName = _nullableString(
      profile['artist_name'],
    );

    if (artistName !=
        null) {
      return artistName;
    }

    final name = _nullableString(
      profile['name'],
    );

    if (name !=
        null) {
      return name;
    }

    final username = _nullableString(
      profile['username'],
    );

    if (username !=
        null) {
      return username.startsWith(
            '@',
          )
          ? username
          : '@$username';
    }

    return 'Participante';
  }

  // ============================================================
  // ROWS
  // ============================================================

  List<
    Map<
      String,
      dynamic
    >
  >
  _rows(
    dynamic response,
  ) {
    if (response
        is! Iterable) {
      return const <
        Map<
          String,
          dynamic
        >
      >[];
    }

    final result =
        <
          Map<
            String,
            dynamic
          >
        >[];

    for (final value in response) {
      if (value
          is Map) {
        result.add(
          Map<
            String,
            dynamic
          >.from(
            value,
          ),
        );
      }
    }

    return result;
  }

  // ============================================================
  // READ STRING ARRAY
  // ============================================================

  List<
    String
  >
  _readStringArray(
    dynamic value,
  ) {
    if (value
        is! Iterable) {
      return const <
        String
      >[];
    }

    final result =
        <
          String
        >[];

    final seen =
        <
          String
        >{};

    for (final item in value) {
      final normalized =
          item?.toString().trim() ??
          '';

      if (normalized.isEmpty) {
        continue;
      }

      if (!seen.add(
        normalized,
      )) {
        continue;
      }

      result.add(
        normalized,
      );
    }

    return result;
  }

  // ============================================================
  // NULLABLE STRING
  // ============================================================

  String? _nullableString(
    dynamic value,
  ) {
    final normalized =
        value?.toString().trim() ??
        '';

    if (normalized.isEmpty) {
      return null;
    }

    final lower = normalized.toLowerCase();

    if (lower ==
            'null' ||
        lower ==
            'undefined' ||
        lower ==
            'none' ||
        lower ==
            'nil') {
      return null;
    }

    return normalized;
  }

  // ============================================================
  // REQUIRE
  // ============================================================

  String _require(
    String value, {
    required String fieldName,
  }) {
    final normalized = value.trim();

    if (normalized.isEmpty) {
      throw ArgumentError.value(
        value,
        fieldName,
        '$fieldName não pode ficar vazio.',
      );
    }

    return normalized;
  }
}
