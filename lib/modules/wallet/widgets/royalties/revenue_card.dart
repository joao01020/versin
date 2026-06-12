import 'package:flutter/material.dart';
import 'package:versin/app/locator.dart';
import '../../controllers/royalties_controller.dart';
import 'chart_widget.dart'; // Certifique-se de que este arquivo existe

class RevenueCard extends StatelessWidget {
  const RevenueCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = sl<RoyaltiesController>();

    // Proteção: Se estiver carregando, exibe um container vazio com o estilo do card
    // Isso evita o bloco vermelho e mantém o layout consistente.
    if (controller.isLoading) {
      return Container(
        decoration: BoxDecoration(
          color: controller.cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: controller.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Revenue Trends", style: TextStyle(color: Colors.white54, fontSize: 14)),
                Icon(Icons.trending_up, color: controller.accentNeon, size: 16),
              ],
            ),
            const SizedBox(height: 16),
            // O gráfico agora ocupa o espaço restante do card
            const Expanded(child: RoyaltyChartWidget()),
          ],
        ),
      ),
    );
  }
}