import 'package:flutter/material.dart';

import 'package:versin/modules/networking/tasks/controllers/project_tasks_controller.dart';
import 'package:versin/modules/networking/tasks/page/tasks_page_coordinator.dart';
import 'package:versin/modules/networking/tasks/page/tasks_page_view.dart';

// ============================================================
// TASKS VIEW
// ============================================================
//
// Composition root público da feature de produção.
//
// Preserva a API existente:
// - projectId
// - controller
//
// ============================================================

class TasksView extends StatefulWidget {
  final String projectId;
  final ProjectTasksController controller;

  const TasksView({
    super.key,
    required this.projectId,
    required this.controller,
  });

  @override
  State<TasksView> createState() => _TasksViewState();
}

class _TasksViewState extends State<TasksView> {
  late final TasksPageCoordinator _coordinator;

  @override
  void initState() {
    super.initState();

    _coordinator = TasksPageCoordinator(
      projectId: widget.projectId,
      controller: widget.controller,
    );
  }

  @override
  Widget build(BuildContext context) {
    return TasksPageView(
      projectId: _coordinator.projectId,
      controller: _coordinator.controller,
    );
  }

  @override
  void dispose() {
    _coordinator.dispose();

    super.dispose();
  }
}
