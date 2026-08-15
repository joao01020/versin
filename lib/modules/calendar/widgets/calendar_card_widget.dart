import 'package:flutter/material.dart';

import '../controllers/calendar_controller.dart';
import 'calendar_event_card.dart';

// ============================================================
// CALENDAR CARD WIDGET
// ============================================================
//
// Calendário conectado ao CalendarController.
//
// Não utiliza tarefas fake do DashboardController.
//
// INTERAÇÕES:
//
// Clique normal:
//
// - seleciona o dia.
//
// Botão direito:
//
// - solicita abertura da anotação daquele dia.
//
// Pressionar e segurar:
//
// - mesma função do botão direito;
// - permite utilizar o recurso em Android/iOS.
//
// ============================================================

class CalendarCardWidget
    extends
        StatelessWidget {
  // ============================================================
  // CONTROLLER
  // ============================================================

  final CalendarController controller;

  // ============================================================
  // ADICIONAR COMPROMISSO
  // ============================================================

  final VoidCallback onAddAppointmentTap;

  // ============================================================
  // EVENTOS
  // ============================================================

  final void Function(
    String eventId,
  )?
  onEditEvent;

  final void Function(
    String eventId,
  )?
  onDeleteEvent;

  // ============================================================
  // ANOTAÇÃO DO DIA
  // ============================================================
  //
  // Chamado quando:
  //
  // - botão direito é pressionado;
  // - usuário mantém o dedo pressionado.
  //
  // ============================================================

  final void Function(
    DateTime date,
  )?
  onDayNoteRequested;

  // ============================================================
  // VERIFICAR SE DIA POSSUI ANOTAÇÃO
  // ============================================================
  //
  // Callback opcional.
  //
  // Enquanto o banco de notas ainda não estiver conectado,
  // pode permanecer null.
  //
  // ============================================================

  final bool Function(
    DateTime date,
  )?
  hasNoteForDay;

  // ============================================================
  // COR
  // ============================================================

  final Color accentColor;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  const CalendarCardWidget({
    super.key,
    required this.controller,
    required this.onAddAppointmentTap,
    required this.accentColor,
    this.onEditEvent,
    this.onDeleteEvent,
    this.onDayNoteRequested,
    this.hasNoteForDay,
  });

  // ============================================================
  // MESES
  // ============================================================

  static const List<
    String
  >
  _months = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];

  // ============================================================
  // DATA DO DIA
  // ============================================================

  DateTime _buildDate({
    required DateTime focusedDay,
    required int day,
  }) {
    return DateTime(
      focusedDay.year,
      focusedDay.month,
      day,
    );
  }

  // ============================================================
  // SOLICITAR ANOTAÇÃO
  // ============================================================

  void _requestDayNote({
    required DateTime focusedDay,
    required int day,
  }) {
    final callback = onDayNoteRequested;

    if (callback ==
        null) {
      return;
    }

    final date = _buildDate(
      focusedDay: focusedDay,

      day: day,
    );

    callback(
      date,
    );
  }

  // ============================================================
  // DIA POSSUI ANOTAÇÃO?
  // ============================================================

  bool _dayHasNote({
    required DateTime focusedDay,
    required int day,
  }) {
    final checker = hasNoteForDay;

    if (checker ==
        null) {
      return false;
    }

    return checker(
      _buildDate(
        focusedDay: focusedDay,

        day: day,
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
    return AnimatedBuilder(
      animation: controller,

      builder:
          (
            context,
            child,
          ) {
            final focusedDay = controller.focusedDay;

            final events = controller.selectedDayEvents;

            final daysInMonth = DateTime(
              focusedDay.year,
              focusedDay.month +
                  1,
              0,
            ).day;

            final firstDayOffset =
                DateTime(
                  focusedDay.year,
                  focusedDay.month,
                  1,
                ).weekday %
                7;

            return Container(
              width: double.infinity,

              padding: const EdgeInsets.all(
                14,
              ),

              decoration: BoxDecoration(
                color: const Color(
                  0xFF17132D,
                ),

                borderRadius: BorderRadius.circular(
                  16,
                ),

                border: Border.all(
                  color: Colors.white.withValues(
                    alpha: 0.06,
                  ),
                ),
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  // ==================================================
                  // HEADER
                  // ==================================================
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_month_rounded,

                        color: accentColor,

                        size: 17,
                      ),

                      const SizedBox(
                        width: 8,
                      ),

                      Expanded(
                        child: Text(
                          '${_months[focusedDay.month - 1]} ${focusedDay.year}',

                          style: const TextStyle(
                            color: Colors.white,

                            fontSize: 13,

                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      // ==============================================
                      // MÊS ANTERIOR
                      // ==============================================
                      IconButton(
                        tooltip: 'Mês anterior',

                        onPressed: controller.isLoading
                            ? null
                            : () {
                                controller.navigateMonth(
                                  forward: false,
                                );
                              },

                        icon: const Icon(
                          Icons.chevron_left_rounded,

                          color: Colors.white54,
                        ),
                      ),

                      // ==============================================
                      // PRÓXIMO MÊS
                      // ==============================================
                      IconButton(
                        tooltip: 'Próximo mês',

                        onPressed: controller.isLoading
                            ? null
                            : () {
                                controller.navigateMonth(
                                  forward: true,
                                );
                              },

                        icon: const Icon(
                          Icons.chevron_right_rounded,

                          color: Colors.white54,
                        ),
                      ),

                      // ==============================================
                      // EXPANDIR
                      // ==============================================
                      IconButton(
                        tooltip: controller.isCalendarExpanded
                            ? 'Recolher calendário'
                            : 'Expandir calendário',

                        onPressed: controller.toggleCalendarExpanded,

                        icon: Icon(
                          controller.isCalendarExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,

                          color: Colors.white38,
                        ),
                      ),
                    ],
                  ),

                  // ==================================================
                  // LOADING
                  // ==================================================
                  if (controller.isLoading)
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 6,
                      ),

                      child: LinearProgressIndicator(
                        minHeight: 1.5,

                        color: accentColor,

                        backgroundColor: Colors.white10,
                      ),
                    ),

                  // ==================================================
                  // CALENDÁRIO
                  // ==================================================
                  if (controller.isCalendarExpanded) ...[
                    const SizedBox(
                      height: 14,
                    ),

                    // ================================================
                    // DIAS DA SEMANA
                    // ================================================
                    Row(
                      children:
                          const [
                            'D',
                            'S',
                            'T',
                            'Q',
                            'Q',
                            'S',
                            'S',
                          ].map(
                            (
                              day,
                            ) {
                              return Expanded(
                                child: Center(
                                  child: Text(
                                    day,

                                    style: TextStyle(
                                      color: Colors.white38,

                                      fontSize: 11,

                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ).toList(),
                    ),

                    const SizedBox(
                      height: 6,
                    ),

                    // ================================================
                    // GRID
                    // ================================================
                    GridView.builder(
                      shrinkWrap: true,

                      physics: const NeverScrollableScrollPhysics(),

                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,

                        mainAxisSpacing: 4,

                        crossAxisSpacing: 4,

                        childAspectRatio: 1,
                      ),

                      itemCount:
                          daysInMonth +
                          firstDayOffset,

                      itemBuilder:
                          (
                            context,
                            index,
                          ) {
                            if (index <
                                firstDayOffset) {
                              return const SizedBox.shrink();
                            }

                            final day =
                                index -
                                firstDayOffset +
                                1;

                            final selected =
                                controller.selectedDay ==
                                day;

                            final hasEvent = controller.hasEventOnDay(
                              day,
                            );

                            final hasNote = _dayHasNote(
                              focusedDay: focusedDay,

                              day: day,
                            );

                            // ============================================
                            // DIA
                            // ============================================

                            return Material(
                              color: Colors.transparent,

                              child: InkWell(
                                borderRadius: BorderRadius.circular(
                                  7,
                                ),

                                // ========================================
                                // CLIQUE NORMAL
                                // ========================================
                                onTap: () {
                                  controller.selectDay(
                                    day,
                                  );
                                },

                                // ========================================
                                // BOTÃO DIREITO - DESKTOP
                                // ========================================
                                onSecondaryTap:
                                    onDayNoteRequested ==
                                        null
                                    ? null
                                    : () {
                                        controller.selectDay(
                                          day,
                                        );

                                        _requestDayNote(
                                          focusedDay: focusedDay,

                                          day: day,
                                        );
                                      },

                                // ========================================
                                // PRESSIONAR E SEGURAR - MOBILE
                                // ========================================
                                onLongPress:
                                    onDayNoteRequested ==
                                        null
                                    ? null
                                    : () {
                                        controller.selectDay(
                                          day,
                                        );

                                        _requestDayNote(
                                          focusedDay: focusedDay,

                                          day: day,
                                        );
                                      },

                                child: Container(
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? accentColor
                                        : Colors.transparent,

                                    borderRadius: BorderRadius.circular(
                                      7,
                                    ),
                                  ),

                                  child: Stack(
                                    alignment: Alignment.center,

                                    children: [
                                      // ==================================
                                      // NÚMERO
                                      // ==================================
                                      Text(
                                        '$day',

                                        style: TextStyle(
                                          color: selected
                                              ? Colors.black
                                              : Colors.white38,

                                          fontSize: 11,

                                          fontWeight: selected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),

                                      // ==================================
                                      // EVENTO
                                      // ==================================
                                      if (hasEvent)
                                        Positioned(
                                          bottom: 4,

                                          left: hasNote
                                              ? 8
                                              : null,

                                          child: Container(
                                            width: 4,

                                            height: 4,

                                            decoration: BoxDecoration(
                                              color: selected
                                                  ? Colors.black54
                                                  : accentColor,

                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),

                                      // ==================================
                                      // ANOTAÇÃO
                                      // ==================================
                                      if (hasNote)
                                        Positioned(
                                          bottom: 3,

                                          right: 5,

                                          child: Icon(
                                            Icons.edit_note_rounded,

                                            size: 10,

                                            color: selected
                                                ? Colors.black54
                                                : Colors.white38,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                    ),

                    // ================================================
                    // DICA DE INTERAÇÃO
                    // ================================================
                    if (onDayNoteRequested !=
                        null) ...[
                      const SizedBox(
                        height: 8,
                      ),

                      const Row(
                        children: [
                          Icon(
                            Icons.mouse_outlined,

                            size: 11,

                            color: Colors.white24,
                          ),

                          SizedBox(
                            width: 5,
                          ),

                          Expanded(
                            child: Text(
                              'Botão direito no dia para abrir uma anotação.',

                              style: TextStyle(
                                color: Colors.white24,

                                fontSize: 9,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],

                  const SizedBox(
                    height: 14,
                  ),

                  // ==================================================
                  // EVENTOS DO DIA
                  // ==================================================
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Dia ${controller.selectedDay}',

                          style: const TextStyle(
                            color: Colors.white54,

                            fontSize: 11,

                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      if (events.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,

                            vertical: 3,
                          ),

                          decoration: BoxDecoration(
                            color: accentColor.withValues(
                              alpha: 0.15,
                            ),

                            borderRadius: BorderRadius.circular(
                              20,
                            ),
                          ),

                          child: Text(
                            '${events.length}',

                            style: TextStyle(
                              color: accentColor,

                              fontSize: 10,

                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  // ==================================================
                  // SEM EVENTOS
                  // ==================================================
                  if (events.isEmpty)
                    Container(
                      width: double.infinity,

                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,

                        vertical: 18,
                      ),

                      decoration: BoxDecoration(
                        color: Colors.black.withValues(
                          alpha: 0.16,
                        ),

                        borderRadius: BorderRadius.circular(
                          10,
                        ),
                      ),

                      child: const Text(
                        'Nenhuma atividade neste dia.',

                        textAlign: TextAlign.center,

                        style: TextStyle(
                          color: Colors.white24,

                          fontSize: 11,
                        ),
                      ),
                    )
                  // ==================================================
                  // EVENTOS
                  // ==================================================
                  else
                    ...events.map(
                      (
                        event,
                      ) {
                        return CalendarEventCard(
                          event: event,

                          accentColor: accentColor,

                          onEdit:
                              onEditEvent ==
                                  null
                              ? null
                              : () {
                                  onEditEvent!(
                                    event.id,
                                  );
                                },

                          onDelete:
                              onDeleteEvent ==
                                  null
                              ? null
                              : () {
                                  onDeleteEvent!(
                                    event.id,
                                  );
                                },
                        );
                      },
                    ),

                  const SizedBox(
                    height: 10,
                  ),

                  // ==================================================
                  // ADICIONAR ATIVIDADE
                  // ==================================================
                  SizedBox(
                    width: double.infinity,

                    height: 38,

                    child: OutlinedButton.icon(
                      onPressed: controller.isSubmitting
                          ? null
                          : onAddAppointmentTap,

                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: accentColor.withValues(
                            alpha: 0.45,
                          ),
                        ),

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            9,
                          ),
                        ),
                      ),

                      icon: Icon(
                        Icons.add_rounded,

                        color: accentColor,

                        size: 15,
                      ),

                      label: Text(
                        'Adicionar atividade',

                        style: TextStyle(
                          color: accentColor,

                          fontSize: 10,

                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // ==================================================
                  // ERRO
                  // ==================================================
                  if (controller.hasError) ...[
                    const SizedBox(
                      height: 10,
                    ),

                    Text(
                      controller.errorMessage ??
                          'Erro no calendário.',

                      style: const TextStyle(
                        color: Colors.redAccent,

                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
    );
  }
}
