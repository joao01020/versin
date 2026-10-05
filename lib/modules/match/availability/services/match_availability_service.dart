import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/match_availability_state.dart';

// ============================================================
// MATCH AVAILABILITY SERVICE
// ============================================================
//
// Responsável pela persistência da disponibilidade temporária.
//
// BACKEND REAL DO PROJETO:
//
// public.profiles
//
// campos:
//
// - available_now
// - available_until
//
// RPC:
//
// - set_my_available_now
// - clear_my_available_now
//
// NÃO:
//
// - conhece Widgets;
// - controla Timer;
// - controla estado visual;
// - mostra SnackBar.
//
// ============================================================

class MatchAvailabilityService {
  // ============================================================
  // DURATIONS
  // ============================================================

  static const int thirtyMinutes = 30;

  static const int oneHour = 60;

  static const int twoHours = 120;

  // ============================================================
  // SUPABASE
  // ============================================================

  final SupabaseClient _supabase;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  MatchAvailabilityService({
    SupabaseClient? supabase,
  }) : _supabase =
           supabase ??
           Supabase.instance.client;

  // ============================================================
  // CURRENT USER
  // ============================================================

  String? get _currentUserId {
    final userId = _supabase.auth.currentUser?.id.trim();

    if (userId ==
            null ||
        userId.isEmpty) {
      return null;
    }

    return userId;
  }

  // ============================================================
  // LOAD CURRENT STATE
  // ============================================================

  Future<
    MatchAvailabilityState
  >
  loadCurrentState() async {
    final userId = _currentUserId;

    if (userId ==
        null) {
      debugPrint(
        '[MATCH AVAILABILITY SERVICE] '
        'Usuário não autenticado.',
      );

      return const MatchAvailabilityState(
        availableNow: false,
        availableUntil: null,
      );
    }

    try {
      // ========================================================
      // PROFILE
      // ========================================================

      final response = await _supabase
          .from(
            'profiles',
          )
          .select(
            'available_now, available_until',
          )
          .eq(
            'id',
            userId,
          )
          .maybeSingle();

      // ========================================================
      // PROFILE NOT FOUND
      // ========================================================

      if (response ==
          null) {
        debugPrint(
          '[MATCH AVAILABILITY SERVICE] '
          'Perfil não encontrado.',
        );

        return const MatchAvailabilityState(
          availableNow: false,
          availableUntil: null,
        );
      }

      final availableNow =
          response['available_now'] ==
          true;

      final availableUntil = _parseDateTime(
        response['available_until'],
      );

      // ========================================================
      // NOT ACTIVE
      // ========================================================

      if (!availableNow) {
        return const MatchAvailabilityState(
          availableNow: false,
          availableUntil: null,
        );
      }

      // ========================================================
      // INVALID / EXPIRED
      // ========================================================

      if (availableUntil ==
              null ||
          !availableUntil.isAfter(
            DateTime.now(),
          )) {
        debugPrint(
          '[MATCH AVAILABILITY SERVICE] '
          'Disponibilidade expirada.',
        );

        // ======================================================
        // TENTA LIMPAR NO BACKEND
        // ======================================================

        try {
          await clearAvailability();
        } catch (
          error
        ) {
          debugPrint(
            '[MATCH AVAILABILITY SERVICE] '
            'Não foi possível limpar disponibilidade expirada: '
            '$error',
          );
        }

        return const MatchAvailabilityState(
          availableNow: false,
          availableUntil: null,
        );
      }

      // ========================================================
      // ACTIVE
      // ========================================================

      final state = MatchAvailabilityState(
        availableNow: true,
        availableUntil: availableUntil,
      );

      debugPrint(
        '[MATCH AVAILABILITY SERVICE] '
        'Disponibilidade carregada. '
        'Até: ${state.availableUntil}',
      );

      return state;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[MATCH AVAILABILITY SERVICE] '
        'Erro ao carregar disponibilidade: '
        '$error',
      );

      debugPrint(
        '[MATCH AVAILABILITY SERVICE] '
        'Stack trace: '
        '$stackTrace',
      );

      rethrow;
    }
  }

  // ============================================================
  // SET AVAILABLE NOW
  // ============================================================

  Future<
    MatchAvailabilityState
  >
  setAvailableNow({
    required int minutes,
  }) async {
    _requireAuthenticatedUser();

    _validateDuration(
      minutes,
    );

    try {
      debugPrint(
        '[MATCH AVAILABILITY SERVICE] '
        'Ativando disponibilidade por '
        '$minutes minutos.',
      );

      // ========================================================
      // RPC REAL
      // ========================================================
      //
      // A função SQL deve ser responsável por:
      //
      // available_now = true
      // available_until = now() + intervalo
      //
      // ========================================================

      final response = await _supabase.rpc(
        'set_my_available_now',
        params: {
          'p_minutes': minutes,
        },
      );

      // ========================================================
      // TENTAR LER RESULTADO DA RPC
      // ========================================================

      final state = _parseRpcState(
        response,
      );

      if (state !=
          null) {
        debugPrint(
          '[MATCH AVAILABILITY SERVICE] '
          'RPC retornou disponibilidade até '
          '${state.availableUntil}.',
        );

        return state;
      }

      // ========================================================
      // FALLBACK
      // ========================================================
      //
      // Caso a RPC não retorne row/json, carregamos novamente
      // diretamente do profiles.
      //
      // ========================================================

      return loadCurrentState();
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[MATCH AVAILABILITY SERVICE] '
        'Erro ao ativar disponibilidade: '
        '$error',
      );

      debugPrint(
        '[MATCH AVAILABILITY SERVICE] '
        'Stack trace: '
        '$stackTrace',
      );

      rethrow;
    }
  }

  // ============================================================
  // CLEAR AVAILABILITY
  // ============================================================

  Future<
    MatchAvailabilityState
  >
  clearAvailability() async {
    _requireAuthenticatedUser();

    try {
      debugPrint(
        '[MATCH AVAILABILITY SERVICE] '
        'Encerrando disponibilidade.',
      );

      // ========================================================
      // RPC REAL
      // ========================================================

      await _supabase.rpc(
        'clear_my_available_now',
      );

      debugPrint(
        '[MATCH AVAILABILITY SERVICE] '
        'Disponibilidade encerrada.',
      );

      return const MatchAvailabilityState(
        availableNow: false,
        availableUntil: null,
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[MATCH AVAILABILITY SERVICE] '
        'Erro ao encerrar disponibilidade: '
        '$error',
      );

      debugPrint(
        '[MATCH AVAILABILITY SERVICE] '
        'Stack trace: '
        '$stackTrace',
      );

      rethrow;
    }
  }

  // ============================================================
  // REQUIRE AUTH
  // ============================================================

  String _requireAuthenticatedUser() {
    final userId = _currentUserId;

    if (userId ==
        null) {
      throw StateError(
        'Usuário não autenticado.',
      );
    }

    return userId;
  }

  // ============================================================
  // VALIDATE DURATION
  // ============================================================

  void _validateDuration(
    int minutes,
  ) {
    final valid =
        minutes ==
            thirtyMinutes ||
        minutes ==
            oneHour ||
        minutes ==
            twoHours;

    if (!valid) {
      throw ArgumentError.value(
        minutes,
        'minutes',
        'Duração inválida. '
            'Use 30, 60 ou 120 minutos.',
      );
    }
  }

  // ============================================================
  // PARSE DATE
  // ============================================================

  DateTime? _parseDateTime(
    dynamic raw,
  ) {
    if (raw ==
        null) {
      return null;
    }

    if (raw
        is DateTime) {
      return raw.toLocal();
    }

    final value = raw.toString().trim();

    if (value.isEmpty) {
      return null;
    }

    return DateTime.tryParse(
      value,
    )?.toLocal();
  }

  // ============================================================
  // PARSE RPC STATE
  // ============================================================

  MatchAvailabilityState? _parseRpcState(
    dynamic response,
  ) {
    if (response ==
        null) {
      return null;
    }

    // ==========================================================
    // MAP
    // ==========================================================

    if (response
        is Map<
          String,
          dynamic
        >) {
      return _stateFromMap(
        response,
      );
    }

    if (response
        is Map) {
      return _stateFromMap(
        Map<
          String,
          dynamic
        >.from(
          response,
        ),
      );
    }

    // ==========================================================
    // LIST
    // ==========================================================

    if (response
            is List &&
        response.isNotEmpty) {
      final first = response.first;

      if (first
          is Map<
            String,
            dynamic
          >) {
        return _stateFromMap(
          first,
        );
      }

      if (first
          is Map) {
        return _stateFromMap(
          Map<
            String,
            dynamic
          >.from(
            first,
          ),
        );
      }
    }

    return null;
  }

  // ============================================================
  // STATE FROM MAP
  // ============================================================

  MatchAvailabilityState? _stateFromMap(
    Map<
      String,
      dynamic
    >
    map,
  ) {
    final rawAvailableNow = map['available_now'];

    final rawAvailableUntil = map['available_until'];

    // ==========================================================
    // RPC SEM CAMPOS CONHECIDOS
    // ==========================================================

    if (!map.containsKey(
          'available_now',
        ) &&
        !map.containsKey(
          'available_until',
        )) {
      return null;
    }

    final availableNow =
        rawAvailableNow ==
        true;

    final availableUntil = _parseDateTime(
      rawAvailableUntil,
    );

    if (!availableNow ||
        availableUntil ==
            null) {
      return const MatchAvailabilityState(
        availableNow: false,
        availableUntil: null,
      );
    }

    return MatchAvailabilityState(
      availableNow: true,
      availableUntil: availableUntil,
    );
  }
}
