import 'calendar_event_type.dart';

// ============================================================
// CALENDAR EVENT
// ============================================================
//
// Representa um evento armazenado no calendário.
//
// Pode representar:
//
// - tarefa pessoal;
// - projeto;
// - reunião;
// - ensaio;
// - gravação;
// - evento.
//
// Banco esperado:
//
// calendar_events
//
// Colunas:
//
// id
// creator_id
// project_id
// title
// description
// starts_at
// ends_at
// location_name
// event_type
// created_at
// updated_at
//
// ============================================================

class CalendarEvent {
  // ============================================================
  // IDENTIFICAÇÃO
  // ============================================================

  final String id;

  final String creatorId;

  final String? projectId;

  // ============================================================
  // CONTEÚDO
  // ============================================================

  final String title;

  final String? description;

  final String? locationName;

  // ============================================================
  // DATA / HORÁRIO
  // ============================================================

  final DateTime startsAt;

  final DateTime? endsAt;

  // ============================================================
  // TIPO
  // ============================================================

  final CalendarEventType type;

  // ============================================================
  // AUDITORIA
  // ============================================================

  final DateTime createdAt;

  final DateTime updatedAt;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  const CalendarEvent({
    required this.id,
    required this.creatorId,
    required this.title,
    required this.startsAt,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    this.projectId,
    this.description,
    this.endsAt,
    this.locationName,
  });

  // ============================================================
  // É PESSOAL
  // ============================================================

  bool get isPersonal {
    return type ==
        CalendarEventType.personal;
  }

  // ============================================================
  // É COLABORATIVO
  // ============================================================

  bool get isCollaborative {
    return type.isCollaborative;
  }

  // ============================================================
  // POSSUI PROJETO
  // ============================================================

  bool get hasProject {
    return _hasText(
      projectId,
    );
  }

  // ============================================================
  // POSSUI DESCRIÇÃO
  // ============================================================

  bool get hasDescription {
    return _hasText(
      description,
    );
  }

  // ============================================================
  // POSSUI LOCAL
  // ============================================================

  bool get hasLocation {
    return _hasText(
      locationName,
    );
  }

  // ============================================================
  // POSSUI HORÁRIO FINAL
  // ============================================================

  bool get hasEndTime {
    return endsAt !=
        null;
  }

  // ============================================================
  // DURAÇÃO
  // ============================================================

  Duration? get duration {
    final end = endsAt;

    if (end ==
        null) {
      return null;
    }

    return end.difference(
      startsAt,
    );
  }

  // ============================================================
  // JÁ TERMINOU
  // ============================================================

  bool get isFinished {
    final reference =
        endsAt ??
        startsAt;

    return reference.isBefore(
      DateTime.now(),
    );
  }

  // ============================================================
  // ESTÁ ACONTECENDO
  // ============================================================

  bool get isHappeningNow {
    final end = endsAt;

    if (end ==
        null) {
      return false;
    }

    final now = DateTime.now();

    return !now.isBefore(
          startsAt,
        ) &&
        !now.isAfter(
          end,
        );
  }

  // ============================================================
  // É FUTURO
  // ============================================================

  bool get isUpcoming {
    return startsAt.isAfter(
      DateTime.now(),
    );
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  CalendarEvent copyWith({
    String? id,
    String? creatorId,
    String? projectId,
    bool clearProjectId = false,
    String? title,
    String? description,
    bool clearDescription = false,
    DateTime? startsAt,
    DateTime? endsAt,
    bool clearEndsAt = false,
    String? locationName,
    bool clearLocationName = false,
    CalendarEventType? type,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CalendarEvent(
      id:
          id ??
          this.id,

      creatorId:
          creatorId ??
          this.creatorId,

      projectId: clearProjectId
          ? null
          : projectId ??
                this.projectId,

      title:
          title ??
          this.title,

      description: clearDescription
          ? null
          : description ??
                this.description,

      startsAt:
          startsAt ??
          this.startsAt,

      endsAt: clearEndsAt
          ? null
          : endsAt ??
                this.endsAt,

      locationName: clearLocationName
          ? null
          : locationName ??
                this.locationName,

      type:
          type ??
          this.type,

      createdAt:
          createdAt ??
          this.createdAt,

      updatedAt:
          updatedAt ??
          this.updatedAt,
    );
  }

  // ============================================================
  // FROM MAP
  // ============================================================

  factory CalendarEvent.fromMap(
    Map<
      String,
      dynamic
    >
    map,
  ) {
    final now = DateTime.now();

    final startsAt =
        _parseDateTime(
          map['starts_at'],
        ) ??
        now;

    final createdAt =
        _parseDateTime(
          map['created_at'],
        ) ??
        now;

    final updatedAt =
        _parseDateTime(
          map['updated_at'],
        ) ??
        createdAt;

    return CalendarEvent(
      id: _parseRequiredString(
        map['id'],
      ),

      creatorId: _parseRequiredString(
        map['creator_id'],
      ),

      projectId: _parseNullableString(
        map['project_id'],
      ),

      title: _parseRequiredString(
        map['title'],
      ),

      description: _parseNullableString(
        map['description'],
      ),

      startsAt: startsAt,

      endsAt: _parseDateTime(
        map['ends_at'],
      ),

      locationName: _parseNullableString(
        map['location_name'],
      ),

      type: CalendarEventTypeExtension.fromKey(
        map['event_type']?.toString(),
      ),

      createdAt: createdAt,

      updatedAt: updatedAt,
    );
  }

  // ============================================================
  // TO MAP
  // ============================================================
  //
  // Representação completa do objeto.
  //
  // ============================================================

  Map<
    String,
    dynamic
  >
  toMap() {
    return {
      'id': id,

      'creator_id': creatorId,

      'project_id': _normalizeOptionalText(
        projectId,
      ),

      'title': title.trim(),

      'description': _normalizeOptionalText(
        description,
      ),

      'starts_at': startsAt.toUtc().toIso8601String(),

      'ends_at': endsAt?.toUtc().toIso8601String(),

      'location_name': _normalizeOptionalText(
        locationName,
      ),

      'event_type': type.key,

      'created_at': createdAt.toUtc().toIso8601String(),

      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  // ============================================================
  // TO INSERT MAP
  // ============================================================
  //
  // Usado para INSERT no Supabase.
  //
  // O id é criado pelo banco.
  //
  // created_at e updated_at podem ser gerados pelo banco,
  // portanto não precisam ser enviados.
  //
  // ============================================================

  Map<
    String,
    dynamic
  >
  toInsertMap() {
    return {
      'creator_id': creatorId,

      'project_id': _normalizeOptionalText(
        projectId,
      ),

      'title': title.trim(),

      'description': _normalizeOptionalText(
        description,
      ),

      'starts_at': startsAt.toUtc().toIso8601String(),

      'ends_at': endsAt?.toUtc().toIso8601String(),

      'location_name': _normalizeOptionalText(
        locationName,
      ),

      'event_type': type.key,
    };
  }

  // ============================================================
  // TO UPDATE MAP
  // ============================================================
  //
  // Não envia:
  //
  // - id;
  // - creator_id;
  // - created_at.
  //
  // ============================================================

  Map<
    String,
    dynamic
  >
  toUpdateMap() {
    return {
      'project_id': _normalizeOptionalText(
        projectId,
      ),

      'title': title.trim(),

      'description': _normalizeOptionalText(
        description,
      ),

      'starts_at': startsAt.toUtc().toIso8601String(),

      'ends_at': endsAt?.toUtc().toIso8601String(),

      'location_name': _normalizeOptionalText(
        locationName,
      ),

      'event_type': type.key,

      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  // ============================================================
  // PARSE STRING OBRIGATÓRIA
  // ============================================================

  static String _parseRequiredString(
    dynamic value,
  ) {
    return value?.toString().trim() ??
        '';
  }

  // ============================================================
  // PARSE STRING OPCIONAL
  // ============================================================

  static String? _parseNullableString(
    dynamic value,
  ) {
    if (value ==
        null) {
      return null;
    }

    final text = value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    return text;
  }

  // ============================================================
  // PARSE DATETIME
  // ============================================================

  static DateTime? _parseDateTime(
    dynamic value,
  ) {
    if (value ==
        null) {
      return null;
    }

    final text = value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    return DateTime.tryParse(
      text,
    );
  }

  // ============================================================
  // NORMALIZAR STRING OPCIONAL
  // ============================================================

  static String? _normalizeOptionalText(
    String? value,
  ) {
    final text = value?.trim();

    if (text ==
            null ||
        text.isEmpty) {
      return null;
    }

    return text;
  }

  // ============================================================
  // POSSUI TEXTO
  // ============================================================

  static bool _hasText(
    String? value,
  ) {
    return value !=
            null &&
        value.trim().isNotEmpty;
  }

  // ============================================================
  // TO STRING
  // ============================================================

  @override
  String toString() {
    return 'CalendarEvent('
        'id: $id, '
        'creatorId: $creatorId, '
        'projectId: $projectId, '
        'title: $title, '
        'type: ${type.key}, '
        'startsAt: $startsAt, '
        'endsAt: $endsAt, '
        'locationName: $locationName'
        ')';
  }
}
