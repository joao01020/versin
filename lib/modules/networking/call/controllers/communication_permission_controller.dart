import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/models/communication_permission_model.dart';
import '../data/models/communication_request_model.dart';
import '../data/models/communication_video_invite_state_model.dart';

import '../repositories/communication_permission_repository.dart';

import '../services/communication_permission_service.dart';

// ============================================================
// COMMUNICATION PERMISSION CONTROLLER
// ============================================================
//
// Responsável pelo estado de comunicação do projeto.
//
// Mantém:
//
// - permissões bilaterais de vídeo;
// - estado direcional dos convites;
// - solicitações recebidas;
// - solicitações enviadas;
// - áudio;
// - cooldown;
// - bloqueio;
// - reabertura;
// - revogação;
// - sincronização Realtime.
//
// MODELO:
//
// PERMISSÃO
//
// usuário A <-> usuário B
//
// ------------------------------------------------------------
//
// CONVITE
//
// requester -> target
//
// ------------------------------------------------------------
//
// REGRA:
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
// Depois:
//
// somente o target pode permitir uma nova tentativa.
//
// ============================================================

class CommunicationPermissionController
    with
        ChangeNotifier {
  // ==========================================================
  // PROJECT
  // ==========================================================

  final String projectId;

  // ==========================================================
  // SERVICE
  // ==========================================================

  final CommunicationPermissionService _service;

  // ==========================================================
  // SUBSCRIPTIONS
  // ==========================================================

  StreamSubscription<
    List<
      CommunicationPermissionModel
    >
  >?
  _permissionsSubscription;

  StreamSubscription<
    List<
      CommunicationVideoInviteStateModel
    >
  >?
  _inviteStatesSubscription;

  StreamSubscription<
    List<
      CommunicationRequestModel
    >
  >?
  _receivedRequestsSubscription;

  StreamSubscription<
    List<
      CommunicationRequestModel
    >
  >?
  _sentRequestsSubscription;

  // ==========================================================
  // STATE
  // ==========================================================

  List<
    CommunicationPermissionModel
  >
  _permissions =
      const <
        CommunicationPermissionModel
      >[];

  List<
    CommunicationVideoInviteStateModel
  >
  _inviteStates =
      const <
        CommunicationVideoInviteStateModel
      >[];

  List<
    CommunicationRequestModel
  >
  _receivedRequests =
      const <
        CommunicationRequestModel
      >[];

  List<
    CommunicationRequestModel
  >
  _sentRequests =
      const <
        CommunicationRequestModel
      >[];

  // ==========================================================
  // AUDIO CACHE
  // ==========================================================

  final Map<
    String,
    bool
  >
  _audioPermissions =
      <
        String,
        bool
      >{};

  // ==========================================================
  // PROCESSING
  // ==========================================================

  final Set<
    String
  >
  _processingUsers =
      <
        String
      >{};

  bool _isLoading = false;

  bool _isProcessing = false;

  bool _disposed = false;

  String? _errorMessage;

  // ==========================================================
  // CONSTRUCTOR
  // ==========================================================

  CommunicationPermissionController({
    required String projectId,
    CommunicationPermissionRepository? repository,
    CommunicationPermissionService? service,
  }) : projectId = _requiredProjectId(
         projectId,
       ),
       _service =
           service ??
           CommunicationPermissionService(
             repository: repository,
           );

  // ==========================================================
  // GETTERS
  // ==========================================================

  List<
    CommunicationPermissionModel
  >
  get permissions => _permissions;

  List<
    CommunicationVideoInviteStateModel
  >
  get inviteStates => _inviteStates;

  List<
    CommunicationRequestModel
  >
  get receivedRequests => _receivedRequests;

  List<
    CommunicationRequestModel
  >
  get sentRequests => _sentRequests;

  bool get isLoading => _isLoading;

  bool get isProcessing => _isProcessing;

  bool get hasError =>
      _errorMessage !=
      null;

  String? get errorMessage => _errorMessage;

  bool get hasPendingRequests => pendingReceivedRequests.isNotEmpty;

  // ==========================================================
  // CURRENT USER
  // ==========================================================

  String get currentUserId => _service.currentUserId;

  // ==========================================================
  // PENDING RECEIVED
  // ==========================================================

  List<
    CommunicationRequestModel
  >
  get pendingReceivedRequests {
    return _receivedRequests
        .where(
          (
            request,
          ) =>
              request.canRespond &&
              request.isVideoRequest,
        )
        .toList(
          growable: false,
        );
  }

  // ==========================================================
  // PENDING SENT
  // ==========================================================

  List<
    CommunicationRequestModel
  >
  get pendingSentRequests {
    return _sentRequests
        .where(
          (
            request,
          ) =>
              request.canRespond &&
              request.isVideoRequest,
        )
        .toList(
          growable: false,
        );
  }

  // ==========================================================
  // COMPATIBILITY
  // ==========================================================

  List<
    CommunicationRequestModel
  >
  get pendingRequests => pendingReceivedRequests;

  // ==========================================================
  // INIT
  // ==========================================================

  Future<
    void
  >
  init() async {
    if (_disposed) {
      return;
    }

    _isLoading = true;

    _errorMessage = null;

    _safeNotify();

    try {
      await _stopSubscriptions();

      // ======================================================
      // PERMISSIONS REALTIME
      // ======================================================

      _permissionsSubscription = _service
          .streamProjectPermissions(
            projectId: projectId,
          )
          .listen(
            _handlePermissions,

            onError: _handlePermissionsError,
          );

      // ======================================================
      // INVITE STATES REALTIME
      // ======================================================

      _inviteStatesSubscription = _service
          .streamProjectVideoInviteStates(
            projectId: projectId,
          )
          .listen(
            _handleInviteStates,

            onError: _handleInviteStatesError,
          );

      // ======================================================
      // RECEIVED REALTIME
      // ======================================================

      _receivedRequestsSubscription = _service
          .streamReceivedRequests(
            projectId: projectId,
          )
          .listen(
            _handleReceivedRequests,

            onError: _handleReceivedRequestsError,
          );

      // ======================================================
      // SENT REALTIME
      // ======================================================

      _sentRequestsSubscription = _service
          .streamSentRequests(
            projectId: projectId,
          )
          .listen(
            _handleSentRequests,

            onError: _handleSentRequestsError,
          );

      // ======================================================
      // INITIAL LOAD
      // ======================================================

      await _loadInitialState();
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[COMMUNICATION PERMISSION CONTROLLER] '
        'Erro no init: '
        '$error',
      );

      debugPrint(
        '[COMMUNICATION PERMISSION CONTROLLER] '
        '$stackTrace',
      );

      if (_disposed) {
        return;
      }

      _isLoading = false;

      _errorMessage = 'Não foi possível carregar as permissões de comunicação.';

      _safeNotify();
    }
  }

  // ==========================================================
  // INITIAL LOAD
  // ==========================================================

  Future<
    void
  >
  _loadInitialState() async {
    final results =
        await Future.wait<
          dynamic
        >(
          [
            _service.getProjectPermissions(
              projectId: projectId,
            ),

            _service.getProjectVideoInviteStates(
              projectId: projectId,
            ),

            _service.getReceivedRequests(
              projectId: projectId,
            ),

            _service.getSentRequests(
              projectId: projectId,
            ),
          ],
        );

    if (_disposed) {
      return;
    }

    _permissions =
        List<
          CommunicationPermissionModel
        >.unmodifiable(
          results[0]
              as List<
                CommunicationPermissionModel
              >,
        );

    _inviteStates =
        List<
          CommunicationVideoInviteStateModel
        >.unmodifiable(
          results[1]
              as List<
                CommunicationVideoInviteStateModel
              >,
        );

    _receivedRequests =
        List<
          CommunicationRequestModel
        >.unmodifiable(
          results[2]
              as List<
                CommunicationRequestModel
              >,
        );

    _sentRequests =
        List<
          CommunicationRequestModel
        >.unmodifiable(
          results[3]
              as List<
                CommunicationRequestModel
              >,
        );

    _isLoading = false;

    _errorMessage = null;

    _safeNotify();
  }

  // ==========================================================
  // HANDLE PERMISSIONS
  // ==========================================================

  void _handlePermissions(
    List<
      CommunicationPermissionModel
    >
    permissions,
  ) {
    if (_disposed) {
      return;
    }

    _permissions =
        List<
          CommunicationPermissionModel
        >.unmodifiable(
          permissions,
        );

    _safeNotify();
  }

  // ==========================================================
  // HANDLE INVITE STATES
  // ==========================================================

  void _handleInviteStates(
    List<
      CommunicationVideoInviteStateModel
    >
    states,
  ) {
    if (_disposed) {
      return;
    }

    _inviteStates =
        List<
          CommunicationVideoInviteStateModel
        >.unmodifiable(
          states,
        );

    _safeNotify();
  }

  // ==========================================================
  // HANDLE RECEIVED
  // ==========================================================

  void _handleReceivedRequests(
    List<
      CommunicationRequestModel
    >
    requests,
  ) {
    if (_disposed) {
      return;
    }

    _receivedRequests =
        List<
          CommunicationRequestModel
        >.unmodifiable(
          requests,
        );

    _safeNotify();
  }

  // ==========================================================
  // HANDLE SENT
  // ==========================================================

  void _handleSentRequests(
    List<
      CommunicationRequestModel
    >
    requests,
  ) {
    if (_disposed) {
      return;
    }

    _sentRequests =
        List<
          CommunicationRequestModel
        >.unmodifiable(
          requests,
        );

    _safeNotify();
  }

  // ==========================================================
  // STREAM ERRORS
  // ==========================================================

  void _handlePermissionsError(
    Object error,
    StackTrace stackTrace,
  ) {
    _handleRealtimeError(
      'permissões',
      error,
      stackTrace,
    );
  }

  void _handleInviteStatesError(
    Object error,
    StackTrace stackTrace,
  ) {
    _handleRealtimeError(
      'estados de convite',
      error,
      stackTrace,
    );
  }

  void _handleReceivedRequestsError(
    Object error,
    StackTrace stackTrace,
  ) {
    _handleRealtimeError(
      'convites recebidos',
      error,
      stackTrace,
    );
  }

  void _handleSentRequestsError(
    Object error,
    StackTrace stackTrace,
  ) {
    _handleRealtimeError(
      'convites enviados',
      error,
      stackTrace,
    );
  }

  void _handleRealtimeError(
    String source,
    Object error,
    StackTrace stackTrace,
  ) {
    debugPrint(
      '[COMMUNICATION PERMISSION CONTROLLER] '
      'Erro Realtime em $source: '
      '$error',
    );

    debugPrint(
      '$stackTrace',
    );

    if (_disposed) {
      return;
    }

    _errorMessage = 'Erro ao atualizar $source.';

    _safeNotify();
  }

  // ==========================================================
  // PERMISSION FOR USER
  // ==========================================================

  CommunicationPermissionModel? permissionForUser(
    String userId,
  ) {
    final normalized = userId.trim();

    if (normalized.isEmpty ||
        normalized ==
            currentUserId) {
      return null;
    }

    for (final permission in _permissions) {
      if (permission.matchesPair(
        firstUserId: currentUserId,

        secondUserId: normalized,
      )) {
        return permission;
      }
    }

    return null;
  }

  // ==========================================================
  // PERMISSION WITH
  // ==========================================================

  CommunicationPermissionModel? permissionWith(
    String otherUserId,
  ) {
    return permissionForUser(
      otherUserId,
    );
  }

  // ==========================================================
  // VIDEO ALLOWED LOCAL
  // ==========================================================

  bool isVideoAllowedFor(
    String userId,
  ) {
    return permissionForUser(
          userId,
        )?.videoAllowed ??
        false;
  }

  // ==========================================================
  // VIDEO ALLOWED REMOTE
  // ==========================================================

  Future<
    bool
  >
  checkVideoAllowedFor(
    String userId,
  ) async {
    final normalized = userId.trim();

    if (normalized.isEmpty ||
        normalized ==
            currentUserId) {
      return false;
    }

    try {
      return await _service.canUseVideoWith(
        projectId: projectId,

        otherUserId: normalized,
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[COMMUNICATION PERMISSION CONTROLLER] '
        'Erro verificando vídeo: '
        '$error',
      );

      debugPrint(
        '$stackTrace',
      );

      return false;
    }
  }

  // ==========================================================
  // OUTGOING INVITE STATE
  // ==========================================================
  //
  // currentUser -> target
  //
  // ==========================================================

  CommunicationVideoInviteStateModel? inviteStateForUser(
    String targetUserId,
  ) {
    final target = targetUserId.trim();

    if (target.isEmpty ||
        target ==
            currentUserId) {
      return null;
    }

    for (final state in _inviteStates) {
      if (state.matchesDirection(
        requesterUserId: currentUserId,

        targetUserId: target,
      )) {
        return state;
      }
    }

    return null;
  }

  // ==========================================================
  // INCOMING INVITE STATE
  // ==========================================================
  //
  // requester -> currentUser
  //
  // ==========================================================

  CommunicationVideoInviteStateModel? incomingInviteStateFrom(
    String requesterId,
  ) {
    final requester = requesterId.trim();

    if (requester.isEmpty ||
        requester ==
            currentUserId) {
      return null;
    }

    for (final state in _inviteStates) {
      if (state.matchesDirection(
        requesterUserId: requester,

        targetUserId: currentUserId,
      )) {
        return state;
      }
    }

    return null;
  }

  // ==========================================================
  // CAN INVITE VIDEO
  // ==========================================================

  bool canInviteVideo(
    String targetUserId,
  ) {
    final target = targetUserId.trim();

    if (target.isEmpty ||
        target ==
            currentUserId) {
      return false;
    }

    if (isVideoAllowedFor(
      target,
    )) {
      return false;
    }

    if (hasPendingRequestTo(
      target,
    )) {
      return false;
    }

    final state = inviteStateForUser(
      target,
    );

    if (state ==
        null) {
      return true;
    }

    return state.canRequestVideo;
  }

  // ==========================================================
  // BLOCKED
  // ==========================================================

  bool isVideoInviteBlocked(
    String targetUserId,
  ) {
    return inviteStateForUser(
          targetUserId,
        )?.blockedAfterLimit ??
        false;
  }

  // ==========================================================
  // COOLDOWN
  // ==========================================================

  bool hasVideoInviteCooldown(
    String targetUserId,
  ) {
    return inviteStateForUser(
          targetUserId,
        )?.hasCooldown ??
        false;
  }

  Duration? cooldownRemainingFor(
    String targetUserId,
  ) {
    return inviteStateForUser(
      targetUserId,
    )?.cooldownRemaining;
  }

  String cooldownLabelFor(
    String targetUserId,
  ) {
    return inviteStateForUser(
          targetUserId,
        )?.cooldownLabel ??
        '';
  }

  // ==========================================================
  // REJECTION COUNT
  // ==========================================================

  int rejectionCountFor(
    String targetUserId,
  ) {
    return inviteStateForUser(
          targetUserId,
        )?.rejectionCount ??
        0;
  }

  // ==========================================================
  // NEXT ATTEMPT
  // ==========================================================

  int nextAttemptFor(
    String targetUserId,
  ) {
    return inviteStateForUser(
          targetUserId,
        )?.nextAttempt ??
        1;
  }

  // ==========================================================
  // CAN REOPEN USER
  // ==========================================================
  //
  // Se:
  //
  // requester -> currentUser
  //
  // atingiu três recusas.
  //
  // ==========================================================

  bool canAllowNewInviteFrom(
    String requesterId,
  ) {
    final state = incomingInviteStateFrom(
      requesterId,
    );

    return state?.blockedAfterLimit ??
        false;
  }

  // ==========================================================
  // AUDIO
  // ==========================================================

  Future<
    bool
  >
  checkAudioAllowedFor(
    String userId,
  ) async {
    final normalized = userId.trim();

    if (normalized.isEmpty) {
      return false;
    }

    try {
      final allowed = await _service.canUseAudio(
        projectId: projectId,

        userId: normalized,
      );

      if (!_disposed) {
        _audioPermissions[normalized] = allowed;

        _safeNotify();
      }

      return allowed;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[COMMUNICATION PERMISSION CONTROLLER] '
        'Erro verificando áudio: '
        '$error',
      );

      debugPrint(
        '$stackTrace',
      );

      return false;
    }
  }

  // ==========================================================
  // AUDIO CACHED
  // ==========================================================

  bool isAudioAllowedFor(
    String userId,
  ) {
    final normalized = userId.trim();

    if (normalized.isEmpty) {
      return false;
    }

    return _audioPermissions[normalized] ??
        false;
  }

  // ==========================================================
  // CURRENT USER AUDIO
  // ==========================================================

  Future<
    bool
  >
  checkCurrentUserAudioAllowed() {
    return checkAudioAllowedFor(
      currentUserId,
    );
  }

  // ==========================================================
  // PROCESSING USER
  // ==========================================================

  bool isProcessingUser(
    String userId,
  ) {
    return _processingUsers.contains(
      userId.trim(),
    );
  }

  // ==========================================================
  // REQUEST VIDEO
  // ==========================================================

  Future<
    CommunicationRequestModel?
  >
  requestVideo({
    required String targetUserId,
  }) async {
    if (_disposed) {
      return null;
    }

    final target = targetUserId.trim();

    if (target.isEmpty ||
        target ==
            currentUserId) {
      _setError(
        'Usuário inválido.',
      );

      return null;
    }

    if (isVideoAllowedFor(
      target,
    )) {
      _setError(
        'O vídeo já está liberado com esse usuário.',
      );

      return null;
    }

    if (hasPendingRequestTo(
      target,
    )) {
      _setError(
        'Já existe um convite de vídeo aguardando resposta.',
      );

      return null;
    }

    final state = inviteStateForUser(
      target,
    );

    if (state?.blockedAfterLimit ==
        true) {
      _setError(
        'O limite de convites foi atingido. '
        'O outro usuário precisa liberar uma nova tentativa.',
      );

      return null;
    }

    if (state?.hasCooldown ==
        true) {
      final label = state!.cooldownLabel;

      _setError(
        label.isEmpty
            ? 'Você ainda precisa aguardar antes de enviar outro convite.'
            : 'Novo convite disponível em $label.',
      );

      return null;
    }

    _setUserProcessing(
      target,
      true,
    );

    try {
      final request = await _service.requestVideo(
        projectId: projectId,

        targetUserId: target,
      );

      await refresh();

      return request;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[COMMUNICATION PERMISSION CONTROLLER] '
        'Erro ao solicitar vídeo: '
        '$error',
      );

      debugPrint(
        '$stackTrace',
      );

      _errorMessage = _mapRequestVideoError(
        error,
      );

      return null;
    } finally {
      _setUserProcessing(
        target,
        false,
      );
    }
  }

  // ==========================================================
  // REQUEST VIDEO UPGRADE
  // ==========================================================

  Future<
    CommunicationRequestModel?
  >
  requestVideoUpgrade({
    required String targetUserId,
    required String callId,
  }) async {
    if (_disposed) {
      return null;
    }

    final target = targetUserId.trim();

    final normalizedCallId = callId.trim();

    if (target.isEmpty ||
        target ==
            currentUserId ||
        normalizedCallId.isEmpty) {
      _setError(
        'Dados inválidos para solicitar vídeo.',
      );

      return null;
    }

    _setUserProcessing(
      target,
      true,
    );

    try {
      final request = await _service.requestVideoUpgrade(
        projectId: projectId,

        targetUserId: target,

        callId: normalizedCallId,
      );

      await refresh();

      return request;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[COMMUNICATION PERMISSION CONTROLLER] '
        'Erro no upgrade de vídeo: '
        '$error',
      );

      debugPrint(
        '$stackTrace',
      );

      _errorMessage = _mapRequestVideoError(
        error,
      );

      return null;
    } finally {
      _setUserProcessing(
        target,
        false,
      );
    }
  }

  // ==========================================================
  // REQUEST VIDEO BULK
  // ==========================================================

  Future<
    List<
      VideoInviteBulkResult
    >
  >
  requestVideoBulk({
    required List<
      String
    >
    targetUserIds,
    String? callId,
    bool videoUpgrade = false,
  }) async {
    if (_disposed ||
        _isProcessing) {
      return const <
        VideoInviteBulkResult
      >[];
    }

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

    _isProcessing = true;

    _processingUsers.addAll(
      targets,
    );

    _errorMessage = null;

    _safeNotify();

    try {
      final result = await _service.requestVideoBulk(
        projectId: projectId,

        targetUserIds: targets,

        callId: callId,

        videoUpgrade: videoUpgrade,
      );

      await refresh();

      return result;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[COMMUNICATION PERMISSION CONTROLLER] '
        'Erro enviando convites em lote: '
        '$error',
      );

      debugPrint(
        '$stackTrace',
      );

      _errorMessage = 'Não foi possível enviar os convites de vídeo.';

      return const <
        VideoInviteBulkResult
      >[];
    } finally {
      if (!_disposed) {
        _processingUsers.removeAll(
          targets,
        );

        _isProcessing = false;

        _safeNotify();
      }
    }
  }

  // ==========================================================
  // ACCEPT REQUEST
  // ==========================================================

  Future<
    bool
  >
  acceptRequest(
    CommunicationRequestModel request,
  ) async {
    if (_disposed ||
        _isProcessing) {
      return false;
    }

    if (!_validateIncomingRequest(
      request,
    )) {
      return false;
    }

    _isProcessing = true;

    _errorMessage = null;

    _safeNotify();

    try {
      await _service.acceptRequest(
        request: request,
      );

      await refresh();

      return true;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[COMMUNICATION PERMISSION CONTROLLER] '
        'Erro ao aceitar solicitação: '
        '$error',
      );

      debugPrint(
        '$stackTrace',
      );

      _errorMessage = 'Não foi possível aceitar a solicitação.';

      return false;
    } finally {
      if (!_disposed) {
        _isProcessing = false;

        _safeNotify();
      }
    }
  }

  // ==========================================================
  // REJECT REQUEST
  // ==========================================================

  Future<
    bool
  >
  rejectRequest(
    CommunicationRequestModel request,
  ) async {
    if (_disposed ||
        _isProcessing) {
      return false;
    }

    if (!_validateIncomingRequest(
      request,
    )) {
      return false;
    }

    _isProcessing = true;

    _errorMessage = null;

    _safeNotify();

    try {
      await _service.rejectRequest(
        request: request,
      );

      await refresh();

      return true;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[COMMUNICATION PERMISSION CONTROLLER] '
        'Erro ao recusar solicitação: '
        '$error',
      );

      debugPrint(
        '$stackTrace',
      );

      _errorMessage = 'Não foi possível recusar a solicitação.';

      return false;
    } finally {
      if (!_disposed) {
        _isProcessing = false;

        _safeNotify();
      }
    }
  }

  // ==========================================================
  // ALLOW NEW INVITE FROM
  // ==========================================================

  Future<
    bool
  >
  allowNewInviteFrom(
    String requesterId,
  ) async {
    if (_disposed ||
        _isProcessing) {
      return false;
    }

    final requester = requesterId.trim();

    if (requester.isEmpty ||
        requester ==
            currentUserId) {
      return false;
    }

    final state = incomingInviteStateFrom(
      requester,
    );

    if (state ==
            null ||
        !state.blockedAfterLimit) {
      _setError(
        'Este usuário não está bloqueado para novos convites.',
      );

      return false;
    }

    _isProcessing = true;

    _errorMessage = null;

    _safeNotify();

    try {
      await _service.allowVideoInvitesFrom(
        projectId: projectId,

        requesterId: requester,
      );

      await refresh();

      return true;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[COMMUNICATION PERMISSION CONTROLLER] '
        'Erro liberando novo convite: '
        '$error',
      );

      debugPrint(
        '$stackTrace',
      );

      _errorMessage = 'Não foi possível liberar uma nova tentativa.';

      return false;
    } finally {
      if (!_disposed) {
        _isProcessing = false;

        _safeNotify();
      }
    }
  }

  // ==========================================================
  // REVOKE VIDEO PERMISSION
  // ==========================================================

  Future<
    bool
  >
  revokeVideoPermission(
    String otherUserId,
  ) async {
    if (_disposed ||
        _isProcessing) {
      return false;
    }

    final other = otherUserId.trim();

    if (other.isEmpty ||
        other ==
            currentUserId) {
      return false;
    }

    if (!isVideoAllowedFor(
      other,
    )) {
      _setError(
        'O vídeo já está bloqueado com esse usuário.',
      );

      return false;
    }

    _isProcessing = true;

    _errorMessage = null;

    _safeNotify();

    try {
      await _service.revokeVideoPermission(
        projectId: projectId,

        otherUserId: other,
      );

      await refresh();

      return true;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[COMMUNICATION PERMISSION CONTROLLER] '
        'Erro revogando vídeo: '
        '$error',
      );

      debugPrint(
        '$stackTrace',
      );

      _errorMessage = 'Não foi possível bloquear o vídeo com esse usuário.';

      return false;
    } finally {
      if (!_disposed) {
        _isProcessing = false;

        _safeNotify();
      }
    }
  }

  // ==========================================================
  // PENDING REQUEST FROM
  // ==========================================================

  CommunicationRequestModel? pendingRequestFrom(
    String senderId,
  ) {
    final sender = senderId.trim();

    if (sender.isEmpty) {
      return null;
    }

    for (final request in pendingReceivedRequests) {
      if (request.senderId ==
          sender) {
        return request;
      }
    }

    return null;
  }

  // ==========================================================
  // HAS PENDING FROM
  // ==========================================================

  bool hasPendingRequestFrom(
    String senderId,
  ) {
    return pendingRequestFrom(
          senderId,
        ) !=
        null;
  }

  // ==========================================================
  // PENDING REQUEST TO
  // ==========================================================

  CommunicationRequestModel? pendingRequestTo(
    String targetUserId,
  ) {
    final target = targetUserId.trim();

    if (target.isEmpty) {
      return null;
    }

    for (final request in pendingSentRequests) {
      if (request.targetUserId ==
          target) {
        return request;
      }
    }

    return null;
  }

  // ==========================================================
  // HAS PENDING TO
  // ==========================================================

  bool hasPendingRequestTo(
    String targetUserId,
  ) {
    return pendingRequestTo(
          targetUserId,
        ) !=
        null;
  }

  // ==========================================================
  // REFRESH
  // ==========================================================

  Future<
    void
  >
  refresh() async {
    if (_disposed) {
      return;
    }

    try {
      await _loadInitialState();
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[COMMUNICATION PERMISSION CONTROLLER] '
        'Erro no refresh: '
        '$error',
      );

      debugPrint(
        '$stackTrace',
      );

      _setError(
        'Não foi possível atualizar as permissões.',
      );
    }
  }

  // ==========================================================
  // VALIDATE INCOMING REQUEST
  // ==========================================================

  bool _validateIncomingRequest(
    CommunicationRequestModel request,
  ) {
    if (!request.isValid) {
      _setError(
        'Solicitação de comunicação inválida.',
      );

      return false;
    }

    if (!request.canRespond) {
      _setError(
        'Essa solicitação não pode mais ser respondida.',
      );

      return false;
    }

    if (!request.isVideoRequest) {
      _setError(
        'Essa solicitação não é um convite de vídeo.',
      );

      return false;
    }

    if (!request.wasSentTo(
      currentUserId,
    )) {
      _setError(
        'Essa solicitação não pertence ao usuário atual.',
      );

      return false;
    }

    return true;
  }

  // ==========================================================
  // PROCESS USER
  // ==========================================================

  void _setUserProcessing(
    String userId,
    bool value,
  ) {
    if (_disposed) {
      return;
    }

    final normalized = userId.trim();

    if (normalized.isEmpty) {
      return;
    }

    if (value) {
      _processingUsers.add(
        normalized,
      );
    } else {
      _processingUsers.remove(
        normalized,
      );
    }

    _safeNotify();
  }

  // ==========================================================
  // CLEAR ERROR
  // ==========================================================

  void clearError() {
    if (_disposed ||
        _errorMessage ==
            null) {
      return;
    }

    _errorMessage = null;

    _safeNotify();
  }

  // ==========================================================
  // MAP VIDEO ERROR
  // ==========================================================

  String _mapRequestVideoError(
    Object error,
  ) {
    final message = error.toString().toLowerCase();

    if (message.contains(
      'vídeo já está liberado',
    )) {
      return 'O vídeo já está liberado com esse usuário.';
    }

    if (message.contains(
          'novo convite permitido somente após',
        ) ||
        message.contains(
          'cooldown',
        )) {
      return 'Você ainda precisa aguardar antes de enviar outro convite.';
    }

    if (message.contains(
          'limite',
        ) ||
        message.contains(
          'outro usuário precisa permitir',
        )) {
      return 'O limite de convites foi atingido. '
          'O outro usuário precisa liberar uma nova tentativa.';
    }

    if (message.contains(
          'pending',
        ) ||
        message.contains(
          'aguardando resposta',
        )) {
      return 'Já existe um convite de vídeo aguardando resposta.';
    }

    if (message.contains(
      'não pertence ao projeto',
    )) {
      return 'Esse usuário não pertence mais ao projeto.';
    }

    return 'Não foi possível enviar o convite de vídeo.';
  }

  // ==========================================================
  // SET ERROR
  // ==========================================================

  void _setError(
    String message,
  ) {
    if (_disposed) {
      return;
    }

    _errorMessage = message;

    _safeNotify();
  }

  // ==========================================================
  // STOP SUBSCRIPTIONS
  // ==========================================================

  Future<
    void
  >
  _stopSubscriptions() async {
    await _permissionsSubscription?.cancel();

    await _inviteStatesSubscription?.cancel();

    await _receivedRequestsSubscription?.cancel();

    await _sentRequestsSubscription?.cancel();

    _permissionsSubscription = null;

    _inviteStatesSubscription = null;

    _receivedRequestsSubscription = null;

    _sentRequestsSubscription = null;
  }

  // ==========================================================
  // SAFE NOTIFY
  // ==========================================================

  void _safeNotify() {
    if (_disposed ||
        !hasListeners) {
      return;
    }

    notifyListeners();
  }

  // ==========================================================
  // PROJECT ID
  // ==========================================================

  static String _requiredProjectId(
    String value,
  ) {
    final normalized = value.trim();

    if (normalized.isEmpty) {
      throw ArgumentError(
        'projectId não pode ser vazio.',
      );
    }

    return normalized;
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    if (_disposed) {
      return;
    }

    _disposed = true;

    unawaited(
      _stopSubscriptions(),
    );

    _permissions =
        const <
          CommunicationPermissionModel
        >[];

    _inviteStates =
        const <
          CommunicationVideoInviteStateModel
        >[];

    _receivedRequests =
        const <
          CommunicationRequestModel
        >[];

    _sentRequests =
        const <
          CommunicationRequestModel
        >[];

    _audioPermissions.clear();

    _processingUsers.clear();

    super.dispose();
  }
}
