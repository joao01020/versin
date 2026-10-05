import 'package:supabase_flutter/supabase_flutter.dart';

import '../../repositories/communication_permission_repository.dart';

import '../models/communication_permission_model.dart';
import '../models/communication_request_model.dart';
import '../models/communication_video_invite_state_model.dart';

// ============================================================
// COMMUNICATION PERMISSION REPOSITORY IMPLEMENTATION
// ============================================================
//
// Implementação Supabase de:
//
// CommunicationPermissionRepository
//
// MODELO DE VÍDEO
// ------------------------------------------------------------
//
// Permissão:
//
// usuário A <-> usuário B
//
// Estado de convite:
//
// requester -> target
//
// Isso permite:
//
// 1ª recusa
// -> cooldown 2 dias
//
// 2ª recusa
// -> cooldown 4 dias
//
// 3ª recusa
// -> bloqueio
//
// Depois da terceira recusa:
//
// somente o target pode permitir uma nova tentativa.
//
// ============================================================

class CommunicationPermissionRepositoryImpl
    implements
        CommunicationPermissionRepository {
  // ==========================================================
  // TABLES
  // ==========================================================

  static const String _permissionsTable = 'communication_video_permissions';

  static const String _inviteStatesTable = 'communication_video_invite_states';

  static const String _requestsTable = 'communication_requests';

  // ==========================================================
  // RPCs
  // ==========================================================

  static const String _requestVideoRpc = 'request_project_video';

  static const String _requestVideoBulkRpc = 'request_project_video_bulk';

  static const String _respondVideoRpc = 'respond_project_video_request';

  static const String _canUseVideoRpc = 'can_use_project_video_with';

  static const String _allowVideoInvitesFromRpc = 'allow_video_invites_from';

  static const String _revokeVideoPermissionRpc = 'revoke_project_video_permission';

  static const String _isProjectMemberRpc = 'is_project_member';

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

    final otherUserId = _required(
      userId,
      'userId',
    );

    final authenticatedUserId = currentUserId;

    if (otherUserId ==
        authenticatedUserId) {
      return null;
    }

    final pair = _canonicalPair(
      authenticatedUserId,
      otherUserId,
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
          'user_a_id',
          pair.$1,
        )
        .eq(
          'user_b_id',
          pair.$2,
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
  }) async {
    final normalizedProjectId = _required(
      projectId,
      'projectId',
    );

    final userId = currentUserId;

    final response = await _supabase
        .from(
          _permissionsTable,
        )
        .select()
        .eq(
          'project_id',
          normalizedProjectId,
        )
        .or(
          'user_a_id.eq.$userId,user_b_id.eq.$userId',
        )
        .order(
          'created_at',
          ascending: true,
        )
        .limit(
          1,
        );

    if (response.isEmpty) {
      return null;
    }

    return CommunicationPermissionModel.fromMap(
      Map<
        String,
        dynamic
      >.from(
        response.first,
      ),
    );
  }

  // ==========================================================
  // PROJECT PERMISSIONS
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
          ) {
            return rows
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
                );
          },
        );
  }

  // ==========================================================
  // GET VIDEO INVITE STATE
  // ==========================================================

  @override
  Future<
    CommunicationVideoInviteStateModel?
  >
  getVideoInviteState({
    required String projectId,
    required String targetUserId,
  }) {
    return getVideoInviteStateByDirection(
      projectId: projectId,

      requesterId: currentUserId,

      targetUserId: targetUserId,
    );
  }

  // ==========================================================
  // GET VIDEO INVITE STATE BY DIRECTION
  // ==========================================================

  @override
  Future<
    CommunicationVideoInviteStateModel?
  >
  getVideoInviteStateByDirection({
    required String projectId,
    required String requesterId,
    required String targetUserId,
  }) async {
    final normalizedProjectId = _required(
      projectId,
      'projectId',
    );

    final normalizedRequesterId = _required(
      requesterId,
      'requesterId',
    );

    final normalizedTargetUserId = _required(
      targetUserId,
      'targetUserId',
    );

    if (normalizedRequesterId ==
        normalizedTargetUserId) {
      return null;
    }

    final response = await _supabase
        .from(
          _inviteStatesTable,
        )
        .select()
        .eq(
          'project_id',
          normalizedProjectId,
        )
        .eq(
          'requester_id',
          normalizedRequesterId,
        )
        .eq(
          'target_user_id',
          normalizedTargetUserId,
        )
        .maybeSingle();

    if (response ==
        null) {
      return null;
    }

    return CommunicationVideoInviteStateModel.fromMap(
      Map<
        String,
        dynamic
      >.from(
        response,
      ),
    );
  }

  // ==========================================================
  // GET PROJECT VIDEO INVITE STATES
  // ==========================================================

  @override
  Future<
    List<
      CommunicationVideoInviteStateModel
    >
  >
  getProjectVideoInviteStates({
    required String projectId,
  }) async {
    final normalizedProjectId = _required(
      projectId,
      'projectId',
    );

    final response = await _supabase
        .from(
          _inviteStatesTable,
        )
        .select()
        .eq(
          'project_id',
          normalizedProjectId,
        )
        .order(
          'updated_at',
          ascending: false,
        );

    return response
        .map(
          (
            item,
          ) => CommunicationVideoInviteStateModel.fromMap(
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
  // STREAM PROJECT VIDEO INVITE STATES
  // ==========================================================

  @override
  Stream<
    List<
      CommunicationVideoInviteStateModel
    >
  >
  streamProjectVideoInviteStates({
    required String projectId,
  }) {
    final normalizedProjectId = _required(
      projectId,
      'projectId',
    );

    return _supabase
        .from(
          _inviteStatesTable,
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
          'updated_at',
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
                  ) => CommunicationVideoInviteStateModel.fromMap(
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
  // ALLOW VIDEO INVITES FROM
  // ==========================================================

  @override
  Future<
    CommunicationVideoInviteStateModel
  >
  allowVideoInvitesFrom({
    required String projectId,
    required String requesterId,
  }) async {
    final normalizedProjectId = _required(
      projectId,
      'projectId',
    );

    final normalizedRequesterId = _required(
      requesterId,
      'requesterId',
    );

    if (normalizedRequesterId ==
        currentUserId) {
      throw ArgumentError(
        'Você não pode liberar convites para si mesmo.',
      );
    }

    final response = await _supabase.rpc(
      _allowVideoInvitesFromRpc,

      params: {
        'p_project_id': normalizedProjectId,

        'p_requester_id': normalizedRequesterId,
      },
    );

    return CommunicationVideoInviteStateModel.fromMap(
      _extractSingleMap(
        response,

        operation: 'liberar nova tentativa de convite',
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

    return _mapRequests(
      response,
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

    final userId = currentUserId;

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
          userId,
        )
        .eq(
          'status',
          'pending',
        )
        .order(
          'created_at',
          ascending: false,
        );

    return _mapRequests(
      response,
    );
  }

  // ==========================================================
  // GET SENT REQUESTS
  // ==========================================================

  @override
  Future<
    List<
      CommunicationRequestModel
    >
  >
  getSentRequests({
    required String projectId,
  }) async {
    final normalizedProjectId = _required(
      projectId,
      'projectId',
    );

    final userId = currentUserId;

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
          'sender_id',
          userId,
        )
        .order(
          'created_at',
          ascending: false,
        );

    return _mapRequests(
      response,
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
            return rows
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
          },
        );
  }

  // ==========================================================
  // STREAM SENT REQUESTS
  // ==========================================================

  @override
  Stream<
    List<
      CommunicationRequestModel
    >
  >
  streamSentRequests({
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
            return rows
                .where(
                  (
                    row,
                  ) {
                    final senderId = row['sender_id']?.toString().trim();

                    return senderId ==
                        userId;
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
  }) {
    return _requestVideo(
      projectId: projectId,

      targetUserId: targetUserId,

      callId: null,

      requestType: 'video_unlock',
    );
  }

  // ==========================================================
  // REQUEST VIDEO UPGRADE
  // ==========================================================

  @override
  Future<
    CommunicationRequestModel
  >
  requestVideoUpgrade({
    required String projectId,
    required String targetUserId,
    required String callId,
  }) {
    return _requestVideo(
      projectId: projectId,

      targetUserId: targetUserId,

      callId: _required(
        callId,
        'callId',
      ),

      requestType: 'video_upgrade',
    );
  }

  // ==========================================================
  // INTERNAL REQUEST VIDEO
  // ==========================================================

  Future<
    CommunicationRequestModel
  >
  _requestVideo({
    required String projectId,
    required String targetUserId,
    required String? callId,
    required String requestType,
  }) async {
    final normalizedProjectId = _required(
      projectId,
      'projectId',
    );

    final normalizedTargetUserId = _required(
      targetUserId,
      'targetUserId',
    );

    if (normalizedTargetUserId ==
        currentUserId) {
      throw ArgumentError(
        'Não é possível solicitar vídeo para si mesmo.',
      );
    }

    final response = await _supabase.rpc(
      _requestVideoRpc,

      params: {
        'p_project_id': normalizedProjectId,

        'p_target_user_id': normalizedTargetUserId,

        'p_call_id': callId,

        'p_request_type': requestType,
      },
    );

    return CommunicationRequestModel.fromMap(
      _extractSingleMap(
        response,

        operation:
            requestType ==
                'video_upgrade'
            ? 'solicitar upgrade para vídeo'
            : 'solicitar permissão de vídeo',
      ),
    );
  }

  // ==========================================================
  // REQUEST VIDEO BULK
  // ==========================================================

  @override
  Future<
    List<
      VideoInviteBulkResult
    >
  >
  requestVideoBulk({
    required String projectId,
    required List<
      String
    >
    targetUserIds,
    String? callId,
    bool videoUpgrade = false,
  }) async {
    final normalizedProjectId = _required(
      projectId,
      'projectId',
    );

    final normalizedCallId = _nullable(
      callId,
    );

    final targets = targetUserIds
        .map(
          (
            item,
          ) => item.trim(),
        )
        .where(
          (
            item,
          ) =>
              item.isNotEmpty &&
              item !=
                  currentUserId,
        )
        .toSet()
        .toList(
          growable: false,
        );

    if (targets.isEmpty) {
      return const <
        VideoInviteBulkResult
      >[];
    }

    if (videoUpgrade &&
        normalizedCallId ==
            null) {
      throw ArgumentError(
        'callId é obrigatório para videoUpgrade.',
      );
    }

    final response = await _supabase.rpc(
      _requestVideoBulkRpc,

      params: {
        'p_project_id': normalizedProjectId,

        'p_target_user_ids': targets,

        'p_call_id': normalizedCallId,

        'p_request_type': videoUpgrade
            ? 'video_upgrade'
            : 'video_unlock',
      },
    );

    final rows = _extractList(
      response,

      operation: 'enviar convites de vídeo em lote',
    );

    return rows
        .map(
          (
            item,
          ) => VideoInviteBulkResult.fromMap(
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
  // REVOKE VIDEO PERMISSION
  // ==========================================================

  @override
  Future<
    CommunicationPermissionModel
  >
  revokeVideoPermission({
    required String projectId,
    required String otherUserId,
  }) async {
    final normalizedProjectId = _required(
      projectId,
      'projectId',
    );

    final normalizedOtherUserId = _required(
      otherUserId,
      'otherUserId',
    );

    if (normalizedOtherUserId ==
        currentUserId) {
      throw ArgumentError(
        'Não é possível revogar permissão consigo mesmo.',
      );
    }

    final response = await _supabase.rpc(
      _revokeVideoPermissionRpc,

      params: {
        'p_project_id': normalizedProjectId,

        'p_other_user_id': normalizedOtherUserId,
      },
    );

    return CommunicationPermissionModel.fromMap(
      _extractSingleMap(
        response,

        operation: 'revogar permissão de vídeo',
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
    final normalizedProjectId = _required(
      projectId,
      'projectId',
    );

    final otherUserId = _required(
      userId,
      'userId',
    );

    if (otherUserId ==
        currentUserId) {
      return false;
    }

    final response = await _supabase.rpc(
      _canUseVideoRpc,

      params: {
        'p_project_id': normalizedProjectId,

        'p_other_user_id': otherUserId,
      },
    );

    return _readRpcBool(
      response,
    );
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
    final normalizedProjectId = _required(
      projectId,
      'projectId',
    );

    final normalizedUserId = _required(
      userId,
      'userId',
    );

    final response = await _supabase.rpc(
      _isProjectMemberRpc,

      params: {
        'p_project_id': normalizedProjectId,

        'p_user_id': normalizedUserId,
      },
    );

    return _readRpcBool(
      response,
    );
  }

  // ==========================================================
  // MAP REQUESTS
  // ==========================================================

  List<
    CommunicationRequestModel
  >
  _mapRequests(
    List<
      dynamic
    >
    response,
  ) {
    return response
        .map(
          (
            item,
          ) => CommunicationRequestModel.fromMap(
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
  // READ RPC BOOL
  // ==========================================================

  bool _readRpcBool(
    dynamic response,
  ) {
    if (response
        is bool) {
      return response;
    }

    if (response
        is num) {
      return response !=
          0;
    }

    if (response
        is String) {
      final normalized = response.trim().toLowerCase();

      if (normalized ==
              'true' ||
          normalized ==
              '1') {
        return true;
      }

      if (normalized ==
              'false' ||
          normalized ==
              '0') {
        return false;
      }
    }

    if (response
            is List &&
        response.length ==
            1) {
      return _readRpcBool(
        response.first,
      );
    }

    if (response
            is Map &&
        response.length ==
            1) {
      return _readRpcBool(
        response.values.first,
      );
    }

    return false;
  }

  // ==========================================================
  // EXTRACT SINGLE MAP
  // ==========================================================

  Map<
    String,
    dynamic
  >
  _extractSingleMap(
    dynamic response, {
    required String operation,
  }) {
    if (response
        is Map) {
      return Map<
        String,
        dynamic
      >.from(
        response,
      );
    }

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
  // EXTRACT LIST
  // ==========================================================

  List<
    Map<
      String,
      dynamic
    >
  >
  _extractList(
    dynamic response, {
    required String operation,
  }) {
    if (response ==
        null) {
      return const <
        Map<
          String,
          dynamic
        >
      >[];
    }

    if (response
        is List) {
      return response
          .whereType<
            Map
          >()
          .map(
            (
              item,
            ) =>
                Map<
                  String,
                  dynamic
                >.from(
                  item,
                ),
          )
          .toList(
            growable: false,
          );
    }

    if (response
        is Map) {
      return [
        Map<
          String,
          dynamic
        >.from(
          response,
        ),
      ];
    }

    throw StateError(
      'Resposta inválida do Supabase ao $operation.',
    );
  }

  // ==========================================================
  // CANONICAL PAIR
  // ==========================================================

  (
    String,
    String,
  )
  _canonicalPair(
    String firstUserId,
    String secondUserId,
  ) {
    final first = _required(
      firstUserId,
      'firstUserId',
    );

    final second = _required(
      secondUserId,
      'secondUserId',
    );

    if (first ==
        second) {
      throw ArgumentError(
        'Os usuários do par precisam ser diferentes.',
      );
    }

    if (first.compareTo(
          second,
        ) <
        0) {
      return (
        first,
        second,
      );
    }

    return (
      second,
      first,
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
