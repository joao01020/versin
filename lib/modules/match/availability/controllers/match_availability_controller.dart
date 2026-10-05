import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/match_availability_state.dart';
import '../services/match_availability_service.dart';

// ============================================================
// MATCH AVAILABILITY CONTROLLER
// ============================================================
//
// Responsável por controlar:
//
// - estado atual de disponibilidade;
// - loading;
// - ativação;
// - encerramento;
// - atualização automática do tempo restante;
// - expiração local da disponibilidade.
//
// NÃO:
//
// - acessa Supabase diretamente;
// - conhece Widgets;
// - abre dialogs;
// - mostra SnackBars;
// - controla navegação.
//
// ============================================================

class MatchAvailabilityController
    extends
        ChangeNotifier {
  // ============================================================
  // DEPENDENCIES
  // ============================================================

  final MatchAvailabilityService availabilityService;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  MatchAvailabilityController({
    required this.availabilityService,
  });

  // ============================================================
  // STATE
  // ============================================================

  MatchAvailabilityState _state = const MatchAvailabilityState(
    availableNow: false,
    availableUntil: null,
  );

  MatchAvailabilityState get state {
    return _state;
  }

  // ============================================================
  // LOADING
  // ============================================================

  bool _isLoading = false;

  bool get isLoading {
    return _isLoading;
  }

  // ============================================================
  // INITIALIZED
  // ============================================================

  bool _isInitialized = false;

  bool get isInitialized {
    return _isInitialized;
  }

  // ============================================================
  // TICKER
  // ============================================================

  Timer? _ticker;

  static const Duration tickerInterval = Duration(
    seconds: 30,
  );

  // ============================================================
  // GETTERS
  // ============================================================

  bool get isActive {
    return _state.isActive;
  }

  bool get isInactive {
    return !isActive;
  }

  DateTime? get availableUntil {
    return _state.availableUntil;
  }

  String get remainingLabel {
    return _state.remainingLabel;
  }

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<
    void
  >
  initialize() async {
    if (_isInitialized ||
        _isLoading) {
      return;
    }

    _setLoading(
      true,
    );

    try {
      debugPrint(
        '[MATCH AVAILABILITY CONTROLLER] '
        'Inicializando disponibilidade.',
      );

      final loadedState = await availabilityService.loadCurrentState();

      _state = loadedState;

      _isInitialized = true;

      _startTicker();

      debugPrint(
        '[MATCH AVAILABILITY CONTROLLER] '
        'Disponibilidade carregada. '
        'Ativa: ${_state.isActive} | '
        'Até: ${_state.availableUntil}',
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[MATCH AVAILABILITY CONTROLLER] '
        'Erro ao inicializar disponibilidade: '
        '$error',
      );

      debugPrint(
        '[MATCH AVAILABILITY CONTROLLER] '
        'Stack trace: '
        '$stackTrace',
      );

      rethrow;
    } finally {
      _setLoading(
        false,
      );
    }
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<
    void
  >
  refresh() async {
    if (_isLoading) {
      return;
    }

    _setLoading(
      true,
    );

    try {
      final loadedState = await availabilityService.loadCurrentState();

      _state = loadedState;

      _isInitialized = true;

      notifyListeners();

      debugPrint(
        '[MATCH AVAILABILITY CONTROLLER] '
        'Disponibilidade atualizada.',
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[MATCH AVAILABILITY CONTROLLER] '
        'Erro ao atualizar disponibilidade: '
        '$error',
      );

      debugPrint(
        '[MATCH AVAILABILITY CONTROLLER] '
        'Stack trace: '
        '$stackTrace',
      );

      rethrow;
    } finally {
      _setLoading(
        false,
      );
    }
  }

  // ============================================================
  // ACTIVATE
  // ============================================================

  Future<
    bool
  >
  activate({
    required int minutes,
  }) async {
    if (_isLoading) {
      return false;
    }

    if (!_isValidDuration(
      minutes,
    )) {
      debugPrint(
        '[MATCH AVAILABILITY CONTROLLER] '
        'Duração inválida: '
        '$minutes minutos.',
      );

      return false;
    }

    _setLoading(
      true,
    );

    try {
      debugPrint(
        '[MATCH AVAILABILITY CONTROLLER] '
        'Ativando disponibilidade por '
        '$minutes minutos.',
      );

      final newState = await availabilityService.setAvailableNow(
        minutes: minutes,
      );

      _state = newState;

      _isInitialized = true;

      _startTicker();

      notifyListeners();

      debugPrint(
        '[MATCH AVAILABILITY CONTROLLER] '
        'Disponibilidade ativada até '
        '${_state.availableUntil}.',
      );

      return true;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[MATCH AVAILABILITY CONTROLLER] '
        'Erro ao ativar disponibilidade: '
        '$error',
      );

      debugPrint(
        '[MATCH AVAILABILITY CONTROLLER] '
        'Stack trace: '
        '$stackTrace',
      );

      return false;
    } finally {
      _setLoading(
        false,
      );
    }
  }

  // ============================================================
  // CLEAR
  // ============================================================

  Future<
    bool
  >
  clear() async {
    if (_isLoading) {
      return false;
    }

    _setLoading(
      true,
    );

    try {
      debugPrint(
        '[MATCH AVAILABILITY CONTROLLER] '
        'Encerrando disponibilidade.',
      );

      final newState = await availabilityService.clearAvailability();

      _state = newState;

      notifyListeners();

      debugPrint(
        '[MATCH AVAILABILITY CONTROLLER] '
        'Disponibilidade encerrada.',
      );

      return true;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[MATCH AVAILABILITY CONTROLLER] '
        'Erro ao encerrar disponibilidade: '
        '$error',
      );

      debugPrint(
        '[MATCH AVAILABILITY CONTROLLER] '
        'Stack trace: '
        '$stackTrace',
      );

      return false;
    } finally {
      _setLoading(
        false,
      );
    }
  }

  // ============================================================
  // TICKER
  // ============================================================

  void _startTicker() {
    _ticker?.cancel();

    _ticker = Timer.periodic(
      tickerInterval,
      (
        _,
      ) {
        _handleTick();
      },
    );
  }

  // ============================================================
  // HANDLE TICK
  // ============================================================

  void _handleTick() {
    if (!_state.availableNow) {
      return;
    }

    final availableUntil = _state.availableUntil;

    if (availableUntil ==
        null) {
      return;
    }

    final now = DateTime.now();

    // ==========================================================
    // EXPIRED
    // ==========================================================

    if (!availableUntil.isAfter(
      now,
    )) {
      debugPrint(
        '[MATCH AVAILABILITY CONTROLLER] '
        'Disponibilidade expirou localmente.',
      );

      _state = const MatchAvailabilityState(
        availableNow: false,
        availableUntil: null,
      );

      notifyListeners();

      return;
    }

    // ==========================================================
    // UPDATE REMAINING TIME
    // ==========================================================

    notifyListeners();
  }

  // ============================================================
  // VALIDATE DURATION
  // ============================================================

  bool _isValidDuration(
    int minutes,
  ) {
    return minutes ==
            MatchAvailabilityService.thirtyMinutes ||
        minutes ==
            MatchAvailabilityService.oneHour ||
        minutes ==
            MatchAvailabilityService.twoHours;
  }

  // ============================================================
  // DURATION LABEL
  // ============================================================

  String durationLabel(
    int minutes,
  ) {
    switch (minutes) {
      case MatchAvailabilityService.thirtyMinutes:
        return '30 minutos';

      case MatchAvailabilityService.oneHour:
        return '1 hora';

      case MatchAvailabilityService.twoHours:
        return '2 horas';

      default:
        return '$minutes minutos';
    }
  }

  // ============================================================
  // SET LOADING
  // ============================================================

  void _setLoading(
    bool value,
  ) {
    if (_isLoading ==
        value) {
      return;
    }

    _isLoading = value;

    notifyListeners();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _ticker?.cancel();

    _ticker = null;

    super.dispose();
  }
}
