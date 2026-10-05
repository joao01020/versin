import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/models/project_call_model.dart';

import '../data/repositories/project_call_repository_impl.dart';

import '../repositories/project_call_repository.dart';

import '../types/call_media_type.dart';

// ============================================================
// PROJECT CALL CONTROLLER
// ============================================================
//
// Responsável pelo estado de chamadas dentro de uma
// Studio Session.
//
// Responsabilidades:
//
// - observar chamadas do projeto;
// - detectar chamada ativa;
// - iniciar áudio;
// - iniciar vídeo;
// - aceitar chamada;
// - recusar chamada;
// - encerrar chamada;
// - sincronizar estado via Realtime.
//
// NÃO cuida de:
//
// - microfone;
// - câmera;
// - WebRTC;
// - SDP;
// - ICE.
//
// Essas responsabilidades ficarão em:
//
// WebRtcCallService
// CallSignalingService
//
// ============================================================

class ProjectCallController
    with
        ChangeNotifier {
  // ==========================================================
  // PROJECT
  // ==========================================================

  final String projectId;

  // ==========================================================
  // REPOSITORY
  // ==========================================================

  final ProjectCallRepository _repository;

  // ==========================================================
  // SUBSCRIPTIONS
  // ==========================================================

  StreamSubscription<
    List<
      ProjectCallModel
    >
  >?
  _projectCallsSubscription;

  StreamSubscription<
    ProjectCallModel?
  >?
  _activeCallSubscription;

  Timer? _clockTimer;

  static const Duration ringingTimeout = Duration(
    seconds: 30,
  );

  // ==========================================================
  // STATE
  // ==========================================================

  List<
    ProjectCallModel
  >
  _calls =
      const <
        ProjectCallModel
      >[];

  ProjectCallModel? _activeCall;

  bool _isLoading = false;

  bool _isProcessing = false;

  bool _disposed = false;

  String? _errorMessage;

  DateTime? _callStartedAt;

  DateTime? _ringingStartedAt;

  bool _ringingTimeoutInProgress = false;

  String? _currentParticipantName;

  // ==========================================================
  // CONSTRUCTOR
  // ==========================================================

  ProjectCallController({
    required String projectId,
    ProjectCallRepository? repository,
  }) : projectId = _requiredProjectId(
         projectId,
       ),
       _repository =
           repository ??
           ProjectCallRepositoryImpl();

  // ==========================================================
  // GETTERS
  // ==========================================================

  List<
    ProjectCallModel
  >
  get calls => _calls;

  ProjectCallModel? get activeCall => _activeCall;

  bool get isLoading => _isLoading;

  bool get isProcessing => _isProcessing;

  bool get hasError =>
      _errorMessage !=
      null;

  String? get errorMessage => _errorMessage;

  bool get hasActiveCall =>
      _activeCall !=
          null &&
      !_activeCall!.isFinished;

  bool get isRinging =>
      _activeCall?.isRinging ??
      false;

  bool get isInCall =>
      _activeCall?.isActive ??
      false;

  // ==========================================================
  // GLOBAL CALL STATE
  // ==========================================================

  bool get isCalling {
    final call = _activeCall;

    if (call ==
        null) {
      return false;
    }

    return call.isRinging &&
        _repository.currentUserId ==
            call.createdBy;
  }

  bool get isIncomingCall {
    final call = _activeCall;

    if (call ==
        null) {
      return false;
    }

    return call.isRinging &&
        _repository.currentUserId !=
            call.createdBy;
  }

  bool get isEndingCall =>
      _isProcessing &&
      _activeCall !=
          null &&
      _activeCall!.canEnd;

  String? get currentParticipantName => _currentParticipantName;

  Duration get currentCallDuration {
    final startedAt = _callStartedAt;

    if (startedAt ==
            null ||
        !isInCall) {
      return Duration.zero;
    }

    return DateTime.now().difference(
      startedAt,
    );
  }

  Duration get currentRingingDuration {
    final startedAt = _ringingStartedAt;

    if (startedAt ==
            null ||
        !isRinging) {
      return Duration.zero;
    }

    final elapsed = DateTime.now().difference(
      startedAt,
    );

    return elapsed.isNegative
        ? Duration.zero
        : elapsed;
  }

  Duration get remainingRingingDuration {
    final remaining =
        ringingTimeout -
        currentRingingDuration;

    return remaining.isNegative
        ? Duration.zero
        : remaining;
  }

  bool get hasRingingTimedOut =>
      isRinging &&
      currentRingingDuration >=
          ringingTimeout;

  String get currentCallParticipantId {
    final call = _activeCall;

    if (call ==
        null) {
      return '';
    }

    final currentUserId = _repository.currentUserId;

    if (call.createdBy ==
        currentUserId) {
      return call.targetUserId?.trim() ??
          '';
    }

    return call.createdBy.trim();
  }

  void setCurrentParticipantName(
    String? value,
  ) {
    final normalized = value?.trim();

    _currentParticipantName =
        normalized ==
                null ||
            normalized.isEmpty
        ? null
        : normalized;

    _safeNotify();
  }

  // ==========================================================
  // SYNC CALL CLOCK
  // ==========================================================

  void _syncCallClock(
    ProjectCallModel? call,
  ) {
    if (call ==
            null ||
        call.isFinished) {
      _callStartedAt = null;
      _ringingStartedAt = null;
      _stopClockTimer();
      return;
    }

    if (call.isRinging) {
      _callStartedAt = null;
      _ringingStartedAt ??= DateTime.now();
      _ensureClockTimer();
      return;
    }

    if (call.isActive) {
      _ringingStartedAt = null;
      _callStartedAt ??= DateTime.now();
      _ensureClockTimer();
      return;
    }

    _callStartedAt = null;
    _ringingStartedAt = null;
    _stopClockTimer();
  }

  // ==========================================================
  // CLOCK TIMER
  // ==========================================================

  void _ensureClockTimer() {
    if (_disposed ||
        _clockTimer !=
            null) {
      return;
    }

    _clockTimer = Timer.periodic(
      const Duration(
        seconds: 1,
      ),
      (
        _,
      ) {
        if (_disposed) {
          return;
        }

        if (!isRinging &&
            !isInCall) {
          _stopClockTimer();
          return;
        }

        _safeNotify();

        if (hasRingingTimedOut) {
          unawaited(
            _handleRingingTimeout(),
          );
        }
      },
    );
  }

  void _stopClockTimer() {
    _clockTimer?.cancel();
    _clockTimer = null;
  }

  // ==========================================================
  // RINGING TIMEOUT
  // ==========================================================

  Future<
    void
  >
  _handleRingingTimeout() async {
    if (_disposed ||
        _ringingTimeoutInProgress ||
        !isRinging) {
      return;
    }

    _ringingTimeoutInProgress = true;

    try {
      await endCall();
    } finally {
      _ringingTimeoutInProgress = false;
    }
  }

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
      // PROJECT CALLS REALTIME
      // ======================================================

      _projectCallsSubscription = _repository
          .streamProjectCalls(
            projectId: projectId,
          )
          .listen(
            _handleProjectCalls,
            onError: _handleProjectCallsError,
          );

      // ======================================================
      // INITIAL ACTIVE CALL
      // ======================================================

      final currentCall = await _repository.getActiveCall(
        projectId: projectId,
      );

      if (_disposed) {
        return;
      }

      _activeCall = currentCall;

      _syncCallClock(
        currentCall,
      );

      if (currentCall !=
          null) {
        _listenToActiveCall(
          currentCall.id,
        );
      }

      _isLoading = false;

      _safeNotify();
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[PROJECT CALL CONTROLLER] '
        'Erro no init: '
        '$error',
      );

      debugPrint(
        '[PROJECT CALL CONTROLLER] '
        'StackTrace: '
        '$stackTrace',
      );

      if (_disposed) {
        return;
      }

      _isLoading = false;

      _errorMessage = 'Não foi possível carregar as chamadas.';

      _safeNotify();
    }
  }

  // ==========================================================
  // HANDLE PROJECT CALLS
  // ==========================================================

  void _handleProjectCalls(
    List<
      ProjectCallModel
    >
    calls,
  ) {
    if (_disposed) {
      return;
    }

    _calls =
        List<
          ProjectCallModel
        >.unmodifiable(
          calls,
        );

    // ========================================================
    // DESCOBRIR CHAMADA ATIVA PELO STREAM
    // ========================================================

    ProjectCallModel? discoveredActiveCall;

    for (final call in calls) {
      if (call.isRinging ||
          call.isActive) {
        discoveredActiveCall = call;

        break;
      }
    }

    final currentId = _activeCall?.id;

    final discoveredId = discoveredActiveCall?.id;

    if (currentId !=
        discoveredId) {
      _activeCall = discoveredActiveCall;

      _syncCallClock(
        discoveredActiveCall,
      );

      unawaited(
        _activeCallSubscription?.cancel(),
      );

      _activeCallSubscription = null;

      if (discoveredActiveCall !=
          null) {
        _listenToActiveCall(
          discoveredActiveCall.id,
        );
      }
    } else if (discoveredActiveCall !=
        null) {
      _activeCall = discoveredActiveCall;

      _syncCallClock(
        discoveredActiveCall,
      );
    }

    _isLoading = false;

    _safeNotify();
  }

  // ==========================================================
  // PROJECT CALL STREAM ERROR
  // ==========================================================

  void _handleProjectCallsError(
    Object error,
    StackTrace stackTrace,
  ) {
    debugPrint(
      '[PROJECT CALL CONTROLLER] '
      'Erro Realtime das chamadas: '
      '$error',
    );

    debugPrint(
      '$stackTrace',
    );

    if (_disposed) {
      return;
    }

    _errorMessage = 'Erro ao atualizar chamadas.';

    _safeNotify();
  }

  // ==========================================================
  // LISTEN ACTIVE CALL
  // ==========================================================

  void _listenToActiveCall(
    String callId,
  ) {
    if (_disposed) {
      return;
    }

    unawaited(
      _activeCallSubscription?.cancel(),
    );

    _activeCallSubscription = _repository
        .streamCall(
          callId: callId,
        )
        .listen(
          _handleActiveCall,
          onError: _handleActiveCallError,
        );
  }

  // ==========================================================
  // ACTIVE CALL UPDATED
  // ==========================================================

  void _handleActiveCall(
    ProjectCallModel? call,
  ) {
    if (_disposed) {
      return;
    }

    _activeCall = call;

    _syncCallClock(
      call,
    );

    if (call ==
            null ||
        call.isFinished) {
      unawaited(
        _activeCallSubscription?.cancel(),
      );

      _activeCallSubscription = null;
    }

    _safeNotify();
  }

  // ==========================================================
  // ACTIVE CALL ERROR
  // ==========================================================

  void _handleActiveCallError(
    Object error,
    StackTrace stackTrace,
  ) {
    debugPrint(
      '[PROJECT CALL CONTROLLER] '
      'Erro Realtime chamada ativa: '
      '$error',
    );

    debugPrint(
      '$stackTrace',
    );

    if (_disposed) {
      return;
    }

    _errorMessage = 'Erro ao sincronizar a chamada.';

    _safeNotify();
  }

  // ==========================================================
  // START AUDIO CALL
  // ==========================================================

  Future<
    ProjectCallModel?
  >
  startAudioCall({
    String? targetUserId,
  }) {
    return startCall(
      mediaType: CallMediaType.audio,

      targetUserId: targetUserId,
    );
  }

  // ==========================================================
  // START VIDEO CALL
  // ==========================================================

  Future<
    ProjectCallModel?
  >
  startVideoCall({
    String? targetUserId,
  }) {
    return startCall(
      mediaType: CallMediaType.video,

      targetUserId: targetUserId,
    );
  }

  // ==========================================================
  // START CALL
  // ==========================================================

  Future<
    ProjectCallModel?
  >
  startCall({
    required CallMediaType mediaType,
    String? targetUserId,
  }) async {
    if (_disposed ||
        _isProcessing) {
      return null;
    }

    if (hasActiveCall) {
      _setError(
        'Já existe uma chamada ativa nesta sessão.',
      );

      return null;
    }

    final normalizedTarget = _nullable(
      targetUserId,
    );

    _isProcessing = true;

    _errorMessage = null;

    _safeNotify();

    try {
      final call = await _repository.createCall(
        projectId: projectId,

        mediaType: mediaType,

        targetUserId: normalizedTarget,
      );

      if (_disposed) {
        return call;
      }

      _activeCall = call;

      _syncCallClock(
        call,
      );

      _listenToActiveCall(
        call.id,
      );

      _safeNotify();

      return call;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[PROJECT CALL CONTROLLER] '
        'Erro ao iniciar chamada: '
        '$error',
      );

      debugPrint(
        '$stackTrace',
      );

      _errorMessage = mediaType.isVideo
          ? 'Não foi possível iniciar a chamada de vídeo.'
          : 'Não foi possível iniciar a chamada de áudio.';

      return null;
    } finally {
      if (!_disposed) {
        _isProcessing = false;

        _safeNotify();
      }
    }
  }

  // ==========================================================
  // ACCEPT CALL
  // ==========================================================

  Future<
    bool
  >
  acceptCall({
    ProjectCallModel? call,
  }) async {
    if (_disposed ||
        _isProcessing) {
      return false;
    }

    final targetCall =
        call ??
        _activeCall;

    if (targetCall ==
        null) {
      _setError(
        'Nenhuma chamada para aceitar.',
      );

      return false;
    }

    if (!targetCall.canAccept) {
      _setError(
        'Essa chamada não pode mais ser aceita.',
      );

      return false;
    }

    _isProcessing = true;

    _errorMessage = null;

    _safeNotify();

    try {
      final updatedCall = await _repository.acceptCall(
        callId: targetCall.id,
      );

      if (_disposed) {
        return true;
      }

      _activeCall = updatedCall;

      _syncCallClock(
        updatedCall,
      );

      _listenToActiveCall(
        updatedCall.id,
      );

      return true;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[PROJECT CALL CONTROLLER] '
        'Erro ao aceitar chamada: '
        '$error',
      );

      debugPrint(
        '$stackTrace',
      );

      _errorMessage = 'Não foi possível aceitar a chamada.';

      return false;
    } finally {
      if (!_disposed) {
        _isProcessing = false;

        _safeNotify();
      }
    }
  }

  // ==========================================================
  // REJECT CALL
  // ==========================================================

  Future<
    bool
  >
  rejectCall({
    ProjectCallModel? call,
  }) async {
    if (_disposed ||
        _isProcessing) {
      return false;
    }

    final targetCall =
        call ??
        _activeCall;

    if (targetCall ==
        null) {
      _setError(
        'Nenhuma chamada para recusar.',
      );

      return false;
    }

    if (!targetCall.canReject) {
      _setError(
        'Essa chamada não pode mais ser recusada.',
      );

      return false;
    }

    _isProcessing = true;

    _errorMessage = null;

    _safeNotify();

    try {
      final updatedCall = await _repository.rejectCall(
        callId: targetCall.id,
      );

      if (!_disposed) {
        _activeCall = updatedCall;

        _syncCallClock(
          updatedCall,
        );

        _safeNotify();
      }

      return true;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[PROJECT CALL CONTROLLER] '
        'Erro ao recusar chamada: '
        '$error',
      );

      debugPrint(
        '$stackTrace',
      );

      _errorMessage = 'Não foi possível recusar a chamada.';

      return false;
    } finally {
      if (!_disposed) {
        _isProcessing = false;

        _safeNotify();
      }
    }
  }

  // ==========================================================
  // END CALL
  // ==========================================================

  Future<
    bool
  >
  endCall() async {
    if (_disposed ||
        _isProcessing) {
      return false;
    }

    final call = _activeCall;

    if (call ==
        null) {
      return true;
    }

    if (!call.canEnd) {
      _activeCall = null;

      _safeNotify();

      return true;
    }

    _isProcessing = true;

    _errorMessage = null;

    _safeNotify();

    try {
      final endedCall = await _repository.endCall(
        callId: call.id,
      );

      if (_disposed) {
        return true;
      }

      _activeCall = endedCall;

      _syncCallClock(
        endedCall,
      );

      await _activeCallSubscription?.cancel();

      _activeCallSubscription = null;

      _safeNotify();

      return true;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[PROJECT CALL CONTROLLER] '
        'Erro ao encerrar chamada: '
        '$error',
      );

      debugPrint(
        '$stackTrace',
      );

      _errorMessage = 'Não foi possível encerrar a chamada.';

      return false;
    } finally {
      if (!_disposed) {
        _isProcessing = false;

        _safeNotify();
      }
    }
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
      final calls = await _repository.getProjectCalls(
        projectId: projectId,
      );

      final activeCall = await _repository.getActiveCall(
        projectId: projectId,
      );

      if (_disposed) {
        return;
      }

      _calls =
          List<
            ProjectCallModel
          >.unmodifiable(
            calls,
          );

      _activeCall = activeCall;

      _syncCallClock(
        activeCall,
      );

      if (activeCall !=
          null) {
        _listenToActiveCall(
          activeCall.id,
        );
      }

      _errorMessage = null;

      _safeNotify();
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[PROJECT CALL CONTROLLER] '
        'Erro no refresh: '
        '$error',
      );

      debugPrint(
        '$stackTrace',
      );

      _setError(
        'Não foi possível atualizar as chamadas.',
      );
    }
  }

  // ==========================================================
  // CALL BY ID
  // ==========================================================

  ProjectCallModel? callById(
    String callId,
  ) {
    final normalized = callId.trim();

    if (normalized.isEmpty) {
      return null;
    }

    for (final call in _calls) {
      if (call.id ==
          normalized) {
        return call;
      }
    }

    return null;
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

  // ==========================================================
  // STOP SUBSCRIPTIONS
  // ==========================================================

  Future<
    void
  >
  _stopSubscriptions() async {
    _stopClockTimer();

    await _projectCallsSubscription?.cancel();

    await _activeCallSubscription?.cancel();

    _projectCallsSubscription = null;

    _activeCallSubscription = null;
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

    _stopClockTimer();

    unawaited(
      _stopSubscriptions(),
    );

    super.dispose();
  }
}
