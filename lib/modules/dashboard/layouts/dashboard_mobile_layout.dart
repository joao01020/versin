import 'package:flutter/material.dart';

import 'package:versin/features/rhymes/presentation/controller/rhymes_controller.dart';

import '../controllers/dashboard_controller.dart';
import '../account/widgets/account_activities_card_widget.dart';
import '../ai/widgets/ai_monthly_usage_card_widget.dart';
import '../widgets/hub_status_card_widget.dart';
import '../widgets/versin_statistics_card_widget.dart';

// ============================================================
// DASHBOARD MOBILE LAYOUT
// ============================================================
//
// Layout da Home do Dashboard para telas menores.
//
// Ordem:
//
// Perfil
//   ↓
// IA mensal
//   ↓
// Versin Hub
//   ↓
// Estatísticas Versin
//
// ============================================================

class DashboardMobileLayout
    extends
        StatelessWidget {
  final DashboardController controller;

  final RhymesController rhymesController;

  const DashboardMobileLayout({
    super.key,
    required this.controller,
    required this.rhymesController,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Column(
      children: [
        // ======================================================
        // PERFIL
        // ======================================================
        AccountActivitiesCardWidget(
          controller: controller,
          onStateChanged: () {},
        ),

        const SizedBox(
          height: 16,
        ),

        // ======================================================
        // IA MENSAL
        // ======================================================
        AnimatedBuilder(
          animation: rhymesController,
          builder:
              (
                context,
                _,
              ) {
                return AiMonthlyUsageCardWidget(
                  controller: rhymesController,
                );
              },
        ),

        const SizedBox(
          height: 20,
        ),

        // ======================================================
        // VERSIN HUB
        // ======================================================
        HubStatusCardWidget(
          controller: controller,
        ),

        const SizedBox(
          height: 16,
        ),

        // ======================================================
        // ESTATÍSTICAS VERSIN
        // ======================================================
        VersinStatisticsCardWidget(
          controller: controller,
        ),
      ],
    );
  }
}
