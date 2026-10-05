import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:versin/modules/networking/call/data/repositories/project_call_repository_impl.dart';
import 'package:versin/modules/profile/services/profile_name_cache_service.dart';

// ============================================================
// DASHBOARD GLOBAL CALL SERVICE
// ============================================================
//
// Responsabilidade:
//
// - observar chamadas globais;
// - filtrar chamadas relevantes para o usuário;
// - aceitar chamada;
// - recusar chamada;
// - encerrar chamada;
// - resolver nome do outro participante.
//
// Não contém:
//
// - Widgets;
// - Navigator;
// - ScaffoldMessenger;
// - estado visual.
//
// ============================================================

class DashboardGlobalCallService {
  // ============================================================
  // DEPENDÊNCIAS
  // ============================================================

  final SupabaseClient _supabase;

  final ProjectCallRepositoryImpl _callRepository;

  final ProfileNameCacheService _profileNameCacheService;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  DashboardGlobalCallService({
    SupabaseClient? supabase,
    ProjectCallRepositoryImpl? callRepository,
    ProfileNameCacheService? profileNameCacheService,
  }) : _supabase =
           supabase ??
           Supabase.instance.client,
       _callRepository =
           callRepository ??
           ProjectCallRepositoryImpl(),
       _profileNameCacheService =
           profileNameCacheService ??
           ProfileNameCacheService();

  // ============================================================
  // CURRENT USER ID
  // ============================================================

  String? get currentUserId {
    final value = _supabase.auth.currentUser?.id.trim();

    if (value ==
            null ||
        value.isEmpty) {
      return null;
    }

    return value;
  }

  // ============================================================
  // WATCH CALLS
  // ============================================================

  Stream<
    List<
      Map<
        String,
        dynamic
      >
    >
  >
  watchCalls() {
    return _supabase
        .from(
          'project_calls',
        )
        .stream(
          primaryKey: [
            'id',
          ],
        )
        .order(
          'created_at',
          ascending: false,
        );
  }

  // ============================================================
  // FIND ACTIVE CALL
  // ============================================================

  Map<
    String,
    dynamic
  >?
  findActiveCall({
    required List<
      Map<
        String,
        dynamic
      >
    >
    rows,
    required String currentUserId,
  }) {
    final normalizedCurrentUserId = currentUserId.trim();

    if (normalizedCurrentUserId.isEmpty) {
      return null;
    }

    for (final row in rows) {
      final status = row['status']?.toString().trim();

      if (status !=
              'ringing' &&
          status !=
              'active') {
        continue;
      }

      final createdBy = row['created_by']?.toString().trim();

      final targetUserId = row['target_user_id']?.toString().trim();

      final directlyInvolved =
          createdBy ==
              normalizedCurrentUserId ||
          targetUserId ==
              normalizedCurrentUserId;

      final groupCall =
          targetUserId ==
              null ||
          targetUserId.isEmpty;

      if (!directlyInvolved &&
          !groupCall) {
        continue;
      }

      return row;
    }

    return null;
  }

  // ============================================================
  // ACCEPT CALL
  // ============================================================

  Future<
    void
  >
  acceptCall({
    required String callId,
  }) async {
    final normalizedCallId = callId.trim();

    if (normalizedCallId.isEmpty) {
      return;
    }

    await _callRepository.acceptCall(
      callId: normalizedCallId,
    );
  }

  // ============================================================
  // REJECT CALL
  // ============================================================

  Future<
    void
  >
  rejectCall({
    required String callId,
  }) async {
    final normalizedCallId = callId.trim();

    if (normalizedCallId.isEmpty) {
      return;
    }

    await _callRepository.rejectCall(
      callId: normalizedCallId,
    );
  }

  // ============================================================
  // END CALL
  // ============================================================

  Future<
    void
  >
  endCall({
    required String callId,
  }) async {
    final normalizedCallId = callId.trim();

    if (normalizedCallId.isEmpty) {
      return;
    }

    await _callRepository.endCall(
      callId: normalizedCallId,
    );
  }

  // ============================================================
  // RESOLVE PARTICIPANT USER ID
  // ============================================================

  String resolveParticipantUserId({
    required String createdBy,
    required String? targetUserId,
    required String currentUserId,
  }) {
    final normalizedCreatedBy = createdBy.trim();

    final normalizedTargetUserId = targetUserId?.trim();

    final normalizedCurrentUserId = currentUserId.trim();

    // ========================================================
    // EU CRIEI A CHAMADA
    // ========================================================

    if (normalizedCreatedBy ==
        normalizedCurrentUserId) {
      if (normalizedTargetUserId !=
              null &&
          normalizedTargetUserId.isNotEmpty) {
        return normalizedTargetUserId;
      }

      return '';
    }

    // ========================================================
    // OUTRO USUÁRIO CRIOU A CHAMADA
    // ========================================================

    return normalizedCreatedBy;
  }

  // ============================================================
  // RESOLVE PARTICIPANT NAME
  // ============================================================

  Future<
    String
  >
  resolveParticipantName(
    String userId,
  ) async {
    final normalizedUserId = userId.trim();

    if (normalizedUserId.isEmpty) {
      return 'Membro da sessão';
    }

    try {
      final resolvedName = await _profileNameCacheService.getName(
        normalizedUserId,
      );

      final normalizedName = resolvedName.trim();

      if (normalizedName.isNotEmpty &&
          normalizedName !=
              'Membro') {
        return normalizedName;
      }
    } catch (
      error,
      stackTrace
    ) {
      print(
        '[DASHBOARD GLOBAL CALL SERVICE] '
        'Erro ao resolver participante: '
        '$error',
      );

      print(
        stackTrace,
      );
    }

    return 'Membro da sessão';
  }
}
