import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/contribution_approval_model.dart';
import '../../models/contribution_delivery_model.dart';
import '../../models/project_contribution_model.dart';
import '../../models/project_record_event_model.dart';
import '../../models/project_task_member_model.dart';
import '../../repositories/project_tasks_repository.dart';

// ============================================================
// PROFESSIONAL ROLE RESOLVER
// ============================================================
//
// Resolve a habilidade/função profissional do membro usando
// exatamente a mesma fonte utilizada pelo Match.
//
// Exemplo:
//
// Artista
// Produtor
// Beatmaker
// Compositor
//
// O Repository não precisa saber onde essa informação está
// armazenada.
//
// ============================================================

typedef ProjectTaskProfessionalRoleResolver =
    Future<
      String?
    >
    Function(
      String userId,
    );

// ============================================================
// PROJECT TASKS REPOSITORY IMPLEMENTATION
// ============================================================
//
// Implementação Supabase do módulo de produção.
//
// RESPONSABILIDADES:
//
// - membros;
// - founders;
// - contribuições;
// - aprovações;
// - entregas;
// - estados da produção;
// - realtime;
// - Versin Record;
// - calendário.
//
// NÃO:
//
// - desenha UI;
// - mantém estado da tela;
// - seleciona arquivo;
// - calcula SHA-256;
// - decide regra visual.
//
// ============================================================

class ProjectTasksRepositoryImpl
    implements
        ProjectTasksRepository {
  // ============================================================
  // TABLES
  // ============================================================

  static const String _projectsTable = 'projects';

  static const String _profilesTable = 'profiles';

  static const String _contributionsTable = 'project_contributions';

  static const String _approvalsTable = 'contribution_approvals';

  static const String _deliveriesTable = 'contribution_deliveries';

  static const String _recordEventsTable = 'project_record_events';

  // ============================================================
  // SUPABASE
  // ============================================================

  final SupabaseClient _supabase;

  // ============================================================
  // PROFESSIONAL ROLE
  // ============================================================

  final ProjectTaskProfessionalRoleResolver _professionalRoleResolver;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  ProjectTasksRepositoryImpl({
    SupabaseClient? supabase,
    required ProjectTaskProfessionalRoleResolver professionalRoleResolver,
  }) : _supabase =
           supabase ??
           Supabase.instance.client,
       _professionalRoleResolver = professionalRoleResolver;

  // ============================================================
  // PROJECT MEMBERS
  // ============================================================

  @override
  Future<
    List<
      ProjectTaskMemberModel
    >
  >
  getProjectMembers({
    required String projectId,
  }) async {
    final normalizedProjectId = _requireValue(
      projectId,
      fieldName: 'projectId',
    );

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
        ProjectTaskMemberModel
      >[];
    }

    final memberIds = _readStringArray(
      project['members'],
    );

    if (memberIds.isEmpty) {
      return const <
        ProjectTaskMemberModel
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

    final profileRows = _rowsFromResponse(
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

    for (final row in profileRows) {
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
    // MEMBERS
    // ==========================================================

    final result =
        <
          ProjectTaskMemberModel
        >[];

    for (final userId in memberIds) {
      final profile = profileById[userId];

      final professionalRole = await _resolveProfessionalRole(
        userId,
      );

      result.add(
        ProjectTaskMemberModel(
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

          professionalRole: professionalRole,

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

        return a.resolvedDisplayName.toLowerCase().compareTo(
          b.resolvedDisplayName.toLowerCase(),
        );
      },
    );

    return result;
  }

  // ============================================================
  // WATCH PROJECT MEMBERS
  // ============================================================

  @override
  Stream<
    List<
      ProjectTaskMemberModel
    >
  >
  watchProjectMembers({
    required String projectId,
  }) {
    final normalizedProjectId = _requireValue(
      projectId,
      fieldName: 'projectId',
    );

    return _supabase
        .from(
          _projectsTable,
        )
        .stream(
          primaryKey: const [
            'id',
          ],
        )
        .eq(
          'id',
          normalizedProjectId,
        )
        .asyncMap(
          (
            rows,
          ) async {
            if (rows.isEmpty) {
              return const <
                ProjectTaskMemberModel
              >[];
            }

            return getProjectMembers(
              projectId: normalizedProjectId,
            );
          },
        );
  }

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
    final normalizedProjectId = _requireValue(
      projectId,
      fieldName: 'projectId',
    );

    final project = await _supabase
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

    return project !=
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
    final normalizedProjectId = _requireValue(
      projectId,
      fieldName: 'projectId',
    );

    final normalizedUserId = _requireValue(
      userId,
      fieldName: 'userId',
    );

    final project = await _supabase
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

    if (project ==
        null) {
      return false;
    }

    final members = _readStringArray(
      project['members'],
    );

    return members.contains(
      normalizedUserId,
    );
  }

  // ============================================================
  // IS PROJECT FOUNDER
  // ============================================================

  @override
  Future<
    bool
  >
  isProjectFounder({
    required String projectId,
    required String userId,
  }) async {
    final normalizedProjectId = _requireValue(
      projectId,
      fieldName: 'projectId',
    );

    final normalizedUserId = _requireValue(
      userId,
      fieldName: 'userId',
    );

    final project = await _supabase
        .from(
          _projectsTable,
        )
        .select(
          'founders',
        )
        .eq(
          'id',
          normalizedProjectId,
        )
        .maybeSingle();

    if (project ==
        null) {
      return false;
    }

    final founders = _readStringArray(
      project['founders'],
    );

    return founders.contains(
      normalizedUserId,
    );
  }

  // ============================================================
  // GET CONTRIBUTIONS
  // ============================================================

  @override
  Future<
    List<
      ProjectContributionModel
    >
  >
  getContributions({
    required String projectId,
  }) async {
    final normalizedProjectId = _requireValue(
      projectId,
      fieldName: 'projectId',
    );

    final response = await _supabase
        .from(
          _contributionsTable,
        )
        .select()
        .eq(
          'project_id',
          normalizedProjectId,
        )
        .order(
          'created_at',
          ascending: true,
        );

    return _rowsFromResponse(
          response,
        )
        .map(
          _contributionFromRow,
        )
        .toList();
  }

  // ============================================================
  // GET USER CONTRIBUTION
  // ============================================================

  @override
  Future<
    ProjectContributionModel?
  >
  getUserContribution({
    required String projectId,
    required String userId,
  }) async {
    final normalizedProjectId = _requireValue(
      projectId,
      fieldName: 'projectId',
    );

    final normalizedUserId = _requireValue(
      userId,
      fieldName: 'userId',
    );

    final row = await _supabase
        .from(
          _contributionsTable,
        )
        .select()
        .eq(
          'project_id',
          normalizedProjectId,
        )
        .eq(
          'user_id',
          normalizedUserId,
        )
        .maybeSingle();

    if (row ==
        null) {
      return null;
    }

    return _contributionFromRow(
      Map<
        String,
        dynamic
      >.from(
        row,
      ),
    );
  }

  // ============================================================
  // CREATE CONTRIBUTION
  // ============================================================

  @override
  Future<
    ProjectContributionModel
  >
  createContribution({
    required String projectId,
    required String userId,
    required String title,
    required String description,
    required String roleSnapshot,
    String? dependencyContributionId,
    DateTime? dueAt,
  }) async {
    final normalizedProjectId = _requireValue(
      projectId,
      fieldName: 'projectId',
    );

    final normalizedUserId = _requireValue(
      userId,
      fieldName: 'userId',
    );

    final normalizedTitle = _requireValue(
      title,
      fieldName: 'title',
    );

    final normalizedDescription = description.trim();

    final normalizedRole = _requireValue(
      roleSnapshot,
      fieldName: 'roleSnapshot',
    );

    final now = DateTime.now().toUtc();

    final response = await _supabase
        .from(
          _contributionsTable,
        )
        .insert(
          {
            'project_id': normalizedProjectId,

            'user_id': normalizedUserId,

            'title': normalizedTitle,

            'description': normalizedDescription,

            'role_snapshot': normalizedRole,

            'dependency_contribution_id': _emptyToNull(
              dependencyContributionId,
            ),

            'status': 'draft',

            'due_at': dueAt?.toUtc().toIso8601String(),

            'version': 1,

            'created_at': now.toIso8601String(),

            'updated_at': now.toIso8601String(),
          },
        )
        .select()
        .single();

    return _contributionFromRow(
      Map<
        String,
        dynamic
      >.from(
        response,
      ),
    );
  }

  // ============================================================
  // UPDATE CONTRIBUTION
  // ============================================================

  @override
  Future<
    ProjectContributionModel
  >
  updateContribution({
    required ProjectContributionModel contribution,
  }) async {
    final contributionId = _requireValue(
      contribution.id,
      fieldName: 'contribution.id',
    );

    final now = DateTime.now().toUtc();

    final response = await _supabase
        .from(
          _contributionsTable,
        )
        .update(
          {
            'title': contribution.title.trim(),

            'description': contribution.description.trim(),

            'role_snapshot': _emptyToNull(
              contribution.roleSnapshot,
            ),

            'dependency_contribution_id': _emptyToNull(
              contribution.dependencyContributionId,
            ),

            'status': contribution.statusDatabaseValue,

            'version': contribution.version,

            'due_at': contribution.dueAt?.toUtc().toIso8601String(),

            'calendar_event_id': _emptyToNull(
              contribution.calendarEventId,
            ),

            'locked_at': contribution.lockedAt?.toUtc().toIso8601String(),

            'updated_at': now.toIso8601String(),
          },
        )
        .eq(
          'id',
          contributionId,
        )
        .select()
        .single();

    return _contributionFromRow(
      Map<
        String,
        dynamic
      >.from(
        response,
      ),
    );
  }

  // ============================================================
  // SUBMIT CONTRIBUTION FOR APPROVAL
  // ============================================================

  @override
  Future<
    ProjectContributionModel
  >
  submitContributionForApproval({
    required String contributionId,
  }) {
    return _updateContributionStatus(
      contributionId: contributionId,
      status: ProjectContributionStatus.waitingApproval,
    );
  }

  // ============================================================
  // START CONTRIBUTION
  // ============================================================

  @override
  Future<
    ProjectContributionModel
  >
  startContribution({
    required String contributionId,
  }) {
    return _updateContributionStatus(
      contributionId: contributionId,
      status: ProjectContributionStatus.inProgress,
    );
  }

  // ============================================================
  // WATCH CONTRIBUTIONS
  // ============================================================

  @override
  Stream<
    List<
      ProjectContributionModel
    >
  >
  watchContributions({
    required String projectId,
  }) {
    final normalizedProjectId = _requireValue(
      projectId,
      fieldName: 'projectId',
    );

    return _supabase
        .from(
          _contributionsTable,
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
          ascending: true,
        )
        .map(
          (
            rows,
          ) {
            return rows
                .map(
                  (
                    row,
                  ) => _contributionFromRow(
                    Map<
                      String,
                      dynamic
                    >.from(
                      row,
                    ),
                  ),
                )
                .toList();
          },
        );
  }

  // ============================================================
  // GET CONTRIBUTION APPROVALS
  // ============================================================

  @override
  Future<
    List<
      ContributionApprovalModel
    >
  >
  getContributionApprovals({
    required String projectId,
  }) async {
    final contributionIds = await _getContributionIds(
      projectId,
    );

    if (contributionIds.isEmpty) {
      return const <
        ContributionApprovalModel
      >[];
    }

    final response = await _supabase
        .from(
          _approvalsTable,
        )
        .select()
        .inFilter(
          'contribution_id',
          contributionIds,
        )
        .order(
          'approved_at',
          ascending: true,
        );

    return _rowsFromResponse(
          response,
        )
        .map(
          _approvalFromRow,
        )
        .toList();
  }

  // ============================================================
  // GET APPROVALS FOR CONTRIBUTION
  // ============================================================

  @override
  Future<
    List<
      ContributionApprovalModel
    >
  >
  getApprovalsForContribution({
    required String contributionId,
    required int contributionVersion,
  }) async {
    final normalizedContributionId = _requireValue(
      contributionId,
      fieldName: 'contributionId',
    );

    final response = await _supabase
        .from(
          _approvalsTable,
        )
        .select()
        .eq(
          'contribution_id',
          normalizedContributionId,
        )
        .eq(
          'contribution_version',
          contributionVersion,
        )
        .order(
          'approved_at',
          ascending: true,
        );

    return _rowsFromResponse(
          response,
        )
        .map(
          _approvalFromRow,
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
  hasUserApprovedContribution({
    required String contributionId,
    required String userId,
    required int contributionVersion,
  }) async {
    final normalizedContributionId = _requireValue(
      contributionId,
      fieldName: 'contributionId',
    );

    final normalizedUserId = _requireValue(
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
          'contribution_id',
          normalizedContributionId,
        )
        .eq(
          'user_id',
          normalizedUserId,
        )
        .eq(
          'contribution_version',
          contributionVersion,
        )
        .maybeSingle();

    return row !=
        null;
  }

  // ============================================================
  // APPROVE CONTRIBUTION
  // ============================================================

  @override
  Future<
    ContributionApprovalModel
  >
  approveContribution({
    required String contributionId,
    required String userId,
    required int contributionVersion,
  }) async {
    final normalizedContributionId = _requireValue(
      contributionId,
      fieldName: 'contributionId',
    );

    final normalizedUserId = _requireValue(
      userId,
      fieldName: 'userId',
    );

    if (contributionVersion <=
        0) {
      throw ArgumentError.value(
        contributionVersion,
        'contributionVersion',
        'A versão precisa ser maior que zero.',
      );
    }

    final now = DateTime.now().toUtc();

    final response = await _supabase
        .from(
          _approvalsTable,
        )
        .insert(
          {
            'contribution_id': normalizedContributionId,

            'user_id': normalizedUserId,

            'contribution_version': contributionVersion,

            'approved_at': now.toIso8601String(),
          },
        )
        .select()
        .single();

    return _approvalFromRow(
      Map<
        String,
        dynamic
      >.from(
        response,
      ),
    );
  }

  // ============================================================
  // WATCH CONTRIBUTION APPROVALS
  // ============================================================

  @override
  Stream<
    List<
      ContributionApprovalModel
    >
  >
  watchContributionApprovals({
    required String projectId,
  }) {
    final normalizedProjectId = _requireValue(
      projectId,
      fieldName: 'projectId',
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
        .asyncMap(
          (
            rows,
          ) async {
            final contributionIds = (await _getContributionIds(
              normalizedProjectId,
            )).toSet();

            if (contributionIds.isEmpty) {
              return const <
                ContributionApprovalModel
              >[];
            }

            final result = rows
                .where(
                  (
                    row,
                  ) {
                    final id = _nullableString(
                      row['contribution_id'],
                    );

                    return id !=
                            null &&
                        contributionIds.contains(
                          id,
                        );
                  },
                )
                .map(
                  (
                    row,
                  ) {
                    return _approvalFromRow(
                      Map<
                        String,
                        dynamic
                      >.from(
                        row,
                      ),
                    );
                  },
                )
                .toList();

            result.sort(
              (
                a,
                b,
              ) => a.approvedAt.compareTo(
                b.approvedAt,
              ),
            );

            return result;
          },
        );
  }

  // ============================================================
  // GET DELIVERIES
  // ============================================================

  @override
  Future<
    List<
      ContributionDeliveryModel
    >
  >
  getDeliveries({
    required String projectId,
  }) async {
    final contributionIds = await _getContributionIds(
      projectId,
    );

    if (contributionIds.isEmpty) {
      return const <
        ContributionDeliveryModel
      >[];
    }

    final response = await _supabase
        .from(
          _deliveriesTable,
        )
        .select()
        .inFilter(
          'contribution_id',
          contributionIds,
        )
        .order(
          'created_at',
          ascending: true,
        );

    return _rowsFromResponse(
          response,
        )
        .map(
          _deliveryFromRow,
        )
        .toList();
  }

  // ============================================================
  // DELIVERIES FOR CONTRIBUTION
  // ============================================================

  @override
  Future<
    List<
      ContributionDeliveryModel
    >
  >
  getDeliveriesForContribution({
    required String contributionId,
  }) async {
    final normalizedContributionId = _requireValue(
      contributionId,
      fieldName: 'contributionId',
    );

    final response = await _supabase
        .from(
          _deliveriesTable,
        )
        .select()
        .eq(
          'contribution_id',
          normalizedContributionId,
        )
        .order(
          'version',
          ascending: true,
        );

    return _rowsFromResponse(
          response,
        )
        .map(
          _deliveryFromRow,
        )
        .toList();
  }

  // ============================================================
  // LATEST DELIVERY
  // ============================================================

  @override
  Future<
    ContributionDeliveryModel?
  >
  getLatestDelivery({
    required String contributionId,
  }) async {
    final normalizedContributionId = _requireValue(
      contributionId,
      fieldName: 'contributionId',
    );

    final response = await _supabase
        .from(
          _deliveriesTable,
        )
        .select()
        .eq(
          'contribution_id',
          normalizedContributionId,
        )
        .order(
          'version',
          ascending: false,
        )
        .limit(
          1,
        );

    final rows = _rowsFromResponse(
      response,
    );

    if (rows.isEmpty) {
      return null;
    }

    return _deliveryFromRow(
      rows.first,
    );
  }

  // ============================================================
  // CREATE DELIVERY
  // ============================================================

  @override
  Future<
    ContributionDeliveryModel
  >
  createDelivery({
    required String contributionId,
    required String uploadedBy,
    required String fileName,
    required String storagePath,
    required int version,
    required int fileSize,
    required String sha256,
    String? mimeType,
  }) async {
    final normalizedContributionId = _requireValue(
      contributionId,
      fieldName: 'contributionId',
    );

    final normalizedUploadedBy = _requireValue(
      uploadedBy,
      fieldName: 'uploadedBy',
    );

    final normalizedFileName = _requireValue(
      fileName,
      fieldName: 'fileName',
    );

    final normalizedStoragePath = _requireValue(
      storagePath,
      fieldName: 'storagePath',
    );

    final normalizedHash = _requireValue(
      sha256,
      fieldName: 'sha256',
    );

    if (version <=
        0) {
      throw ArgumentError.value(
        version,
        'version',
        'A versão precisa ser maior que zero.',
      );
    }

    if (fileSize <=
        0) {
      throw ArgumentError.value(
        fileSize,
        'fileSize',
        'O arquivo precisa possuir conteúdo.',
      );
    }

    final now = DateTime.now().toUtc();

    final response = await _supabase
        .from(
          _deliveriesTable,
        )
        .insert(
          {
            'contribution_id': normalizedContributionId,

            'uploaded_by': normalizedUploadedBy,

            'file_name': normalizedFileName,

            'storage_path': normalizedStoragePath,

            'mime_type': _emptyToNull(
              mimeType,
            ),

            'file_size': fileSize,

            'sha256': normalizedHash,

            'version': version,

            'status': 'submitted',

            'created_at': now.toIso8601String(),
          },
        )
        .select()
        .single();

    return _deliveryFromRow(
      Map<
        String,
        dynamic
      >.from(
        response,
      ),
    );
  }

  // ============================================================
  // MARK CONTRIBUTION DELIVERED
  // ============================================================

  @override
  Future<
    ProjectContributionModel
  >
  markContributionDelivered({
    required String contributionId,
  }) {
    return _updateContributionStatus(
      contributionId: contributionId,
      status: ProjectContributionStatus.delivered,
    );
  }

  // ============================================================
  // VALIDATE DELIVERY
  // ============================================================

  @override
  Future<
    ContributionDeliveryModel
  >
  validateDelivery({
    required String deliveryId,
  }) async {
    final normalizedDeliveryId = _requireValue(
      deliveryId,
      fieldName: 'deliveryId',
    );

    // ==========================================================
    // DELIVERY
    // ==========================================================

    final deliveryRow = await _supabase
        .from(
          _deliveriesTable,
        )
        .select(
          'id, contribution_id',
        )
        .eq(
          'id',
          normalizedDeliveryId,
        )
        .single();

    final contributionId = _requireDynamicValue(
      deliveryRow['contribution_id'],
      fieldName: 'contribution_id',
    );

    final now = DateTime.now().toUtc();

    // ==========================================================
    // UPDATE DELIVERY
    // ==========================================================

    final response = await _supabase
        .from(
          _deliveriesTable,
        )
        .update(
          {
            'status': 'validated',

            'validated_at': now.toIso8601String(),
          },
        )
        .eq(
          'id',
          normalizedDeliveryId,
        )
        .select()
        .single();

    // ==========================================================
    // UPDATE CONTRIBUTION
    // ==========================================================

    await _supabase
        .from(
          _contributionsTable,
        )
        .update(
          {
            'status': 'validated',

            'updated_at': now.toIso8601String(),
          },
        )
        .eq(
          'id',
          contributionId,
        );

    return _deliveryFromRow(
      Map<
        String,
        dynamic
      >.from(
        response,
      ),
    );
  }

  // ============================================================
  // REJECT DELIVERY
  // ============================================================

  @override
  Future<
    ContributionDeliveryModel
  >
  rejectDelivery({
    required String deliveryId,
  }) async {
    final normalizedDeliveryId = _requireValue(
      deliveryId,
      fieldName: 'deliveryId',
    );

    final response = await _supabase
        .from(
          _deliveriesTable,
        )
        .update(
          {
            'status': 'rejected',

            'validated_at': null,
          },
        )
        .eq(
          'id',
          normalizedDeliveryId,
        )
        .select()
        .single();

    return _deliveryFromRow(
      Map<
        String,
        dynamic
      >.from(
        response,
      ),
    );
  }

  // ============================================================
  // WATCH DELIVERIES
  // ============================================================

  @override
  Stream<
    List<
      ContributionDeliveryModel
    >
  >
  watchDeliveries({
    required String projectId,
  }) {
    final normalizedProjectId = _requireValue(
      projectId,
      fieldName: 'projectId',
    );

    return _supabase
        .from(
          _deliveriesTable,
        )
        .stream(
          primaryKey: const [
            'id',
          ],
        )
        .asyncMap(
          (
            rows,
          ) async {
            final contributionIds = (await _getContributionIds(
              normalizedProjectId,
            )).toSet();

            if (contributionIds.isEmpty) {
              return const <
                ContributionDeliveryModel
              >[];
            }

            final result = rows
                .where(
                  (
                    row,
                  ) {
                    final id = _nullableString(
                      row['contribution_id'],
                    );

                    return id !=
                            null &&
                        contributionIds.contains(
                          id,
                        );
                  },
                )
                .map(
                  (
                    row,
                  ) {
                    return _deliveryFromRow(
                      Map<
                        String,
                        dynamic
                      >.from(
                        row,
                      ),
                    );
                  },
                )
                .toList();

            result.sort(
              (
                a,
                b,
              ) => a.createdAt.compareTo(
                b.createdAt,
              ),
            );

            return result;
          },
        );
  }

  // ============================================================
  // GET PROJECT RECORD EVENTS
  // ============================================================

  @override
  Future<
    List<
      ProjectRecordEventModel
    >
  >
  getProjectRecordEvents({
    required String projectId,
  }) async {
    final normalizedProjectId = _requireValue(
      projectId,
      fieldName: 'projectId',
    );

    final response = await _supabase
        .from(
          _recordEventsTable,
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

    return _rowsFromResponse(
          response,
        )
        .map(
          _recordEventFromRow,
        )
        .toList();
  }

  // ============================================================
  // GET LATEST PROJECT RECORD EVENT
  // ============================================================

  @override
  Future<
    ProjectRecordEventModel?
  >
  getLatestProjectRecordEvent({
    required String projectId,
  }) async {
    final normalizedProjectId = _requireValue(
      projectId,
      fieldName: 'projectId',
    );

    final response = await _supabase
        .from(
          _recordEventsTable,
        )
        .select()
        .eq(
          'project_id',
          normalizedProjectId,
        )
        .order(
          'created_at',
          ascending: false,
        )
        .limit(
          1,
        );

    final rows = _rowsFromResponse(
      response,
    );

    if (rows.isEmpty) {
      return null;
    }

    return _recordEventFromRow(
      rows.first,
    );
  }

  // ============================================================
  // CREATE PROJECT RECORD EVENT
  // ============================================================

  @override
  Future<
    ProjectRecordEventModel
  >
  createProjectRecordEvent({
    required String projectId,
    required ProjectRecordEventType eventType,
    required Map<
      String,
      dynamic
    >
    payload,
    required DateTime createdAt,
    String? actorUserId,
    String? entityType,
    String? entityId,
    String? payloadHash,
    String? previousEventHash,
    String? eventHash,
  }) async {
    final normalizedProjectId = _requireValue(
      projectId,
      fieldName: 'projectId',
    );

    final temporaryModel = ProjectRecordEventModel(
      id: '',

      projectId: normalizedProjectId,

      actorUserId: _emptyToNull(
        actorUserId,
      ),

      eventType: eventType,

      entityType: _emptyToNull(
        entityType,
      ),

      entityId: _emptyToNull(
        entityId,
      ),

      payload:
          Map<
            String,
            dynamic
          >.from(
            payload,
          ),

      payloadHash: _emptyToNull(
        payloadHash,
      ),

      previousEventHash: _emptyToNull(
        previousEventHash,
      ),

      eventHash: _emptyToNull(
        eventHash,
      ),

      createdAt: createdAt.toUtc(),
    );

    final response = await _supabase
        .from(
          _recordEventsTable,
        )
        .insert(
          {
            'project_id': normalizedProjectId,

            'actor_user_id': _emptyToNull(
              actorUserId,
            ),

            'event_type': temporaryModel.eventDatabaseValue,

            'entity_type': _emptyToNull(
              entityType,
            ),

            'entity_id': _emptyToNull(
              entityId,
            ),

            'payload': payload,

            'payload_hash': _emptyToNull(
              payloadHash,
            ),

            'previous_event_hash': _emptyToNull(
              previousEventHash,
            ),

            'event_hash': _emptyToNull(
              eventHash,
            ),

            'created_at': createdAt.toUtc().toIso8601String(),
          },
        )
        .select()
        .single();

    return _recordEventFromRow(
      Map<
        String,
        dynamic
      >.from(
        response,
      ),
    );
  }

  // ============================================================
  // WATCH PROJECT RECORD EVENTS
  // ============================================================

  @override
  Stream<
    List<
      ProjectRecordEventModel
    >
  >
  watchProjectRecordEvents({
    required String projectId,
  }) {
    final normalizedProjectId = _requireValue(
      projectId,
      fieldName: 'projectId',
    );

    return _supabase
        .from(
          _recordEventsTable,
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
                return _recordEventFromRow(
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
  // ATTACH CALENDAR EVENT
  // ============================================================

  @override
  Future<
    ProjectContributionModel
  >
  attachCalendarEvent({
    required String contributionId,
    required String calendarEventId,
  }) async {
    final normalizedContributionId = _requireValue(
      contributionId,
      fieldName: 'contributionId',
    );

    final normalizedCalendarEventId = _requireValue(
      calendarEventId,
      fieldName: 'calendarEventId',
    );

    final response = await _supabase
        .from(
          _contributionsTable,
        )
        .update(
          {
            'calendar_event_id': normalizedCalendarEventId,

            'updated_at': DateTime.now().toUtc().toIso8601String(),
          },
        )
        .eq(
          'id',
          normalizedContributionId,
        )
        .select()
        .single();

    return _contributionFromRow(
      Map<
        String,
        dynamic
      >.from(
        response,
      ),
    );
  }

  // ============================================================
  // DETACH CALENDAR EVENT
  // ============================================================

  @override
  Future<
    ProjectContributionModel
  >
  detachCalendarEvent({
    required String contributionId,
  }) async {
    final normalizedContributionId = _requireValue(
      contributionId,
      fieldName: 'contributionId',
    );

    final response = await _supabase
        .from(
          _contributionsTable,
        )
        .update(
          {
            'calendar_event_id': null,

            'updated_at': DateTime.now().toUtc().toIso8601String(),
          },
        )
        .eq(
          'id',
          normalizedContributionId,
        )
        .select()
        .single();

    return _contributionFromRow(
      Map<
        String,
        dynamic
      >.from(
        response,
      ),
    );
  }

  // ============================================================
  // UPDATE CONTRIBUTION STATUS
  // ============================================================

  Future<
    ProjectContributionModel
  >
  _updateContributionStatus({
    required String contributionId,
    required ProjectContributionStatus status,
  }) async {
    final normalizedContributionId = _requireValue(
      contributionId,
      fieldName: 'contributionId',
    );

    final now = DateTime.now().toUtc();

    final temporary = ProjectContributionModel(
      id: normalizedContributionId,

      projectId: '',

      userId: '',

      title: '',

      description: '',

      status: status,

      version: 1,

      createdAt: now,

      updatedAt: now,
    );

    final response = await _supabase
        .from(
          _contributionsTable,
        )
        .update(
          {
            'status': temporary.statusDatabaseValue,

            'updated_at': now.toIso8601String(),
          },
        )
        .eq(
          'id',
          normalizedContributionId,
        )
        .select()
        .single();

    return _contributionFromRow(
      Map<
        String,
        dynamic
      >.from(
        response,
      ),
    );
  }

  // ============================================================
  // GET CONTRIBUTION IDS
  // ============================================================

  Future<
    List<
      String
    >
  >
  _getContributionIds(
    String projectId,
  ) async {
    final normalizedProjectId = _requireValue(
      projectId,
      fieldName: 'projectId',
    );

    final response = await _supabase
        .from(
          _contributionsTable,
        )
        .select(
          'id',
        )
        .eq(
          'project_id',
          normalizedProjectId,
        );

    final result =
        <
          String
        >[];

    for (final row in _rowsFromResponse(
      response,
    )) {
      final id = _nullableString(
        row['id'],
      );

      if (id !=
          null) {
        result.add(
          id,
        );
      }
    }

    return result;
  }

  // ============================================================
  // CONTRIBUTION FROM ROW
  // ============================================================

  ProjectContributionModel _contributionFromRow(
    Map<
      String,
      dynamic
    >
    row,
  ) {
    final createdAt =
        _dateTime(
          row['created_at'],
        ) ??
        DateTime.now().toUtc();

    final updatedAt =
        _dateTime(
          row['updated_at'],
        ) ??
        createdAt;

    return ProjectContributionModel(
      id: _requireDynamicValue(
        row['id'],
        fieldName: 'id',
      ),

      projectId: _requireDynamicValue(
        row['project_id'],
        fieldName: 'project_id',
      ),

      userId: _requireDynamicValue(
        row['user_id'],
        fieldName: 'user_id',
      ),

      title:
          row['title']?.toString().trim() ??
          '',

      description:
          row['description']?.toString().trim() ??
          '',

      roleSnapshot: _nullableString(
        row['role_snapshot'],
      ),

      dependencyContributionId: _nullableString(
        row['dependency_contribution_id'],
      ),

      status: ProjectContributionModel.statusFromDatabase(
        row['status']?.toString(),
      ),

      version: _intValue(
        row['version'],
        fallback: 1,
      ),

      dueAt: _dateTime(
        row['due_at'],
      ),

      calendarEventId: _nullableString(
        row['calendar_event_id'],
      ),

      lockedAt: _dateTime(
        row['locked_at'],
      ),

      createdAt: createdAt,

      updatedAt: updatedAt,
    );
  }

  // ============================================================
  // APPROVAL FROM ROW
  // ============================================================

  ContributionApprovalModel _approvalFromRow(
    Map<
      String,
      dynamic
    >
    row,
  ) {
    return ContributionApprovalModel(
      id: _requireDynamicValue(
        row['id'],
        fieldName: 'id',
      ),

      contributionId: _requireDynamicValue(
        row['contribution_id'],
        fieldName: 'contribution_id',
      ),

      userId: _requireDynamicValue(
        row['user_id'],
        fieldName: 'user_id',
      ),

      contributionVersion: _intValue(
        row['contribution_version'],
        fallback: 1,
      ),

      approvedAt:
          _dateTime(
            row['approved_at'],
          ) ??
          DateTime.now().toUtc(),
    );
  }

  // ============================================================
  // DELIVERY FROM ROW
  // ============================================================

  ContributionDeliveryModel _deliveryFromRow(
    Map<
      String,
      dynamic
    >
    row,
  ) {
    return ContributionDeliveryModel(
      id: _requireDynamicValue(
        row['id'],
        fieldName: 'id',
      ),

      contributionId: _requireDynamicValue(
        row['contribution_id'],
        fieldName: 'contribution_id',
      ),

      uploadedBy: _requireDynamicValue(
        row['uploaded_by'],
        fieldName: 'uploaded_by',
      ),

      fileName: _requireDynamicValue(
        row['file_name'],
        fieldName: 'file_name',
      ),

      storagePath: _requireDynamicValue(
        row['storage_path'],
        fieldName: 'storage_path',
      ),

      mimeType: _nullableString(
        row['mime_type'],
      ),

      fileSize: _nullableInt(
        row['file_size'],
      ),

      sha256: _nullableString(
        row['sha256'],
      ),

      version: _intValue(
        row['version'],
        fallback: 1,
      ),

      status: ContributionDeliveryModel.statusFromDatabase(
        row['status']?.toString(),
      ),

      createdAt:
          _dateTime(
            row['created_at'],
          ) ??
          DateTime.now().toUtc(),

      validatedAt: _dateTime(
        row['validated_at'],
      ),
    );
  }

  // ============================================================
  // RECORD EVENT FROM ROW
  // ============================================================

  ProjectRecordEventModel _recordEventFromRow(
    Map<
      String,
      dynamic
    >
    row,
  ) {
    final payloadRaw = row['payload'];

    final payload =
        payloadRaw
            is Map
        ? Map<
            String,
            dynamic
          >.from(
            payloadRaw,
          )
        : <
            String,
            dynamic
          >{};

    return ProjectRecordEventModel(
      id: _requireDynamicValue(
        row['id'],
        fieldName: 'id',
      ),

      projectId: _requireDynamicValue(
        row['project_id'],
        fieldName: 'project_id',
      ),

      actorUserId: _nullableString(
        row['actor_user_id'],
      ),

      eventType: ProjectRecordEventModel.eventFromDatabase(
        row['event_type']?.toString(),
      ),

      entityType: _nullableString(
        row['entity_type'],
      ),

      entityId: _nullableString(
        row['entity_id'],
      ),

      payload: payload,

      payloadHash: _nullableString(
        row['payload_hash'],
      ),

      previousEventHash: _nullableString(
        row['previous_event_hash'],
      ),

      eventHash: _nullableString(
        row['event_hash'],
      ),

      createdAt:
          _dateTime(
            row['created_at'],
          ) ??
          DateTime.now().toUtc(),
    );
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
      final value = await _professionalRoleResolver(
        userId,
      );

      final normalized =
          value?.trim() ??
          '';

      if (normalized.isNotEmpty) {
        return normalized;
      }
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[PROJECT TASKS REPOSITORY] '
        'Erro ao resolver habilidade '
        'de $userId: $error',
      );

      debugPrint(
        '$stackTrace',
      );
    }

    return 'Profissional';
  }

  // ============================================================
  // RESOLVE DISPLAY NAME
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
      return 'Usuário';
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
      final normalized = username.replaceFirst(
        RegExp(
          r'^@+',
        ),
        '',
      );

      if (normalized.isNotEmpty) {
        return '@$normalized';
      }
    }

    return 'Usuário';
  }

  // ============================================================
  // ROWS FROM RESPONSE
  // ============================================================

  List<
    Map<
      String,
      dynamic
    >
  >
  _rowsFromResponse(
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

    for (final item in response) {
      if (item
          is Map) {
        result.add(
          Map<
            String,
            dynamic
          >.from(
            item,
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
    dynamic raw,
  ) {
    if (raw
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

    for (final value in raw) {
      final normalized =
          value?.toString().trim() ??
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
  // DATE TIME
  // ============================================================

  DateTime? _dateTime(
    dynamic value,
  ) {
    if (value ==
        null) {
      return null;
    }

    if (value
        is DateTime) {
      return value.toUtc();
    }

    final normalized = value.toString().trim();

    if (normalized.isEmpty) {
      return null;
    }

    return DateTime.tryParse(
      normalized,
    )?.toUtc();
  }

  // ============================================================
  // INT VALUE
  // ============================================================

  int _intValue(
    dynamic value, {
    required int fallback,
  }) {
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
        fallback;
  }

  // ============================================================
  // NULLABLE INT
  // ============================================================

  int? _nullableInt(
    dynamic value,
  ) {
    if (value ==
        null) {
      return null;
    }

    if (value
        is int) {
      return value;
    }

    if (value
        is num) {
      return value.toInt();
    }

    return int.tryParse(
      value.toString(),
    );
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
  // EMPTY TO NULL
  // ============================================================

  String? _emptyToNull(
    String? value,
  ) {
    final normalized =
        value?.trim() ??
        '';

    return normalized.isEmpty
        ? null
        : normalized;
  }

  // ============================================================
  // REQUIRE VALUE
  // ============================================================

  String _requireValue(
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

  // ============================================================
  // REQUIRE DYNAMIC VALUE
  // ============================================================

  String _requireDynamicValue(
    dynamic value, {
    required String fieldName,
  }) {
    final normalized =
        value?.toString().trim() ??
        '';

    if (normalized.isEmpty) {
      throw StateError(
        'Campo obrigatório ausente: '
        '$fieldName.',
      );
    }

    return normalized;
  }
}
