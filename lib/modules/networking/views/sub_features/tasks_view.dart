import 'package:flutter/material.dart';

class TasksView
    extends
        StatelessWidget {
  final String projectId;
  const TasksView({
    super.key,
    required this.projectId,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: const Color(
        0xFF0F0F0F,
      ),
      appBar: AppBar(
        title: const Text(
          "Tarefas",
          style: TextStyle(
            fontSize: 16,
          ),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: const Center(
        child: Text(
          "Lista de Tarefas do Projeto",
          style: TextStyle(
            color: Colors.white70,
          ),
        ),
      ),
    );
  }
}
