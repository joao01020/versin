import 'package:flutter/material.dart';

import 'package:versin/modules/dashboard/page/dashboard_page_coordinator.dart';
import 'package:versin/modules/dashboard/page/dashboard_page_view.dart';

// ============================================================
// DASHBOARD PAGE
// ============================================================
//
// Composition root do shell principal.
//
// Responsabilidade:
//
// - criar o coordinator;
// - iniciar o Dashboard;
// - observar o estado de página;
// - renderizar DashboardPageView;
// - encerrar recursos pertencentes ao Dashboard.
//
// NÃO:
//
// - acessa Supabase;
// - monta repositório de IA;
// - conhece banners internamente;
// - conhece páginas do PageView;
// - executa navegação de feature;
// - contém layout desktop/mobile.
//
// ============================================================

class DashboardPage extends StatefulWidget {
  static const String routeName = '/';

  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final DashboardPageCoordinator _coordinator;

  @override
  void initState() {
    super.initState();

    _coordinator = DashboardPageCoordinator();

    _coordinator.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _coordinator,
      builder: (context, _) {
        return DashboardPageView(coordinator: _coordinator);
      },
    );
  }

  @override
  void dispose() {
    _coordinator.dispose();

    super.dispose();
  }
}
