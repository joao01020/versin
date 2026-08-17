import 'package:supabase_flutter/supabase_flutter.dart';

import '../../repositories/communication_permission_repository.dart';

import '../models/communication_permission_model.dart';
import '../models/communication_request_model.dart';

// ============================================================
// COMMUNICATION PERMISSION REPOSITORY IMPLEMENTATION
// ============================================================
//
// Implementação Supabase de:
//
// CommunicationPermissionRepository
//
// Responsável por:
//
// - consultar permissões;
// - acompanhar permissões via Realtime;
// - consultar pedidos;
// - acompanhar pedidos via Realtime;
// - solicitar desbloqueio de vídeo;
// - aceitar desbloqueio;
// - recusar desbloqueio;
// - verificar autorização de áudio/vídeo.
//
// Regras críticas de segurança ficam no PostgreSQL:
//
// - RLS;
// - RPC;
// - validação do usuário autenticado;
// - validação de participação no projeto.
//
// ============================================================

class CommunicationPermissionRepositoryImpl
    implements
        CommunicationPermissionRepository {
  // ==========================================================
  // TABLES
  // ==========================================================

  static const String _permissionsTable = 'project_member_permissions';

  static const String _requestsTable = 'communication_requests';

  // ==========================================================
  // RPC
  // ==========================================================

  static const String _requestVideoRpc = 'request_project_video_permission';

  static const String _respondVideoRpc = 'respond_project_video_permission';

  // ==========================================================
  // SUPABASE
  // ==========================================================

  final SupabaseClient _supabase;

  // ==========================================================
  // CONSTRUCTOR
  // ==========================================================

  CommunicationPermissionRepositoryImpl({
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
  // GET PERMISSION
  // ==========================================================

  @override
  Future<
    CommunicationPermissionModel?
  >
  getPermission({
    required String projectId,
    required String userId,
  }) async {
    final normalizedProjectId = _required(
      projectId,
      'projectId',
    );

    final normalizedUserId = _required(
      userId,
      'userId',
    );

    final response = await _supabase
        .from(
          _permissionsTable,
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

    if (response ==
        null) {
      return null;
    }

    return CommunicationPermissionModel.fromMap(
      Map<
        String,
        dynamic
      >.from(
        response,
      ),
    );
  }

  // ==========================================================
  // GET CURRENT USER PERMISSION
  // ==========================================================

  @override
  Future<
    CommunicationPermissionModel?
  >
  getCurrentUserPermission({
    required String projectId,
  }) {
    return getPermission(
      projectId: projectId,

      userId: currentUserId,
    );
  }

  // ==========================================================
  // GET PROJECT PERMISSIONS
  // ==========================================================

  @override
  Future<
    List<
      CommunicationPermissionModel
    >
  >
  getProjectPermissions({
    required String projectId,
  }) async {
    final normalizedProjectId = _required(
      projectId,
      'projectId',
    );

    final response = await _supabase
        .from(
          _permissionsTable,
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

    return response
        .map(
          (
            item,
          ) => CommunicationPermissionModel.fromMap(
            Map<
              String,
              dynamic
            >.from(
              item,
            ),
          ),
        )
        .toList(
          growable: false,
        );
  }

  // ==========================================================
  // STREAM PROJECT PERMISSIONS
  // ==========================================================

  @override
  Stream<
    List<
      CommunicationPermissionModel
    >
  >
  streamProjectPermissions({
    required String projectId,
  }) {
    final normalizedProjectId = _required(
      projectId,
      'projectId',
    );

    return _supabase
        .from(
          _permissionsTable,
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
          ascending: true,
        )
        .map(
          (
            rows,
          ) => rows
              .map(
                (
                  row,
                ) => CommunicationPermissionModel.fromMap(
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
              ),
        );
  }

  // ==========================================================
  // GET REQUEST
  // ==========================================================

  @override
  Future<
    CommunicationRequestModel?
  >
  getRequestById({
    required String requestId,
  }) async {
    final normalizedRequestId = _required(
      requestId,
      'requestId',
    );

    final response = await _supabase
        .from(
          _requestsTable,
        )
        .select()
        .eq(
          'id',
          normalizedRequestId,
        )
        .maybeSingle();

    if (response ==
        null) {
      return null;
    }

    return CommunicationRequestModel.fromMap(
      Map<
        String,
        dynamic
      >.from(
        response,
      ),
    );
  }

  // ==========================================================
  // GET PROJECT REQUESTS
  // ==========================================================

  @override
  Future<
    List<
      CommunicationRequestModel
    >
  >
  getProjectRequests({
    required String projectId,
  }) async {
    final normalizedProjectId = _required(
      projectId,
      'projectId',
    );

    final response = await _supabase
        .from(
          _requestsTable,
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

    return response
        .map(
          (
            item,
          ) => CommunicationRequestModel.fromMap(
            Map<
              String,
              dynamic
            >.from(
              item,
            ),
          ),
        )
        .toList(
          growable: false,
        );
  }

  // ==========================================================
  // GET RECEIVED REQUESTS
  // ==========================================================

  @override
  Future<
    List<
      CommunicationRequestModel
    >
  >
  getReceivedRequests({
    required String projectId,
  }) async {
    final normalizedProjectId = _required(
      projectId,
      'projectId',
    );

    final response = await _supabase
        .from(
          _requestsTable,
        )
        .select()
        .eq(
          'project_id',
          normalizedProjectId,
        )
        .eq(
          'target_user_id',
          currentUserId,
        )
        .eq(
          'status',
          'pending',
        )
        .order(
          'created_at',
          ascending: false,
        );

    return response
        .map(
          (
            item,
          ) => CommunicationRequestModel.fromMap(
            Map<
              String,
              dynamic
            >.from(
              item,
            ),
          ),
        )
        .toList(
          growable: false,
        );
  }

  // ==========================================================
  // STREAM RECEIVED REQUESTS
  // ==========================================================

  @override
  Stream<
    List<
      CommunicationRequestModel
    >
  >
  streamReceivedRequests({
    required String projectId,
  }) {
    final normalizedProjectId = _required(
      projectId,
      'projectId',
    );

    final userId = currentUserId;

    return _supabase
        .from(
          _requestsTable,
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
            final requests = rows
                .where(
                  (
                    row,
                  ) {
                    final targetId = row['target_user_id']?.toString().trim();

                    final status = row['status']?.toString().trim().toLowerCase();

                    return targetId ==
                            userId &&
                        status ==
                            'pending';
                  },
                )
                .map(
                  (
                    row,
                  ) => CommunicationRequestModel.fromMap(
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

            return requests;
          },
        );
  }

  // ==========================================================
  // REQUEST VIDEO
  // ==========================================================

  @override
  Future<
    CommunicationRequestModel
  >
  requestVideo({
    required String projectId,
    required String targetUserId,
  }) async {
    final normalizedProjectId = _required(
      projectId,
      'projectId',
    );

    final normalizedTargetUserId = _required(
      targetUserId,
      'targetUserId',
    );

    final userId = currentUserId;

    // ========================================================
    // NÃO PODE SOLICITAR PARA SI MESMO
    // ========================================================

    if (normalizedTargetUserId ==
        userId) {
      throw ArgumentError(
        'Não é possível solicitar vídeo para si mesmo.',
      );
    }

    // ========================================================
    // RPC
    // ========================================================

    final response = await _supabase.rpc(
      _requestVideoRpc,

      params: {
        'p_project_id': normalizedProjectId,

        'p_target_user_id': normalizedTargetUserId,
      },
    );

    return CommunicationRequestModel.fromMap(
      _extractSingleMap(
        response,

        operation: 'solicitar permissão de vídeo',
      ),
    );
  }

  // ==========================================================
  // ACCEPT VIDEO REQUEST
  // ==========================================================

  @override
  Future<
    CommunicationRequestModel
  >
  acceptVideoRequest({
    required String requestId,
  }) {
    return _respondVideoRequest(
      requestId: requestId,

      accepted: true,
    );
  }

  // ==========================================================
  // REJECT VIDEO REQUEST
  // ==========================================================

  @override
  Future<
    CommunicationRequestModel
  >
  rejectVideoRequest({
    required String requestId,
  }) {
    return _respondVideoRequest(
      requestId: requestId,

      accepted: false,
    );
  }

  // ==========================================================
  // RESPOND VIDEO REQUEST
  // ==========================================================

  Future<
    CommunicationRequestModel
  >
  _respondVideoRequest({
    required String requestId,
    required bool accepted,
  }) async {
    final normalizedRequestId = _required(
      requestId,
      'requestId',
    );

    final response = await _supabase.rpc(
      _respondVideoRpc,

      params: {
        'p_request_id': normalizedRequestId,

        'p_accept': accepted,
      },
    );

    return CommunicationRequestModel.fromMap(
      _extractSingleMap(
        response,

        operation: accepted
            ? 'aceitar permissão de vídeo'
            : 'recusar permissão de vídeo',
      ),
    );
  }

  // ==========================================================
  // VIDEO ALLOWED
  // ==========================================================

  @override
  Future<
    bool
  >
  isVideoAllowed({
    required String projectId,
    required String userId,
  }) async {
    final permission = await getPermission(
      projectId: projectId,

      userId: userId,
    );

    return permission?.videoAllowed ??
        false;
  }

  // ==========================================================
  // AUDIO ALLOWED
  // ==========================================================

  @override
  Future<
    bool
  >
  isAudioAllowed({
    required String projectId,
    required String userId,
  }) async {
    final permission = await getPermission(
      projectId: projectId,

      userId: userId,
    );

    return permission?.audioAllowed ??
        false;
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
    // MAP DIRETO
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
    // LISTA COM UMA LINHA
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

    // ========================================================
    // RESPOSTA INVÁLIDA
    // ========================================================

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
}
