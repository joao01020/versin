import 'package:flutter/foundation.dart';

import '../../data/datasources/chat_remote_datasource.dart';

import '../../services/ai_provider_service.dart';
import '../../services/private_ai_client.dart';

import 'chat_repository.dart';

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
// Se utilizar API privada:
//
// AiProviderService
//       ↓
// PrivateAiClient
//       ↓
// OpenAI / Groq / OpenRouter / Gemini / Anthropic / Custom
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
      final result = await aiProviderService.generate(
        prompt: normalized,

        // ======================================================
        // IA OFICIAL VERSIN
        // ======================================================
        generateWithVersin:
            (
              prompt,
            ) async {
              debugPrint(
                '[CHAT REPOSITORY] '
                'Utilizando IA Versin.',
              );

              final response = await remoteDatasource.sendAiMessage(
                prompt,
              );

              final content = response['content']?.toString().trim();

              if (content ==
                      null ||
                  content.isEmpty) {
                throw StateError(
                  'A IA Versin retornou conteúdo vazio.',
                );
              }

              return content;
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

      if (result.provider !=
              null &&
          result.provider!.trim().isNotEmpty) {
        debugPrint(
          '[CHAT REPOSITORY] '
          'Provider: ${result.provider}',
        );
      }

      if (result.model !=
              null &&
          result.model!.trim().isNotEmpty) {
        debugPrint(
          '[CHAT REPOSITORY] '
          'Modelo: ${result.model}',
        );
      }

      // ========================================================
      // RESPOSTA PADRONIZADA
      // ========================================================

      return {
        'content': result.content,

        'source': result.source.name,

        'provider': result.provider,

        'model': result.model,

        'used_versin_api': result.usedVersinApi,

        'used_private_api': result.usedPrivateApi,
      };
    } on PrivateAiException catch (
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
    } catch (
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
