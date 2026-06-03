import 'package:flutter/material.dart';

class CallView
    extends
        StatelessWidget {
  final String projectId;
  const CallView({
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
          "Áudio/Vídeo",
          style: TextStyle(
            fontSize: 16,
          ),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: const Center(
        child: Text(
          "Conexão de Voz Ativa",
          style: TextStyle(
            color: Colors.white70,
          ),
        ),
      ),
    );
  }
}
