import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/private_api_config.dart';
import 'ai_provider_service.dart';

// ============================================================
// PRIVATE AI CLIENT
// ============================================================
//
// Responsável por executar requisições reais utilizando
// a credencial privada configurada pelo usuário.
//
// Suporta:
//
// - OpenAI;
// - Groq;
// - OpenRouter;
// - Google Gemini;
// - Anthropic;
// - Custom OpenAI-compatible.
//
// IMPORTANTE:
//
// Este serviço:
//
// - NÃO salva API Keys;
// - NÃO conhece Widgets;
// - NÃO conhece Supabase;
// - NÃO altera a quota Versin;
// - NÃO imprime API Keys em logs.
//
// A chave chega através de PrivateAiRequest e existe somente
// durante o fluxo da requisição privada.
//
// O PrivateAiClient não persiste a chave em nenhum campo.
// A chave existe somente durante o request temporário da chamada.
//
// ============================================================

class PrivateAiClient {
  // ============================================================
  // HTTP CLIENT
  // ============================================================

  final http.Client _client;

  // ============================================================
  // TIMEOUT
  // ============================================================

  final Duration timeout;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  PrivateAiClient({
    http.Client? client,
    this.timeout = const Duration(
      seconds: 60,
    ),
  }) : _client =
           client ??
           http.Client();

  // ============================================================
  // ENDPOINTS
  // ============================================================

  static const String _openAiBaseUrl = 'https://api.openai.com/v1';

  static const String _groqBaseUrl = 'https://api.groq.com/openai/v1';

  static const String _openRouterBaseUrl = 'https://openrouter.ai/api/v1';

  static const String _geminiBaseUrl = 'https://generativelanguage.googleapis.com/v1beta';

  static const String _anthropicBaseUrl = 'https://api.anthropic.com/v1';

  // ============================================================
  // MODELOS PADRÃO
  // ============================================================
  //
  // O usuário pode sempre sobrescrever estes valores através
  // da configuração.
  //
  // ============================================================

  static const String _defaultOpenAiModel = 'gpt-4.1-mini';

  static const String _defaultGroqModel = 'llama-3.3-70b-versatile';

  static const String _defaultOpenRouterModel = 'openai/gpt-4.1-mini';

  static const String _defaultGeminiModel = 'gemini-2.5-flash';

  static const String _defaultAnthropicModel = 'claude-sonnet-4-20250514';

  // ============================================================
  // GERAR
  // ============================================================

  Future<
    String
  >
  generate(
    PrivateAiRequest request,
  ) async {
    final prompt = request.prompt.trim();

    if (prompt.isEmpty) {
      throw ArgumentError(
        'Prompt não pode ficar vazio.',
      );
    }

    // Valida a credencial sem manter uma referência extra.
    _requireApiKey(
      request,
    );

    final provider = _normalizeProvider(
      request.provider,
    );

    debugPrint(
      '[PRIVATE AI CLIENT] '
      'Provider: $provider',
    );

    if (request.model !=
            null &&
        request.model!.trim().isNotEmpty) {
      debugPrint(
        '[PRIVATE AI CLIENT] '
        'Modelo: ${request.model!.trim()}',
      );
    }

    switch (provider) {
      case PrivateApiConfig.providerOpenAi:
        return _generateOpenAiCompatible(
          request: request,

          baseUrl:
              _normalizeBaseUrl(
                request.baseUrl,
              ) ??
              _openAiBaseUrl,

          defaultModel: _defaultOpenAiModel,
        );

      case PrivateApiConfig.providerGroq:
        return _generateOpenAiCompatible(
          request: request,

          baseUrl:
              _normalizeBaseUrl(
                request.baseUrl,
              ) ??
              _groqBaseUrl,

          defaultModel: _defaultGroqModel,
        );

      case PrivateApiConfig.providerOpenRouter:
        return _generateOpenRouter(
          request,
        );

      case PrivateApiConfig.providerGemini:
        return _generateGemini(
          request,
        );

      case PrivateApiConfig.providerAnthropic:
        return _generateAnthropic(
          request,
        );

      case PrivateApiConfig.providerCustom:
        return _generateCustom(
          request,
        );

      default:
        throw UnsupportedError(
          'Provider não suportado: ${request.provider}',
        );
    }
  }

  // ============================================================
  // OPENAI COMPATIBLE
  // ============================================================
  //
  // Utilizado por:
  //
  // - OpenAI;
  // - Groq.
  //
  // ============================================================

  Future<
    String
  >
  _generateOpenAiCompatible({
    required PrivateAiRequest request,
    required String baseUrl,
    required String defaultModel,
  }) async {
    final model = _resolveModel(
      request.model,
      defaultModel,
    );

    final uri = Uri.parse(
      '$baseUrl/chat/completions',
    );

    final response = await _postJson(
      uri: uri,

      headers: {
        'Authorization': 'Bearer ${_requireApiKey(request)}',
      },

      body: {
        'model': model,

        'messages': [
          {
            'role': 'user',

            'content': request.prompt.trim(),
          },
        ],
      },
    );

    return _extractOpenAiCompatibleContent(
      response,
    );
  }

  // ============================================================
  // OPENROUTER
  // ============================================================

  Future<
    String
  >
  _generateOpenRouter(
    PrivateAiRequest request,
  ) async {
    final baseUrl =
        _normalizeBaseUrl(
          request.baseUrl,
        ) ??
        _openRouterBaseUrl;

    final model = _resolveModel(
      request.model,
      _defaultOpenRouterModel,
    );

    final uri = Uri.parse(
      '$baseUrl/chat/completions',
    );

    final response = await _postJson(
      uri: uri,

      headers: {
        'Authorization': 'Bearer ${_requireApiKey(request)}',
      },

      body: {
        'model': model,

        'messages': [
          {
            'role': 'user',

            'content': request.prompt.trim(),
          },
        ],
      },
    );

    return _extractOpenAiCompatibleContent(
      response,
    );
  }

  // ============================================================
  // GEMINI
  // ============================================================

  Future<
    String
  >
  _generateGemini(
    PrivateAiRequest request,
  ) async {
    final baseUrl =
        _normalizeBaseUrl(
          request.baseUrl,
        ) ??
        _geminiBaseUrl;

    final model = _resolveModel(
      request.model,
      _defaultGeminiModel,
    );

    final apiKey = _requireApiKey(
      request,
    );

    final uri = Uri.parse(
      '$baseUrl/models/$model:generateContent',
    );

    final response = await _postJson(
      uri: uri,

      headers: {
        'x-goog-api-key': apiKey,
      },

      body: {
        'contents': [
          {
            'role': 'user',

            'parts': [
              {
                'text': request.prompt.trim(),
              },
            ],
          },
        ],
      },
    );

    return _extractGeminiContent(
      response,
    );
  }

  // ============================================================
  // ANTHROPIC
  // ============================================================

  Future<
    String
  >
  _generateAnthropic(
    PrivateAiRequest request,
  ) async {
    final baseUrl =
        _normalizeBaseUrl(
          request.baseUrl,
        ) ??
        _anthropicBaseUrl;

    final model = _resolveModel(
      request.model,
      _defaultAnthropicModel,
    );

    final uri = Uri.parse(
      '$baseUrl/messages',
    );

    final response = await _postJson(
      uri: uri,

      headers: {
        'x-api-key': _requireApiKey(
          request,
        ),

        'anthropic-version': '2023-06-01',
      },

      body: {
        'model': model,

        'max_tokens': 2048,

        'messages': [
          {
            'role': 'user',

            'content': request.prompt.trim(),
          },
        ],
      },
    );

    return _extractAnthropicContent(
      response,
    );
  }

  // ============================================================
  // CUSTOM
  // ============================================================
  //
  // O provider Custom é tratado como uma API compatível com
  // Chat Completions.
  //
  // Exemplo de baseUrl:
  //
  // https://meu-servidor.com/v1
  //
  // O endpoint final será:
  //
  // /chat/completions
  //
  // ============================================================

  Future<
    String
  >
  _generateCustom(
    PrivateAiRequest request,
  ) async {
    final baseUrl = _normalizeBaseUrl(
      request.baseUrl,
    );

    if (baseUrl ==
        null) {
      throw StateError(
        'Base URL obrigatória para provider Custom.',
      );
    }

    final model = request.model?.trim();

    if (model ==
            null ||
        model.isEmpty) {
      throw StateError(
        'Informe o modelo para o provider Custom.',
      );
    }

    return _generateOpenAiCompatible(
      request: request,

      baseUrl: baseUrl,

      defaultModel: model,
    );
  }

  // ============================================================
  // POST JSON
  // ============================================================

  Future<
    Map<
      String,
      dynamic
    >
  >
  _postJson({
    required Uri uri,
    required Map<
      String,
      String
    >
    headers,
    required Map<
      String,
      dynamic
    >
    body,
  }) async {
    debugPrint(
      '[PRIVATE AI CLIENT] '
      'POST ${uri.host}${uri.path}',
    );

    try {
      final response = await _client
          .post(
            uri,

            headers: {
              'Content-Type': 'application/json',

              'Accept': 'application/json',

              ...headers,
            },

            body: jsonEncode(
              body,
            ),
          )
          .timeout(
            timeout,
          );

      debugPrint(
        '[PRIVATE AI CLIENT] '
        'Status: ${response.statusCode}',
      );

      final decoded = _decodeResponse(
        response.body,
      );

      if (response.statusCode <
              200 ||
          response.statusCode >=
              300) {
        throw PrivateAiException(
          message: _extractErrorMessage(
            decoded,
            response.body,
          ),

          statusCode: response.statusCode,
        );
      }

      return decoded;
    } on TimeoutException {
      throw const PrivateAiException(
        message: 'A API privada demorou demais para responder.',
      );
    } on PrivateAiException {
      rethrow;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[PRIVATE AI CLIENT] '
        'Erro: $error',
      );

      debugPrint(
        '[PRIVATE AI CLIENT] '
        'Stack trace: $stackTrace',
      );

      throw PrivateAiException(
        message: 'Falha ao conectar com a API privada: $error',
      );
    }
  }

  // ============================================================
  // DECODE
  // ============================================================

  Map<
    String,
    dynamic
  >
  _decodeResponse(
    String body,
  ) {
    if (body.trim().isEmpty) {
      return {};
    }

    try {
      final decoded = jsonDecode(
        body,
      );

      if (decoded
          is Map) {
        return Map<
          String,
          dynamic
        >.from(
          decoded,
        );
      }

      throw const FormatException(
        'Resposta JSON não é um objeto.',
      );
    } on FormatException {
      throw const PrivateAiException(
        message: 'O provedor retornou uma resposta em formato inválido.',
      );
    }
  }

  // ============================================================
  // OPENAI COMPATIBLE CONTENT
  // ============================================================

  String _extractOpenAiCompatibleContent(
    Map<
      String,
      dynamic
    >
    data,
  ) {
    final choices = data['choices'];

    if (choices
            is! List ||
        choices.isEmpty) {
      throw const PrivateAiException(
        message: 'O provedor não retornou nenhuma resposta.',
      );
    }

    final firstChoice = choices.first;

    if (firstChoice
        is! Map) {
      throw const PrivateAiException(
        message: 'Formato de resposta incompatível.',
      );
    }

    final choice =
        Map<
          String,
          dynamic
        >.from(
          firstChoice,
        );

    final message = choice['message'];

    if (message
        is Map) {
      final messageMap =
          Map<
            String,
            dynamic
          >.from(
            message,
          );

      final content = messageMap['content'];

      final parsed = _parseFlexibleText(
        content,
      );

      if (parsed !=
              null &&
          parsed.isNotEmpty) {
        return parsed;
      }
    }

    final text = choice['text']?.toString().trim();

    if (text !=
            null &&
        text.isNotEmpty) {
      return text;
    }

    throw const PrivateAiException(
      message: 'O provedor respondeu sem conteúdo.',
    );
  }

  // ============================================================
  // GEMINI CONTENT
  // ============================================================

  String _extractGeminiContent(
    Map<
      String,
      dynamic
    >
    data,
  ) {
    final candidates = data['candidates'];

    if (candidates
            is! List ||
        candidates.isEmpty) {
      throw const PrivateAiException(
        message: 'O Gemini não retornou candidatos.',
      );
    }

    final candidate = candidates.first;

    if (candidate
        is! Map) {
      throw const PrivateAiException(
        message: 'Resposta inválida do Gemini.',
      );
    }

    final candidateMap =
        Map<
          String,
          dynamic
        >.from(
          candidate,
        );

    final content = candidateMap['content'];

    if (content
        is! Map) {
      throw const PrivateAiException(
        message: 'O Gemini respondeu sem conteúdo.',
      );
    }

    final contentMap =
        Map<
          String,
          dynamic
        >.from(
          content,
        );

    final parts = contentMap['parts'];

    if (parts
        is! List) {
      throw const PrivateAiException(
        message: 'O Gemini respondeu sem texto.',
      );
    }

    final buffer = StringBuffer();

    for (final part in parts) {
      if (part
          is! Map) {
        continue;
      }

      final partMap =
          Map<
            String,
            dynamic
          >.from(
            part,
          );

      final text = partMap['text']?.toString().trim();

      if (text ==
              null ||
          text.isEmpty) {
        continue;
      }

      if (buffer.isNotEmpty) {
        buffer.writeln();
      }

      buffer.write(
        text,
      );
    }

    final result = buffer.toString().trim();

    if (result.isEmpty) {
      throw const PrivateAiException(
        message: 'O Gemini respondeu sem texto.',
      );
    }

    return result;
  }

  // ============================================================
  // ANTHROPIC CONTENT
  // ============================================================

  String _extractAnthropicContent(
    Map<
      String,
      dynamic
    >
    data,
  ) {
    final content = data['content'];

    if (content
        is! List) {
      throw const PrivateAiException(
        message: 'A Anthropic respondeu sem conteúdo.',
      );
    }

    final buffer = StringBuffer();

    for (final item in content) {
      if (item
          is! Map) {
        continue;
      }

      final itemMap =
          Map<
            String,
            dynamic
          >.from(
            item,
          );

      if (itemMap['type'] !=
          'text') {
        continue;
      }

      final text = itemMap['text']?.toString().trim();

      if (text ==
              null ||
          text.isEmpty) {
        continue;
      }

      if (buffer.isNotEmpty) {
        buffer.writeln();
      }

      buffer.write(
        text,
      );
    }

    final result = buffer.toString().trim();

    if (result.isEmpty) {
      throw const PrivateAiException(
        message: 'A Anthropic respondeu sem texto.',
      );
    }

    return result;
  }

  // ============================================================
  // TEXTO FLEXÍVEL
  // ============================================================
  //
  // Alguns providers podem retornar content como String;
  // outros podem usar uma lista de blocos.
  //
  // ============================================================

  String? _parseFlexibleText(
    dynamic content,
  ) {
    if (content
        is String) {
      final normalized = content.trim();

      return normalized.isEmpty
          ? null
          : normalized;
    }

    if (content
        is! List) {
      return null;
    }

    final buffer = StringBuffer();

    for (final item in content) {
      if (item
          is String) {
        final normalized = item.trim();

        if (normalized.isEmpty) {
          continue;
        }

        if (buffer.isNotEmpty) {
          buffer.writeln();
        }

        buffer.write(
          normalized,
        );

        continue;
      }

      if (item
          is! Map) {
        continue;
      }

      final map =
          Map<
            String,
            dynamic
          >.from(
            item,
          );

      final text = map['text']?.toString().trim();

      if (text ==
              null ||
          text.isEmpty) {
        continue;
      }

      if (buffer.isNotEmpty) {
        buffer.writeln();
      }

      buffer.write(
        text,
      );
    }

    final result = buffer.toString().trim();

    if (result.isEmpty) {
      return null;
    }

    return result;
  }

  // ============================================================
  // ERROR MESSAGE
  // ============================================================

  String _extractErrorMessage(
    Map<
      String,
      dynamic
    >
    data,
    String rawBody,
  ) {
    final error = data['error'];

    if (error
        is Map) {
      final errorMap =
          Map<
            String,
            dynamic
          >.from(
            error,
          );

      final message = errorMap['message']?.toString().trim();

      if (message !=
              null &&
          message.isNotEmpty) {
        return _sanitizeErrorMessage(
          message,
        );
      }
    }

    if (error
            is String &&
        error.trim().isNotEmpty) {
      return _sanitizeErrorMessage(
        error.trim(),
      );
    }

    final message = data['message']?.toString().trim();

    if (message !=
            null &&
        message.isNotEmpty) {
      return _sanitizeErrorMessage(
        message,
      );
    }

    final detail = data['detail']?.toString().trim();

    if (detail !=
            null &&
        detail.isNotEmpty) {
      return _sanitizeErrorMessage(
        detail,
      );
    }

    if (rawBody.trim().isNotEmpty) {
      const maxLength = 300;

      final normalized = rawBody.trim();

      if (normalized.length <=
          maxLength) {
        return _sanitizeErrorMessage(
          normalized,
        );
      }

      return _sanitizeErrorMessage(
        '${normalized.substring(0, maxLength)}...',
      );
    }

    return 'O provedor recusou a requisição.';
  }

  // ============================================================
  // SANITIZAR MENSAGEM DE ERRO
  // ============================================================

  String _sanitizeErrorMessage(
    String value,
  ) {
    var sanitized = value.trim();

    if (sanitized.isEmpty) {
      return 'O provedor recusou a requisição.';
    }

    sanitized = sanitized.replaceAll(
      RegExp(
        r'Bearer\s+[A-Za-z0-9._~+/=-]+',
        caseSensitive: false,
      ),
      'Bearer [REDACTED]',
    );

    sanitized = sanitized.replaceAll(
      RegExp(
        r'(?i)(api[_ -]?key|x-api-key|authorization)\s*[:=]\s*[^,\s}]+',
      ),
      '[CREDENTIAL REDACTED]',
    );

    const maxLength = 500;

    if (sanitized.length >
        maxLength) {
      sanitized = '${sanitized.substring(0, maxLength)}...';
    }

    return sanitized;
  }

  // ============================================================
  // API KEY DA REQUISIÇÃO
  // ============================================================
  //
  // Centraliza a leitura temporária da chave.
  //
  // A chave:
  //
  // - não é armazenada em campo;
  // - não é adicionada a logs;
  // - não é incluída em exceptions;
  // - existe apenas enquanto a requisição está em execução.
  //
  // ============================================================

  String _requireApiKey(
    PrivateAiRequest request,
  ) {
    final value = request.apiKey.trim();

    if (value.isEmpty) {
      throw StateError(
        'API Key privada não configurada.',
      );
    }

    return value;
  }

  // ============================================================
  // PROVIDER
  // ============================================================

  String _normalizeProvider(
    String provider,
  ) {
    final config = PrivateApiConfig(
      provider: provider,

      enabled: false,

      hasApiKey: false,
    );

    return config.normalizedProvider;
  }

  // ============================================================
  // MODEL
  // ============================================================

  String _resolveModel(
    String? configuredModel,
    String defaultModel,
  ) {
    final normalized = configuredModel?.trim();

    if (normalized ==
            null ||
        normalized.isEmpty) {
      return defaultModel;
    }

    return normalized;
  }

  // ============================================================
  // BASE URL
  // ============================================================

  String? _normalizeBaseUrl(
    String? value,
  ) {
    final raw = value?.trim();

    if (raw ==
            null ||
        raw.isEmpty) {
      return null;
    }

    var normalized = raw;

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

    final uri = Uri.tryParse(
      normalized,
    );

    if (uri ==
            null ||
        !uri.hasScheme ||
        uri.host.isEmpty) {
      throw ArgumentError(
        'Base URL inválida.',
      );
    }

    if (uri.scheme !=
            'https' &&
        uri.scheme !=
            'http') {
      throw ArgumentError(
        'A Base URL deve utilizar HTTP ou HTTPS.',
      );
    }

    return normalized;
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  void dispose() {
    _client.close();
  }
}

// ============================================================
// PRIVATE AI EXCEPTION
// ============================================================

class PrivateAiException
    implements
        Exception {
  final String message;

  final int? statusCode;

  const PrivateAiException({
    required this.message,
    this.statusCode,
  });

  // ============================================================
  // HELPERS
  // ============================================================

  bool get isUnauthorized {
    return statusCode ==
            401 ||
        statusCode ==
            403;
  }

  bool get isRateLimited {
    return statusCode ==
        429;
  }

  bool get isServerError {
    final code = statusCode;

    if (code ==
        null) {
      return false;
    }

    return code >=
            500 &&
        code <=
            599;
  }

  // ============================================================
  // TO STRING
  // ============================================================

  @override
  String toString() {
    if (statusCode ==
        null) {
      return 'PrivateAiException: $message';
    }

    return 'PrivateAiException'
        '(statusCode: $statusCode, message: $message)';
  }
}
