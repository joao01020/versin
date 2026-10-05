// ============================================================
// COMMUNICATION REQUEST STATUS
// ============================================================
//
// Estado de um pedido de consentimento.
//
// Exemplos:
//
// video_unlock
// video_upgrade
//
// Fluxo:
//
// pending
//    ├── accepted
//    ├── rejected
//    ├── cancelled
//    └── expired
//
// ============================================================

enum CommunicationRequestStatus {
  pending,
  accepted,
  rejected,
  cancelled,
  expired;

  // ==========================================================
  // DATABASE VALUE
  // ==========================================================

  String get value {
    switch (this) {
      case CommunicationRequestStatus.pending:
        return 'pending';

      case CommunicationRequestStatus.accepted:
        return 'accepted';

      case CommunicationRequestStatus.rejected:
        return 'rejected';

      case CommunicationRequestStatus.cancelled:
        return 'cancelled';

      case CommunicationRequestStatus.expired:
        return 'expired';
    }
  }

  // ==========================================================
  // LABEL
  // ==========================================================

  String get label {
    switch (this) {
      case CommunicationRequestStatus.pending:
        return 'Pendente';

      case CommunicationRequestStatus.accepted:
        return 'Aceito';

      case CommunicationRequestStatus.rejected:
        return 'Recusado';

      case CommunicationRequestStatus.cancelled:
        return 'Cancelado';

      case CommunicationRequestStatus.expired:
        return 'Expirado';
    }
  }

  // ==========================================================
  // HELPERS
  // ==========================================================

  bool get isPending =>
      this ==
      CommunicationRequestStatus.pending;

  bool get isAccepted =>
      this ==
      CommunicationRequestStatus.accepted;

  bool get isRejected =>
      this ==
      CommunicationRequestStatus.rejected;

  bool get isCancelled =>
      this ==
      CommunicationRequestStatus.cancelled;

  bool get isExpired =>
      this ==
      CommunicationRequestStatus.expired;

  // ==========================================================
  // FINAL
  // ==========================================================

  bool get isFinal => !isPending;

  // ==========================================================
  // PODE SER RESPONDIDO?
  // ==========================================================

  bool get canRespond => isPending;

  // ==========================================================
  // FROM STRING
  // ==========================================================

  static CommunicationRequestStatus fromString(
    String? value,
  ) {
    final normalized = value?.trim().toLowerCase();

    switch (normalized) {
      case 'pending':
        return CommunicationRequestStatus.pending;

      case 'accepted':
        return CommunicationRequestStatus.accepted;

      case 'rejected':
        return CommunicationRequestStatus.rejected;

      case 'cancelled':
        return CommunicationRequestStatus.cancelled;

      case 'expired':
        return CommunicationRequestStatus.expired;

      default:
        throw ArgumentError(
          'CommunicationRequestStatus inválido: $value',
        );
    }
  }

  // ==========================================================
  // TRY FROM STRING
  // ==========================================================

  static CommunicationRequestStatus? tryFromString(
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
    CommunicationRequestStatus value,
  ) {
    return value.value;
  }
}
