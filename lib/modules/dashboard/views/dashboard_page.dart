import 'package:flutter/material.dart';

import 'package:versin/app/locator.dart';
import 'package:versin/features/rhymes/presentation/controller/rhymes_controller.dart';

// ============================================================
// DASHBOARD
// ============================================================

import '../config/dashboard_menu_config.dart';
import '../controllers/dashboard_controller.dart';
import '../layouts/dashboard_home_layout.dart';
import '../navigation/dashboard_bottom_navigation.dart';
import '../navigation/dashboard_navigation.dart';
import '../navigation/dashboard_side_rail.dart';
import '../widgets/dashboard_header_widget.dart';

// ============================================================
// ECOSSISTEMA
// ============================================================

import 'package:versin/modules/calendar/views/calendar_page.dart';
import 'package:versin/modules/chat/views/chat_page.dart';
import 'package:versin/modules/hub/views/hub_page.dart';
import 'package:versin/modules/market/market_page.dart';
import 'package:versin/modules/match/views/match_page.dart';
import 'package:versin/modules/settings/views/settings_page.dart';
import 'package:versin/modules/storage/views/storage_page.dart';
import 'package:versin/modules/studio/views/studio_page.dart';
import 'package:versin/modules/vnode/vnode_page.dart';
import 'package:versin/modules/wallet/views/wallet_page.dart';

// ============================================================
// DASHBOARD PAGE
// ============================================================
//
// Responsabilidade:
//
// - obter controllers;
// - orquestrar navegação;
// - montar shell principal;
// - manter PageView dos módulos;
// - delegar UI para componentes especializados.
//
// Não contém:
//
// - configuração dos menus;
// - model de menu;
// - desenho do SideRail;
// - desenho da BottomNavigation;
// - layout da Home;
// - formulário de compromisso.
//
// ============================================================

class DashboardPage
    extends
        StatefulWidget {
  static const String routeName = '/';

  const DashboardPage({
    super.key,
  });

  @override
  State<
    DashboardPage
  >
  createState() => _DashboardPageState();
}

// ============================================================
// STATE
// ============================================================

class _DashboardPageState
    extends
        State<
          DashboardPage
        > {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final DashboardController _controller =
      sl<
        DashboardController
      >();

  final RhymesController _rhymesController =
      sl<
        RhymesController
      >();

  // ============================================================
  // MENUS VISÍVEIS
  // ============================================================

  get _visibleMenuItems => DashboardMenuConfig.visibleItems;

  // ============================================================
  // ÍNDICE VISÍVEL ATUAL
  // ============================================================

  int get _visibleCurrentIndex {
    return DashboardNavigation.visibleIndexFromOriginalIndex(
      items: DashboardMenuConfig.items,
      originalIndex: _controller.currentIndex,
    );
  }

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _controller.init();
  }

  // ============================================================
  // NAVEGAÇÃO
  // ============================================================

  void _onNavigationTap(
    int visibleIndex,
  ) {
    final originalIndex = DashboardNavigation.originalIndexFromVisibleIndex(
      items: DashboardMenuConfig.items,
      visibleIndex: visibleIndex,
    );

    if (originalIndex ==
        null) {
      return;
    }

    setState(
      () {
        _controller.navigationTap(
          originalIndex,
        );
      },
    );
  }

  // ============================================================
  // ABRIR CALENDÁRIO
  // ============================================================
  //
  // O antigo AddAppointmentSheet foi removido deste fluxo.
  //
  // A criação de tarefas e compromissos agora fica centralizada
  // no módulo Calendar.
  //
  // ============================================================

  Future<
    void
  >
  _openCalendarPage() async {
    if (!mounted) {
      return;
    }

    await Navigator.of(
      context,
    ).push(
      MaterialPageRoute(
        builder:
            (
              _,
            ) {
              return const CalendarPage();
            },
      ),
    );

    if (!mounted) {
      return;
    }

    setState(
      () {},
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return LayoutBuilder(
      builder:
          (
            context,
            constraints,
          ) {
            final isMobile =
                constraints.maxWidth <
                800;

            return Scaffold(
              backgroundColor: Colors.black,

              // ====================================================
              // NAVEGAÇÃO MOBILE
              // ====================================================
              bottomNavigationBar: isMobile
                  ? DashboardBottomNavigation(
                      controller: _controller,
                      items: _visibleMenuItems,
                      currentVisibleIndex: _visibleCurrentIndex,
                      onTap: _onNavigationTap,
                    )
                  : null,

              // ====================================================
              // BODY
              // ====================================================
              body: _buildBody(
                isMobile: isMobile,
              ),
            );
          },
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody({
    required bool isMobile,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(
              0xFF2E1A47,
            ),

            _controller.deepBg,

            Colors.black,
          ],
        ),
      ),
      child: Row(
        children: [
          // ====================================================
          // MENU DESKTOP
          // ====================================================
          if (!isMobile)
            DashboardSideRail(
              controller: _controller,
              items: _visibleMenuItems,
              currentVisibleIndex: _visibleCurrentIndex,
              onTap: _onNavigationTap,
            ),

          // ====================================================
          // CONTEÚDO
          // ====================================================
          Expanded(
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ============================================
                  // HEADER
                  // ============================================
                  DashboardHeaderWidget(
                    controller: _controller,
                  ),

                  // ============================================
                  // MÓDULOS
                  // ============================================
                  Expanded(
                    child: _buildPageView(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PAGE VIEW
  // ============================================================
  //
  // IMPORTANTE:
  //
  // Preserve esta ordem.
  //
  // 0 = Dashboard
  // 1 = Match
  // 2 = Market
  // 3 = Wallet
  // 4 = IA / Chat
  // 5 = Storage
  // 6 = Hub
  // 7 = VNode
  // 8 = Settings
  // 9 = Studio
  //
  // Os itens ocultos continuam no PageView para preservar os
  // índices usados pelo DashboardController.
  //
  // ============================================================

  Widget _buildPageView() {
    return PageView(
      controller: _controller.pageController,

      physics: const NeverScrollableScrollPhysics(),

      onPageChanged:
          (
            index,
          ) {
            if (!mounted) {
              return;
            }

            setState(
              () {
                _controller.handlePageChange(
                  index,
                );
              },
            );
          },

      children: [
        // ======================================================
        // 0 — DASHBOARD
        // ======================================================
        DashboardHomeLayout(
          controller: _controller,
          rhymesController: _rhymesController,
          onAddAppointment: () {
            _openCalendarPage();
          },
        ),

        // ======================================================
        // 1 — CONECTAR
        // ======================================================
        const MatchPage(),

        // ======================================================
        // 2 — MERCADO
        // ======================================================
        //
        // Continua existindo mesmo quando oculto do menu.
        //
        // ======================================================
        MarketPage(),

        // ======================================================
        // 3 — CARTEIRA
        // ======================================================
        const WalletPage(),

        // ======================================================
        // 4 — IA
        // ======================================================
        const ChatPage(),

        // ======================================================
        // 5 — ARMAZENAR
        // ======================================================
        StoragePage(),

        // ======================================================
        // 6 — HUB
        // ======================================================
        const HubPage(),

        // ======================================================
        // 7 — VNODE
        // ======================================================
        //
        // Continua existindo mesmo quando oculto do menu.
        //
        // ======================================================
        VNodePage(),

        // ======================================================
        // 8 — AJUSTES
        // ======================================================
        SettingsPage(),

        // ======================================================
        // 9 — STUDIO
        // ======================================================
        const StudioPage(),
      ],
    );
  }
}
