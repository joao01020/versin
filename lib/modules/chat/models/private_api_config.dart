// ============================================================
// PRIVATE API CONFIG
// ============================================================
//
// Representa SOMENTE os metadados da configuração da API
// privada do usuário.
//
// IMPORTANTE:
//
// A API KEY NÃO FICA NESTE MODEL.
//
// A chave deve permanecer exclusivamente no:
//
// PrivateApiService
//        ↓
// flutter_secure_storage
//
// Este model pode circular com segurança por:
//
// - UI;
// - controllers;
// - services;
// - logs controlados;
// - analytics;
// - Supabase, caso sejam salvos apenas metadados.
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
  // PROVIDERS SUPORTADOS
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
  // PROVIDER
  // ============================================================

  final String provider;

  // ============================================================
  // MODELO
  // ============================================================

  final String? model;

  // ============================================================
  // BASE URL
  // ============================================================

  final String? baseUrl;

  // ============================================================
  // API PRIVADA ATIVA?
  // ============================================================

  final bool enabled;

  // ============================================================
  // EXISTE UMA API KEY SALVA?
  // ============================================================
  //
  // Este campo informa apenas a existência da chave.
  //
  // Ele NÃO contém a chave.
  //
  // ============================================================

  final bool hasApiKey;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  const PrivateApiConfig({
    required this.provider,
    required this.enabled,
    required this.hasApiKey,
    this.model,
    this.baseUrl,
  });

  // ============================================================
  // CONFIGURAÇÃO VAZIA
  // ============================================================

  factory PrivateApiConfig.empty() {
    return const PrivateApiConfig(
      provider: 'OpenAI',

      enabled: false,

      hasApiKey: false,
    );
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

  String get normalizedProvider {
    final value = provider.trim().toLowerCase();

    switch (value) {
      case 'openai':
      case 'open ai':
        return providerOpenAi;

      case 'anthropic':
      case 'claude':
        return providerAnthropic;

      case 'gemini':
      case 'google':
      case 'google gemini':
        return providerGemini;

      case 'groq':
        return providerGroq;

      case 'openrouter':
      case 'open router':
        return providerOpenRouter;

      case 'custom':
      case 'personalizado':
      case 'personalizada':
        return providerCustom;

      default:
        return value;
    }
  }

  // ============================================================
  // PROVIDER VÁLIDO?
  // ============================================================

  bool get hasValidProvider {
    return supportedProviders.contains(
      normalizedProvider,
    );
  }

  // ============================================================
  // LABEL DO PROVIDER
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
  // COMPATÍVEL COM OPENAI
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
  // SUPORTA BASE URL CUSTOMIZADA
  // ============================================================

  bool get supportsCustomBaseUrl {
    return isCustom ||
        isOpenAi ||
        isGroq ||
        isOpenRouter;
  }

  // ============================================================
  // API PRIVADA PODE SER UTILIZADA?
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

    if (isCustom &&
        !hasBaseUrl) {
      return false;
    }

    return true;
  }

  // ============================================================
  // CONFIGURAÇÃO VÁLIDA
  // ============================================================

  bool get isValid {
    return canUsePrivateApi;
  }

  // ============================================================
  // MOTIVO DA CONFIGURAÇÃO INVÁLIDA
  // ============================================================

  String? get validationError {
    if (!enabled) {
      return 'A API privada está desativada.';
    }

    if (!hasApiKey) {
      return 'Nenhuma API Key privada está salva neste dispositivo.';
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
    String? model,
    String? baseUrl,
    bool? enabled,
    bool? hasApiKey,
    bool clearModel = false,
    bool clearBaseUrl = false,
  }) {
    return PrivateApiConfig(
      provider:
          provider ??
          this.provider,

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

      hasApiKey:
          hasApiKey ??
          this.hasApiKey,
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
  // MARCAR QUE EXISTE CHAVE
  // ============================================================

  PrivateApiConfig withStoredApiKey() {
    return copyWith(
      hasApiKey: true,
    );
  }

  // ============================================================
  // MARCAR QUE A CHAVE FOI REMOVIDA
  // ============================================================

  PrivateApiConfig withoutStoredApiKey() {
    return copyWith(
      hasApiKey: false,

      enabled: false,
    );
  }

  // ============================================================
  // TO MAP
  // ============================================================
  //
  // SEGURO:
  //
  // NÃO contém API Key.
  //
  // ============================================================

  Map<
    String,
    dynamic
  >
  toMap() {
    return {
      'provider': normalizedProvider,

      'provider_label': providerLabel,

      'model': normalizedModel,

      'base_url': normalizedBaseUrl,

      'enabled': enabled,

      'has_api_key': hasApiKey,
    };
  }

  // ============================================================
  // SAFE MAP
  // ============================================================
  //
  // Mantido como alias de toMap() para compatibilidade com
  // código anterior.
  //
  // Ambos são seguros porque este model não contém segredo.
  //
  // ============================================================

  Map<
    String,
    dynamic
  >
  toSafeMap() {
    return {
      ...toMap(),

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

      model: _nullableString(
        map['model'],
      ),

      baseUrl: _nullableString(
        map['base_url'],
      ),

      enabled: _parseBool(
        map['enabled'],
      ),

      hasApiKey: _parseBool(
        map['has_api_key'],
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
  // MESMA CONFIGURAÇÃO DE CONEXÃO
  // ============================================================
  //
  // API Key propositalmente não participa porque ela não faz
  // mais parte deste objeto.
  //
  // ============================================================

  bool hasSameConnectionConfig(
    PrivateApiConfig other,
  ) {
    return normalizedProvider ==
            other.normalizedProvider &&
        normalizedModel ==
            other.normalizedModel &&
        normalizedBaseUrl ==
            other.normalizedBaseUrl &&
        enabled ==
            other.enabled &&
        hasApiKey ==
            other.hasApiKey;
  }

  // ============================================================
  // TO STRING
  // ============================================================
  //
  // Seguro por construção:
  //
  // não existe API Key neste model.
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
