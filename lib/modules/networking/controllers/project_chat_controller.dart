import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/models/project_message_model.dart';
import '../services/project_chat_service.dart';

// ============================================================
// PROJECT CHAT CONTROLLER
// ============================================================
//
// Responsável pelo estado da interface do chat.
//
// Fluxo:
//
// ChatView
//    ↓
// ProjectChatController
//    ↓
// ProjectChatService
//    ↓
// Supabase
//    ↓
// project_messages
//
// O Controller:
//
// - inicia Realtime;
// - mantém a lista de mensagens;
// - envia mensagens;
// - informa loading;
// - informa sending;
// - informa erros;
// - expõe currentUserId;
// - encerra subscription corretamente.
//
// ============================================================

class ProjectChatController
    with
        ChangeNotifier {
  // ==========================================================
  // PROJETO
  // ==========================================================

  final String projectId;

  // ==========================================================
  // SERVICE
  // ==========================================================

  final ProjectChatService _service;

  // ==========================================================
  // SUBSCRIPTION
  // ==========================================================

  StreamSubscription<
    List<
      ProjectMessageModel
    >
  >?
  _messagesSubscription;

  // ==========================================================
  // ESTADO
  // ==========================================================

  List<
    ProjectMessageModel
  >
  _messages = const [];

  bool _isLoading = true;

  bool _isSending = false;

  bool _disposed = false;

  String? _errorMessage;

  // ==========================================================
  // CONSTRUTOR
  // ==========================================================

  ProjectChatController({
    required String projectId,
    ProjectChatService? service,
  }) : projectId = _requiredProjectId(
         projectId,
       ),
       _service =
           service ??
           ProjectChatService();

  // ==========================================================
  // GETTERS
  // ==========================================================

  List<
    ProjectMessageModel
  >
  get messages => _messages;

  bool get isLoading => _isLoading;

  bool get isSending => _isSending;

  bool get hasMessages => _messages.isNotEmpty;

  bool get hasError =>
      _errorMessage !=
      null;

  String? get errorMessage => _errorMessage;

  String? get currentUserId => _service.currentUserId;

  // ==========================================================
  // INIT
  // ==========================================================

  Future<
    void
  >
  init() async {
    if (_disposed) {
      return;
    }

    // ========================================================
    // RESET
    // ========================================================

    _isLoading = true;

    _errorMessage = null;

    _messages = const [];

    _safeNotify();

    // ========================================================
    // USUÁRIO
    // ========================================================

    final userId = currentUserId;

    if (userId ==
            null ||
        userId.isEmpty) {
      _isLoading = false;

      _errorMessage = 'Usuário não autenticado.';

      _safeNotify();

      return;
    }

    // ========================================================
    // REALTIME
    // ========================================================

    await _startRealtime();
  }

  // ==========================================================
  // START REALTIME
  // ==========================================================

  Future<
    void
  >
  _startRealtime() async {
    await _messagesSubscription?.cancel();

    _messagesSubscription = null;

    try {
      _messagesSubscription = _service
          .streamMessages(
            projectId: projectId,
          )
          .listen(
            _onMessagesReceived,
            onError: _onRealtimeError,
          );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[PROJECT CHAT CONTROLLER] '
        'Erro ao iniciar Realtime: '
        '$error',
      );

      debugPrint(
        '[PROJECT CHAT CONTROLLER] '
        'StackTrace: '
        '$stackTrace',
      );

      if (_disposed) {
        return;
      }

      _isLoading = false;

      _errorMessage = 'Não foi possível conectar ao chat.';

      _safeNotify();
    }
  }

  // ==========================================================
  // MENSAGENS RECEBIDAS
  // ==========================================================

  void _onMessagesReceived(
    List<
      ProjectMessageModel
    >
    messages,
  ) {
    if (_disposed) {
      return;
    }

    // ========================================================
    // MERGE + DEDUPLICAÇÃO
    // ========================================================
    //
    // Junta:
    //
    // - mensagens já adicionadas localmente;
    // - mensagens recebidas pelo Realtime.
    //
    // A chave é o ID real retornado pelo Supabase.
    //
    // ========================================================

    final byId =
        <
          String,
          ProjectMessageModel
        >{};

    for (final message in _messages) {
      if (message.id.isEmpty) {
        continue;
      }

      byId[message.id] = message;
    }

    for (final message in messages) {
      if (message.id.isEmpty) {
        continue;
      }

      byId[message.id] = message;
    }

    // ========================================================
    // ORDENAR
    // ========================================================

    final sorted =
        byId.values.toList(
          growable: false,
        )..sort(
          (
            first,
            second,
          ) => first.createdAt.compareTo(
            second.createdAt,
          ),
        );

    // ========================================================
    // ESTADO
    // ========================================================

    _messages =
        List<
          ProjectMessageModel
        >.unmodifiable(
          sorted,
        );

    _isLoading = false;

    _errorMessage = null;

    _safeNotify();

    debugPrint(
      '[PROJECT CHAT CONTROLLER] '
      '${_messages.length} mensagem(ns) sincronizada(s).',
    );
  }

  // ==========================================================
  // ERRO REALTIME
  // ==========================================================

  void _onRealtimeError(
    Object error,
    StackTrace stackTrace,
  ) {
    if (_disposed) {
      return;
    }

    debugPrint(
      '[PROJECT CHAT CONTROLLER] '
      'Erro Realtime: '
      '$error',
    );

    debugPrint(
      '[PROJECT CHAT CONTROLLER] '
      'StackTrace: '
      '$stackTrace',
    );

    _isLoading = false;

    _errorMessage = 'Não foi possível atualizar as mensagens.';

    _safeNotify();
  }

  // ==========================================================
  // ENVIAR
  // ==========================================================

  Future<
    bool
  >
  sendMessage(
    String content,
  ) async {
    if (_disposed ||
        _isSending) {
      return false;
    }

    final normalized = content.trim();

    if (normalized.isEmpty) {
      return false;
    }

    // ========================================================
    // LIMITE
    // ========================================================

    if (normalized.length >
        ProjectChatService.maxMessageLength) {
      _errorMessage = 'A mensagem é muito longa.';

      _safeNotify();

      return false;
    }

    // ========================================================
    // AUTH
    // ========================================================

    if (currentUserId ==
        null) {
      _errorMessage = 'Usuário não autenticado.';

      _safeNotify();

      return false;
    }

    // ========================================================
    // SENDING
    // ========================================================

    _isSending = true;

    _errorMessage = null;

    _safeNotify();

    try {
      // ======================================================
      // SUPABASE
      // ======================================================

      final sentMessage = await _service.sendMessage(
        projectId: projectId,

        content: normalized,
      );

      if (_disposed) {
        return true;
      }

      // ======================================================
      // MOSTRAR IMEDIATAMENTE
      // ======================================================
      //
      // O INSERT já devolveu:
      //
      // - id;
      // - project_id;
      // - sender_id;
      // - content;
      // - created_at.
      //
      // Portanto não precisamos esperar o Realtime.
      //
      // ======================================================

      _addOrReplaceMessage(
        sentMessage,
      );

      debugPrint(
        '[PROJECT CHAT CONTROLLER] '
        'Mensagem adicionada imediatamente: '
        '${sentMessage.id}',
      );

      return true;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[PROJECT CHAT CONTROLLER] '
        'Erro ao enviar: '
        '$error',
      );

      debugPrint(
        '[PROJECT CHAT CONTROLLER] '
        'StackTrace: '
        '$stackTrace',
      );

      if (!_disposed) {
        _errorMessage = 'Não foi possível enviar a mensagem.';
      }

      return false;
    } finally {
      if (!_disposed) {
        _isSending = false;

        _safeNotify();
      }
    }
  }

  // ==========================================================
  // ADICIONAR / SUBSTITUIR MENSAGEM
  // ==========================================================
  //
  // Evita duplicação quando:
  //
  // INSERT
  //   ↓
  // adicionamos localmente
  //
  // e depois:
  //
  // Realtime
  //   ↓
  // devolve a mesma mensagem.
  //
  // ==========================================================

  void _addOrReplaceMessage(
    ProjectMessageModel message,
  ) {
    if (_disposed ||
        message.id.isEmpty) {
      return;
    }

    final byId =
        <
          String,
          ProjectMessageModel
        >{};

    for (final current in _messages) {
      if (current.id.isEmpty) {
        continue;
      }

      byId[current.id] = current;
    }

    byId[message.id] = message;

    final updated =
        byId.values.toList(
          growable: false,
        )..sort(
          (
            first,
            second,
          ) => first.createdAt.compareTo(
            second.createdAt,
          ),
        );

    _messages =
        List<
          ProjectMessageModel
        >.unmodifiable(
          updated,
        );

    _isLoading = false;

    _errorMessage = null;

    _safeNotify();
  }

  // ==========================================================
  // APAGAR
  // ==========================================================

  Future<
    bool
  >
  deleteMessage(
    String messageId,
  ) async {
    if (_disposed) {
      return false;
    }

    final normalizedMessageId = messageId.trim();

    if (normalizedMessageId.isEmpty) {
      return false;
    }

    try {
      await _service.deleteMessage(
        messageId: normalizedMessageId,
      );

      if (_disposed) {
        return true;
      }

      // ======================================================
      // REMOVER LOCALMENTE
      // ======================================================
      //
      // Não depende do Realtime para a UI responder.
      //
      // ======================================================

      _messages =
          List<
            ProjectMessageModel
          >.unmodifiable(
            _messages.where(
              (
                message,
              ) =>
                  message.id !=
                  normalizedMessageId,
            ),
          );

      _safeNotify();

      return true;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[PROJECT CHAT CONTROLLER] '
        'Erro ao apagar mensagem: '
        '$error',
      );

      debugPrint(
        '[PROJECT CHAT CONTROLLER] '
        'StackTrace: '
        '$stackTrace',
      );

      if (!_disposed) {
        _errorMessage = 'Não foi possível apagar a mensagem.';

        _safeNotify();
      }

      return false;
    }
  }

  // ==========================================================
  // É MINHA?
  // ==========================================================

  bool isMyMessage(
    ProjectMessageModel message,
  ) {
    final userId = currentUserId;

    if (userId ==
        null) {
      return false;
    }

    return message.isMine(
      userId,
    );
  }

  // ==========================================================
  // LIMPAR ERRO
  // ==========================================================

  void clearError() {
    if (_disposed ||
        _errorMessage ==
            null) {
      return;
    }

    _errorMessage = null;

    _safeNotify();
  }

  // ==========================================================
  // RECARREGAR STREAM
  // ==========================================================

  Future<
    void
  >
  reconnect() async {
    if (_disposed) {
      return;
    }

    _isLoading = true;

    _errorMessage = null;

    _safeNotify();

    await _startRealtime();
  }

  // ==========================================================
  // SAFE NOTIFY
  // ==========================================================

  void _safeNotify() {
    if (_disposed) {
      return;
    }

    if (!hasListeners) {
      return;
    }

    notifyListeners();
  }

  // ==========================================================
  // PROJECT ID
  // ==========================================================

  static String _requiredProjectId(
    String value,
  ) {
    final normalized = value.trim();

    if (normalized.isEmpty) {
      throw ArgumentError(
        'projectId não pode ser vazio.',
      );
    }

    return normalized;
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    if (_disposed) {
      return;
    }

    _disposed = true;

    unawaited(
      _messagesSubscription?.cancel(),
    );

    _messagesSubscription = null;

    super.dispose();
  }
}
