import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:versin/features/rhymes/data/repositories/rhymes_repository.dart';

// ============================================================
// RHYMES AI SERVICE
// ============================================================
//
// Responsável pelo fluxo legado de IA utilizado pelo módulo
// de rimas.
//
// Retira do RhymesController:
//
// - requisição HTTP;
// - jsonDecode;
// - tratamento de status HTTP;
// - timeout;
// - timer de conexão;
// - isLoading da requisição;
// - tratamento de erros;
// - interpretação inicial da quota.
//
// IMPORTANTE:
//
// O fluxo principal do Chat continua sendo:
//
// ChatController
//      ↓
// ChatRepository
//      ↓
// AiProviderService
//
// Este service existe para manter os fluxos antigos do módulo
// de rimas organizados enquanto a migração é concluída.
//
// ============================================================

class RhymesAiService
    extends
        ChangeNotifier {
  // ============================================================
  // REPOSITORY
  // ============================================================

  final RhymesRepository repository;

  // ============================================================
  // TIMER
  // ============================================================

  Timer? _connectionTimer;

  // ============================================================
  // ESTADO
  // ============================================================

  bool _isLoading = false;

  int _connectionSeconds = 0;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  RhymesAiService({
    RhymesRepository? repository,
  }) : repository =
           repository ??
           RhymesRepository();

  // ============================================================
  // GETTERS
  // ============================================================

  bool get isLoading => _isLoading;

  int get connectionSeconds => _connectionSeconds;

  // ============================================================
  // FETCH
  // ============================================================

  Future<
    RhymesAiResult
  >
  fetchAiResponse({
    required String message,
    required List<
      String
    >
    vocabulary,
    required int bpm,
    required String vibe,
    required String technique,
    String? apiKey,
  }) async {
    final normalizedMessage = message.trim();

    if (normalizedMessage.isEmpty) {
      return const RhymesAiResult(
        role: 'assistant',

        content: 'Digite uma mensagem antes de enviar.',
      );
    }

    // ==========================================================
    // INICIAR CONEXÃO
    // ==========================================================

    _startConnectionTimer();

    try {
      debugPrint(
        '[RHYMES AI] '
        'Enviando mensagem.',
      );

      debugPrint(
        '[RHYMES AI] '
        'BPM: $bpm',
      );

      debugPrint(
        '[RHYMES AI] '
        'Vibe: $vibe',
      );

      debugPrint(
        '[RHYMES AI] '
        'Técnica: $technique',
      );

      debugPrint(
        '[RHYMES AI] '
        'Vocabulário: ${vocabulary.length} palavras',
      );

      // ========================================================
      // REPOSITORY
      // ========================================================

      final response = await repository.postChat(
        message: normalizedMessage,

        currentList: vocabulary,

        apiKey: apiKey,

        context: {
          'bpm': bpm,

          'vibe': vibe,

          'technique': technique,
        },
      );

      debugPrint(
        '[RHYMES AI] '
        'Status: ${response.statusCode}',
      );

      // ========================================================
      // ERRO HTTP
      // ========================================================

      if (response.statusCode <
              200 ||
          response.statusCode >=
              300) {
        final error = _parseServerError(
          statusCode: response.statusCode,

          responseBody: response.body,
        );

        return RhymesAiResult(
          role: 'assistant',

          content: error.message,

          quota: error.quota,
        );
      }

      // ========================================================
      // JSON
      // ========================================================

      final decoded = jsonDecode(
        response.body,
      );

      if (decoded
          is! Map) {
        return const RhymesAiResult(
          role: 'assistant',

          content: 'O servidor respondeu em um formato inválido.',
        );
      }

      final data =
          Map<
            String,
            dynamic
          >.from(
            decoded,
          );

      // ========================================================
      // CONTENT
      // ========================================================

      final content = data['content']?.toString().trim();

      if (content ==
              null ||
          content.isEmpty) {
        return RhymesAiResult(
          role: 'assistant',

          content: 'O servidor respondeu sem conteúdo.',

          rawData: data,

          quota: _extractQuota(
            data,
          ),
        );
      }

      // ========================================================
      // SUCESSO
      // ========================================================

      return RhymesAiResult(
        role: 'assistant',

        content: content,

        rawData: data,

        quota: _extractQuota(
          data,
        ),
      );
    } on FormatException catch (
      error
    ) {
      debugPrint(
        '[RHYMES AI] '
        'JSON inválido: $error',
      );

      return const RhymesAiResult(
        role: 'assistant',

        content: 'O servidor respondeu em um formato inválido.',
      );
    } on TimeoutException catch (
      error
    ) {
      debugPrint(
        '[RHYMES AI] '
        'Timeout: $error',
      );

      return const RhymesAiResult(
        role: 'assistant',

        content: 'O servidor demorou demais para responder. Tente novamente.',
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[RHYMES AI] '
        'Erro: $error',
      );

      debugPrint(
        '[RHYMES AI] '
        'Stack trace: $stackTrace',
      );

      return const RhymesAiResult(
        role: 'assistant',

        content: 'Conexão instável. Tente novamente!',
      );
    } finally {
      _stopConnectionTimer();
    }
  }

  // ============================================================
  // INICIAR TIMER
  // ============================================================

  void _startConnectionTimer() {
    _connectionTimer?.cancel();

    _connectionSeconds = 0;

    _isLoading = true;

    notifyListeners();

    _connectionTimer = Timer.periodic(
      const Duration(
        seconds: 1,
      ),
      (
        _,
      ) {
        _connectionSeconds++;

        notifyListeners();
      },
    );
  }

  // ============================================================
  // PARAR TIMER
  // ============================================================

  void _stopConnectionTimer() {
    _connectionTimer?.cancel();

    _connectionTimer = null;

    _isLoading = false;

    notifyListeners();
  }

  // ============================================================
  // EXTRAIR QUOTA
  // ============================================================

  Map<
    String,
    dynamic
  >?
  _extractQuota(
    Map<
      String,
      dynamic
    >
    data,
  ) {
    dynamic rawQuota = data['quota'];

    rawQuota ??= data['ai_quota'];

    rawQuota ??= data['usage'];

    if (rawQuota
        is Map) {
      return Map<
        String,
        dynamic
      >.from(
        rawQuota,
      );
    }

    // ==========================================================
    // FORMATO FLAT
    // ==========================================================

    final hasFlatQuota =
        data.containsKey(
          'usage_percentage',
        ) ||
        data.containsKey(
          'used_tokens',
        ) ||
        data.containsKey(
          'remaining_tokens',
        ) ||
        data.containsKey(
          'limit_tokens',
        ) ||
        data.containsKey(
          'blocked',
        ) ||
        data.containsKey(
          'can_use_ai',
        );

    if (!hasFlatQuota) {
      return null;
    }

    return {
      if (data.containsKey(
        'usage_percentage',
      ))
        'usage_percentage': data['usage_percentage'],

      if (data.containsKey(
        'progress',
      ))
        'progress': data['progress'],

      if (data.containsKey(
        'used_tokens',
      ))
        'used_tokens': data['used_tokens'],

      if (data.containsKey(
        'remaining_tokens',
      ))
        'remaining_tokens': data['remaining_tokens'],

      if (data.containsKey(
        'limit_tokens',
      ))
        'limit_tokens': data['limit_tokens'],

      if (data.containsKey(
        'blocked',
      ))
        'blocked': data['blocked'],

      if (data.containsKey(
        'can_use_ai',
      ))
        'can_use_ai': data['can_use_ai'],

      if (data.containsKey(
        'level',
      ))
        'level': data['level'],

      if (data.containsKey(
        'message',
      ))
        'message': data['message'],
    };
  }

  // ============================================================
  // ERRO DO SERVIDOR
  // ============================================================

  _RhymesAiServerError _parseServerError({
    required int statusCode,
    required String responseBody,
  }) {
    String? serverMessage;

    // ==========================================================
    // TENTAR JSON
    // ==========================================================

    try {
      final decoded = jsonDecode(
        responseBody,
      );

      if (decoded
          is Map) {
        final data =
            Map<
              String,
              dynamic
            >.from(
              decoded,
            );

        final error = data['error'];

        if (error
            is Map) {
          serverMessage = error['message']?.toString().trim();
        }

        serverMessage ??= data['error']?.toString().trim();

        serverMessage ??= data['message']?.toString().trim();

        serverMessage ??= data['detail']?.toString().trim();
      }
    } catch (
      _
    ) {
      final normalized = responseBody.trim();

      if (normalized.isNotEmpty) {
        serverMessage = normalized;
      }
    }

    // ==========================================================
    // QUOTA
    // ==========================================================

    final normalizedMessage = serverMessage?.toLowerCase();

    final quotaReached =
        statusCode ==
            429 &&
        normalizedMessage !=
            null &&
        (normalizedMessage.contains(
              'limite mensal',
            ) ||
            normalizedMessage.contains(
              'monthly',
            ) ||
            normalizedMessage.contains(
              'quota',
            ));

    if (quotaReached) {
      final message =
          serverMessage !=
                  null &&
              serverMessage.isNotEmpty
          ? serverMessage
          : 'Limite mensal de IA atingido.';

      return _RhymesAiServerError(
        message: message,

        quota: {
          'usage_percentage': 100.0,

          'progress': 1.0,

          'blocked': true,

          'can_use_ai': false,

          'level': 'blocked',

          'message': message,
        },
      );
    }

    // ==========================================================
    // STATUS
    // ==========================================================

    switch (statusCode) {
      case 401:
        return _RhymesAiServerError(
          message:
              serverMessage !=
                  null
              ? 'Não autorizado: $serverMessage'
              : 'Não autorizado. Verifique sua API Key.',
        );

      case 403:
        return _RhymesAiServerError(
          message:
              serverMessage !=
                  null
              ? 'Acesso negado: $serverMessage'
              : 'Acesso negado pelo servidor.',
        );

      case 404:
        return _RhymesAiServerError(
          message:
              serverMessage !=
                  null
              ? 'Serviço não encontrado: $serverMessage'
              : 'O serviço da IA não foi encontrado.',
        );

      case 429:
        return _RhymesAiServerError(
          message:
              serverMessage !=
                  null
              ? 'Limite de requisições atingido: $serverMessage'
              : 'Muitas requisições. Aguarde um pouco e tente novamente.',
        );

      case 500:
        return _RhymesAiServerError(
          message:
              serverMessage !=
                  null
              ? 'Erro interno do servidor: $serverMessage'
              : 'Erro interno do servidor.',
        );

      case 502:
        return _RhymesAiServerError(
          message:
              serverMessage !=
                  null
              ? 'Gateway inválido: $serverMessage'
              : 'O servidor intermediário falhou.',
        );

      case 503:
        return _RhymesAiServerError(
          message:
              serverMessage !=
                  null
              ? 'Servidor temporariamente indisponível: $serverMessage'
              : 'Servidor temporariamente indisponível. Tente novamente em instantes.',
        );

      case 504:
        return _RhymesAiServerError(
          message:
              serverMessage !=
                  null
              ? 'Tempo limite do servidor: $serverMessage'
              : 'O servidor demorou demais para responder.',
        );

      default:
        return _RhymesAiServerError(
          message:
              serverMessage !=
                  null
              ? 'Erro no servidor ($statusCode): $serverMessage'
              : 'Erro no servidor (Status: $statusCode)',
        );
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _connectionTimer?.cancel();

    _connectionTimer = null;

    super.dispose();
  }
}

// ============================================================
// RHYMES AI RESULT
// ============================================================

class RhymesAiResult {
  final String role;

  final String content;

  final Map<
    String,
    dynamic
  >?
  quota;

  final Map<
    String,
    dynamic
  >?
  rawData;

  const RhymesAiResult({
    required this.role,
    required this.content,
    this.quota,
    this.rawData,
  });

  // ============================================================
  // TO MESSAGE MAP
  // ============================================================

  Map<
    String,
    String
  >
  toMessageMap() {
    return {
      'role': role,

      'content': content,
    };
  }

  // ============================================================
  // POSSUI QUOTA
  // ============================================================

  bool get hasQuota =>
      quota !=
      null;

  // ============================================================
  // POSSUI RAW DATA
  // ============================================================

  bool get hasRawData =>
      rawData !=
      null;
}

// ============================================================
// SERVER ERROR
// ============================================================

class _RhymesAiServerError {
  final String message;

  final Map<
    String,
    dynamic
  >?
  quota;

  const _RhymesAiServerError({
    required this.message,
    this.quota,
  });
}
