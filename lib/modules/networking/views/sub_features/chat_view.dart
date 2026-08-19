import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../controllers/project_chat_controller.dart';
import '../../data/models/project_message_model.dart';
import '../../services/chat_audio_recorder_service.dart';
import '../../widgets/chat_audio_player.dart';

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
  // SUPABASE
  // ==========================================================

  final SupabaseClient _supabase = Supabase.instance.client;

  // ==========================================================
  // CACHE DE NOMES
  // ==========================================================

  final Map<
    String,
    String
  >
  _memberNameCache =
      <
        String,
        String
      >{};

  final Set<
    String
  >
  _memberNameLoading =
      <
        String
      >{};

  // ==========================================================
  // AUDIO RECORDER
  // ==========================================================

  final ChatAudioRecorderService _audioRecorder = ChatAudioRecorderService();

  Timer? _recordingUiTimer;

  bool _isRecordingAudio = false;

  bool _isAudioPaused = false;

  Duration _recordingDuration = Duration.zero;

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

    _resolveVisibleMemberNames();
  }

  // ==========================================================
  // CONTROLLER UPDATE
  // ==========================================================

  void _handleControllerUpdate() {
    if (!mounted) {
      return;
    }

    _resolveVisibleMemberNames();

    final currentCount = _controller.messages.length;

    if (currentCount >
        _previousMessageCount) {
      _previousMessageCount = currentCount;

      _scrollToBottom();
    }
  }

  // ==========================================================
  // RESOLVER NOMES DOS MEMBROS
  // ==========================================================

  void _resolveVisibleMemberNames() {
    for (final message in _controller.messages) {
      final senderId = message.senderId.trim();

      if (senderId.isEmpty) {
        continue;
      }

      if (_memberNameCache.containsKey(
        senderId,
      )) {
        continue;
      }

      if (_memberNameLoading.contains(
        senderId,
      )) {
        continue;
      }

      _loadMemberName(
        senderId,
      );
    }
  }

  // ==========================================================
  // CARREGAR NOME DO MEMBRO
  // ==========================================================

  Future<
    void
  >
  _loadMemberName(
    String userId,
  ) async {
    final normalizedUserId = userId.trim();

    if (normalizedUserId.isEmpty) {
      return;
    }

    if (_memberNameCache.containsKey(
      normalizedUserId,
    )) {
      return;
    }

    if (_memberNameLoading.contains(
      normalizedUserId,
    )) {
      return;
    }

    _memberNameLoading.add(
      normalizedUserId,
    );

    try {
      final profile = await _supabase
          .from(
            'profiles',
          )
          .select(
            'id, artist_name, name, username',
          )
          .eq(
            'id',
            normalizedUserId,
          )
          .maybeSingle();

      final resolvedName = _resolveProfileDisplayName(
        profile,
      );

      if (!mounted) {
        return;
      }

      setState(
        () {
          _memberNameCache[normalizedUserId] = resolvedName;
        },
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[CHAT VIEW] '
        'Erro ao buscar perfil do membro '
        '$normalizedUserId: '
        '$error',
      );

      debugPrint(
        '$stackTrace',
      );

      if (!mounted) {
        return;
      }

      setState(
        () {
          _memberNameCache[normalizedUserId] = 'Membro';
        },
      );
    } finally {
      _memberNameLoading.remove(
        normalizedUserId,
      );
    }
  }

  // ==========================================================
  // NOME DO PERFIL
  // ==========================================================

  String _resolveProfileDisplayName(
    Map<
      String,
      dynamic
    >?
    profile,
  ) {
    if (profile ==
        null) {
      return 'Membro';
    }

    final artistName = profile['artist_name']?.toString().trim();

    if (artistName !=
            null &&
        artistName.isNotEmpty) {
      return artistName;
    }

    final name = profile['name']?.toString().trim();

    if (name !=
            null &&
        name.isNotEmpty) {
      return name;
    }

    final username = profile['username']?.toString().trim().replaceFirst(
      RegExp(
        r'^@+',
      ),
      '',
    );

    if (username !=
            null &&
        username.isNotEmpty) {
      return '@$username';
    }

    return 'Membro';
  }

  // ==========================================================
  // NOME DA MENSAGEM
  // ==========================================================

  String _getMessageSenderName(
    ProjectMessageModel message,
  ) {
    final senderId = message.senderId.trim();

    if (senderId.isEmpty) {
      return 'Membro';
    }

    return _memberNameCache[senderId] ??
        'Membro';
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
  // INICIAR GRAVAÇÃO DE ÁUDIO
  // ==========================================================

  Future<
    void
  >
  _startAudioRecording() async {
    if (_controller.isBusy ||
        _isRecordingAudio) {
      return;
    }

    final started = await _audioRecorder.start();

    if (!mounted) {
      return;
    }

    if (!started) {
      _showError(
        'Não foi possível iniciar a gravação. Verifique a permissão do microfone.',
      );

      return;
    }

    _recordingUiTimer?.cancel();

    _recordingUiTimer = Timer.periodic(
      const Duration(
        milliseconds: 250,
      ),
      (
        _,
      ) {
        if (!mounted) {
          return;
        }

        setState(
          () {
            _recordingDuration = _audioRecorder.duration;
          },
        );
      },
    );

    setState(
      () {
        _isRecordingAudio = true;
        _isAudioPaused = false;
        _recordingDuration = Duration.zero;
      },
    );
  }

  // ==========================================================
  // PAUSAR / CONTINUAR
  // ==========================================================

  Future<
    void
  >
  _toggleAudioPause() async {
    if (!_isRecordingAudio ||
        _controller.isSendingAudio) {
      return;
    }

    if (_isAudioPaused) {
      final resumed = await _audioRecorder.resume();

      if (!mounted) {
        return;
      }

      if (!resumed) {
        _showError(
          'Não foi possível continuar a gravação.',
        );

        return;
      }

      setState(
        () {
          _isAudioPaused = false;
        },
      );

      return;
    }

    final paused = await _audioRecorder.pause();

    if (!mounted) {
      return;
    }

    if (!paused) {
      _showError(
        'Não foi possível pausar a gravação.',
      );

      return;
    }

    setState(
      () {
        _isAudioPaused = true;
        _recordingDuration = _audioRecorder.duration;
      },
    );
  }

  // ==========================================================
  // CANCELAR GRAVAÇÃO
  // ==========================================================

  Future<
    void
  >
  _cancelAudioRecording() async {
    if (!_isRecordingAudio ||
        _controller.isSendingAudio) {
      return;
    }

    _recordingUiTimer?.cancel();
    _recordingUiTimer = null;

    await _audioRecorder.cancel();

    if (!mounted) {
      return;
    }

    setState(
      () {
        _isRecordingAudio = false;
        _isAudioPaused = false;
        _recordingDuration = Duration.zero;
      },
    );
  }

  // ==========================================================
  // FINALIZAR E ENVIAR ÁUDIO
  // ==========================================================

  Future<
    void
  >
  _sendAudioRecording() async {
    if (!_isRecordingAudio ||
        _controller.isSendingAudio) {
      return;
    }

    _recordingUiTimer?.cancel();
    _recordingUiTimer = null;

    final recordedAudio = await _audioRecorder.stop();

    if (!mounted) {
      return;
    }

    if (recordedAudio ==
            null ||
        recordedAudio.isEmpty ||
        recordedAudio.durationMs <=
            0) {
      setState(
        () {
          _isRecordingAudio = false;
          _isAudioPaused = false;
          _recordingDuration = Duration.zero;
        },
      );

      _showError(
        'Nenhum áudio válido foi gravado.',
      );

      return;
    }

    setState(
      () {
        _isRecordingAudio = false;
        _isAudioPaused = false;
        _recordingDuration = recordedAudio.duration;
      },
    );

    final sent = await _controller.sendAudioMessage(
      audioBytes: recordedAudio.bytes,
      durationMs: recordedAudio.durationMs,
      fileExtension: recordedAudio.extension,
      mimeType: recordedAudio.mimeType,
    );

    if (!mounted) {
      return;
    }

    setState(
      () {
        _recordingDuration = Duration.zero;
      },
    );

    if (sent) {
      _scrollToBottom();

      return;
    }

    final error = _controller.errorMessage;

    _showError(
      error !=
                  null &&
              error.isNotEmpty
          ? error
          : 'Não foi possível enviar o áudio.',
    );
  }

  // ==========================================================
  // FORMATAR TEMPO DE GRAVAÇÃO
  // ==========================================================

  String _formatRecordingDuration(
    Duration duration,
  ) {
    final totalSeconds = duration.inSeconds;

    final minutes =
        totalSeconds ~/
        60;

    final seconds =
        totalSeconds %
        60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
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
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chat - Sessão de Studio',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(
              height: 2,
            ),
            Text(
              'Conversa compartilhada entre os membros',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
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
                    // CHAT COMPARTILHADO
                    // ============================================
                    _buildSessionChatNotice(),

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
  // AVISO DO CHAT DA SESSÃO
  // ==========================================================

  Widget _buildSessionChatNotice() {
    return Container(
      width: double.infinity,

      margin: const EdgeInsets.fromLTRB(
        16,
        8,
        16,
        4,
      ),

      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 9,
      ),

      decoration: BoxDecoration(
        color:
            const Color(
              0xFF6D28D9,
            ).withValues(
              alpha: 0.08,
            ),

        borderRadius: BorderRadius.circular(
          14,
        ),

        border: Border.all(
          color:
              const Color(
                0xFF6D28D9,
              ).withValues(
                alpha: 0.18,
              ),
        ),
      ),

      child: const Row(
        children: [
          Icon(
            Icons.groups_2_outlined,
            color: Color(
              0xFFA78BFA,
            ),
            size: 17,
          ),

          SizedBox(
            width: 9,
          ),

          Expanded(
            child: Text(
              'Este chat pertence à Studio Session e acompanha a equipe conforme novos membros entram.',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 10,
                height: 1.35,
              ),
            ),
          ),
        ],
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
              'Comece a conversa. Todos os membros da sessão poderão participar aqui.',
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
              // AUTOR
              // ==============================================
              if (!isMine) ...[
                Text(
                  _getMessageSenderName(
                    message,
                  ),
                  style: const TextStyle(
                    color: Color(
                      0xFFA78BFA,
                    ),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),
              ],

              // ==============================================
              // CONTEÚDO: TEXTO / ÁUDIO
              // ==============================================
              if (message.isAudio)
                ChatAudioPlayer(
                  controller: _controller,
                  message: message,
                  isMine: isMine,
                )
              else
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
    if (_isRecordingAudio) {
      return _buildAudioRecordingInput();
    }

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

              enabled: !_controller.isBusy,

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
          // MICROFONE
          // ================================================
          Material(
            color: const Color(
              0xFF252525,
            ),

            shape: const CircleBorder(),

            child: InkWell(
              customBorder: const CircleBorder(),

              onTap: _controller.isBusy
                  ? null
                  : _startAudioRecording,

              child: SizedBox(
                width: 46,
                height: 46,
                child: Center(
                  child: Icon(
                    Icons.mic_rounded,
                    color: _controller.isBusy
                        ? Colors.white24
                        : const Color(
                            0xFFA78BFA,
                          ),
                    size: 21,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(
            width: 8,
          ),

          // ================================================
          // ENVIAR TEXTO
          // ================================================
          Material(
            color: const Color(
              0xFF6D28D9,
            ),

            shape: const CircleBorder(),

            child: InkWell(
              customBorder: const CircleBorder(),

              onTap: _controller.isBusy
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
  // INPUT DE GRAVAÇÃO
  // ==========================================================

  Widget _buildAudioRecordingInput() {
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
        children: [
          // ================================================
          // CANCELAR
          // ================================================
          Material(
            color: Colors.red.withValues(
              alpha: 0.12,
            ),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _controller.isSendingAudio
                  ? null
                  : _cancelAudioRecording,
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                  size: 20,
                ),
              ),
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          // ================================================
          // STATUS / TEMPO
          // ================================================
          Expanded(
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
              ),
              decoration: BoxDecoration(
                color: const Color(
                  0xFF202020,
                ),
                borderRadius: BorderRadius.circular(
                  22,
                ),
                border: Border.all(
                  color: _isAudioPaused
                      ? Colors.amber.withValues(
                          alpha: 0.30,
                        )
                      : Colors.redAccent.withValues(
                          alpha: 0.25,
                        ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _isAudioPaused
                          ? Colors.amber
                          : Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                  ),

                  const SizedBox(
                    width: 9,
                  ),

                  Text(
                    _isAudioPaused
                        ? 'Pausado'
                        : 'Gravando',
                    style: TextStyle(
                      color: _isAudioPaused
                          ? Colors.amber
                          : Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const Spacer(),

                  Text(
                    _formatRecordingDuration(
                      _recordingDuration,
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(
            width: 8,
          ),

          // ================================================
          // PAUSAR / CONTINUAR
          // ================================================
          Material(
            color: const Color(
              0xFF252525,
            ),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _controller.isSendingAudio
                  ? null
                  : _toggleAudioPause,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  _isAudioPaused
                      ? Icons.play_arrow_rounded
                      : Icons.pause_rounded,
                  color: const Color(
                    0xFFA78BFA,
                  ),
                  size: 21,
                ),
              ),
            ),
          ),

          const SizedBox(
            width: 8,
          ),

          // ================================================
          // ENVIAR ÁUDIO
          // ================================================
          Material(
            color: const Color(
              0xFF6D28D9,
            ),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _controller.isSendingAudio
                  ? null
                  : _sendAudioRecording,
              child: SizedBox(
                width: 46,
                height: 46,
                child: Center(
                  child: _controller.isSendingAudio
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
    final canDelete = _controller.canDeleteMessage(
      message,
    );

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
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 6,
                ),

                child: Column(
                  mainAxisSize: MainAxisSize.min,

                  children: [
                    ListTile(
                      leading: Icon(
                        canDelete
                            ? Icons.delete_outline_rounded
                            : Icons.lock_clock_outlined,
                        color: canDelete
                            ? Colors.redAccent
                            : Colors.white30,
                      ),

                      title: Text(
                        canDelete
                            ? message.isAudio
                                  ? 'Apagar áudio'
                                  : 'Apagar mensagem'
                            : 'Não é mais possível apagar',
                        style: TextStyle(
                          color: canDelete
                              ? Colors.white
                              : Colors.white38,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      subtitle: Text(
                        canDelete
                            ? 'Você pode apagar durante as primeiras 24 horas.'
                            : 'O prazo de 24 horas para apagar terminou.',
                        style: TextStyle(
                          color: Colors.white.withValues(
                            alpha: 0.35,
                          ),
                          fontSize: 11,
                        ),
                      ),

                      onTap: canDelete
                          ? () async {
                              Navigator.pop(
                                bottomSheetContext,
                              );

                              final confirmed = await _confirmDeleteMessage(
                                message,
                              );

                              if (!confirmed ||
                                  !mounted) {
                                return;
                              }

                              final deleted = await _controller.deleteMessage(
                                message.id,
                              );

                              if (!mounted) {
                                return;
                              }

                              if (!deleted) {
                                _showError(
                                  _controller.errorMessage ??
                                      'Não foi possível apagar a mensagem.',
                                );
                              }
                            }
                          : null,
                    ),
                  ],
                ),
              ),
            );
          },
    );
  }

  // ==========================================================
  // CONFIRMAR EXCLUSÃO
  // ==========================================================

  Future<
    bool
  >
  _confirmDeleteMessage(
    ProjectMessageModel message,
  ) async {
    final result =
        await showDialog<
          bool
        >(
          context: context,

          builder:
              (
                dialogContext,
              ) {
                return AlertDialog(
                  backgroundColor: const Color(
                    0xFF202020,
                  ),

                  title: Text(
                    message.isAudio
                        ? 'Apagar áudio?'
                        : 'Apagar mensagem?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  content: Text(
                    message.isAudio
                        ? 'O áudio será removido do chat e não poderá ser recuperado.'
                        : 'A mensagem será removida do chat e não poderá ser recuperada.',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),

                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(
                          dialogContext,
                          false,
                        );
                      },
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          color: Colors.white54,
                        ),
                      ),
                    ),

                    TextButton(
                      onPressed: () {
                        Navigator.pop(
                          dialogContext,
                          true,
                        );
                      },
                      child: const Text(
                        'Apagar',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                );
              },
        );

    return result ??
        false;
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
    _recordingUiTimer?.cancel();

    _recordingUiTimer = null;

    unawaited(
      _audioRecorder.dispose(),
    );

    _controller.removeListener(
      _handleControllerUpdate,
    );

    _controller.dispose();

    _messageController.dispose();

    _scrollController.dispose();

    super.dispose();
  }
}
