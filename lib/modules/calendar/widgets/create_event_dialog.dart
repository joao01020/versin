import 'package:flutter/material.dart';

import '../models/calendar_event_type.dart';

// ============================================================
// CREATE EVENT DIALOG RESULT
// ============================================================

class CreateEventDialogResult {
  final String title;

  final String? description;

  final String? locationName;

  final DateTime startsAt;

  final DateTime? endsAt;

  final CalendarEventType type;

  final List<
    String
  >
  participantIds;

  final String? projectId;

  const CreateEventDialogResult({
    required this.title,
    required this.startsAt,
    required this.type,
    this.description,
    this.locationName,
    this.endsAt,
    this.participantIds = const [],
    this.projectId,
  });

  bool get isPersonal {
    return type ==
        CalendarEventType.personal;
  }
}

// ============================================================
// CREATE EVENT DIALOG
// ============================================================

class CreateEventDialog
    extends
        StatefulWidget {
  final DateTime initialDate;

  final Color accentColor;

  final Map<
    String,
    String
  >
  availableParticipants;

  final String? projectId;

  const CreateEventDialog({
    super.key,
    required this.initialDate,
    required this.accentColor,
    this.availableParticipants = const {},
    this.projectId,
  });

  // ============================================================
  // SHOW
  // ============================================================

  static Future<
    CreateEventDialogResult?
  >
  show({
    required BuildContext context,
    required DateTime initialDate,
    required Color accentColor,
    Map<
          String,
          String
        >
        availableParticipants =
        const {},
    String? projectId,
  }) {
    return showDialog<
      CreateEventDialogResult
    >(
      context: context,

      barrierDismissible: false,

      builder:
          (
            context,
          ) {
            return CreateEventDialog(
              initialDate: initialDate,

              accentColor: accentColor,

              availableParticipants: availableParticipants,

              projectId: projectId,
            );
          },
    );
  }

  @override
  State<
    CreateEventDialog
  >
  createState() => _CreateEventDialogState();
}

// ============================================================
// STATE
// ============================================================

class _CreateEventDialogState
    extends
        State<
          CreateEventDialog
        > {
  final TextEditingController _titleController = TextEditingController();

  final TextEditingController _descriptionController = TextEditingController();

  final TextEditingController _locationController = TextEditingController();

  late DateTime _selectedDate;

  TimeOfDay _startTime = const TimeOfDay(
    hour: 18,
    minute: 0,
  );

  TimeOfDay? _endTime;

  CalendarEventType _type = CalendarEventType.personal;

  final Set<
    String
  >
  _selectedParticipants = {};

  String? _errorMessage;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _selectedDate = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _titleController.dispose();

    _descriptionController.dispose();

    _locationController.dispose();

    super.dispose();
  }

  // ============================================================
  // PICK DATE
  // ============================================================

  Future<
    void
  >
  _pickDate() async {
    final result = await showDatePicker(
      context: context,

      initialDate: _selectedDate,

      firstDate: DateTime.now().subtract(
        const Duration(
          days: 365,
        ),
      ),

      lastDate: DateTime.now().add(
        const Duration(
          days: 3650,
        ),
      ),
    );

    if (result ==
            null ||
        !mounted) {
      return;
    }

    setState(
      () {
        _selectedDate = result;
      },
    );
  }

  // ============================================================
  // PICK START TIME
  // ============================================================

  Future<
    void
  >
  _pickStartTime() async {
    final result = await showTimePicker(
      context: context,

      initialTime: _startTime,
    );

    if (result ==
            null ||
        !mounted) {
      return;
    }

    setState(
      () {
        _startTime = result;
      },
    );
  }

  // ============================================================
  // PICK END TIME
  // ============================================================

  Future<
    void
  >
  _pickEndTime() async {
    final result = await showTimePicker(
      context: context,

      initialTime:
          _endTime ??
          TimeOfDay(
            hour:
                (_startTime.hour +
                    1) %
                24,

            minute: _startTime.minute,
          ),
    );

    if (result ==
            null ||
        !mounted) {
      return;
    }

    setState(
      () {
        _endTime = result;
      },
    );
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String _formatDate(
    DateTime date,
  ) {
    final day = date.day.toString().padLeft(
      2,
      '0',
    );

    final month = date.month.toString().padLeft(
      2,
      '0',
    );

    return '$day/$month/${date.year}';
  }

  // ============================================================
  // COMBINE DATE + TIME
  // ============================================================

  DateTime _combine(
    TimeOfDay time,
  ) {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      time.hour,
      time.minute,
    );
  }

  // ============================================================
  // SUBMIT
  // ============================================================

  void _submit() {
    final title = _titleController.text.trim();

    if (title.isEmpty) {
      setState(
        () {
          _errorMessage = 'Informe um título.';
        },
      );

      return;
    }

    if (_type.isCollaborative &&
        _selectedParticipants.isEmpty) {
      setState(
        () {
          _errorMessage = 'Selecione pelo menos um participante.';
        },
      );

      return;
    }

    final startsAt = _combine(
      _startTime,
    );

    final endsAt =
        _endTime ==
            null
        ? null
        : _combine(
            _endTime!,
          );

    if (endsAt !=
            null &&
        endsAt.isBefore(
          startsAt,
        )) {
      setState(
        () {
          _errorMessage = 'O horário final não pode ser anterior ao inicial.';
        },
      );

      return;
    }

    Navigator.of(
      context,
    ).pop(
      CreateEventDialogResult(
        title: title,

        description: _normalize(
          _descriptionController.text,
        ),

        locationName: _normalize(
          _locationController.text,
        ),

        startsAt: startsAt,

        endsAt: endsAt,

        type: _type,

        participantIds: _selectedParticipants.toList(),

        projectId: widget.projectId,
      ),
    );
  }

  // ============================================================
  // NORMALIZE
  // ============================================================

  String? _normalize(
    String value,
  ) {
    final normalized = value.trim();

    if (normalized.isEmpty) {
      return null;
    }

    return normalized;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final participants = widget.availableParticipants.entries.toList();

    return AlertDialog(
      backgroundColor: const Color(
        0xFF17132D,
      ),

      surfaceTintColor: Colors.transparent,

      title: const Text(
        'Nova atividade',

        style: TextStyle(
          color: Colors.white,

          fontSize: 17,

          fontWeight: FontWeight.bold,
        ),
      ),

      content: SizedBox(
        width: 460,

        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              TextField(
                controller: _titleController,

                style: const TextStyle(
                  color: Colors.white,
                ),

                decoration: const InputDecoration(
                  labelText: 'Título',

                  labelStyle: TextStyle(
                    color: Colors.white54,
                  ),
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              DropdownButtonFormField<
                CalendarEventType
              >(
                initialValue: _type,

                dropdownColor: const Color(
                  0xFF17132D,
                ),

                style: const TextStyle(
                  color: Colors.white,
                ),

                decoration: const InputDecoration(
                  labelText: 'Tipo',

                  labelStyle: TextStyle(
                    color: Colors.white54,
                  ),
                ),

                items: CalendarEventType.values.map(
                  (
                    type,
                  ) {
                    return DropdownMenuItem(
                      value: type,

                      child: Text(
                        type.label,
                      ),
                    );
                  },
                ).toList(),

                onChanged:
                    (
                      value,
                    ) {
                      if (value ==
                          null) {
                        return;
                      }

                      setState(
                        () {
                          _type = value;

                          if (!_type.isCollaborative) {
                            _selectedParticipants.clear();
                          }
                        },
                      );
                    },
              ),

              const SizedBox(
                height: 12,
              ),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,

                      icon: const Icon(
                        Icons.calendar_today_outlined,
                      ),

                      label: Text(
                        _formatDate(
                          _selectedDate,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickStartTime,

                      icon: const Icon(
                        Icons.schedule_rounded,
                      ),

                      label: Text(
                        _startTime.format(
                          context,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 8,
              ),

              SizedBox(
                width: double.infinity,

                child: OutlinedButton.icon(
                  onPressed: _pickEndTime,

                  icon: const Icon(
                    Icons.timelapse_rounded,
                  ),

                  label: Text(
                    _endTime ==
                            null
                        ? 'Adicionar horário final'
                        : 'Final: ${_endTime!.format(context)}',
                  ),
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              TextField(
                controller: _locationController,

                style: const TextStyle(
                  color: Colors.white,
                ),

                decoration: const InputDecoration(
                  labelText: 'Local (opcional)',

                  labelStyle: TextStyle(
                    color: Colors.white54,
                  ),
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              TextField(
                controller: _descriptionController,

                maxLines: 3,

                style: const TextStyle(
                  color: Colors.white,
                ),

                decoration: const InputDecoration(
                  labelText: 'Descrição (opcional)',

                  alignLabelWithHint: true,

                  labelStyle: TextStyle(
                    color: Colors.white54,
                  ),
                ),
              ),

              if (_type.isCollaborative) ...[
                const SizedBox(
                  height: 18,
                ),

                const Text(
                  'Participantes',

                  style: TextStyle(
                    color: Colors.white70,

                    fontSize: 12,

                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                if (participants.isEmpty)
                  const Text(
                    'Nenhum participante disponível para este projeto.',

                    style: TextStyle(
                      color: Colors.white30,

                      fontSize: 11,
                    ),
                  )
                else
                  ...participants.map(
                    (
                      entry,
                    ) {
                      final selected = _selectedParticipants.contains(
                        entry.key,
                      );

                      return CheckboxListTile(
                        dense: true,

                        contentPadding: EdgeInsets.zero,

                        value: selected,

                        activeColor: widget.accentColor,

                        title: Text(
                          entry.value,

                          style: const TextStyle(
                            color: Colors.white70,

                            fontSize: 11,
                          ),
                        ),

                        onChanged:
                            (
                              value,
                            ) {
                              setState(
                                () {
                                  if (value ==
                                      true) {
                                    _selectedParticipants.add(
                                      entry.key,
                                    );
                                  } else {
                                    _selectedParticipants.remove(
                                      entry.key,
                                    );
                                  }
                                },
                              );
                            },
                      );
                    },
                  ),
              ],

              if (_errorMessage !=
                  null) ...[
                const SizedBox(
                  height: 12,
                ),

                Text(
                  _errorMessage!,

                  style: const TextStyle(
                    color: Colors.redAccent,

                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),

      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(
              context,
            ).pop();
          },

          child: const Text(
            'CANCELAR',
          ),
        ),

        FilledButton(
          onPressed: _submit,

          style: FilledButton.styleFrom(
            backgroundColor: widget.accentColor,

            foregroundColor: Colors.black,
          ),

          child: const Text(
            'CRIAR',
          ),
        ),
      ],
    );
  }
}
