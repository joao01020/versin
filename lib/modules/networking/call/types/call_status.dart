// ============================================================
// CALL STATUS
// ============================================================
//
// Estado geral da chamada.
//
// Fluxo principal:
//
// ringing
//    ↓
// active
//    ↓
// ended
//
// Outros finais:
//
// ringing → rejected
// ringing → cancelled
// ringing → missed
//
// ============================================================

enum CallStatus {
  ringing,
  active,
  rejected,
  cancelled,
  missed,
  ended;

  // ==========================================================
  // DATABASE VALUE
  // ==========================================================

  String get value {
    switch (this) {
      case CallStatus.ringing:
        return 'ringing';

      case CallStatus.active:
        return 'active';

      case CallStatus.rejected:
        return 'rejected';

      case CallStatus.cancelled:
        return 'cancelled';

      case CallStatus.missed:
        return 'missed';

      case CallStatus.ended:
        return 'ended';
    }
  }

  // ==========================================================
  // LABEL
  // ==========================================================

  String get label {
    switch (this) {
      case CallStatus.ringing:
        return 'Chamando';

      case CallStatus.active:
        return 'Em chamada';

      case CallStatus.rejected:
        return 'Recusada';

      case CallStatus.cancelled:
        return 'Cancelada';

      case CallStatus.missed:
        return 'Perdida';

      case CallStatus.ended:
        return 'Encerrada';
    }
  }

  // ==========================================================
  // HELPERS
  // ==========================================================

  bool get isRinging =>
      this ==
      CallStatus.ringing;

  bool get isActive =>
      this ==
      CallStatus.active;

  bool get isRejected =>
      this ==
      CallStatus.rejected;

  bool get isCancelled =>
      this ==
      CallStatus.cancelled;

  bool get isMissed =>
      this ==
      CallStatus.missed;

  bool get isEnded =>
      this ==
      CallStatus.ended;

  // ==========================================================
  // ESTADO FINAL
  // ==========================================================

  bool get isFinished {
    switch (this) {
      case CallStatus.rejected:
      case CallStatus.cancelled:
      case CallStatus.missed:
      case CallStatus.ended:
        return true;

      case CallStatus.ringing:
      case CallStatus.active:
        return false;
    }
  }

  // ==========================================================
  // PODE ACEITAR?
  // ==========================================================

  bool get canAccept => isRinging;

  // ==========================================================
  // PODE RECUSAR?
  // ==========================================================

  bool get canReject => isRinging;

  // ==========================================================
  // PODE ENCERRAR?
  // ==========================================================

  bool get canEnd =>
      isRinging ||
      isActive;

  // ==========================================================
  // FROM STRING
  // ==========================================================

  static CallStatus fromString(
    String? value,
  ) {
    final normalized = value?.trim().toLowerCase();

    switch (normalized) {
      case 'ringing':
        return CallStatus.ringing;

      case 'active':
        return CallStatus.active;

      case 'rejected':
        return CallStatus.rejected;

      case 'cancelled':
        return CallStatus.cancelled;

      case 'missed':
        return CallStatus.missed;

      case 'ended':
        return CallStatus.ended;

      default:
        throw ArgumentError(
          'CallStatus inválido: $value',
        );
    }
  }

  // ==========================================================
  // TRY FROM STRING
  // ==========================================================

  static CallStatus? tryFromString(
    String? value,
  ) {
    try {
      return fromString(
        value,
      );
    } catch (
      _
    ) {
      return null;
    }
  }

  // ==========================================================
  // DATABASE
  // ==========================================================

  static String toDatabase(
    CallStatus value,
  ) {
    return value.value;
  }
}
