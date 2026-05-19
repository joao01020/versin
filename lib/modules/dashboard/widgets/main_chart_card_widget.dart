import 'package:flutter/material.dart';
import '../controllers/dashboard_controller.dart';

/// [MainChartCardWidget] renders the mock statistical database chart bars.
/// [MainChartCardWidget] renderiza as barras do gráfico estatístico simulado do banco.
class MainChartCardWidget extends StatelessWidget {
  final DashboardController controller;

  const MainChartCardWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Estatísticas Versin", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          SizedBox(
            height: 150,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(12, (index) {
                double barHeight = (20 + (index * 12)) % 100 + 40;
                return Container(
                  width: 15,
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: index == 11 ? controller.accentNeon : controller.primaryPurple.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}