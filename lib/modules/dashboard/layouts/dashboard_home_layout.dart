import 'package:flutter/material.dart';

import 'package:versin/features/rhymes/presentation/controller/rhymes_controller.dart';

import '../controllers/dashboard_controller.dart';
import '../widgets/active_project_card_widget.dart';
import '../widgets/calendar_card_widget.dart';

import 'dashboard_desktop_layout.dart';
import 'dashboard_mobile_layout.dart';

// ============================================================
// DASHBOARD HOME LAYOUT
// ============================================================
//
// Orquestra a Home do Dashboard.
//
// Responsabilidades:
//
// - aplicar scroll;
// - detectar mobile / desktop;
// - escolher o layout responsivo;
// - posicionar projeto ativo;
// - posicionar calendário.
//
// IMPORTANTE:
//
// Este arquivo NÃO desenha diretamente:
//
// - projeto ativo;
// - perfil;
// - IA mensal;
// - Versin Hub;
// - Estatísticas Versin;
// - calendário.
//
// Cada componente visual possui seu próprio widget.
//
// Estrutura:
//
// DashboardHomeLayout
//        │
//        ├── ActiveProjectCardWidget
//        │
//        ├── DashboardMobileLayout
//        │          ou
//        │   DashboardDesktopLayout
//        │
//        └── CalendarCardWidget
//
// ============================================================

class DashboardHomeLayout
    extends
        StatelessWidget {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final DashboardController controller;

  final RhymesController rhymesController;

  // ============================================================
  // CALLBACKS
  // ============================================================

  final VoidCallback onAddAppointment;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  const DashboardHomeLayout({
    super.key,
    required this.controller,
    required this.rhymesController,
    required this.onAddAppointment,
  });

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    // ==========================================================
    // RESPONSIVIDADE
    // ==========================================================

    final screenWidth = MediaQuery.of(
      context,
    ).size.width;

    final isMobile =
        screenWidth <
        800;

    // ==========================================================
    // HOME
    // ==========================================================

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(
            height: 10,
          ),

          // ====================================================
          // PROJETO ATIVO
          // ====================================================
          if (controller.hasActiveProject) ...[
            ActiveProjectCardWidget(
              controller: controller,
            ),

            const SizedBox(
              height: 16,
            ),
          ],

          // ====================================================
          // CONTEÚDO PRINCIPAL
          // ====================================================
          if (isMobile)
            DashboardMobileLayout(
              controller: controller,
              rhymesController: rhymesController,
            )
          else
            DashboardDesktopLayout(
              controller: controller,
              rhymesController: rhymesController,
            ),

          const SizedBox(
            height: 20,
          ),

          // ====================================================
          // CALENDÁRIO
          // ====================================================
          CalendarCardWidget(
            controller: controller,
            onStateChanged: () {},
            onAddAppointmentTap: onAddAppointment,
          ),

          const SizedBox(
            height: 20,
          ),
        ],
      ),
    );
  }
}
