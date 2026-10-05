import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../services/call_signaling_service.dart';
import '../services/webrtc_call_service.dart';

// ============================================================
// WEBRTC CALL CONTROLLER
// ============================================================
//
// Faz a ponte entre:
//
// CallView
//    ↓
// WebRtcCallController
//    ↓
// ┌──────────────────────┐
// │ WebRtcCallService    │
// │ áudio / vídeo / ICE  │
// └──────────────────────┘
//            +
// ┌──────────────────────┐
// │ CallSignalingService │
// │ Supabase Realtime    │
// └──────────────────────┘
//
// ============================================================

class WebRtcCallController
    with
        ChangeNotifier {
  // ==========================================================
  // SERVICES
  // ==========================================================

  final WebRtcCallService _webRtc;

  final CallSignalingService _signaling;

  // ==========================================================
  // IDENTIFICAÇÃO
  // ==========================================================

  String? _callId;

  String? _currentUserId;

  String? _remoteUserId;

  // ==========================================================
  // STATE
  // ==========================================================

  bool _initialized = false;

  bool _initializing = false;

  bool _connected = false;

  bool _disposed = false;

  String? _errorMessage;

  // ==========================================================
  // CONSTRUCTOR
  // ==========================================================

  WebRtcCallController({
    WebRtcCallService? webRtc,
    CallSignalingService? signaling,
  }) : _webRtc =
           webRtc ??
           WebRtcCallService(),
       _signaling =
           signaling ??
           CallSignalingService() {
    _configureCallbacks();
  }

  // ==========================================================
  // GETTERS
  // ==========================================================

  bool get initialized => _initialized;

  bool get initializing => _initializing;

  bool get connected => _connected;

  bool get microphoneEnabled => _webRtc.microphoneEnabled;

  bool get cameraEnabled => _webRtc.cameraEnabled;

  bool get speakerEnabled => _webRtc.speakerEnabled;

  String? get errorMessage => _errorMessage;

  MediaStream? get localStream => _webRtc.localStream;

  RTCVideoRenderer? get localRenderer => _webRtc.localRenderer;

  Map<
    String,
    RTCVideoRenderer
  >
  get remoteRenderers => _webRtc.remoteRenderers;

  // ==========================================================
  // CONFIGURAR CALLBACKS
  // ==========================================================

  void _configureCallbacks() {
    // ========================================================
    // ICE LOCAL
    // ========================================================

    _webRtc.onIceCandidate =
        (
          String remoteUserId,
          RTCIceCandidate candidate,
        ) {
          if (_disposed) {
            return;
          }

          final candidateValue = candidate.candidate;

          if (candidateValue ==
                  null ||
              candidateValue.trim().isEmpty) {
            return;
          }

          unawaited(
            _signaling.sendIceCandidate(
              toUserId: remoteUserId,
              candidate: candidateValue,
              sdpMid: candidate.sdpMid,
              sdpMLineIndex: candidate.sdpMLineIndex,
            ),
          );
        };

    // ========================================================
    // STREAM REMOTO
    // ========================================================

    _webRtc.onRemoteStream =
        (
          String remoteUserId,
          MediaStream stream,
        ) {
          if (_disposed) {
            return;
          }

          debugPrint(
            '[WEBRTC CONTROLLER] '
            'Stream remoto recebido de '
            '$remoteUserId',
          );

          _connected = true;

          _safeNotify();
        };

    // ========================================================
    // CONNECTION STATE
    // ========================================================

    _webRtc.onConnectionState =
        (
          String remoteUserId,
          RTCPeerConnectionState state,
        ) {
          if (_disposed) {
            return;
          }

          debugPrint(
            '[WEBRTC CONTROLLER] '
            'Peer $remoteUserId: '
            '$state',
          );

          switch (state) {
            case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
              _connected = true;

              break;

            case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
            case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
            case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
              _connected = false;

              break;

            default:
              break;
          }

          _safeNotify();
        };

    // ========================================================
    // REMOTE DISCONNECTED
    // ========================================================

    _webRtc.onRemoteDisconnected =
        (
          String remoteUserId,
        ) {
          if (_disposed) {
            return;
          }

          _connected = false;

          _safeNotify();
        };

    // ========================================================
    // OFFER REMOTA
    // ========================================================

    _signaling.onOffer =
        ({
          required String fromUserId,
          required String sdp,
        }) {
          unawaited(
            _handleRemoteOffer(
              fromUserId: fromUserId,
              sdp: sdp,
            ),
          );
        };

    // ========================================================
    // ANSWER REMOTA
    // ========================================================

    _signaling.onAnswer =
        ({
          required String fromUserId,
          required String sdp,
        }) {
          unawaited(
            _handleRemoteAnswer(
              fromUserId: fromUserId,
              sdp: sdp,
            ),
          );
        };

    // ========================================================
    // ICE REMOTO
    // ========================================================

    _signaling.onIceCandidate =
        ({
          required String fromUserId,
          required String candidate,
          String? sdpMid,
          int? sdpMLineIndex,
        }) {
          unawaited(
            _handleRemoteIce(
              fromUserId: fromUserId,
              candidate: candidate,
              sdpMid: sdpMid,
              sdpMLineIndex: sdpMLineIndex,
            ),
          );
        };

    // ========================================================
    // HANGUP
    // ========================================================

    _signaling.onHangup =
        ({
          required String fromUserId,
        }) {
          unawaited(
            _handleRemoteHangup(
              fromUserId,
            ),
          );
        };

    // ========================================================
    // SIGNALING ERROR
    // ========================================================

    _signaling.onError =
        (
          Object error,
        ) {
          if (_disposed) {
            return;
          }

          debugPrint(
            '[WEBRTC CONTROLLER] '
            'Erro signaling: '
            '$error',
          );

          _errorMessage = 'Falha na conexão da chamada.';

          _safeNotify();
        };
  }

  // ==========================================================
  // INITIALIZE
  // ==========================================================

  Future<
    bool
  >
  initialize({
    required String callId,
    required String currentUserId,
    required String remoteUserId,
    required bool enableVideo,
  }) async {
    if (_disposed ||
        _initializing) {
      return false;
    }

    final normalizedCallId = callId.trim();

    final normalizedCurrentUserId = currentUserId.trim();

    final normalizedRemoteUserId = remoteUserId.trim();

    if (normalizedCallId.isEmpty ||
        normalizedCurrentUserId.isEmpty ||
        normalizedRemoteUserId.isEmpty) {
      _errorMessage = 'Dados da chamada incompletos.';

      _safeNotify();

      return false;
    }

    if (_initialized &&
        _callId ==
            normalizedCallId &&
        _remoteUserId ==
            normalizedRemoteUserId) {
      return true;
    }

    _initializing = true;

    _errorMessage = null;

    _safeNotify();

    try {
      _callId = normalizedCallId;

      _currentUserId = normalizedCurrentUserId;

      _remoteUserId = normalizedRemoteUserId;

      // ======================================================
      // MICROFONE / CÂMERA
      // ======================================================

      await _webRtc.initializeLocalMedia(
        enableAudio: true,
        enableVideo: enableVideo,
      );

      // ======================================================
      // SIGNALING
      // ======================================================

      await _signaling.start(
        callId: normalizedCallId,
        currentUserId: normalizedCurrentUserId,
      );

      // ======================================================
      // PEER
      // ======================================================

      await _webRtc.ensurePeer(
        normalizedRemoteUserId,
      );

      _initialized = true;

      _safeNotify();

      return true;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[WEBRTC CONTROLLER] '
        'Erro initialize: '
        '$error',
      );

      debugPrint(
        '$stackTrace',
      );

      _errorMessage = 'Não foi possível preparar áudio da chamada.';

      return false;
    } finally {
      if (!_disposed) {
        _initializing = false;

        _safeNotify();
      }
    }
  }

  // ==========================================================
  // CALLER: CRIAR OFFER
  // ==========================================================

  Future<
    bool
  >
  startAsCaller() async {
    if (_disposed ||
        !_initialized) {
      return false;
    }

    final remoteUserId = _remoteUserId;

    if (remoteUserId ==
            null ||
        remoteUserId.isEmpty) {
      return false;
    }

    try {
      final offer = await _webRtc.createOffer(
        remoteUserId,
      );

      final sdp = offer.sdp;

      if (sdp ==
              null ||
          sdp.trim().isEmpty) {
        throw StateError(
          'Offer criada sem SDP.',
        );
      }

      await _signaling.sendOffer(
        toUserId: remoteUserId,
        sdp: sdp,
      );

      debugPrint(
        '[WEBRTC CONTROLLER] '
        'Offer enviada.',
      );

      return true;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[WEBRTC CONTROLLER] '
        'Erro criando offer: '
        '$error',
      );

      debugPrint(
        '$stackTrace',
      );

      _errorMessage = 'Não foi possível iniciar a conexão de áudio.';

      _safeNotify();

      return false;
    }
  }

  // ==========================================================
  // RECEBER OFFER
  // ==========================================================

  Future<
    void
  >
  _handleRemoteOffer({
    required String fromUserId,
    required String sdp,
  }) async {
    if (_disposed) {
      return;
    }

    try {
      final answer = await _webRtc.handleOffer(
        remoteUserId: fromUserId,
        sdp: sdp,
      );

      final answerSdp = answer.sdp;

      if (answerSdp ==
              null ||
          answerSdp.trim().isEmpty) {
        return;
      }

      await _signaling.sendAnswer(
        toUserId: fromUserId,
        sdp: answerSdp,
      );

      debugPrint(
        '[WEBRTC CONTROLLER] '
        'Answer enviada.',
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[WEBRTC CONTROLLER] '
        'Erro processando offer: '
        '$error',
      );

      debugPrint(
        '$stackTrace',
      );

      _errorMessage = 'Erro na negociação da chamada.';

      _safeNotify();
    }
  }

  // ==========================================================
  // RECEBER ANSWER
  // ==========================================================

  Future<
    void
  >
  _handleRemoteAnswer({
    required String fromUserId,
    required String sdp,
  }) async {
    if (_disposed) {
      return;
    }

    try {
      await _webRtc.handleAnswer(
        remoteUserId: fromUserId,
        sdp: sdp,
      );

      debugPrint(
        '[WEBRTC CONTROLLER] '
        'Answer aplicada.',
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[WEBRTC CONTROLLER] '
        'Erro processando answer: '
        '$error',
      );

      debugPrint(
        '$stackTrace',
      );
    }
  }

  // ==========================================================
  // RECEBER ICE
  // ==========================================================

  Future<
    void
  >
  _handleRemoteIce({
    required String fromUserId,
    required String candidate,
    String? sdpMid,
    int? sdpMLineIndex,
  }) async {
    if (_disposed) {
      return;
    }

    try {
      await _webRtc.addIceCandidate(
        remoteUserId: fromUserId,
        candidate: candidate,
        sdpMid: sdpMid,
        sdpMLineIndex: sdpMLineIndex,
      );
    } catch (
      error
    ) {
      debugPrint(
        '[WEBRTC CONTROLLER] '
        'Erro ICE: '
        '$error',
      );
    }
  }

  // ==========================================================
  // REMOTE HANGUP
  // ==========================================================

  Future<
    void
  >
  _handleRemoteHangup(
    String remoteUserId,
  ) async {
    await _webRtc.closePeer(
      remoteUserId,
    );

    _connected = false;

    _safeNotify();
  }

  // ==========================================================
  // MICROFONE
  // ==========================================================

  Future<
    bool
  >
  toggleMicrophone() async {
    if (_disposed ||
        !_initialized) {
      return false;
    }

    final result = await _webRtc.toggleMicrophone();

    if (result) {
      await _sendMediaState();

      _safeNotify();
    }

    return result;
  }

  // ==========================================================
  // CÂMERA
  // ==========================================================

  Future<
    bool
  >
  toggleCamera() async {
    if (_disposed ||
        !_initialized) {
      return false;
    }

    final result = await _webRtc.toggleCamera();

    if (result) {
      await _sendMediaState();

      _safeNotify();
    }

    return result;
  }

  // ==========================================================
  // SPEAKER
  // ==========================================================

  Future<
    void
  >
  toggleSpeaker() async {
    if (_disposed ||
        !_initialized) {
      return;
    }

    await _webRtc.toggleSpeaker();

    _safeNotify();
  }

  // ==========================================================
  // SWITCH CAMERA
  // ==========================================================

  Future<
    bool
  >
  switchCamera() async {
    if (_disposed ||
        !_initialized) {
      return false;
    }

    final result = await _webRtc.switchCamera();

    _safeNotify();

    return result;
  }

  // ==========================================================
  // MEDIA STATE
  // ==========================================================

  Future<
    void
  >
  _sendMediaState() async {
    final remoteUserId = _remoteUserId;

    if (remoteUserId ==
            null ||
        remoteUserId.isEmpty) {
      return;
    }

    try {
      await _signaling.sendMediaState(
        toUserId: remoteUserId,
        microphoneEnabled: microphoneEnabled,
        cameraEnabled: cameraEnabled,
      );
    } catch (
      error
    ) {
      debugPrint(
        '[WEBRTC CONTROLLER] '
        'Erro enviando media state: '
        '$error',
      );
    }
  }

  // ==========================================================
  // HANGUP
  // ==========================================================

  Future<
    void
  >
  hangup() async {
    final remoteUserId = _remoteUserId;

    if (remoteUserId !=
            null &&
        remoteUserId.isNotEmpty) {
      try {
        await _signaling.sendHangup(
          toUserId: remoteUserId,
        );
      } catch (
        error
      ) {
        debugPrint(
          '[WEBRTC CONTROLLER] '
          'Erro enviando hangup: '
          '$error',
        );
      }
    }

    await _webRtc.closeAllPeers();

    _connected = false;

    _safeNotify();
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
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    if (_disposed) {
      return;
    }

    _disposed = true;

    unawaited(
      _signaling.dispose(),
    );

    unawaited(
      _webRtc.dispose(),
    );

    super.dispose();
  }
}
