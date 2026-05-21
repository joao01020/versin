import 'package:flutter/material.dart';
import '../controllers/dashboard_controller.dart';

/// [DashboardHeaderWidget] renders the stylized uppercase dynamic page title.
/// [DashboardHeaderWidget] renderiza o título dinâmico estilizado da página em caixa alta.
class DashboardHeaderWidget extends StatelessWidget {
  final DashboardController controller;

  const DashboardHeaderWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            controller.getModuleTitle().toUpperCase(),
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.5),
          ),
          const SizedBox(height: 6),
          Container(height: 3, width: 30, color: controller.accentNeon),
        ],
      ),
    );
  }
}