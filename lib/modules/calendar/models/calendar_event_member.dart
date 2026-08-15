import 'calendar_member_status.dart';

// ============================================================
// CALENDAR EVENT MEMBER
// ============================================================
//
// Representa a participação de um usuário em um compromisso.
//
// Cada registro corresponde a:
//
// - um evento;
// - um usuário;
// - um status de participação.
//
// Status possíveis:
//
// - pending;
// - accepted;
// - declined.
//
// ============================================================

class CalendarEventMember {
  // ==========================================================
  // IDENTIFICAÇÃO
  // ==========================================================

  final String id;

  final String eventId;

  final String userId;

  // ==========================================================
  // STATUS
  // ==========================================================

  final CalendarMemberStatus status;

  // ==========================================================
  // DATAS
  // ==========================================================

  final DateTime createdAt;

  final DateTime? respondedAt;

  // ==========================================================
  // CONSTRUTOR
  // ==========================================================

  const CalendarEventMember({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });

  // ==========================================================
  // HELPERS
  // ==========================================================

  bool get isPending {
    return status.isPending;
  }

  bool get isAccepted {
    return status.isAccepted;
  }

  bool get isDeclined {
    return status.isDeclined;
  }

  bool get hasResponded {
    return respondedAt !=
        null;
  }

  bool get hasValidEventId {
    return eventId.trim().isNotEmpty;
  }

  bool get hasValidUserId {
    return userId.trim().isNotEmpty;
  }

  // ==========================================================
  // COPY WITH
  // ==========================================================

  CalendarEventMember copyWith({
    String? id,
    String? eventId,
    String? userId,
    CalendarMemberStatus? status,
    DateTime? createdAt,
    DateTime? respondedAt,
    bool clearRespondedAt = false,
  }) {
    return CalendarEventMember(
      id:
          id ??
          this.id,

      eventId:
          eventId ??
          this.eventId,

      userId:
          userId ??
          this.userId,

      status:
          status ??
          this.status,

      createdAt:
          createdAt ??
          this.createdAt,

      respondedAt: clearRespondedAt
          ? null
          : respondedAt ??
                this.respondedAt,
    );
  }

  // ==========================================================
  // FROM MAP
  // ==========================================================

  factory CalendarEventMember.fromMap(
    Map<
      String,
      dynamic
    >
    map,
  ) {
    final createdAt =
        _parseDateTime(
          map['created_at'],
        ) ??
        DateTime.now();

    return CalendarEventMember(
      id: _parseString(
        map['id'],
      ),

      eventId: _parseString(
        map['event_id'],
      ),

      userId: _parseString(
        map['user_id'],
      ),

      status: CalendarMemberStatusExtension.fromKey(
        map['status']?.toString(),
      ),

      createdAt: createdAt,

      respondedAt: _parseDateTime(
        map['responded_at'],
      ),
    );
  }

  // ==========================================================
  // TO MAP
  // ==========================================================

  Map<
    String,
    dynamic
  >
  toMap() {
    return {
      'id': id,

      'event_id': eventId,

      'user_id': userId,

      'status': status.key,

      'created_at': createdAt.toUtc().toIso8601String(),

      'responded_at': respondedAt?.toUtc().toIso8601String(),
    };
  }

  // ==========================================================
  // TO INSERT MAP
  // ==========================================================

  Map<
    String,
    dynamic
  >
  toInsertMap() {
    return {
      'event_id': eventId.trim(),

      'user_id': userId.trim(),

      'status': status.key,

      'created_at': createdAt.toUtc().toIso8601String(),

      'responded_at': respondedAt?.toUtc().toIso8601String(),
    };
  }

  // ==========================================================
  // TO UPDATE MAP
  // ==========================================================

  Map<
    String,
    dynamic
  >
  toUpdateMap() {
    return {
      'status': status.key,

      'responded_at': respondedAt?.toUtc().toIso8601String(),
    };
  }

  // ==========================================================
  // ACEITAR
  // ==========================================================

  CalendarEventMember accept() {
    return copyWith(
      status: CalendarMemberStatus.accepted,

      respondedAt: DateTime.now(),
    );
  }

  // ==========================================================
  // RECUSAR
  // ==========================================================

  CalendarEventMember decline() {
    return copyWith(
      status: CalendarMemberStatus.declined,

      respondedAt: DateTime.now(),
    );
  }

  // ==========================================================
  // VOLTAR PARA PENDENTE
  // ==========================================================

  CalendarEventMember resetToPending() {
    return copyWith(
      status: CalendarMemberStatus.pending,

      clearRespondedAt: true,
    );
  }

  // ==========================================================
  // PARSE STRING
  // ==========================================================

  static String _parseString(
    dynamic value,
  ) {
    return value?.toString().trim() ??
        '';
  }

  // ==========================================================
  // PARSE DATETIME
  // ==========================================================

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

  // ==========================================================
  // TO STRING
  // ==========================================================

  @override
  String toString() {
    return 'CalendarEventMember('
        'id: $id, '
        'eventId: $eventId, '
        'userId: $userId, '
        'status: ${status.key}, '
        'createdAt: $createdAt, '
        'respondedAt: $respondedAt'
        ')';
  }
}
