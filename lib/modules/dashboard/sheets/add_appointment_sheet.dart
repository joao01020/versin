import 'package:flutter/material.dart';

import '../controllers/dashboard_controller.dart';

// ============================================================
// ADD APPOINTMENT SHEET
// ============================================================
//
// Modal responsável por criar um novo compromisso.
//
// Responsabilidades:
//
// - abrir BottomSheet;
// - receber descrição;
// - receber horário;
// - validar campos;
// - enviar compromisso ao DashboardController;
// - fechar modal.
//
// Este arquivo NÃO:
//
// - controla navegação do Dashboard;
// - conhece PageView;
// - conhece menus;
// - desenha o Dashboard principal.
//
// ============================================================

abstract final class AddAppointmentSheet {
  // ==========================================================
  // ABRIR
  // ==========================================================

  static Future<
    void
  >
  show({
    required BuildContext context,
    required DashboardController controller,
    String? fixedTime,
  }) async {
    final titleController = TextEditingController();

    final now = DateTime.now();

    final defaultTime =
        fixedTime ??
        '${now.hour.toString().padLeft(2, '0')}:'
            '${now.minute.toString().padLeft(2, '0')}';

    final timeController = TextEditingController(
      text: defaultTime,
    );

    try {
      await showModalBottomSheet<
        void
      >(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(
          0xFF15122C,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(
              24,
            ),
          ),
        ),
        builder:
            (
              sheetContext,
            ) {
              return _AddAppointmentSheetContent(
                controller: controller,
                titleController: titleController,
                timeController: timeController,
              );
            },
      );
    } finally {
      titleController.dispose();

      timeController.dispose();
    }
  }
}

// ============================================================
// CONTENT
// ============================================================

class _AddAppointmentSheetContent
    extends
        StatefulWidget {
  final DashboardController controller;

  final TextEditingController titleController;

  final TextEditingController timeController;

  const _AddAppointmentSheetContent({
    required this.controller,
    required this.titleController,
    required this.timeController,
  });

  @override
  State<
    _AddAppointmentSheetContent
  >
  createState() => _AddAppointmentSheetContentState();
}

// ============================================================
// STATE
// ============================================================

class _AddAppointmentSheetContentState
    extends
        State<
          _AddAppointmentSheetContent
        > {
  // ============================================================
  // ERRO
  // ============================================================

  String? _errorMessage;

  // ============================================================
  // GETTERS
  // ============================================================

  DashboardController get controller => widget.controller;

  TextEditingController get titleController => widget.titleController;

  TextEditingController get timeController => widget.timeController;

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding: EdgeInsets.only(
        bottom:
            MediaQuery.of(
              context,
            ).viewInsets.bottom +
            24,
        top: 24,
        left: 24,
        right: 24,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================================================
            // HEADER
            // ==================================================
            _buildHeader(),

            const SizedBox(
              height: 16,
            ),

            // ==================================================
            // DESCRIÇÃO
            // ==================================================
            _buildDescriptionField(),

            const SizedBox(
              height: 12,
            ),

            // ==================================================
            // HORÁRIO
            // ==================================================
            _buildTimeField(),

            // ==================================================
            // ERRO
            // ==================================================
            if (_errorMessage !=
                null) ...[
              const SizedBox(
                height: 10,
              ),

              Text(
                _errorMessage!,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 10,
                ),
              ),
            ],

            const SizedBox(
              height: 20,
            ),

            // ==================================================
            // BOTÃO
            // ==================================================
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            'NOVO COMPROMISSO - DIA '
            '${controller.selectedDay}/'
            '${controller.focusedDay.month}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ),

        const SizedBox(
          width: 12,
        ),

        IconButton(
          tooltip: 'Fechar',
          onPressed: () {
            Navigator.of(
              context,
            ).pop();
          },
          icon: const Icon(
            Icons.close_rounded,
            color: Colors.white54,
            size: 20,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DESCRIÇÃO
  // ============================================================

  Widget _buildDescriptionField() {
    return TextField(
      controller: titleController,
      autofocus: true,
      textInputAction: TextInputAction.next,
      style: const TextStyle(
        color: Colors.white,
      ),
      onChanged:
          (
            _,
          ) {
            _clearError();
          },
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withValues(
          alpha: 0.05,
        ),
        hintText: 'Descrição do compromisso',
        hintStyle: const TextStyle(
          color: Colors.white30,
        ),
        prefixIcon: const Icon(
          Icons.edit_outlined,
          color: Colors.white38,
          size: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            12,
          ),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            12,
          ),
          borderSide: BorderSide(
            color: Colors.white.withValues(
              alpha: 0.05,
            ),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            12,
          ),
          borderSide: BorderSide(
            color: controller.accentNeon.withValues(
              alpha: 0.55,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HORÁRIO
  // ============================================================

  Widget _buildTimeField() {
    return TextField(
      controller: timeController,
      keyboardType: TextInputType.datetime,
      textInputAction: TextInputAction.done,
      style: const TextStyle(
        color: Colors.white,
        fontFamily: 'monospace',
      ),
      onChanged:
          (
            _,
          ) {
            _clearError();
          },
      onSubmitted:
          (
            _,
          ) {
            _submit();
          },
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withValues(
          alpha: 0.05,
        ),
        hintText: 'Horário (HH:MM)',
        hintStyle: const TextStyle(
          color: Colors.white30,
        ),
        prefixIcon: const Icon(
          Icons.access_time_rounded,
          color: Colors.white38,
          size: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            12,
          ),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            12,
          ),
          borderSide: BorderSide(
            color: Colors.white.withValues(
              alpha: 0.05,
            ),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            12,
          ),
          borderSide: BorderSide(
            color: controller.accentNeon.withValues(
              alpha: 0.55,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BOTÃO
  // ============================================================

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: controller.accentNeon,
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              12,
            ),
          ),
        ),
        icon: const Icon(
          Icons.add_task_rounded,
          size: 18,
        ),
        label: const Text(
          'AGENDAR NO CHASSI',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SUBMIT
  // ============================================================

  void _submit() {
    final title = titleController.text.trim();

    final time = timeController.text.trim();

    // ==========================================================
    // DESCRIÇÃO
    // ==========================================================

    if (title.isEmpty) {
      _showError(
        'Digite a descrição do compromisso.',
      );

      return;
    }

    // ==========================================================
    // HORÁRIO
    // ==========================================================

    if (time.isEmpty) {
      _showError(
        'Digite o horário do compromisso.',
      );

      return;
    }

    // ==========================================================
    // VALIDAR HH:MM
    // ==========================================================

    if (!_isValidTime(
      time,
    )) {
      _showError(
        'Use um horário válido no formato HH:MM.',
      );

      return;
    }

    // ==========================================================
    // ADICIONAR
    // ==========================================================

    controller.addAppointment(
      title: title,
      time: time,
    );

    // ==========================================================
    // FECHAR
    // ==========================================================

    Navigator.of(
      context,
    ).pop();
  }

  // ============================================================
  // VALIDAR HORÁRIO
  // ============================================================

  bool _isValidTime(
    String value,
  ) {
    final match =
        RegExp(
          r'^([01]\d|2[0-3]):([0-5]\d)$',
        ).firstMatch(
          value,
        );

    return match !=
        null;
  }

  // ============================================================
  // ERRO
  // ============================================================

  void _showError(
    String message,
  ) {
    setState(
      () {
        _errorMessage = message;
      },
    );
  }

  void _clearError() {
    if (_errorMessage ==
        null) {
      return;
    }

    setState(
      () {
        _errorMessage = null;
      },
    );
  }
}
