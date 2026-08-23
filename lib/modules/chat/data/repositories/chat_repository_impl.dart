import 'package:flutter/foundation.dart';

import '../datasources/chat_remote_datasource.dart';

import '../../ai/services/provider/ai_provider_service.dart';
import '../../ai/services/private_api/private_ai_client.dart';

import '../../domain/repositories/chat_repository.dart';

// ============================================================
// CHAT REPOSITORY IMPLEMENTATION
// ============================================================
//
// Faz a ponte entre:
//
// ChatController
//       ↓
// ChatRepository
//       ↓
// AiProviderService
//
// O AiProviderService decide se utiliza:
//
// - IA Versin;
// - API privada do usuário.
//
// IA VERSIN:
//
// ChatRepositoryImpl
//       ↓
// ChatRemoteDatasource
//       ↓
// Backend Versin
//       ↓
// conteúdo + quota
//       ↓
// VersinAiResponse
//       ↓
// AiProviderResult
//
// API PRIVADA:
//
// AiProviderService
//       ↓
// PrivateAiClient
//       ↓
// OpenAI / Groq / OpenRouter / Gemini / Anthropic / Custom
//
// IMPORTANTE:
//
// API privada:
//
// - não utiliza backend oficial;
// - não consome quota Versin;
// - não deve alterar a quota exibida.
//
// ============================================================

class ChatRepositoryImpl
    implements
        ChatRepository {
  // ============================================================
  // DEPENDÊNCIAS
  // ============================================================

  final ChatRemoteDatasource remoteDatasource;

  final AiProviderService aiProviderService;

  final PrivateAiClient privateAiClient;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  ChatRepositoryImpl({
    required this.remoteDatasource,
    required this.aiProviderService,
    required this.privateAiClient,
  });

  // ============================================================
  // IA
  // ============================================================

  @override
  Future<
    Map<
      String,
      dynamic
    >
  >
  fetchAiResponse(
    String message,
  ) async {
    final normalized = message.trim();

    if (normalized.isEmpty) {
      throw ArgumentError(
        'Mensagem não pode ficar vazia.',
      );
    }

    debugPrint(
      '[CHAT REPOSITORY] '
      'Iniciando requisição de IA.',
    );

    try {
      // ========================================================
      // AI PROVIDER
      // ========================================================

      final result = await aiProviderService.generate(
        prompt: normalized,

        // ======================================================
        // IA OFICIAL VERSIN
        // ======================================================
        //
        // Diferente da API privada, a resposta Versin precisa
        // preservar:
        //
        // - conteúdo;
        // - quota;
        // - provider;
        // - modelo.
        //
        // ======================================================
        generateWithVersin:
            (
              prompt,
            ) async {
              debugPrint(
                '[CHAT REPOSITORY] '
                'Utilizando IA Versin.',
              );

              // ====================================================
              // REMOTE RESPONSE
              // ====================================================

              final response = await remoteDatasource.sendAiMessage(
                prompt,
              );

              // ====================================================
              // CONTENT
              // ====================================================

              final content = response['content']?.toString().trim();

              if (content ==
                      null ||
                  content.isEmpty) {
                throw StateError(
                  'A IA Versin retornou conteúdo vazio.',
                );
              }

              // ====================================================
              // QUOTA
              // ====================================================

              final quota = _extractMap(
                response['quota'],
              );

              if (quota !=
                  null) {
                debugPrint(
                  '[CHAT REPOSITORY] '
                  'Quota recebida do backend Versin.',
                );

                debugPrint(
                  '[CHAT REPOSITORY] '
                  'Quota possui '
                  '${quota.length} campo(s).',
                );
              } else {
                debugPrint(
                  '[CHAT REPOSITORY] '
                  'Backend Versin não retornou quota.',
                );
              }

              // ====================================================
              // PROVIDER
              // ====================================================

              final provider = _extractString(
                response['provider'],
              );

              // ====================================================
              // MODEL
              // ====================================================

              final model = _extractString(
                response['model'],
              );

              // ====================================================
              // RESPONSE
              // ====================================================

              return VersinAiResponse(
                content: content,

                quota: quota,

                provider:
                    provider ??
                    'versin',

                model: model,
              );
            },

        // ======================================================
        // API PRIVADA
        // ======================================================
        generateWithPrivateApi:
            (
              request,
            ) async {
              debugPrint(
                '[CHAT REPOSITORY] '
                'Utilizando API privada.',
              );

              debugPrint(
                '[CHAT REPOSITORY] '
                'Provider: ${request.provider}',
              );

              if (request.model !=
                      null &&
                  request.model!.trim().isNotEmpty) {
                debugPrint(
                  '[CHAT REPOSITORY] '
                  'Modelo: ${request.model!.trim()}',
                );
              }

              // ====================================================
              // NUNCA LOGAR
              // ====================================================
              //
              // request.apiKey
              //
              // ====================================================

              return privateAiClient.generate(
                request,
              );
            },
      );

      // ========================================================
      // LOG
      // ========================================================

      debugPrint(
        '[CHAT REPOSITORY] '
        'Resposta recebida.',
      );

      debugPrint(
        '[CHAT REPOSITORY] '
        'Fonte: ${result.source}',
      );

      // ========================================================
      // PROVIDER
      // ========================================================

      if (result.provider !=
              null &&
          result.provider!.trim().isNotEmpty) {
        debugPrint(
          '[CHAT REPOSITORY] '
          'Provider: ${result.provider}',
        );
      }

      // ========================================================
      // MODEL
      // ========================================================

      if (result.model !=
              null &&
          result.model!.trim().isNotEmpty) {
        debugPrint(
          '[CHAT REPOSITORY] '
          'Modelo: ${result.model}',
        );
      }

      // ========================================================
      // QUOTA
      // ========================================================

      if (result.hasQuota) {
        debugPrint(
          '[CHAT REPOSITORY] '
          'Quota Versin preservada na resposta.',
        );
      }

      // ========================================================
      // RESPOSTA PADRONIZADA
      // ========================================================
      //
      // IMPORTANTE:
      //
      // Agora quota também é devolvida ao ChatController.
      //
      // Isso permite:
      //
      // Backend
      //    ↓
      // quota
      //    ↓
      // Repository
      //    ↓
      // ChatController
      //    ↓
      // RhymesController
      //    ↓
      // AiQuotaController
      //    ↓
      // card IA mensal
      //
      // ========================================================

      return {
        // ======================================================
        // CONTENT
        // ======================================================
        'content': result.content,

        // ======================================================
        // SOURCE
        // ======================================================
        'source': result.source.name,

        // ======================================================
        // PROVIDER
        // ======================================================
        'provider': result.provider,

        // ======================================================
        // MODEL
        // ======================================================
        'model': result.model,

        // ======================================================
        // QUOTA
        // ======================================================
        'quota': result.quota,

        // ======================================================
        // SOURCE HELPERS
        // ======================================================
        'used_versin_api': result.usedVersinApi,

        'used_private_api': result.usedPrivateApi,
      };
    }
    // ==========================================================
    // PRIVATE API ERROR
    // ==========================================================
    on PrivateAiException catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[CHAT REPOSITORY] '
        'Erro da API privada.',
      );

      debugPrint(
        '[CHAT REPOSITORY] '
        'Status: ${error.statusCode}',
      );

      debugPrint(
        '[CHAT REPOSITORY] '
        'Mensagem: ${error.message}',
      );

      debugPrint(
        '[CHAT REPOSITORY] '
        'Stack trace: $stackTrace',
      );

      rethrow;
    }
    // ==========================================================
    // OUTROS ERROS
    // ==========================================================
    catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[CHAT REPOSITORY] '
        'Erro ao buscar resposta da IA.',
      );

      debugPrint(
        '[CHAT REPOSITORY] '
        'Erro: $error',
      );

      debugPrint(
        '[CHAT REPOSITORY] '
        'Stack trace: $stackTrace',
      );

      rethrow;
    }
  }

  // ============================================================
  // AI QUOTA
  // ============================================================
  //
  // Busca a quota atual da IA Versin diretamente no backend.
  //
  // Esta operação:
  //
  // - não envia mensagem para a IA;
  // - não consome tokens;
  // - não consulta API privada;
  // - não altera a decisão do AiProviderService.
  //
  // O backend continua sendo a fonte da verdade.
  //
  // ============================================================

  @override
  Future<
    Map<
      String,
      dynamic
    >
  >
  fetchAiQuota() async {
    debugPrint(
      '[CHAT REPOSITORY] '
      'Buscando quota atual da IA Versin.',
    );

    try {
      final quota = await remoteDatasource.fetchAiQuota();

      if (quota.isEmpty) {
        throw StateError(
          'O backend Versin retornou uma quota vazia.',
        );
      }

      debugPrint(
        '[CHAT REPOSITORY] '
        'Quota atual recebida.',
      );

      debugPrint(
        '[CHAT REPOSITORY] '
        'Quota possui ${quota.length} campo(s).',
      );

      if (quota.containsKey(
        'used_tokens',
      )) {
        debugPrint(
          '[CHAT REPOSITORY] '
          'Tokens usados: ${quota['used_tokens']}',
        );
      }

      if (quota.containsKey(
        'remaining_tokens',
      )) {
        debugPrint(
          '[CHAT REPOSITORY] '
          'Tokens restantes: ${quota['remaining_tokens']}',
        );
      }

      if (quota.containsKey(
        'limit_tokens',
      )) {
        debugPrint(
          '[CHAT REPOSITORY] '
          'Limite: ${quota['limit_tokens']}',
        );
      }

      return quota;
    } on ChatRemoteException catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[CHAT REPOSITORY] '
        'Erro remoto ao buscar quota Versin.',
      );

      debugPrint(
        '[CHAT REPOSITORY] '
        'Status: ${error.statusCode}',
      );

      debugPrint(
        '[CHAT REPOSITORY] '
        'Mensagem: ${error.message}',
      );

      debugPrint(
        '[CHAT REPOSITORY] '
        'Stack trace: $stackTrace',
      );

      rethrow;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[CHAT REPOSITORY] '
        'Erro ao buscar quota Versin.',
      );

      debugPrint(
        '[CHAT REPOSITORY] '
        'Erro: $error',
      );

      debugPrint(
        '[CHAT REPOSITORY] '
        'Stack trace: $stackTrace',
      );

      rethrow;
    }
  }

  // ============================================================
  // EXTRAIR MAP
  // ============================================================
  //
  // Converte respostas JSON dinâmicas para:
  //
  // Map<String, dynamic>
  //
  // sem confiar no tipo específico retornado por jsonDecode.
  //
  // ============================================================

  static Map<
    String,
    dynamic
  >?
  _extractMap(
    dynamic value,
  ) {
    if (value ==
        null) {
      return null;
    }

    if (value
        is Map<
          String,
          dynamic
        >) {
      if (value.isEmpty) {
        return null;
      }

      return Map<
        String,
        dynamic
      >.from(
        value,
      );
    }

    if (value
        is Map) {
      try {
        final converted =
            Map<
              String,
              dynamic
            >.from(
              value,
            );

        if (converted.isEmpty) {
          return null;
        }

        return converted;
      } catch (
        _
      ) {
        return null;
      }
    }

    return null;
  }

  // ============================================================
  // EXTRAIR STRING
  // ============================================================

  static String? _extractString(
    dynamic value,
  ) {
    if (value ==
        null) {
      return null;
    }

    final normalized = value.toString().trim();

    if (normalized.isEmpty) {
      return null;
    }

    final lowered = normalized.toLowerCase();

    if (lowered ==
            'null' ||
        lowered ==
            'none' ||
        lowered ==
            'undefined') {
      return null;
    }

    return normalized;
  }

  // ============================================================
  // SALVAR PROJETO
  // ============================================================

  @override
  Future<
    void
  >
  saveProject(
    Map<
      String,
      dynamic
    >
    projectData,
  ) async {
    debugPrint(
      '[CHAT REPOSITORY] '
      'saveProject ainda não implementado.',
    );
  }
}
