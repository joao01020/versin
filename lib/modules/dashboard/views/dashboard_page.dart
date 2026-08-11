import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:versin/app/locator.dart';
import 'package:versin/app/routes/app_routes.dart'; // Importação das rotas

// CONTROLLER & WIDGETS IMPORTS
import '../controllers/dashboard_controller.dart';
import '../widgets/side_rail_widget.dart';
import '../widgets/dashboard_header_widget.dart';
import '../widgets/account_activities_card_widget.dart';
import '../widgets/hub_status_card_widget.dart';
import '../widgets/main_chart_card_widget.dart';
import '../widgets/calendar_card_widget.dart';

// ECOSYSTEM MODULES IMPORTS
import 'package:versin/modules/chat/views/chat_page.dart';
import 'package:versin/modules/hub/views/hub_page.dart';
// EN: Updated path targeting the newly structured modular layout location
// PT: Caminho atualizado apontando para o local da nova estrutura modular
import 'package:versin/modules/match/views/match_page.dart';
import 'package:versin/modules/wallet/views/wallet_page.dart';
import 'package:versin/modules/market/market_page.dart';
import 'package:versin/modules/showcase/showcase_page.dart';
import 'package:versin/modules/vnode/vnode_page.dart';
import 'package:versin/modules/settings/settings_page.dart';

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

  // Mapeamento dos índices para as rotas nomeadas
  final List<
    String
  >
  _routes = [
    '/',
    AppRoutes.match,
    AppRoutes.market,
    AppRoutes.wallet,
    AppRoutes.chat,
    AppRoutes.showcase,
    AppRoutes.hub,
    AppRoutes.vnode,
    AppRoutes.settings,
  ];

  @override
  void initState() {
    super.initState();
    _controller.init();
  }

  void _onNavigationTap(
    int index,
  ) {
    setState(
      () => _controller.navigationTap(
        index,
      ),
    );
    // Navega para a rota correspondente via sistema de rotas do Flutter
    if (index !=
        0) {
      Navigator.of(
        context,
      ).pushNamed(
        _routes[index],
      );
    }
  }

  void _showAddAppointmentSheet({
    String? fixedTime,
  }) {
    final TextEditingController titleController = TextEditingController();
    final now = DateTime.now();
    final String defaultTime =
        fixedTime ??
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "NOVO COMPROMISSO - DIA ${_controller.selectedDay}/${_controller.focusedDay.month}",
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
                        onPressed: () => Navigator.pop(
                          context,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 16,
                  ),
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
                      hintText: "Descrição do compromisso",
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
                      hintText: "Horário (HH:MM)",
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
                        if (titleController.text.isNotEmpty &&
                            timeController.text.isNotEmpty) {
                          setState(
                            () => _controller.addAppointment(
                              title: titleController.text,
                              time: timeController.text,
                            ),
                          );
                          Navigator.pop(
                            context,
                          );
                        }
                      },
                      child: const Text(
                        "AGENDAR NO CHASSI",
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
    );
  }

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
            bool isMobile =
                constraints.maxWidth <
                800;

            return Scaffold(
              backgroundColor: Colors.black,
              bottomNavigationBar: isMobile
                  ? BottomNavigationBar(
                      currentIndex: _controller.currentIndex,
                      onTap: _onNavigationTap,
                      selectedItemColor: _controller.accentNeon,
                      unselectedItemColor: Colors.white24,
                      type: BottomNavigationBarType.fixed,
                      items: const [
                        BottomNavigationBarItem(
                          icon: Icon(
                            Icons.dashboard_outlined,
                          ),
                          label: "Dash",
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(
                            Icons.share_outlined,
                          ),
                          label: "Match",
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(
                            Icons.local_mall_outlined,
                          ),
                          label: "Market",
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(
                            Icons.account_balance_wallet_outlined,
                          ),
                          label: "Wallet",
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(
                            Icons.mic_external_on_outlined,
                          ),
                          label: "Studio",
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(
                            Icons.storefront_outlined,
                          ),
                          label: "Showcase",
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(
                            Icons.settings_input_component,
                          ),
                          label: "Hub",
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(
                            Icons.lan_outlined,
                          ),
                          label: "VNode",
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(
                            Icons.settings_outlined,
                          ),
                          label: "Settings",
                        ),
                      ],
                    )
                  : null,
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
                    if (!isMobile)
                      SideRailWidget(
                        controller: _controller,
                      ),
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
                                onPageChanged:
                                    (
                                      index,
                                    ) => setState(
                                      () => _controller.handlePageChange(
                                        index,
                                      ),
                                    ),
                                children: [
                                  DashboardLabPage(
                                    controller: _controller,
                                    onAddAppointment: _showAddAppointmentSheet,
                                  ),
                                  const MatchPage(),
                                  MarketPage(),
                                  const WalletPage(),
                                  const ChatPage(),
                                  ShowcasePage(),
                                  const HubPage(),
                                  VNodePage(),
                                  SettingsPage(),
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
}

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
    bool isMobile =
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
          // CARD DE PROJETO ATIVO
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
                    "Studio Session Ativa",
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
          isMobile
              ? Column(
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
              : Row(
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
