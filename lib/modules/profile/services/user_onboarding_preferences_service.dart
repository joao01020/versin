import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================================
// USER ONBOARDING PREFERENCES SERVICE
// ============================================================
//
// Responsável por persistir estados de onboarding e dicas
// apresentadas ao usuário.
//
// Exemplos:
//
// - usuário já viu o destaque do botão "Como usar a IA";
// - usuário já viu determinada dica;
// - usuário já concluiu determinado onboarding;
//
// IMPORTANTE:
//
// Cada preferência é isolada pelo ID imutável da conta:
//
// user_onboarding_v1.<USER_ID>.<PREFERENCE>
//
// Exemplo:
//
// user_onboarding_v1.abc123.ai_guide_hint_seen
//
// Dessa forma:
//
// usuário A
//     ↓
// preferências A
//
// usuário B
//     ↓
// preferências B
//
// Mesmo utilizando o mesmo computador.
//
// NÃO utilizar:
//
// - username;
// - display name;
// - email;
//
// como identificador.
//
// O UUID da autenticação é a referência correta.
//
// Este service também NÃO deve armazenar:
//
// - JWT;
// - access token;
// - API keys;
// - senhas;
// - dados sensíveis.
//
// SharedPreferences guarda somente pequenos estados locais
// relacionados à experiência/onboarding.
//
// ============================================================

class UserOnboardingPreferencesService {
  // ============================================================
  // NAMESPACE
  // ============================================================

  static const String _namespace = 'user_onboarding_v1';

  // ============================================================
  // PREFERENCES
  // ============================================================

  static const String _aiGuideHintSeenPreference = 'ai_guide_hint_seen';

  // ============================================================
  // DEFAULTS
  // ============================================================

  static const bool _defaultAiGuideHintSeen = false;

  // ============================================================
  // SUPABASE
  // ============================================================

  SupabaseClient get _supabase => Supabase.instance.client;

  // ============================================================
  // CURRENT USER ID
  // ============================================================
  //
  // Utilizamos o UUID da sessão autenticada.
  //
  // O username pode mudar.
  // O nome pode mudar.
  // O email pode mudar.
  //
  // O UUID da conta é a identidade adequada para separar
  // as preferências locais.
  //
  // ============================================================

  String? get _currentUserId {
    final user = _supabase.auth.currentUser;

    if (user ==
        null) {
      return null;
    }

    final userId = user.id.trim();

    if (userId.isEmpty) {
      return null;
    }

    return userId;
  }

  // ============================================================
  // BUILD USER KEY
  // ============================================================

  String _buildUserKey({
    required String userId,
    required String preference,
  }) {
    return '$_namespace.$userId.$preference';
  }

  // ============================================================
  // REQUIRE USER ID
  // ============================================================
  //
  // Operações de escrita não devem criar preferência global
  // quando não existir uma conta autenticada.
  //
  // ============================================================

  String? _resolveCurrentUserId() {
    final userId = _currentUserId;

    if (userId ==
            null ||
        userId.isEmpty) {
      return null;
    }

    return userId;
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
    try {
      final userId = _resolveCurrentUserId();

      if (userId ==
          null) {
        return defaultValue;
      }

      final preferences = await SharedPreferences.getInstance();

      final key = _buildUserKey(
        userId: userId,
        preference: preference,
      );

      return preferences.getBool(
            key,
          ) ??
          defaultValue;
    } catch (
      _
    ) {
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
    try {
      final userId = _resolveCurrentUserId();

      if (userId ==
          null) {
        return false;
      }

      final preferences = await SharedPreferences.getInstance();

      final key = _buildUserKey(
        userId: userId,
        preference: preference,
      );

      return await preferences.setBool(
        key,
        value,
      );
    } catch (
      _
    ) {
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
    try {
      final userId = _resolveCurrentUserId();

      if (userId ==
          null) {
        return false;
      }

      final preferences = await SharedPreferences.getInstance();

      final key = _buildUserKey(
        userId: userId,
        preference: preference,
      );

      return await preferences.remove(
        key,
      );
    } catch (
      _
    ) {
      return false;
    }
  }

  // ============================================================
  // AI GUIDE HINT SEEN
  // ============================================================
  //
  // Indica se o usuário atual já recebeu o destaque visual
  // inicial do botão:
  //
  // ⓘ Como usar a IA
  //
  // false:
  //
  // primeira entrada
  //      ↓
  // botão pulsa 3 vezes
  //
  // true:
  //
  // usuário já viu
  //      ↓
  // botão permanece normal
  //
  // ============================================================

  Future<
    bool
  >
  loadAiGuideHintSeen() {
    return _loadBool(
      preference: _aiGuideHintSeenPreference,
      defaultValue: _defaultAiGuideHintSeen,
    );
  }

  // ============================================================
  // SAVE AI GUIDE HINT SEEN
  // ============================================================

  Future<
    bool
  >
  saveAiGuideHintSeen(
    bool seen,
  ) {
    return _saveBool(
      preference: _aiGuideHintSeenPreference,
      value: seen,
    );
  }

  // ============================================================
  // MARK AI GUIDE HINT AS SEEN
  // ============================================================
  //
  // Helper semântico para o caso mais comum.
  //
  // Em vez de:
  //
  // saveAiGuideHintSeen(true)
  //
  // podemos usar:
  //
  // markAiGuideHintSeen()
  //
  // ============================================================

  Future<
    bool
  >
  markAiGuideHintSeen() {
    return saveAiGuideHintSeen(
      true,
    );
  }

  // ============================================================
  // RESET AI GUIDE HINT
  // ============================================================
  //
  // Útil para:
  //
  // - desenvolvimento;
  // - testes;
  // - reset de onboarding.
  //
  // Depois do reset, o botão poderá voltar a chamar atenção
  // na próxima entrada da conta atual.
  //
  // ============================================================

  Future<
    bool
  >
  resetAiGuideHintSeen() {
    return _resetBool(
      preference: _aiGuideHintSeenPreference,
    );
  }

  // ============================================================
  // RESET CURRENT USER ONBOARDING
  // ============================================================
  //
  // Remove TODAS as preferências pertencentes ao namespace de
  // onboarding da conta atual.
  //
  // Atualmente existe:
  //
  // - ai_guide_hint_seen
  //
  // Futuramente podem existir:
  //
  // - library_hint_seen
  // - studio_hint_seen
  // - match_onboarding_completed
  // - professional_profile_hint_seen
  //
  // O método continuará funcionando sem precisar manter uma
  // lista manual de todas as chaves.
  //
  // ============================================================

  Future<
    bool
  >
  resetCurrentUserOnboarding() async {
    try {
      final userId = _resolveCurrentUserId();

      if (userId ==
          null) {
        return false;
      }

      final preferences = await SharedPreferences.getInstance();

      final userPrefix = '$_namespace.$userId.';

      final keys = preferences
          .getKeys()
          .where(
            (
              key,
            ) => key.startsWith(
              userPrefix,
            ),
          )
          .toList(
            growable: false,
          );

      var success = true;

      for (final key in keys) {
        final removed = await preferences.remove(
          key,
        );

        if (!removed) {
          success = false;
        }
      }

      return success;
    } catch (
      _
    ) {
      return false;
    }
  }

  // ============================================================
  // HAS AUTHENTICATED USER
  // ============================================================
  //
  // Pode ser útil para telas que precisam saber se é seguro
  // consultar/salvar onboarding.
  //
  // ============================================================

  bool get hasAuthenticatedUser {
    return _resolveCurrentUserId() !=
        null;
  }
}
