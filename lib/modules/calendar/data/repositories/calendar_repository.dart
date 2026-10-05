import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/calendar_day_note.dart';
import '../../models/calendar_event.dart';
import '../../models/calendar_event_member.dart';
import '../../models/calendar_event_type.dart';
import '../../models/calendar_member_status.dart';

// ============================================================
// CALENDAR REPOSITORY
// ============================================================
//
// Responsável exclusivamente pelo acesso aos dados do
// calendário no Supabase.
//
// Tabelas utilizadas:
//
// calendar_events
// calendar_event_members
// calendar_day_notes
//
// ============================================================

class CalendarRepository {
  // ==========================================================
  // SUPABASE
  // ==========================================================

  final SupabaseClient _supabase;

  // ==========================================================
  // TABELAS
  // ==========================================================

  static const String _eventsTable = 'calendar_events';

  static const String _membersTable = 'calendar_event_members';

  static const String _notesTable = 'calendar_day_notes';

  // ==========================================================
  // CONSTRUTOR
  // ==========================================================

  CalendarRepository({
    SupabaseClient? supabase,
  }) : _supabase =
           supabase ??
           Supabase.instance.client;

  // ==========================================================
  // USER ID
  // ==========================================================

  String? get currentUserId {
    final id = _supabase.auth.currentUser?.id.trim();

    if (id ==
            null ||
        id.isEmpty) {
      return null;
    }

    return id;
  }

  // ==========================================================
  // EXIGIR USUÁRIO
  // ==========================================================

  String _requireUserId() {
    final userId = currentUserId;

    if (userId ==
        null) {
      throw StateError(
        'Usuário não autenticado.',
      );
    }

    return userId;
  }

  // ==========================================================
  // CRIAR TAREFA PESSOAL
  // ==========================================================

  Future<
    CalendarEvent
  >
  createPersonalEvent({
    required String title,
    required DateTime startsAt,
    String? description,
    DateTime? endsAt,
    String? locationName,
  }) async {
    final userId = _requireUserId();

    final cleanTitle = title.trim();

    if (cleanTitle.isEmpty) {
      throw ArgumentError(
        'O título do compromisso não pode ficar vazio.',
      );
    }

    _validateDates(
      startsAt: startsAt,
      endsAt: endsAt,
    );

    final now = DateTime.now().toUtc();

    debugPrint(
      '[CALENDAR REPOSITORY] '
      'Criando compromisso pessoal.',
    );

    final response = await _supabase
        .from(
          _eventsTable,
        )
        .insert(
          {
            'creator_id': userId,

            'project_id': null,

            'title': cleanTitle,

            'description': _cleanNullableText(
              description,
            ),

            'starts_at': startsAt.toUtc().toIso8601String(),

            'ends_at': endsAt?.toUtc().toIso8601String(),

            'location_name': _cleanNullableText(
              locationName,
            ),

            'event_type': CalendarEventType.personal.key,

            'created_at': now.toIso8601String(),

            'updated_at': now.toIso8601String(),
          },
        )
        .select()
        .single();

    final event = CalendarEvent.fromMap(
      Map<
        String,
        dynamic
      >.from(
        response,
      ),
    );

    // ========================================================
    // CRIADOR JÁ É PARTICIPANTE ACEITO
    // ========================================================

    await _insertMember(
      eventId: event.id,

      userId: userId,

      status: CalendarMemberStatus.accepted,

      respondedAt: now,
    );

    debugPrint(
      '[CALENDAR REPOSITORY] '
      'Compromisso pessoal criado: ${event.id}',
    );

    return event;
  }

  // ==========================================================
  // CRIAR COMPROMISSO COLABORATIVO
  // ==========================================================

  Future<
    CalendarEvent
  >
  createCollaborativeEvent({
    required String title,
    required DateTime startsAt,
    required CalendarEventType type,
    required List<
      String
    >
    participantIds,
    String? projectId,
    String? description,
    DateTime? endsAt,
    String? locationName,
  }) async {
    final creatorId = _requireUserId();

    if (type ==
        CalendarEventType.personal) {
      throw ArgumentError(
        'Use createPersonalEvent() para compromissos pessoais.',
      );
    }

    final cleanTitle = title.trim();

    if (cleanTitle.isEmpty) {
      throw ArgumentError(
        'O título do compromisso não pode ficar vazio.',
      );
    }

    _validateDates(
      startsAt: startsAt,
      endsAt: endsAt,
    );

    final now = DateTime.now().toUtc();

    // ========================================================
    // REMOVER IDS INVÁLIDOS E DUPLICADOS
    // ========================================================

    final participants = participantIds
        .map(
          (
            id,
          ) => id.trim(),
        )
        .where(
          (
            id,
          ) =>
              id.isNotEmpty &&
              id !=
                  creatorId,
        )
        .toSet();

    debugPrint(
      '[CALENDAR REPOSITORY] '
      'Criando compromisso colaborativo.',
    );

    debugPrint(
      '[CALENDAR REPOSITORY] '
      'Participantes convidados: ${participants.length}',
    );

    final response = await _supabase
        .from(
          _eventsTable,
        )
        .insert(
          {
            'creator_id': creatorId,

            'project_id': _cleanNullableText(
              projectId,
            ),

            'title': cleanTitle,

            'description': _cleanNullableText(
              description,
            ),

            'starts_at': startsAt.toUtc().toIso8601String(),

            'ends_at': endsAt?.toUtc().toIso8601String(),

            'location_name': _cleanNullableText(
              locationName,
            ),

            'event_type': type.key,

            'created_at': now.toIso8601String(),

            'updated_at': now.toIso8601String(),
          },
        )
        .select()
        .single();

    final event = CalendarEvent.fromMap(
      Map<
        String,
        dynamic
      >.from(
        response,
      ),
    );

    // ========================================================
    // CRIADOR ACEITA AUTOMATICAMENTE
    // ========================================================

    await _insertMember(
      eventId: event.id,

      userId: creatorId,

      status: CalendarMemberStatus.accepted,

      respondedAt: now,
    );

    // ========================================================
    // CRIAR CONVITES
    // ========================================================

    if (participants.isNotEmpty) {
      final rows = participants.map(
        (
          userId,
        ) {
          return {
            'event_id': event.id,

            'user_id': userId,

            'status': CalendarMemberStatus.pending.key,

            'created_at': now.toIso8601String(),

            'responded_at': null,
          };
        },
      ).toList();

      await _supabase
          .from(
            _membersTable,
          )
          .insert(
            rows,
          );
    }

    debugPrint(
      '[CALENDAR REPOSITORY] '
      'Evento criado: ${event.id}',
    );

    debugPrint(
      '[CALENDAR REPOSITORY] '
      'Convites enviados: ${participants.length}',
    );

    return event;
  }

  // ==========================================================
  // EVENTOS DO USUÁRIO
  // ==========================================================
  //
  // Retorna eventos em que o usuário possui participação
  // aceita.
  //
  // Isso inclui:
  //
  // - tarefas pessoais;
  // - eventos criados pelo usuário;
  // - eventos colaborativos aceitos.
  //
  // ==========================================================

  Future<
    List<
      CalendarEvent
    >
  >
  getMyEvents() async {
    final userId = _requireUserId();

    debugPrint(
      '[CALENDAR REPOSITORY] '
      'Carregando eventos do usuário.',
    );

    final memberRows = await _supabase
        .from(
          _membersTable,
        )
        .select(
          'event_id',
        )
        .eq(
          'user_id',
          userId,
        )
        .eq(
          'status',
          CalendarMemberStatus.accepted.key,
        );

    final eventIds =
        (memberRows
                as List)
            .map(
              (
                row,
              ) => row['event_id']?.toString(),
            )
            .whereType<
              String
            >()
            .map(
              (
                id,
              ) => id.trim(),
            )
            .where(
              (
                id,
              ) => id.isNotEmpty,
            )
            .toSet()
            .toList();

    if (eventIds.isEmpty) {
      debugPrint(
        '[CALENDAR REPOSITORY] '
        'Nenhum evento aceito encontrado.',
      );

      return const [];
    }

    final rows = await _supabase
        .from(
          _eventsTable,
        )
        .select()
        .inFilter(
          'id',
          eventIds,
        )
        .order(
          'starts_at',
          ascending: true,
        );

    final events =
        (rows
                as List)
            .map(
              (
                row,
              ) => CalendarEvent.fromMap(
                Map<
                  String,
                  dynamic
                >.from(
                  row,
                ),
              ),
            )
            .toList();

    debugPrint(
      '[CALENDAR REPOSITORY] '
      '${events.length} evento(s) carregado(s).',
    );

    return events;
  }

  // ==========================================================
  // EVENTOS POR PERÍODO
  // ==========================================================

  Future<
    List<
      CalendarEvent
    >
  >
  getEventsBetween({
    required DateTime start,
    required DateTime end,
  }) async {
    if (end.isBefore(
      start,
    )) {
      throw ArgumentError(
        'A data final não pode ser anterior à data inicial.',
      );
    }

    final events = await getMyEvents();

    return events.where(
      (
        event,
      ) {
        final date = event.startsAt;

        return !date.isBefore(
              start,
            ) &&
            !date.isAfter(
              end,
            );
      },
    ).toList();
  }

  // ==========================================================
  // CONVITES PENDENTES
  // ==========================================================

  Future<
    List<
      CalendarEventMember
    >
  >
  getPendingInvitations() async {
    final userId = _requireUserId();

    debugPrint(
      '[CALENDAR REPOSITORY] '
      'Buscando convites pendentes.',
    );

    final rows = await _supabase
        .from(
          _membersTable,
        )
        .select()
        .eq(
          'user_id',
          userId,
        )
        .eq(
          'status',
          CalendarMemberStatus.pending.key,
        )
        .order(
          'created_at',
          ascending: false,
        );

    final invitations =
        (rows
                as List)
            .map(
              (
                row,
              ) => CalendarEventMember.fromMap(
                Map<
                  String,
                  dynamic
                >.from(
                  row,
                ),
              ),
            )
            .toList();

    debugPrint(
      '[CALENDAR REPOSITORY] '
      '${invitations.length} convite(s) pendente(s).',
    );

    return invitations;
  }

  // ==========================================================
  // BUSCAR EVENTO
  // ==========================================================

  Future<
    CalendarEvent?
  >
  getEventById(
    String eventId,
  ) async {
    final cleanEventId = eventId.trim();

    if (cleanEventId.isEmpty) {
      return null;
    }

    final response = await _supabase
        .from(
          _eventsTable,
        )
        .select()
        .eq(
          'id',
          cleanEventId,
        )
        .maybeSingle();

    if (response ==
        null) {
      return null;
    }

    return CalendarEvent.fromMap(
      Map<
        String,
        dynamic
      >.from(
        response,
      ),
    );
  }

  // ==========================================================
  // BUSCAR PARTICIPANTES DO EVENTO
  // ==========================================================

  Future<
    List<
      CalendarEventMember
    >
  >
  getEventMembers(
    String eventId,
  ) async {
    final cleanEventId = eventId.trim();

    if (cleanEventId.isEmpty) {
      return const [];
    }

    final rows = await _supabase
        .from(
          _membersTable,
        )
        .select()
        .eq(
          'event_id',
          cleanEventId,
        )
        .order(
          'created_at',
          ascending: true,
        );

    return (rows
            as List)
        .map(
          (
            row,
          ) => CalendarEventMember.fromMap(
            Map<
              String,
              dynamic
            >.from(
              row,
            ),
          ),
        )
        .toList();
  }

  // ==========================================================
  // ACEITAR CONVITE
  // ==========================================================

  Future<
    void
  >
  acceptInvitation(
    String eventId,
  ) async {
    final userId = _requireUserId();

    final cleanEventId = eventId.trim();

    if (cleanEventId.isEmpty) {
      throw ArgumentError(
        'ID do evento inválido.',
      );
    }

    final now = DateTime.now().toUtc().toIso8601String();

    await _supabase
        .from(
          _membersTable,
        )
        .update(
          {
            'status': CalendarMemberStatus.accepted.key,

            'responded_at': now,
          },
        )
        .eq(
          'event_id',
          cleanEventId,
        )
        .eq(
          'user_id',
          userId,
        )
        .eq(
          'status',
          CalendarMemberStatus.pending.key,
        );

    debugPrint(
      '[CALENDAR REPOSITORY] '
      'Convite aceito: $cleanEventId',
    );
  }

  // ==========================================================
  // RECUSAR CONVITE
  // ==========================================================

  Future<
    void
  >
  declineInvitation(
    String eventId,
  ) async {
    final userId = _requireUserId();

    final cleanEventId = eventId.trim();

    if (cleanEventId.isEmpty) {
      throw ArgumentError(
        'ID do evento inválido.',
      );
    }

    final now = DateTime.now().toUtc().toIso8601String();

    await _supabase
        .from(
          _membersTable,
        )
        .update(
          {
            'status': CalendarMemberStatus.declined.key,

            'responded_at': now,
          },
        )
        .eq(
          'event_id',
          cleanEventId,
        )
        .eq(
          'user_id',
          userId,
        )
        .eq(
          'status',
          CalendarMemberStatus.pending.key,
        );

    debugPrint(
      '[CALENDAR REPOSITORY] '
      'Convite recusado: $cleanEventId',
    );
  }

  // ==========================================================
  // ATUALIZAR EVENTO
  // ==========================================================
  //
  // Somente o criador pode editar.
  //
  // A RLS do Supabase também deve garantir essa regra.
  //
  // ==========================================================

  Future<
    CalendarEvent
  >
  updateEvent({
    required String eventId,
    required String title,
    required DateTime startsAt,
    String? description,
    DateTime? endsAt,
    String? locationName,
  }) async {
    final userId = _requireUserId();

    final cleanEventId = eventId.trim();

    final cleanTitle = title.trim();

    if (cleanEventId.isEmpty) {
      throw ArgumentError(
        'ID do evento inválido.',
      );
    }

    if (cleanTitle.isEmpty) {
      throw ArgumentError(
        'O título não pode ficar vazio.',
      );
    }

    _validateDates(
      startsAt: startsAt,
      endsAt: endsAt,
    );

    final now = DateTime.now().toUtc().toIso8601String();

    final response = await _supabase
        .from(
          _eventsTable,
        )
        .update(
          {
            'title': cleanTitle,

            'description': _cleanNullableText(
              description,
            ),

            'starts_at': startsAt.toUtc().toIso8601String(),

            'ends_at': endsAt?.toUtc().toIso8601String(),

            'location_name': _cleanNullableText(
              locationName,
            ),

            'updated_at': now,
          },
        )
        .eq(
          'id',
          cleanEventId,
        )
        .eq(
          'creator_id',
          userId,
        )
        .select()
        .single();

    debugPrint(
      '[CALENDAR REPOSITORY] '
      'Evento atualizado: $cleanEventId',
    );

    return CalendarEvent.fromMap(
      Map<
        String,
        dynamic
      >.from(
        response,
      ),
    );
  }

  // ==========================================================
  // EXCLUIR EVENTO
  // ==========================================================

  Future<
    void
  >
  deleteEvent(
    String eventId,
  ) async {
    final userId = _requireUserId();

    final cleanEventId = eventId.trim();

    if (cleanEventId.isEmpty) {
      return;
    }

    // ========================================================
    // BUSCAR EVENTO
    // ========================================================

    final event = await getEventById(
      cleanEventId,
    );

    if (event ==
        null) {
      return;
    }

    if (event.creatorId !=
        userId) {
      throw StateError(
        'Somente o criador pode excluir este compromisso.',
      );
    }

    // ========================================================
    // REMOVER PARTICIPANTES
    // ========================================================

    await _supabase
        .from(
          _membersTable,
        )
        .delete()
        .eq(
          'event_id',
          cleanEventId,
        );

    // ========================================================
    // REMOVER EVENTO
    // ========================================================

    await _supabase
        .from(
          _eventsTable,
        )
        .delete()
        .eq(
          'id',
          cleanEventId,
        )
        .eq(
          'creator_id',
          userId,
        );

    debugPrint(
      '[CALENDAR REPOSITORY] '
      'Evento excluído: $cleanEventId',
    );
  }

  // ==========================================================
  // SAIR DE UM EVENTO
  // ==========================================================
  //
  // Permite que um participante remova o evento do próprio
  // calendário sem excluir o compromisso para os demais.
  //
  // O criador não pode utilizar esta função.
  //
  // ==========================================================

  Future<
    void
  >
  leaveEvent(
    String eventId,
  ) async {
    final userId = _requireUserId();

    final cleanEventId = eventId.trim();

    if (cleanEventId.isEmpty) {
      throw ArgumentError(
        'ID do evento inválido.',
      );
    }

    final event = await getEventById(
      cleanEventId,
    );

    if (event ==
        null) {
      return;
    }

    if (event.creatorId ==
        userId) {
      throw StateError(
        'O criador não pode sair do próprio compromisso.',
      );
    }

    await _supabase
        .from(
          _membersTable,
        )
        .delete()
        .eq(
          'event_id',
          cleanEventId,
        )
        .eq(
          'user_id',
          userId,
        );

    debugPrint(
      '[CALENDAR REPOSITORY] '
      'Usuário saiu do evento: $cleanEventId',
    );
  }

  // ==========================================================
  // BUSCAR ANOTAÇÃO DO DIA
  // ==========================================================
  //
  // Cada usuário possui no máximo uma anotação por dia.
  //
  // ==========================================================

  Future<
    CalendarDayNote?
  >
  getDayNote(
    DateTime date,
  ) async {
    final userId = _requireUserId();

    final normalizedDate = _formatDateOnly(
      date,
    );

    debugPrint(
      '[CALENDAR REPOSITORY] '
      'Buscando anotação do dia $normalizedDate.',
    );

    final response = await _supabase
        .from(
          _notesTable,
        )
        .select()
        .eq(
          'user_id',
          userId,
        )
        .eq(
          'note_date',
          normalizedDate,
        )
        .maybeSingle();

    if (response ==
        null) {
      debugPrint(
        '[CALENDAR REPOSITORY] '
        'Nenhuma anotação encontrada para $normalizedDate.',
      );

      return null;
    }

    return CalendarDayNote.fromMap(
      Map<
        String,
        dynamic
      >.from(
        response,
      ),
    );
  }

  // ==========================================================
  // BUSCAR ANOTAÇÕES DO MÊS
  // ==========================================================
  //
  // Utilizado para:
  //
  // - marcar os dias que possuem anotação;
  // - evitar uma consulta ao banco para cada célula;
  // - carregar o estado do mês de uma única vez.
  //
  // ==========================================================

  Future<
    List<
      CalendarDayNote
    >
  >
  getNotesForMonth(
    DateTime month,
  ) async {
    final userId = _requireUserId();

    final firstDay = DateTime(
      month.year,
      month.month,
      1,
    );

    final nextMonth = DateTime(
      month.year,
      month.month +
          1,
      1,
    );

    final start = _formatDateOnly(
      firstDay,
    );

    final endExclusive = _formatDateOnly(
      nextMonth,
    );

    debugPrint(
      '[CALENDAR REPOSITORY] '
      'Buscando anotações de $start até $endExclusive.',
    );

    final rows = await _supabase
        .from(
          _notesTable,
        )
        .select()
        .eq(
          'user_id',
          userId,
        )
        .gte(
          'note_date',
          start,
        )
        .lt(
          'note_date',
          endExclusive,
        )
        .order(
          'note_date',
          ascending: true,
        );

    final notes =
        (rows
                as List)
            .map(
              (
                row,
              ) {
                return CalendarDayNote.fromMap(
                  Map<
                    String,
                    dynamic
                  >.from(
                    row,
                  ),
                );
              },
            )
            .toList();

    debugPrint(
      '[CALENDAR REPOSITORY] '
      '${notes.length} anotação(ões) carregada(s).',
    );

    return notes;
  }

  // ==========================================================
  // SALVAR ANOTAÇÃO DO DIA
  // ==========================================================
  //
  // Utiliza UPSERT porque existe somente uma anotação por:
  //
  // user_id + note_date
  //
  // Portanto:
  //
  // - se não existir, cria;
  // - se existir, atualiza.
  //
  // Requer no banco:
  //
  // unique(user_id, note_date)
  //
  // ==========================================================

  Future<
    CalendarDayNote
  >
  saveDayNote({
    required DateTime date,
    required String content,
  }) async {
    final userId = _requireUserId();

    final normalizedContent = content.trim();

    if (normalizedContent.isEmpty) {
      throw ArgumentError(
        'A anotação não pode ficar vazia.',
      );
    }

    final normalizedDate = _formatDateOnly(
      date,
    );

    final now = DateTime.now().toUtc().toIso8601String();

    debugPrint(
      '[CALENDAR REPOSITORY] '
      'Salvando anotação de $normalizedDate.',
    );

    final response = await _supabase
        .from(
          _notesTable,
        )
        .upsert(
          {
            'user_id': userId,

            'note_date': normalizedDate,

            'content': normalizedContent,

            'updated_at': now,
          },
          onConflict: 'user_id,note_date',
        )
        .select()
        .single();

    final note = CalendarDayNote.fromMap(
      Map<
        String,
        dynamic
      >.from(
        response,
      ),
    );

    debugPrint(
      '[CALENDAR REPOSITORY] '
      'Anotação salva: ${note.id}',
    );

    return note;
  }

  // ==========================================================
  // EXCLUIR ANOTAÇÃO DO DIA
  // ==========================================================

  Future<
    void
  >
  deleteDayNote(
    DateTime date,
  ) async {
    final userId = _requireUserId();

    final normalizedDate = _formatDateOnly(
      date,
    );

    await _supabase
        .from(
          _notesTable,
        )
        .delete()
        .eq(
          'user_id',
          userId,
        )
        .eq(
          'note_date',
          normalizedDate,
        );

    debugPrint(
      '[CALENDAR REPOSITORY] '
      'Anotação removida de $normalizedDate.',
    );
  }

  // ==========================================================
  // EXCLUIR ANOTAÇÃO POR ID
  // ==========================================================

  Future<
    void
  >
  deleteDayNoteById(
    String noteId,
  ) async {
    final userId = _requireUserId();

    final normalizedId = noteId.trim();

    if (normalizedId.isEmpty) {
      throw ArgumentError(
        'ID da anotação inválido.',
      );
    }

    await _supabase
        .from(
          _notesTable,
        )
        .delete()
        .eq(
          'id',
          normalizedId,
        )
        .eq(
          'user_id',
          userId,
        );

    debugPrint(
      '[CALENDAR REPOSITORY] '
      'Anotação removida: $normalizedId',
    );
  }

  // ==========================================================
  // EXISTE ANOTAÇÃO NO DIA?
  // ==========================================================
  //
  // Útil para verificações pontuais.
  //
  // Para desenhar o calendário inteiro, prefira
  // getNotesForMonth().
  //
  // ==========================================================

  Future<
    bool
  >
  hasDayNote(
    DateTime date,
  ) async {
    final note = await getDayNote(
      date,
    );

    return note !=
        null;
  }

  // ==========================================================
  // INSERIR PARTICIPANTE
  // ==========================================================

  Future<
    void
  >
  _insertMember({
    required String eventId,
    required String userId,
    required CalendarMemberStatus status,
    DateTime? respondedAt,
  }) async {
    final now = DateTime.now().toUtc();

    await _supabase
        .from(
          _membersTable,
        )
        .insert(
          {
            'event_id': eventId,

            'user_id': userId,

            'status': status.key,

            'created_at': now.toIso8601String(),

            'responded_at': respondedAt?.toUtc().toIso8601String(),
          },
        );
  }

  // ==========================================================
  // VALIDAR DATAS
  // ==========================================================

  void _validateDates({
    required DateTime startsAt,
    DateTime? endsAt,
  }) {
    if (endsAt ==
        null) {
      return;
    }

    if (endsAt.isBefore(
      startsAt,
    )) {
      throw ArgumentError(
        'O horário de término não pode ser anterior ao início.',
      );
    }
  }

  // ==========================================================
  // FORMATAR DATA SEM HORÁRIO
  // ==========================================================
  //
  // Retorna:
  //
  // 2026-08-15
  //
  // O PostgreSQL armazena note_date como DATE.
  //
  // ==========================================================

  String _formatDateOnly(
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
  // LIMPAR STRING OPCIONAL
  // ==========================================================

  String? _cleanNullableText(
    String? value,
  ) {
    final cleaned = value?.trim();

    if (cleaned ==
            null ||
        cleaned.isEmpty) {
      return null;
    }

    return cleaned;
  }
}
