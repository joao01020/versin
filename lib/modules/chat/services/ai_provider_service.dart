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
// - modelo.
//
// Essa informação é utilizada pelo restante do aplicativo para:
//
// - saber se a cota Versin deve ser atualizada;
// - indicar que uma API privada está ativa;
// - exibir provider/modelo utilizados.
//
// ============================================================

class AiProviderResult {
  // ============================================================
  // CONTEÚDO
  // ============================================================

  final String content;

  // ============================================================
  // FONTE
  // ============================================================

  final AiProviderSource source;

  // ============================================================
  // PROVIDER
  // ============================================================

  final String? provider;

  // ============================================================
  // MODELO
  // ============================================================

  final String? model;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  const AiProviderResult({
    required this.content,
    required this.source,
    this.provider,
    this.model,
  });

  // ============================================================
  // USOU VERSIN?
  // ============================================================

  bool get usedVersinApi {
    return source ==
        AiProviderSource.versin;
  }

  // ============================================================
  // USOU API PRIVADA?
  // ============================================================

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
// Objeto de curta duração criado SOMENTE no momento em que
// uma requisição privada será enviada.
//
// IMPORTANTE:
//
// A API Key não fica em:
//
// - PrivateApiConfig;
// - controllers;
// - widgets;
// - estado da aplicação.
//
// Ela é lida do PrivateApiService imediatamente antes da
// requisição e colocada temporariamente neste objeto.
//
// Nunca imprimir este objeto inteiro em logs.
//
// ============================================================

class PrivateAiRequest {
  // ============================================================
  // PROMPT
  // ============================================================

  final String prompt;

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
  // CONSTRUTOR
  // ============================================================

  const PrivateAiRequest({
    required this.prompt,
    required this.provider,
    required this.apiKey,
    this.model,
    this.baseUrl,
  });

  // ============================================================
  // TO STRING SEGURO
  // ============================================================
  //
  // API Key propositalmente NÃO aparece.
  //
  // ============================================================

  @override
  String toString() {
    return 'PrivateAiRequest('
        'provider: $provider, '
        'model: $model, '
        'baseUrl: $baseUrl, '
        'promptLength: ${prompt.length}'
        ')';
  }
}

// ============================================================
// AI PROVIDER SERVICE
// ============================================================
//
// Responsável por decidir qual fonte deve responder:
//
// ┌───────────────────────────────┐
// │ API privada pode ser usada?   │
// └───────────────┬───────────────┘
//                 │
//          ┌──────┴──────┐
//          │             │
//         NÃO           SIM
//          │             │
//          ▼             ▼
//       VERSIN       API PRIVADA
//
// SEGURANÇA:
//
// - PrivateApiConfig NÃO contém API Key;
// - a chave só é lida quando realmente necessária;
// - a chave não é logada;
// - a chave não é devolvida em AiProviderResult.
//
// ============================================================

class AiProviderService {
  // ============================================================
  // PRIVATE API SERVICE
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
  // executa a infraestrutura oficial do Versin.
  //
  // generateWithPrivateApi:
  //
  // executa o PrivateAiClient.
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
    // CARREGAR APENAS METADADOS
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
      'Utilizando IA Versin.',
    );

    final content = await generate(
      prompt,
    );

    final normalizedContent = content.trim();

    if (normalizedContent.isEmpty) {
      throw StateError(
        'A IA Versin retornou conteúdo vazio.',
      );
    }

    return AiProviderResult(
      content: normalizedContent,

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
    // ==========================================================
    // VALIDAÇÃO
    // ==========================================================

    if (!config.canUsePrivateApi) {
      throw StateError(
        config.validationError ??
            'A API privada não pode ser utilizada.',
      );
    }

    debugPrint(
      '[AI PROVIDER] '
      'Utilizando API privada.',
    );

    debugPrint(
      '[AI PROVIDER] '
      'Provider: ${config.providerLabel}',
    );

    if (config.hasModel) {
      debugPrint(
        '[AI PROVIDER] '
        'Modelo: ${config.normalizedModel}',
      );
    }

    // ==========================================================
    // LER API KEY SOMENTE AGORA
    // ==========================================================
    //
    // A chave não estava em memória dentro do config.
    //
    // Ela é recuperada somente imediatamente antes da chamada.
    //
    // ==========================================================

    final apiKey = await privateApiService.readApiKey();

    if (apiKey ==
            null ||
        apiKey.isEmpty) {
      // ========================================================
      // ESTADO INCONSISTENTE
      // ========================================================
      //
      // Exemplo:
      //
      // enabled = true
      // hasApiKey do config ficou verdadeiro
      // mas a chave foi removida externamente.
      //
      // ========================================================

      await privateApiService.disable();

      throw StateError(
        'A API privada estava ativa, mas a credencial não foi encontrada.',
      );
    }

    // ==========================================================
    // REQUEST TEMPORÁRIO
    // ==========================================================

    final request = PrivateAiRequest(
      prompt: prompt,

      provider: config.normalizedProvider,

      apiKey: apiKey,

      model: config.normalizedModel,

      baseUrl: config.normalizedBaseUrl,
    );

    // ==========================================================
    // EXECUTAR
    // ==========================================================

    final content = await generate(
      request,
    );

    final normalizedContent = content.trim();

    if (normalizedContent.isEmpty) {
      throw StateError(
        'A API privada retornou conteúdo vazio.',
      );
    }

    // ==========================================================
    // RESULTADO
    // ==========================================================
    //
    // A API Key NÃO é devolvida.
    //
    // ==========================================================

    return AiProviderResult(
      content: normalizedContent,

      source: AiProviderSource.privateApi,

      provider: config.providerLabel,

      model: config.normalizedModel,
    );
  }

  // ============================================================
  // QUAL FONTE ESTÁ CONFIGURADA?
  // ============================================================
  //
  // Útil para:
  //
  // - Settings;
  // - barra de IA;
  // - badges;
  // - status visual.
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

  // ============================================================
  // ESTÁ UTILIZANDO IA VERSIN?
  // ============================================================

  Future<
    bool
  >
  isUsingVersinApi() async {
    return !await isUsingPrivateApi();
  }

  // ============================================================
  // POSSUI API PRIVADA CONFIGURADA?
  // ============================================================

  Future<
    bool
  >
  hasPrivateApiConfiguration() async {
    final config = await privateApiService.loadConfig();

    return config.hasApiKey;
  }

  // ============================================================
  // ATIVAR API PRIVADA
  // ============================================================

  Future<
    void
  >
  enablePrivateApi() async {
    await privateApiService.enable();
  }

  // ============================================================
  // DESATIVAR API PRIVADA
  // ============================================================

  Future<
    void
  >
  disablePrivateApi() async {
    await privateApiService.disable();
  }
}
