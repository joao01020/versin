import '../data/models/communication_permission_model.dart';
import '../data/models/communication_request_model.dart';
import '../data/models/communication_video_invite_state_model.dart';

import '../data/repositories/communication_permission_repository_impl.dart';

import '../repositories/communication_permission_repository.dart';

// ============================================================
// COMMUNICATION PERMISSION SERVICE
// ============================================================
//
// Camada de regras de negócio relacionada a:
//
// - participação por áudio;
// - consentimento bilateral de vídeo;
// - solicitações de vídeo;
// - convite individual;
// - convite em lote;
// - upgrade áudio -> vídeo;
// - aceite;
// - recusa;
// - cooldown;
// - bloqueio;
// - reabertura após terceira recusa;
// - revogação de consentimento;
// - consulta de permissões;
// - observação Realtime.
//
// ARQUITETURA:
//
// Controller
//      ↓
// CommunicationPermissionService
//      ↓
// CommunicationPermissionRepository
//      ↓
// RepositoryImpl
//      ↓
// Supabase
//
// IMPORTANTE:
//
// As regras críticas ficam no PostgreSQL:
//
// - 1ª recusa -> 2 dias;
// - 2ª recusa -> 4 dias;
// - 3ª recusa -> bloqueio;
// - validação de membro;
// - permissão bilateral;
// - prevenção de convites duplicados.
//
// O Flutter apenas representa e coordena esses estados.
//
// ============================================================

class CommunicationPermissionService {
  // ==========================================================
  // REPOSITORY
  // ==========================================================

  final CommunicationPermissionRepository _repository;

  // ==========================================================
  // CONSTRUCTOR
  // ==========================================================

  CommunicationPermissionService({
    CommunicationPermissionRepository? repository,
  }) : _repository =
           repository ??
           CommunicationPermissionRepositoryImpl();

  // ==========================================================
  // CURRENT USER
  // ==========================================================

  String get currentUserId => _repository.currentUserId;

  // ==========================================================
  // GET PERMISSION
  // ==========================================================
  //
  // userId representa o OUTRO usuário.
  //
  // Exemplo:
  //
  // current = João
  // userId  = Artista
  //
  // Consulta:
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
  }) {
    final normalizedProjectId = _required(
      projectId,
      'projectId',
    );

    final otherUserId = _requiredOtherUser(
      userId,
      'userId',
    );

    return _repository.getPermission(
      projectId: normalizedProjectId,

      userId: otherUserId,
    );
  }

  // ==========================================================
  // GET PERMISSION WITH USER
  // ==========================================================

  Future<
    CommunicationPermissionModel?
  >
  getPermissionWith({
    required String projectId,
    required String otherUserId,
  }) {
    return getPermission(
      projectId: projectId,

      userId: otherUserId,
    );
  }

  // ==========================================================
  // CURRENT PERMISSION
  // ==========================================================
  //
  // Compatibilidade temporária com código anterior.
  //
  // No modelo bilateral não existe uma única permissão global.
  //
  // ==========================================================

  Future<
    CommunicationPermissionModel?
  >
  getCurrentUserPermission({
    required String projectId,
  }) {
    return _repository.getCurrentUserPermission(
      projectId: _required(
        projectId,
        'projectId',
      ),
    );
  }

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
  }) {
    return _repository.getProjectPermissions(
      projectId: _required(
        projectId,
        'projectId',
      ),
    );
  }

  // ==========================================================
  // STREAM PERMISSIONS
  // ==========================================================

  Stream<
    List<
      CommunicationPermissionModel
    >
  >
  streamProjectPermissions({
    required String projectId,
  }) {
    return _repository.streamProjectPermissions(
      projectId: _required(
        projectId,
        'projectId',
      ),
    );
  }

  // ==========================================================
  // VIDEO INVITE STATE
  // ==========================================================
  //
  // Consulta:
  //
  // currentUser -> targetUser
  //
  // ==========================================================

  Future<
    CommunicationVideoInviteStateModel?
  >
  getVideoInviteState({
    required String projectId,
    required String targetUserId,
  }) {
    return _repository.getVideoInviteState(
      projectId: _required(
        projectId,
        'projectId',
      ),

      targetUserId: _requiredOtherUser(
        targetUserId,
        'targetUserId',
      ),
    );
  }

  // ==========================================================
  // VIDEO INVITE STATE BY DIRECTION
  // ==========================================================

  Future<
    CommunicationVideoInviteStateModel?
  >
  getVideoInviteStateByDirection({
    required String projectId,
    required String requesterId,
    required String targetUserId,
  }) {
    final normalizedProjectId = _required(
      projectId,
      'projectId',
    );

    final normalizedRequester = _required(
      requesterId,
      'requesterId',
    );

    final normalizedTarget = _required(
      targetUserId,
      'targetUserId',
    );

    if (normalizedRequester ==
        normalizedTarget) {
      throw ArgumentError(
        'requesterId e targetUserId precisam ser diferentes.',
      );
    }

    return _repository.getVideoInviteStateByDirection(
      projectId: normalizedProjectId,

      requesterId: normalizedRequester,

      targetUserId: normalizedTarget,
    );
  }

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
  }) {
    return _repository.getProjectVideoInviteStates(
      projectId: _required(
        projectId,
        'projectId',
      ),
    );
  }

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
  }) {
    return _repository.streamProjectVideoInviteStates(
      projectId: _required(
        projectId,
        'projectId',
      ),
    );
  }

  // ==========================================================
  // CAN REQUEST VIDEO
  // ==========================================================

  Future<
    bool
  >
  canRequestVideo({
    required String projectId,
    required String targetUserId,
  }) async {
    final normalizedTarget = _requiredOtherUser(
      targetUserId,
      'targetUserId',
    );

    // ========================================================
    // ALREADY ALLOWED
    // ========================================================

    final alreadyAllowed = await canUseVideoWith(
      projectId: projectId,

      otherUserId: normalizedTarget,
    );

    if (alreadyAllowed) {
      return false;
    }

    // ========================================================
    // STATE
    // ========================================================

    final state = await getVideoInviteState(
      projectId: projectId,

      targetUserId: normalizedTarget,
    );

    if (state ==
        null) {
      return true;
    }

    return state.canRequestVideo;
  }

  // ==========================================================
  // CAN USE AUDIO
  // ==========================================================

  Future<
    bool
  >
  canUseAudio({
    required String projectId,
    String? userId,
  }) {
    final normalizedProjectId = _required(
      projectId,
      'projectId',
    );

    final normalizedUserId =
        _optionalUserId(
          userId,
        ) ??
        currentUserId;

    return _repository.isAudioAllowed(
      projectId: normalizedProjectId,

      userId: normalizedUserId,
    );
  }

  // ==========================================================
  // CAN USE VIDEO
  // ==========================================================

  Future<
    bool
  >
  canUseVideo({
    required String projectId,
    required String userId,
  }) {
    final normalizedProjectId = _required(
      projectId,
      'projectId',
    );

    final otherUserId = _requiredOtherUser(
      userId,
      'userId',
    );

    return _repository.isVideoAllowed(
      projectId: normalizedProjectId,

      userId: otherUserId,
    );
  }

  // ==========================================================
  // CAN USE VIDEO WITH
  // ==========================================================

  Future<
    bool
  >
  canUseVideoWith({
    required String projectId,
    required String otherUserId,
  }) {
    return canUseVideo(
      projectId: projectId,

      userId: otherUserId,
    );
  }

  // ==========================================================
  // HAS VIDEO PERMISSION WITH
  // ==========================================================

  Future<
    bool
  >
  hasVideoPermissionWith({
    required String projectId,
    required String otherUserId,
  }) {
    return canUseVideoWith(
      projectId: projectId,

      otherUserId: otherUserId,
    );
  }

  // ==========================================================
  // REQUEST VIDEO
  // ==========================================================

  Future<
    CommunicationRequestModel
  >
  requestVideo({
    required String projectId,
    required String targetUserId,
  }) {
    final normalizedProjectId = _required(
      projectId,
      'projectId',
    );

    final normalizedTarget = _requiredOtherUser(
      targetUserId,
      'targetUserId',
    );

    return _repository.requestVideo(
      projectId: normalizedProjectId,

      targetUserId: normalizedTarget,
    );
  }

  // ==========================================================
  // REQUEST VIDEO UPGRADE
  // ==========================================================
  //
  // Durante uma chamada ativa:
  //
  // áudio
  //   ↓
  // pedido de consentimento
  //   ↓
  // vídeo
  //
  // ==========================================================

  Future<
    CommunicationRequestModel
  >
  requestVideoUpgrade({
    required String projectId,
    required String targetUserId,
    required String callId,
  }) {
    final normalizedProjectId = _required(
      projectId,
      'projectId',
    );

    final normalizedTarget = _requiredOtherUser(
      targetUserId,
      'targetUserId',
    );

    final normalizedCallId = _required(
      callId,
      'callId',
    );

    return _repository.requestVideoUpgrade(
      projectId: normalizedProjectId,

      targetUserId: normalizedTarget,

      callId: normalizedCallId,
    );
  }

  // ==========================================================
  // REQUEST VIDEO BULK
  // ==========================================================
  //
  // MembersView poderá selecionar vários usuários.
  //
  // Cada resultado é independente.
  //
  // Exemplo:
  //
  // Artista
  // -> enviado
  //
  // Beatmaker
  // -> cooldown
  //
  // Produtor
  // -> bloqueado
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
  }) {
    final normalizedProjectId = _required(
      projectId,
      'projectId',
    );

    final targets = _normalizeUserIds(
      targetUserIds,
    );

    if (targets.isEmpty) {
      return Future.value(
        const <
          VideoInviteBulkResult
        >[],
      );
    }

    final normalizedCallId = _optional(
      callId,
    );

    if (videoUpgrade &&
        normalizedCallId ==
            null) {
      throw ArgumentError(
        'callId é obrigatório para videoUpgrade.',
      );
    }

    return _repository.requestVideoBulk(
      projectId: normalizedProjectId,

      targetUserIds: targets,

      callId: normalizedCallId,

      videoUpgrade: videoUpgrade,
    );
  }

  // ==========================================================
  // ACCEPT REQUEST
  // ==========================================================

  Future<
    CommunicationRequestModel
  >
  acceptRequest({
    required CommunicationRequestModel request,
  }) {
    _validateRequestForCurrentUser(
      request,
    );

    if (!request.canRespond) {
      throw StateError(
        'Essa solicitação não pode mais ser aceita.',
      );
    }

    if (!request.isVideoRequest) {
      throw StateError(
        'A solicitação não é uma solicitação de vídeo.',
      );
    }

    return _repository.acceptVideoRequest(
      requestId: request.id,
    );
  }

  // ==========================================================
  // REJECT REQUEST
  // ==========================================================

  Future<
    CommunicationRequestModel
  >
  rejectRequest({
    required CommunicationRequestModel request,
  }) {
    _validateRequestForCurrentUser(
      request,
    );

    if (!request.canRespond) {
      throw StateError(
        'Essa solicitação não pode mais ser recusada.',
      );
    }

    if (!request.isVideoRequest) {
      throw StateError(
        'A solicitação não é uma solicitação de vídeo.',
      );
    }

    return _repository.rejectVideoRequest(
      requestId: request.id,
    );
  }

  // ==========================================================
  // ALLOW VIDEO INVITES FROM
  // ==========================================================
  //
  // Usado pelo TARGET depois da terceira recusa.
  //
  // Exemplo:
  //
  // João -> Artista
  //
  // Artista recusou 3 vezes.
  //
  // Artista executa:
  //
  // allowVideoInvitesFrom(
  //   requesterId: joaoId,
  // )
  //
  // Isso NÃO libera vídeo.
  //
  // Apenas permite João perguntar novamente.
  //
  // ==========================================================

  Future<
    CommunicationVideoInviteStateModel
  >
  allowVideoInvitesFrom({
    required String projectId,
    required String requesterId,
  }) {
    final normalizedRequester = _requiredOtherUser(
      requesterId,
      'requesterId',
    );

    return _repository.allowVideoInvitesFrom(
      projectId: _required(
        projectId,
        'projectId',
      ),

      requesterId: normalizedRequester,
    );
  }

  // ==========================================================
  // REVOKE VIDEO PERMISSION
  // ==========================================================
  //
  // Qualquer um dos dois pode retirar o próprio consentimento.
  //
  // ==========================================================

  Future<
    CommunicationPermissionModel
  >
  revokeVideoPermission({
    required String projectId,
    required String otherUserId,
  }) {
    return _repository.revokeVideoPermission(
      projectId: _required(
        projectId,
        'projectId',
      ),

      otherUserId: _requiredOtherUser(
        otherUserId,
        'otherUserId',
      ),
    );
  }

  // ==========================================================
  // REQUEST BY ID
  // ==========================================================

  Future<
    CommunicationRequestModel?
  >
  getRequestById({
    required String requestId,
  }) {
    return _repository.getRequestById(
      requestId: _required(
        requestId,
        'requestId',
      ),
    );
  }

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
  }) {
    return _repository.getProjectRequests(
      projectId: _required(
        projectId,
        'projectId',
      ),
    );
  }

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
  }) {
    return _repository.getReceivedRequests(
      projectId: _required(
        projectId,
        'projectId',
      ),
    );
  }

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
  }) {
    return _repository.getSentRequests(
      projectId: _required(
        projectId,
        'projectId',
      ),
    );
  }

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
  }) {
    return _repository.streamReceivedRequests(
      projectId: _required(
        projectId,
        'projectId',
      ),
    );
  }

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
  }) {
    return _repository.streamSentRequests(
      projectId: _required(
        projectId,
        'projectId',
      ),
    );
  }

  // ==========================================================
  // FIND PENDING RECEIVED VIDEO REQUEST
  // ==========================================================

  Future<
    CommunicationRequestModel?
  >
  findPendingVideoRequest({
    required String projectId,
    required String senderId,
  }) async {
    final normalizedSender = _requiredOtherUser(
      senderId,
      'senderId',
    );

    final requests = await getReceivedRequests(
      projectId: projectId,
    );

    for (final request in requests) {
      if (!request.canRespond) {
        continue;
      }

      if (!request.isVideoRequest) {
        continue;
      }

      if (request.senderId ==
          normalizedSender) {
        return request;
      }
    }

    return null;
  }

  // ==========================================================
  // HAS PENDING VIDEO REQUEST FROM
  // ==========================================================

  Future<
    bool
  >
  hasPendingVideoRequestFrom({
    required String projectId,
    required String senderId,
  }) async {
    final request = await findPendingVideoRequest(
      projectId: projectId,

      senderId: senderId,
    );

    return request !=
        null;
  }

  // ==========================================================
  // FIND PENDING SENT VIDEO REQUEST
  // ==========================================================

  Future<
    CommunicationRequestModel?
  >
  findPendingVideoRequestTo({
    required String projectId,
    required String targetUserId,
  }) async {
    final normalizedTarget = _requiredOtherUser(
      targetUserId,
      'targetUserId',
    );

    final requests = await getSentRequests(
      projectId: projectId,
    );

    for (final request in requests) {
      if (!request.canRespond) {
        continue;
      }

      if (!request.isVideoRequest) {
        continue;
      }

      if (request.targetUserId ==
          normalizedTarget) {
        return request;
      }
    }

    return null;
  }

  // ==========================================================
  // HAS PENDING VIDEO REQUEST TO
  // ==========================================================

  Future<
    bool
  >
  hasPendingVideoRequestTo({
    required String projectId,
    required String targetUserId,
  }) async {
    final request = await findPendingVideoRequestTo(
      projectId: projectId,

      targetUserId: targetUserId,
    );

    return request !=
        null;
  }

  // ==========================================================
  // GET OUTGOING INVITE STATE
  // ==========================================================

  Future<
    CommunicationVideoInviteStateModel?
  >
  getOutgoingInviteState({
    required String projectId,
    required String targetUserId,
  }) {
    return getVideoInviteState(
      projectId: projectId,

      targetUserId: targetUserId,
    );
  }

  // ==========================================================
  // GET INCOMING INVITE STATE
  // ==========================================================
  //
  // Consulta:
  //
  // requester -> currentUser
  //
  // É esse estado que diz se o requester chegou ao limite
  // de três recusas e pode ser reaberto pelo usuário atual.
  //
  // ==========================================================

  Future<
    CommunicationVideoInviteStateModel?
  >
  getIncomingInviteState({
    required String projectId,
    required String requesterId,
  }) {
    return getVideoInviteStateByDirection(
      projectId: projectId,

      requesterId: _requiredOtherUser(
        requesterId,
        'requesterId',
      ),

      targetUserId: currentUserId,
    );
  }

  // ==========================================================
  // CAN REOPEN INVITES FROM
  // ==========================================================

  Future<
    bool
  >
  canReopenInvitesFrom({
    required String projectId,
    required String requesterId,
  }) async {
    final state = await getIncomingInviteState(
      projectId: projectId,

      requesterId: requesterId,
    );

    if (state ==
        null) {
      return false;
    }

    return state.blockedAfterLimit;
  }

  // ==========================================================
  // IS VIDEO REQUEST
  // ==========================================================

  bool isVideoRequest(
    CommunicationRequestModel request,
  ) {
    return request.isVideoRequest;
  }

  // ==========================================================
  // VALIDATE REQUEST
  // ==========================================================

  void _validateRequestForCurrentUser(
    CommunicationRequestModel request,
  ) {
    if (!request.isValid) {
      throw ArgumentError(
        'Solicitação de comunicação inválida.',
      );
    }

    if (!request.wasSentTo(
      currentUserId,
    )) {
      throw StateError(
        'A solicitação não pertence ao usuário autenticado.',
      );
    }

    if (request.wasSentBy(
      currentUserId,
    )) {
      throw StateError(
        'O remetente não pode responder a própria solicitação.',
      );
    }
  }

  // ==========================================================
  // NORMALIZE USER IDS
  // ==========================================================

  List<
    String
  >
  _normalizeUserIds(
    List<
      String
    >
    values,
  ) {
    final result =
        <
          String
        >{};

    for (final value in values) {
      final normalized = value.trim();

      if (normalized.isEmpty) {
        continue;
      }

      if (normalized ==
          currentUserId) {
        continue;
      }

      result.add(
        normalized,
      );
    }

    return result.toList(
      growable: false,
    );
  }

  // ==========================================================
  // REQUIRED OTHER USER
  // ==========================================================

  String _requiredOtherUser(
    String value,
    String field,
  ) {
    final normalized = _required(
      value,
      field,
    );

    if (normalized ==
        currentUserId) {
      throw ArgumentError(
        '$field precisa representar outro usuário.',
      );
    }

    return normalized;
  }

  // ==========================================================
  // OPTIONAL USER ID
  // ==========================================================

  String? _optionalUserId(
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

  // ==========================================================
  // OPTIONAL STRING
  // ==========================================================

  String? _optional(
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
