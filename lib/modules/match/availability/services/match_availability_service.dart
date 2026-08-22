import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/match_availability_state.dart';

// ============================================================
// MATCH AVAILABILITY SERVICE
// ============================================================
//
// Responsável exclusivamente por:
//
// - carregar disponibilidade do usuário;
// - ativar disponibilidade;
// - encerrar disponibilidade;
// - persistir dados no Supabase.
//
// NÃO:
//
// - controla Widgets;
// - usa BuildContext;
// - mostra SnackBars;
// - abre páginas;
// - controla Timer.
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
  // TABLE
  // ============================================================

  static const String _tableName = 'match_availability';

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
  // CURRENT USER ID
  // ============================================================

  String? get _currentUserId {
    final id = _supabase.auth.currentUser?.id.trim();

    if (id ==
            null ||
        id.isEmpty) {
      return null;
    }

    return id;
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
      final response = await _supabase
          .from(
            _tableName,
          )
          .select(
            'available_now, available_until',
          )
          .eq(
            'user_id',
            userId,
          )
          .maybeSingle();

      // ========================================================
      // NO RECORD
      // ========================================================

      if (response ==
          null) {
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
      // EXPIRED
      // ========================================================

      if (availableUntil ==
              null ||
          !availableUntil.isAfter(
            DateTime.now(),
          )) {
        if (availableNow) {
          await _expireAvailability(
            userId,
          );
        }

        return const MatchAvailabilityState(
          availableNow: false,
          availableUntil: null,
        );
      }

      return MatchAvailabilityState(
        availableNow: availableNow,
        availableUntil: availableUntil,
      );
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
    final userId = _requireUserId();

    _validateMinutes(
      minutes,
    );

    final now = DateTime.now().toUtc();

    final availableUntil = now.add(
      Duration(
        minutes: minutes,
      ),
    );

    try {
      await _supabase
          .from(
            _tableName,
          )
          .upsert(
            {
              'user_id': userId,

              'available_now': true,

              'available_until': availableUntil.toIso8601String(),

              'updated_at': now.toIso8601String(),
            },

            onConflict: 'user_id',
          );

      debugPrint(
        '[MATCH AVAILABILITY SERVICE] '
        'Disponibilidade ativada. '
        'Usuário: $userId | '
        'Até: $availableUntil',
      );

      return MatchAvailabilityState(
        availableNow: true,
        availableUntil: availableUntil.toLocal(),
      );
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
    final userId = _requireUserId();

    final now = DateTime.now().toUtc();

    try {
      await _supabase
          .from(
            _tableName,
          )
          .upsert(
            {
              'user_id': userId,

              'available_now': false,

              'available_until': null,

              'updated_at': now.toIso8601String(),
            },

            onConflict: 'user_id',
          );

      debugPrint(
        '[MATCH AVAILABILITY SERVICE] '
        'Disponibilidade encerrada. '
        'Usuário: $userId',
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
  // EXPIRE AVAILABILITY
  // ============================================================

  Future<
    void
  >
  _expireAvailability(
    String userId,
  ) async {
    try {
      await _supabase
          .from(
            _tableName,
          )
          .update(
            {
              'available_now': false,

              'available_until': null,

              'updated_at': DateTime.now().toUtc().toIso8601String(),
            },
          )
          .eq(
            'user_id',
            userId,
          );

      debugPrint(
        '[MATCH AVAILABILITY SERVICE] '
        'Disponibilidade expirada automaticamente.',
      );
    } catch (
      error
    ) {
      debugPrint(
        '[MATCH AVAILABILITY SERVICE] '
        'Erro ao expirar disponibilidade: '
        '$error',
      );
    }
  }

  // ============================================================
  // REQUIRE USER ID
  // ============================================================

  String _requireUserId() {
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
  // VALIDATE MINUTES
  // ============================================================

  void _validateMinutes(
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
    dynamic value,
  ) {
    if (value ==
        null) {
      return null;
    }

    if (value
        is DateTime) {
      return value.toLocal();
    }

    final raw = value.toString().trim();

    if (raw.isEmpty) {
      return null;
    }

    return DateTime.tryParse(
      raw,
    )?.toLocal();
  }
}
