import 'package:flutter/foundation.dart';

import '../models/private_api_config.dart';
import 'private_api_service.dart';

// ============================================================
// AI PROVIDER SOURCE
// ============================================================
//
// Identifica qual fonte respondeu à requisição.
//
// ============================================================

enum AiProviderSource {
  versin,
  privateApi,
}

// ============================================================
// AI PROVIDER RESULT
// ============================================================
//
// Resultado padronizado da geração.
//
// Permite saber:
//
// - texto retornado;
// - fonte utilizada;
// - provider;
// - modelo;
//
// Essa informação será importante para decidir se os tokens
// devem ou não ser descontados da cota Versin.
//
// ============================================================

class AiProviderResult {
  final String content;

  final AiProviderSource source;

  final String? provider;

  final String? model;

  const AiProviderResult({
    required this.content,
    required this.source,
    this.provider,
    this.model,
  });

  // ============================================================
  // HELPERS
  // ============================================================

  bool get usedVersinApi {
    return source ==
        AiProviderSource.versin;
  }

  bool get usedPrivateApi {
    return source ==
        AiProviderSource.privateApi;
  }

  // ============================================================
  // TO STRING
  // ============================================================

  @override
  String toString() {
    return 'AiProviderResult('
        'source: $source, '
        'provider: $provider, '
        'model: $model, '
        'contentLength: ${content.length}'
        ')';
  }
}

// ============================================================
// PRIVATE AI REQUEST
// ============================================================
//
// Dados enviados para o callback que fará a requisição privada.
//
// A API key nunca deve ser impressa em logs.
//
// ============================================================

class PrivateAiRequest {
  final String prompt;

  final String provider;

  final String apiKey;

  final String? model;

  final String? baseUrl;

  const PrivateAiRequest({
    required this.prompt,
    required this.provider,
    required this.apiKey,
    this.model,
    this.baseUrl,
  });
}

// ============================================================
// AI PROVIDER SERVICE
// ============================================================
//
// Decide automaticamente:
//
// ┌───────────────────────────────┐
// │ API privada está configurada? │
// └───────────────┬───────────────┘
//                 │
//          ┌──────┴──────┐
//          │             │
//         NÃO           SIM
//          │             │
//          ▼             ▼
//       VERSIN      API PRIVADA
//
// IMPORTANTE:
//
// Este serviço não conhece Widgets.
//
// Também não contabiliza a cota diretamente.
// Ele informa qual fonte foi usada através de AiProviderResult.
//
// ============================================================

class AiProviderService {
  // ============================================================
  // PRIVATE API
  // ============================================================

  final PrivateApiService privateApiService;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  AiProviderService({
    required this.privateApiService,
  });

  // ============================================================
  // GERAR
  // ============================================================
  //
  // generateWithVersin:
  //
  // callback para sua implementação atual.
  //
  // generateWithPrivateApi:
  //
  // callback que recebe os dados necessários para a API privada.
  //
  // ============================================================

  Future<
    AiProviderResult
  >
  generate({
    required String prompt,

    required Future<
      String
    >
    Function(
      String prompt,
    )
    generateWithVersin,

    required Future<
      String
    >
    Function(
      PrivateAiRequest request,
    )
    generateWithPrivateApi,
  }) async {
    final normalizedPrompt = prompt.trim();

    if (normalizedPrompt.isEmpty) {
      throw ArgumentError(
        'Prompt não pode ficar vazio.',
      );
    }

    // ==========================================================
    // CARREGAR CONFIGURAÇÃO
    // ==========================================================

    final config = await privateApiService.loadConfig();

    // ==========================================================
    // API PRIVADA
    // ==========================================================

    if (config.canUsePrivateApi) {
      return _generatePrivate(
        prompt: normalizedPrompt,

        config: config,

        generate: generateWithPrivateApi,
      );
    }

    // ==========================================================
    // API VERSIN
    // ==========================================================

    return _generateVersin(
      prompt: normalizedPrompt,

      generate: generateWithVersin,
    );
  }

  // ============================================================
  // API VERSIN
  // ============================================================

  Future<
    AiProviderResult
  >
  _generateVersin({
    required String prompt,

    required Future<
      String
    >
    Function(
      String prompt,
    )
    generate,
  }) async {
    debugPrint(
      '[AI PROVIDER] '
      'Utilizando API Versin.',
    );

    final content = await generate(
      prompt,
    );

    return AiProviderResult(
      content: content,

      source: AiProviderSource.versin,

      provider: 'versin',
    );
  }

  // ============================================================
  // API PRIVADA
  // ============================================================

  Future<
    AiProviderResult
  >
  _generatePrivate({
    required String prompt,

    required PrivateApiConfig config,

    required Future<
      String
    >
    Function(
      PrivateAiRequest request,
    )
    generate,
  }) async {
    debugPrint(
      '[AI PROVIDER] '
      'Utilizando API privada.',
    );

    debugPrint(
      '[AI PROVIDER] '
      'Provider: ${config.provider}',
    );

    if (config.hasModel) {
      debugPrint(
        '[AI PROVIDER] '
        'Modelo: ${config.model}',
      );
    }

    // ==========================================================
    // NUNCA:
    //
    // debugPrint(config.apiKey);
    //
    // ==========================================================

    final request = PrivateAiRequest(
      prompt: prompt,

      provider: config.provider,

      apiKey: config.apiKey,

      model: config.model,

      baseUrl: config.baseUrl,
    );

    final content = await generate(
      request,
    );

    return AiProviderResult(
      content: content,

      source: AiProviderSource.privateApi,

      provider: config.provider,

      model: config.model,
    );
  }

  // ============================================================
  // QUAL FONTE SERÁ USADA?
  // ============================================================
  //
  // Útil para interface.
  //
  // Exemplo:
  //
  // "API privada ativa"
  //
  // ============================================================

  Future<
    AiProviderSource
  >
  getCurrentSource() async {
    final config = await privateApiService.loadConfig();

    if (config.canUsePrivateApi) {
      return AiProviderSource.privateApi;
    }

    return AiProviderSource.versin;
  }

  // ============================================================
  // CONFIGURAÇÃO PRIVADA
  // ============================================================

  Future<
    PrivateApiConfig
  >
  getPrivateConfig() {
    return privateApiService.loadConfig();
  }

  // ============================================================
  // ESTÁ UTILIZANDO API PRIVADA?
  // ============================================================

  Future<
    bool
  >
  isUsingPrivateApi() async {
    final source = await getCurrentSource();

    return source ==
        AiProviderSource.privateApi;
  }
}
