// ============================================================
// DASHBOARD MENU VISIBILITY
// ============================================================
//
// Configuração central responsável por definir quais módulos
// aparecem na navegação do Dashboard.
//
// IMPORTANTE:
//
// Este arquivo controla somente VISIBILIDADE.
//
// Ele NÃO:
//
// - remove páginas;
// - altera índices;
// - controla navegação;
// - cria widgets;
// - acessa controllers.
//
// Dessa forma podemos esconder uma opção do menu sem alterar
// a estrutura interna do Dashboard.
//
// ============================================================

abstract final class DashboardMenuVisibility {
  // ==========================================================
  // DASHBOARD
  // ==========================================================

  static const bool showDashboard = true;

  // ==========================================================
  // MATCH / CONECTAR
  // ==========================================================

  static const bool showMatch = true;

  // ==========================================================
  // MARKET
  // ==========================================================

  static const bool showMarket = false;

  // ==========================================================
  // WALLET
  // ==========================================================

  static const bool showWallet = true;

  // ==========================================================
  // STUDIO
  // ==========================================================

  static const bool showStudio = true;

  // ==========================================================
  // STORAGE
  // ==========================================================

  static const bool showStorage = true;

  // ==========================================================
  // HUB
  // ==========================================================

  static const bool showHub = true;

  // ==========================================================
  // VNODE
  // ==========================================================

  static const bool showVNode = false;

  // ==========================================================
  // SETTINGS
  // ==========================================================

  static const bool showSettings = true;

  // ==========================================================
  // IA
  // ==========================================================

  static const bool showAi = true;
}
