import 'package:flutter/material.dart';

// ============================================================
// APP
// ============================================================

import 'package:versin/app/auth_guard.dart';

// ============================================================
// LOGIN / AUTH
// ============================================================

import 'package:versin/modules/login/views/login_page.dart';

import 'package:versin/modules/login/recovery/views/forgot_password_page.dart';
import 'package:versin/modules/login/recovery/views/reset_password_page.dart';

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
//
// Centraliza os nomes das rotas do Versin.
//
// As rotas são divididas em:
//
// PÚBLICAS:
//
// - login;
// - recuperação de senha;
// - redefinição de senha.
//
// PRIVADAS:
//
// - dashboard;
// - contratos;
// - calendário;
// - chat;
// - hub;
// - match;
// - wallet;
// - royalties;
// - market;
// - storage;
// - vnode;
// - settings.
//
// As rotas privadas passam obrigatoriamente por:
//
// AuthGuard
//
// Portanto, acessar diretamente:
//
// http://localhost:8080/dashboard
//
// sem sessão válida NÃO abre mais o Dashboard.
//
// ============================================================

class AppRoutes {
  AppRoutes._();

  // ==========================================================
  // AUTH
  // ==========================================================

  static const String login = '/login';

  static const String forgotPassword = '/forgot-password';

  static const String resetPassword = '/reset-password';

  // ==========================================================
  // ROTAS PRINCIPAIS
  // ==========================================================

  static const String dashboard = '/dashboard';

  static const String contracts = '/contracts';

  static const String calendar = '/calendar';

  // ==========================================================
  // ECOSSISTEMA
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
  // ROUTES
  // ==========================================================

  static Map<
    String,
    WidgetBuilder
  >
  get routes => {
    // ========================================================
    // ROTAS PÚBLICAS
    // ========================================================

    // ========================================================
    // LOGIN
    // ========================================================
    login:
        (
          context,
        ) => const LoginPage(),

    // ========================================================
    // FORGOT PASSWORD
    // ========================================================
    forgotPassword:
        (
          context,
        ) => const ForgotPasswordPage(),

    // ========================================================
    // RESET PASSWORD
    // ========================================================
    //
    // Precisa continuar pública porque o usuário ainda está
    // entrando através de uma sessão especial de recovery.
    //
    // O Supabase/AuthWrapper continuam responsáveis por validar
    // a sessão de recuperação.
    //
    // ========================================================
    resetPassword:
        (
          context,
        ) => const ResetPasswordPage(),

    // ========================================================
    // ROTAS PRIVADAS
    // ========================================================
    //
    // Todas passam obrigatoriamente pelo AuthGuard.
    //
    // ========================================================

    // ========================================================
    // DASHBOARD
    // ========================================================
    dashboard:
        (
          context,
        ) => const AuthGuard(
          child: DashboardPage(),
        ),

    // ========================================================
    // CONTRACTS
    // ========================================================
    contracts:
        (
          context,
        ) => const AuthGuard(
          child: ContractsPage(),
        ),

    // ========================================================
    // CALENDAR
    // ========================================================
    calendar:
        (
          context,
        ) => const AuthGuard(
          child: CalendarPage(),
        ),

    // ========================================================
    // CHAT
    // ========================================================
    chat:
        (
          context,
        ) => const AuthGuard(
          child: ChatPage(),
        ),

    // ========================================================
    // HUB
    // ========================================================
    hub:
        (
          context,
        ) => const AuthGuard(
          child: HubPage(),
        ),

    // ========================================================
    // MATCH
    // ========================================================
    match:
        (
          context,
        ) => const AuthGuard(
          child: MatchPage(),
        ),

    // ========================================================
    // WALLET
    // ========================================================
    wallet:
        (
          context,
        ) => const AuthGuard(
          child: WalletPage(),
        ),

    // ========================================================
    // ROYALTIES
    // ========================================================
    royalties:
        (
          context,
        ) => const AuthGuard(
          child: RoyaltiesPage(),
        ),

    // ========================================================
    // MARKET
    // ========================================================
    //
    // MarketPage não está sendo criada como const no seu
    // projeto atual, então o AuthGuard também não pode ser
    // const nesta rota.
    //
    // ========================================================
    market:
        (
          context,
        ) => AuthGuard(
          child: MarketPage(),
        ),

    // ========================================================
    // STORAGE
    // ========================================================
    storage:
        (
          context,
        ) => const AuthGuard(
          child: StoragePage(),
        ),

    // ========================================================
    // VNODE
    // ========================================================
    //
    // VNodePage também não está sendo criada como const.
    //
    // ========================================================
    vnode:
        (
          context,
        ) => AuthGuard(
          child: VNodePage(),
        ),

    // ========================================================
    // SETTINGS
    // ========================================================
    settings:
        (
          context,
        ) => const AuthGuard(
          child: SettingsPage(),
        ),
  };
}
