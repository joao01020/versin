import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================================
// CHAT REMOTE DATASOURCE
// ============================================================
//
// Responsável exclusivamente pela comunicação remota com
// a infraestrutura oficial do Versin.
//
// Atualmente utiliza:
//
// Supabase Edge Function
//
// chat-ai
//
// IMPORTANTE:
//
// Este datasource representa a IA oficial do Versin.
//
// API privada do usuário NÃO deve ser implementada aqui.
//
// ============================================================

class ChatRemoteDatasource {
  // ============================================================
  // SUPABASE
  // ============================================================

  final SupabaseClient _client;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  ChatRemoteDatasource({
    SupabaseClient? client,
  }) : _client =
           client ??
           Supabase.instance.client;

  // ============================================================
  // ENVIAR PARA IA VERSIN
  // ============================================================

  Future<
    Map<
      String,
      dynamic
    >
  >
  sendAiMessage(
    String message,
  ) async {
    final normalized = message.trim();

    if (normalized.isEmpty) {
      throw ArgumentError(
        'Mensagem não pode ficar vazia.',
      );
    }

    debugPrint(
      '[CHAT REMOTE] '
      'Enviando mensagem para IA Versin.',
    );

    try {
      final response = await _client.functions.invoke(
        'chat-ai',

        body: {
          'text': normalized,
        },
      );

      final data = response.data;

      if (data ==
          null) {
        throw StateError(
          'A IA retornou uma resposta vazia.',
        );
      }

      // ========================================================
      // MAP
      // ========================================================

      if (data
          is Map<
            String,
            dynamic
          >) {
        return data;
      }

      // ========================================================
      // MAP GENÉRICO
      // ========================================================

      if (data
          is Map) {
        return Map<
          String,
          dynamic
        >.from(
          data,
        );
      }

      // ========================================================
      // STRING
      // ========================================================

      if (data
          is String) {
        return {
          'content': data,
        };
      }

      throw StateError(
        'Formato de resposta da IA não reconhecido.',
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[CHAT REMOTE] '
        'Erro ao chamar chat-ai: $error',
      );

      debugPrint(
        '[CHAT REMOTE] '
        'Stack trace: $stackTrace',
      );

      rethrow;
    }
  }
}
