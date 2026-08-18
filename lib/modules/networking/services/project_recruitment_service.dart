import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models/project_recruitment_model.dart';

// ============================================================
// PROJECT RECRUITMENT SERVICE
// ============================================================
//
// Gerencia:
//
// - buscas abertas;
// - descoberta de candidatos;
// - convites;
// - interesse;
// - aprovação;
// - inclusão em projects.members.
//
// ============================================================

class ProjectRecruitmentService {
  static const String _projectsTable = 'projects';

  static const String _profilesTable = 'profiles';

  static const String _recruitmentsTable = 'project_recruitments';

  static const String _candidatesTable = 'project_recruitment_candidates';

  final SupabaseClient _supabase;

  ProjectRecruitmentService({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  // ==========================================================
  // CURRENT USER
  // ==========================================================

  String? get currentUserId {
    final id = _supabase.auth.currentUser?.id.trim();

    if (id == null || id.isEmpty) {
      return null;
    }

    return id;
  }

  String requireCurrentUserId() {
    final id = currentUserId;

    if (id == null) {
      throw StateError('Usuário não autenticado.');
    }

    return id;
  }

  // ==========================================================
  // CRIAR RECRUTAMENTO
  // ==========================================================

  Future<ProjectRecruitmentModel> createRecruitment({
    required String projectId,
    required String role,
    String description = '',
    DateTime? expiresAt,
  }) async {
    final normalizedProjectId = _required(projectId, 'projectId');

    final normalizedRole = _required(role, 'role').toLowerCase();

    final userId = requireCurrentUserId();

    final response = await _supabase
        .from(_recruitmentsTable)
        .insert({
          'project_id': normalizedProjectId,

          'created_by': userId,

          'role': normalizedRole,

          'description': description.trim(),

          'status': 'open',

          'expires_at': expiresAt?.toUtc().toIso8601String(),
        })
        .select()
        .single();

    final recruitment = ProjectRecruitmentModel.fromMap(
      Map<String, dynamic>.from(response),
    );

    debugPrint(
      '[PROJECT RECRUITMENT] '
      'Busca criada: '
      '${recruitment.id} | '
      '${recruitment.role}',
    );

    return recruitment;
  }

  // ==========================================================
  // LISTAR RECRUTAMENTOS
  // ==========================================================

  Future<List<ProjectRecruitmentModel>> getRecruitments({
    required String projectId,
  }) async {
    final id = _required(projectId, 'projectId');

    final response = await _supabase
        .from(_recruitmentsTable)
        .select()
        .eq('project_id', id)
        .order('created_at', ascending: false);

    return response
        .map(
          (row) =>
              ProjectRecruitmentModel.fromMap(Map<String, dynamic>.from(row)),
        )
        .toList(growable: false);
  }

  // ==========================================================
  // STREAM
  // ==========================================================

  Stream<List<ProjectRecruitmentModel>> streamRecruitments({
    required String projectId,
  }) {
    final id = _required(projectId, 'projectId');

    return _supabase
        .from(_recruitmentsTable)
        .stream(primaryKey: ['id'])
        .eq('project_id', id)
        .order('created_at', ascending: false)
        .map(
          (rows) => rows
              .map(
                (row) => ProjectRecruitmentModel.fromMap(
                  Map<String, dynamic>.from(row),
                ),
              )
              .toList(growable: false),
        );
  }

  // ==========================================================
  // CANDIDATOS
  // ==========================================================

  Future<List<ProjectRecruitmentCandidateModel>> getCandidates({
    required ProjectRecruitmentModel recruitment,
  }) async {
    // ========================================================
    // PROJETO
    // ========================================================

    final project = await _supabase
        .from(_projectsTable)
        .select('members')
        .eq('id', recruitment.projectId)
        .single();

    final memberIds = _readIds(project['members']);

    // ========================================================
    // PROFILES COMPATÍVEIS
    // ========================================================

    final profiles = await _supabase
        .from(_profilesTable)
        .select('''
              id,
              username,
              name,
              artist_name,
              primary_role,
              roles,
              avatar_url,
              is_online
              ''')
        .contains('roles', [recruitment.role])
        .limit(100);

    // ========================================================
    // STATUS JÁ REGISTRADOS
    // ========================================================

    final candidateRows = await _supabase
        .from(_candidatesTable)
        .select('''
              id,
              user_id,
              status
              ''')
        .eq('recruitment_id', recruitment.id);

    final candidateByUser = <String, Map<String, dynamic>>{};

    for (final row in candidateRows) {
      final map = Map<String, dynamic>.from(row);

      final userId = map['user_id']?.toString().trim();

      if (userId != null && userId.isNotEmpty) {
        candidateByUser[userId] = map;
      }
    }

    // ========================================================
    // CONVERTER
    // ========================================================

    final candidates = <ProjectRecruitmentCandidateModel>[];

    for (final row in profiles) {
      final map = Map<String, dynamic>.from(row);

      final userId = map['id']?.toString().trim();

      if (userId == null || userId.isEmpty) {
        continue;
      }

      // Já faz parte da Studio Session.
      if (memberIds.contains(userId)) {
        continue;
      }

      final candidateRow = candidateByUser[userId];

      candidates.add(
        ProjectRecruitmentCandidateModel.fromProfileMap(
          map,
          candidateRecordId: candidateRow?['id']?.toString(),
          status: ProjectRecruitmentCandidateModel.statusFromString(
            candidateRow?['status']?.toString(),
          ),
        ),
      );
    }

    candidates.sort((first, second) {
      if (first.isOnline != second.isOnline) {
        return first.isOnline ? -1 : 1;
      }

      return first.displayName.toLowerCase().compareTo(
        second.displayName.toLowerCase(),
      );
    });

    return candidates;
  }

  // ==========================================================
  // CONVIDAR
  // ==========================================================

  Future<void> inviteCandidate({
    required String recruitmentId,
    required String userId,
  }) async {
    final currentUserId = requireCurrentUserId();

    await _supabase.from(_candidatesTable).upsert({
      'recruitment_id': _required(recruitmentId, 'recruitmentId'),

      'user_id': _required(userId, 'userId'),

      'status': 'invited',

      'invited_by': currentUserId,

      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'recruitment_id,user_id');
  }

  // ==========================================================
  // REGISTRAR INTERESSE
  // ==========================================================

  Future<void> registerInterest({required String recruitmentId}) async {
    final userId = requireCurrentUserId();

    await _supabase.from(_candidatesTable).upsert({
      'recruitment_id': _required(recruitmentId, 'recruitmentId'),

      'user_id': userId,

      'status': 'interested',

      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'recruitment_id,user_id');
  }

  // ==========================================================
  // APROVAR
  // ==========================================================
  //
  // A aprovação acontece no PostgreSQL através da RPC:
  //
  // public.approve_project_recruitment_candidate
  //
  // Isso evita que o Flutter altere projects.members
  // diretamente.
  //
  // A RPC valida:
  //
  // - usuário autenticado;
  // - recrutamento aberto;
  // - usuário aprovador pertence ao projeto;
  // - candidato existe;
  // - candidato está vinculado ao recrutamento;
  // - candidato ainda não pertence ao projeto;
  // - status permitido para aprovação.
  //
  // Depois, de forma atômica:
  //
  // 1. adiciona o candidato em projects.members;
  // 2. muda o status para approved.
  //
  // ==========================================================

  Future<void> approveCandidate({
    required ProjectRecruitmentModel recruitment,
    required String userId,
  }) async {
    final recruitmentId = _required(recruitment.id, 'recruitmentId');

    final candidateUserId = _required(userId, 'userId');

    // ========================================================
    // AUTH
    // ========================================================

    requireCurrentUserId();

    try {
      // ======================================================
      // RPC SEGURA
      // ======================================================

      await _supabase.rpc(
        'approve_project_recruitment_candidate',
        params: {
          'p_recruitment_id': recruitmentId,
          'p_candidate_user_id': candidateUserId,
        },
      );

      debugPrint(
        '[PROJECT RECRUITMENT] '
        'Candidato aprovado: '
        '$candidateUserId',
      );
    } on PostgrestException catch (error) {
      debugPrint(
        '[PROJECT RECRUITMENT] '
        'Erro ao aprovar candidato: '
        '${error.message}',
      );

      debugPrint(
        '[PROJECT RECRUITMENT] '
        'Código: '
        '${error.code}',
      );

      rethrow;
    } catch (error, stackTrace) {
      debugPrint(
        '[PROJECT RECRUITMENT] '
        'Erro inesperado ao aprovar candidato: '
        '$error',
      );

      debugPrint(
        '[PROJECT RECRUITMENT] '
        'StackTrace: '
        '$stackTrace',
      );

      rethrow;
    }
  }

  // ==========================================================
  // FECHAR RECRUTAMENTO
  // ==========================================================

  Future<void> closeRecruitment({required String recruitmentId}) async {
    await _supabase
        .from(_recruitmentsTable)
        .update({'status': 'closed'})
        .eq('id', _required(recruitmentId, 'recruitmentId'));
  }

  // ==========================================================
  // IDS
  // ==========================================================

  List<String> _readIds(dynamic value) {
    if (value is! Iterable) {
      return <String>[];
    }

    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList();
  }

  // ==========================================================
  // REQUIRED
  // ==========================================================

  String _required(String value, String field) {
    final normalized = value.trim();

    if (normalized.isEmpty) {
      throw ArgumentError('$field não pode ser vazio.');
    }

    return normalized;
  }
}
