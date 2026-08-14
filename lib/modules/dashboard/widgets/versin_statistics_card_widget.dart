import 'package:flutter/material.dart';

import '../controllers/dashboard_controller.dart';

// ============================================================
// VERSIN STATISTICS CARD WIDGET
// ============================================================

class VersinStatisticsCardWidget
    extends
        StatelessWidget {
  final DashboardController controller;

  const VersinStatisticsCardWidget({
    super.key,
    required this.controller,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        24,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.05,
        ),
        borderRadius: BorderRadius.circular(
          24,
        ),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ====================================================
          // TÍTULO
          // ====================================================
          const Text(
            'Estatísticas Versin',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 30,
          ),

          // ====================================================
          // GRÁFICO
          // ====================================================
          SizedBox(
            height: 150,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(
                12,
                (
                  index,
                ) {
                  final barHeight =
                      (20 +
                              (index *
                                  12)) %
                          100 +
                      40.0;

                  return Container(
                    width: 15,
                    height: barHeight,
                    decoration: BoxDecoration(
                      color:
                          index ==
                              11
                          ? controller.accentNeon
                          : controller.primaryPurple.withValues(
                              alpha: 0.4,
                            ),
                      borderRadius: BorderRadius.circular(
                        4,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
