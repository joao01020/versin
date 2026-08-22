import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================================
// MATCH AVAILABILITY SERVICE
// ============================================================
//
// Responsável pelo modo:
//
// DISPONÍVEIS AGORA
//
// Este service controla:
//
// - ativar disponibilidade por 30 minutos;
// - ativar disponibilidade por 1 hora;
// - ativar disponibilidade por 2 horas;
// - encerrar disponibilidade manualmente;
// - carregar o estado atual;
// - calcular tempo restante.
//
// Banco:
//
// public.profiles.available_now
// public.profiles.available_until
//
// RPCs:
//
// public.set_my_available_now(p_minutes integer)
// public.clear_my_available_now()
//
// ============================================================

class MatchAvailabilityService {
  // ============================================================
  // SUPABASE
  // ============================================================

  final SupabaseClient _supabase;

  // ============================================================
  // CONFIGURAÇÃO
  // ============================================================

  static const int thirtyMinutes = 30;

  static const int oneHour = 60;

  static const int twoHours = 120;

  static const List<
    int
  >
  allowedDurations = [
    thirtyMinutes,
    oneHour,
    twoHours,
  ];

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  MatchAvailabilityService({
    SupabaseClient? supabase,
  }) : _supabase =
           supabase ??
           Supabase.instance.client;

  // ============================================================
  // ATIVAR DISPONIBILIDADE
  // ============================================================

  Future<
    MatchAvailabilityState
  >
  setAvailableNow({
    required int minutes,
  }) async {
    final normalizedMinutes = _validateMinutes(
      minutes,
    );

    _requireAuthenticatedUserId();

    try {
      debugPrint(
        '[MATCH AVAILABILITY] '
        'Ativando disponibilidade por '
        '$normalizedMinutes minuto(s).',
      );

      await _supabase.rpc(
        'set_my_available_now',
        params: {
          'p_minutes': normalizedMinutes,
        },
      );

      final state = await loadCurrentState();

      debugPrint(
        '[MATCH AVAILABILITY] '
        'Disponibilidade ativada. '
        'Até: '
        '${state.availableUntil?.toIso8601String() ?? 'n/a'}',
      );

      return state;
    } on PostgrestException catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[MATCH AVAILABILITY] '
        'Erro Supabase ao ativar disponibilidade: '
        '${error.message}',
      );

      debugPrint(
        '[MATCH AVAILABILITY] '
        'Código: ${error.code}',
      );

      debugPrint(
        '[MATCH AVAILABILITY] '
        'Detalhes: ${error.details}',
      );

      debugPrint(
        '$stackTrace',
      );

      rethrow;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[MATCH AVAILABILITY] '
        'Erro inesperado ao ativar disponibilidade: '
        '$error',
      );

      debugPrint(
        '$stackTrace',
      );

      rethrow;
    }
  }

  // ============================================================
  // 30 MINUTOS
  // ============================================================

  Future<
    MatchAvailabilityState
  >
  setThirtyMinutes() {
    return setAvailableNow(
      minutes: thirtyMinutes,
    );
  }

  // ============================================================
  // 1 HORA
  // ============================================================

  Future<
    MatchAvailabilityState
  >
  setOneHour() {
    return setAvailableNow(
      minutes: oneHour,
    );
  }

  // ============================================================
  // 2 HORAS
  // ============================================================

  Future<
    MatchAvailabilityState
  >
  setTwoHours() {
    return setAvailableNow(
      minutes: twoHours,
    );
  }

  // ============================================================
  // ENCERRAR DISPONIBILIDADE
  // ============================================================

  Future<
    MatchAvailabilityState
  >
  clearAvailability() async {
    _requireAuthenticatedUserId();

    try {
      debugPrint(
        '[MATCH AVAILABILITY] '
        'Encerrando disponibilidade.',
      );

      await _supabase.rpc(
        'clear_my_available_now',
      );

      debugPrint(
        '[MATCH AVAILABILITY] '
        'Disponibilidade encerrada.',
      );

      return const MatchAvailabilityState(
        availableNow: false,
        availableUntil: null,
      );
    } on PostgrestException catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[MATCH AVAILABILITY] '
        'Erro Supabase ao encerrar disponibilidade: '
        '${error.message}',
      );

      debugPrint(
        '[MATCH AVAILABILITY] '
        'Código: ${error.code}',
      );

      debugPrint(
        '[MATCH AVAILABILITY] '
        'Detalhes: ${error.details}',
      );

      debugPrint(
        '$stackTrace',
      );

      rethrow;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[MATCH AVAILABILITY] '
        'Erro inesperado ao encerrar disponibilidade: '
        '$error',
      );

      debugPrint(
        '$stackTrace',
      );

      rethrow;
    }
  }

  // ============================================================
  // CARREGAR ESTADO ATUAL
  // ============================================================

  Future<
    MatchAvailabilityState
  >
  loadCurrentState() async {
    final userId = _requireAuthenticatedUserId();

    try {
      final response = await _supabase
          .from(
            'profiles',
          )
          .select(
            '''
                available_now,
                available_until
                ''',
          )
          .eq(
            'id',
            userId,
          )
          .maybeSingle();

      if (response ==
          null) {
        return const MatchAvailabilityState(
          availableNow: false,
          availableUntil: null,
        );
      }

      final state = MatchAvailabilityState.fromMap(
        Map<
          String,
          dynamic
        >.from(
          response,
        ),
      );

      debugPrint(
        '[MATCH AVAILABILITY] '
        'Estado carregado: '
        'availableNow=${state.availableNow} | '
        'availableUntil=${state.availableUntil?.toIso8601String() ?? 'null'} | '
        'active=${state.isActive}',
      );

      return state;
    } on PostgrestException catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[MATCH AVAILABILITY] '
        'Erro Supabase ao carregar disponibilidade: '
        '${error.message}',
      );

      debugPrint(
        '[MATCH AVAILABILITY] '
        'Código: ${error.code}',
      );

      debugPrint(
        '$stackTrace',
      );

      rethrow;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[MATCH AVAILABILITY] '
        'Erro inesperado ao carregar disponibilidade: '
        '$error',
      );

      debugPrint(
        '$stackTrace',
      );

      rethrow;
    }
  }

  // ============================================================
  // DISPONÍVEL AGORA?
  // ============================================================

  Future<
    bool
  >
  isAvailableNow() async {
    final state = await loadCurrentState();

    return state.isActive;
  }

  // ============================================================
  // TEMPO RESTANTE
  // ============================================================

  Future<
    Duration
  >
  remainingTime() async {
    final state = await loadCurrentState();

    return state.remainingTime;
  }

  // ============================================================
  // VALIDAR TEMPO
  // ============================================================

  int _validateMinutes(
    int value,
  ) {
    if (!allowedDurations.contains(
      value,
    )) {
      throw ArgumentError(
        'Tempo inválido. '
        'Use apenas 30, 60 ou 120 minutos.',
      );
    }

    return value;
  }

  // ============================================================
  // USUÁRIO AUTENTICADO
  // ============================================================

  String _requireAuthenticatedUserId() {
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
}

// ============================================================
// MATCH AVAILABILITY STATE
// ============================================================
//
// Representa o estado atual do usuário.
//
// IMPORTANTE:
//
// availableNow sozinho não significa que ainda está ativo.
//
// Também precisamos verificar:
//
// availableUntil > agora.
//
// ============================================================

class MatchAvailabilityState {
  // ============================================================
  // CAMPOS
  // ============================================================

  final bool availableNow;

  final DateTime? availableUntil;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  const MatchAvailabilityState({
    required this.availableNow,
    required this.availableUntil,
  });

  // ============================================================
  // FROM MAP
  // ============================================================

  factory MatchAvailabilityState.fromMap(
    Map<
      String,
      dynamic
    >
    map,
  ) {
    return MatchAvailabilityState(
      availableNow: _readBool(
        map['available_now'],
      ),
      availableUntil: _readDateTime(
        map['available_until'],
      ),
    );
  }

  // ============================================================
  // ESTÁ ATIVO
  // ============================================================

  bool get isActive {
    if (!availableNow) {
      return false;
    }

    final until = availableUntil;

    if (until ==
        null) {
      return false;
    }

    return until.isAfter(
      DateTime.now().toUtc(),
    );
  }

  // ============================================================
  // EXPIRADO
  // ============================================================

  bool get isExpired {
    if (!availableNow) {
      return false;
    }

    final until = availableUntil;

    if (until ==
        null) {
      return true;
    }

    return !until.isAfter(
      DateTime.now().toUtc(),
    );
  }

  // ============================================================
  // TEMPO RESTANTE
  // ============================================================

  Duration get remainingTime {
    if (!isActive) {
      return Duration.zero;
    }

    final until = availableUntil;

    if (until ==
        null) {
      return Duration.zero;
    }

    final difference = until.difference(
      DateTime.now().toUtc(),
    );

    if (difference.isNegative) {
      return Duration.zero;
    }

    return difference;
  }

  // ============================================================
  // MINUTOS RESTANTES
  // ============================================================

  int get remainingMinutes {
    final duration = remainingTime;

    if (duration ==
        Duration.zero) {
      return 0;
    }

    final seconds = duration.inSeconds;

    return (seconds /
            60)
        .ceil();
  }

  // ============================================================
  // LABEL
  // ============================================================

  String get remainingLabel {
    if (!isActive) {
      return 'Indisponível';
    }

    final minutes = remainingMinutes;

    if (minutes <=
        0) {
      return 'Encerrando';
    }

    if (minutes <
        60) {
      return '$minutes min restantes';
    }

    final hours =
        minutes ~/
        60;

    final remainder =
        minutes %
        60;

    if (remainder ==
        0) {
      return hours ==
              1
          ? '1 hora restante'
          : '$hours horas restantes';
    }

    if (hours ==
        1) {
      return '1h ${remainder}min restantes';
    }

    return '${hours}h ${remainder}min restantes';
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  MatchAvailabilityState copyWith({
    bool? availableNow,
    DateTime? availableUntil,
    bool clearAvailableUntil = false,
  }) {
    return MatchAvailabilityState(
      availableNow:
          availableNow ??
          this.availableNow,
      availableUntil: clearAvailableUntil
          ? null
          : availableUntil ??
                this.availableUntil,
    );
  }

  // ============================================================
  // TO STRING
  // ============================================================

  @override
  String toString() {
    return 'MatchAvailabilityState('
        'availableNow: $availableNow, '
        'availableUntil: $availableUntil, '
        'isActive: $isActive, '
        'remainingMinutes: $remainingMinutes'
        ')';
  }

  // ============================================================
  // READ BOOL
  // ============================================================

  static bool _readBool(
    dynamic value,
  ) {
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
      final normalized = value.trim().toLowerCase();

      return normalized ==
              'true' ||
          normalized ==
              '1';
    }

    return false;
  }

  // ============================================================
  // READ DATETIME
  // ============================================================

  static DateTime? _readDateTime(
    dynamic value,
  ) {
    if (value ==
        null) {
      return null;
    }

    if (value
        is DateTime) {
      return value.toUtc();
    }

    final normalized = value.toString().trim();

    if (normalized.isEmpty) {
      return null;
    }

    return DateTime.tryParse(
      normalized,
    )?.toUtc();
  }
}
