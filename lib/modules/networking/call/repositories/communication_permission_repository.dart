import '../data/models/communication_permission_model.dart';
import '../data/models/communication_request_model.dart';
import '../data/models/communication_video_invite_state_model.dart';

// ============================================================
// COMMUNICATION PERMISSION REPOSITORY
// ============================================================
//
// Contrato da camada de persistência responsável pelas
// permissões de comunicação do módulo de chamadas.
//
// MODELO DE VÍDEO
// ------------------------------------------------------------
//
// A permissão é BILATERAL:
//
// João <-> Artista
//
// Porém o controle de convites é DIRECIONAL:
//
// João -> Artista
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
// somente quem recusou pode liberar
// uma nova tentativa.
//
// ÁUDIO
// ------------------------------------------------------------
//
// Áudio é independente da permissão bilateral de vídeo.
//
// ============================================================

abstract class CommunicationPermissionRepository {
  // ==========================================================
  // CURRENT USER
  // ==========================================================

  String get currentUserId;

  // ==========================================================
  // VIDEO PERMISSION
  // ==========================================================
  //
  // userId representa o OUTRO usuário.
  //
  // Exemplo:
  //
  // currentUserId = João
  // userId        = Artista
  //
  // Procura:
  //
  // João <-> Artista
  //
  // ==========================================================

  Future<
    CommunicationPermissionModel?
  >
  getPermission({
    required String projectId,
    required String userId,
  });

  // ==========================================================
  // CURRENT USER PERMISSION
  // ==========================================================
  //
  // Compatibilidade temporária.
  //
  // No modelo bilateral não existe uma única permissão global.
  //
  // ==========================================================

  Future<
    CommunicationPermissionModel?
  >
  getCurrentUserPermission({
    required String projectId,
  });

  // ==========================================================
  // PROJECT PERMISSIONS
  // ==========================================================

  Future<
    List<
      CommunicationPermissionModel
    >
  >
  getProjectPermissions({
    required String projectId,
  });

  // ==========================================================
  // STREAM PROJECT PERMISSIONS
  // ==========================================================

  Stream<
    List<
      CommunicationPermissionModel
    >
  >
  streamProjectPermissions({
    required String projectId,
  });

  // ==========================================================
  // VIDEO INVITE STATE
  // ==========================================================
  //
  // Retorna o estado direcional:
  //
  // currentUserId -> targetUserId
  //
  // Exemplo:
  //
  // João -> Artista
  //
  // Informa:
  //
  // - rejectionCount;
  // - cooldownUntil;
  // - blockedAfterLimit;
  // - reopenedAt;
  // - reopenedBy.
  //
  // ==========================================================

  Future<
    CommunicationVideoInviteStateModel?
  >
  getVideoInviteState({
    required String projectId,
    required String targetUserId,
  });

  // ==========================================================
  // VIDEO INVITE STATE BY DIRECTION
  // ==========================================================
  //
  // Permite consultar qualquer direção que o usuário
  // autenticado tenha permissão de visualizar.
  //
  // Exemplo:
  //
  // requesterId -> targetUserId
  //
  // ==========================================================

  Future<
    CommunicationVideoInviteStateModel?
  >
  getVideoInviteStateByDirection({
    required String projectId,
    required String requesterId,
    required String targetUserId,
  });

  // ==========================================================
  // PROJECT VIDEO INVITE STATES
  // ==========================================================

  Future<
    List<
      CommunicationVideoInviteStateModel
    >
  >
  getProjectVideoInviteStates({
    required String projectId,
  });

  // ==========================================================
  // STREAM VIDEO INVITE STATES
  // ==========================================================

  Stream<
    List<
      CommunicationVideoInviteStateModel
    >
  >
  streamProjectVideoInviteStates({
    required String projectId,
  });

  // ==========================================================
  // ALLOW VIDEO INVITES FROM
  // ==========================================================
  //
  // Usado depois da terceira recusa.
  //
  // Exemplo:
  //
  // João -> Artista
  //
  // Artista recusou 3 vezes.
  //
  // João ficou bloqueado.
  //
  // Então Artista executa:
  //
  // allowVideoInvitesFrom(
  //   requesterId: joaoId,
  // )
  //
  // Isso NÃO libera vídeo.
  //
  // Apenas permite que João faça um novo convite.
  //
  // ==========================================================

  Future<
    CommunicationVideoInviteStateModel
  >
  allowVideoInvitesFrom({
    required String projectId,
    required String requesterId,
  });

  // ==========================================================
  // REQUEST BY ID
  // ==========================================================

  Future<
    CommunicationRequestModel?
  >
  getRequestById({
    required String requestId,
  });

  // ==========================================================
  // PROJECT REQUESTS
  // ==========================================================

  Future<
    List<
      CommunicationRequestModel
    >
  >
  getProjectRequests({
    required String projectId,
  });

  // ==========================================================
  // RECEIVED REQUESTS
  // ==========================================================

  Future<
    List<
      CommunicationRequestModel
    >
  >
  getReceivedRequests({
    required String projectId,
  });

  // ==========================================================
  // SENT REQUESTS
  // ==========================================================

  Future<
    List<
      CommunicationRequestModel
    >
  >
  getSentRequests({
    required String projectId,
  });

  // ==========================================================
  // STREAM RECEIVED REQUESTS
  // ==========================================================

  Stream<
    List<
      CommunicationRequestModel
    >
  >
  streamReceivedRequests({
    required String projectId,
  });

  // ==========================================================
  // STREAM SENT REQUESTS
  // ==========================================================

  Stream<
    List<
      CommunicationRequestModel
    >
  >
  streamSentRequests({
    required String projectId,
  });

  // ==========================================================
  // REQUEST VIDEO
  // ==========================================================
  //
  // O Flutter NÃO calcula:
  //
  // - tentativa;
  // - cooldown;
  // - limite;
  // - bloqueio.
  //
  // Tudo isso pertence ao PostgreSQL.
  //
  // ==========================================================

  Future<
    CommunicationRequestModel
  >
  requestVideo({
    required String projectId,
    required String targetUserId,
  });

  // ==========================================================
  // REQUEST VIDEO DURING CALL
  // ==========================================================
  //
  // Usado para:
  //
  // audio -> video
  //
  // durante uma chamada ativa.
  //
  // ==========================================================

  Future<
    CommunicationRequestModel
  >
  requestVideoUpgrade({
    required String projectId,
    required String targetUserId,
    required String callId,
  });

  // ==========================================================
  // REQUEST VIDEO BULK
  // ==========================================================
  //
  // Usado pela MembersView quando vários membros forem
  // selecionados.
  //
  // O retorno é individual por usuário porque:
  //
  // um membro pode receber;
  // outro pode estar em cooldown;
  // outro pode estar bloqueado;
  // outro já pode ter vídeo liberado.
  //
  // ==========================================================

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
  });

  // ==========================================================
  // ACCEPT VIDEO REQUEST
  // ==========================================================

  Future<
    CommunicationRequestModel
  >
  acceptVideoRequest({
    required String requestId,
  });

  // ==========================================================
  // REJECT VIDEO REQUEST
  // ==========================================================

  Future<
    CommunicationRequestModel
  >
  rejectVideoRequest({
    required String requestId,
  });

  // ==========================================================
  // REVOKE VIDEO PERMISSION
  // ==========================================================
  //
  // Qualquer participante da relação pode retirar
  // seu consentimento posteriormente.
  //
  // ==========================================================

  Future<
    CommunicationPermissionModel
  >
  revokeVideoPermission({
    required String projectId,
    required String otherUserId,
  });

  // ==========================================================
  // VIDEO ALLOWED
  // ==========================================================

  Future<
    bool
  >
  isVideoAllowed({
    required String projectId,
    required String userId,
  });

  // ==========================================================
  // AUDIO ALLOWED
  // ==========================================================

  Future<
    bool
  >
  isAudioAllowed({
    required String projectId,
    required String userId,
  });
}

// ============================================================
// VIDEO INVITE BULK RESULT
// ============================================================
//
// Representa o retorno individual da RPC:
//
// request_project_video_bulk
//
// Exemplo:
//
// usuário A
// success = true
//
// usuário B
// success = false
// error = cooldown
//
// ============================================================

class VideoInviteBulkResult {
  // ==========================================================
  // USER
  // ==========================================================

  final String userId;

  // ==========================================================
  // RESULT
  // ==========================================================

  final bool success;

  // ==========================================================
  // REQUEST
  // ==========================================================

  final String? requestId;

  final int? attemptNumber;

  final String? status;

  // ==========================================================
  // ERROR
  // ==========================================================

  final String? error;

  // ==========================================================
  // CONSTRUCTOR
  // ==========================================================

  const VideoInviteBulkResult({
    required this.userId,
    required this.success,
    this.requestId,
    this.attemptNumber,
    this.status,
    this.error,
  });

  // ==========================================================
  // FROM MAP
  // ==========================================================

  factory VideoInviteBulkResult.fromMap(
    Map<
      String,
      dynamic
    >
    map,
  ) {
    return VideoInviteBulkResult(
      userId: _readString(
        map['user_id'],
      ),
      success: _readBool(
        map['success'],
      ),
      requestId: _readNullableString(
        map['request_id'],
      ),
      attemptNumber: _readNullableInt(
        map['attempt_number'],
      ),
      status: _readNullableString(
        map['status'],
      ),
      error: _readNullableString(
        map['error'],
      ),
    );
  }

  // ==========================================================
  // HELPERS
  // ==========================================================

  bool get failed => !success;

  bool get hasError =>
      error !=
          null &&
      error!.isNotEmpty;

  // ==========================================================
  // PARSERS
  // ==========================================================

  static String _readString(
    dynamic value,
  ) {
    return value?.toString().trim() ??
        '';
  }

  static String? _readNullableString(
    dynamic value,
  ) {
    final normalized = value?.toString().trim();

    if (normalized ==
            null ||
        normalized.isEmpty) {
      return null;
    }

    return normalized;
  }

  static int? _readNullableInt(
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

    if (value
        is String) {
      return int.tryParse(
        value.trim(),
      );
    }

    return null;
  }

  static bool _readBool(
    dynamic value, {
    bool fallback = false,
  }) {
    if (value
        is bool) {
      return value;
    }

    if (value
        is num) {
      return value !=
          0;
    }

    if (value
        is String) {
      switch (value.trim().toLowerCase()) {
        case 'true':
        case '1':
          return true;

        case 'false':
        case '0':
          return false;
      }
    }

    return fallback;
  }

  // ==========================================================
  // OBJECT
  // ==========================================================

  @override
  String toString() {
    return 'VideoInviteBulkResult('
        'userId: $userId, '
        'success: $success, '
        'requestId: $requestId, '
        'attemptNumber: $attemptNumber, '
        'status: $status, '
        'error: $error'
        ')';
  }
}
