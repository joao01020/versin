import 'package:flutter/material.dart';

class RoyaltiesView
    extends
        StatelessWidget {
  final String projectId;
  const RoyaltiesView({
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
          "Royalties",
          style: TextStyle(
            fontSize: 16,
          ),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: const Center(
        child: Text(
          "Divisão de Porcentagens",
          style: TextStyle(
            color: Colors.white70,
          ),
        ),
      ),
    );
  }
}
