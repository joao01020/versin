import 'package:flutter/foundation.dart';

import '../models/calendar_day_note.dart';
import '../models/calendar_event.dart';
import '../models/calendar_event_member.dart';
import '../models/calendar_event_type.dart';
import '../services/calendar_service.dart';

// ============================================================
// CALENDAR CONTROLLER
// ============================================================
//
// Controla o estado da interface do calendário.
//
// Responsável por:
//
// - mês em foco;
// - dia selecionado;
// - eventos;
// - anotações por dia;
// - convites;
// - loading;
// - erros;
// - criação de tarefas;
// - criação de compromissos;
// - aceitar/recusar convites;
// - edição;
// - exclusão;
// - criação, edição e exclusão de anotações.
//
// ============================================================

class CalendarController
    extends
        ChangeNotifier {
  // ============================================================
  // SERVICE
  // ============================================================

  final CalendarService service;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  CalendarController({
    required this.service,
  }) : _focusedDay =
           DateTime.now(),
       _selectedDate = DateTime(
         DateTime.now().year,
         DateTime.now().month,
         DateTime.now().day,
       );

  // ============================================================
  // CALENDAR STATE
  // ============================================================

  DateTime _focusedDay;

  DateTime _selectedDate;

  bool _isCalendarExpanded = true;

  // ============================================================
  // LOADING
  // ============================================================

  bool _isLoading = false;

  bool _isSubmitting = false;

  // ============================================================
  // ERROR
  // ============================================================

  String? _errorMessage;

  // ============================================================
  // DATA
  // ============================================================

  List<
    CalendarEvent
  >
  _events = const [];

  List<
    CalendarEventMember
  >
  _pendingInvitations = const [];

  List<
    CalendarEventMember
  >
  _eventMembers = const [];

  String? _loadedMembersEventId;

  // ============================================================
  // ANOTAÇÕES
  // ============================================================

  List<
    CalendarDayNote
  >
  _dayNotes = const [];

  CalendarDayNote? _selectedDayNote;

  // ============================================================
  // GETTERS
  // ============================================================

  DateTime get focusedDay => _focusedDay;

  DateTime get selectedDate => _selectedDate;

  int get selectedDay => _selectedDate.day;

  bool get isCalendarExpanded => _isCalendarExpanded;

  bool get isLoading => _isLoading;

  bool get isSubmitting => _isSubmitting;

  String? get errorMessage => _errorMessage;

  bool get hasError =>
      _errorMessage !=
      null;

  List<
    CalendarEvent
  >
  get events => List.unmodifiable(
    _events,
  );

  List<
    CalendarEventMember
  >
  get pendingInvitations => List.unmodifiable(
    _pendingInvitations,
  );

  int get pendingInvitationCount => _pendingInvitations.length;

  List<
    CalendarEventMember
  >
  get eventMembers => List.unmodifiable(
    _eventMembers,
  );

  String? get loadedMembersEventId => _loadedMembersEventId;

  List<
    CalendarDayNote
  >
  get dayNotes => List.unmodifiable(
    _dayNotes,
  );

  CalendarDayNote? get selectedDayNote => _selectedDayNote;

  bool get hasSelectedDayNote {
    return _selectedDayNote !=
        null;
  }

  // ============================================================
  // ANOTAÇÃO DO DIA
  // ============================================================

  CalendarDayNote? noteForDay(
    DateTime date,
  ) {
    for (final note in _dayNotes) {
      if (_isSameDay(
        note.noteDate,
        date,
      )) {
        return note;
      }
    }

    return null;
  }

  // ============================================================
  // POSSUI ANOTAÇÃO NA DATA
  // ============================================================

  bool hasNoteForDate(
    DateTime date,
  ) {
    return noteForDay(
          date,
        ) !=
        null;
  }

  // ============================================================
  // POSSUI ANOTAÇÃO NO DIA DO MÊS ATUAL
  // ============================================================

  bool hasNoteOnDay(
    int day,
  ) {
    final maxDay = DateTime(
      _focusedDay.year,
      _focusedDay.month +
          1,
      0,
    ).day;

    if (day <
            1 ||
        day >
            maxDay) {
      return false;
    }

    return hasNoteForDate(
      DateTime(
        _focusedDay.year,
        _focusedDay.month,
        day,
      ),
    );
  }

  // ============================================================
  // EVENTOS DO DIA SELECIONADO
  // ============================================================

  List<
    CalendarEvent
  >
  get selectedDayEvents {
    final result = _events.where(
      (
        event,
      ) {
        return _isSameDay(
          event.startsAt.toLocal(),
          _selectedDate,
        );
      },
    ).toList();

    result.sort(
      (
        a,
        b,
      ) => a.startsAt.compareTo(
        b.startsAt,
      ),
    );

    return result;
  }

  // ============================================================
  // INICIALIZAR
  // ============================================================

  Future<
    void
  >
  initialize() async {
    await refresh();
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<
    void
  >
  refresh() async {
    if (_isLoading) {
      return;
    }

    _setLoading(
      true,
    );

    _clearError();

    try {
      final results = await Future.wait(
        [
          service.getEventsForMonth(
            _focusedDay,
          ),

          service.getPendingInvitations(),

          service.getNotesForMonth(
            _focusedDay,
          ),
        ],
      );

      _events =
          results[0]
              as List<
                CalendarEvent
              >;

      _pendingInvitations =
          results[1]
              as List<
                CalendarEventMember
              >;

      _dayNotes =
          results[2]
              as List<
                CalendarDayNote
              >;

      _selectedDayNote = noteForDay(
        _selectedDate,
      );

      notifyListeners();
    } catch (
      error,
      stackTrace
    ) {
      _setError(
        'Não foi possível carregar o calendário.',
      );

      debugPrint(
        '[CALENDAR CONTROLLER] '
        'Erro ao carregar calendário: $error',
      );

      debugPrint(
        '[CALENDAR CONTROLLER] '
        'Stack trace: $stackTrace',
      );
    } finally {
      _setLoading(
        false,
      );
    }
  }

  // ============================================================
  // ATUALIZAR SOMENTE CONVITES
  // ============================================================

  Future<
    void
  >
  refreshInvitations() async {
    try {
      _pendingInvitations = await service.getPendingInvitations();

      notifyListeners();
    } catch (
      error,
      stackTrace
    ) {
      _setError(
        'Não foi possível carregar os convites.',
      );

      debugPrint(
        '[CALENDAR CONTROLLER] '
        'Erro ao carregar convites: $error',
      );

      debugPrint(
        '[CALENDAR CONTROLLER] '
        'Stack trace: $stackTrace',
      );
    }
  }

  // ============================================================
  // SELECIONAR DIA
  // ============================================================

  void selectDay(
    int day,
  ) {
    final maxDay = DateTime(
      _focusedDay.year,
      _focusedDay.month +
          1,
      0,
    ).day;

    if (day <
            1 ||
        day >
            maxDay) {
      return;
    }

    _selectedDate = DateTime(
      _focusedDay.year,
      _focusedDay.month,
      day,
    );

    _selectedDayNote = noteForDay(
      _selectedDate,
    );

    notifyListeners();
  }

  // ============================================================
  // ALTERAR MÊS
  // ============================================================

  Future<
    void
  >
  updateFocusedMonth(
    int month,
  ) async {
    if (month <
            1 ||
        month >
            12) {
      return;
    }

    _focusedDay = DateTime(
      _focusedDay.year,
      month,
      1,
    );

    _selectedDate = DateTime(
      _focusedDay.year,
      month,
      1,
    );

    _selectedDayNote = null;

    notifyListeners();

    await _reloadCurrentMonth();
  }

  // ============================================================
  // ALTERAR ANO
  // ============================================================

  Future<
    void
  >
  updateFocusedYear(
    int year,
  ) async {
    _focusedDay = DateTime(
      year,
      _focusedDay.month,
      1,
    );

    _selectedDate = DateTime(
      year,
      _focusedDay.month,
      1,
    );

    _selectedDayNote = null;

    notifyListeners();

    await _reloadCurrentMonth();
  }

  // ============================================================
  // NAVEGAR ENTRE MESES
  // ============================================================

  Future<
    void
  >
  navigateMonth({
    required bool forward,
  }) async {
    final offset = forward
        ? 1
        : -1;

    _focusedDay = DateTime(
      _focusedDay.year,
      _focusedDay.month +
          offset,
      1,
    );

    _selectedDate = DateTime(
      _focusedDay.year,
      _focusedDay.month,
      1,
    );

    _selectedDayNote = null;

    notifyListeners();

    await _reloadCurrentMonth();
  }

  // ============================================================
  // EXPANDIR / RECOLHER
  // ============================================================

  void toggleCalendarExpanded() {
    _isCalendarExpanded = !_isCalendarExpanded;

    notifyListeners();
  }

  // ============================================================
  // EXISTE EVENTO NESTE DIA?
  // ============================================================

  bool hasEventOnDay(
    int day,
  ) {
    return _events.any(
      (
        event,
      ) {
        final local = event.startsAt.toLocal();

        return local.year ==
                _focusedDay.year &&
            local.month ==
                _focusedDay.month &&
            local.day ==
                day;
      },
    );
  }

  // ============================================================
  // EVENTOS DE UM DIA
  // ============================================================

  List<
    CalendarEvent
  >
  eventsForDay(
    int day,
  ) {
    final result = _events.where(
      (
        event,
      ) {
        final local = event.startsAt.toLocal();

        return local.year ==
                _focusedDay.year &&
            local.month ==
                _focusedDay.month &&
            local.day ==
                day;
      },
    ).toList();

    result.sort(
      (
        a,
        b,
      ) => a.startsAt.compareTo(
        b.startsAt,
      ),
    );

    return result;
  }

  // ============================================================
  // CARREGAR ANOTAÇÃO DO DIA
  // ============================================================

  Future<
    CalendarDayNote?
  >
  loadDayNote(
    DateTime date,
  ) async {
    _clearError();

    try {
      final note = await service.getDayNote(
        date,
      );

      _selectedDayNote = note;

      _replaceCachedDayNote(
        date: date,
        note: note,
      );

      notifyListeners();

      return note;
    } catch (
      error,
      stackTrace
    ) {
      _setError(
        'Não foi possível carregar a anotação.',
      );

      debugPrint(
        '[CALENDAR CONTROLLER] '
        'Erro ao carregar anotação: $error',
      );

      debugPrint(
        '[CALENDAR CONTROLLER] '
        'Stack trace: $stackTrace',
      );

      return null;
    }
  }

  // ============================================================
  // RECARREGAR ANOTAÇÕES DO MÊS
  // ============================================================

  Future<
    void
  >
  refreshDayNotes() async {
    _clearError();

    try {
      _dayNotes = await service.getNotesForMonth(
        _focusedDay,
      );

      _selectedDayNote = noteForDay(
        _selectedDate,
      );

      notifyListeners();
    } catch (
      error,
      stackTrace
    ) {
      _setError(
        'Não foi possível carregar as anotações.',
      );

      debugPrint(
        '[CALENDAR CONTROLLER] '
        'Erro ao carregar anotações: $error',
      );

      debugPrint(
        '[CALENDAR CONTROLLER] '
        'Stack trace: $stackTrace',
      );
    }
  }

  // ============================================================
  // SALVAR ANOTAÇÃO
  // ============================================================

  Future<
    bool
  >
  saveDayNote({
    required DateTime date,
    required String content,
  }) async {
    if (_isSubmitting) {
      return false;
    }

    final normalizedContent = content.trim();

    if (normalizedContent.isEmpty) {
      _setError(
        'A anotação não pode ficar vazia.',
      );

      return false;
    }

    _isSubmitting = true;

    _clearError();

    notifyListeners();

    try {
      final note = await service.saveDayNote(
        date: date,

        content: normalizedContent,
      );

      _replaceCachedDayNote(
        date: date,
        note: note,
      );

      if (_isSameDay(
        _selectedDate,
        date,
      )) {
        _selectedDayNote = note;
      }

      debugPrint(
        '[CALENDAR CONTROLLER] '
        'Anotação salva: ${note.id}',
      );

      return true;
    } catch (
      error,
      stackTrace
    ) {
      _setError(
        _resolveErrorMessage(
          error,
        ),
      );

      debugPrint(
        '[CALENDAR CONTROLLER] '
        'Erro ao salvar anotação: $error',
      );

      debugPrint(
        '[CALENDAR CONTROLLER] '
        'Stack trace: $stackTrace',
      );

      return false;
    } finally {
      _isSubmitting = false;

      notifyListeners();
    }
  }

  // ============================================================
  // EXCLUIR ANOTAÇÃO
  // ============================================================

  Future<
    bool
  >
  deleteDayNote(
    DateTime date,
  ) async {
    if (_isSubmitting) {
      return false;
    }

    _isSubmitting = true;

    _clearError();

    notifyListeners();

    try {
      await service.deleteDayNote(
        date,
      );

      _replaceCachedDayNote(
        date: date,
        note: null,
      );

      if (_isSameDay(
        _selectedDate,
        date,
      )) {
        _selectedDayNote = null;
      }

      debugPrint(
        '[CALENDAR CONTROLLER] '
        'Anotação excluída.',
      );

      return true;
    } catch (
      error,
      stackTrace
    ) {
      _setError(
        _resolveErrorMessage(
          error,
        ),
      );

      debugPrint(
        '[CALENDAR CONTROLLER] '
        'Erro ao excluir anotação: $error',
      );

      debugPrint(
        '[CALENDAR CONTROLLER] '
        'Stack trace: $stackTrace',
      );

      return false;
    } finally {
      _isSubmitting = false;

      notifyListeners();
    }
  }

  // ============================================================
  // ATUALIZAR CACHE DE ANOTAÇÕES
  // ============================================================

  void _replaceCachedDayNote({
    required DateTime date,
    required CalendarDayNote? note,
  }) {
    final updated = _dayNotes.where(
      (
        current,
      ) {
        return !_isSameDay(
          current.noteDate,
          date,
        );
      },
    ).toList();

    if (note !=
        null) {
      updated.add(
        note,
      );

      updated.sort(
        (
          a,
          b,
        ) {
          return a.noteDate.compareTo(
            b.noteDate,
          );
        },
      );
    }

    _dayNotes = updated;
  }

  // ============================================================
  // CRIAR TAREFA PESSOAL
  // ============================================================

  Future<
    bool
  >
  createPersonalEvent({
    required String title,
    required DateTime startsAt,
    String? description,
    DateTime? endsAt,
    String? locationName,
  }) async {
    return _executeAction(
      action: () async {
        await service.createPersonalEvent(
          title: title,
          startsAt: startsAt,
          description: description,
          endsAt: endsAt,
          locationName: locationName,
        );
      },
    );
  }

  // ============================================================
  // CRIAR COMPROMISSO COLABORATIVO
  // ============================================================

  Future<
    bool
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
    return _executeAction(
      action: () async {
        await service.createCollaborativeEvent(
          title: title,
          startsAt: startsAt,
          type: type,
          participantIds: participantIds,
          projectId: projectId,
          description: description,
          endsAt: endsAt,
          locationName: locationName,
        );
      },
    );
  }

  // ============================================================
  // CARREGAR PARTICIPANTES DO EVENTO
  // ============================================================

  Future<
    void
  >
  loadEventMembers(
    String eventId,
  ) async {
    final normalized = eventId.trim();

    if (normalized.isEmpty) {
      _eventMembers = const [];

      _loadedMembersEventId = null;

      notifyListeners();

      return;
    }

    try {
      _eventMembers = await service.getEventMembers(
        normalized,
      );

      _loadedMembersEventId = normalized;

      notifyListeners();

      debugPrint(
        '[CALENDAR CONTROLLER] '
        '${_eventMembers.length} participante(s) carregado(s) '
        'para o evento $normalized.',
      );
    } catch (
      error,
      stackTrace
    ) {
      _setError(
        'Não foi possível carregar os participantes.',
      );

      debugPrint(
        '[CALENDAR CONTROLLER] '
        'Erro ao carregar participantes: $error',
      );

      debugPrint(
        '[CALENDAR CONTROLLER] '
        'Stack trace: $stackTrace',
      );
    }
  }

  // ============================================================
  // LIMPAR PARTICIPANTES CARREGADOS
  // ============================================================

  void clearEventMembers() {
    if (_eventMembers.isEmpty &&
        _loadedMembersEventId ==
            null) {
      return;
    }

    _eventMembers = const [];

    _loadedMembersEventId = null;

    notifyListeners();
  }

  // ============================================================
  // ACEITAR CONVITE
  // ============================================================

  Future<
    bool
  >
  acceptInvitation(
    String eventId,
  ) async {
    return _executeAction(
      action: () async {
        await service.acceptInvitation(
          eventId,
        );
      },
    );
  }

  // ============================================================
  // RECUSAR CONVITE
  // ============================================================

  Future<
    bool
  >
  declineInvitation(
    String eventId,
  ) async {
    return _executeAction(
      action: () async {
        await service.declineInvitation(
          eventId,
        );
      },
    );
  }

  // ============================================================
  // ATUALIZAR EVENTO
  // ============================================================

  Future<
    bool
  >
  updateEvent({
    required String eventId,
    required String title,
    required DateTime startsAt,
    String? description,
    DateTime? endsAt,
    String? locationName,
  }) async {
    return _executeAction(
      action: () async {
        await service.updateEvent(
          eventId: eventId,
          title: title,
          startsAt: startsAt,
          description: description,
          endsAt: endsAt,
          locationName: locationName,
        );
      },
    );
  }

  // ============================================================
  // EXCLUIR EVENTO
  // ============================================================

  Future<
    bool
  >
  deleteEvent(
    String eventId,
  ) async {
    return _executeAction(
      action: () async {
        await service.deleteEvent(
          eventId,
        );
      },
    );
  }

  // ============================================================
  // SAIR DO EVENTO
  // ============================================================

  Future<
    bool
  >
  leaveEvent(
    String eventId,
  ) async {
    return _executeAction(
      action: () async {
        await service.leaveEvent(
          eventId,
        );
      },
    );
  }

  // ============================================================
  // EXECUTAR OPERAÇÃO
  // ============================================================

  Future<
    bool
  >
  _executeAction({
    required Future<
      void
    >
    Function()
    action,
  }) async {
    if (_isSubmitting) {
      return false;
    }

    _isSubmitting = true;

    _clearError();

    notifyListeners();

    try {
      await action();

      await refresh();

      return true;
    } catch (
      error,
      stackTrace
    ) {
      _setError(
        _resolveErrorMessage(
          error,
        ),
      );

      debugPrint(
        '[CALENDAR CONTROLLER] '
        'Erro na operação: $error',
      );

      debugPrint(
        '[CALENDAR CONTROLLER] '
        'Stack trace: $stackTrace',
      );

      return false;
    } finally {
      _isSubmitting = false;

      notifyListeners();
    }
  }

  // ============================================================
  // RECARREGAR MÊS
  // ============================================================

  Future<
    void
  >
  _reloadCurrentMonth() async {
    _setLoading(
      true,
    );

    _clearError();

    try {
      final results = await Future.wait(
        [
          service.getEventsForMonth(
            _focusedDay,
          ),

          service.getNotesForMonth(
            _focusedDay,
          ),
        ],
      );

      _events =
          results[0]
              as List<
                CalendarEvent
              >;

      _dayNotes =
          results[1]
              as List<
                CalendarDayNote
              >;

      _selectedDayNote = noteForDay(
        _selectedDate,
      );

      notifyListeners();
    } catch (
      error,
      stackTrace
    ) {
      _setError(
        'Não foi possível carregar os compromissos.',
      );

      debugPrint(
        '[CALENDAR CONTROLLER] '
        'Erro ao carregar mês: $error',
      );

      debugPrint(
        '[CALENDAR CONTROLLER] '
        'Stack trace: $stackTrace',
      );
    } finally {
      _setLoading(
        false,
      );
    }
  }

  // ============================================================
  // RESOLVER MENSAGEM DE ERRO
  // ============================================================

  String _resolveErrorMessage(
    Object error,
  ) {
    if (error
        is ArgumentError) {
      return error.toString().replaceFirst(
        'Invalid argument(s): ',
        '',
      );
    }

    if (error
        is StateError) {
      return error.toString().replaceFirst(
        'Bad state: ',
        '',
      );
    }

    return 'Não foi possível concluir a operação.';
  }

  // ============================================================
  // LOADING
  // ============================================================

  void _setLoading(
    bool value,
  ) {
    if (_isLoading ==
        value) {
      return;
    }

    _isLoading = value;

    notifyListeners();
  }

  // ============================================================
  // ERROR
  // ============================================================

  void _setError(
    String message,
  ) {
    _errorMessage = message;

    notifyListeners();
  }

  // ============================================================
  // CLEAR ERROR
  // ============================================================

  void clearError() {
    _clearError();
  }

  void _clearError() {
    if (_errorMessage ==
        null) {
      return;
    }

    _errorMessage = null;

    notifyListeners();
  }

  // ============================================================
  // SAME DAY
  // ============================================================

  bool _isSameDay(
    DateTime a,
    DateTime b,
  ) {
    return a.year ==
            b.year &&
        a.month ==
            b.month &&
        a.day ==
            b.day;
  }
}
