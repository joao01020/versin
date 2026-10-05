import 'package:flutter/foundation.dart';

import 'package:versin/modules/networking/tasks/controllers/project_tasks_controller.dart';

// ============================================================
// TASKS PAGE COORDINATOR
// ============================================================
//
// Mantém o contrato de entrada da página separado do Widget.
//
// O ProjectTasksController é fornecido pelo chamador e NÃO é
// owned por este coordinator.
//
// ============================================================

class TasksPageCoordinator extends ChangeNotifier {
  final String projectId;
  final ProjectTasksController controller;

  bool _disposed = false;

  TasksPageCoordinator({required this.projectId, required this.controller});

  @override
  void dispose() {
    if (_disposed) {
      return;
    }

    _disposed = true;

    // controller pertence ao chamador.
    // NÃO fazemos controller.dispose() aqui.

    super.dispose();
  }
}
