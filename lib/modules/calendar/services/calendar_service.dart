import 'package:flutter/foundation.dart';

import '../data/repositories/calendar_repository.dart';
import '../models/calendar_day_note.dart';
import '../models/calendar_event.dart';
import '../models/calendar_event_member.dart';
import '../models/calendar_event_type.dart';

// ============================================================
// CALENDAR SERVICE
// ============================================================
//
// Camada responsável pelas regras do calendário.
//
// Responsável por:
//
// - criar tarefas pessoais;
// - criar compromissos colaborativos;
// - carregar eventos;
// - carregar anotações por dia;
// - carregar participantes;
// - carregar convites;
// - aceitar convites;
// - recusar convites;
// - editar compromissos;
// - excluir compromissos;
// - sair de compromissos;
// - salvar/excluir anotações;
// - validar dados antes do Repository.
//
// IMPORTANTE:
//
// Esta classe NÃO acessa o Supabase diretamente.
//
// ============================================================

class CalendarService {
  // ============================================================
  // REPOSITORY
  // ============================================================

  final CalendarRepository repository;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  CalendarService({
    required this.repository,
  });

  // ============================================================
  // CRIAR TAREFA PESSOAL
  // ============================================================

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
    _validateTitle(
      title,
    );

    _validateDateRange(
      startsAt: startsAt,
      endsAt: endsAt,
    );

    debugPrint(
      '[CALENDAR SERVICE] '
      'Criando tarefa pessoal.',
    );

    return repository.createPersonalEvent(
      title: title.trim(),
      startsAt: startsAt,
      description: _normalizeOptionalText(
        description,
      ),
      endsAt: endsAt,
      locationName: _normalizeOptionalText(
        locationName,
      ),
    );
  }

  // ============================================================
  // CRIAR COMPROMISSO COLABORATIVO
  // ============================================================

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
    _validateTitle(
      title,
    );

    _validateDateRange(
      startsAt: startsAt,
      endsAt: endsAt,
    );

    if (type ==
        CalendarEventType.personal) {
      throw ArgumentError(
        'Um compromisso colaborativo não pode usar o tipo personal.',
      );
    }

    final participants = participantIds
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

    if (participants.isEmpty) {
      throw ArgumentError(
        'Selecione pelo menos um participante.',
      );
    }

    debugPrint(
      '[CALENDAR SERVICE] '
      'Criando compromisso colaborativo.',
    );

    debugPrint(
      '[CALENDAR SERVICE] '
      'Participantes: ${participants.length}',
    );

    return repository.createCollaborativeEvent(
      title: title.trim(),
      startsAt: startsAt,
      type: type,
      participantIds: participants,
      projectId: _normalizeOptionalText(
        projectId,
      ),
      description: _normalizeOptionalText(
        description,
      ),
      endsAt: endsAt,
      locationName: _normalizeOptionalText(
        locationName,
      ),
    );
  }

  // ============================================================
  // CARREGAR TODOS OS EVENTOS DO USUÁRIO
  // ============================================================

  Future<
    List<
      CalendarEvent
    >
  >
  getMyEvents() async {
    final events = await repository.getMyEvents();

    events.sort(
      (
        a,
        b,
      ) => a.startsAt.compareTo(
        b.startsAt,
      ),
    );

    return events;
  }

  // ============================================================
  // EVENTOS DE UM DIA
  // ============================================================

  Future<
    List<
      CalendarEvent
    >
  >
  getEventsForDay(
    DateTime day,
  ) async {
    final start = DateTime(
      day.year,
      day.month,
      day.day,
    );

    final end = DateTime(
      day.year,
      day.month,
      day.day,
      23,
      59,
      59,
      999,
    );

    final events = await repository.getEventsBetween(
      start: start,
      end: end,
    );

    events.sort(
      (
        a,
        b,
      ) => a.startsAt.compareTo(
        b.startsAt,
      ),
    );

    return events;
  }

  // ============================================================
  // EVENTOS DE UM MÊS
  // ============================================================

  Future<
    List<
      CalendarEvent
    >
  >
  getEventsForMonth(
    DateTime month,
  ) async {
    final start = DateTime(
      month.year,
      month.month,
      1,
    );

    final end = DateTime(
      month.year,
      month.month +
          1,
      0,
      23,
      59,
      59,
      999,
    );

    final events = await repository.getEventsBetween(
      start: start,
      end: end,
    );

    events.sort(
      (
        a,
        b,
      ) => a.startsAt.compareTo(
        b.startsAt,
      ),
    );

    return events;
  }

  // ============================================================
  // ANOTAÇÃO DO DIA
  // ============================================================

  Future<
    CalendarDayNote?
  >
  getDayNote(
    DateTime date,
  ) async {
    return repository.getDayNote(
      _normalizeDate(
        date,
      ),
    );
  }

  // ============================================================
  // ANOTAÇÕES DO MÊS
  // ============================================================

  Future<
    List<
      CalendarDayNote
    >
  >
  getNotesForMonth(
    DateTime month,
  ) async {
    final notes = await repository.getNotesForMonth(
      DateTime(
        month.year,
        month.month,
        1,
      ),
    );

    notes.sort(
      (
        a,
        b,
      ) => a.noteDate.compareTo(
        b.noteDate,
      ),
    );

    return notes;
  }

  // ============================================================
  // SALVAR ANOTAÇÃO
  // ============================================================

  Future<
    CalendarDayNote
  >
  saveDayNote({
    required DateTime date,
    required String content,
  }) async {
    final normalizedContent = content.trim();

    if (normalizedContent.isEmpty) {
      throw ArgumentError(
        'A anotação não pode ficar vazia.',
      );
    }

    debugPrint(
      '[CALENDAR SERVICE] '
      'Salvando anotação do dia '
      '${date.year}-${date.month}-${date.day}.',
    );

    return repository.saveDayNote(
      date: _normalizeDate(
        date,
      ),
      content: normalizedContent,
    );
  }

  // ============================================================
  // EXCLUIR ANOTAÇÃO
  // ============================================================

  Future<
    void
  >
  deleteDayNote(
    DateTime date,
  ) async {
    debugPrint(
      '[CALENDAR SERVICE] '
      'Excluindo anotação do dia '
      '${date.year}-${date.month}-${date.day}.',
    );

    await repository.deleteDayNote(
      _normalizeDate(
        date,
      ),
    );
  }

  // ============================================================
  // EXCLUIR ANOTAÇÃO POR ID
  // ============================================================

  Future<
    void
  >
  deleteDayNoteById(
    String noteId,
  ) async {
    final normalized = noteId.trim();

    if (normalized.isEmpty) {
      throw ArgumentError(
        'ID da anotação inválido.',
      );
    }

    await repository.deleteDayNoteById(
      normalized,
    );
  }

  // ============================================================
  // POSSUI ANOTAÇÃO?
  // ============================================================

  Future<
    bool
  >
  hasDayNote(
    DateTime date,
  ) async {
    return repository.hasDayNote(
      _normalizeDate(
        date,
      ),
    );
  }

  // ============================================================
  // PARTICIPANTES DO EVENTO
  // ============================================================

  Future<
    List<
      CalendarEventMember
    >
  >
  getEventMembers(
    String eventId,
  ) async {
    final normalized = _validateEventId(
      eventId,
    );

    final members = await repository.getEventMembers(
      normalized,
    );

    return members;
  }

  // ============================================================
  // CONVITES PENDENTES
  // ============================================================

  Future<
    List<
      CalendarEventMember
    >
  >
  getPendingInvitations() async {
    final invitations = await repository.getPendingInvitations();

    return invitations;
  }

  // ============================================================
  // BUSCAR EVENTO
  // ============================================================

  Future<
    CalendarEvent?
  >
  getEventById(
    String eventId,
  ) async {
    final normalized = eventId.trim();

    if (normalized.isEmpty) {
      return null;
    }

    return repository.getEventById(
      normalized,
    );
  }

  // ============================================================
  // ACEITAR CONVITE
  // ============================================================

  Future<
    void
  >
  acceptInvitation(
    String eventId,
  ) async {
    final normalized = _validateEventId(
      eventId,
    );

    debugPrint(
      '[CALENDAR SERVICE] '
      'Aceitando convite: $normalized',
    );

    await repository.acceptInvitation(
      normalized,
    );
  }

  // ============================================================
  // RECUSAR CONVITE
  // ============================================================

  Future<
    void
  >
  declineInvitation(
    String eventId,
  ) async {
    final normalized = _validateEventId(
      eventId,
    );

    debugPrint(
      '[CALENDAR SERVICE] '
      'Recusando convite: $normalized',
    );

    await repository.declineInvitation(
      normalized,
    );
  }

  // ============================================================
  // ATUALIZAR EVENTO
  // ============================================================

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
    final normalizedEventId = _validateEventId(
      eventId,
    );

    _validateTitle(
      title,
    );

    _validateDateRange(
      startsAt: startsAt,
      endsAt: endsAt,
    );

    debugPrint(
      '[CALENDAR SERVICE] '
      'Atualizando evento: $normalizedEventId',
    );

    return repository.updateEvent(
      eventId: normalizedEventId,
      title: title.trim(),
      startsAt: startsAt,
      description: _normalizeOptionalText(
        description,
      ),
      endsAt: endsAt,
      locationName: _normalizeOptionalText(
        locationName,
      ),
    );
  }

  // ============================================================
  // EXCLUIR EVENTO
  // ============================================================

  Future<
    void
  >
  deleteEvent(
    String eventId,
  ) async {
    final normalized = _validateEventId(
      eventId,
    );

    debugPrint(
      '[CALENDAR SERVICE] '
      'Excluindo evento: $normalized',
    );

    await repository.deleteEvent(
      normalized,
    );
  }

  // ============================================================
  // SAIR DO EVENTO
  // ============================================================

  Future<
    void
  >
  leaveEvent(
    String eventId,
  ) async {
    final normalized = _validateEventId(
      eventId,
    );

    debugPrint(
      '[CALENDAR SERVICE] '
      'Saindo do evento: $normalized',
    );

    await repository.leaveEvent(
      normalized,
    );
  }

  // ============================================================
  // VALIDAR TÍTULO
  // ============================================================

  void _validateTitle(
    String title,
  ) {
    final normalized = title.trim();

    if (normalized.isEmpty) {
      throw ArgumentError(
        'Informe um título para o compromisso.',
      );
    }

    if (normalized.length >
        120) {
      throw ArgumentError(
        'O título deve possuir no máximo 120 caracteres.',
      );
    }
  }

  // ============================================================
  // VALIDAR HORÁRIO
  // ============================================================

  void _validateDateRange({
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
        'O horário final não pode ser anterior ao horário inicial.',
      );
    }
  }

  // ============================================================
  // VALIDAR EVENT ID
  // ============================================================

  String _validateEventId(
    String eventId,
  ) {
    final normalized = eventId.trim();

    if (normalized.isEmpty) {
      throw ArgumentError(
        'ID do compromisso inválido.',
      );
    }

    return normalized;
  }

  // ============================================================
  // NORMALIZAR DATA
  // ============================================================
  //
  // Remove horário/minutos/segundos.
  //
  // ============================================================

  DateTime _normalizeDate(
    DateTime value,
  ) {
    return DateTime(
      value.year,
      value.month,
      value.day,
    );
  }

  // ============================================================
  // NORMALIZAR TEXTO OPCIONAL
  // ============================================================

  String? _normalizeOptionalText(
    String? value,
  ) {
    final normalized = value?.trim();

    if (normalized ==
            null ||
        normalized.isEmpty) {
      return null;
    }

    return normalized;
  }
}
