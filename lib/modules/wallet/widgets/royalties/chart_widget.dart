import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:versin/app/locator.dart';
import '../../controllers/royalties_controller.dart';

class RoyaltyChartWidget extends StatelessWidget {
  const RoyaltyChartWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Acessa a instância global do controller via GetIt
    final controller = sl<RoyaltiesController>();

    // 1. Tratamento de Loading: Exibe um indicador sutil enquanto aguarda os dados
    if (controller.isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: controller.primaryPurple,
          strokeWidth: 2,
        ),
      );
    }

    // 2. Gráfico de Linha: Configurado com os dados dinâmicos do controller
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => controller.primaryPurple,
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            // Utiliza o getter revenueHistory definido no RoyaltiesController
            spots: controller.revenueHistory.isNotEmpty 
                ? controller.revenueHistory 
                : const [FlSpot(0, 0), FlSpot(5, 0)],
            
            isCurved: true,
            color: controller.accentNeon,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            
            // Gradiente moderno abaixo da linha para efeito visual
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  controller.accentNeon.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}