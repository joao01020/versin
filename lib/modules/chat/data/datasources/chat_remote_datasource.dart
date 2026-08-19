import 'dart:async';
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
// SEGURANÇA:
//
// - não envia API privada;
// - não imprime access token;
// - não utiliza usuário fake;
// - utiliza sessão autenticada do Supabase;
// - envia JWT para o backend quando disponível.
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
  // ENDPOINT
  // ============================================================

  static const String _chatPath = '/chat';

  // ============================================================
  // TIMEOUT
  // ============================================================

  static const Duration _timeout = Duration(
    seconds: 60,
  );

  // ============================================================
  // MAX ERROR PREVIEW
  // ============================================================
  //
  // Evita despejar páginas inteiras do servidor no console.
  //
  // ============================================================

  static const int _maxErrorPreviewLength = 500;

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
        const <
          String
        >[],
    Map<
          String,
          dynamic
        >
        context =
        const <
          String,
          dynamic
        >{},
  }) async {
    // ==========================================================
    // NORMALIZAR MENSAGEM
    // ==========================================================

    final normalizedMessage = message.trim();

    if (normalizedMessage.isEmpty) {
      throw ArgumentError(
        'Mensagem não pode ficar vazia.',
      );
    }

    // ==========================================================
    // USUÁRIO AUTENTICADO
    // ==========================================================
    //
    // Não usamos mais:
    //
    // ?? 'user_dev_01'
    //
    // Um usuário fake pode causar inconsistência entre:
    //
    // Flutter
    // Supabase
    // Backend
    // memória da IA
    // limites de uso
    //
    // ==========================================================

    final currentUser = _supabase.auth.currentUser;

    if (currentUser ==
        null) {
      throw const ChatRemoteException(
        statusCode: 401,
        message: 'Usuário não autenticado.',
      );
    }

    final userId = currentUser.id.trim();

    if (userId.isEmpty) {
      throw const ChatRemoteException(
        statusCode: 401,
        message: 'Não foi possível identificar o usuário autenticado.',
      );
    }

    // ==========================================================
    // SESSION
    // ==========================================================

    final session = _supabase.auth.currentSession;

    final accessToken = session?.accessToken.trim();

    // ==========================================================
    // ENDPOINT
    // ==========================================================

    final uri = Uri.parse(
      '$_baseUrl$_chatPath',
    );

    // ==========================================================
    // REQUEST BODY
    // ==========================================================

    final requestBody =
        <
          String,
          dynamic
        >{
          'user_id': userId,

          'message': normalizedMessage,

          'current_list':
              List<
                String
              >.from(
                currentList,
              ),

          // ========================================================
          // API PRIVADA
          // ========================================================
          //
          // Nunca enviar uma chave privada pelo fluxo oficial.
          //
          // Mantemos null somente por compatibilidade com o contrato
          // atual do backend.
          //
          // ========================================================
          'private_api_key': null,

          'context':
              Map<
                String,
                dynamic
              >.from(
                context,
              ),
        };

    // ==========================================================
    // HEADERS
    // ==========================================================

    final headers =
        <
          String,
          String
        >{
          'Content-Type': 'application/json; charset=UTF-8',

          'Accept': 'application/json',
        };

    // ==========================================================
    // AUTHORIZATION
    // ==========================================================
    //
    // Se existe uma sessão válida, enviamos o JWT.
    //
    // O backend pode então verificar a identidade ao invés de
    // confiar somente no user_id recebido no JSON.
    //
    // Nunca logar este token.
    //
    // ==========================================================

    if (accessToken !=
            null &&
        accessToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $accessToken';
    }

    // ==========================================================
    // LOG REQUEST
    // ==========================================================

    debugPrint(
      '[CHAT REMOTE] '
      'Enviando mensagem para IA Versin.',
    );

    debugPrint(
      '[CHAT REMOTE] '
      'Endpoint: $uri',
    );

    debugPrint(
      '[CHAT REMOTE] '
      'User ID: $userId',
    );

    debugPrint(
      '[CHAT REMOTE] '
      'Autenticação JWT: '
      '${accessToken?.isNotEmpty == true}',
    );

    debugPrint(
      '[CHAT REMOTE] '
      'Mensagem: '
      '${normalizedMessage.length} caracteres.',
    );

    debugPrint(
      '[CHAT REMOTE] '
      'Current list: '
      '${currentList.length} item(ns).',
    );

    debugPrint(
      '[CHAT REMOTE] '
      'Context: '
      '${context.length} campo(s).',
    );

    try {
      // ========================================================
      // HTTP POST
      // ========================================================

      final response = await _httpClient
          .post(
            uri,
            headers: headers,
            body: jsonEncode(
              requestBody,
            ),
          )
          .timeout(
            _timeout,
          );

      // ========================================================
      // RESPONSE LOG
      // ========================================================

      debugPrint(
        '[CHAT REMOTE] '
        'Status: ${response.statusCode}',
      );

      debugPrint(
        '[CHAT REMOTE] '
        'Content-Type: '
        '${response.headers['content-type'] ?? 'desconhecido'}',
      );

      // ========================================================
      // HTTP ERROR
      // ========================================================

      if (!_isSuccessfulStatus(
        response.statusCode,
      )) {
        final errorMessage = _extractErrorMessage(
          response.body,
        );

        debugPrint(
          '[CHAT REMOTE] '
          'Backend retornou erro HTTP.',
        );

        debugPrint(
          '[CHAT REMOTE] '
          'Status: ${response.statusCode}',
        );

        debugPrint(
          '[CHAT REMOTE] '
          'Mensagem: $errorMessage',
        );

        final bodyPreview = _safeBodyPreview(
          response.body,
        );

        if (bodyPreview.isNotEmpty) {
          debugPrint(
            '[CHAT REMOTE] '
            'Body: $bodyPreview',
          );
        }

        throw ChatRemoteException(
          statusCode: response.statusCode,
          message: errorMessage,
        );
      }

      // ========================================================
      // EMPTY BODY
      // ========================================================

      final normalizedBody = response.body.trim();

      if (normalizedBody.isEmpty) {
        throw const ChatRemoteException(
          message: 'O servidor Versin retornou uma resposta vazia.',
        );
      }

      // ========================================================
      // DECODE JSON
      // ========================================================

      final dynamic decoded;

      try {
        decoded = jsonDecode(
          normalizedBody,
        );
      } on FormatException catch (
        error
      ) {
        debugPrint(
          '[CHAT REMOTE] '
          'Resposta não é JSON válido.',
        );

        debugPrint(
          '[CHAT REMOTE] '
          'Erro JSON: $error',
        );

        debugPrint(
          '[CHAT REMOTE] '
          'Body: ${_safeBodyPreview(normalizedBody)}',
        );

        throw const ChatRemoteException(
          message: 'O servidor Versin retornou uma resposta em formato inválido.',
        );
      }

      // ========================================================
      // RESPONSE MUST BE MAP
      // ========================================================

      if (decoded
          is! Map) {
        debugPrint(
          '[CHAT REMOTE] '
          'Formato inesperado: '
          '${decoded.runtimeType}',
        );

        throw const ChatRemoteException(
          message: 'O servidor Versin retornou uma estrutura inesperada.',
        );
      }

      // ========================================================
      // CONVERT
      // ========================================================

      final data =
          Map<
            String,
            dynamic
          >.from(
            decoded,
          );

      // ========================================================
      // BACKEND ERROR INSIDE 2XX
      // ========================================================
      //
      // Alguns backends retornam:
      //
      // HTTP 200
      //
      // {
      //   "error": "...",
      //   "success": false
      // }
      //
      // Tratamos isso também.
      //
      // ========================================================

      final successValue = data['success'];

      final hasExplicitFailure =
          successValue ==
          false;

      if (hasExplicitFailure) {
        throw ChatRemoteException(
          message: _extractErrorMessage(
            normalizedBody,
          ),
        );
      }

      // ========================================================
      // CONTENT VALIDATION
      // ========================================================
      //
      // ChatRepositoryImpl espera:
      //
      // response['content']
      //
      // Portanto validamos aqui também para identificar melhor
      // respostas inconsistentes do backend.
      //
      // ========================================================

      final content = data['content']?.toString().trim();

      if (content ==
              null ||
          content.isEmpty) {
        debugPrint(
          '[CHAT REMOTE] '
          'Resposta recebida, mas sem content.',
        );

        debugPrint(
          '[CHAT REMOTE] '
          'Chaves recebidas: '
          '${data.keys.join(', ')}',
        );

        throw const ChatRemoteException(
          message: 'A IA Versin retornou conteúdo vazio.',
        );
      }

      // ========================================================
      // SUCCESS
      // ========================================================

      debugPrint(
        '[CHAT REMOTE] '
        'Resposta recebida com sucesso.',
      );

      debugPrint(
        '[CHAT REMOTE] '
        'Conteúdo: ${content.length} caracteres.',
      );

      return data;
    }
    // ==========================================================
    // CHAT REMOTE EXCEPTION
    // ==========================================================
    on ChatRemoteException {
      rethrow;
    }
    // ==========================================================
    // TIMEOUT
    // ==========================================================
    on TimeoutException catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[CHAT REMOTE] '
        'Timeout ao chamar backend Versin.',
      );

      debugPrint(
        '[CHAT REMOTE] '
        'Erro: $error',
      );

      debugPrint(
        '[CHAT REMOTE] '
        'Stack trace: $stackTrace',
      );

      throw const ChatRemoteException(
        message: 'O servidor Versin demorou demais para responder.',
      );
    }
    // ==========================================================
    // HTTP CLIENT ERROR
    // ==========================================================
    on http.ClientException catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[CHAT REMOTE] '
        'Erro HTTP ao chamar backend Versin.',
      );

      debugPrint(
        '[CHAT REMOTE] '
        'Erro: $error',
      );

      debugPrint(
        '[CHAT REMOTE] '
        'Stack trace: $stackTrace',
      );

      throw ChatRemoteException(
        message:
            'Não foi possível conectar ao servidor Versin. '
            '${error.message}',
      );
    }
    // ==========================================================
    // UNKNOWN
    // ==========================================================
    catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[CHAT REMOTE] '
        'Erro inesperado ao chamar backend Versin.',
      );

      debugPrint(
        '[CHAT REMOTE] '
        'Erro: $error',
      );

      debugPrint(
        '[CHAT REMOTE] '
        'Stack trace: $stackTrace',
      );

      throw ChatRemoteException(
        message:
            'Erro inesperado ao conectar com a IA Versin: '
            '$error',
      );
    }
  }

  // ============================================================
  // SUCCESS STATUS
  // ============================================================

  bool _isSuccessfulStatus(
    int statusCode,
  ) {
    return statusCode >=
            200 &&
        statusCode <
            300;
  }

  // ============================================================
  // EXTRAIR ERRO
  // ============================================================
  //
  // Suporta formatos como:
  //
  // {
  //   "message": "..."
  // }
  //
  // {
  //   "detail": "..."
  // }
  //
  // {
  //   "error": "..."
  // }
  //
  // {
  //   "error": {
  //     "message": "..."
  //   }
  // }
  //
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

        // ======================================================
        // ERROR OBJECT
        // ======================================================

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

          final nestedMessage = _normalizedString(
            errorMap['message'],
          );

          if (nestedMessage !=
              null) {
            return nestedMessage;
          }

          final nestedDetail = _normalizedString(
            errorMap['detail'],
          );

          if (nestedDetail !=
              null) {
            return nestedDetail;
          }

          final nestedError = _normalizedString(
            errorMap['error'],
          );

          if (nestedError !=
              null) {
            return nestedError;
          }
        }

        // ======================================================
        // MESSAGE
        // ======================================================

        final message = _normalizedString(
          data['message'],
        );

        if (message !=
            null) {
          return message;
        }

        // ======================================================
        // DETAIL
        // ======================================================

        final detail = _normalizedString(
          data['detail'],
        );

        if (detail !=
            null) {
          return detail;
        }

        // ======================================================
        // ERROR STRING
        // ======================================================

        if (error
            is String) {
          final errorText = error.trim();

          if (errorText.isNotEmpty) {
            return errorText;
          }
        }

        // ======================================================
        // ERROR FALLBACK
        // ======================================================

        final errorText = _normalizedString(
          error,
        );

        if (errorText !=
                null &&
            !errorText.startsWith(
              '{',
            )) {
          return errorText;
        }
      }
    } catch (
      _
    ) {
      // ========================================================
      // NOT JSON
      // ========================================================
      //
      // Continua e devolve o texto recebido.
      //
      // ========================================================
    }

    return normalized;
  }

  // ============================================================
  // NORMALIZED STRING
  // ============================================================

  String? _normalizedString(
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

    final lower = normalized.toLowerCase();

    if (lower ==
            'null' ||
        lower ==
            'undefined' ||
        lower ==
            'none' ||
        lower ==
            'nil') {
      return null;
    }

    return normalized;
  }

  // ============================================================
  // SAFE BODY PREVIEW
  // ============================================================

  String _safeBodyPreview(
    String body,
  ) {
    final normalized = body.trim();

    if (normalized.isEmpty) {
      return '';
    }

    if (normalized.length <=
        _maxErrorPreviewLength) {
      return normalized;
    }

    return '${normalized.substring(0, _maxErrorPreviewLength)}...';
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
  // UNAUTHORIZED
  // ============================================================

  bool get isUnauthorized {
    return statusCode ==
            401 ||
        statusCode ==
            403;
  }

  // ============================================================
  // RATE LIMITED
  // ============================================================

  bool get isRateLimited {
    return statusCode ==
        429;
  }

  // ============================================================
  // SERVER ERROR
  // ============================================================

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
  // TIMEOUT-LIKE
  // ============================================================

  bool get isTimeout {
    final normalized = message.trim().toLowerCase();

    return normalized.contains(
          'timeout',
        ) ||
        normalized.contains(
          'demorou demais',
        );
  }

  // ============================================================
  // TO STRING
  // ============================================================

  @override
  String toString() {
    if (statusCode ==
        null) {
      return 'ChatRemoteException: '
          '$message';
    }

    return 'ChatRemoteException'
        '('
        'statusCode: $statusCode, '
        'message: $message'
        ')';
  }
}
