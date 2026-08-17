import 'package:flutter/material.dart';

import '../../controllers/project_chat_controller.dart';
import '../../data/models/project_message_model.dart';

class ChatView
    extends
        StatefulWidget {
  final String projectId;

  const ChatView({
    super.key,
    required this.projectId,
  });

  @override
  State<
    ChatView
  >
  createState() => _ChatViewState();
}

class _ChatViewState
    extends
        State<
          ChatView
        > {
  // ==========================================================
  // CONTROLLER
  // ==========================================================

  late final ProjectChatController _controller;

  // ==========================================================
  // TEXT
  // ==========================================================

  final TextEditingController _messageController = TextEditingController();

  // ==========================================================
  // SCROLL
  // ==========================================================

  final ScrollController _scrollController = ScrollController();

  // ==========================================================
  // ESTADO LOCAL
  // ==========================================================

  int _previousMessageCount = 0;

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _controller = ProjectChatController(
      projectId: widget.projectId,
    );

    _controller.addListener(
      _handleControllerUpdate,
    );

    _controller.init();
  }

  // ==========================================================
  // CONTROLLER UPDATE
  // ==========================================================

  void _handleControllerUpdate() {
    if (!mounted) {
      return;
    }

    final currentCount = _controller.messages.length;

    if (currentCount >
        _previousMessageCount) {
      _previousMessageCount = currentCount;

      _scrollToBottom();
    }
  }

  // ==========================================================
  // SCROLL
  // ==========================================================

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback(
      (
        _,
      ) {
        if (!mounted ||
            !_scrollController.hasClients) {
          return;
        }

        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(
            milliseconds: 250,
          ),
          curve: Curves.easeOut,
        );
      },
    );
  }

  // ==========================================================
  // ENVIAR
  // ==========================================================

  Future<
    void
  >
  _sendMessage() async {
    final text = _messageController.text.trim();

    if (text.isEmpty ||
        _controller.isSending) {
      return;
    }

    final sent = await _controller.sendMessage(
      text,
    );

    if (!mounted) {
      return;
    }

    if (sent) {
      _messageController.clear();

      _scrollToBottom();

      return;
    }

    final error = _controller.errorMessage;

    if (error !=
            null &&
        error.isNotEmpty) {
      _showError(
        error,
      );
    }
  }

  // ==========================================================
  // ERRO
  // ==========================================================

  void _showError(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
        context,
      )
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
          ),
          backgroundColor: Colors.red.shade900,
        ),
      );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: const Color(
        0xFF0F0F0F,
      ),

      appBar: AppBar(
        title: const Text(
          'Chat de Sessão',
          style: TextStyle(
            fontSize: 16,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      body: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: _controller,

          builder:
              (
                context,
                _,
              ) {
                return Column(
                  children: [
                    // ============================================
                    // CONTEÚDO
                    // ============================================
                    Expanded(
                      child: _buildContent(),
                    ),

                    // ============================================
                    // ERRO
                    // ============================================
                    if (_controller.hasError &&
                        !_controller.isLoading)
                      _buildErrorBar(),

                    // ============================================
                    // INPUT
                    // ============================================
                    _buildMessageInput(),
                  ],
                );
              },
        ),
      ),
    );
  }

  // ==========================================================
  // CONTEÚDO
  // ==========================================================

  Widget _buildContent() {
    if (_controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_controller.messages.isEmpty) {
      return _buildEmptyState();
    }

    return _buildMessageList();
  }

  // ==========================================================
  // EMPTY
  // ==========================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(
          30,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.chat_bubble_outline_rounded,
              color: Colors.white24,
              size: 42,
            ),

            const SizedBox(
              height: 15,
            ),

            const Text(
              'Nenhuma mensagem ainda',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(
              height: 6,
            ),

            Text(
              'Envie a primeira mensagem da sessão.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(
                  alpha: 0.35,
                ),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // LISTA
  // ==========================================================

  Widget _buildMessageList() {
    final messages = _controller.messages;

    return ListView.builder(
      controller: _scrollController,

      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        20,
      ),

      itemCount: messages.length,

      itemBuilder:
          (
            context,
            index,
          ) {
            final message = messages[index];

            final isMine = _controller.isMyMessage(
              message,
            );

            return _buildMessage(
              message: message,
              isMine: isMine,
            );
          },
    );
  }

  // ==========================================================
  // MENSAGEM
  // ==========================================================

  Widget _buildMessage({
    required ProjectMessageModel message,
    required bool isMine,
  }) {
    return Align(
      alignment: isMine
          ? Alignment.centerRight
          : Alignment.centerLeft,

      child: GestureDetector(
        onLongPress: isMine
            ? () => _showMessageOptions(
                message,
              )
            : null,

        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 360,
          ),

          margin: const EdgeInsets.only(
            bottom: 10,
          ),

          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),

          decoration: BoxDecoration(
            color: isMine
                ? const Color(
                    0xFF6D28D9,
                  )
                : const Color(
                    0xFF202020,
                  ),

            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(
                16,
              ),

              topRight: const Radius.circular(
                16,
              ),

              bottomLeft: Radius.circular(
                isMine
                    ? 16
                    : 4,
              ),

              bottomRight: Radius.circular(
                isMine
                    ? 4
                    : 16,
              ),
            ),
          ),

          child: Column(
            crossAxisAlignment: isMine
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,

            children: [
              // ==============================================
              // TEXTO
              // ==============================================
              Text(
                message.content,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.35,
                ),
              ),

              const SizedBox(
                height: 5,
              ),

              // ==============================================
              // HORÁRIO
              // ==============================================
              Text(
                _formatTime(
                  message.createdAt,
                ),
                style: TextStyle(
                  color: Colors.white.withValues(
                    alpha: 0.45,
                  ),
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // INPUT
  // ==========================================================

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        12,
        10,
        12,
        12,
      ),

      decoration: const BoxDecoration(
        color: Color(
          0xFF151515,
        ),

        border: Border(
          top: BorderSide(
            color: Colors.white10,
          ),
        ),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,

        children: [
          // ================================================
          // CAMPO
          // ================================================
          Expanded(
            child: TextField(
              controller: _messageController,

              enabled: !_controller.isSending,

              minLines: 1,

              maxLines: 5,

              maxLength: 4000,

              textCapitalization: TextCapitalization.sentences,

              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),

              decoration: InputDecoration(
                hintText: 'Digite uma mensagem...',

                hintStyle: const TextStyle(
                  color: Colors.white38,
                ),

                counterText: '',

                filled: true,

                fillColor: const Color(
                  0xFF202020,
                ),

                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    22,
                  ),
                  borderSide: BorderSide.none,
                ),

                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    22,
                  ),
                  borderSide: BorderSide.none,
                ),

                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    22,
                  ),
                  borderSide: const BorderSide(
                    color: Color(
                      0xFF6D28D9,
                    ),
                  ),
                ),
              ),

              onSubmitted:
                  (
                    _,
                  ) {
                    _sendMessage();
                  },
            ),
          ),

          const SizedBox(
            width: 8,
          ),

          // ================================================
          // ENVIAR
          // ================================================
          Material(
            color: const Color(
              0xFF6D28D9,
            ),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),

              onTap: _controller.isSending
                  ? null
                  : _sendMessage,

              child: SizedBox(
                width: 46,
                height: 46,
                child: Center(
                  child: _controller.isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ERROR BAR
  // ==========================================================

  Widget _buildErrorBar() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),

      color: Colors.red.withValues(
        alpha: 0.12,
      ),

      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.redAccent,
            size: 17,
          ),

          const SizedBox(
            width: 8,
          ),

          Expanded(
            child: Text(
              _controller.errorMessage ??
                  'Erro no chat.',
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 11,
              ),
            ),
          ),

          TextButton(
            onPressed: _controller.reconnect,

            child: const Text(
              'Tentar novamente',
              style: TextStyle(
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // OPÇÕES DA MENSAGEM
  // ==========================================================

  void _showMessageOptions(
    ProjectMessageModel message,
  ) {
    showModalBottomSheet<
      void
    >(
      context: context,

      backgroundColor: const Color(
        0xFF202020,
      ),

      builder:
          (
            bottomSheetContext,
          ) {
            return SafeArea(
              child: ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                ),

                title: const Text(
                  'Apagar mensagem',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),

                onTap: () async {
                  Navigator.pop(
                    bottomSheetContext,
                  );

                  final deleted = await _controller.deleteMessage(
                    message.id,
                  );

                  if (!deleted &&
                      mounted) {
                    _showError(
                      _controller.errorMessage ??
                          'Não foi possível apagar a mensagem.',
                    );
                  }
                },
              ),
            );
          },
    );
  }

  // ==========================================================
  // HORÁRIO
  // ==========================================================

  String _formatTime(
    DateTime date,
  ) {
    final local = date.toLocal();

    final hour = local.hour.toString().padLeft(
      2,
      '0',
    );

    final minute = local.minute.toString().padLeft(
      2,
      '0',
    );

    return '$hour:$minute';
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _controller.removeListener(
      _handleControllerUpdate,
    );

    _controller.dispose();

    _messageController.dispose();

    _scrollController.dispose();

    super.dispose();
  }
}
