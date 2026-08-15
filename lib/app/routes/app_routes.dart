import 'package:flutter/material.dart';

// ============================================================
// LOGIN
// ============================================================

import 'package:versin/modules/login/views/login_page.dart';

// ============================================================
// DASHBOARD
// ============================================================

import 'package:versin/modules/dashboard/views/dashboard_page.dart';
import 'package:versin/modules/dashboard/views/contracts/contracts_page.dart';

// ============================================================
// CALENDAR
// ============================================================

import 'package:versin/modules/calendar/views/calendar_page.dart';

// ============================================================
// CHAT / IA
// ============================================================

import 'package:versin/modules/chat/views/chat_page.dart';

// ============================================================
// HUB
// ============================================================

import 'package:versin/modules/hub/views/hub_page.dart';

// ============================================================
// MATCH / CONECTAR
// ============================================================

import 'package:versin/modules/match/views/match_page.dart';

// ============================================================
// WALLET
// ============================================================

import 'package:versin/modules/wallet/views/wallet_page.dart';
import 'package:versin/modules/wallet/views/royalties_page.dart';

// ============================================================
// MARKET
// ============================================================

import 'package:versin/modules/market/market_page.dart';

// ============================================================
// STORAGE
// ============================================================

import 'package:versin/modules/storage/views/storage_page.dart';

// ============================================================
// VNODE
// ============================================================

import 'package:versin/modules/vnode/vnode_page.dart';

// ============================================================
// SETTINGS
// ============================================================

import 'package:versin/modules/settings/views/settings_page.dart';

// ============================================================
// APP ROUTES
// ============================================================

class AppRoutes {
  AppRoutes._();

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
    //
    // Novo módulo:
    //
    // lib/modules/calendar/views/calendar_page.dart
    //
    // Inclui:
    //
    // - eventos reais;
    // - compromissos colaborativos;
    // - convites;
    // - anotações por dia;
    // - Supabase.
    //
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
    // MATCH / CONECTAR
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
        ) => const SettingsPage(),
  };
}
