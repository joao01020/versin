import 'package:flutter/material.dart';

// Módulos principais
import 'package:versin/modules/login/views/login_page.dart';
import 'package:versin/modules/dashboard/views/dashboard_page.dart';
import 'package:versin/modules/dashboard/views/contracts/contracts_page.dart';
import 'package:versin/modules/dashboard/views/calendar/calendar_page.dart';

// Módulos do Ecossistema
import 'package:versin/modules/chat/views/chat_page.dart';
import 'package:versin/modules/hub/views/hub_page.dart';
import 'package:versin/modules/match/views/match_page.dart'; 
import 'package:versin/modules/wallet/views/wallet_page.dart';
import 'package:versin/modules/wallet/views/royalties_page.dart';
import 'package:versin/modules/market/market_page.dart';
import 'package:versin/modules/showcase/showcase_page.dart';
import 'package:versin/modules/vnode/vnode_page.dart';
import 'package:versin/modules/settings/settings_page.dart';

class AppRoutes {
  // Strings de navegação
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String contracts = '/contracts';
  static const String calendar = '/calendar';
  
  // Rotas do ecossistema
  static const String chat = '/chat';
  static const String hub = '/hub';
  static const String match = '/match';
  static const String wallet = '/wallet';
  static const String royalties = '/royalties';
  static const String market = '/market';
  static const String showcase = '/showcase';
  static const String vnode = '/vnode';
  static const String settings = '/settings';

  // Mapa de rotas do aplicativo
  static Map<String, WidgetBuilder> get routes => {
    login: (context) => const LoginPage(),
    dashboard: (context) => const DashboardPage(),
    contracts: (context) => const ContractsPage(),
    calendar: (context) => const CalendarPage(),
    
    // Rotas do ecossistema
    chat: (context) => const ChatPage(),
    hub: (context) => const HubPage(),
    match: (context) => const MatchPage(),
    wallet: (context) => const WalletPage(),
    royalties: (context) => const RoyaltiesPage(),
    market: (context) => MarketPage(),
    showcase: (context) => ShowcasePage(),
    vnode: (context) => VNodePage(),
    settings: (context) => SettingsPage(),
  };
}