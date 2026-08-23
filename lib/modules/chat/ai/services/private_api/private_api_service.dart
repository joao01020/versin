import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../models/private_api_config.dart';

// ============================================================
// PRIVATE API SERVICE
// ============================================================
//
// Responsável pelo armazenamento seguro da API privada.
//
// RESPONSABILIDADES:
//
// - salvar a API Key no secure storage;
// - ler a API Key somente quando necessário;
// - salvar metadados da configuração;
// - ativar/desativar a API privada;
// - remover a chave;
// - carregar PrivateApiConfig SEM expor a chave.
//
// IMPORTANTE:
//
// A API Key:
//
// - NÃO fica em PrivateApiConfig;
// - NÃO deve ir para logs;
// - NÃO deve ir para SharedPreferences;
// - NÃO deve ir para Supabase em texto puro;
// - NÃO deve ser enviada para analytics;
// - NÃO deve aparecer em toString();
//
// ============================================================

class PrivateApiService {
  // ============================================================
  // STORAGE
  // ============================================================

  final FlutterSecureStorage _storage;

  // ============================================================
  // STORAGE KEYS
  // ============================================================

  static const String _providerKey = 'versin_private_api_provider';

  static const String _apiKeyKey = 'versin_private_api_key';

  static const String _modelKey = 'versin_private_api_model';

  static const String _baseUrlKey = 'versin_private_api_base_url';

  static const String _enabledKey = 'versin_private_api_enabled';

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  PrivateApiService({
    FlutterSecureStorage? storage,
  }) : _storage =
           storage ??
           const FlutterSecureStorage();

  // ============================================================
  // SALVAR CONFIGURAÇÃO COMPLETA
  // ============================================================
  //
  // Recebe:
  //
  // - metadados seguros;
  // - API Key separadamente.
  //
  // Dessa forma a chave nunca precisa entrar em
  // PrivateApiConfig.
  //
  // ============================================================

  Future<
    void
  >
  saveConfig({
    required PrivateApiConfig config,
    required String apiKey,
  }) async {
    final normalizedApiKey = apiKey.trim();

    final normalizedProvider = config.normalizedProvider;

    // ==========================================================
    // VALIDAR PROVIDER
    // ==========================================================

    if (!config.hasValidProvider) {
      throw ArgumentError(
        'Provider inválido ou não suportado.',
      );
    }

    // ==========================================================
    // VALIDAR API KEY
    // ==========================================================

    if (normalizedApiKey.isEmpty) {
      throw ArgumentError(
        'API Key não pode ficar vazia.',
      );
    }

    // ==========================================================
    // CUSTOM PRECISA DE BASE URL
    // ==========================================================

    if (config.isCustom &&
        !config.hasBaseUrl) {
      throw ArgumentError(
        'Provider Custom exige uma Base URL.',
      );
    }

    try {
      // ========================================================
      // PROVIDER
      // ========================================================

      await _storage.write(
        key: _providerKey,

        value: normalizedProvider,
      );

      // ========================================================
      // API KEY
      // ========================================================
      //
      // Único ponto onde a chave é persistida.
      //
      // ========================================================

      await _storage.write(
        key: _apiKeyKey,

        value: normalizedApiKey,
      );

      // ========================================================
      // MODEL
      // ========================================================

      await _writeNullable(
        key: _modelKey,

        value: config.normalizedModel,
      );

      // ========================================================
      // BASE URL
      // ========================================================

      await _writeNullable(
        key: _baseUrlKey,

        value: config.normalizedBaseUrl,
      );

      // ========================================================
      // ENABLED
      // ========================================================

      await _storage.write(
        key: _enabledKey,

        value: config.enabled
            ? 'true'
            : 'false',
      );

      // ========================================================
      // LOG SEGURO
      // ========================================================

      debugPrint(
        '[PRIVATE API] '
        'Configuração salva.',
      );

      debugPrint(
        '[PRIVATE API] '
        'Provider: ${config.providerLabel}',
      );

      debugPrint(
        '[PRIVATE API] '
        'Modelo: ${config.normalizedModel ?? 'padrão'}',
      );

      debugPrint(
        '[PRIVATE API] '
        'Ativa: ${config.enabled}',
      );

      // ========================================================
      // NUNCA:
      //
      // debugPrint(apiKey);
      //
      // ========================================================
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[PRIVATE API] '
        'Erro ao salvar configuração: $error',
      );

      debugPrint(
        '[PRIVATE API] '
        'Stack trace: $stackTrace',
      );

      rethrow;
    }
  }

  // ============================================================
  // SALVAR SOMENTE METADADOS
  // ============================================================
  //
  // Útil quando:
  //
  // - trocar provider;
  // - trocar modelo;
  // - trocar base URL;
  // - ativar/desativar.
  //
  // Não altera a API Key já armazenada.
  //
  // ============================================================

  Future<
    void
  >
  saveMetadata(
    PrivateApiConfig config,
  ) async {
    if (!config.hasValidProvider) {
      throw ArgumentError(
        'Provider inválido ou não suportado.',
      );
    }

    if (config.isCustom &&
        !config.hasBaseUrl) {
      throw ArgumentError(
        'Provider Custom exige uma Base URL.',
      );
    }

    await _storage.write(
      key: _providerKey,

      value: config.normalizedProvider,
    );

    await _writeNullable(
      key: _modelKey,

      value: config.normalizedModel,
    );

    await _writeNullable(
      key: _baseUrlKey,

      value: config.normalizedBaseUrl,
    );

    await _storage.write(
      key: _enabledKey,

      value: config.enabled
          ? 'true'
          : 'false',
    );

    debugPrint(
      '[PRIVATE API] '
      'Metadados atualizados.',
    );
  }

  // ============================================================
  // ATUALIZAR SOMENTE API KEY
  // ============================================================

  Future<
    void
  >
  saveApiKey(
    String apiKey,
  ) async {
    final normalized = apiKey.trim();

    if (normalized.isEmpty) {
      throw ArgumentError(
        'API Key não pode ficar vazia.',
      );
    }

    await _storage.write(
      key: _apiKeyKey,

      value: normalized,
    );

    debugPrint(
      '[PRIVATE API] '
      'API Key atualizada.',
    );
  }

  // ============================================================
  // CARREGAR CONFIGURAÇÃO
  // ============================================================
  //
  // IMPORTANTE:
  //
  // A API Key NÃO é retornada.
  //
  // Retornamos apenas:
  //
  // - provider;
  // - model;
  // - baseUrl;
  // - enabled;
  // - hasApiKey.
  //
  // ============================================================

  Future<
    PrivateApiConfig
  >
  loadConfig() async {
    try {
      final provider = await _storage.read(
        key: _providerKey,
      );

      final model = await _storage.read(
        key: _modelKey,
      );

      final baseUrl = await _storage.read(
        key: _baseUrlKey,
      );

      final enabled = await _storage.read(
        key: _enabledKey,
      );

      // ========================================================
      // SÓ VERIFICAR EXISTÊNCIA
      // ========================================================
      //
      // Não colocamos a chave dentro do config.
      //
      // ========================================================

      final storedApiKey = await _storage.read(
        key: _apiKeyKey,
      );

      final hasStoredApiKey =
          storedApiKey !=
              null &&
          storedApiKey.trim().isNotEmpty;

      return PrivateApiConfig(
        provider: _normalizeProviderOrDefault(
          provider,
        ),

        model: _normalizeNullable(
          model,
        ),

        baseUrl: _normalizeNullable(
          baseUrl,
        ),

        enabled:
            enabled ==
            'true',

        hasApiKey: hasStoredApiKey,
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[PRIVATE API] '
        'Erro ao carregar configuração: $error',
      );

      debugPrint(
        '[PRIVATE API] '
        'Stack trace: $stackTrace',
      );

      return PrivateApiConfig.empty();
    }
  }

  // ============================================================
  // API PRIVADA PODE SER USADA?
  // ============================================================

  Future<
    bool
  >
  isEnabled() async {
    final config = await loadConfig();

    return config.canUsePrivateApi;
  }

  // ============================================================
  // POSSUI API KEY?
  // ============================================================

  Future<
    bool
  >
  hasApiKey() async {
    try {
      final value = await _storage.read(
        key: _apiKeyKey,
      );

      return value !=
              null &&
          value.trim().isNotEmpty;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[PRIVATE API] '
        'Erro ao verificar API Key: $error',
      );

      debugPrint(
        '[PRIVATE API] '
        'Stack trace: $stackTrace',
      );

      return false;
    }
  }

  // ============================================================
  // LER API KEY
  // ============================================================
  //
  // ESTE MÉTODO DEVE SER USADO SOMENTE NO MOMENTO DA REQUISIÇÃO.
  //
  // Fluxo esperado:
  //
  // ChatRepository
  //      ↓
  // PrivateApiService.readApiKey()
  //      ↓
  // PrivateAiClient
  //      ↓
  // provider
  //
  // Não guardar o resultado em campos permanentes.
  //
  // ============================================================

  Future<
    String?
  >
  readApiKey() async {
    try {
      final value = await _storage.read(
        key: _apiKeyKey,
      );

      if (value ==
          null) {
        return null;
      }

      final normalized = value.trim();

      if (normalized.isEmpty) {
        return null;
      }

      return normalized;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[PRIVATE API] '
        'Erro ao acessar API Key.',
      );

      debugPrint(
        '[PRIVATE API] '
        'Stack trace: $stackTrace',
      );

      rethrow;
    }
  }

  // ============================================================
  // ATIVAR
  // ============================================================

  Future<
    void
  >
  enable() async {
    final config = await loadConfig();

    if (!config.hasApiKey) {
      throw StateError(
        'Nenhuma API Key privada foi configurada.',
      );
    }

    if (!config.hasValidProvider) {
      throw StateError(
        'Provider inválido.',
      );
    }

    if (config.isCustom &&
        !config.hasBaseUrl) {
      throw StateError(
        'Provider Custom exige uma Base URL.',
      );
    }

    await _storage.write(
      key: _enabledKey,

      value: 'true',
    );

    debugPrint(
      '[PRIVATE API] '
      'API privada ativada.',
    );
  }

  // ============================================================
  // DESATIVAR
  // ============================================================

  Future<
    void
  >
  disable() async {
    await _storage.write(
      key: _enabledKey,

      value: 'false',
    );

    debugPrint(
      '[PRIVATE API] '
      'API privada desativada.',
    );
  }

  // ============================================================
  // ALTERAR ENABLED
  // ============================================================

  Future<
    void
  >
  setEnabled(
    bool enabled,
  ) async {
    if (enabled) {
      await enable();

      return;
    }

    await disable();
  }

  // ============================================================
  // REMOVER API KEY
  // ============================================================
  //
  // Ao remover a chave:
  //
  // - API privada é automaticamente desativada.
  //
  // ============================================================

  Future<
    void
  >
  removeApiKey() async {
    try {
      await _storage.delete(
        key: _apiKeyKey,
      );

      await disable();

      debugPrint(
        '[PRIVATE API] '
        'API Key removida deste dispositivo.',
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[PRIVATE API] '
        'Erro ao remover API Key: $error',
      );

      debugPrint(
        '[PRIVATE API] '
        'Stack trace: $stackTrace',
      );

      rethrow;
    }
  }

  // ============================================================
  // REMOVER TODA CONFIGURAÇÃO
  // ============================================================

  Future<
    void
  >
  clear() async {
    try {
      await Future.wait(
        [
          _storage.delete(
            key: _providerKey,
          ),

          _storage.delete(
            key: _apiKeyKey,
          ),

          _storage.delete(
            key: _modelKey,
          ),

          _storage.delete(
            key: _baseUrlKey,
          ),

          _storage.delete(
            key: _enabledKey,
          ),
        ],
      );

      debugPrint(
        '[PRIVATE API] '
        'Toda configuração privada foi removida.',
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[PRIVATE API] '
        'Erro ao limpar configuração: $error',
      );

      debugPrint(
        '[PRIVATE API] '
        'Stack trace: $stackTrace',
      );

      rethrow;
    }
  }

  // ============================================================
  // CONFIGURAÇÃO EXISTE?
  // ============================================================

  Future<
    bool
  >
  hasConfiguration() async {
    final config = await loadConfig();

    return config.hasApiKey ||
        config.hasModel ||
        config.hasBaseUrl ||
        config.enabled;
  }

  // ============================================================
  // SALVAR STRING OPCIONAL
  // ============================================================

  Future<
    void
  >
  _writeNullable({
    required String key,
    required String? value,
  }) async {
    final normalized = value?.trim();

    if (normalized ==
            null ||
        normalized.isEmpty) {
      await _storage.delete(
        key: key,
      );

      return;
    }

    await _storage.write(
      key: key,

      value: normalized,
    );
  }

  // ============================================================
  // NORMALIZAR STRING
  // ============================================================

  String? _normalizeNullable(
    String? value,
  ) {
    if (value ==
        null) {
      return null;
    }

    final normalized = value.trim();

    if (normalized.isEmpty) {
      return null;
    }

    return normalized;
  }

  // ============================================================
  // NORMALIZAR PROVIDER
  // ============================================================

  String _normalizeProviderOrDefault(
    String? value,
  ) {
    final normalized = value?.trim();

    if (normalized ==
            null ||
        normalized.isEmpty) {
      return 'OpenAI';
    }

    return normalized;
  }
}
