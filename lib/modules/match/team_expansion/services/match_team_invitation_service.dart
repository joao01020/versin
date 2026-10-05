import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================================
// MATCH TEAM INVITATION RESULT
// ============================================================

enum MatchTeamInvitationStatus {
  invited,
  alreadyPending,
  alreadyMember,
}

// ============================================================
// MATCH TEAM INVITATION RESULT
// ============================================================

class MatchTeamInvitationResult {
  final MatchTeamInvitationStatus status;

  final String projectId;

  final String invitedUserId;

  final String? invitationId;

  const MatchTeamInvitationResult({
    required this.status,
    required this.projectId,
    required this.invitedUserId,
    this.invitationId,
  });

  bool get wasCreated {
    return status ==
        MatchTeamInvitationStatus.invited;
  }

  bool get alreadyPending {
    return status ==
        MatchTeamInvitationStatus.alreadyPending;
  }

  bool get alreadyMember {
    return status ==
        MatchTeamInvitationStatus.alreadyMember;
  }
}

// ============================================================
// MATCH TEAM INVITATION SERVICE
// ============================================================
//
// Responsável exclusivamente pela regra de negócio de convite
// durante o modo Team Expansion do Match.
//
// FLUXO:
//
// Match
//   ↓
// Studio Session existente
//   ↓
// usuário encontra profissional
//   ↓
// convite
//   ↓
// project_invitations
//
// IMPORTANTE:
//
// Este service NÃO adiciona o profissional diretamente em:
//
// projects.members
//
// O usuário só entra na Studio Session depois de aceitar o
// convite.
//
// ============================================================

class MatchTeamInvitationService {
  // ============================================================
  // SUPABASE
  // ============================================================

  final SupabaseClient _supabase;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  MatchTeamInvitationService({
    SupabaseClient? supabase,
  }) : _supabase =
           supabase ??
           Supabase.instance.client;

  // ============================================================
  // CURRENT USER
  // ============================================================

  String? get currentUserId {
    final userId = _supabase.auth.currentUser?.id.trim();

    if (userId ==
            null ||
        userId.isEmpty) {
      return null;
    }

    return userId;
  }

  // ============================================================
  // SEND INVITATION
  // ============================================================

  Future<
    MatchTeamInvitationResult
  >
  invite({
    required String projectId,
    required String invitedUserId,
  }) async {
    final normalizedProjectId = projectId.trim();

    final normalizedInvitedUserId = invitedUserId.trim();

    // ==========================================================
    // VALIDATE PROJECT
    // ==========================================================

    if (normalizedProjectId.isEmpty) {
      throw ArgumentError(
        'projectId não pode ficar vazio.',
      );
    }

    // ==========================================================
    // VALIDATE USER
    // ==========================================================

    if (normalizedInvitedUserId.isEmpty) {
      throw ArgumentError(
        'invitedUserId não pode ficar vazio.',
      );
    }

    // ==========================================================
    // AUTH
    // ==========================================================

    final inviterId = _requireAuthenticatedUserId();

    // ==========================================================
    // SELF INVITATION
    // ==========================================================

    if (inviterId ==
        normalizedInvitedUserId) {
      throw StateError(
        'Você não pode convidar a si mesmo.',
      );
    }

    try {
      debugPrint(
        '[MATCH TEAM EXPANSION] '
        'Preparando convite. '
        'Projeto: $normalizedProjectId | '
        'Convidado: $normalizedInvitedUserId',
      );

      // ========================================================
      // PROJECT
      // ========================================================

      final project = await _supabase
          .from(
            'projects',
          )
          .select(
            'id, title, members, founders',
          )
          .eq(
            'id',
            normalizedProjectId,
          )
          .maybeSingle();

      if (project ==
          null) {
        throw StateError(
          'Studio Session não encontrada.',
        );
      }

      // ========================================================
      // MEMBERS
      // ========================================================

      final members = _readStringSet(
        project['members'],
      );

      // ========================================================
      // FOUNDERS
      // ========================================================

      final founders = _readStringSet(
        project['founders'],
      );

      // ========================================================
      // VALIDATE FOUNDER
      // ========================================================

      if (!founders.contains(
        inviterId,
      )) {
        throw StateError(
          'Somente fundadores podem convidar novos membros.',
        );
      }

      // ========================================================
      // ALREADY MEMBER
      // ========================================================

      if (members.contains(
        normalizedInvitedUserId,
      )) {
        debugPrint(
          '[MATCH TEAM EXPANSION] '
          'Usuário já pertence ao projeto.',
        );

        return MatchTeamInvitationResult(
          status: MatchTeamInvitationStatus.alreadyMember,
          projectId: normalizedProjectId,
          invitedUserId: normalizedInvitedUserId,
        );
      }

      // ========================================================
      // EXISTING PENDING INVITATION
      // ========================================================

      final existing = await _findPendingInvitation(
        projectId: normalizedProjectId,
        invitedUserId: normalizedInvitedUserId,
      );

      if (existing !=
          null) {
        debugPrint(
          '[MATCH TEAM EXPANSION] '
          'Já existe convite pendente.',
        );

        return MatchTeamInvitationResult(
          status: MatchTeamInvitationStatus.alreadyPending,
          projectId: normalizedProjectId,
          invitedUserId: normalizedInvitedUserId,
          invitationId: existing['id']?.toString(),
        );
      }

      // ========================================================
      // CREATE INVITATION
      // ========================================================

      final inserted = await _supabase
          .from(
            'project_invitations',
          )
          .insert(
            {
              'project_id': normalizedProjectId,

              'invited_by': inviterId,

              'invited_user_id': normalizedInvitedUserId,

              'status': 'pending',
            },
          )
          .select(
            'id, project_id, invited_by, invited_user_id, status',
          )
          .single();

      final invitationId = inserted['id']?.toString().trim();

      debugPrint(
        '[MATCH TEAM EXPANSION] '
        'Convite criado. '
        'ID: ${invitationId ?? 'n/a'} | '
        '$inviterId -> '
        '$normalizedInvitedUserId',
      );

      return MatchTeamInvitationResult(
        status: MatchTeamInvitationStatus.invited,
        projectId: normalizedProjectId,
        invitedUserId: normalizedInvitedUserId,
        invitationId: invitationId,
      );
    } on PostgrestException catch (
      error,
      stackTrace
    ) {
      // ========================================================
      // UNIQUE / RACE CONDITION
      // ========================================================
      //
      // Outro processo pode criar o mesmo convite entre nossa
      // consulta e o INSERT.
      //
      // Nesse caso buscamos novamente.
      //
      // ========================================================

      if (error.code ==
          '23505') {
        final existing = await _findPendingInvitation(
          projectId: normalizedProjectId,
          invitedUserId: normalizedInvitedUserId,
        );

        if (existing !=
            null) {
          return MatchTeamInvitationResult(
            status: MatchTeamInvitationStatus.alreadyPending,
            projectId: normalizedProjectId,
            invitedUserId: normalizedInvitedUserId,
            invitationId: existing['id']?.toString(),
          );
        }
      }

      debugPrint(
        '[MATCH TEAM EXPANSION] '
        'Erro Supabase ao criar convite: '
        '${error.message}',
      );

      debugPrint(
        '[MATCH TEAM EXPANSION] '
        'Código: ${error.code}',
      );

      debugPrint(
        '[MATCH TEAM EXPANSION] '
        'Detalhes: ${error.details}',
      );

      debugPrint(
        '$stackTrace',
      );

      rethrow;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[MATCH TEAM EXPANSION] '
        'Erro ao criar convite: '
        '$error',
      );

      debugPrint(
        '$stackTrace',
      );

      rethrow;
    }
  }

  // ============================================================
  // HAS PENDING INVITATION
  // ============================================================

  Future<
    bool
  >
  hasPendingInvitation({
    required String projectId,
    required String invitedUserId,
  }) async {
    final normalizedProjectId = projectId.trim();

    final normalizedInvitedUserId = invitedUserId.trim();

    if (normalizedProjectId.isEmpty ||
        normalizedInvitedUserId.isEmpty) {
      return false;
    }

    final invitation = await _findPendingInvitation(
      projectId: normalizedProjectId,
      invitedUserId: normalizedInvitedUserId,
    );

    return invitation !=
        null;
  }

  // ============================================================
  // FIND PENDING INVITATION
  // ============================================================

  Future<
    Map<
      String,
      dynamic
    >?
  >
  _findPendingInvitation({
    required String projectId,
    required String invitedUserId,
  }) async {
    final response = await _supabase
        .from(
          'project_invitations',
        )
        .select(
          'id, project_id, invited_by, invited_user_id, status',
        )
        .eq(
          'project_id',
          projectId,
        )
        .eq(
          'invited_user_id',
          invitedUserId,
        )
        .eq(
          'status',
          'pending',
        )
        .maybeSingle();

    if (response ==
        null) {
      return null;
    }

    return Map<
      String,
      dynamic
    >.from(
      response,
    );
  }

  // ============================================================
  // AUTHENTICATED USER
  // ============================================================

  String _requireAuthenticatedUserId() {
    final userId = currentUserId;

    if (userId ==
        null) {
      throw StateError(
        'Usuário não autenticado.',
      );
    }

    return userId;
  }

  // ============================================================
  // READ STRING SET
  // ============================================================

  Set<
    String
  >
  _readStringSet(
    dynamic raw,
  ) {
    final result =
        <
          String
        >{};

    if (raw
        is Iterable) {
      for (final value in raw) {
        final normalized = value?.toString().trim();

        if (normalized !=
                null &&
            normalized.isNotEmpty) {
          result.add(
            normalized,
          );
        }
      }
    }

    return result;
  }
}
