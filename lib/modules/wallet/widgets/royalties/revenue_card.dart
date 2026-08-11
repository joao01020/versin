import 'package:flutter/material.dart';
import 'package:versin/app/locator.dart';

import '../../controllers/royalties_controller.dart';
import 'chart_widget.dart';

class RevenueCard
    extends
        StatelessWidget {
  const RevenueCard({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final RoyaltiesController controller =
        sl<
          RoyaltiesController
        >();

    final borderColor = Colors.white.withValues(
      alpha: 0.05,
    );

    if (controller.isLoading) {
      return Container(
        decoration: BoxDecoration(
          color: controller.cardBg,
          borderRadius: BorderRadius.circular(
            24,
          ),
          border: Border.all(
            color: borderColor,
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: controller.cardBg,
        borderRadius: BorderRadius.circular(
          24,
        ),
        border: Border.all(
          color: borderColor,
        ),
      ),
      padding: const EdgeInsets.all(
        24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Revenue Trends',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                ),
              ),
              Icon(
                Icons.trending_up,
                color: controller.accentNeon,
                size: 16,
              ),
            ],
          ),

          const SizedBox(
            height: 16,
          ),

          const Expanded(
            child: RoyaltyChartWidget(),
          ),
        ],
      ),
    );
  }
}
