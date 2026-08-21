import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
// ============================================================
// ISOLAMENTO POR USUÁRIO
// ============================================================
//
// Cada usuário possui suas próprias chaves.
//
// Exemplo:
//
// dashboard_ui_v2.<USER_ID>.profile_card_expanded
// dashboard_ui_v2.<USER_ID>.ai_monthly_card_expanded
//
// Dessa forma:
//
// Conta A
//   ↓
// preferências A
//
// Conta B
//   ↓
// preferências B
//
// Uma conta nunca reutiliza o estado visual da outra.
//
// ============================================================
// IMPORTANTE
// ============================================================
//
// Este service NÃO deve armazenar:
//
// - tokens;
// - API keys;
// - senhas;
// - JWT;
// - refresh tokens;
// - informações sensíveis.
//
// SharedPreferences é utilizado somente para preferências
// locais de interface.
//
// ============================================================

class DashboardUiPreferencesService {
  // ============================================================
  // SUPABASE
  // ============================================================

  final SupabaseClient _supabase;

  // ============================================================
  // CONSTRUTOR
  // ============================================================
  //
  // Permitir injetar SupabaseClient melhora:
  //
  // - testabilidade;
  // - desacoplamento;
  // - mocks;
  // - testes unitários.
  //
  // No aplicativo normal:
  //
  // DashboardUiPreferencesService()
  //
  // continua funcionando sem alterações.
  //
  // ============================================================

  DashboardUiPreferencesService({
    SupabaseClient? supabase,
  }) : _supabase =
           supabase ??
           Supabase.instance.client;

  // ============================================================
  // NAMESPACE
  // ============================================================

  static const String _namespace = 'dashboard_ui_v2';

  // ============================================================
  // SUFIXOS DAS PREFERÊNCIAS
  // ============================================================

  static const String _aiMonthlyCardExpandedPreference = 'ai_monthly_card_expanded';

  static const String _profileCardExpandedPreference = 'profile_card_expanded';

  static const String _statisticsCardExpandedPreference = 'statistics_card_expanded';

  // ============================================================
  // CHAVES LEGADAS
  // ============================================================
  //
  // Essas eram globais.
  //
  // Não migramos os valores porque não existe uma forma segura
  // de saber a qual usuário eles pertenciam.
  //
  // ============================================================

  static const String _legacyAiMonthlyCardExpandedKey = 'dashboard_ai_monthly_card_expanded';

  static const String _legacyProfileCardExpandedKey = 'dashboard_profile_card_expanded';

  static const String _legacyStatisticsCardExpandedKey = 'dashboard_statistics_card_expanded';

  // ============================================================
  // LEGACY CLEANUP MARKER
  // ============================================================

  static const String _legacyCleanupMarker = 'dashboard_ui_v2_legacy_cleanup_done';

  // ============================================================
  // DEFAULT VALUES
  // ============================================================

  static const bool _defaultAiMonthlyCardExpanded = true;

  static const bool _defaultProfileCardExpanded = true;

  static const bool _defaultStatisticsCardExpanded = true;

  // ============================================================
  // CURRENT USER ID
  // ============================================================

  String? _currentUserId() {
    final userId = _supabase.auth.currentUser?.id.trim();

    if (userId ==
            null ||
        userId.isEmpty) {
      return null;
    }

    return userId;
  }

  // ============================================================
  // BUILD USER KEY
  // ============================================================
  //
  // IMPORTANTE:
  //
  // Capturamos o userId antes de qualquer operação async.
  //
  // Isso evita situações como:
  //
  // Conta A inicia uma gravação
  //      ↓
  // usuário troca para B
  //      ↓
  // operação termina usando a conta errada
  //
  // ============================================================

  String _buildUserKey({
    required String userId,
    required String preference,
  }) {
    final normalizedUserId = _normalizeUserIdForKey(
      userId,
    );

    return '$_namespace.'
        '$normalizedUserId.'
        '$preference';
  }

  // ============================================================
  // NORMALIZE USER ID
  // ============================================================

  String _normalizeUserIdForKey(
    String userId,
  ) {
    final normalized = userId.trim().replaceAll(
      RegExp(
        r'[^a-zA-Z0-9_-]',
      ),
      '_',
    );

    if (normalized.isEmpty) {
      throw ArgumentError(
        'userId inválido para preferência local.',
      );
    }

    return normalized;
  }

  // ============================================================
  // PREPARE PREFERENCES
  // ============================================================

  Future<
    SharedPreferences
  >
  _preferences() async {
    final preferences = await SharedPreferences.getInstance();

    await _removeLegacyGlobalPreferences(
      preferences,
    );

    return preferences;
  }

  // ============================================================
  // REMOVE LEGACY GLOBAL PREFERENCES
  // ============================================================
  //
  // Executado somente uma vez neste dispositivo.
  //
  // Os valores antigos são removidos em vez de migrados porque
  // poderiam pertencer a outra conta.
  //
  // ============================================================

  Future<
    void
  >
  _removeLegacyGlobalPreferences(
    SharedPreferences preferences,
  ) async {
    final alreadyCleaned =
        preferences.getBool(
          _legacyCleanupMarker,
        ) ??
        false;

    if (alreadyCleaned) {
      return;
    }

    await preferences.remove(
      _legacyAiMonthlyCardExpandedKey,
    );

    await preferences.remove(
      _legacyProfileCardExpandedKey,
    );

    await preferences.remove(
      _legacyStatisticsCardExpandedKey,
    );

    await preferences.setBool(
      _legacyCleanupMarker,
      true,
    );

    debugPrint(
      '[DASHBOARD UI] '
      'Preferências globais legadas removidas.',
    );
  }

  // ============================================================
  // LOAD BOOL
  // ============================================================

  Future<
    bool
  >
  _loadBool({
    required String preference,
    required bool defaultValue,
  }) async {
    // ==========================================================
    // CAPTURAR USUÁRIO
    // ==========================================================

    final userId = _currentUserId();

    // ==========================================================
    // SEM USUÁRIO
    // ==========================================================
    //
    // Não reutilizamos preferências de qualquer outra conta.
    //
    // ==========================================================

    if (userId ==
        null) {
      return defaultValue;
    }

    try {
      final preferences = await _preferences();

      final key = _buildUserKey(
        userId: userId,

        preference: preference,
      );

      return preferences.getBool(
            key,
          ) ??
          defaultValue;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[DASHBOARD UI] '
        'Erro ao carregar preferência '
        '$preference: $error',
      );

      debugPrint(
        '$stackTrace',
      );

      return defaultValue;
    }
  }

  // ============================================================
  // SAVE BOOL
  // ============================================================

  Future<
    bool
  >
  _saveBool({
    required String preference,
    required bool value,
  }) async {
    // ==========================================================
    // CAPTURAR USUÁRIO
    // ==========================================================

    final userId = _currentUserId();

    // ==========================================================
    // SEM USUÁRIO
    // ==========================================================

    if (userId ==
        null) {
      debugPrint(
        '[DASHBOARD UI] '
        'Preferência não salva: '
        'nenhum usuário autenticado.',
      );

      return false;
    }

    try {
      final preferences = await _preferences();

      final key = _buildUserKey(
        userId: userId,

        preference: preference,
      );

      return await preferences.setBool(
        key,
        value,
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[DASHBOARD UI] '
        'Erro ao salvar preferência '
        '$preference: $error',
      );

      debugPrint(
        '$stackTrace',
      );

      return false;
    }
  }

  // ============================================================
  // RESET BOOL
  // ============================================================

  Future<
    bool
  >
  _resetBool({
    required String preference,
  }) async {
    final userId = _currentUserId();

    if (userId ==
        null) {
      return false;
    }

    try {
      final preferences = await _preferences();

      final key = _buildUserKey(
        userId: userId,

        preference: preference,
      );

      return await preferences.remove(
        key,
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[DASHBOARD UI] '
        'Erro ao limpar preferência '
        '$preference: $error',
      );

      debugPrint(
        '$stackTrace',
      );

      return false;
    }
  }

  // ============================================================
  // AI MONTHLY CARD
  // ============================================================

  Future<
    bool
  >
  loadAiMonthlyCardExpanded() {
    return _loadBool(
      preference: _aiMonthlyCardExpandedPreference,

      defaultValue: _defaultAiMonthlyCardExpanded,
    );
  }

  Future<
    bool
  >
  saveAiMonthlyCardExpanded(
    bool isExpanded,
  ) {
    return _saveBool(
      preference: _aiMonthlyCardExpandedPreference,

      value: isExpanded,
    );
  }

  Future<
    bool
  >
  resetAiMonthlyCardExpanded() {
    return _resetBool(
      preference: _aiMonthlyCardExpandedPreference,
    );
  }

  // ============================================================
  // PROFILE CARD
  // ============================================================

  Future<
    bool
  >
  loadProfileCardExpanded() {
    return _loadBool(
      preference: _profileCardExpandedPreference,

      defaultValue: _defaultProfileCardExpanded,
    );
  }

  Future<
    bool
  >
  saveProfileCardExpanded(
    bool isExpanded,
  ) {
    return _saveBool(
      preference: _profileCardExpandedPreference,

      value: isExpanded,
    );
  }

  Future<
    bool
  >
  resetProfileCardExpanded() {
    return _resetBool(
      preference: _profileCardExpandedPreference,
    );
  }

  // ============================================================
  // STATISTICS CARD
  // ============================================================

  Future<
    bool
  >
  loadStatisticsCardExpanded() {
    return _loadBool(
      preference: _statisticsCardExpandedPreference,

      defaultValue: _defaultStatisticsCardExpanded,
    );
  }

  Future<
    bool
  >
  saveStatisticsCardExpanded(
    bool isExpanded,
  ) {
    return _saveBool(
      preference: _statisticsCardExpandedPreference,

      value: isExpanded,
    );
  }

  Future<
    bool
  >
  resetStatisticsCardExpanded() {
    return _resetBool(
      preference: _statisticsCardExpandedPreference,
    );
  }

  // ============================================================
  // RESET DASHBOARD PREFERENCES
  // ============================================================
  //
  // Remove SOMENTE as preferências da conta atual.
  //
  // Não altera:
  //
  // - preferências de outras contas;
  // - login;
  // - sessão;
  // - caches de outros módulos.
  //
  // ============================================================

  Future<
    bool
  >
  resetDashboardPreferences() async {
    final userId = _currentUserId();

    if (userId ==
        null) {
      return false;
    }

    try {
      final preferences = await _preferences();

      final keys =
          <
            String
          >[
            _buildUserKey(
              userId: userId,

              preference: _aiMonthlyCardExpandedPreference,
            ),

            _buildUserKey(
              userId: userId,

              preference: _profileCardExpandedPreference,
            ),

            _buildUserKey(
              userId: userId,

              preference: _statisticsCardExpandedPreference,
            ),
          ];

      var success = true;

      for (final key in keys) {
        final removed = await preferences.remove(
          key,
        );

        if (!removed &&
            preferences.containsKey(
              key,
            )) {
          success = false;
        }
      }

      debugPrint(
        '[DASHBOARD UI] '
        'Preferências do Dashboard '
        'da conta atual removidas.',
      );

      return success;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[DASHBOARD UI] '
        'Erro ao resetar preferências '
        'do Dashboard: $error',
      );

      debugPrint(
        '$stackTrace',
      );

      return false;
    }
  }
}
