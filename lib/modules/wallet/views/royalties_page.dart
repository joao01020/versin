import 'package:flutter/material.dart';
import 'package:versin/app/locator.dart';
import '../controllers/royalties_controller.dart';
import 'package:versin/modules/wallet/widgets/royalties/revenue_card.dart';

class RoyaltiesPage extends StatelessWidget {
  const RoyaltiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Acessa a instância global do controller via GetIt (locator)
    final controller = sl<RoyaltiesController>();

    return Scaffold(
      backgroundColor: controller.deepBg,
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          // Exibe loader centralizado enquanto o controller busca dados no banco
          if (controller.isLoading) {
            return Center(
              child: CircularProgressIndicator(color: controller.accentNeon),
            );
          }

          // Grid com 3 colunas exibindo os dados financeiros
          return GridView.count(
            crossAxisCount: 3,
            padding: const EdgeInsets.all(24),
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            children: [
              // Cards informativos com dados dinâmicos
              _buildGlassCard("Revenue", "R\$ ${controller.totalRevenue.toStringAsFixed(2)}", controller),
              _buildGlassCard("Monthly Revenue", "R\$ ${controller.monthlyRevenue.toStringAsFixed(2)}", controller),
              _buildGlassCard("Total Streams", "${controller.totalStreams}", controller),
              
              // RevenueCard injetado dinamicamente (removido o 'const' para corrigir o erro de compilação)
              RevenueCard(),
            ],
          );
        },
      ),
    );
  }

  /// Método auxiliar para criar os cards com efeito Glassmorphism
  Widget _buildGlassCard(String title, String value, RoyaltiesController controller) {
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title, 
              style: const TextStyle(color: Colors.white54, fontSize: 14)
            ),
            const SizedBox(height: 10),
            Text(
              value, 
              style: const TextStyle(
                color: Colors.white, 
                fontSize: 32, 
                fontWeight: FontWeight.bold
              )
            ),
          ],
        ),
      ),
    );
  }
}