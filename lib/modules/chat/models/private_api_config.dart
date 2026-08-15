// ============================================================
// PRIVATE API CONFIG
// ============================================================
//
// Representa a configuração da API privada do usuário.
//
// Este model é utilizado por:
//
// PrivateApiSettingsPage
//        ↓
// PrivateApiService
//        ↓
// AiProviderService
//        ↓
// PrivateAiClient
//
// IMPORTANTE:
//
// Este model NÃO:
//
// - salva dados;
// - faz requisições HTTP;
// - conhece widgets;
// - conhece Supabase;
// - imprime a API Key em logs.
//
// ============================================================

class PrivateApiConfig {
  // ============================================================
  // PROVIDERS SUPORTADOS
  // ============================================================

  static const String providerOpenAi = 'openai';

  static const String providerAnthropic = 'anthropic';

  static const String providerGemini = 'gemini';

  static const String providerGroq = 'groq';

  static const String providerOpenRouter = 'openrouter';

  static const String providerCustom = 'custom';

  // ============================================================
  // PROVIDER
  // ============================================================

  final String provider;

  // ============================================================
  // API KEY
  // ============================================================

  final String apiKey;

  // ============================================================
  // MODELO
  // ============================================================

  final String? model;

  // ============================================================
  // BASE URL
  // ============================================================

  final String? baseUrl;

  // ============================================================
  // ATIVA?
  // ============================================================

  final bool enabled;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  const PrivateApiConfig({
    required this.provider,
    required this.apiKey,
    required this.enabled,
    this.model,
    this.baseUrl,
  });

  // ============================================================
  // CONFIGURAÇÃO VAZIA
  // ============================================================

  factory PrivateApiConfig.empty() {
    return const PrivateApiConfig(
      provider: 'OpenAI',

      apiKey: '',

      enabled: false,
    );
  }

  // ============================================================
  // API KEY
  // ============================================================

  bool get hasApiKey {
    return apiKey.trim().isNotEmpty;
  }

  // ============================================================
  // MODELO
  // ============================================================

  bool get hasModel {
    return normalizedModel !=
        null;
  }

  String? get normalizedModel {
    final value = model?.trim();

    if (value ==
            null ||
        value.isEmpty) {
      return null;
    }

    return value;
  }

  // ============================================================
  // BASE URL
  // ============================================================

  bool get hasBaseUrl {
    return normalizedBaseUrl !=
        null;
  }

  String? get normalizedBaseUrl {
    final rawValue = baseUrl?.trim();

    if (rawValue ==
            null ||
        rawValue.isEmpty) {
      return null;
    }

    var normalized = rawValue;

    // ==========================================================
    // REMOVER "/" FINAL
    // ==========================================================

    while (normalized.endsWith(
      '/',
    )) {
      normalized = normalized.substring(
        0,
        normalized.length -
            1,
      );
    }

    if (normalized.isEmpty) {
      return null;
    }

    return normalized;
  }

  // ============================================================
  // PROVIDER NORMALIZADO
  // ============================================================
  //
  // A interface pode salvar:
  //
  // OpenAI
  // Google Gemini
  // OpenRouter
  //
  // Internamente padronizamos para:
  //
  // openai
  // gemini
  // openrouter
  //
  // ============================================================

  String get normalizedProvider {
    final value = provider.trim().toLowerCase();

    switch (value) {
      // ========================================================
      // OPENAI
      // ========================================================

      case 'openai':
      case 'open ai':
        return providerOpenAi;

      // ========================================================
      // ANTHROPIC
      // ========================================================

      case 'anthropic':
      case 'claude':
        return providerAnthropic;

      // ========================================================
      // GEMINI
      // ========================================================

      case 'gemini':
      case 'google':
      case 'google gemini':
        return providerGemini;

      // ========================================================
      // GROQ
      // ========================================================

      case 'groq':
        return providerGroq;

      // ========================================================
      // OPENROUTER
      // ========================================================

      case 'openrouter':
      case 'open router':
        return providerOpenRouter;

      // ========================================================
      // CUSTOM
      // ========================================================

      case 'custom':
      case 'personalizado':
      case 'personalizada':
        return providerCustom;

      // ========================================================
      // DESCONHECIDO
      // ========================================================

      default:
        return value;
    }
  }

  // ============================================================
  // PROVIDER É VÁLIDO?
  // ============================================================

  bool get hasValidProvider {
    return supportedProviders.contains(
      normalizedProvider,
    );
  }

  // ============================================================
  // LISTA DE PROVIDERS
  // ============================================================

  static const Set<
    String
  >
  supportedProviders = {
    providerOpenAi,
    providerAnthropic,
    providerGemini,
    providerGroq,
    providerOpenRouter,
    providerCustom,
  };

  // ============================================================
  // NOME VISUAL
  // ============================================================

  String get providerLabel {
    switch (normalizedProvider) {
      case providerOpenAi:
        return 'OpenAI';

      case providerAnthropic:
        return 'Anthropic';

      case providerGemini:
        return 'Google Gemini';

      case providerGroq:
        return 'Groq';

      case providerOpenRouter:
        return 'OpenRouter';

      case providerCustom:
        return 'Custom';

      default:
        final normalized = provider.trim();

        if (normalized.isEmpty) {
          return 'Desconhecido';
        }

        return normalized;
    }
  }

  // ============================================================
  // PROVIDERS
  // ============================================================

  bool get isOpenAi {
    return normalizedProvider ==
        providerOpenAi;
  }

  bool get isAnthropic {
    return normalizedProvider ==
        providerAnthropic;
  }

  bool get isGemini {
    return normalizedProvider ==
        providerGemini;
  }

  bool get isGroq {
    return normalizedProvider ==
        providerGroq;
  }

  bool get isOpenRouter {
    return normalizedProvider ==
        providerOpenRouter;
  }

  bool get isCustom {
    return normalizedProvider ==
        providerCustom;
  }

  // ============================================================
  // API COMPATÍVEL COM OPENAI
  // ============================================================
  //
  // Esses providers podem compartilhar parte importante da
  // estrutura de requisição.
  //
  // O PrivateAiClient decidirá os detalhes.
  //
  // ============================================================

  bool get usesOpenAiCompatibleApi {
    switch (normalizedProvider) {
      case providerOpenAi:
      case providerGroq:
      case providerOpenRouter:
      case providerCustom:
        return true;

      default:
        return false;
    }
  }

  // ============================================================
  // BASE URL PERSONALIZÁVEL
  // ============================================================

  bool get supportsCustomBaseUrl {
    return isCustom ||
        isOpenAi ||
        isGroq ||
        isOpenRouter;
  }

  // ============================================================
  // PODE USAR API PRIVADA?
  // ============================================================

  bool get canUsePrivateApi {
    if (!enabled) {
      return false;
    }

    if (!hasApiKey) {
      return false;
    }

    if (!hasValidProvider) {
      return false;
    }

    // ==========================================================
    // CUSTOM PRECISA DE URL
    // ==========================================================

    if (isCustom &&
        !hasBaseUrl) {
      return false;
    }

    return true;
  }

  // ============================================================
  // CONFIGURAÇÃO COMPLETA?
  // ============================================================

  bool get isValid {
    return canUsePrivateApi;
  }

  // ============================================================
  // MOTIVO DA CONFIGURAÇÃO SER INVÁLIDA
  // ============================================================

  String? get validationError {
    if (!enabled) {
      return 'A API privada está desativada.';
    }

    if (!hasApiKey) {
      return 'Informe uma API Key.';
    }

    if (!hasValidProvider) {
      return 'Provider não suportado.';
    }

    if (isCustom &&
        !hasBaseUrl) {
      return 'Informe a Base URL para o provider Custom.';
    }

    return null;
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  PrivateApiConfig copyWith({
    String? provider,
    String? apiKey,
    String? model,
    String? baseUrl,
    bool? enabled,
    bool clearApiKey = false,
    bool clearModel = false,
    bool clearBaseUrl = false,
  }) {
    return PrivateApiConfig(
      provider:
          provider ??
          this.provider,

      apiKey: clearApiKey
          ? ''
          : apiKey ??
                this.apiKey,

      model: clearModel
          ? null
          : model ??
                this.model,

      baseUrl: clearBaseUrl
          ? null
          : baseUrl ??
                this.baseUrl,

      enabled:
          enabled ??
          this.enabled,
    );
  }

  // ============================================================
  // ATIVAR
  // ============================================================

  PrivateApiConfig enable() {
    return copyWith(
      enabled: true,
    );
  }

  // ============================================================
  // DESATIVAR
  // ============================================================

  PrivateApiConfig disable() {
    return copyWith(
      enabled: false,
    );
  }

  // ============================================================
  // TO MAP
  // ============================================================
  //
  // IMPORTANTE:
  //
  // Este método inclui a API Key.
  //
  // Deve ser usado somente quando realmente for necessário
  // serializar a configuração completa para armazenamento
  // seguro.
  //
  // Para logs, UI, Supabase ou analytics, utilize:
  //
  // toSafeMap()
  //
  // ============================================================

  Map<
    String,
    dynamic
  >
  toMap() {
    return {
      'provider': normalizedProvider,

      'api_key': apiKey,

      'model': normalizedModel,

      'base_url': normalizedBaseUrl,

      'enabled': enabled,
    };
  }

  // ============================================================
  // MAP SEGURO
  // ============================================================
  //
  // NÃO CONTÉM API KEY.
  //
  // Pode ser usado para:
  //
  // - logs;
  // - analytics;
  // - debug;
  // - persistência de metadados;
  // - Supabase, caso você queira sincronizar apenas configuração.
  //
  // ============================================================

  Map<
    String,
    dynamic
  >
  toSafeMap() {
    return {
      'provider': normalizedProvider,

      'provider_label': providerLabel,

      'has_api_key': hasApiKey,

      'model': normalizedModel,

      'base_url': normalizedBaseUrl,

      'enabled': enabled,

      'valid': isValid,
    };
  }

  // ============================================================
  // FROM MAP
  // ============================================================

  factory PrivateApiConfig.fromMap(
    Map<
      String,
      dynamic
    >
    map,
  ) {
    final provider =
        _parseString(
          map['provider'],
        ) ??
        _parseString(
          map['provider_key'],
        ) ??
        'OpenAI';

    return PrivateApiConfig(
      provider: provider,

      apiKey:
          _parseString(
            map['api_key'],
          ) ??
          '',

      model: _nullableString(
        map['model'],
      ),

      baseUrl: _nullableString(
        map['base_url'],
      ),

      enabled: _parseBool(
        map['enabled'],
      ),
    );
  }

  // ============================================================
  // STRING
  // ============================================================

  static String? _parseString(
    dynamic value,
  ) {
    if (value ==
        null) {
      return null;
    }

    final text = value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    return text;
  }

  // ============================================================
  // STRING OPCIONAL
  // ============================================================

  static String? _nullableString(
    dynamic value,
  ) {
    return _parseString(
      value,
    );
  }

  // ============================================================
  // BOOL
  // ============================================================

  static bool _parseBool(
    dynamic value,
  ) {
    if (value
        is bool) {
      return value;
    }

    if (value
        is num) {
      return value !=
          0;
    }

    final normalized = value?.toString().trim().toLowerCase();

    switch (normalized) {
      case 'true':
      case '1':
      case 'yes':
      case 'sim':
      case 'enabled':
        return true;

      default:
        return false;
    }
  }

  // ============================================================
  // IGUALDADE DE CONFIGURAÇÃO
  // ============================================================

  bool hasSameConnectionConfig(
    PrivateApiConfig other,
  ) {
    return normalizedProvider ==
            other.normalizedProvider &&
        apiKey ==
            other.apiKey &&
        normalizedModel ==
            other.normalizedModel &&
        normalizedBaseUrl ==
            other.normalizedBaseUrl &&
        enabled ==
            other.enabled;
  }

  // ============================================================
  // TO STRING
  // ============================================================
  //
  // NUNCA COLOCAR:
  //
  // apiKey
  //
  // aqui.
  //
  // ============================================================

  @override
  String toString() {
    return 'PrivateApiConfig('
        'provider: $providerLabel, '
        'providerKey: $normalizedProvider, '
        'hasApiKey: $hasApiKey, '
        'model: $normalizedModel, '
        'baseUrl: $normalizedBaseUrl, '
        'enabled: $enabled, '
        'valid: $isValid'
        ')';
  }
}
