import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:versin/app/locator.dart';
import 'package:versin/app/routes/app_routes.dart';
import 'package:versin/features/rhymes/presentation/controller/rhymes_controller.dart';

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
import 'package:versin/modules/storage/views/storage_page.dart';
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
  static const bool showStorage = true;
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

  final RhymesController _rhymesController =
      sl<
        RhymesController
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
      label: 'Estudio',
      icon: Icons.edit_note_rounded,
      route: '',
      visible: DashboardMenuVisibility.showStudio,
    ),

    _DashboardMenuItem(
      originalIndex: 4,
      label: 'IA ',
      icon: Icons.chat_bubble_outline_rounded,
      route: AppRoutes.chat,
      visible: true,
    ),

    _DashboardMenuItem(
      originalIndex: 1,
      label: 'Conectar',
      icon: Icons.share_outlined,
      route: AppRoutes.match,
      visible: DashboardMenuVisibility.showMatch,
    ),

    _DashboardMenuItem(
      originalIndex: 2,
      label: 'Mercado',
      icon: Icons.local_mall_outlined,
      route: AppRoutes.market,
      visible: DashboardMenuVisibility.showMarket,
    ),

    _DashboardMenuItem(
      originalIndex: 3,
      label: 'Carteira',
      icon: Icons.account_balance_wallet_outlined,
      route: AppRoutes.wallet,
      visible: DashboardMenuVisibility.showWallet,
    ),

    _DashboardMenuItem(
      originalIndex: 5,
      label: 'Armazenamento',
      icon: Icons.storefront_outlined,
      route: AppRoutes.storage,
      visible: DashboardMenuVisibility.showStorage,
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
      label: 'Ajustes',
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
                                    rhymesController: _rhymesController,
                                    onAddAppointment: _showAddAppointmentSheet,
                                  ),

                                  const MatchPage(),

                                  // MARKET CONTINUA EXISTINDO,
                                  // MAS ESTÁ OCULTO DOS MENUS.
                                  MarketPage(),

                                  const WalletPage(),

                                  const ChatPage(),

                                  StoragePage(),

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

  final RhymesController rhymesController;

  final VoidCallback onAddAppointment;

  const DashboardLabPage({
    super.key,
    required this.controller,
    required this.rhymesController,
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
          // IA MENSAL
          // ======================================================
          AnimatedBuilder(
            animation: rhymesController,
            builder:
                (
                  context,
                  _,
                ) {
                  return _AiMonthlyUsageCard(
                    controller: rhymesController,
                  );
                },
          ),

          const SizedBox(
            height: 16,
          ),

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

// ============================================================
// CARD — USO MENSAL DA IA
// ============================================================

class _AiMonthlyUsageCard
    extends
        StatelessWidget {
  final RhymesController controller;

  const _AiMonthlyUsageCard({
    required this.controller,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final percentage = controller.aiUsagePercentage.clamp(
      0.0,
      100.0,
    );

    final progress = controller.aiUsageProgress.clamp(
      0.0,
      1.0,
    );

    final level = controller.aiUsageLevel;

    final message = controller.aiUsageMessage;

    final usedTokens = controller.aiUsedTokens;

    final remainingTokens = controller.aiRemainingTokens;

    final limitTokens = controller.aiLimitTokens;

    final accentColor = _accentForLevel(
      level,
      percentage,
    );

    final statusText = _statusText(
      level,
      percentage,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        16,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(
          0.035,
        ),
        borderRadius: BorderRadius.circular(
          16,
        ),
        border: Border.all(
          color: accentColor.withOpacity(
            percentage >=
                    70
                ? 0.30
                : 0.12,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ====================================================
          // HEADER
          // ====================================================
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(
                    0.10,
                  ),
                  borderRadius: BorderRadius.circular(
                    12,
                  ),
                  border: Border.all(
                    color: accentColor.withOpacity(
                      0.22,
                    ),
                  ),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: accentColor,
                  size: 20,
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'IA mensal',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    SizedBox(
                      height: 2,
                    ),

                    Text(
                      'Uso da sua cota mensal de inteligência artificial',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(
                    0.10,
                  ),
                  borderRadius: BorderRadius.circular(
                    20,
                  ),
                  border: Border.all(
                    color: accentColor.withOpacity(
                      0.22,
                    ),
                  ),
                ),
                child: Text(
                  '${_formatPercentage(percentage)}%',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 16,
          ),

          // ====================================================
          // STATUS
          // ====================================================
          Row(
            children: [
              Icon(
                _iconForLevel(
                  level,
                  percentage,
                ),
                size: 15,
                color: accentColor,
              ),

              const SizedBox(
                width: 7,
              ),

              Text(
                statusText,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 9,
          ),

          // ====================================================
          // BARRA
          // ====================================================
          ClipRRect(
            borderRadius: BorderRadius.circular(
              20,
            ),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white.withOpacity(
                0.07,
              ),
              valueColor:
                  AlwaysStoppedAnimation<
                    Color
                  >(
                    accentColor,
                  ),
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          // ====================================================
          // MARCADORES
          // ====================================================
          const Row(
            children: [
              Text(
                '0%',
                style: TextStyle(
                  color: Colors.white24,
                  fontSize: 9,
                ),
              ),

              Spacer(),

              Text(
                '70%',
                style: TextStyle(
                  color: Colors.white24,
                  fontSize: 9,
                ),
              ),

              SizedBox(
                width: 24,
              ),

              Text(
                '90%',
                style: TextStyle(
                  color: Colors.white24,
                  fontSize: 9,
                ),
              ),

              SizedBox(
                width: 18,
              ),

              Text(
                '100%',
                style: TextStyle(
                  color: Colors.white24,
                  fontSize: 9,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 12,
          ),

          // ====================================================
          // MENSAGEM
          // ====================================================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(
                0.06,
              ),
              borderRadius: BorderRadius.circular(
                10,
              ),
              border: Border.all(
                color: accentColor.withOpacity(
                  0.12,
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: accentColor.withOpacity(
                    0.90,
                  ),
                  size: 15,
                ),

                const SizedBox(
                  width: 8,
                ),

                Expanded(
                  child: Text(
                    _normalizeMessage(
                      message,
                      percentage,
                    ),
                    style: TextStyle(
                      color: accentColor.withOpacity(
                        0.92,
                      ),
                      fontSize: 11,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          // ====================================================
          // TOKENS
          // ====================================================
          Row(
            children: [
              Expanded(
                child: _buildMetric(
                  label: 'USADOS',
                  value: _formatTokens(
                    usedTokens,
                  ),
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              Expanded(
                child: _buildMetric(
                  label: 'RESTANTES',
                  value: _formatTokens(
                    remainingTokens,
                  ),
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              Expanded(
                child: _buildMetric(
                  label: 'LIMITE',
                  value: _formatTokens(
                    limitTokens,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MÉTRICA
  // ============================================================

  Widget _buildMetric({
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(
          0.18,
        ),
        borderRadius: BorderRadius.circular(
          10,
        ),
        border: Border.all(
          color: Colors.white.withOpacity(
            0.04,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white30,
              fontSize: 8,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.7,
            ),
          ),

          const SizedBox(
            height: 3,
          ),

          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COR POR NÍVEL
  // ============================================================

  Color _accentForLevel(
    String level,
    double percentage,
  ) {
    final normalizedLevel = level.toLowerCase();

    if (percentage >=
            100 ||
        normalizedLevel ==
            'blocked') {
      return Colors.redAccent;
    }

    if (percentage >=
            90 ||
        normalizedLevel ==
            'critical') {
      return Colors.orangeAccent;
    }

    if (percentage >=
            70 ||
        normalizedLevel ==
            'warning') {
      return Colors.amberAccent;
    }

    return const Color(
      0xFFE100FF,
    );
  }

  // ============================================================
  // ÍCONE POR NÍVEL
  // ============================================================

  IconData _iconForLevel(
    String level,
    double percentage,
  ) {
    final normalizedLevel = level.toLowerCase();

    if (percentage >=
            100 ||
        normalizedLevel ==
            'blocked') {
      return Icons.block_rounded;
    }

    if (percentage >=
            90 ||
        normalizedLevel ==
            'critical') {
      return Icons.warning_amber_rounded;
    }

    if (percentage >=
            70 ||
        normalizedLevel ==
            'warning') {
      return Icons.info_outline_rounded;
    }

    return Icons.check_circle_outline_rounded;
  }

  // ============================================================
  // STATUS
  // ============================================================

  String _statusText(
    String level,
    double percentage,
  ) {
    final normalizedLevel = level.toLowerCase();

    if (percentage >=
            100 ||
        normalizedLevel ==
            'blocked') {
      return 'Limite atingido';
    }

    if (percentage >=
            90 ||
        normalizedLevel ==
            'critical') {
      return 'Limite próximo';
    }

    if (percentage >=
            70 ||
        normalizedLevel ==
            'warning') {
      return 'Uso elevado';
    }

    return 'Uso normal';
  }

  // ============================================================
  // MENSAGEM
  // ============================================================

  String _normalizeMessage(
    String message,
    double percentage,
  ) {
    final normalized = message.trim();

    if (percentage >=
        100) {
      return 'Limite mensal de IA atingido.';
    }

    if (percentage >=
        90) {
      return 'Seu limite mensal está próximo.';
    }

    if (percentage >=
        70) {
      return 'Você já utilizou boa parte da sua IA este mês.';
    }

    if (normalized.isNotEmpty) {
      return normalized;
    }

    return 'Uso normal da IA.';
  }

  // ============================================================
  // FORMATAR PERCENTUAL
  // ============================================================

  static String _formatPercentage(
    double percentage,
  ) {
    if (percentage ==
        percentage.roundToDouble()) {
      return percentage.toInt().toString();
    }

    return percentage.toStringAsFixed(
      1,
    );
  }

  // ============================================================
  // FORMATAR TOKENS
  // ============================================================

  String _formatTokens(
    int value,
  ) {
    if (value >=
        1000000) {
      final millions =
          value /
          1000000;

      if (millions ==
          millions.roundToDouble()) {
        return '${millions.toInt()}M';
      }

      return '${millions.toStringAsFixed(1)}M';
    }

    if (value >=
        1000) {
      final thousands =
          value /
          1000;

      if (thousands ==
          thousands.roundToDouble()) {
        return '${thousands.toInt()}k';
      }

      return '${thousands.toStringAsFixed(1)}k';
    }

    return value.toString();
  }
}
