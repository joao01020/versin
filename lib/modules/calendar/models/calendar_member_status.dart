// ============================================================
// CALENDAR MEMBER STATUS
// ============================================================
//
// Define o estado de participação de um usuário em um
// compromisso colaborativo.
//
// Fluxo normal:
//
// pending
//    ↓
// accepted
//
// ou
//
// pending
//    ↓
// declined
//
// ============================================================

enum CalendarMemberStatus {
  // ==========================================================
  // PENDENTE
  // ==========================================================
  //
  // O usuário recebeu o convite, mas ainda não respondeu.
  //
  // ==========================================================
  pending,

  // ==========================================================
  // ACEITO
  // ==========================================================
  //
  // O usuário aceitou participar do compromisso.
  //
  // O evento pode aparecer normalmente no calendário dele.
  //
  // ==========================================================
  accepted,

  // ==========================================================
  // RECUSADO
  // ==========================================================
  //
  // O usuário recusou o convite.
  //
  // ==========================================================
  declined,
}

// ============================================================
// CALENDAR MEMBER STATUS EXTENSION
// ============================================================

extension CalendarMemberStatusExtension
    on
        CalendarMemberStatus {
  // ==========================================================
  // KEY
  // ==========================================================
  //
  // Valor utilizado no banco de dados.
  //
  // ==========================================================

  String get key {
    switch (this) {
      case CalendarMemberStatus.pending:
        return 'pending';

      case CalendarMemberStatus.accepted:
        return 'accepted';

      case CalendarMemberStatus.declined:
        return 'declined';
    }
  }

  // ==========================================================
  // LABEL
  // ==========================================================

  String get label {
    switch (this) {
      case CalendarMemberStatus.pending:
        return 'Pendente';

      case CalendarMemberStatus.accepted:
        return 'Aceito';

      case CalendarMemberStatus.declined:
        return 'Recusado';
    }
  }

  // ==========================================================
  // DESCRIÇÃO
  // ==========================================================

  String get description {
    switch (this) {
      case CalendarMemberStatus.pending:
        return 'Aguardando resposta ao convite.';

      case CalendarMemberStatus.accepted:
        return 'Convite aceito pelo participante.';

      case CalendarMemberStatus.declined:
        return 'Convite recusado pelo participante.';
    }
  }

  // ==========================================================
  // É PENDENTE
  // ==========================================================

  bool get isPending {
    return this ==
        CalendarMemberStatus.pending;
  }

  // ==========================================================
  // FOI ACEITO
  // ==========================================================

  bool get isAccepted {
    return this ==
        CalendarMemberStatus.accepted;
  }

  // ==========================================================
  // FOI RECUSADO
  // ==========================================================

  bool get isDeclined {
    return this ==
        CalendarMemberStatus.declined;
  }

  // ==========================================================
  // JÁ FOI RESPONDIDO
  // ==========================================================

  bool get hasResponded {
    return this !=
        CalendarMemberStatus.pending;
  }

  // ==========================================================
  // AGUARDA RESPOSTA
  // ==========================================================

  bool get requiresResponse {
    return this ==
        CalendarMemberStatus.pending;
  }

  // ==========================================================
  // PARTICIPA DO EVENTO
  // ==========================================================
  //
  // Somente participantes que aceitaram devem ter o evento
  // considerado confirmado no calendário.
  //
  // ==========================================================

  bool get participatesInEvent {
    return this ==
        CalendarMemberStatus.accepted;
  }

  // ==========================================================
  // PODE ACEITAR
  // ==========================================================

  bool get canAccept {
    return this ==
            CalendarMemberStatus.pending ||
        this ==
            CalendarMemberStatus.declined;
  }

  // ==========================================================
  // PODE RECUSAR
  // ==========================================================

  bool get canDecline {
    return this ==
            CalendarMemberStatus.pending ||
        this ==
            CalendarMemberStatus.accepted;
  }

  // ==========================================================
  // FROM KEY
  // ==========================================================
  //
  // Converte o valor recebido do banco.
  //
  // Em caso de valor:
  //
  // - null;
  // - vazio;
  // - desconhecido;
  //
  // retorna pending por segurança.
  //
  // ==========================================================

  static CalendarMemberStatus fromKey(
    String? value,
  ) {
    switch (value?.trim().toLowerCase()) {
      case 'accepted':
        return CalendarMemberStatus.accepted;

      case 'declined':
        return CalendarMemberStatus.declined;

      case 'pending':
      default:
        return CalendarMemberStatus.pending;
    }
  }

  // ==========================================================
  // TRY FROM KEY
  // ==========================================================
  //
  // Diferente de fromKey(), retorna null quando o valor não
  // corresponde a nenhum status conhecido.
  //
  // ==========================================================

  static CalendarMemberStatus? tryFromKey(
    String? value,
  ) {
    switch (value?.trim().toLowerCase()) {
      case 'pending':
        return CalendarMemberStatus.pending;

      case 'accepted':
        return CalendarMemberStatus.accepted;

      case 'declined':
        return CalendarMemberStatus.declined;

      default:
        return null;
    }
  }

  // ==========================================================
  // VALOR VÁLIDO
  // ==========================================================

  static bool isValidKey(
    String? value,
  ) {
    return tryFromKey(
          value,
        ) !=
        null;
  }
}
