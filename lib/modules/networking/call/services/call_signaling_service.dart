import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/call_channel_name.dart';

// ============================================================
// CALL SIGNALING SERVICE
// ============================================================
//
// Responsável SOMENTE pela sinalização WebRTC.
//
// Fluxo:
//
// WebRtcCallService
//      ↓
// offer / answer / ICE
//      ↓
// CallSignalingService
//      ↓
// Supabase Realtime Broadcast
//      ↓
// CallSignalingService remoto
//      ↓
// WebRtcCallService remoto
//
// NÃO transmite:
//
// - áudio;
// - vídeo;
// - MediaStream.
//
// Áudio e vídeo trafegam pelo WebRTC.
//
// ============================================================

class CallSignalingService {
  // ==========================================================
  // EVENTOS
  // ==========================================================

  static const String offerEvent = 'offer';

  static const String answerEvent = 'answer';

  static const String iceCandidateEvent = 'ice_candidate';

  static const String hangupEvent = 'hangup';

  static const String mediaStateEvent = 'media_state';

  // ==========================================================
  // SUPABASE
  // ==========================================================

  final SupabaseClient _supabase;

  // ==========================================================
  // CHANNEL
  // ==========================================================

  RealtimeChannel? _channel;

  // ==========================================================
  // IDENTIFICAÇÃO
  // ==========================================================

  String? _callId;

  String? _currentUserId;

  // ==========================================================
  // ESTADO
  // ==========================================================

  bool _isSubscribed = false;

  bool _disposed = false;

  Completer<void>? _subscribeCompleter;

  // ==========================================================
  // CALLBACKS
  // ==========================================================

  void Function({required String fromUserId, required String sdp})? onOffer;

  void Function({required String fromUserId, required String sdp})? onAnswer;

  void Function({
    required String fromUserId,
    required String candidate,
    String? sdpMid,
    int? sdpMLineIndex,
  })?
  onIceCandidate;

  void Function({required String fromUserId})? onHangup;

  void Function({
    required String fromUserId,
    required bool microphoneEnabled,
    required bool cameraEnabled,
  })?
  onMediaState;

  void Function(RealtimeSubscribeStatus status)? onSubscriptionStatus;

  void Function(Object error)? onError;

  // ==========================================================
  // CONSTRUTOR
  // ==========================================================

  CallSignalingService({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  // ==========================================================
  // GETTERS
  // ==========================================================

  bool get isSubscribed => _isSubscribed;

  bool get isDisposed => _disposed;

  String? get callId => _callId;

  String? get currentUserId => _currentUserId;

  RealtimeChannel? get channel => _channel;

  // ==========================================================
  // START
  // ==========================================================

  Future<void> start({
    required String callId,
    required String currentUserId,
  }) async {
    _ensureNotDisposed();

    final normalizedCallId = _required(callId, 'callId');

    final normalizedUserId = _required(currentUserId, 'currentUserId');

    // ========================================================
    // MESMA SESSÃO JÁ ESTÁ ATIVA
    // ========================================================

    if (_channel != null &&
        _callId == normalizedCallId &&
        _currentUserId == normalizedUserId &&
        _isSubscribed) {
      return;
    }

    // ========================================================
    // LIMPAR CANAL ANTIGO
    // ========================================================

    await stop();

    _callId = normalizedCallId;

    _currentUserId = normalizedUserId;

    _subscribeCompleter = Completer<void>();

    // ========================================================
    // NOME DO CANAL
    // ========================================================

    final channelName = CallChannelName.signaling(normalizedCallId);

    debugPrint(
      '[CALL SIGNALING] '
      'Abrindo canal: '
      '$channelName',
    );

    // ========================================================
    // CHANNEL
    // ========================================================
    //
    // Por enquanto deixamos público no nível do Realtime
    // porque seu projeto ainda não possui policies específicas
    // para realtime.messages.
    //
    // Depois podemos mudar para:
    //
    // RealtimeChannelConfig(
    //   private: true,
    // )
    //
    // + RLS em realtime.messages.
    //
    // ========================================================

    final channel = _supabase.channel(channelName);

    _channel = channel;

    // ========================================================
    // OFFER
    // ========================================================

    channel.onBroadcast(
      event: offerEvent,

      callback: (payload) {
        _handleOffer(payload);
      },
    );

    // ========================================================
    // ANSWER
    // ========================================================

    channel.onBroadcast(
      event: answerEvent,

      callback: (payload) {
        _handleAnswer(payload);
      },
    );

    // ========================================================
    // ICE
    // ========================================================

    channel.onBroadcast(
      event: iceCandidateEvent,

      callback: (payload) {
        _handleIceCandidate(payload);
      },
    );

    // ========================================================
    // HANGUP
    // ========================================================

    channel.onBroadcast(
      event: hangupEvent,

      callback: (payload) {
        _handleHangup(payload);
      },
    );

    // ========================================================
    // MEDIA STATE
    // ========================================================

    channel.onBroadcast(
      event: mediaStateEvent,

      callback: (payload) {
        _handleMediaState(payload);
      },
    );

    // ========================================================
    // SUBSCRIBE
    // ========================================================

    channel.subscribe((status, error) {
      if (_disposed) {
        return;
      }

      debugPrint(
        '[CALL SIGNALING] '
        'Status: '
        '$status',
      );

      onSubscriptionStatus?.call(status);

      switch (status) {
        case RealtimeSubscribeStatus.subscribed:
          _isSubscribed = true;

          if (_subscribeCompleter != null &&
              !_subscribeCompleter!.isCompleted) {
            _subscribeCompleter!.complete();
          }

          debugPrint(
            '[CALL SIGNALING] '
            'Canal conectado.',
          );

          break;

        case RealtimeSubscribeStatus.channelError:
        case RealtimeSubscribeStatus.timedOut:
          _isSubscribed = false;

          final exception =
              error ??
              StateError(
                'Falha ao conectar ao canal de signaling: '
                '$status',
              );

          if (_subscribeCompleter != null &&
              !_subscribeCompleter!.isCompleted) {
            _subscribeCompleter!.completeError(exception);
          }

          onError?.call(exception);

          break;

        case RealtimeSubscribeStatus.closed:
          _isSubscribed = false;

          break;
      }
    });

    // ========================================================
    // ESPERAR SUBSCRIBE
    // ========================================================

    try {
      await _subscribeCompleter!.future.timeout(const Duration(seconds: 12));
    } on TimeoutException {
      throw StateError('Timeout ao conectar ao canal de signaling.');
    }
  }

  // ==========================================================
  // SEND OFFER
  // ==========================================================

  Future<void> sendOffer({
    required String toUserId,
    required String sdp,
  }) async {
    final payload = _basePayload(toUserId: toUserId);

    payload['sdp'] = _required(sdp, 'sdp');

    await _send(event: offerEvent, payload: payload);

    debugPrint(
      '[CALL SIGNALING] '
      'Offer enviada para '
      '${_short(toUserId)}.',
    );
  }

  // ==========================================================
  // SEND ANSWER
  // ==========================================================

  Future<void> sendAnswer({
    required String toUserId,
    required String sdp,
  }) async {
    final payload = _basePayload(toUserId: toUserId);

    payload['sdp'] = _required(sdp, 'sdp');

    await _send(event: answerEvent, payload: payload);

    debugPrint(
      '[CALL SIGNALING] '
      'Answer enviada para '
      '${_short(toUserId)}.',
    );
  }

  // ==========================================================
  // SEND ICE
  // ==========================================================

  Future<void> sendIceCandidate({
    required String toUserId,
    required String candidate,
    String? sdpMid,
    int? sdpMLineIndex,
  }) async {
    final payload = _basePayload(toUserId: toUserId);

    payload.addAll({
      'candidate': _required(candidate, 'candidate'),

      'sdp_mid': sdpMid,

      'sdp_m_line_index': sdpMLineIndex,
    });

    await _send(event: iceCandidateEvent, payload: payload);
  }

  // ==========================================================
  // SEND HANGUP
  // ==========================================================

  Future<void> sendHangup({required String toUserId}) async {
    await _send(
      event: hangupEvent,

      payload: _basePayload(toUserId: toUserId),
    );

    debugPrint(
      '[CALL SIGNALING] '
      'Hangup enviado para '
      '${_short(toUserId)}.',
    );
  }

  // ==========================================================
  // SEND MEDIA STATE
  // ==========================================================

  Future<void> sendMediaState({
    required String toUserId,
    required bool microphoneEnabled,
    required bool cameraEnabled,
  }) async {
    final payload = _basePayload(toUserId: toUserId);

    payload.addAll({
      'microphone_enabled': microphoneEnabled,

      'camera_enabled': cameraEnabled,
    });

    await _send(event: mediaStateEvent, payload: payload);
  }

  // ==========================================================
  // SEND
  // ==========================================================

  Future<void> _send({
    required String event,
    required Map<String, dynamic> payload,
  }) async {
    _ensureNotDisposed();

    final channel = _channel;

    if (channel == null) {
      throw StateError('Canal de signaling ainda não foi iniciado.');
    }

    try {
      await channel.sendBroadcastMessage(event: event, payload: payload);
    } catch (error, stackTrace) {
      debugPrint(
        '[CALL SIGNALING] '
        'Erro enviando '
        '$event: '
        '$error',
      );

      debugPrint(
        '[CALL SIGNALING] '
        'StackTrace: '
        '$stackTrace',
      );

      onError?.call(error);

      rethrow;
    }
  }

  // ==========================================================
  // HANDLE OFFER
  // ==========================================================

  void _handleOffer(Map<String, dynamic> raw) {
    final payload = _extractPayload(raw);

    if (!_shouldHandle(payload)) {
      return;
    }

    final fromUserId = _readRequiredString(payload, 'from_user_id');

    final sdp = _readRequiredString(payload, 'sdp');

    if (fromUserId == null || sdp == null) {
      return;
    }

    debugPrint(
      '[CALL SIGNALING] '
      'Offer recebida de '
      '${_short(fromUserId)}.',
    );

    onOffer?.call(fromUserId: fromUserId, sdp: sdp);
  }

  // ==========================================================
  // HANDLE ANSWER
  // ==========================================================

  void _handleAnswer(Map<String, dynamic> raw) {
    final payload = _extractPayload(raw);

    if (!_shouldHandle(payload)) {
      return;
    }

    final fromUserId = _readRequiredString(payload, 'from_user_id');

    final sdp = _readRequiredString(payload, 'sdp');

    if (fromUserId == null || sdp == null) {
      return;
    }

    debugPrint(
      '[CALL SIGNALING] '
      'Answer recebida de '
      '${_short(fromUserId)}.',
    );

    onAnswer?.call(fromUserId: fromUserId, sdp: sdp);
  }

  // ==========================================================
  // HANDLE ICE
  // ==========================================================

  void _handleIceCandidate(Map<String, dynamic> raw) {
    final payload = _extractPayload(raw);

    if (!_shouldHandle(payload)) {
      return;
    }

    final fromUserId = _readRequiredString(payload, 'from_user_id');

    final candidate = _readRequiredString(payload, 'candidate');

    if (fromUserId == null || candidate == null) {
      return;
    }

    final sdpMid = _readNullableString(payload['sdp_mid']);

    final sdpMLineIndex = _readNullableInt(payload['sdp_m_line_index']);

    onIceCandidate?.call(
      fromUserId: fromUserId,

      candidate: candidate,

      sdpMid: sdpMid,

      sdpMLineIndex: sdpMLineIndex,
    );
  }

  // ==========================================================
  // HANDLE HANGUP
  // ==========================================================

  void _handleHangup(Map<String, dynamic> raw) {
    final payload = _extractPayload(raw);

    if (!_shouldHandle(payload)) {
      return;
    }

    final fromUserId = _readRequiredString(payload, 'from_user_id');

    if (fromUserId == null) {
      return;
    }

    debugPrint(
      '[CALL SIGNALING] '
      'Hangup recebido de '
      '${_short(fromUserId)}.',
    );

    onHangup?.call(fromUserId: fromUserId);
  }

  // ==========================================================
  // HANDLE MEDIA STATE
  // ==========================================================

  void _handleMediaState(Map<String, dynamic> raw) {
    final payload = _extractPayload(raw);

    if (!_shouldHandle(payload)) {
      return;
    }

    final fromUserId = _readRequiredString(payload, 'from_user_id');

    if (fromUserId == null) {
      return;
    }

    final microphoneEnabled = payload['microphone_enabled'] == true;

    final cameraEnabled = payload['camera_enabled'] == true;

    onMediaState?.call(
      fromUserId: fromUserId,

      microphoneEnabled: microphoneEnabled,

      cameraEnabled: cameraEnabled,
    );
  }

  // ==========================================================
  // DEVE PROCESSAR?
  // ==========================================================
  //
  // Todos usam o mesmo canal da chamada.
  //
  // Por isso filtramos o destinatário aqui.
  //
  // ==========================================================

  bool _shouldHandle(Map<String, dynamic> payload) {
    if (_disposed) {
      return false;
    }

    final currentUserId = _currentUserId;

    final currentCallId = _callId;

    if (currentUserId == null || currentCallId == null) {
      return false;
    }

    final payloadCallId = _readNullableString(payload['call_id']);

    final fromUserId = _readNullableString(payload['from_user_id']);

    final toUserId = _readNullableString(payload['to_user_id']);

    // ========================================================
    // OUTRA CHAMADA
    // ========================================================

    if (payloadCallId != currentCallId) {
      return false;
    }

    // ========================================================
    // EVENTO ENVIADO PELO PRÓPRIO CLIENTE
    // ========================================================

    if (fromUserId == currentUserId) {
      return false;
    }

    // ========================================================
    // NÃO É PARA ESTE USUÁRIO
    // ========================================================

    if (toUserId != currentUserId) {
      return false;
    }

    return true;
  }

  // ==========================================================
  // PAYLOAD BASE
  // ==========================================================

  Map<String, dynamic> _basePayload({required String toUserId}) {
    final currentCallId = _callId;

    final currentUserId = _currentUserId;

    if (currentCallId == null || currentCallId.isEmpty) {
      throw StateError('callId ainda não foi configurado.');
    }

    if (currentUserId == null || currentUserId.isEmpty) {
      throw StateError('currentUserId ainda não foi configurado.');
    }

    return {
      'call_id': currentCallId,

      'from_user_id': currentUserId,

      'to_user_id': _required(toUserId, 'toUserId'),

      'sent_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  // ==========================================================
  // EXTRAIR PAYLOAD
  // ==========================================================
  //
  // Dependendo da versão do realtime_client, o callback pode
  // entregar:
  //
  // {
  //   payload: {...}
  // }
  //
  // ou diretamente:
  //
  // {...}
  //
  // Este método aceita os dois formatos.
  //
  // ==========================================================

  Map<String, dynamic> _extractPayload(Map<String, dynamic> raw) {
    final nested = raw['payload'];

    if (nested is Map) {
      return Map<String, dynamic>.from(nested);
    }

    return Map<String, dynamic>.from(raw);
  }

  // ==========================================================
  // READ REQUIRED STRING
  // ==========================================================

  String? _readRequiredString(Map<String, dynamic> payload, String key) {
    final value = _readNullableString(payload[key]);

    if (value == null) {
      debugPrint(
        '[CALL SIGNALING] '
        'Payload inválido: '
        '$key ausente.',
      );
    }

    return value;
  }

  // ==========================================================
  // READ STRING
  // ==========================================================

  String? _readNullableString(dynamic value) {
    if (value == null) {
      return null;
    }

    final normalized = value.toString().trim();

    if (normalized.isEmpty) {
      return null;
    }

    return normalized;
  }

  // ==========================================================
  // READ INT
  // ==========================================================

  int? _readNullableInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString());
  }

  // ==========================================================
  // REQUIRED
  // ==========================================================

  String _required(String value, String field) {
    final normalized = value.trim();

    if (normalized.isEmpty) {
      throw ArgumentError('$field não pode ser vazio.');
    }

    return normalized;
  }

  // ==========================================================
  // SHORT ID
  // ==========================================================

  String _short(String value) {
    return CallChannelName.shortId(value);
  }

  // ==========================================================
  // STOP
  // ==========================================================

  Future<void> stop() async {
    final channel = _channel;

    _channel = null;

    _isSubscribed = false;

    _callId = null;

    _currentUserId = null;

    final completer = _subscribeCompleter;

    _subscribeCompleter = null;

    if (completer != null && !completer.isCompleted) {
      completer.completeError(
        StateError('Signaling interrompido antes da inscrição.'),
      );
    }

    if (channel == null) {
      return;
    }

    try {
      await _supabase.removeChannel(channel);

      debugPrint(
        '[CALL SIGNALING] '
        'Canal removido.',
      );
    } catch (error) {
      debugPrint(
        '[CALL SIGNALING] '
        'Erro removendo canal: '
        '$error',
      );
    }
  }

  // ==========================================================
  // ENSURE
  // ==========================================================

  void _ensureNotDisposed() {
    if (_disposed) {
      throw StateError('CallSignalingService já foi descartado.');
    }
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }

    await stop();

    _disposed = true;

    onOffer = null;

    onAnswer = null;

    onIceCandidate = null;

    onHangup = null;

    onMediaState = null;

    onSubscriptionStatus = null;

    onError = null;

    debugPrint(
      '[CALL SIGNALING] '
      'Service descartado.',
    );
  }
}
