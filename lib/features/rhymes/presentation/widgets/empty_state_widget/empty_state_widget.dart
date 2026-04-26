import 'package:flutter/material.dart';

class VersinEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const VersinEmptyState({
    super.key,
    this.title = "ESPERANDO ARQUIVOS",
    this.subtitle = "Nenhum dado encontrado por aqui.",
    this.icon = Icons.cloud_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white10, width: 1),
            ),
            child: Icon(icon, size: 40, color: Colors.white12),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white12,
              letterSpacing: 4,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white10, fontSize: 10),
          ),
        ],
      ),
    );
  }
}