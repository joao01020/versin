import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../data/models/project_message_model.dart';
import '../services/project_chat_service.dart';

// ============================================================
// PROJECT CHAT CONTROLLER
// ============================================================
//
// Responsável pelo estado da interface do chat compartilhado
// de uma Studio Session.
//
// FLUXO:
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
// MODELO:
//
// A conversa pertence ao:
//
// projectId
//
// e NÃO a uma dupla fixa.
//
// Portanto:
//
// João + Maria
//      ↓
// mesmo projectId
//
// Pedro entra na Studio Session
//      ↓
// mesmo projectId
//
// João + Maria + Pedro
//      ↓
// continuam usando o mesmo chat.
//
// O Controller:
//
// - inicia Realtime;
// - mantém mensagens da Studio Session;
// - aceita mensagens de vários remetentes;
// - deduplica mensagens;
// - mantém ordenação cronológica;
// - envia mensagens;
// - remove mensagens;
// - informa loading;
// - informa sending;
// - informa erros;
// - expõe currentUserId;
// - expõe IDs dos participantes que já falaram;
// - encerra subscription corretamente.
//
// IMPORTANTE:
//
// A autorização de quem pode ler e escrever deve continuar
// sendo garantida pelo Service / Repository / RLS.
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
  _messages =
      const <
        ProjectMessageModel
      >[];

  bool _isLoading = true;

  bool _isSending = false;

  bool _isSendingAudio = false;

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

  bool get isSendingAudio => _isSendingAudio;

  bool get isBusy =>
      _isSending ||
      _isSendingAudio;

  bool get hasMessages => _messages.isNotEmpty;

  bool get hasError =>
      _errorMessage !=
      null;

  String? get errorMessage => _errorMessage;

  String? get currentUserId => _service.currentUserId;

  int get messageCount => _messages.length;

  // ==========================================================
  // IDS DOS REMETENTES
  // ==========================================================
  //
  // Retorna os usuários que já enviaram mensagem nesta
  // Studio Session.
  //
  // Não representa necessariamente TODOS os membros atuais
  // do projeto.
  //
  // Para isso, MembersView / ProjectMembersService continuam
  // sendo a fonte correta.
  //
  // ==========================================================

  Set<
    String
  >
  get senderUserIds {
    final result =
        <
          String
        >{};

    for (final message in _messages) {
      final senderId = message.senderId.trim();

      if (senderId.isEmpty) {
        continue;
      }

      result.add(
        senderId,
      );
    }

    return Set<
      String
    >.unmodifiable(
      result,
    );
  }

  // ==========================================================
  // OUTROS REMETENTES
  // ==========================================================

  Set<
    String
  >
  get otherSenderUserIds {
    final userId = currentUserId?.trim();

    if (userId ==
            null ||
        userId.isEmpty) {
      return senderUserIds;
    }

    return Set<
      String
    >.unmodifiable(
      senderUserIds.where(
        (
          senderId,
        ) =>
            senderId !=
            userId,
      ),
    );
  }

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

    _messages =
        const <
          ProjectMessageModel
        >[];

    _safeNotify();

    // ========================================================
    // USUÁRIO
    // ========================================================

    final userId = currentUserId?.trim();

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
    // Como a conversa é da Studio Session, também filtramos
    // defensivamente pelo projectId.
    //
    // ========================================================

    final byId =
        <
          String,
          ProjectMessageModel
        >{};

    for (final message in _messages) {
      if (!_belongsToCurrentProject(
        message,
      )) {
        continue;
      }

      if (message.id.isEmpty) {
        continue;
      }

      byId[message.id] = message;
    }

    for (final message in messages) {
      if (!_belongsToCurrentProject(
        message,
      )) {
        continue;
      }

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
      '${_messages.length} mensagem(ns) sincronizada(s) '
      'na Studio Session $projectId.',
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

    final userId = currentUserId?.trim();

    if (userId ==
            null ||
        userId.isEmpty) {
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
      //
      // A mensagem é enviada somente com:
      //
      // projectId
      // content
      //
      // O senderId vem do usuário autenticado no Service /
      // banco.
      //
      // Não existe receiverId aqui.
      //
      // Isso é o que permite o mesmo chat funcionar com:
      //
      // 2 membros
      // 3 membros
      // 4 membros
      // ...
      //
      // ======================================================

      final sentMessage = await _service.sendMessage(
        projectId: projectId,

        content: normalized,
      );

      if (_disposed) {
        return true;
      }

      // ======================================================
      // VALIDAR PROJETO
      // ======================================================

      if (!_belongsToCurrentProject(
        sentMessage,
      )) {
        _errorMessage = 'A mensagem retornou vinculada a outra sessão.';

        return false;
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
  // ENVIAR ÁUDIO
  // ==========================================================

  Future<
    bool
  >
  sendAudioMessage({
    required Uint8List audioBytes,
    required int durationMs,
    String fileExtension = 'wav',
    String mimeType = 'audio/wav',
  }) async {
    if (_disposed ||
        _isSendingAudio) {
      return false;
    }

    if (audioBytes.isEmpty) {
      _errorMessage = 'O áudio gravado está vazio.';

      _safeNotify();

      return false;
    }

    if (durationMs <=
        0) {
      _errorMessage = 'A duração do áudio é inválida.';

      _safeNotify();

      return false;
    }

    final userId = currentUserId?.trim();

    if (userId ==
            null ||
        userId.isEmpty) {
      _errorMessage = 'Usuário não autenticado.';

      _safeNotify();

      return false;
    }

    _isSendingAudio = true;

    _errorMessage = null;

    _safeNotify();

    try {
      final sentMessage = await _service.sendAudioMessage(
        projectId: projectId,
        audioBytes: audioBytes,
        audioDurationMs: durationMs,
        extension: fileExtension,
        mimeType: mimeType,
      );

      if (_disposed) {
        return true;
      }

      if (!_belongsToCurrentProject(
        sentMessage,
      )) {
        _errorMessage = 'O áudio retornou vinculado a outra sessão.';

        return false;
      }

      _addOrReplaceMessage(
        sentMessage,
      );

      debugPrint(
        '[PROJECT CHAT CONTROLLER] '
        'Áudio adicionado imediatamente: '
        '${sentMessage.id}',
      );

      return true;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[PROJECT CHAT CONTROLLER] '
        'Erro ao enviar áudio: '
        '$error',
      );

      debugPrint(
        '[PROJECT CHAT CONTROLLER] '
        'StackTrace: '
        '$stackTrace',
      );

      if (!_disposed) {
        _errorMessage = 'Não foi possível enviar o áudio.';
      }

      return false;
    } finally {
      if (!_disposed) {
        _isSendingAudio = false;

        _safeNotify();
      }
    }
  }

  // ==========================================================
  // CRIAR URL PARA REPRODUÇÃO DO ÁUDIO
  // ==========================================================

  Future<
    String
  >
  createAudioPlaybackUrl({
    required String audioPath,
    int expiresInSeconds = 3600,
  }) {
    return _service.createAudioPlaybackUrl(
      audioPath: audioPath,
      expiresInSeconds: expiresInSeconds,
    );
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
        message.id.isEmpty ||
        !_belongsToCurrentProject(
          message,
        )) {
      return;
    }

    final byId =
        <
          String,
          ProjectMessageModel
        >{};

    for (final current in _messages) {
      if (current.id.isEmpty ||
          !_belongsToCurrentProject(
            current,
          )) {
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

    // ========================================================
    // GARANTIR QUE A MENSAGEM ESTÁ NESTA SESSÃO
    // ========================================================

    final message = getMessageById(
      normalizedMessageId,
    );

    if (message ==
        null) {
      _errorMessage = 'Mensagem não encontrada nesta sessão.';

      _safeNotify();

      return false;
    }

    // ========================================================
    // SOMENTE AUTOR
    // ========================================================
    //
    // A RLS continua sendo a proteção real.
    //
    // Esta validação evita uma ação inválida na própria UI.
    //
    // ========================================================

    if (!isMyMessage(
      message,
    )) {
      _errorMessage = 'Você só pode apagar suas próprias mensagens.';

      _safeNotify();

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

      _messages =
          List<
            ProjectMessageModel
          >.unmodifiable(
            _messages.where(
              (
                current,
              ) =>
                  current.id !=
                  normalizedMessageId,
            ),
          );

      _errorMessage = null;

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
  // BUSCAR MENSAGEM
  // ==========================================================

  ProjectMessageModel? getMessageById(
    String messageId,
  ) {
    final normalized = messageId.trim();

    if (normalized.isEmpty) {
      return null;
    }

    for (final message in _messages) {
      if (message.id ==
          normalized) {
        return message;
      }
    }

    return null;
  }

  // ==========================================================
  // MENSAGENS DE UM MEMBRO
  // ==========================================================

  List<
    ProjectMessageModel
  >
  getMessagesByUserId(
    String userId,
  ) {
    final normalized = userId.trim();

    if (normalized.isEmpty) {
      return const <
        ProjectMessageModel
      >[];
    }

    return List<
      ProjectMessageModel
    >.unmodifiable(
      _messages.where(
        (
          message,
        ) =>
            message.senderId.trim() ==
            normalized,
      ),
    );
  }

  // ==========================================================
  // É MINHA?
  // ==========================================================

  bool isMyMessage(
    ProjectMessageModel message,
  ) {
    final userId = currentUserId?.trim();

    if (userId ==
            null ||
        userId.isEmpty) {
      return false;
    }

    return message.isMine(
      userId,
    );
  }

  // ==========================================================
  // PERTENCE AO PROJETO?
  // ==========================================================

  bool _belongsToCurrentProject(
    ProjectMessageModel message,
  ) {
    return message.projectId.trim() ==
        projectId;
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
