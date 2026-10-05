// ============================================================
// MATCH AVAILABILITY STATE
// ============================================================
//
// Representa o estado da disponibilidade temporária do usuário.
//
// Exemplo:
//
// availableNow: true
// availableUntil: 2026-08-22 22:30
//
// A propriedade isActive também verifica se o horário ainda
// não expirou.
//
// NÃO:
//
// - acessa Supabase;
// - conhece Widgets;
// - controla Timer;
// - altera estado;
// - possui regra de navegação.
//
// ============================================================

class MatchAvailabilityState {
  // ============================================================
  // FIELDS
  // ============================================================

  final bool availableNow;

  final DateTime? availableUntil;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  const MatchAvailabilityState({
    required this.availableNow,
    required this.availableUntil,
  });

  // ============================================================
  // INITIAL
  // ============================================================

  const MatchAvailabilityState.initial()
    : availableNow = false,
      availableUntil = null;

  // ============================================================
  // IS ACTIVE
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
      DateTime.now(),
    );
  }

  // ============================================================
  // IS EXPIRED
  // ============================================================

  bool get isExpired {
    final until = availableUntil;

    if (until ==
        null) {
      return false;
    }

    return !until.isAfter(
      DateTime.now(),
    );
  }

  // ============================================================
  // REMAINING
  // ============================================================

  Duration get remaining {
    final until = availableUntil;

    if (!availableNow ||
        until ==
            null) {
      return Duration.zero;
    }

    final difference = until.difference(
      DateTime.now(),
    );

    if (difference.isNegative) {
      return Duration.zero;
    }

    return difference;
  }

  // ============================================================
  // REMAINING MINUTES
  // ============================================================

  int get remainingMinutes {
    final duration = remaining;

    if (duration ==
        Duration.zero) {
      return 0;
    }

    // Arredonda para cima para evitar mostrar "0 min"
    // quando ainda restam alguns segundos.

    return (duration.inSeconds /
            Duration.secondsPerMinute)
        .ceil();
  }

  // ============================================================
  // REMAINING LABEL
  // ============================================================

  String get remainingLabel {
    if (!isActive) {
      return 'Encerrado';
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

    final remainingMinutesAfterHour =
        minutes %
        60;

    if (remainingMinutesAfterHour ==
        0) {
      if (hours ==
          1) {
        return '1 hora restante';
      }

      return '$hours horas restantes';
    }

    if (hours ==
        1) {
      return '1h ${remainingMinutesAfterHour}min restantes';
    }

    return '${hours}h ${remainingMinutesAfterHour}min restantes';
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
  // TO MAP
  // ============================================================

  Map<
    String,
    dynamic
  >
  toMap() {
    return {
      'available_now': availableNow,

      'available_until': availableUntil?.toUtc().toIso8601String(),
    };
  }

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
    final availableNow =
        map['available_now'] ==
        true;

    final rawAvailableUntil = map['available_until'];

    DateTime? availableUntil;

    if (rawAvailableUntil
        is DateTime) {
      availableUntil = rawAvailableUntil.toLocal();
    } else if (rawAvailableUntil !=
        null) {
      availableUntil = DateTime.tryParse(
        rawAvailableUntil.toString(),
      )?.toLocal();
    }

    return MatchAvailabilityState(
      availableNow: availableNow,

      availableUntil: availableUntil,
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
        'remaining: ${remaining.inSeconds}s'
        ')';
  }

  // ============================================================
  // EQUALITY
  // ============================================================

  @override
  bool operator ==(
    Object other,
  ) {
    if (identical(
      this,
      other,
    )) {
      return true;
    }

    return other
            is MatchAvailabilityState &&
        other.availableNow ==
            availableNow &&
        other.availableUntil ==
            availableUntil;
  }

  // ============================================================
  // HASH CODE
  // ============================================================

  @override
  int get hashCode {
    return Object.hash(
      availableNow,
      availableUntil,
    );
  }
}
