import 'dart:async';

import 'package:flutter/material.dart';

import 'package:versin/modules/dashboard/navigation/dashboard_bottom_navigation.dart';
import 'package:versin/modules/dashboard/navigation/dashboard_side_rail.dart';
import 'package:versin/modules/dashboard/page/dashboard_page_coordinator.dart';
import 'package:versin/modules/dashboard/page/navigation/dashboard_page_modules.dart';
import 'package:versin/modules/dashboard/page/widgets/dashboard_global_overlays.dart';
import 'package:versin/modules/dashboard/widgets/dashboard_header_widget.dart';

// ============================================================
// DASHBOARD PAGE VIEW
// ============================================================
//
// Somente shell visual:
//
// - desktop/mobile;
// - SideRail;
// - BottomNavigation;
// - Header;
// - PageView;
// - overlays globais.
//
// Não cria controller/service.
// Não acessa Supabase.
// Não monta repositório de IA.
//
// ============================================================

class DashboardPageView extends StatelessWidget {
  final DashboardPageCoordinator coordinator;

  const DashboardPageView({super.key, required this.coordinator});

  @override
  Widget build(BuildContext context) {
    final dashboardController = coordinator.dashboardController;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;

        final locked = coordinator.requiresDisplayName;

        return Scaffold(
          backgroundColor: Colors.black,
          bottomNavigationBar: isMobile
              ? IgnorePointer(
                  ignoring: locked,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 180),
                    opacity: locked ? 0.28 : 1.0,
                    child: DashboardBottomNavigation(
                      controller: dashboardController,
                      items: coordinator.visibleMenuItems,
                      currentVisibleIndex: coordinator.visibleCurrentIndex,
                      onTap: (visibleIndex) {
                        coordinator.onNavigationTap(context, visibleIndex);
                      },
                    ),
                  ),
                )
              : null,
          body: _buildBody(context: context, isMobile: isMobile),
        );
      },
    );
  }

  Widget _buildBody({required BuildContext context, required bool isMobile}) {
    final dashboardController = coordinator.dashboardController;

    final locked = coordinator.requiresDisplayName;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2E1A47),
            dashboardController.deepBg,
            Colors.black,
          ],
        ),
      ),
      child: Row(
        children: [
          if (!isMobile)
            IgnorePointer(
              ignoring: locked,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: locked ? 0.28 : 1.0,
                child: DashboardSideRail(
                  controller: dashboardController,
                  items: coordinator.visibleMenuItems,
                  currentVisibleIndex: coordinator.visibleCurrentIndex,
                  onTap: (visibleIndex) {
                    coordinator.onNavigationTap(context, visibleIndex);
                  },
                ),
              ),
            ),
          Expanded(
            child: Stack(
              children: [
                SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DashboardHeaderWidget(controller: dashboardController),
                      Expanded(child: _buildPageView(context)),
                    ],
                  ),
                ),
                if (!locked)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: DashboardGlobalOverlays(
                      invitationController: coordinator.invitationController,
                      globalCallController: coordinator.globalCallController,
                      globalChatController: coordinator.globalChatController,
                      canInteract: () {
                        return coordinator.canInteract(context);
                      },
                      onOpenProject: (projectId) {
                        return coordinator.openInvitedProject(
                          context,
                          projectId,
                        );
                      },
                      onOpenCall: (projectId) {
                        return coordinator.openCall(context, projectId);
                      },
                      onOpenChat: (projectId) {
                        return coordinator.openGlobalChat(context, projectId);
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageView(BuildContext context) {
    final dashboardController = coordinator.dashboardController;

    return PageView(
      controller: dashboardController.pageController,
      physics: const NeverScrollableScrollPhysics(),
      onPageChanged: coordinator.onPageChanged,
      children: DashboardPageModules.build(
        dashboardController: dashboardController,
        rhymesController: coordinator.rhymesController,
        onOpenCalendar: () {
          unawaited(coordinator.openCalendar(context));
        },
      ),
    );
  }
}
