import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../controllers/project_chat_controller.dart';
import '../models/project_message_model.dart';

// ============================================================
// CHAT AUDIO PLAYER
// ============================================================
//
// Player de mensagens de áudio da Studio Session.
//
// Fluxo:
//
// ProjectMessageModel
//    ↓
// audio_path
//    ↓
// ProjectChatController
//    ↓
// ProjectChatService
//    ↓
// URL assinada temporária
//    ↓
// just_audio
//
// O widget:
//
// - cria URL assinada somente quando necessário;
// - carrega o áudio;
// - reproduz;
// - pausa;
// - permite seek;
// - mostra duração;
// - mostra posição;
// - trata loading;
// - trata erro;
// - volta ao início ao finalizar;
// - descarta o player corretamente.
//
// ============================================================

class ChatAudioPlayer
    extends
        StatefulWidget {
  // ==========================================================
  // CONTROLLER
  // ==========================================================

  final ProjectChatController controller;

  // ==========================================================
  // MESSAGE
  // ==========================================================

  final ProjectMessageModel message;

  // ==========================================================
  // VISUAL
  // ==========================================================

  final bool isMine;

  // ==========================================================
  // CONSTRUCTOR
  // ==========================================================

  const ChatAudioPlayer({
    super.key,
    required this.controller,
    required this.message,
    required this.isMine,
  });

  // ==========================================================
  // STATE
  // ==========================================================

  @override
  State<
    ChatAudioPlayer
  >
  createState() => _ChatAudioPlayerState();
}

// ============================================================
// STATE
// ============================================================

class _ChatAudioPlayerState
    extends
        State<
          ChatAudioPlayer
        > {
  // ==========================================================
  // PLAYER
  // ==========================================================

  final AudioPlayer _player = AudioPlayer();

  // ==========================================================
  // SUPABASE
  // ==========================================================

  final SupabaseClient _supabase = Supabase.instance.client;

  static const String _audioBucket = 'chat-audio';

  // ==========================================================
  // CHAT SERVICE
  // ==========================================================

  // ==========================================================
  // SUBSCRIPTIONS
  // ==========================================================

  StreamSubscription<
    PlayerState
  >?
  _playerStateSubscription;

  StreamSubscription<
    Duration
  >?
  _positionSubscription;

  StreamSubscription<
    Duration?
  >?
  _durationSubscription;

  // ==========================================================
  // STATE
  // ==========================================================

  bool _isLoading = false;

  bool _isReady = false;

  bool _hasError = false;

  bool _isPlaying = false;

  Duration _position = Duration.zero;

  Duration _duration = Duration.zero;

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _duration = widget.message.audioDuration;

    _setupPlayerListeners();
  }

  // ==========================================================
  // DID UPDATE
  // ==========================================================

  @override
  void didUpdateWidget(
    covariant ChatAudioPlayer oldWidget,
  ) {
    super.didUpdateWidget(
      oldWidget,
    );

    if (oldWidget.message.id ==
        widget.message.id) {
      return;
    }

    _resetForNewMessage();
  }

  // ==========================================================
  // SETUP LISTENERS
  // ==========================================================

  void _setupPlayerListeners() {
    _playerStateSubscription = _player.playerStateStream.listen(
      (
        state,
      ) {
        if (!mounted) {
          return;
        }

        final playing = state.playing;

        final completed =
            state.processingState ==
            ProcessingState.completed;

        if (completed) {
          unawaited(
            _handleCompleted(),
          );

          return;
        }

        if (_isPlaying !=
            playing) {
          setState(
            () {
              _isPlaying = playing;
            },
          );
        }
      },

      onError:
          (
            Object error,
            StackTrace stackTrace,
          ) {
            _handlePlayerError(
              error,
              stackTrace,
            );
          },
    );

    _positionSubscription = _player.positionStream.listen(
      (
        position,
      ) {
        if (!mounted) {
          return;
        }

        setState(
          () {
            _position = position;
          },
        );
      },
    );

    _durationSubscription = _player.durationStream.listen(
      (
        duration,
      ) {
        if (!mounted ||
            duration ==
                null) {
          return;
        }

        setState(
          () {
            _duration = duration;
          },
        );
      },
    );
  }

  // ==========================================================
  // RESET NEW MESSAGE
  // ==========================================================

  Future<
    void
  >
  _resetForNewMessage() async {
    try {
      await _player.stop();
    } catch (
      _
    ) {
      // Ignora.
    }

    if (!mounted) {
      return;
    }

    setState(
      () {
        _isLoading = false;

        _isReady = false;

        _hasError = false;

        _isPlaying = false;

        _position = Duration.zero;

        _duration = widget.message.audioDuration;
      },
    );
  }

  // ==========================================================
  // PLAY / PAUSE
  // ==========================================================

  Future<
    void
  >
  _togglePlayback() async {
    if (_isLoading) {
      return;
    }

    if (_hasError) {
      await _retry();

      return;
    }

    if (!_isReady) {
      final loaded = await _loadAudio();

      if (!loaded) {
        return;
      }
    }

    try {
      if (_player.playing) {
        await _player.pause();

        return;
      }

      if (_player.processingState ==
          ProcessingState.completed) {
        await _player.seek(
          Duration.zero,
        );
      }

      unawaited(
        _player.play(),
      );
    } catch (
      error,
      stackTrace
    ) {
      _handlePlayerError(
        error,
        stackTrace,
      );
    }
  }

  // ==========================================================
  // LOAD AUDIO
  // ==========================================================

  Future<
    bool
  >
  _loadAudio() async {
    if (_isReady) {
      return true;
    }

    if (!widget.message.isAudio ||
        !widget.message.hasAudio) {
      _setError();

      return false;
    }

    setState(
      () {
        _isLoading = true;

        _hasError = false;
      },
    );

    try {
      // ======================================================
      // VALIDAR STUDIO SESSION
      // ======================================================

      if (!widget.message.belongsToProject(
        widget.controller.projectId,
      )) {
        _setError();

        return false;
      }

      // ======================================================
      // AUDIO PATH
      // ======================================================

      final audioPath = widget.message.audioPath?.trim();

      if (audioPath ==
              null ||
          audioPath.isEmpty) {
        _setError();

        return false;
      }

      // ======================================================
      // URL ASSINADA
      // ======================================================

      final url = await _supabase.storage
          .from(
            _audioBucket,
          )
          .createSignedUrl(
            audioPath,
            3600,
          );

      if (!mounted) {
        return false;
      }

      if (url.trim().isEmpty) {
        _setError();

        return false;
      }

      final detectedDuration = await _player.setUrl(
        url,
      );

      if (!mounted) {
        return false;
      }

      setState(
        () {
          _isLoading = false;

          _isReady = true;

          _hasError = false;

          if (detectedDuration !=
              null) {
            _duration = detectedDuration;
          }
        },
      );

      return true;
    } on PlayerException catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[CHAT AUDIO PLAYER] '
        'Erro just_audio: '
        '${error.code} '
        '${error.message}',
      );

      _handlePlayerError(
        error,
        stackTrace,
      );

      return false;
    } on PlayerInterruptedException catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[CHAT AUDIO PLAYER] '
        'Carregamento interrompido: '
        '${error.message}',
      );

      _handlePlayerError(
        error,
        stackTrace,
      );

      return false;
    } catch (
      error,
      stackTrace
    ) {
      _handlePlayerError(
        error,
        stackTrace,
      );

      return false;
    }
  }

  // ==========================================================
  // COMPLETED
  // ==========================================================

  Future<
    void
  >
  _handleCompleted() async {
    try {
      await _player.pause();

      await _player.seek(
        Duration.zero,
      );
    } catch (
      _
    ) {
      // Ignora.
    }

    if (!mounted) {
      return;
    }

    setState(
      () {
        _isPlaying = false;

        _position = Duration.zero;
      },
    );
  }

  // ==========================================================
  // SEEK
  // ==========================================================

  Future<
    void
  >
  _seek(
    double value,
  ) async {
    if (!_isReady ||
        _duration.inMilliseconds <=
            0) {
      return;
    }

    final milliseconds = value.round().clamp(
      0,
      _duration.inMilliseconds,
    );

    try {
      await _player.seek(
        Duration(
          milliseconds: milliseconds,
        ),
      );
    } catch (
      error,
      stackTrace
    ) {
      _handlePlayerError(
        error,
        stackTrace,
      );
    }
  }

  // ==========================================================
  // RETRY
  // ==========================================================

  Future<
    void
  >
  _retry() async {
    try {
      await _player.stop();
    } catch (
      _
    ) {
      // Ignora.
    }

    if (!mounted) {
      return;
    }

    setState(
      () {
        _hasError = false;

        _isReady = false;

        _isPlaying = false;

        _position = Duration.zero;
      },
    );

    await _togglePlayback();
  }

  // ==========================================================
  // ERROR
  // ==========================================================

  void _handlePlayerError(
    Object error,
    StackTrace stackTrace,
  ) {
    debugPrint(
      '[CHAT AUDIO PLAYER] '
      'Erro: '
      '$error',
    );

    debugPrint(
      '[CHAT AUDIO PLAYER] '
      'StackTrace: '
      '$stackTrace',
    );

    if (!mounted) {
      return;
    }

    _setError();
  }

  void _setError() {
    if (!mounted) {
      return;
    }

    setState(
      () {
        _isLoading = false;

        _isReady = false;

        _isPlaying = false;

        _hasError = true;
      },
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final maxPosition =
        _duration.inMilliseconds >
            0
        ? _duration.inMilliseconds.toDouble()
        : 1.0;

    final currentPosition = _position.inMilliseconds
        .clamp(
          0,
          maxPosition.toInt(),
        )
        .toDouble();

    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: 190,
        maxWidth: 280,
      ),

      child: Column(
        mainAxisSize: MainAxisSize.min,

        children: [
          Row(
            children: [
              // ================================================
              // PLAY
              // ================================================
              _buildPlayButton(),

              const SizedBox(
                width: 8,
              ),

              // ================================================
              // SEEK + TEMPO
              // ================================================
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,

                  children: [
                    SliderTheme(
                      data:
                          SliderTheme.of(
                            context,
                          ).copyWith(
                            trackHeight: 2,

                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 5,
                            ),

                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 11,
                            ),
                          ),

                      child: Slider(
                        min: 0,

                        max: maxPosition,

                        value: currentPosition,

                        onChanged: !_isReady
                            ? null
                            : (
                                value,
                              ) {
                                unawaited(
                                  _seek(
                                    value,
                                  ),
                                );
                              },

                        activeColor: Colors.white,

                        inactiveColor: Colors.white.withValues(
                          alpha: 0.20,
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                      ),

                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,

                        children: [
                          Text(
                            _formatDuration(
                              _position,
                            ),
                            style: _timeStyle,
                          ),

                          Text(
                            _formatDuration(
                              _duration,
                            ),
                            style: _timeStyle,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ====================================================
          // ERRO
          // ====================================================
          if (_hasError) ...[
            const SizedBox(
              height: 4,
            ),

            Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,

                  color: Colors.redAccent,

                  size: 13,
                ),

                const SizedBox(
                  width: 5,
                ),

                Expanded(
                  child: Text(
                    'Áudio indisponível. Toque para tentar novamente.',

                    style: TextStyle(
                      color: Colors.white.withValues(
                        alpha: 0.55,
                      ),

                      fontSize: 9,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================================
  // PLAY BUTTON
  // ==========================================================

  Widget _buildPlayButton() {
    return Material(
      color: Colors.white.withValues(
        alpha: 0.12,
      ),

      shape: const CircleBorder(),

      child: InkWell(
        onTap: _togglePlayback,

        customBorder: const CircleBorder(),

        child: SizedBox(
          width: 40,

          height: 40,

          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 17,

                    height: 17,

                    child: CircularProgressIndicator(
                      strokeWidth: 2,

                      color: Colors.white,
                    ),
                  )
                : Icon(
                    _hasError
                        ? Icons.refresh_rounded
                        : _isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,

                    color: _hasError
                        ? Colors.redAccent
                        : Colors.white,

                    size: 23,
                  ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // TIME STYLE
  // ==========================================================

  TextStyle get _timeStyle {
    return TextStyle(
      color: Colors.white.withValues(
        alpha: 0.52,
      ),

      fontSize: 9,

      fontWeight: FontWeight.w500,
    );
  }

  // ==========================================================
  // FORMAT DURATION
  // ==========================================================

  String _formatDuration(
    Duration value,
  ) {
    final totalSeconds =
        value.inSeconds <
            0
        ? 0
        : value.inSeconds;

    final hours =
        totalSeconds ~/
        3600;

    final minutes =
        (totalSeconds %
            3600) ~/
        60;

    final seconds =
        totalSeconds %
        60;

    if (hours >
        0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    unawaited(
      _playerStateSubscription?.cancel(),
    );

    unawaited(
      _positionSubscription?.cancel(),
    );

    unawaited(
      _durationSubscription?.cancel(),
    );

    unawaited(
      _player.dispose(),
    );

    super.dispose();
  }
}
