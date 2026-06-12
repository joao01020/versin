import 'package:flutter/material.dart';

class ChatView
    extends
        StatelessWidget {
  final String projectId;
  const ChatView({
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
          "Chat de Sessão",
          style: TextStyle(
            fontSize: 16,
          ),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: const Center(
        child: Text(
          "Histórico de mensagens",
          style: TextStyle(
            color: Colors.white70,
          ),
        ),
      ),
    );
  }
}
