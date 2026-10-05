import 'package:flutter/material.dart';

import 'package:versin/features/rhymes/presentation/controller/rhymes_controller.dart';

import 'package:versin/modules/chat/views/chat_page.dart';
import 'package:versin/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:versin/modules/dashboard/layouts/dashboard_home_layout.dart';
import 'package:versin/modules/hub/views/hub_page.dart';
import 'package:versin/modules/market/market_page.dart';
import 'package:versin/modules/match/views/match_page.dart';
import 'package:versin/modules/settings/views/settings_page.dart';
import 'package:versin/modules/storage/views/storage_page.dart';
import 'package:versin/modules/studio/views/studio_page.dart';
import 'package:versin/modules/vnode/vnode_page.dart';
import 'package:versin/modules/wallet/views/wallet_page.dart';

// ============================================================
// DASHBOARD PAGE MODULES
// ============================================================
//
// Contrato estrutural do PageView.
//
// IMPORTANTE:
//
// Estes índices NÃO são apenas layout.
// Eles são utilizados pelo DashboardController e pelo menu.
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
// Alterar a ordem exige alterar o contrato inteiro de navegação.
//
// ============================================================

abstract final class DashboardPageModules {
  static List<Widget> build({
    required DashboardController dashboardController,
    required RhymesController rhymesController,
    required VoidCallback onOpenCalendar,
  }) {
    return <Widget>[
      // 0 — DASHBOARD
      DashboardHomeLayout(
        controller: dashboardController,
        rhymesController: rhymesController,
        onAddAppointment: onOpenCalendar,
      ),

      // 1 — CONECTAR
      const MatchPage(),

      // 2 — MERCADO
      MarketPage(),

      // 3 — CARTEIRA
      const WalletPage(),

      // 4 — IA
      const ChatPage(),

      // 5 — ARMAZENAR
      StoragePage(),

      // 6 — HUB
      const HubPage(),

      // 7 — VNODE
      VNodePage(),

      // 8 — AJUSTES
      SettingsPage(),

      // 9 — STUDIO
      const StudioPage(),
    ];
  }
}
