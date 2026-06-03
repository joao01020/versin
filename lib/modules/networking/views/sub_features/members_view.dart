import 'package:flutter/material.dart';

class MembersView
    extends
        StatelessWidget {
  final String projectId;
  const MembersView({
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
          "Membros",
          style: TextStyle(
            fontSize: 16,
          ),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: const Center(
        child: Text(
          "Gestão de Colaboradores",
          style: TextStyle(
            color: Colors.white70,
          ),
        ),
      ),
    );
  }
}
