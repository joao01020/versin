import 'package:flutter/material.dart';

import '../controllers/calendar_controller.dart';
import '../data/repositories/calendar_repository.dart';
import '../models/calendar_day_note.dart';
import '../services/calendar_service.dart';
import '../widgets/calendar_card_widget.dart';
import '../widgets/calendar_note_dialog.dart';
import '../widgets/create_event_dialog.dart';

// ============================================================
// CALENDAR PAGE
// ============================================================
//
// Página principal do calendário.
//
// Responsável por:
//
// - inicializar CalendarController;
// - carregar eventos reais;
// - abrir criação de tarefa;
// - criar tarefa pessoal;
// - criar compromisso colaborativo;
// - abrir anotações por dia;
// - salvar/excluir anotações;
// - atualizar a interface;
// - permitir voltar para a tela anterior.
//
// ============================================================

class CalendarPage
    extends
        StatefulWidget {
  const CalendarPage({
    super.key,
  });

  @override
  State<
    CalendarPage
  >
  createState() => _CalendarPageState();
}

// ============================================================
// STATE
// ============================================================

class _CalendarPageState
    extends
        State<
          CalendarPage
        > {
  // ============================================================
  // CALENDAR
  // ============================================================

  late final CalendarRepository _calendarRepository;

  late final CalendarService _calendarService;

  late final CalendarController _calendarController;

  // ============================================================
  // VISUAL
  // ============================================================

  static const Color _backgroundColor = Color(
    0xFF0D0B1F,
  );

  static const Color _accentColor = Color(
    0xFFB46CFF,
  );

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _setupDependencies();

    _calendarController.addListener(
      _handleCalendarChanged,
    );

    _initializeCalendar();
  }

  // ============================================================
  // DEPENDENCIES
  // ============================================================

  void _setupDependencies() {
    _calendarRepository = CalendarRepository();

    _calendarService = CalendarService(
      repository: _calendarRepository,
    );

    _calendarController = CalendarController(
      service: _calendarService,
    );
  }

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<
    void
  >
  _initializeCalendar() async {
    await _calendarController.initialize();

    if (!mounted) {
      return;
    }

    if (_calendarController.hasError) {
      _showError(
        _calendarController.errorMessage ??
            'Não foi possível carregar o calendário.',
      );
    }
  }

  // ============================================================
  // CONTROLLER CHANGE
  // ============================================================

  void _handleCalendarChanged() {
    if (!mounted) {
      return;
    }

    setState(
      () {},
    );
  }

  // ============================================================
  // VOLTAR
  // ============================================================

  void _goBack() {
    if (!mounted) {
      return;
    }

    Navigator.of(
      context,
    ).maybePop();
  }

  // ============================================================
  // ADICIONAR ATIVIDADE
  // ============================================================

  Future<
    void
  >
  _openCreateEventDialog() async {
    final result = await CreateEventDialog.show(
      context: context,

      initialDate: _calendarController.selectedDate,

      accentColor: _accentColor,

      // ========================================================
      // PARTICIPANTES
      // ========================================================
      //
      // Por enquanto vazio.
      //
      // Depois vamos preencher com os usuários do projeto /
      // Networking conectado.
      //
      // Formato esperado:
      //
      // {
      //   'uuid-user-1': 'João',
      //   'uuid-user-2': 'Lucas',
      // }
      //
      // ========================================================
      availableParticipants: const {},
    );

    if (!mounted ||
        result ==
            null) {
      return;
    }

    // ==========================================================
    // PESSOAL
    // ==========================================================

    if (result.isPersonal) {
      final success = await _calendarController.createPersonalEvent(
        title: result.title,

        startsAt: result.startsAt,

        description: result.description,

        endsAt: result.endsAt,

        locationName: result.locationName,
      );

      if (!mounted) {
        return;
      }

      if (!success) {
        _showError(
          _calendarController.errorMessage ??
              'Não foi possível criar a atividade.',
        );

        return;
      }

      _showSuccess(
        'Atividade adicionada ao calendário.',
      );

      return;
    }

    // ==========================================================
    // COLABORATIVO
    // ==========================================================

    final success = await _calendarController.createCollaborativeEvent(
      title: result.title,

      startsAt: result.startsAt,

      type: result.type,

      participantIds: result.participantIds,

      projectId: result.projectId,

      description: result.description,

      endsAt: result.endsAt,

      locationName: result.locationName,
    );

    if (!mounted) {
      return;
    }

    if (!success) {
      _showError(
        _calendarController.errorMessage ??
            'Não foi possível criar o compromisso.',
      );

      return;
    }

    _showSuccess(
      'Compromisso criado e convites enviados.',
    );
  }

  // ============================================================
  // ABRIR ANOTAÇÃO DO DIA
  // ============================================================
  //
  // Desktop:
  //
  // - botão direito no dia.
  //
  // Mobile:
  //
  // - pressionar e segurar.
  //
  // ============================================================

  Future<
    void
  >
  _openDayNote(
    DateTime date,
  ) async {
    if (_calendarController.isSubmitting) {
      return;
    }

    // ==========================================================
    // CARREGAR NOTA
    // ==========================================================
    //
    // Primeiro tentamos utilizar o cache do mês.
    //
    // Se não existir no cache, consultamos o banco para garantir
    // que estamos abrindo a versão mais recente.
    //
    // ==========================================================

    CalendarDayNote? note = _calendarController.noteForDay(
      date,
    );

    if (note ==
        null) {
      note = await _calendarController.loadDayNote(
        date,
      );
    }

    if (!mounted) {
      return;
    }

    // ==========================================================
    // ABRIR EDITOR
    // ==========================================================

    final result = await CalendarNoteDialog.show(
      context: context,

      date: date,

      note: note,

      accentColor: _accentColor,
    );

    if (!mounted ||
        result ==
            null) {
      return;
    }

    // ==========================================================
    // EXCLUIR
    // ==========================================================

    if (result.shouldDelete) {
      final success = await _calendarController.deleteDayNote(
        date,
      );

      if (!mounted) {
        return;
      }

      if (!success) {
        _showError(
          _calendarController.errorMessage ??
              'Não foi possível excluir a anotação.',
        );

        return;
      }

      _showSuccess(
        'Anotação excluída.',
      );

      return;
    }

    // ==========================================================
    // SALVAR
    // ==========================================================

    if (result.shouldSave) {
      final success = await _calendarController.saveDayNote(
        date: date,

        content: result.content,
      );

      if (!mounted) {
        return;
      }

      if (!success) {
        _showError(
          _calendarController.errorMessage ??
              'Não foi possível salvar a anotação.',
        );

        return;
      }

      _showSuccess(
        'Anotação salva.',
      );
    }
  }

  // ============================================================
  // EDITAR EVENTO
  // ============================================================
  //
  // A estrutura já fica pronta.
  //
  // Depois podemos abrir o mesmo CreateEventDialog em modo
  // edição.
  //
  // ============================================================

  void _editEvent(
    String eventId,
  ) {
    debugPrint(
      '[CALENDAR PAGE] '
      'Editar evento: $eventId',
    );

    _showInfo(
      'A edição do compromisso será adicionada em seguida.',
    );
  }

  // ============================================================
  // EXCLUIR EVENTO
  // ============================================================

  Future<
    void
  >
  _deleteEvent(
    String eventId,
  ) async {
    final confirmed =
        await showDialog<
          bool
        >(
          context: context,

          builder:
              (
                dialogContext,
              ) {
                return AlertDialog(
                  backgroundColor: const Color(
                    0xFF17132D,
                  ),

                  surfaceTintColor: Colors.transparent,

                  title: const Text(
                    'Excluir compromisso',

                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),

                  content: const Text(
                    'Deseja realmente excluir este compromisso?',

                    style: TextStyle(
                      color: Colors.white60,
                    ),
                  ),

                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(
                          dialogContext,
                        ).pop(
                          false,
                        );
                      },

                      child: const Text(
                        'CANCELAR',
                      ),
                    ),

                    FilledButton(
                      onPressed: () {
                        Navigator.of(
                          dialogContext,
                        ).pop(
                          true,
                        );
                      },

                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.redAccent,

                        foregroundColor: Colors.white,
                      ),

                      child: const Text(
                        'EXCLUIR',
                      ),
                    ),
                  ],
                );
              },
        );

    if (!mounted ||
        confirmed !=
            true) {
      return;
    }

    final success = await _calendarController.deleteEvent(
      eventId,
    );

    if (!mounted) {
      return;
    }

    if (!success) {
      _showError(
        _calendarController.errorMessage ??
            'Não foi possível excluir o compromisso.',
      );

      return;
    }

    _showSuccess(
      'Compromisso excluído.',
    );
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<
    void
  >
  _refreshCalendar() async {
    await _calendarController.refresh();
  }

  // ============================================================
  // SUCCESS
  // ============================================================

  void _showSuccess(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
        context,
      )
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
          ),

          backgroundColor: const Color(
            0xFF2E7D32,
          ),
        ),
      );
  }

  // ============================================================
  // ERROR
  // ============================================================

  void _showError(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
        context,
      )
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
          ),

          backgroundColor: Colors.redAccent,
        ),
      );
  }

  // ============================================================
  // INFO
  // ============================================================

  void _showInfo(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
        context,
      )
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
          ),
        ),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: _backgroundColor,

      body: Container(
        width: double.infinity,

        height: double.infinity,

        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,

            end: Alignment.bottomRight,

            colors: [
              Color(
                0xFF1F1A3A,
              ),

              Color(
                0xFF0D0B1F,
              ),
            ],
          ),
        ),

        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refreshCalendar,

            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),

              padding: const EdgeInsets.symmetric(
                horizontal: 20,

                vertical: 20,
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  // ==============================================
                  // HEADER
                  // ==============================================
                  _buildHeader(),

                  const SizedBox(
                    height: 24,
                  ),

                  // ==============================================
                  // LOADING INICIAL
                  // ==============================================
                  if (_calendarController.isLoading &&
                      _calendarController.events.isEmpty)
                    _buildInitialLoading()
                  else
                    CalendarCardWidget(
                      controller: _calendarController,

                      accentColor: _accentColor,

                      onAddAppointmentTap: _openCreateEventDialog,

                      onEditEvent: _editEvent,

                      onDeleteEvent:
                          (
                            eventId,
                          ) {
                            _deleteEvent(
                              eventId,
                            );
                          },

                      // ============================================
                      // ANOTAÇÕES
                      // ============================================
                      onDayNoteRequested: _openDayNote,

                      hasNoteForDay:
                          (
                            date,
                          ) {
                            return _calendarController.hasNoteForDate(
                              date,
                            );
                          },
                    ),

                  // ==============================================
                  // CONVITES
                  // ==============================================
                  if (_calendarController.pendingInvitations.isNotEmpty) ...[
                    const SizedBox(
                      height: 24,
                    ),

                    _buildPendingInvitationsInfo(),
                  ],

                  const SizedBox(
                    height: 30,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Row(
      children: [
        // ======================================================
        // VOLTAR
        // ======================================================
        Material(
          color: Colors.transparent,

          child: InkWell(
            onTap: _goBack,

            borderRadius: BorderRadius.circular(
              12,
            ),

            child: Container(
              width: 42,

              height: 42,

              decoration: BoxDecoration(
                color: Colors.white.withValues(
                  alpha: 0.06,
                ),

                borderRadius: BorderRadius.circular(
                  12,
                ),

                border: Border.all(
                  color: Colors.white.withValues(
                    alpha: 0.08,
                  ),
                ),
              ),

              child: const Icon(
                Icons.arrow_back_rounded,

                color: Colors.white,

                size: 21,
              ),
            ),
          ),
        ),

        const SizedBox(
          width: 14,
        ),

        // ======================================================
        // TÍTULO
        // ======================================================
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                'AGENDA COMPLETA',

                style: TextStyle(
                  color: Colors.white,

                  fontSize: 18,

                  fontWeight: FontWeight.bold,

                  letterSpacing: 1.2,
                ),
              ),

              SizedBox(
                height: 2,
              ),

              Text(
                'Organize tarefas e compromissos',

                style: TextStyle(
                  color: Colors.white38,

                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),

        // ======================================================
        // REFRESH
        // ======================================================
        IconButton(
          tooltip: 'Atualizar',

          onPressed: _calendarController.isLoading
              ? null
              : () {
                  _refreshCalendar();
                },

          icon: Icon(
            Icons.refresh_rounded,

            color: _calendarController.isLoading
                ? Colors.white24
                : Colors.white54,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildInitialLoading() {
    return Container(
      width: double.infinity,

      height: 220,

      alignment: Alignment.center,

      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.04,
        ),

        borderRadius: BorderRadius.circular(
          16,
        ),

        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.05,
          ),
        ),
      ),

      child: const Column(
        mainAxisSize: MainAxisSize.min,

        children: [
          CircularProgressIndicator(),

          SizedBox(
            height: 14,
          ),

          Text(
            'Carregando calendário...',

            style: TextStyle(
              color: Colors.white38,

              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CONVITES PENDENTES
  // ============================================================

  Widget _buildPendingInvitationsInfo() {
    final count = _calendarController.pendingInvitationCount;

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(
        14,
      ),

      decoration: BoxDecoration(
        color: _accentColor.withValues(
          alpha: 0.08,
        ),

        borderRadius: BorderRadius.circular(
          14,
        ),

        border: Border.all(
          color: _accentColor.withValues(
            alpha: 0.20,
          ),
        ),
      ),

      child: Row(
        children: [
          Icon(
            Icons.mark_email_unread_outlined,

            color: _accentColor,

            size: 20,
          ),

          const SizedBox(
            width: 10,
          ),

          Expanded(
            child: Text(
              count ==
                      1
                  ? 'Você possui 1 convite de compromisso pendente.'
                  : 'Você possui $count convites de compromisso pendentes.',

              style: const TextStyle(
                color: Colors.white60,

                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _calendarController.removeListener(
      _handleCalendarChanged,
    );

    _calendarController.dispose();

    super.dispose();
  }
}
