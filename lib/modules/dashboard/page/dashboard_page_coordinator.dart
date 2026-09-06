import 'dart:async';

import 'package:flutter/material.dart';

import 'package:versin/app/locator.dart';
import 'package:versin/features/rhymes/presentation/controller/rhymes_controller.dart';

import 'package:versin/modules/calendar/views/calendar_page.dart';

import 'package:versin/modules/dashboard/config/menu/dashboard_menu_config.dart';
import 'package:versin/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:versin/modules/dashboard/global_call/controllers/dashboard_global_call_controller.dart';
import 'package:versin/modules/dashboard/global_chat/controllers/dashboard_global_chat_controller.dart';
import 'package:versin/modules/dashboard/invitations/controllers/dashboard_invitation_controller.dart';
import 'package:versin/modules/dashboard/navigation/dashboard_navigation.dart';
import 'package:versin/modules/dashboard/page/services/dashboard_ai_quota_refresher.dart';

import 'package:versin/modules/networking/call/views/call_view.dart';
import 'package:versin/modules/networking/chat/views/chat_view.dart';
import 'package:versin/modules/networking/views/networking_session_view.dart';

// ============================================================
// DASHBOARD PAGE COORDINATOR
// ============================================================
//
// Orquestra o shell principal.
//
// Responsabilidades:
//
// - controllers da página;
// - inicialização;
// - regra do onboarding obrigatório;
// - conversão dos índices de navegação;
// - abertura de páginas externas ao PageView;
// - quota de IA em background;
// - lifecycle dos controllers criados pela página.
//
// NÃO desenha UI.
//
// ============================================================

class DashboardPageCoordinator extends ChangeNotifier {
  // ============================================================
  // SHARED CONTROLLERS
  // ============================================================

  final DashboardController dashboardController = sl<DashboardController>();

  final RhymesController rhymesController = sl<RhymesController>();

  // ============================================================
  // PAGE-OWNED CONTROLLERS
  // ============================================================

  late final DashboardGlobalChatController globalChatController;

  late final DashboardGlobalCallController globalCallController;

  late final DashboardInvitationController invitationController;

  late final DashboardAiQuotaRefresher _aiQuotaRefresher;

  bool _initialized = false;
  bool _disposed = false;

  DashboardPageCoordinator() {
    globalChatController = DashboardGlobalChatController()..init();

    globalCallController = DashboardGlobalCallController()..init();

    invitationController = DashboardInvitationController();

    _aiQuotaRefresher = DashboardAiQuotaRefresher(
      rhymesController: rhymesController,
    );

    dashboardController.addListener(_relayDashboardState);
  }

  // ============================================================
  // DERIVED STATE
  // ============================================================

  get visibleMenuItems => DashboardMenuConfig.visibleItems;

  bool get requiresDisplayName {
    if (!dashboardController.artistNameResolved) {
      return false;
    }

    final value = dashboardController.artistName.trim();

    return value.isEmpty || value == 'Membro';
  }

  int get visibleCurrentIndex {
    return DashboardNavigation.visibleIndexFromOriginalIndex(
      items: DashboardMenuConfig.items,
      originalIndex: dashboardController.currentIndex,
    );
  }

  // ============================================================
  // INITIALIZE
  // ============================================================

  void initialize() {
    if (_initialized || _disposed) {
      return;
    }

    _initialized = true;

    unawaited(_initializeAsync());

    unawaited(invitationController.init());
  }

  Future<void> _initializeAsync() async {
    await dashboardController.init();

    if (_disposed) {
      return;
    }

    if (requiresDisplayName &&
        dashboardController.currentIndex !=
            DashboardMenuConfig.dashboardIndex) {
      dashboardController.navigationTap(DashboardMenuConfig.dashboardIndex);
    }

    notifyListeners();

    // Não bloqueia a abertura do Dashboard.
    unawaited(_aiQuotaRefresher.refresh());
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  void onNavigationTap(BuildContext context, int visibleIndex) {
    if (requiresDisplayName) {
      showCompleteNameMessage(context);

      return;
    }

    final originalIndex = DashboardNavigation.originalIndexFromVisibleIndex(
      items: DashboardMenuConfig.items,
      visibleIndex: visibleIndex,
    );

    if (originalIndex == null) {
      return;
    }

    dashboardController.navigationTap(originalIndex);
  }

  void onPageChanged(int index) {
    if (_disposed) {
      return;
    }

    if (requiresDisplayName && index != DashboardMenuConfig.dashboardIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_disposed) {
          return;
        }

        dashboardController.navigationTap(DashboardMenuConfig.dashboardIndex);
      });

      return;
    }

    dashboardController.handlePageChange(index);
  }

  // ============================================================
  // INTERACTION GUARD
  // ============================================================

  bool canInteract(BuildContext context) {
    if (!requiresDisplayName) {
      return true;
    }

    showCompleteNameMessage(context);

    return false;
  }

  void showCompleteNameMessage(BuildContext context) {
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Defina seu nome para liberar o restante do aplicativo.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // CALENDAR
  // ============================================================

  Future<void> openCalendar(BuildContext context) async {
    if (!canInteract(context)) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) {
          return const CalendarPage();
        },
      ),
    );

    if (_disposed || !context.mounted) {
      return;
    }

    notifyListeners();
  }

  // ============================================================
  // INVITED PROJECT
  // ============================================================

  Future<void> openInvitedProject(
    BuildContext context,
    String projectId,
  ) async {
    if (!canInteract(context)) {
      return;
    }

    final normalizedProjectId = projectId.trim();

    if (!context.mounted || normalizedProjectId.isEmpty) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) {
          return NetworkingSessionView(projectId: normalizedProjectId);
        },
      ),
    );
  }

  // ============================================================
  // GLOBAL CHAT
  // ============================================================

  Future<void> openGlobalChat(BuildContext context, String projectId) async {
    if (!canInteract(context)) {
      return;
    }

    final normalizedProjectId = projectId.trim();

    if (!context.mounted || normalizedProjectId.isEmpty) {
      return;
    }

    final prepared = globalChatController.prepareOpen(normalizedProjectId);

    if (!prepared) {
      return;
    }

    try {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) {
            return ChatView(projectId: normalizedProjectId);
          },
        ),
      );
    } finally {
      globalChatController.finishOpen();
    }
  }

  // ============================================================
  // GLOBAL CALL
  // ============================================================

  Future<void> openCall(BuildContext context, String projectId) async {
    if (!canInteract(context)) {
      return;
    }

    final normalizedProjectId = projectId.trim();

    if (!context.mounted || normalizedProjectId.isEmpty) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) {
          return CallView(projectId: normalizedProjectId);
        },
      ),
    );
  }

  // ============================================================
  // DASHBOARD LISTENER
  // ============================================================

  void _relayDashboardState() {
    if (_disposed) {
      return;
    }

    notifyListeners();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    if (_disposed) {
      return;
    }

    _disposed = true;

    dashboardController.removeListener(_relayDashboardState);

    // Estes três são criados pelo coordinator
    // e pertencem ao lifecycle da DashboardPage.
    globalChatController.dispose();
    globalCallController.dispose();
    invitationController.dispose();

    // DashboardController e RhymesController
    // são compartilhados pelo locator.
    // NÃO fazemos dispose deles aqui.

    super.dispose();
  }
}
