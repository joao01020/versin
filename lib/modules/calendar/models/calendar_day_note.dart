// ============================================================
// CALENDAR DAY NOTE
// ============================================================
//
// Representa uma anotação livre associada a um dia específico
// do calendário.
//
// Diferente de CalendarEvent:
//
// - não possui horário;
// - não é compromisso;
// - não possui participantes;
// - pertence somente ao usuário;
// - pode conter texto livre.
//
// Cada usuário possui no máximo uma anotação principal
// para cada dia.
//
// Banco:
//
// calendar_day_notes
//
// Colunas esperadas:
//
// id
// user_id
// note_date
// content
// created_at
// updated_at
//
// ============================================================

class CalendarDayNote {
  // ==========================================================
  // ID
  // ==========================================================

  final String id;

  // ==========================================================
  // USUÁRIO
  // ==========================================================

  final String userId;

  // ==========================================================
  // DIA DA ANOTAÇÃO
  // ==========================================================

  final DateTime noteDate;

  // ==========================================================
  // CONTEÚDO
  // ==========================================================

  final String content;

  // ==========================================================
  // DATAS
  // ==========================================================

  final DateTime createdAt;

  final DateTime updatedAt;

  // ==========================================================
  // CONSTRUTOR
  // ==========================================================

  const CalendarDayNote({
    required this.id,
    required this.userId,
    required this.noteDate,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  // ==========================================================
  // POSSUI CONTEÚDO
  // ==========================================================

  bool get hasContent {
    return content.trim().isNotEmpty;
  }

  // ==========================================================
  // ESTÁ VAZIA
  // ==========================================================

  bool get isEmpty {
    return content.trim().isEmpty;
  }

  // ==========================================================
  // DATA NORMALIZADA
  // ==========================================================
  //
  // Remove horário da data.
  //
  // ==========================================================

  DateTime get normalizedDate {
    return DateTime(
      noteDate.year,
      noteDate.month,
      noteDate.day,
    );
  }

  // ==========================================================
  // COPY WITH
  // ==========================================================

  CalendarDayNote copyWith({
    String? id,
    String? userId,
    DateTime? noteDate,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CalendarDayNote(
      id:
          id ??
          this.id,

      userId:
          userId ??
          this.userId,

      noteDate:
          noteDate ??
          this.noteDate,

      content:
          content ??
          this.content,

      createdAt:
          createdAt ??
          this.createdAt,

      updatedAt:
          updatedAt ??
          this.updatedAt,
    );
  }

  // ==========================================================
  // FROM MAP
  // ==========================================================
  //
  // Converte o registro recebido do Supabase.
  //
  // ==========================================================

  factory CalendarDayNote.fromMap(
    Map<
      String,
      dynamic
    >
    map,
  ) {
    final now = DateTime.now();

    return CalendarDayNote(
      id: _parseString(
        map['id'],
      ),

      userId: _parseString(
        map['user_id'],
      ),

      noteDate:
          _parseDate(
            map['note_date'],
          ) ??
          DateTime(
            now.year,
            now.month,
            now.day,
          ),

      content: _parseString(
        map['content'],
      ),

      createdAt:
          _parseDateTime(
            map['created_at'],
          ) ??
          now,

      updatedAt:
          _parseDateTime(
            map['updated_at'],
          ) ??
          now,
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

      'user_id': userId,

      'note_date': _formatDate(
        noteDate,
      ),

      'content': content,

      'created_at': createdAt.toUtc().toIso8601String(),

      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  // ==========================================================
  // TO INSERT MAP
  // ==========================================================
  //
  // O ID normalmente será criado pelo PostgreSQL.
  //
  // ==========================================================

  Map<
    String,
    dynamic
  >
  toInsertMap() {
    return {
      'user_id': userId,

      'note_date': _formatDate(
        noteDate,
      ),

      'content': content,
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
      'content': content,

      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  // ==========================================================
  // FORMATAR DATA PARA POSTGRES
  // ==========================================================
  //
  // Retorna:
  //
  // 2026-08-15
  //
  // ==========================================================

  static String _formatDate(
    DateTime date,
  ) {
    final year = date.year.toString().padLeft(
      4,
      '0',
    );

    final month = date.month.toString().padLeft(
      2,
      '0',
    );

    final day = date.day.toString().padLeft(
      2,
      '0',
    );

    return '$year-$month-$day';
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
  // PARSE DATE
  // ==========================================================

  static DateTime? _parseDate(
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

    final parsed = DateTime.tryParse(
      text,
    );

    if (parsed ==
        null) {
      return null;
    }

    return DateTime(
      parsed.year,
      parsed.month,
      parsed.day,
    );
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
    return 'CalendarDayNote('
        'id: $id, '
        'userId: $userId, '
        'noteDate: $noteDate, '
        'contentLength: ${content.length}, '
        'createdAt: $createdAt, '
        'updatedAt: $updatedAt'
        ')';
  }
}
