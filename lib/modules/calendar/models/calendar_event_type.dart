// ============================================================
// CALENDAR EVENT TYPE
// ============================================================
//
// Define os tipos de eventos disponíveis no calendário.
//
// ============================================================

enum CalendarEventType {
  // ==========================================================
  // PESSOAL
  // ==========================================================
  personal,

  // ==========================================================
  // PROJETO
  // ==========================================================
  project,

  // ==========================================================
  // REUNIÃO
  // ==========================================================
  meeting,

  // ==========================================================
  // ENSAIO
  // ==========================================================
  rehearsal,

  // ==========================================================
  // GRAVAÇÃO
  // ==========================================================
  recording,

  // ==========================================================
  // EVENTO
  // ==========================================================
  event,
}

// ============================================================
// CALENDAR EVENT TYPE EXTENSION
// ============================================================

extension CalendarEventTypeExtension
    on
        CalendarEventType {
  // ==========================================================
  // KEY
  // ==========================================================

  String get key {
    switch (this) {
      case CalendarEventType.personal:
        return 'personal';

      case CalendarEventType.project:
        return 'project';

      case CalendarEventType.meeting:
        return 'meeting';

      case CalendarEventType.rehearsal:
        return 'rehearsal';

      case CalendarEventType.recording:
        return 'recording';

      case CalendarEventType.event:
        return 'event';
    }
  }

  // ==========================================================
  // LABEL
  // ==========================================================

  String get label {
    switch (this) {
      case CalendarEventType.personal:
        return 'Pessoal';

      case CalendarEventType.project:
        return 'Projeto';

      case CalendarEventType.meeting:
        return 'Reunião';

      case CalendarEventType.rehearsal:
        return 'Ensaio';

      case CalendarEventType.recording:
        return 'Gravação';

      case CalendarEventType.event:
        return 'Evento';
    }
  }

  // ==========================================================
  // DESCRIÇÃO
  // ==========================================================

  String get description {
    switch (this) {
      case CalendarEventType.personal:
        return 'Atividade pessoal adicionada apenas ao seu calendário.';

      case CalendarEventType.project:
        return 'Compromisso relacionado a um projeto colaborativo.';

      case CalendarEventType.meeting:
        return 'Reunião com outros profissionais ou participantes.';

      case CalendarEventType.rehearsal:
        return 'Ensaio presencial ou preparação artística.';

      case CalendarEventType.recording:
        return 'Sessão de gravação em estúdio ou produção.';

      case CalendarEventType.event:
        return 'Evento, apresentação ou compromisso especial.';
    }
  }

  // ==========================================================
  // É COLABORATIVO
  // ==========================================================

  bool get isCollaborative {
    return this !=
        CalendarEventType.personal;
  }

  // ==========================================================
  // É PESSOAL
  // ==========================================================

  bool get isPersonal {
    return this ==
        CalendarEventType.personal;
  }

  // ==========================================================
  // USA PARTICIPANTES
  // ==========================================================

  bool get supportsParticipants {
    return isCollaborative;
  }

  // ==========================================================
  // USA PROJETO
  // ==========================================================

  bool get supportsProject {
    switch (this) {
      case CalendarEventType.personal:
        return false;

      case CalendarEventType.project:
      case CalendarEventType.meeting:
      case CalendarEventType.rehearsal:
      case CalendarEventType.recording:
      case CalendarEventType.event:
        return true;
    }
  }

  // ==========================================================
  // FROM KEY
  // ==========================================================

  static CalendarEventType fromKey(
    String? value,
  ) {
    switch (value?.trim().toLowerCase()) {
      case 'project':
        return CalendarEventType.project;

      case 'meeting':
        return CalendarEventType.meeting;

      case 'rehearsal':
        return CalendarEventType.rehearsal;

      case 'recording':
        return CalendarEventType.recording;

      case 'event':
        return CalendarEventType.event;

      case 'personal':
      default:
        return CalendarEventType.personal;
    }
  }

  // ==========================================================
  // TRY FROM KEY
  // ==========================================================

  static CalendarEventType? tryFromKey(
    String? value,
  ) {
    switch (value?.trim().toLowerCase()) {
      case 'personal':
        return CalendarEventType.personal;

      case 'project':
        return CalendarEventType.project;

      case 'meeting':
        return CalendarEventType.meeting;

      case 'rehearsal':
        return CalendarEventType.rehearsal;

      case 'recording':
        return CalendarEventType.recording;

      case 'event':
        return CalendarEventType.event;

      default:
        return null;
    }
  }
}
