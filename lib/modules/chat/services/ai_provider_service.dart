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
// VERSIN AI RESPONSE
// ============================================================
//
// Resposta interna produzida pelo callback da IA oficial Versin.
//
// Ela preserva:
//
// - conteúdo;
// - quota;
// - provider;
// - modelo.
//
// IMPORTANTE:
//
// A quota só existe no fluxo oficial Versin.
//
// API privada:
//
// PrivateAiClient
//      ↓
// resposta textual
//      ↓
// NÃO consome quota Versin.
//
// ============================================================

class VersinAiResponse {
  // ============================================================
  // CONTENT
  // ============================================================

  final String content;

  // ============================================================
  // QUOTA
  // ============================================================

  final Map<
    String,
    dynamic
  >?
  quota;

  // ============================================================
  // PROVIDER
  // ============================================================

  final String? provider;

  // ============================================================
  // MODEL
  // ============================================================

  final String? model;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  const VersinAiResponse({
    required this.content,
    this.quota,
    this.provider,
    this.model,
  });

  // ============================================================
  // HAS QUOTA
  // ============================================================

  bool get hasQuota {
    return quota !=
            null &&
        quota!.isNotEmpty;
  }

  // ============================================================
  // TO STRING
  // ============================================================

  @override
  String toString() {
    return 'VersinAiResponse('
        'contentLength: ${content.length}, '
        'hasQuota: $hasQuota, '
        'provider: $provider, '
        'model: $model'
        ')';
  }
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
// - quota Versin.
//
// Essa informação é utilizada pelo restante do aplicativo para:
//
// - atualizar a cota Versin;
// - indicar que uma API privada está ativa;
// - exibir provider/modelo utilizados;
// - impedir que API privada consuma quota Versin.
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
  // QUOTA
  // ============================================================
  //
  // Só deve ser preenchida quando:
  //
  // source == AiProviderSource.versin
  //
  // ============================================================

  final Map<
    String,
    dynamic
  >?
  quota;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  const AiProviderResult({
    required this.content,
    required this.source,
    this.provider,
    this.model,
    this.quota,
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
  // POSSUI QUOTA?
  // ============================================================

  bool get hasQuota {
    return usedVersinApi &&
        quota !=
            null &&
        quota!.isNotEmpty;
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
        'hasQuota: $hasQuota, '
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
// QUOTA:
//
// IA VERSIN
//      ↓
// backend retorna quota
//      ↓
// VersinAiResponse
//      ↓
// AiProviderResult.quota
//
// API PRIVADA
//      ↓
// quota = null
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
  // Deve retornar VersinAiResponse para preservar:
  //
  // - conteúdo;
  // - quota;
  // - provider;
  // - modelo.
  //
  // generateWithPrivateApi:
  //
  // executa o PrivateAiClient.
  //
  // Retorna somente String porque API privada:
  //
  // - não consome quota Versin;
  // - não utiliza quota do backend oficial.
  //
  // ============================================================

  Future<
    AiProviderResult
  >
  generate({
    required String prompt,

    required Future<
      VersinAiResponse
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
      VersinAiResponse
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

    // ==========================================================
    // REQUEST
    // ==========================================================

    final response = await generate(
      prompt,
    );

    // ==========================================================
    // CONTENT
    // ==========================================================

    final normalizedContent = response.content.trim();

    if (normalizedContent.isEmpty) {
      throw StateError(
        'A IA Versin retornou conteúdo vazio.',
      );
    }

    // ==========================================================
    // QUOTA
    // ==========================================================

    Map<
      String,
      dynamic
    >?
    normalizedQuota;

    final quota = response.quota;

    if (quota !=
            null &&
        quota.isNotEmpty) {
      normalizedQuota =
          Map<
            String,
            dynamic
          >.unmodifiable(
            Map<
              String,
              dynamic
            >.from(
              quota,
            ),
          );

      debugPrint(
        '[AI PROVIDER] '
        'Quota Versin recebida.',
      );
    } else {
      debugPrint(
        '[AI PROVIDER] '
        'Resposta Versin sem quota.',
      );
    }

    // ==========================================================
    // PROVIDER
    // ==========================================================

    final normalizedProvider = response.provider?.trim();

    // ==========================================================
    // MODEL
    // ==========================================================

    final normalizedModel = response.model?.trim();

    // ==========================================================
    // RESULT
    // ==========================================================

    return AiProviderResult(
      content: normalizedContent,

      source: AiProviderSource.versin,

      provider:
          normalizedProvider !=
                  null &&
              normalizedProvider.isNotEmpty
          ? normalizedProvider
          : 'versin',

      model:
          normalizedModel !=
                  null &&
              normalizedModel.isNotEmpty
          ? normalizedModel
          : null,

      quota: normalizedQuota,
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
        'A API privada estava ativa, '
        'mas a credencial não foi encontrada.',
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
    // IMPORTANTE:
    //
    // quota = null
    //
    // porque uma API privada nunca deve descontar a quota
    // oficial do Versin.
    //
    // ==========================================================

    return AiProviderResult(
      content: normalizedContent,

      source: AiProviderSource.privateApi,

      provider: config.providerLabel,

      model: config.normalizedModel,

      quota: null,
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
