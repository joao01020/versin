import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================================
// CHAT REMOTE DATASOURCE
// ============================================================
//
// Responsável pela comunicação com a infraestrutura oficial
// de IA do Versin.
//
// Fluxo:
//
// ChatController
//      ↓
// ChatRepositoryImpl
//      ↓
// AiProviderService
//      ↓
// ChatRemoteDatasource
//      ↓
// Backend Versin / Render
//
// IMPORTANTE:
//
// Este datasource representa apenas a IA oficial Versin.
//
// API privada do usuário é executada pelo PrivateAiClient.
//
// ============================================================

class ChatRemoteDatasource {
  // ============================================================
  // SUPABASE
  // ============================================================

  final SupabaseClient _supabase;

  // ============================================================
  // HTTP CLIENT
  // ============================================================

  final http.Client _httpClient;

  // ============================================================
  // BACKEND VERSIN
  // ============================================================

  static const String _baseUrl = 'https://versin.onrender.com';

  // ============================================================
  // TIMEOUT
  // ============================================================

  static const Duration _timeout = Duration(
    seconds: 60,
  );

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  ChatRemoteDatasource({
    SupabaseClient? supabase,
    http.Client? httpClient,
  }) : _supabase =
           supabase ??
           Supabase.instance.client,
       _httpClient =
           httpClient ??
           http.Client();

  // ============================================================
  // ENVIAR MENSAGEM
  // ============================================================

  Future<
    Map<
      String,
      dynamic
    >
  >
  sendAiMessage(
    String message, {
    List<
          String
        >
        currentList =
        const [],
    Map<
          String,
          dynamic
        >
        context =
        const {},
  }) async {
    final normalized = message.trim();

    if (normalized.isEmpty) {
      throw ArgumentError(
        'Mensagem não pode ficar vazia.',
      );
    }

    // ==========================================================
    // USUÁRIO
    // ==========================================================

    final userId =
        _supabase.auth.currentUser?.id ??
        'user_dev_01';

    // ==========================================================
    // ENDPOINT
    // ==========================================================

    final uri = Uri.parse(
      '$_baseUrl/chat',
    );

    debugPrint(
      '[CHAT REMOTE] '
      'Enviando mensagem para IA Versin.',
    );

    debugPrint(
      '[CHAT REMOTE] '
      'Endpoint: $uri',
    );

    try {
      // ========================================================
      // REQUEST
      // ========================================================

      final response = await _httpClient
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode(
              {
                'user_id': userId,

                'message': normalized,

                'current_list': currentList,

                // =================================================
                // API PRIVADA NÃO É ENVIADA
                // =================================================
                //
                // O fluxo privado agora é responsabilidade do
                // PrivateAiClient.
                //
                // Mantemos null por compatibilidade com o backend.
                //
                // =================================================
                'private_api_key': null,

                'context': context,
              },
            ),
          )
          .timeout(
            _timeout,
          );

      debugPrint(
        '[CHAT REMOTE] '
        'Status: ${response.statusCode}',
      );

      // ========================================================
      // STATUS HTTP
      // ========================================================

      if (response.statusCode <
              200 ||
          response.statusCode >=
              300) {
        throw ChatRemoteException(
          statusCode: response.statusCode,

          message: _extractErrorMessage(
            response.body,
          ),
        );
      }

      // ========================================================
      // BODY
      // ========================================================

      if (response.body.trim().isEmpty) {
        throw const ChatRemoteException(
          message: 'O servidor Versin retornou uma resposta vazia.',
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
        throw const ChatRemoteException(
          message: 'O servidor Versin retornou um formato inválido.',
        );
      }

      final data =
          Map<
            String,
            dynamic
          >.from(
            decoded,
          );

      debugPrint(
        '[CHAT REMOTE] '
        'Resposta recebida com sucesso.',
      );

      return data;
    } on ChatRemoteException {
      rethrow;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[CHAT REMOTE] '
        'Erro ao chamar backend Versin: $error',
      );

      debugPrint(
        '[CHAT REMOTE] '
        'Stack trace: $stackTrace',
      );

      rethrow;
    }
  }

  // ============================================================
  // EXTRAIR ERRO
  // ============================================================

  String _extractErrorMessage(
    String body,
  ) {
    final normalized = body.trim();

    if (normalized.isEmpty) {
      return 'Erro retornado pelo servidor Versin.';
    }

    try {
      final decoded = jsonDecode(
        normalized,
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
          final message = error['message']?.toString().trim();

          if (message !=
                  null &&
              message.isNotEmpty) {
            return message;
          }
        }

        final message = data['message']?.toString().trim();

        if (message !=
                null &&
            message.isNotEmpty) {
          return message;
        }

        final detail = data['detail']?.toString().trim();

        if (detail !=
                null &&
            detail.isNotEmpty) {
          return detail;
        }

        final errorText = data['error']?.toString().trim();

        if (errorText !=
                null &&
            errorText.isNotEmpty) {
          return errorText;
        }
      }
    } catch (
      _
    ) {
      // Se não for JSON, devolvemos o próprio corpo.
    }

    return normalized;
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  void dispose() {
    _httpClient.close();
  }
}

// ============================================================
// CHAT REMOTE EXCEPTION
// ============================================================

class ChatRemoteException
    implements
        Exception {
  final String message;

  final int? statusCode;

  const ChatRemoteException({
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
      return 'ChatRemoteException: $message';
    }

    return 'ChatRemoteException'
        '(statusCode: $statusCode, message: $message)';
  }
}
