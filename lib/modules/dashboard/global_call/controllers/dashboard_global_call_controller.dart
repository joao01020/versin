import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/dashboard_global_call_service.dart';

// ============================================================
// DASHBOARD GLOBAL CALL CONTROLLER
// ============================================================
//
// Responsabilidade:
//
// - manter chamada global atual;
// - controlar relógio da chamada;
// - controlar processamento;
// - aceitar;
// - recusar;
// - encerrar;
// - calcular estado da chamada.
//
// Não conhece:
//
// - Navigator;
// - BuildContext;
// - Widgets.
//
// ============================================================

class DashboardGlobalCallController
    extends
        ChangeNotifier {
  // ============================================================
  // SERVICE
  // ============================================================

  final DashboardGlobalCallService service;

  // ============================================================
  // STREAM
  // ============================================================

  StreamSubscription<
    List<
      Map<
        String,
        dynamic
      >
    >
  >?
  _subscription;

  // ============================================================
  // STATE
  // ============================================================

  Map<
    String,
    dynamic
  >?
  _currentCall;

  bool _isProcessing = false;

  String? _processingAction;

  DateTime _clockNow = DateTime.now();

  Timer? _clockTimer;

  bool _initialized = false;

  bool _disposed = false;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  DashboardGlobalCallController({
    DashboardGlobalCallService? service,
  }) : service =
           service ??
           DashboardGlobalCallService();

  // ============================================================
  // GETTERS
  // ============================================================

  Map<
    String,
    dynamic
  >?
  get currentCall => _currentCall;

  bool get hasCall =>
      _currentCall !=
      null;

  bool get isProcessing => _isProcessing;

  String? get processingAction => _processingAction;

  DateTime get clockNow => _clockNow;

  String? get currentUserId => service.currentUserId;

  bool get initialized => _initialized;

  // ============================================================
  // CALL DATA
  // ============================================================

  String get callId => _readString(
    'id',
  );

  String get projectId => _readString(
    'project_id',
  );

  String get createdBy => _readString(
    'created_by',
  );

  String? get targetUserId {
    final value = _currentCall?['target_user_id']?.toString().trim();

    if (value ==
            null ||
        value.isEmpty) {
      return null;
    }

    return value;
  }

  String get status => _readString(
    'status',
  );

  String get mediaType {
    final value = _readString(
      'media_type',
    ).toLowerCase();

    if (value ==
        'video') {
      return 'video';
    }

    return 'audio';
  }

  // ============================================================
  // CALL STATE
  // ============================================================

  bool get isIncoming {
    final userId = currentUserId;

    if (userId ==
            null ||
        userId.isEmpty) {
      return false;
    }

    return status ==
            'ringing' &&
        createdBy !=
            userId &&
        (targetUserId ==
                userId ||
            targetUserId ==
                null);
  }

  bool get isOutgoing {
    final userId = currentUserId;

    if (userId ==
            null ||
        userId.isEmpty) {
      return false;
    }

    return status ==
            'ringing' &&
        createdBy ==
            userId;
  }

  bool get isActive =>
      status ==
      'active';

  bool get isEnding =>
      _isProcessing &&
      _processingAction ==
          'end';

  // ============================================================
  // CREATED AT
  // ============================================================

  DateTime? get createdAt {
    final value = _currentCall?['created_at']?.toString();

    if (value ==
            null ||
        value.trim().isEmpty) {
      return null;
    }

    return DateTime.tryParse(
      value,
    );
  }

  // ============================================================
  // STARTED AT
  // ============================================================

  DateTime? get startedAt {
    final value = _currentCall?['started_at']?.toString();

    if (value ==
            null ||
        value.trim().isEmpty) {
      return null;
    }

    return DateTime.tryParse(
      value,
    );
  }

  // ============================================================
  // RINGING DURATION
  // ============================================================

  Duration? get ringingDuration {
    final value = createdAt;

    if (value ==
            null ||
        !(isIncoming ||
            isOutgoing)) {
      return null;
    }

    return _safeDurationDifference(
      _clockNow.toUtc(),
      value.toUtc(),
    );
  }

  // ============================================================
  // ACTIVE DURATION
  // ============================================================

  Duration? get duration {
    final value = startedAt;

    if (value ==
            null ||
        !isActive) {
      return null;
    }

    return _safeDurationDifference(
      _clockNow.toUtc(),
      value.toUtc(),
    );
  }

  // ============================================================
  // PARTICIPANT USER ID
  // ============================================================

  String get participantUserId {
    final userId = currentUserId;

    if (userId ==
            null ||
        userId.isEmpty) {
      return '';
    }

    return service.resolveParticipantUserId(
      createdBy: createdBy,
      targetUserId: targetUserId,
      currentUserId: userId,
    );
  }

  // ============================================================
  // PARTICIPANT NAME
  // ============================================================

  Future<
    String
  >
  resolveParticipantName() {
    return service.resolveParticipantName(
      participantUserId,
    );
  }

  // ============================================================
  // INITIALIZE
  // ============================================================

  void init() {
    if (_initialized ||
        _disposed) {
      return;
    }

    _initialized = true;

    _startClock();

    _startRealtime();

    debugPrint(
      '[DASHBOARD GLOBAL CALL CONTROLLER] '
      'Inicializado.',
    );
  }

  // ============================================================
  // START REALTIME
  // ============================================================

  void _startRealtime() {
    final userId = currentUserId;

    if (userId ==
            null ||
        userId.isEmpty) {
      debugPrint(
        '[DASHBOARD GLOBAL CALL CONTROLLER] '
        'Realtime não iniciado: usuário não autenticado.',
      );

      return;
    }

    _subscription?.cancel();

    _subscription = service.watchCalls().listen(
      (
        rows,
      ) {
        if (_disposed) {
          return;
        }

        final activeCall = service.findActiveCall(
          rows: rows,
          currentUserId: userId,
        );

        _currentCall = activeCall;

        _notify();
      },
      onError:
          (
            Object error,
            StackTrace stackTrace,
          ) {
            debugPrint(
              '[DASHBOARD GLOBAL CALL CONTROLLER] '
              'Erro no realtime: $error',
            );

            debugPrint(
              '$stackTrace',
            );
          },
    );
  }

  // ============================================================
  // CLOCK
  // ============================================================

  void _startClock() {
    _clockTimer?.cancel();

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

        // Só precisamos reconstruir o banner quando
        // existe uma chamada com duração visível.
        if (!hasCall) {
          return;
        }

        _clockNow = DateTime.now();

        _notify();
      },
    );
  }

  // ============================================================
  // ACCEPT
  // ============================================================

  Future<
    bool
  >
  accept() async {
    if (_isProcessing ||
        callId.isEmpty) {
      return false;
    }

    _setProcessing(
      true,
      'accept',
    );

    try {
      await service.acceptCall(
        callId: callId,
      );

      return true;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[DASHBOARD GLOBAL CALL CONTROLLER] '
        'Erro ao aceitar chamada: $error',
      );

      debugPrint(
        '$stackTrace',
      );

      return false;
    } finally {
      _setProcessing(
        false,
        null,
      );
    }
  }

  // ============================================================
  // REJECT
  // ============================================================

  Future<
    bool
  >
  reject() async {
    if (_isProcessing ||
        callId.isEmpty) {
      return false;
    }

    _setProcessing(
      true,
      'reject',
    );

    try {
      await service.rejectCall(
        callId: callId,
      );

      return true;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[DASHBOARD GLOBAL CALL CONTROLLER] '
        'Erro ao recusar chamada: $error',
      );

      debugPrint(
        '$stackTrace',
      );

      return false;
    } finally {
      _setProcessing(
        false,
        null,
      );
    }
  }

  // ============================================================
  // END
  // ============================================================

  Future<
    bool
  >
  end() async {
    if (_isProcessing ||
        callId.isEmpty) {
      return false;
    }

    _setProcessing(
      true,
      'end',
    );

    try {
      await service.endCall(
        callId: callId,
      );

      return true;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[DASHBOARD GLOBAL CALL CONTROLLER] '
        'Erro ao encerrar chamada: $error',
      );

      debugPrint(
        '$stackTrace',
      );

      return false;
    } finally {
      _setProcessing(
        false,
        null,
      );
    }
  }

  // ============================================================
  // PROCESSING
  // ============================================================

  void _setProcessing(
    bool value,
    String? action,
  ) {
    if (_disposed) {
      return;
    }

    _isProcessing = value;
    _processingAction = action;

    _notify();
  }

  // ============================================================
  // SAFE DURATION
  // ============================================================

  Duration _safeDurationDifference(
    DateTime now,
    DateTime startedAt,
  ) {
    final value = now.difference(
      startedAt,
    );

    if (value.isNegative) {
      return Duration.zero;
    }

    return value;
  }

  // ============================================================
  // READ STRING
  // ============================================================

  String _readString(
    String key,
  ) {
    return _currentCall?[key]?.toString().trim() ??
        '';
  }

  // ============================================================
  // NOTIFY
  // ============================================================

  void _notify() {
    if (_disposed) {
      return;
    }

    notifyListeners();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    if (_disposed) {
      return;
    }

    _disposed = true;

    _clockTimer?.cancel();
    _clockTimer = null;

    _subscription?.cancel();
    _subscription = null;

    _currentCall = null;

    super.dispose();
  }
}
