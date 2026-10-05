import 'package:supabase_flutter/supabase_flutter.dart';

import '../../repositories/project_call_repository.dart';
import '../../types/call_media_type.dart';

import '../models/project_call_model.dart';

// ============================================================
// PROJECT CALL REPOSITORY IMPLEMENTATION
// ============================================================
//
// Implementação Supabase de:
//
// ProjectCallRepository
//
// Responsável por:
//
// - criar chamada;
// - consultar chamada;
// - consultar chamadas do projeto;
// - acompanhar chamadas em Realtime;
// - aceitar chamada;
// - recusar chamada;
// - encerrar chamada;
// - consultar chamada ativa.
//
// NÃO é responsabilidade deste repository:
//
// - câmera;
// - microfone;
// - WebRTC;
// - SDP;
// - ICE;
// - consentimento de vídeo;
// - cooldown de convite.
//
// Essas responsabilidades ficam em:
//
// CommunicationPermissionRepository
// CallSignalingService
// WebRtcCallService
//
// ============================================================

class ProjectCallRepositoryImpl
    implements
        ProjectCallRepository {
  // ==========================================================
  // TABLE
  // ==========================================================

  static const String _table = 'project_calls';

  // ==========================================================
  // RPCs
  // ==========================================================

  static const String _createCallRpc = 'create_project_call';

  static const String _respondCallRpc = 'respond_project_call';

  static const String _endCallRpc = 'end_project_call';

  // ==========================================================
  // SUPABASE
  // ==========================================================

  final SupabaseClient _supabase;

  // ==========================================================
  // CONSTRUCTOR
  // ==========================================================

  ProjectCallRepositoryImpl({
    SupabaseClient? supabase,
  }) : _supabase =
           supabase ??
           Supabase.instance.client;

  // ==========================================================
  // CURRENT USER
  // ==========================================================

  @override
  String get currentUserId {
    final userId = _supabase.auth.currentUser?.id.trim();

    if (userId ==
            null ||
        userId.isEmpty) {
      throw StateError(
        'Usuário não autenticado.',
      );
    }

    return userId;
  }

  // ==========================================================
  // GET CALL BY ID
  // ==========================================================

  @override
  Future<
    ProjectCallModel?
  >
  getCallById({
    required String callId,
  }) async {
    final normalizedCallId = _required(
      callId,
      'callId',
    );

    final response = await _supabase
        .from(
          _table,
        )
        .select()
        .eq(
          'id',
          normalizedCallId,
        )
        .maybeSingle();

    if (response ==
        null) {
      return null;
    }

    return ProjectCallModel.fromMap(
      Map<
        String,
        dynamic
      >.from(
        response,
      ),
    );
  }

  // ==========================================================
  // GET PROJECT CALLS
  // ==========================================================

  @override
  Future<
    List<
      ProjectCallModel
    >
  >
  getProjectCalls({
    required String projectId,
  }) async {
    final normalizedProjectId = _required(
      projectId,
      'projectId',
    );

    final response = await _supabase
        .from(
          _table,
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

    return _mapCalls(
      response,
    );
  }

  // ==========================================================
  // GET ACTIVE CALL
  // ==========================================================

  @override
  Future<
    ProjectCallModel?
  >
  getActiveCall({
    required String projectId,
  }) async {
    final normalizedProjectId = _required(
      projectId,
      'projectId',
    );

    final response = await _supabase
        .from(
          _table,
        )
        .select()
        .eq(
          'project_id',
          normalizedProjectId,
        )
        .inFilter(
          'status',
          [
            'ringing',
            'active',
          ],
        )
        .order(
          'created_at',
          ascending: false,
        )
        .limit(
          1,
        )
        .maybeSingle();

    if (response ==
        null) {
      return null;
    }

    return ProjectCallModel.fromMap(
      Map<
        String,
        dynamic
      >.from(
        response,
      ),
    );
  }

  // ==========================================================
  // STREAM PROJECT CALLS
  // ==========================================================

  @override
  Stream<
    List<
      ProjectCallModel
    >
  >
  streamProjectCalls({
    required String projectId,
  }) {
    final normalizedProjectId = _required(
      projectId,
      'projectId',
    );

    return _supabase
        .from(
          _table,
        )
        .stream(
          primaryKey: [
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
            return rows
                .map(
                  (
                    row,
                  ) => ProjectCallModel.fromMap(
                    Map<
                      String,
                      dynamic
                    >.from(
                      row,
                    ),
                  ),
                )
                .toList(
                  growable: false,
                );
          },
        );
  }

  // ==========================================================
  // STREAM CALL
  // ==========================================================

  @override
  Stream<
    ProjectCallModel?
  >
  streamCall({
    required String callId,
  }) {
    final normalizedCallId = _required(
      callId,
      'callId',
    );

    return _supabase
        .from(
          _table,
        )
        .stream(
          primaryKey: [
            'id',
          ],
        )
        .eq(
          'id',
          normalizedCallId,
        )
        .map(
          (
            rows,
          ) {
            if (rows.isEmpty) {
              return null;
            }

            return ProjectCallModel.fromMap(
              Map<
                String,
                dynamic
              >.from(
                rows.first,
              ),
            );
          },
        );
  }

  // ==========================================================
  // CREATE CALL
  // ==========================================================

  @override
  Future<
    ProjectCallModel
  >
  createCall({
    required String projectId,
    required CallMediaType mediaType,
    String? targetUserId,
  }) async {
    final normalizedProjectId = _required(
      projectId,
      'projectId',
    );

    final normalizedTargetUserId = _nullable(
      targetUserId,
    );

    final userId = currentUserId;

    // ========================================================
    // SELF
    // ========================================================

    if (normalizedTargetUserId ==
        userId) {
      throw ArgumentError(
        'Não é possível iniciar uma chamada para si mesmo.',
      );
    }

    // ========================================================
    // RPC
    // ========================================================
    //
    // A RPC valida:
    //
    // - membership;
    // - chamada já existente;
    // - target;
    // - permissão bilateral para chamada direta de vídeo.
    //
    // ========================================================

    final response = await _supabase.rpc(
      _createCallRpc,

      params: {
        'p_project_id': normalizedProjectId,

        'p_media_type': mediaType.value,

        'p_target_user_id': normalizedTargetUserId,
      },
    );

    return ProjectCallModel.fromMap(
      _extractSingleMap(
        response,

        operation: 'criar chamada',
      ),
    );
  }

  // ==========================================================
  // ACCEPT CALL
  // ==========================================================

  @override
  Future<
    ProjectCallModel
  >
  acceptCall({
    required String callId,
  }) {
    return _respondCall(
      callId: callId,

      accepted: true,
    );
  }

  // ==========================================================
  // REJECT CALL
  // ==========================================================

  @override
  Future<
    ProjectCallModel
  >
  rejectCall({
    required String callId,
  }) {
    return _respondCall(
      callId: callId,

      accepted: false,
    );
  }

  // ==========================================================
  // RESPOND CALL
  // ==========================================================

  Future<
    ProjectCallModel
  >
  _respondCall({
    required String callId,
    required bool accepted,
  }) async {
    final normalizedCallId = _required(
      callId,
      'callId',
    );

    final response = await _supabase.rpc(
      _respondCallRpc,

      params: {
        'p_call_id': normalizedCallId,

        'p_accept': accepted,
      },
    );

    return ProjectCallModel.fromMap(
      _extractSingleMap(
        response,

        operation: accepted
            ? 'aceitar chamada'
            : 'recusar chamada',
      ),
    );
  }

  // ==========================================================
  // END CALL
  // ==========================================================

  @override
  Future<
    ProjectCallModel
  >
  endCall({
    required String callId,
  }) async {
    final normalizedCallId = _required(
      callId,
      'callId',
    );

    final response = await _supabase.rpc(
      _endCallRpc,

      params: {
        'p_call_id': normalizedCallId,
      },
    );

    return ProjectCallModel.fromMap(
      _extractSingleMap(
        response,

        operation: 'encerrar chamada',
      ),
    );
  }

  // ==========================================================
  // HAS ACTIVE CALL
  // ==========================================================

  @override
  Future<
    bool
  >
  hasActiveCall({
    required String projectId,
  }) async {
    final call = await getActiveCall(
      projectId: projectId,
    );

    return call !=
        null;
  }

  // ==========================================================
  // MAP CALLS
  // ==========================================================

  List<
    ProjectCallModel
  >
  _mapCalls(
    List<
      dynamic
    >
    response,
  ) {
    return response
        .map(
          (
            item,
          ) => ProjectCallModel.fromMap(
            Map<
              String,
              dynamic
            >.from(
              item
                  as Map,
            ),
          ),
        )
        .toList(
          growable: false,
        );
  }

  // ==========================================================
  // EXTRACT RPC RESPONSE
  // ==========================================================

  Map<
    String,
    dynamic
  >
  _extractSingleMap(
    dynamic response, {
    required String operation,
  }) {
    // ========================================================
    // MAP
    // ========================================================

    if (response
        is Map) {
      return Map<
        String,
        dynamic
      >.from(
        response,
      );
    }

    // ========================================================
    // LIST
    // ========================================================

    if (response
            is List &&
        response.isNotEmpty) {
      final first = response.first;

      if (first
          is Map) {
        return Map<
          String,
          dynamic
        >.from(
          first,
        );
      }
    }

    throw StateError(
      'Resposta inválida do Supabase ao $operation.',
    );
  }

  // ==========================================================
  // REQUIRED
  // ==========================================================

  String _required(
    String value,
    String field,
  ) {
    final normalized = value.trim();

    if (normalized.isEmpty) {
      throw ArgumentError(
        '$field não pode ser vazio.',
      );
    }

    return normalized;
  }

  // ==========================================================
  // NULLABLE
  // ==========================================================

  String? _nullable(
    String? value,
  ) {
    final normalized = value?.trim();

    if (normalized ==
            null ||
        normalized.isEmpty) {
      return null;
    }

    return normalized;
  }
}
