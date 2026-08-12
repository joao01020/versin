import 'package:flutter/material.dart';

// ============================================================
// MÓDULOS PRINCIPAIS
// ============================================================

import 'package:versin/modules/login/views/login_page.dart';

import 'package:versin/modules/dashboard/views/dashboard_page.dart';
import 'package:versin/modules/dashboard/views/contracts/contracts_page.dart';
import 'package:versin/modules/dashboard/views/calendar/calendar_page.dart';

// ============================================================
// MÓDULOS DO ECOSSISTEMA
// ============================================================

import 'package:versin/modules/chat/views/chat_page.dart';

import 'package:versin/modules/hub/views/hub_page.dart';

import 'package:versin/modules/match/views/match_page.dart';

import 'package:versin/modules/wallet/views/wallet_page.dart';
import 'package:versin/modules/wallet/views/royalties_page.dart';

import 'package:versin/modules/market/market_page.dart';

import 'package:versin/modules/storage/views/storage_page.dart';

import 'package:versin/modules/vnode/vnode_page.dart';

import 'package:versin/modules/settings/settings_page.dart';

// ============================================================
// APP ROUTES
// ============================================================

class AppRoutes {
  // ==========================================================
  // ROTAS PRINCIPAIS
  // ==========================================================

  static const String login = '/login';

  static const String dashboard = '/dashboard';

  static const String contracts = '/contracts';

  static const String calendar = '/calendar';

  // ==========================================================
  // ROTAS DO ECOSSISTEMA
  // ==========================================================

  static const String chat = '/chat';

  static const String hub = '/hub';

  static const String match = '/match';

  static const String wallet = '/wallet';

  static const String royalties = '/royalties';

  static const String market = '/market';

  static const String storage = '/storage';

  static const String vnode = '/vnode';

  static const String settings = '/settings';

  // ==========================================================
  // MAPA DE ROTAS
  // ==========================================================

  static Map<
    String,
    WidgetBuilder
  >
  get routes => {
    // ====================================================
    // LOGIN
    // ====================================================
    login:
        (
          context,
        ) => const LoginPage(),

    // ====================================================
    // DASHBOARD
    // ====================================================
    dashboard:
        (
          context,
        ) => const DashboardPage(),

    // ====================================================
    // CONTRATOS
    // ====================================================
    contracts:
        (
          context,
        ) => const ContractsPage(),

    // ====================================================
    // CALENDÁRIO
    // ====================================================
    calendar:
        (
          context,
        ) => const CalendarPage(),

    // ====================================================
    // CHAT / IA
    // ====================================================
    chat:
        (
          context,
        ) => const ChatPage(),

    // ====================================================
    // HUB
    // ====================================================
    hub:
        (
          context,
        ) => const HubPage(),

    // ====================================================
    // MATCH
    // ====================================================
    match:
        (
          context,
        ) => const MatchPage(),

    // ====================================================
    // WALLET
    // ====================================================
    wallet:
        (
          context,
        ) => const WalletPage(),

    // ====================================================
    // ROYALTIES
    // ====================================================
    royalties:
        (
          context,
        ) => const RoyaltiesPage(),

    // ====================================================
    // MARKET
    // ====================================================
    market:
        (
          context,
        ) => MarketPage(),

    // ====================================================
    // STORAGE
    // ====================================================
    storage:
        (
          context,
        ) => const StoragePage(),

    // ====================================================
    // VNODE
    // ====================================================
    vnode:
        (
          context,
        ) => VNodePage(),

    // ====================================================
    // SETTINGS
    // ====================================================
    settings:
        (
          context,
        ) => SettingsPage(),
  };
}
