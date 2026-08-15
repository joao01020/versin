import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/private_api_config.dart';

// ============================================================
// PRIVATE API SERVICE
// ============================================================
//
// Responsável pelo armazenamento seguro da configuração da
// API privada.
//
// A API Key é armazenada utilizando flutter_secure_storage.
//
// IMPORTANTE:
//
// Não utilizar:
//
// - SharedPreferences para API Key;
// - logs contendo a chave;
// - código-fonte;
// - arquivo .dart;
// - banco público.
//
// ============================================================

class PrivateApiService {
  // ============================================================
  // STORAGE
  // ============================================================

  final FlutterSecureStorage _storage;

  // ============================================================
  // KEYS
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
  // SALVAR CONFIGURAÇÃO
  // ============================================================

  Future<
    void
  >
  saveConfig(
    PrivateApiConfig config,
  ) async {
    final provider = config.provider.trim();

    final apiKey = config.apiKey.trim();

    if (provider.isEmpty) {
      throw ArgumentError(
        'Provider inválido.',
      );
    }

    if (apiKey.isEmpty) {
      throw ArgumentError(
        'API Key não pode ficar vazia.',
      );
    }

    // ==========================================================
    // PROVIDER
    // ==========================================================

    await _storage.write(
      key: _providerKey,

      value: provider,
    );

    // ==========================================================
    // API KEY
    // ==========================================================

    await _storage.write(
      key: _apiKeyKey,

      value: apiKey,
    );

    // ==========================================================
    // MODEL
    // ==========================================================

    await _writeNullable(
      key: _modelKey,

      value: config.model,
    );

    // ==========================================================
    // BASE URL
    // ==========================================================

    await _writeNullable(
      key: _baseUrlKey,

      value: config.baseUrl,
    );

    // ==========================================================
    // ENABLED
    // ==========================================================

    await _storage.write(
      key: _enabledKey,

      value: config.enabled
          ? 'true'
          : 'false',
    );

    debugPrint(
      '[PRIVATE API] '
      'Configuração salva.',
    );

    debugPrint(
      '[PRIVATE API] '
      'Provider: $provider',
    );

    debugPrint(
      '[PRIVATE API] '
      'Ativa: ${config.enabled}',
    );

    // NÃO imprimir apiKey.
  }

  // ============================================================
  // CARREGAR CONFIGURAÇÃO
  // ============================================================

  Future<
    PrivateApiConfig
  >
  loadConfig() async {
    try {
      final provider = await _storage.read(
        key: _providerKey,
      );

      final apiKey = await _storage.read(
        key: _apiKeyKey,
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

      return PrivateApiConfig(
        provider:
            provider?.trim().isNotEmpty ==
                true
            ? provider!.trim()
            : 'OpenAI',

        apiKey:
            apiKey?.trim() ??
            '',

        model: _normalizeNullable(
          model,
        ),

        baseUrl: _normalizeNullable(
          baseUrl,
        ),

        enabled:
            enabled ==
            'true',
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
  // API PRIVADA ATIVA?
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
    final apiKey = await _storage.read(
      key: _apiKeyKey,
    );

    return apiKey !=
            null &&
        apiKey.trim().isNotEmpty;
  }

  // ============================================================
  // LER API KEY
  // ============================================================
  //
  // Deve ser utilizada apenas pelo serviço responsável por
  // montar a requisição.
  //
  // Não enviar esse valor para logs.
  //
  // ============================================================

  Future<
    String?
  >
  readApiKey() async {
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
  }

  // ============================================================
  // ATIVAR
  // ============================================================

  Future<
    void
  >
  enable() async {
    if (!await hasApiKey()) {
      throw StateError(
        'Nenhuma API Key privada foi configurada.',
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
  // REMOVER API KEY
  // ============================================================

  Future<
    void
  >
  removeApiKey() async {
    await _storage.delete(
      key: _apiKeyKey,
    );

    await disable();

    debugPrint(
      '[PRIVATE API] '
      'API Key removida.',
    );
  }

  // ============================================================
  // REMOVER TODA CONFIGURAÇÃO
  // ============================================================

  Future<
    void
  >
  clear() async {
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
      'Configuração removida.',
    );
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
  // NORMALIZAR
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
}
