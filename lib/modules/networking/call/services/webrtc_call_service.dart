import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

// ============================================================
// WEBRTC CALL SERVICE
// ============================================================
//
// Responsabilidade:
//
// - microfone;
// - câmera;
// - MediaStream local;
// - RTCPeerConnection;
// - offer;
// - answer;
// - ICE;
// - streams remotos;
// - renderers;
// - troca de câmera;
// - speaker.
//
// NÃO conhece:
//
// - Supabase;
// - banco;
// - ProjectCallModel;
// - RLS.
//
// ============================================================

class WebRtcCallService {
  // ==========================================================
  // ICE CONFIGURATION
  // ==========================================================
  //
  // STUN público serve para desenvolvimento inicial.
  //
  // Para produção com NAT restritivo será necessário TURN.
  //
  // ==========================================================

  final Map<
    String,
    dynamic
  >
  _peerConfiguration;

  // ==========================================================
  // LOCAL MEDIA
  // ==========================================================

  MediaStream? _localStream;

  RTCVideoRenderer? _localRenderer;

  // ==========================================================
  // PEERS
  // ==========================================================

  final Map<
    String,
    RTCPeerConnection
  >
  _peerConnections =
      <
        String,
        RTCPeerConnection
      >{};

  // ==========================================================
  // REMOTE STREAMS
  // ==========================================================

  final Map<
    String,
    MediaStream
  >
  _remoteStreams =
      <
        String,
        MediaStream
      >{};

  // ==========================================================
  // REMOTE RENDERERS
  // ==========================================================

  final Map<
    String,
    RTCVideoRenderer
  >
  _remoteRenderers =
      <
        String,
        RTCVideoRenderer
      >{};

  // ==========================================================
  // PENDING ICE
  // ==========================================================

  final Map<
    String,
    List<
      RTCIceCandidate
    >
  >
  _pendingIceCandidates =
      <
        String,
        List<
          RTCIceCandidate
        >
      >{};

  // ==========================================================
  // STATE
  // ==========================================================

  bool _microphoneEnabled = true;

  bool _cameraEnabled = false;

  bool _speakerEnabled = true;

  bool _disposed = false;

  // ==========================================================
  // CALLBACKS
  // ==========================================================

  void Function(
    String remoteUserId,
    RTCIceCandidate candidate,
  )?
  onIceCandidate;

  void Function(
    String remoteUserId,
    MediaStream stream,
  )?
  onRemoteStream;

  void Function(
    String remoteUserId,
    RTCPeerConnectionState state,
  )?
  onConnectionState;

  void Function(
    String remoteUserId,
  )?
  onRemoteDisconnected;

  // ==========================================================
  // CONSTRUCTOR
  // ==========================================================

  WebRtcCallService({
    Map<
      String,
      dynamic
    >?
    peerConfiguration,
  }) : _peerConfiguration =
           peerConfiguration ??
           const <
             String,
             dynamic
           >{
             'iceServers': [
               {
                 'urls': [
                   'stun:stun.l.google.com:19302',
                 ],
               },
             ],
             'sdpSemantics': 'unified-plan',
           };

  // ==========================================================
  // GETTERS
  // ==========================================================

  MediaStream? get localStream => _localStream;

  RTCVideoRenderer? get localRenderer => _localRenderer;

  bool get microphoneEnabled => _microphoneEnabled;

  bool get cameraEnabled => _cameraEnabled;

  bool get speakerEnabled => _speakerEnabled;

  Map<
    String,
    RTCVideoRenderer
  >
  get remoteRenderers =>
      Map<
        String,
        RTCVideoRenderer
      >.unmodifiable(
        _remoteRenderers,
      );

  Iterable<
    String
  >
  get remoteUserIds => _peerConnections.keys;

  // ==========================================================
  // INITIALIZE LOCAL MEDIA
  // ==========================================================

  Future<
    void
  >
  initializeLocalMedia({
    bool enableAudio = true,
    bool enableVideo = false,
  }) async {
    _ensureNotDisposed();

    await _disposeLocalMedia();

    final constraints =
        <
          String,
          dynamic
        >{
          'audio': enableAudio,

          'video': enableVideo
              ? <
                  String,
                  dynamic
                >{
                  'facingMode': 'user',

                  'width': 1280,

                  'height': 720,

                  'frameRate': 30,
                }
              : false,
        };

    final stream = await navigator.mediaDevices.getUserMedia(
      constraints,
    );

    _localStream = stream;

    _microphoneEnabled = enableAudio;

    _cameraEnabled = enableVideo;

    // ========================================================
    // TRACK STATE
    // ========================================================

    for (final track in stream.getAudioTracks()) {
      track.enabled = enableAudio;
    }

    for (final track in stream.getVideoTracks()) {
      track.enabled = enableVideo;
    }

    // ========================================================
    // LOCAL RENDERER
    // ========================================================

    final renderer = RTCVideoRenderer();

    await renderer.initialize();

    renderer.srcObject = stream;

    renderer.muted = true;

    _localRenderer = renderer;
  }

  // ==========================================================
  // CREATE PEER
  // ==========================================================

  Future<
    RTCPeerConnection
  >
  ensurePeer(
    String remoteUserId,
  ) async {
    _ensureNotDisposed();

    final normalizedUserId = _required(
      remoteUserId,
      'remoteUserId',
    );

    final existing = _peerConnections[normalizedUserId];

    if (existing !=
        null) {
      return existing;
    }

    final peer = await createPeerConnection(
      Map<
        String,
        dynamic
      >.from(
        _peerConfiguration,
      ),
    );

    _peerConnections[normalizedUserId] = peer;

    // ========================================================
    // LOCAL TRACKS
    // ========================================================

    final stream = _localStream;

    if (stream !=
        null) {
      for (final track in stream.getTracks()) {
        await peer.addTrack(
          track,
          stream,
        );
      }
    }

    // ========================================================
    // ICE
    // ========================================================

    peer.onIceCandidate =
        (
          RTCIceCandidate candidate,
        ) {
          if (_disposed) {
            return;
          }

          final value = candidate.candidate;

          if (value ==
                  null ||
              value.trim().isEmpty) {
            return;
          }

          onIceCandidate?.call(
            normalizedUserId,
            candidate,
          );
        };

    // ========================================================
    // TRACK
    // ========================================================

    peer.onTrack =
        (
          RTCTrackEvent event,
        ) {
          if (_disposed) {
            return;
          }

          if (event.streams.isEmpty) {
            return;
          }

          final remoteStream = event.streams.first;

          unawaited(
            _attachRemoteStream(
              normalizedUserId,
              remoteStream,
            ),
          );
        };

    // ========================================================
    // CONNECTION
    // ========================================================

    peer.onConnectionState =
        (
          RTCPeerConnectionState state,
        ) {
          if (_disposed) {
            return;
          }

          onConnectionState?.call(
            normalizedUserId,
            state,
          );

          switch (state) {
            case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
            case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
            case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
              onRemoteDisconnected?.call(
                normalizedUserId,
              );

              break;

            default:
              break;
          }
        };

    return peer;
  }

  // ==========================================================
  // CREATE OFFER
  // ==========================================================

  Future<
    RTCSessionDescription
  >
  createOffer(
    String remoteUserId,
  ) async {
    final peer = await ensurePeer(
      remoteUserId,
    );

    final offer = await peer.createOffer();

    await peer.setLocalDescription(
      offer,
    );

    return offer;
  }

  // ==========================================================
  // HANDLE OFFER
  // ==========================================================

  Future<
    RTCSessionDescription
  >
  handleOffer({
    required String remoteUserId,
    required String sdp,
  }) async {
    final peer = await ensurePeer(
      remoteUserId,
    );

    final description = RTCSessionDescription(
      _required(
        sdp,
        'sdp',
      ),
      'offer',
    );

    await peer.setRemoteDescription(
      description,
    );

    await _flushPendingIce(
      remoteUserId,
    );

    final answer = await peer.createAnswer();

    await peer.setLocalDescription(
      answer,
    );

    return answer;
  }

  // ==========================================================
  // HANDLE ANSWER
  // ==========================================================

  Future<
    void
  >
  handleAnswer({
    required String remoteUserId,
    required String sdp,
  }) async {
    final peer = await ensurePeer(
      remoteUserId,
    );

    final description = RTCSessionDescription(
      _required(
        sdp,
        'sdp',
      ),
      'answer',
    );

    await peer.setRemoteDescription(
      description,
    );

    await _flushPendingIce(
      remoteUserId,
    );
  }

  // ==========================================================
  // ADD ICE
  // ==========================================================

  Future<
    void
  >
  addIceCandidate({
    required String remoteUserId,
    required String candidate,
    String? sdpMid,
    int? sdpMLineIndex,
  }) async {
    final normalizedUserId = _required(
      remoteUserId,
      'remoteUserId',
    );

    final ice = RTCIceCandidate(
      _required(
        candidate,
        'candidate',
      ),
      sdpMid,
      sdpMLineIndex,
    );

    final peer = _peerConnections[normalizedUserId];

    // ========================================================
    // PEER NOT YET AVAILABLE
    // ========================================================

    if (peer ==
        null) {
      _pendingIceCandidates
          .putIfAbsent(
            normalizedUserId,
            () =>
                <
                  RTCIceCandidate
                >[],
          )
          .add(
            ice,
          );

      return;
    }

    // ========================================================
    // REMOTE SDP NOT READY
    // ========================================================

    final remoteDescription = await peer.getRemoteDescription();

    if (remoteDescription ==
        null) {
      _pendingIceCandidates
          .putIfAbsent(
            normalizedUserId,
            () =>
                <
                  RTCIceCandidate
                >[],
          )
          .add(
            ice,
          );

      return;
    }

    await peer.addCandidate(
      ice,
    );
  }

  // ==========================================================
  // FLUSH ICE
  // ==========================================================

  Future<
    void
  >
  _flushPendingIce(
    String remoteUserId,
  ) async {
    final peer = _peerConnections[remoteUserId];

    if (peer ==
        null) {
      return;
    }

    final candidates = _pendingIceCandidates.remove(
      remoteUserId,
    );

    if (candidates ==
            null ||
        candidates.isEmpty) {
      return;
    }

    for (final candidate in candidates) {
      await peer.addCandidate(
        candidate,
      );
    }
  }

  // ==========================================================
  // REMOTE STREAM
  // ==========================================================

  Future<
    void
  >
  _attachRemoteStream(
    String remoteUserId,
    MediaStream stream,
  ) async {
    _remoteStreams[remoteUserId] = stream;

    var renderer = _remoteRenderers[remoteUserId];

    if (renderer ==
        null) {
      renderer = RTCVideoRenderer();

      await renderer.initialize();

      _remoteRenderers[remoteUserId] = renderer;
    }

    renderer.srcObject = stream;

    onRemoteStream?.call(
      remoteUserId,
      stream,
    );
  }

  // ==========================================================
  // REMOTE RENDERER
  // ==========================================================

  RTCVideoRenderer? rendererFor(
    String remoteUserId,
  ) {
    return _remoteRenderers[remoteUserId.trim()];
  }

  // ==========================================================
  // MICROPHONE
  // ==========================================================

  Future<
    bool
  >
  setMicrophoneEnabled(
    bool enabled,
  ) async {
    _ensureNotDisposed();

    final stream = _localStream;

    if (stream ==
        null) {
      return false;
    }

    final tracks = stream.getAudioTracks();

    if (tracks.isEmpty) {
      return false;
    }

    for (final track in tracks) {
      track.enabled = enabled;
    }

    _microphoneEnabled = enabled;

    return true;
  }

  // ==========================================================
  // TOGGLE MICROPHONE
  // ==========================================================

  Future<
    bool
  >
  toggleMicrophone() {
    return setMicrophoneEnabled(
      !_microphoneEnabled,
    );
  }

  // ==========================================================
  // CAMERA
  // ==========================================================

  Future<
    bool
  >
  setCameraEnabled(
    bool enabled,
  ) async {
    _ensureNotDisposed();

    final stream = _localStream;

    if (stream ==
        null) {
      return false;
    }

    var videoTracks = stream.getVideoTracks();

    // ========================================================
    // CAMERA WAS NEVER ACQUIRED
    // ========================================================

    if (enabled &&
        videoTracks.isEmpty) {
      final cameraStream = await navigator.mediaDevices.getUserMedia(
        {
          'audio': false,

          'video': {
            'facingMode': 'user',

            'width': 1280,

            'height': 720,
          },
        },
      );

      final newVideoTracks = cameraStream.getVideoTracks();

      if (newVideoTracks.isEmpty) {
        await cameraStream.dispose();

        return false;
      }

      final track = newVideoTracks.first;

      await stream.addTrack(
        track,
      );

      await _addVideoTrackToPeers(
        track,
        stream,
      );

      _localRenderer?.srcObject = stream;

      videoTracks = stream.getVideoTracks();
    }

    for (final track in videoTracks) {
      track.enabled = enabled;
    }

    _cameraEnabled = enabled;

    return true;
  }

  // ==========================================================
  // ADD VIDEO TRACK TO PEERS
  // ==========================================================

  Future<
    void
  >
  _addVideoTrackToPeers(
    MediaStreamTrack track,
    MediaStream stream,
  ) async {
    for (final peer in _peerConnections.values) {
      final senders = await peer.senders;

      RTCRtpSender? existingVideoSender;

      for (final sender in senders) {
        if (sender.track?.kind ==
            'video') {
          existingVideoSender = sender;

          break;
        }
      }

      if (existingVideoSender !=
          null) {
        await existingVideoSender.replaceTrack(
          track,
        );
      } else {
        await peer.addTrack(
          track,
          stream,
        );
      }
    }
  }

  // ==========================================================
  // TOGGLE CAMERA
  // ==========================================================

  Future<
    bool
  >
  toggleCamera() {
    return setCameraEnabled(
      !_cameraEnabled,
    );
  }

  // ==========================================================
  // SWITCH CAMERA
  // ==========================================================

  Future<
    bool
  >
  switchCamera() async {
    _ensureNotDisposed();

    final stream = _localStream;

    if (stream ==
        null) {
      return false;
    }

    final tracks = stream.getVideoTracks();

    if (tracks.isEmpty) {
      return false;
    }

    return Helper.switchCamera(
      tracks.first,
      null,
      stream,
    );
  }

  // ==========================================================
  // SPEAKER
  // ==========================================================

  Future<
    void
  >
  setSpeakerEnabled(
    bool enabled,
  ) async {
    _ensureNotDisposed();

    await Helper.setSpeakerphoneOn(
      enabled,
    );

    _speakerEnabled = enabled;
  }

  // ==========================================================
  // TOGGLE SPEAKER
  // ==========================================================

  Future<
    void
  >
  toggleSpeaker() {
    return setSpeakerEnabled(
      !_speakerEnabled,
    );
  }

  // ==========================================================
  // CLOSE PEER
  // ==========================================================

  Future<
    void
  >
  closePeer(
    String remoteUserId,
  ) async {
    final normalized = remoteUserId.trim();

    if (normalized.isEmpty) {
      return;
    }

    final peer = _peerConnections.remove(
      normalized,
    );

    _pendingIceCandidates.remove(
      normalized,
    );

    if (peer !=
        null) {
      try {
        await peer.close();
      } catch (
        error
      ) {
        debugPrint(
          '[WEBRTC] Erro fechando peer: $error',
        );
      }

      try {
        await peer.dispose();
      } catch (
        error
      ) {
        debugPrint(
          '[WEBRTC] Erro descartando peer: $error',
        );
      }
    }

    final renderer = _remoteRenderers.remove(
      normalized,
    );

    if (renderer !=
        null) {
      renderer.srcObject = null;

      await renderer.dispose();
    }

    final stream = _remoteStreams.remove(
      normalized,
    );

    if (stream !=
        null) {
      try {
        await stream.dispose();
      } catch (
        error
      ) {
        debugPrint(
          '[WEBRTC] Erro descartando stream remoto: $error',
        );
      }
    }
  }

  // ==========================================================
  // CLOSE ALL PEERS
  // ==========================================================

  Future<
    void
  >
  closeAllPeers() async {
    final ids =
        List<
          String
        >.from(
          _peerConnections.keys,
        );

    for (final userId in ids) {
      await closePeer(
        userId,
      );
    }
  }

  // ==========================================================
  // LOCAL MEDIA DISPOSE
  // ==========================================================

  Future<
    void
  >
  _disposeLocalMedia() async {
    final renderer = _localRenderer;

    _localRenderer = null;

    if (renderer !=
        null) {
      renderer.srcObject = null;

      await renderer.dispose();
    }

    final stream = _localStream;

    _localStream = null;

    if (stream ==
        null) {
      return;
    }

    for (final track in stream.getTracks()) {
      try {
        await track.stop();
      } catch (
        error
      ) {
        debugPrint(
          '[WEBRTC] Erro parando track: $error',
        );
      }
    }

    try {
      await stream.dispose();
    } catch (
      error
    ) {
      debugPrint(
        '[WEBRTC] Erro descartando stream local: $error',
      );
    }
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
  // ENSURE
  // ==========================================================

  void _ensureNotDisposed() {
    if (_disposed) {
      throw StateError(
        'WebRtcCallService já foi descartado.',
      );
    }
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  Future<
    void
  >
  dispose() async {
    if (_disposed) {
      return;
    }

    _disposed = true;

    await closeAllPeers();

    await _disposeLocalMedia();

    onIceCandidate = null;

    onRemoteStream = null;

    onConnectionState = null;

    onRemoteDisconnected = null;
  }
}
