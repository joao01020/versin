import 'package:flutter/material.dart';

import '../models/calendar_day_note.dart';

// ============================================================
// CALENDAR NOTE RESULT
// ============================================================
//
// Resultado retornado pelo modal.
//
// save:
//
// usuário pediu para salvar.
//
// delete:
//
// usuário pediu para excluir.
//
// ============================================================

enum CalendarNoteAction {
  save,
  delete,
}

// ============================================================
// CALENDAR NOTE RESULT
// ============================================================

class CalendarNoteResult {
  final CalendarNoteAction action;

  final String content;

  const CalendarNoteResult({
    required this.action,
    required this.content,
  });

  // ==========================================================
  // SALVAR
  // ==========================================================

  factory CalendarNoteResult.save(
    String content,
  ) {
    return CalendarNoteResult(
      action: CalendarNoteAction.save,

      content: content,
    );
  }

  // ==========================================================
  // EXCLUIR
  // ==========================================================

  factory CalendarNoteResult.delete() {
    return const CalendarNoteResult(
      action: CalendarNoteAction.delete,

      content: '',
    );
  }

  bool get shouldSave {
    return action ==
        CalendarNoteAction.save;
  }

  bool get shouldDelete {
    return action ==
        CalendarNoteAction.delete;
  }
}

// ============================================================
// CALENDAR NOTE DIALOG
// ============================================================

class CalendarNoteDialog
    extends
        StatefulWidget {
  // ==========================================================
  // DATA
  // ==========================================================

  final DateTime date;

  // ==========================================================
  // NOTA EXISTENTE
  // ==========================================================

  final CalendarDayNote? note;

  // ==========================================================
  // COR
  // ==========================================================

  final Color accentColor;

  // ==========================================================
  // CONSTRUTOR
  // ==========================================================

  const CalendarNoteDialog({
    super.key,
    required this.date,
    required this.accentColor,
    this.note,
  });

  // ==========================================================
  // ABRIR
  // ==========================================================

  static Future<
    CalendarNoteResult?
  >
  show({
    required BuildContext context,
    required DateTime date,
    required Color accentColor,
    CalendarDayNote? note,
  }) {
    return showDialog<
      CalendarNoteResult
    >(
      context: context,

      barrierDismissible: false,

      builder:
          (
            context,
          ) {
            return CalendarNoteDialog(
              date: date,

              note: note,

              accentColor: accentColor,
            );
          },
    );
  }

  @override
  State<
    CalendarNoteDialog
  >
  createState() => _CalendarNoteDialogState();
}

// ============================================================
// STATE
// ============================================================

class _CalendarNoteDialogState
    extends
        State<
          CalendarNoteDialog
        > {
  // ==========================================================
  // CONTROLLER
  // ==========================================================

  late final TextEditingController _textController;

  // ==========================================================
  // FOCUS
  // ==========================================================

  late final FocusNode _focusNode;

  // ==========================================================
  // ESTADO
  // ==========================================================

  bool _hasChanges = false;

  // ==========================================================
  // MESES
  // ==========================================================

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

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _textController = TextEditingController(
      text:
          widget.note?.content ??
          '',
    );

    _focusNode = FocusNode();

    _textController.addListener(
      _handleContentChanged,
    );

    WidgetsBinding.instance.addPostFrameCallback(
      (
        _,
      ) {
        if (!mounted) {
          return;
        }

        _focusNode.requestFocus();
      },
    );
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _textController.removeListener(
      _handleContentChanged,
    );

    _textController.dispose();

    _focusNode.dispose();

    super.dispose();
  }

  // ==========================================================
  // CONTEÚDO ALTERADO
  // ==========================================================

  void _handleContentChanged() {
    final original =
        widget.note?.content ??
        '';

    final changed =
        _textController.text !=
        original;

    if (changed ==
        _hasChanges) {
      return;
    }

    setState(
      () {
        _hasChanges = changed;
      },
    );
  }

  // ==========================================================
  // DATA
  // ==========================================================

  String get _dateLabel {
    final day = widget.date.day.toString().padLeft(
      2,
      '0',
    );

    final month =
        _months[widget.date.month -
                1]
            .toUpperCase();

    return '$day DE $month DE ${widget.date.year}';
  }

  // ==========================================================
  // TEM NOTA?
  // ==========================================================

  bool get _hasExistingNote {
    return widget.note !=
        null;
  }

  // ==========================================================
  // SALVAR
  // ==========================================================

  void _save() {
    final content = _textController.text.trim();

    // Uma nota completamente vazia não precisa ser criada.

    if (content.isEmpty &&
        !_hasExistingNote) {
      Navigator.of(
        context,
      ).pop();

      return;
    }

    // Se uma nota existente foi apagada completamente,
    // tratamos como exclusão.

    if (content.isEmpty &&
        _hasExistingNote) {
      Navigator.of(
        context,
      ).pop(
        CalendarNoteResult.delete(),
      );

      return;
    }

    Navigator.of(
      context,
    ).pop(
      CalendarNoteResult.save(
        content,
      ),
    );
  }

  // ==========================================================
  // EXCLUIR
  // ==========================================================

  Future<
    void
  >
  _delete() async {
    if (!_hasExistingNote) {
      return;
    }

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

                  title: const Text(
                    'Excluir anotação?',

                    style: TextStyle(
                      color: Colors.white,

                      fontSize: 16,

                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  content: const Text(
                    'Esta anotação será removida permanentemente.',

                    style: TextStyle(
                      color: Colors.white54,

                      fontSize: 12,
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

                    TextButton(
                      onPressed: () {
                        Navigator.of(
                          dialogContext,
                        ).pop(
                          true,
                        );
                      },

                      child: const Text(
                        'EXCLUIR',

                        style: TextStyle(
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                  ],
                );
              },
        );

    if (confirmed !=
        true) {
      return;
    }

    if (!mounted) {
      return;
    }

    Navigator.of(
      context,
    ).pop(
      CalendarNoteResult.delete(),
    );
  }

  // ==========================================================
  // FECHAR
  // ==========================================================

  Future<
    void
  >
  _close() async {
    if (!_hasChanges) {
      Navigator.of(
        context,
      ).pop();

      return;
    }

    final close =
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

                  title: const Text(
                    'Descartar alterações?',

                    style: TextStyle(
                      color: Colors.white,

                      fontSize: 16,

                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  content: const Text(
                    'Existem alterações que ainda não foram salvas.',

                    style: TextStyle(
                      color: Colors.white54,

                      fontSize: 12,
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
                        'CONTINUAR EDITANDO',
                      ),
                    ),

                    TextButton(
                      onPressed: () {
                        Navigator.of(
                          dialogContext,
                        ).pop(
                          true,
                        );
                      },

                      child: const Text(
                        'DESCARTAR',

                        style: TextStyle(
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                  ],
                );
              },
        );

    if (close !=
        true) {
      return;
    }

    if (!mounted) {
      return;
    }

    Navigator.of(
      context,
    ).pop();
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final screen = MediaQuery.sizeOf(
      context,
    );

    final dialogWidth =
        screen.width <
            760
        ? screen.width *
              0.92
        : 720.0;

    final dialogHeight =
        screen.height <
            700
        ? screen.height *
              0.88
        : 620.0;

    return PopScope(
      canPop: !_hasChanges,

      onPopInvokedWithResult:
          (
            didPop,
            result,
          ) {
            if (didPop) {
              return;
            }

            _close();
          },

      child: Dialog(
        backgroundColor: Colors.transparent,

        insetPadding: const EdgeInsets.all(
          20,
        ),

        child: Container(
          width: dialogWidth,

          height: dialogHeight,

          decoration: BoxDecoration(
            color: const Color(
              0xFF121022,
            ),

            borderRadius: BorderRadius.circular(
              18,
            ),

            border: Border.all(
              color: Colors.white.withValues(
                alpha: 0.08,
              ),
            ),

            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: 0.45,
                ),

                blurRadius: 30,

                offset: const Offset(
                  0,
                  14,
                ),
              ),
            ],
          ),

          child: Column(
            children: [
              // ==================================================
              // HEADER
              // ==================================================
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  22,
                  18,
                  14,
                  14,
                ),

                child: Row(
                  children: [
                    Icon(
                      Icons.edit_note_rounded,

                      color: widget.accentColor,

                      size: 21,
                    ),

                    const SizedBox(
                      width: 10,
                    ),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Text(
                            _dateLabel,

                            style: const TextStyle(
                              color: Colors.white,

                              fontSize: 14,

                              fontWeight: FontWeight.bold,

                              letterSpacing: 0.5,
                            ),
                          ),

                          const SizedBox(
                            height: 3,
                          ),

                          Text(
                            _hasExistingNote
                                ? 'Anotação do dia'
                                : 'Nova anotação',

                            style: const TextStyle(
                              color: Colors.white38,

                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),

                    IconButton(
                      tooltip: 'Fechar',

                      onPressed: _close,

                      icon: const Icon(
                        Icons.close_rounded,

                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),

              Divider(
                height: 1,

                color: Colors.white.withValues(
                  alpha: 0.06,
                ),
              ),

              // ==================================================
              // EDITOR
              // ==================================================
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    22,
                    20,
                    22,
                    14,
                  ),

                  child: TextField(
                    controller: _textController,

                    focusNode: _focusNode,

                    expands: true,

                    minLines: null,

                    maxLines: null,

                    keyboardType: TextInputType.multiline,

                    textAlignVertical: TextAlignVertical.top,

                    style: const TextStyle(
                      color: Colors.white,

                      fontSize: 14,

                      height: 1.6,
                    ),

                    cursorColor: widget.accentColor,

                    decoration: const InputDecoration(
                      hintText:
                          'Escreva o que quiser...\n\n'
                          'Ideias, lembretes, planejamento, '
                          'observações sobre o dia...',

                      hintStyle: TextStyle(
                        color: Colors.white24,

                        fontSize: 13,

                        height: 1.6,
                      ),

                      border: InputBorder.none,

                      enabledBorder: InputBorder.none,

                      focusedBorder: InputBorder.none,

                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),

              // ==================================================
              // FOOTER
              // ==================================================
              Container(
                padding: const EdgeInsets.fromLTRB(
                  18,
                  12,
                  18,
                  14,
                ),

                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(
                        alpha: 0.06,
                      ),
                    ),
                  ),
                ),

                child: Row(
                  children: [
                    // ============================================
                    // STATUS
                    // ============================================
                    Expanded(
                      child: Text(
                        _hasChanges
                            ? 'Alterações não salvas'
                            : _hasExistingNote
                            ? 'Anotação salva'
                            : 'Nova anotação',

                        style: TextStyle(
                          color: _hasChanges
                              ? widget.accentColor
                              : Colors.white24,

                          fontSize: 10,
                        ),
                      ),
                    ),

                    // ============================================
                    // EXCLUIR
                    // ============================================
                    if (_hasExistingNote)
                      TextButton.icon(
                        onPressed: _delete,

                        icon: const Icon(
                          Icons.delete_outline_rounded,

                          size: 16,

                          color: Colors.redAccent,
                        ),

                        label: const Text(
                          'EXCLUIR',

                          style: TextStyle(
                            color: Colors.redAccent,

                            fontSize: 10,

                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                    if (_hasExistingNote)
                      const SizedBox(
                        width: 8,
                      ),

                    // ============================================
                    // SALVAR
                    // ============================================
                    FilledButton.icon(
                      onPressed: _save,

                      style: FilledButton.styleFrom(
                        backgroundColor: widget.accentColor,

                        foregroundColor: Colors.black,

                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,

                          vertical: 12,
                        ),

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            9,
                          ),
                        ),
                      ),

                      icon: const Icon(
                        Icons.check_rounded,

                        size: 16,
                      ),

                      label: const Text(
                        'SALVAR',

                        style: TextStyle(
                          fontSize: 10,

                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
