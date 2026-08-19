import 'package:shared_preferences/shared_preferences.dart';

// ============================================================
// DASHBOARD UI PREFERENCES SERVICE
// ============================================================
//
// Responsável por persistir preferências VISUAIS do Dashboard.
//
// Exemplos:
//
// - cards expandidos ou recolhidos;
// - filtros selecionados;
// - modos de visualização;
// - outras preferências de interface.
//
// IMPORTANTE:
//
// Este service NÃO deve armazenar:
//
// - tokens;
// - API keys;
// - senhas;
// - JWT;
// - dados de autenticação;
// - informações sensíveis.
//
// SharedPreferences é utilizado apenas para preferências locais
// de interface.
//
// ============================================================

class DashboardUiPreferencesService {
  // ============================================================
  // KEYS
  // ============================================================

  static const String _aiMonthlyCardExpandedKey =
      'dashboard_ai_monthly_card_expanded';

  static const String _profileCardExpandedKey =
      'dashboard_profile_card_expanded';

  static const String _statisticsCardExpandedKey =
      'dashboard_statistics_card_expanded';

  // ============================================================
  // DEFAULT VALUES
  // ============================================================

  static const bool _defaultAiMonthlyCardExpanded = true;

  static const bool _defaultProfileCardExpanded = true;

  static const bool _defaultStatisticsCardExpanded = true;

  // ============================================================
  // LOAD AI MONTHLY CARD EXPANDED
  // ============================================================

  Future<bool> loadAiMonthlyCardExpanded() async {
    try {
      final preferences = await SharedPreferences.getInstance();

      return preferences.getBool(_aiMonthlyCardExpandedKey) ??
          _defaultAiMonthlyCardExpanded;
    } catch (_) {
      return _defaultAiMonthlyCardExpanded;
    }
  }

  // ============================================================
  // SAVE AI MONTHLY CARD EXPANDED
  // ============================================================

  Future<bool> saveAiMonthlyCardExpanded(bool isExpanded) async {
    try {
      final preferences = await SharedPreferences.getInstance();

      return await preferences.setBool(_aiMonthlyCardExpandedKey, isExpanded);
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // RESET AI MONTHLY CARD EXPANDED
  // ============================================================

  Future<bool> resetAiMonthlyCardExpanded() async {
    try {
      final preferences = await SharedPreferences.getInstance();

      return await preferences.remove(_aiMonthlyCardExpandedKey);
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // LOAD PROFILE CARD EXPANDED
  // ============================================================

  Future<bool> loadProfileCardExpanded() async {
    try {
      final preferences = await SharedPreferences.getInstance();

      return preferences.getBool(_profileCardExpandedKey) ??
          _defaultProfileCardExpanded;
    } catch (_) {
      return _defaultProfileCardExpanded;
    }
  }

  // ============================================================
  // SAVE PROFILE CARD EXPANDED
  // ============================================================

  Future<bool> saveProfileCardExpanded(bool isExpanded) async {
    try {
      final preferences = await SharedPreferences.getInstance();

      return await preferences.setBool(_profileCardExpandedKey, isExpanded);
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // RESET PROFILE CARD EXPANDED
  // ============================================================

  Future<bool> resetProfileCardExpanded() async {
    try {
      final preferences = await SharedPreferences.getInstance();

      return await preferences.remove(_profileCardExpandedKey);
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // LOAD STATISTICS CARD EXPANDED
  // ============================================================

  Future<bool> loadStatisticsCardExpanded() async {
    try {
      final preferences = await SharedPreferences.getInstance();

      return preferences.getBool(_statisticsCardExpandedKey) ??
          _defaultStatisticsCardExpanded;
    } catch (_) {
      return _defaultStatisticsCardExpanded;
    }
  }

  // ============================================================
  // SAVE STATISTICS CARD EXPANDED
  // ============================================================

  Future<bool> saveStatisticsCardExpanded(bool isExpanded) async {
    try {
      final preferences = await SharedPreferences.getInstance();

      return await preferences.setBool(_statisticsCardExpandedKey, isExpanded);
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // RESET STATISTICS CARD EXPANDED
  // ============================================================

  Future<bool> resetStatisticsCardExpanded() async {
    try {
      final preferences = await SharedPreferences.getInstance();

      return await preferences.remove(_statisticsCardExpandedKey);
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // RESET DASHBOARD PREFERENCES
  // ============================================================

  Future<void> resetDashboardPreferences() async {
    try {
      final preferences = await SharedPreferences.getInstance();

      const dashboardKeys = <String>[
        _aiMonthlyCardExpandedKey,
        _profileCardExpandedKey,
        _statisticsCardExpandedKey,
      ];

      for (final key in dashboardKeys) {
        await preferences.remove(key);
      }
    } catch (_) {
      // Uma falha ao limpar preferências visuais não deve
      // interromper o funcionamento do aplicativo.
    }
  }
}
