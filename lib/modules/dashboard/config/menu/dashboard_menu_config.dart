import 'package:flutter/material.dart';

import 'package:versin/app/routes/app_routes.dart';

import '../../models/dashboard_menu_item.dart';
import 'dashboard_menu_visibility.dart';

// ============================================================
// DASHBOARD MENU CONFIG
// ============================================================
//
// IMPORTANTE:
//
// originalIndex representa a posição REAL no PageView.
//
// PageView:
//
// 0 = Dashboard
// 1 = Match / Conectar
// 2 = Market
// 3 = Wallet
// 4 = IA / Chat
// 5 = Storage
// 6 = Hub
// 7 = VNode
// 8 = Settings
// 9 = Studio
//
// A ordem VISUAL do menu pode ser diferente.
//
// ============================================================

abstract final class DashboardMenuConfig {
  // ==========================================================
  // ÍNDICES REAIS DO PAGEVIEW
  // ==========================================================

  static const int dashboardIndex = 0;

  static const int matchIndex = 1;

  static const int marketIndex = 2;

  static const int walletIndex = 3;

  static const int aiIndex = 4;

  static const int storageIndex = 5;

  static const int hubIndex = 6;

  static const int vnodeIndex = 7;

  static const int settingsIndex = 8;

  static const int studioIndex = 9;

  // ==========================================================
  // ITENS
  // ==========================================================
  //
  // A ordem abaixo é apenas a ordem VISUAL do menu.
  //
  // O originalIndex continua apontando para o PageView correto.
  //
  // ==========================================================

  static const List<
    DashboardMenuItem
  >
  items = [
    // ========================================================
    // DASHBOARD
    // ========================================================
    DashboardMenuItem(
      originalIndex: dashboardIndex,
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      route: '/',
      visible: DashboardMenuVisibility.showDashboard,
    ),

    // ========================================================
    // STUDIO
    // ========================================================
    //
    // Aparece aqui visualmente,
    // mas continua sendo página 9.
    //
    // ========================================================
    DashboardMenuItem(
      originalIndex: studioIndex,
      label: 'Estudio',
      icon: Icons.edit_note_rounded,
      route: '',
      visible: DashboardMenuVisibility.showStudio,
    ),

    // ========================================================
    // IA
    // ========================================================
    //
    // Página real = 4.
    //
    // ========================================================
    DashboardMenuItem(
      originalIndex: aiIndex,
      label: 'IA',
      icon: Icons.chat_bubble_outline_rounded,
      route: AppRoutes.chat,
      visible: true,
    ),

    // ========================================================
    // CONECTAR
    // ========================================================
    //
    // Página real = 1.
    //
    // ========================================================
    DashboardMenuItem(
      originalIndex: matchIndex,
      label: 'Conectar',
      icon: Icons.share_outlined,
      route: AppRoutes.match,
      visible: DashboardMenuVisibility.showMatch,
    ),

    // ========================================================
    // MERCADO
    // ========================================================
    //
    // Página real = 2.
    //
    // ========================================================
    DashboardMenuItem(
      originalIndex: marketIndex,
      label: 'Mercado',
      icon: Icons.local_mall_outlined,
      route: AppRoutes.market,
      visible: DashboardMenuVisibility.showMarket,
    ),

    // ========================================================
    // CARTEIRA
    // ========================================================
    //
    // Página real = 3.
    //
    // ========================================================
    DashboardMenuItem(
      originalIndex: walletIndex,
      label: 'Carteira',
      icon: Icons.account_balance_wallet_outlined,
      route: AppRoutes.wallet,
      visible: DashboardMenuVisibility.showWallet,
    ),

    // ========================================================
    // ARMAZENAR
    // ========================================================
    //
    // Página real = 5.
    //
    // ========================================================
    DashboardMenuItem(
      originalIndex: storageIndex,
      label: 'Armazenar',
      icon: Icons.cloud_outlined,
      route: AppRoutes.storage,
      visible: DashboardMenuVisibility.showStorage,
    ),

    // ========================================================
    // HUB
    // ========================================================
    //
    // Página real = 6.
    //
    // ========================================================
    DashboardMenuItem(
      originalIndex: hubIndex,
      label: 'Hub',
      icon: Icons.settings_input_component,
      route: AppRoutes.hub,
      visible: DashboardMenuVisibility.showHub,
    ),

    // ========================================================
    // VNODE
    // ========================================================
    //
    // Página real = 7.
    //
    // ========================================================
    DashboardMenuItem(
      originalIndex: vnodeIndex,
      label: 'VNode Network',
      icon: Icons.lan_outlined,
      route: AppRoutes.vnode,
      visible: DashboardMenuVisibility.showVNode,
    ),

    // ========================================================
    // AJUSTES
    // ========================================================
    //
    // Página real = 8.
    //
    // ========================================================
    DashboardMenuItem(
      originalIndex: settingsIndex,
      label: 'Ajustes',
      icon: Icons.settings_outlined,
      route: AppRoutes.settings,
      visible: DashboardMenuVisibility.showSettings,
    ),
  ];

  // ==========================================================
  // ITENS VISÍVEIS
  // ==========================================================

  static List<
    DashboardMenuItem
  >
  get visibleItems {
    return items
        .where(
          (
            item,
          ) {
            return item.visible;
          },
        )
        .toList(
          growable: false,
        );
  }

  // ==========================================================
  // BUSCAR PELO ÍNDICE ORIGINAL
  // ==========================================================

  static DashboardMenuItem? findByOriginalIndex(
    int originalIndex,
  ) {
    for (final item in items) {
      if (item.originalIndex ==
          originalIndex) {
        return item;
      }
    }

    return null;
  }

  // ==========================================================
  // BUSCAR PELA ROTA
  // ==========================================================

  static DashboardMenuItem? findByRoute(
    String route,
  ) {
    final normalizedRoute = route.trim();

    if (normalizedRoute.isEmpty) {
      return null;
    }

    for (final item in items) {
      if (item.route ==
          normalizedRoute) {
        return item;
      }
    }

    return null;
  }

  // ==========================================================
  // VISIBILIDADE
  // ==========================================================

  static bool isVisible(
    int originalIndex,
  ) {
    return findByOriginalIndex(
          originalIndex,
        )?.visible ??
        false;
  }

  // ==========================================================
  // POSIÇÃO VISUAL
  // ==========================================================

  static int visiblePositionOf(
    int originalIndex,
  ) {
    return visibleItems.indexWhere(
      (
        item,
      ) {
        return item.originalIndex ==
            originalIndex;
      },
    );
  }
}
