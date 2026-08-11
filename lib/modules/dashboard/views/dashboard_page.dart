import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:versin/app/locator.dart';
import 'package:versin/app/routes/app_routes.dart';

import '../controllers/dashboard_controller.dart';
import '../widgets/dashboard_header_widget.dart';
import '../widgets/account_activities_card_widget.dart';
import '../widgets/hub_status_card_widget.dart';
import '../widgets/main_chart_card_widget.dart';
import '../widgets/calendar_card_widget.dart';

// ============================================================
// ECOSSISTEMA
// ============================================================

import 'package:versin/modules/chat/views/chat_page.dart';
import 'package:versin/modules/hub/views/hub_page.dart';
import 'package:versin/modules/match/views/match_page.dart';
import 'package:versin/modules/wallet/views/wallet_page.dart';
import 'package:versin/modules/market/market_page.dart';
import 'package:versin/modules/showcase/showcase_page.dart';
import 'package:versin/modules/vnode/vnode_page.dart';
import 'package:versin/modules/settings/settings_page.dart';
import 'package:versin/modules/studio/views/studio_page.dart';

// ============================================================
// CONFIGURAÇÃO DE VISIBILIDADE DOS MENUS
// ============================================================
//
// true  = aparece no menu
// false = continua existindo, mas fica oculto
//
// Para reativar Market futuramente:
//
// static const bool showMarket = true;
//
// ============================================================

class DashboardMenuVisibility {
  static const bool showDashboard = true;
  static const bool showMatch = true;

  // OCULTO
  static const bool showMarket = false;

  static const bool showWallet = true;
  static const bool showStudio = true;
  static const bool showShowcase = true;
  static const bool showHub = true;

  // OCULTO
  static const bool showVNode = false;

  static const bool showSettings = true;
}

// ============================================================
// MODEL INTERNO DO MENU
// ============================================================

class _DashboardMenuItem {
  final int originalIndex;
  final String label;
  final IconData icon;
  final String route;
  final bool visible;

  const _DashboardMenuItem({
    required this.originalIndex,
    required this.label,
    required this.icon,
    required this.route,
    required this.visible,
  });
}

// ============================================================
// DASHBOARD PAGE
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

class _DashboardPageState
    extends
        State<
          DashboardPage
        > {
  final DashboardController _controller =
      sl<
        DashboardController
      >();

  // ============================================================
  // TODOS OS MENUS
  // ============================================================

  final List<
    _DashboardMenuItem
  >
  _menuItems = const [
    _DashboardMenuItem(
      originalIndex: 0,
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      route: '/',
      visible: DashboardMenuVisibility.showDashboard,
    ),

    // ==========================================================
    // STUDIO
    // Página interna do Dashboard, igual ao Match.
    // Índice 9 para preservar todos os índices antigos.
    // ==========================================================
    _DashboardMenuItem(
      originalIndex: 9,
      label: 'Studio',
      icon: Icons.edit_note_rounded,
      route: '',
      visible: DashboardMenuVisibility.showStudio,
    ),

    _DashboardMenuItem(
      originalIndex: 4,
      label: 'Chat',
      icon: Icons.chat_bubble_outline_rounded,
      route: AppRoutes.chat,
      visible: true,
    ),

    _DashboardMenuItem(
      originalIndex: 1,
      label: 'Match',
      icon: Icons.share_outlined,
      route: AppRoutes.match,
      visible: DashboardMenuVisibility.showMatch,
    ),

    _DashboardMenuItem(
      originalIndex: 2,
      label: 'Market',
      icon: Icons.local_mall_outlined,
      route: AppRoutes.market,
      visible: DashboardMenuVisibility.showMarket,
    ),

    _DashboardMenuItem(
      originalIndex: 3,
      label: 'Wallet',
      icon: Icons.account_balance_wallet_outlined,
      route: AppRoutes.wallet,
      visible: DashboardMenuVisibility.showWallet,
    ),

    _DashboardMenuItem(
      originalIndex: 5,
      label: 'Showcase',
      icon: Icons.storefront_outlined,
      route: AppRoutes.showcase,
      visible: DashboardMenuVisibility.showShowcase,
    ),

    _DashboardMenuItem(
      originalIndex: 6,
      label: 'Hub',
      icon: Icons.settings_input_component,
      route: AppRoutes.hub,
      visible: DashboardMenuVisibility.showHub,
    ),

    _DashboardMenuItem(
      originalIndex: 7,
      label: 'VNode Network',
      icon: Icons.lan_outlined,
      route: AppRoutes.vnode,
      visible: DashboardMenuVisibility.showVNode,
    ),

    _DashboardMenuItem(
      originalIndex: 8,
      label: 'Settings',
      icon: Icons.settings_outlined,
      route: AppRoutes.settings,
      visible: DashboardMenuVisibility.showSettings,
    ),
  ];

  // ============================================================
  // MENUS VISÍVEIS
  // ============================================================

  List<
    _DashboardMenuItem
  >
  get _visibleMenuItems {
    return _menuItems
        .where(
          (
            item,
          ) => item.visible,
        )
        .toList();
  }

  // ============================================================
  // ÍNDICE VISÍVEL ATUAL
  // ============================================================

  int get _visibleCurrentIndex {
    final visibleItems = _visibleMenuItems;

    final index = visibleItems.indexWhere(
      (
        item,
      ) =>
          item.originalIndex ==
          _controller.currentIndex,
    );

    if (index ==
        -1) {
      return 0;
    }

    return index;
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
    final visibleItems = _visibleMenuItems;

    if (visibleIndex <
            0 ||
        visibleIndex >=
            visibleItems.length) {
      return;
    }

    final item = visibleItems[visibleIndex];

    // ==========================================================
    // DEMAIS MENUS
    // ==========================================================
    //
    // Não usamos mais pushNamed aqui.
    // A navegação acontece dentro do próprio PageView do Dashboard,
    // mantendo o menu lateral visível e permitindo voltar clicando
    // novamente em Dashboard ou em qualquer outro módulo.
    //
    // ==========================================================

    final originalIndex = item.originalIndex;

    setState(
      () {
        _controller.navigationTap(
          originalIndex,
        );
      },
    );
  }

  // ============================================================
  // COMPROMISSO
  // ============================================================

  void _showAddAppointmentSheet({
    String? fixedTime,
  }) {
    final TextEditingController titleController = TextEditingController();

    final now = DateTime.now();

    final String defaultTime =
        fixedTime ??
        '${now.hour.toString().padLeft(2, '0')}:'
            '${now.minute.toString().padLeft(2, '0')}';

    final TextEditingController timeController = TextEditingController(
      text: defaultTime,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(
        0xFF15122C,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(
            24,
          ),
        ),
      ),
      builder:
          (
            context,
          ) {
            return Padding(
              padding: EdgeInsets.only(
                bottom:
                    MediaQuery.of(
                      context,
                    ).viewInsets.bottom +
                    24,
                top: 24,
                left: 24,
                right: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ==================================================
                  // HEADER
                  // ==================================================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'NOVO COMPROMISSO - DIA '
                        '${_controller.selectedDay}/'
                        '${_controller.focusedDay.month}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),

                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white54,
                          size: 20,
                        ),
                        onPressed: () {
                          Navigator.pop(
                            context,
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  // ==================================================
                  // DESCRIÇÃO
                  // ==================================================
                  TextField(
                    controller: titleController,
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withOpacity(
                        0.05,
                      ),
                      hintText: 'Descrição do compromisso',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          12,
                        ),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  // ==================================================
                  // HORÁRIO
                  // ==================================================
                  TextField(
                    controller: timeController,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withOpacity(
                        0.05,
                      ),
                      hintText: 'Horário (HH:MM)',
                      prefixIcon: const Icon(
                        Icons.access_time,
                        color: Colors.white38,
                        size: 18,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          12,
                        ),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  // ==================================================
                  // AGENDAR
                  // ==================================================
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _controller.accentNeon,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            12,
                          ),
                        ),
                      ),
                      onPressed: () {
                        if (titleController.text.isEmpty ||
                            timeController.text.isEmpty) {
                          return;
                        }

                        setState(
                          () {
                            _controller.addAppointment(
                              title: titleController.text,
                              time: timeController.text,
                            );
                          },
                        );

                        Navigator.pop(
                          context,
                        );
                      },
                      child: const Text(
                        'AGENDAR NO CHASSI',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
    ).whenComplete(
      () {
        titleController.dispose();
        timeController.dispose();
      },
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
            final bool isMobile =
                constraints.maxWidth <
                800;

            return Scaffold(
              backgroundColor: Colors.black,

              // ======================================================
              // MOBILE NAVIGATION
              // ======================================================
              bottomNavigationBar: isMobile
                  ? BottomNavigationBar(
                      currentIndex: _visibleCurrentIndex,
                      onTap: _onNavigationTap,
                      selectedItemColor: _controller.accentNeon,
                      unselectedItemColor: Colors.white24,
                      type: BottomNavigationBarType.fixed,
                      items: _visibleMenuItems.map(
                        (
                          item,
                        ) {
                          return BottomNavigationBarItem(
                            icon: Icon(
                              item.icon,
                            ),
                            label: _shortMobileLabel(
                              item.label,
                            ),
                          );
                        },
                      ).toList(),
                    )
                  : null,

              // ======================================================
              // BODY
              // ======================================================
              body: Container(
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
                    // =================================================
                    // MENU DESKTOP
                    // =================================================
                    if (!isMobile)
                      _DashboardSideRail(
                        controller: _controller,
                        items: _visibleMenuItems,
                        currentVisibleIndex: _visibleCurrentIndex,
                        onTap: _onNavigationTap,
                      ),

                    // =================================================
                    // CONTEÚDO
                    // =================================================
                    Expanded(
                      child: SafeArea(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DashboardHeaderWidget(
                              controller: _controller,
                            ),

                            Expanded(
                              child: PageView(
                                controller: _controller.pageController,

                                // Os módulos ocultos continuam
                                // existindo, porém o usuário não
                                // consegue navegar até eles por swipe.
                                physics: const NeverScrollableScrollPhysics(),

                                onPageChanged:
                                    (
                                      index,
                                    ) {
                                      setState(
                                        () {
                                          _controller.handlePageChange(
                                            index,
                                          );
                                        },
                                      );
                                    },
                                children: [
                                  DashboardLabPage(
                                    controller: _controller,
                                    onAddAppointment: _showAddAppointmentSheet,
                                  ),

                                  const MatchPage(),

                                  // MARKET CONTINUA EXISTINDO,
                                  // MAS ESTÁ OCULTO DOS MENUS.
                                  MarketPage(),

                                  const WalletPage(),

                                  const ChatPage(),

                                  ShowcasePage(),

                                  const HubPage(),

                                  // VNODE CONTINUA EXISTINDO,
                                  // MAS ESTÁ OCULTO DOS MENUS.
                                  VNodePage(),

                                  SettingsPage(),

                                  // =================================================
                                  // STUDIO — ÍNDICE 9
                                  // =================================================
                                  const StudioPage(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
    );
  }

  // ============================================================
  // LABEL MOBILE
  // ============================================================

  String _shortMobileLabel(
    String label,
  ) {
    switch (label) {
      case 'Dashboard':
        return 'Dash';

      case 'VNode Network':
        return 'VNode';

      default:
        return label;
    }
  }
}

// ============================================================
// MENU LATERAL DESKTOP
// ============================================================

class _DashboardSideRail
    extends
        StatelessWidget {
  final DashboardController controller;

  final List<
    _DashboardMenuItem
  >
  items;

  final int currentVisibleIndex;

  final ValueChanged<
    int
  >
  onTap;

  const _DashboardSideRail({
    required this.controller,
    required this.items,
    required this.currentVisibleIndex,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: 92,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(
          0.30,
        ),
        border: const Border(
          right: BorderSide(
            color: Colors.white10,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(
              height: 18,
            ),

            // ==================================================
            // LOGO
            // ==================================================
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: controller.accentNeon.withOpacity(
                  0.10,
                ),
                borderRadius: BorderRadius.circular(
                  14,
                ),
                border: Border.all(
                  color: controller.accentNeon.withOpacity(
                    0.25,
                  ),
                ),
              ),
              child: Icon(
                Icons.graphic_eq_rounded,
                color: controller.accentNeon,
              ),
            ),

            const SizedBox(
              height: 24,
            ),

            // ==================================================
            // MENUS
            // ==================================================
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  vertical: 4,
                ),
                itemCount: items.length,
                itemBuilder:
                    (
                      context,
                      index,
                    ) {
                      final item = items[index];

                      final selected =
                          index ==
                          currentVisibleIndex;

                      return Tooltip(
                        message: item.label,
                        child: InkWell(
                          onTap: () {
                            onTap(
                              index,
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(
                              milliseconds: 180,
                            ),
                            margin: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? controller.accentNeon.withOpacity(
                                      0.12,
                                    )
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(
                                12,
                              ),
                              border: Border.all(
                                color: selected
                                    ? controller.accentNeon.withOpacity(
                                        0.25,
                                      )
                                    : Colors.transparent,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  item.icon,
                                  color: selected
                                      ? controller.accentNeon
                                      : Colors.white38,
                                  size: 22,
                                ),

                                const SizedBox(
                                  height: 5,
                                ),

                                Text(
                                  _railLabel(
                                    item.label,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: selected
                                        ? controller.accentNeon
                                        : Colors.white38,
                                    fontSize: 9,
                                    fontWeight: selected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _railLabel(
    String label,
  ) {
    switch (label) {
      case 'Dashboard':
        return 'Dash';

      case 'VNode Network':
        return 'VNode';

      default:
        return label;
    }
  }
}

// ============================================================
// DASHBOARD HOME
// ============================================================

class DashboardLabPage
    extends
        StatelessWidget {
  final DashboardController controller;

  final VoidCallback onAddAppointment;

  const DashboardLabPage({
    super.key,
    required this.controller,
    required this.onAddAppointment,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final bool isMobile =
        MediaQuery.of(
          context,
        ).size.width <
        800;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
      ),
      child: Column(
        children: [
          const SizedBox(
            height: 10,
          ),

          // ======================================================
          // PROJETO ATIVO
          // ======================================================
          if (controller.hasActiveProject) ...[
            Container(
              padding: const EdgeInsets.all(
                16,
              ),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(
                  0.1,
                ),
                borderRadius: BorderRadius.circular(
                  16,
                ),
                border: Border.all(
                  color: Colors.green.withOpacity(
                    0.3,
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.fiber_manual_record,
                    color: Colors.green,
                    size: 12,
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  Text(
                    'Studio Session Ativa',
                    style: TextStyle(
                      color: Colors.green.shade300,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 16,
            ),
          ],

          // ======================================================
          // CARDS
          // ======================================================
          if (isMobile)
            Column(
              children: [
                AccountActivitiesCardWidget(
                  controller: controller,
                  onStateChanged: () {},
                ),

                const SizedBox(
                  height: 16,
                ),

                HubStatusCardWidget(
                  controller: controller,
                ),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AccountActivitiesCardWidget(
                    controller: controller,
                    onStateChanged: () {},
                  ),
                ),

                const SizedBox(
                  width: 16,
                ),

                Expanded(
                  child: HubStatusCardWidget(
                    controller: controller,
                  ),
                ),
              ],
            ),

          const SizedBox(
            height: 20,
          ),

          MainChartCardWidget(
            controller: controller,
          ),

          const SizedBox(
            height: 20,
          ),

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
