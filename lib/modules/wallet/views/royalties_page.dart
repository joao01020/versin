import 'package:flutter/material.dart';
import 'package:versin/app/locator.dart';
import 'package:versin/modules/wallet/widgets/royalties/revenue_card.dart';

import '../controllers/royalties_controller.dart';

class RoyaltiesPage
    extends
        StatelessWidget {
  const RoyaltiesPage({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    // ============================================================
    // CONTROLLER
    // ============================================================

    final controller =
        sl<
          RoyaltiesController
        >();

    return Scaffold(
      backgroundColor: controller.deepBg,

      body: ListenableBuilder(
        listenable: controller,

        builder:
            (
              context,
              _,
            ) {
              // ======================================================
              // LOADING
              // ======================================================

              if (controller.isLoading) {
                return Center(
                  child: CircularProgressIndicator(
                    color: controller.accentNeon,
                  ),
                );
              }

              // ======================================================
              // GRID
              // ======================================================

              return GridView.count(
                crossAxisCount: 3,

                padding: const EdgeInsets.all(
                  24,
                ),

                mainAxisSpacing: 20,

                crossAxisSpacing: 20,

                children: [
                  // ==================================================
                  // RECEITA TOTAL
                  // ==================================================
                  _buildGlassCard(
                    "Revenue",
                    "R\$ ${controller.totalRevenue.toStringAsFixed(2)}",
                    controller,
                  ),

                  // ==================================================
                  // RECEITA MENSAL
                  // ==================================================
                  _buildGlassCard(
                    "Monthly Revenue",
                    "R\$ ${controller.monthlyRevenue.toStringAsFixed(2)}",
                    controller,
                  ),

                  // ==================================================
                  // TOTAL DE STREAMS
                  // ==================================================
                  _buildGlassCard(
                    "Total Streams",
                    "${controller.totalStreams}",
                    controller,
                  ),

                  // ==================================================
                  // REVENUE CARD
                  // ==================================================
                  RevenueCard(),
                ],
              );
            },
      ),
    );
  }

  // ============================================================
  // GLASS CARD
  // ============================================================

  Widget _buildGlassCard(
    String title,
    String value,
    RoyaltiesController controller,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: controller.cardBg,

        borderRadius: BorderRadius.circular(
          24,
        ),

        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.05,
          ),
        ),
      ),

      child: Padding(
        padding: const EdgeInsets.all(
          24,
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            // ====================================================
            // TÍTULO
            // ====================================================
            Text(
              title,

              style: const TextStyle(
                color: Colors.white54,

                fontSize: 14,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            // ====================================================
            // VALOR
            // ====================================================
            Text(
              value,

              style: const TextStyle(
                color: Colors.white,

                fontSize: 32,

                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
