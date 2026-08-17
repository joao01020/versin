import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../controllers/project_call_controller.dart';
import '../data/models/call_participant_model.dart';
import '../data/models/project_call_model.dart';

import 'active_call_view.dart';
import 'incoming_call_view.dart';

// ============================================================
// CALL VIEW
// ============================================================
//
// Porta de entrada da funcionalidade de chamadas.
//
// Responsabilidades:
//
// - inicializar ProjectCallController;
// - observar chamadas do projeto;
// - identificar chamada recebida;
// - mostrar chamada recebida;
// - mostrar chamada ativa;
// - permitir iniciar áudio;
// - preparar fluxo de vídeo com consentimento.
//
// IMPORTANTE:
//
// Esta versão ainda NÃO executa:
//
// - WebRTC;
// - captura real de microfone;
// - captura real de câmera;
// - signaling;
// - SDP;
// - ICE.
//
// Nesta etapa estamos estabilizando:
//
// - models;
// - repositories;
// - controllers;
// - UI;
// - fluxo de estados.
//
// Depois serão conectados:
//
// CommunicationPermissionController
// CallSignalingService
// WebRtcCallService
//
// ============================================================

class CallView
    extends
        StatefulWidget {
  final String projectId;

  const CallView({
    super.key,
    required this.projectId,
  });

  @override
  State<
    CallView
  >
  createState() => _CallViewState();
}

// ============================================================
// STATE
// ============================================================

class _CallViewState
    extends
        State<
          CallView
        > {
  // ==========================================================
  // COLORS
  // ==========================================================

  static const Color _background = Color(
    0xFF08080B,
  );

  static const Color _surface = Color(
    0xFF111116,
  );

  static const Color _purple = Color(
    0xFF8B5CF6,
  );

  // ==========================================================
  // CONTROLLER
  // ==========================================================

  late final ProjectCallController _controller;

  // ==========================================================
  // PARTICIPANTS
  // ==========================================================
  //
  // Ainda é placeholder.
  //
  // Depois será alimentado pelo:
  //
  // WebRtcCallService
  // +
  // Presence / signaling
  //
  // ==========================================================

  final List<
    CallParticipantModel
  >
  _participants =
      const <
        CallParticipantModel
      >[];

  // ==========================================================
  // LOCAL MEDIA STATE
  // ==========================================================
  //
  // Ainda são estados locais da UI.
  //
  // Depois serão delegados para WebRtcCallService.
  //
  // ==========================================================

  bool _microphoneEnabled = true;

  bool _cameraEnabled = false;

  final bool _videoAllowed = false;

  bool _speakerEnabled = true;

  // ==========================================================
  // CURRENT USER
  // ==========================================================

  String? get _currentUserId {
    final userId = Supabase.instance.client.auth.currentUser?.id.trim();

    if (userId ==
            null ||
        userId.isEmpty) {
      return null;
    }

    return userId;
  }

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _controller = ProjectCallController(
      projectId: widget.projectId,
    );

    _controller.init();
  }

  // ==========================================================
  // START AUDIO
  // ==========================================================

  Future<
    void
  >
  _startAudio() async {
    final call = await _controller.startAudioCall();

    if (!mounted ||
        call ==
            null) {
      return;
    }

    setState(
      () {
        _cameraEnabled = false;
      },
    );
  }

  // ==========================================================
  // START VIDEO
  // ==========================================================

  Future<
    void
  >
  _startVideo() async {
    if (!_videoAllowed) {
      _showMessage(
        'O vídeo precisa ser liberado por consentimento.',
      );

      return;
    }

    final call = await _controller.startVideoCall();

    if (!mounted ||
        call ==
            null) {
      return;
    }

    setState(
      () {
        _cameraEnabled = true;
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
    return ListenableBuilder(
      listenable: _controller,

      builder:
          (
            context,
            _,
          ) {
            // ====================================================
            // LOADING
            // ====================================================

            if (_controller.isLoading) {
              return const Scaffold(
                backgroundColor: _background,

                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final call = _controller.activeCall;

            // ====================================================
            // ACTIVE CALL
            // ====================================================

            if (call !=
                    null &&
                call.isActive) {
              return ActiveCallView(
                projectId: widget.projectId,

                controller: _controller,

                call: call,

                participants: _participants,

                microphoneEnabled: _microphoneEnabled,

                cameraEnabled: _cameraEnabled,

                videoAllowed: _videoAllowed,

                speakerEnabled: _speakerEnabled,

                onToggleMicrophone: _toggleMicrophone,

                onToggleCamera: _toggleCamera,

                onRequestVideo: _requestVideo,

                onSwitchCamera: _switchCamera,

                onToggleSpeaker: _toggleSpeaker,
              );
            }

            // ====================================================
            // RINGING
            // ====================================================

            if (call !=
                    null &&
                call.isRinging) {
              final isIncoming = _isIncomingCall(
                call,
              );

              if (isIncoming) {
                return IncomingCallView(
                  controller: _controller,

                  call: call,

                  callerName: 'Membro da sessão',

                  onAccepted: _handleCallAccepted,

                  onRejected: _handleCallRejected,
                );
              }

              return _buildOutgoingCall(
                call,
              );
            }

            // ====================================================
            // IDLE
            // ====================================================

            return _buildIdle();
          },
    );
  }

  // ==========================================================
  // INCOMING CALL
  // ==========================================================

  bool _isIncomingCall(
    ProjectCallModel call,
  ) {
    final currentUserId = _currentUserId;

    if (currentUserId ==
        null) {
      return false;
    }

    final targetUserId = call.targetUserId?.trim();

    if (targetUserId ==
            null ||
        targetUserId.isEmpty) {
      // ======================================================
      // CHAMADA DE GRUPO
      // ======================================================
      //
      // Nesta versão ainda não tratamos convite individual
      // para chamada em grupo.
      //
      // ======================================================

      return false;
    }

    return targetUserId ==
        currentUserId;
  }

  // ==========================================================
  // ACCEPTED
  // ==========================================================

  void _handleCallAccepted() {
    if (!mounted) {
      return;
    }

    setState(
      () {},
    );
  }

  // ==========================================================
  // REJECTED
  // ==========================================================

  void _handleCallRejected() {
    if (!mounted) {
      return;
    }

    setState(
      () {},
    );
  }

  // ==========================================================
  // IDLE
  // ==========================================================

  Widget _buildIdle() {
    return Scaffold(
      backgroundColor: _background,

      appBar: AppBar(
        backgroundColor: Colors.transparent,

        surfaceTintColor: Colors.transparent,

        elevation: 0,

        title: const Text(
          'Ligar',

          style: TextStyle(
            fontSize: 16,

            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: RefreshIndicator(
        onRefresh: _controller.refresh,

        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),

          padding: const EdgeInsets.all(
            18,
          ),

          children: [
            // ================================================
            // HERO
            // ================================================
            _buildHero(),

            const SizedBox(
              height: 26,
            ),

            // ================================================
            // SECTION
            // ================================================
            const Text(
              'COMUNICAÇÃO',

              style: TextStyle(
                color: Colors.white38,

                fontSize: 10,

                fontWeight: FontWeight.w700,

                letterSpacing: 1.2,
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            // ================================================
            // AUDIO
            // ================================================
            _buildCallAction(
              icon: Icons.call_rounded,

              title: 'Áudio',

              description: 'Converse por voz com os membros da sessão.',

              enabled: true,

              onTap: _controller.isProcessing
                  ? null
                  : _startAudio,
            ),

            const SizedBox(
              height: 10,
            ),

            // ================================================
            // VIDEO
            // ================================================
            _buildCallAction(
              icon: _videoAllowed
                  ? Icons.videocam_rounded
                  : Icons.lock_rounded,

              title: 'Vídeo',

              description: _videoAllowed
                  ? 'Vídeo liberado por consentimento.'
                  : 'Requer consentimento antes da primeira chamada.',

              enabled: _videoAllowed,

              onTap: _controller.isProcessing
                  ? null
                  : _startVideo,
            ),

            // ================================================
            // VIDEO LOCK INFO
            // ================================================
            if (!_videoAllowed) ...[
              const SizedBox(
                height: 14,
              ),

              _buildVideoUnlockInfo(),
            ],

            // ================================================
            // ERROR
            // ================================================
            if (_controller.hasError) ...[
              const SizedBox(
                height: 18,
              ),

              _buildError(),
            ],
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // HERO
  // ==========================================================

  Widget _buildHero() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(
        20,
      ),

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          24,
        ),

        gradient: const LinearGradient(
          begin: Alignment.topLeft,

          end: Alignment.bottomRight,

          colors: [
            Color(
              0xFF21113E,
            ),

            _surface,
          ],
        ),

        border: Border.all(
          color: _purple.withValues(
            alpha: 0.20,
          ),
        ),
      ),

      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Icon(
            Icons.spatial_audio_off_rounded,

            color: _purple,

            size: 30,
          ),

          SizedBox(
            height: 14,
          ),

          Text(
            'Converse no seu ritmo',

            style: TextStyle(
              color: Colors.white,

              fontSize: 18,

              fontWeight: FontWeight.w700,
            ),
          ),

          SizedBox(
            height: 6,
          ),

          Text(
            'Comece por áudio. O vídeo só é liberado quando houver consentimento entre os participantes.',

            style: TextStyle(
              color: Colors.white38,

              fontSize: 11,

              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // CALL ACTION
  // ==========================================================

  Widget _buildCallAction({
    required IconData icon,
    required String title,
    required String description,
    required bool enabled,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,

      child: InkWell(
        onTap: onTap,

        borderRadius: BorderRadius.circular(
          18,
        ),

        child: Ink(
          padding: const EdgeInsets.all(
            15,
          ),

          decoration: BoxDecoration(
            color: _surface,

            borderRadius: BorderRadius.circular(
              18,
            ),

            border: Border.all(
              color: enabled
                  ? _purple.withValues(
                      alpha: 0.16,
                    )
                  : Colors.white.withValues(
                      alpha: 0.05,
                    ),
            ),
          ),

          child: Row(
            children: [
              // ==============================================
              // ICON
              // ==============================================
              Container(
                width: 44,

                height: 44,

                decoration: BoxDecoration(
                  color: enabled
                      ? _purple.withValues(
                          alpha: 0.12,
                        )
                      : Colors.white.withValues(
                          alpha: 0.04,
                        ),

                  borderRadius: BorderRadius.circular(
                    14,
                  ),
                ),

                child: Icon(
                  icon,

                  color: enabled
                      ? _purple
                      : Colors.white30,

                  size: 21,
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              // ==============================================
              // TEXT
              // ==============================================
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      title,

                      style: TextStyle(
                        color: enabled
                            ? Colors.white
                            : Colors.white38,

                        fontSize: 13,

                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(
                      height: 3,
                    ),

                    Text(
                      description,

                      style: const TextStyle(
                        color: Colors.white30,

                        fontSize: 9,

                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),

              // ==============================================
              // TRAILING
              // ==============================================
              Icon(
                enabled
                    ? Icons.chevron_right_rounded
                    : Icons.lock_outline_rounded,

                color: enabled
                    ? Colors.white24
                    : Colors.white12,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // VIDEO INFO
  // ==========================================================

  Widget _buildVideoUnlockInfo() {
    return Container(
      padding: const EdgeInsets.all(
        14,
      ),

      decoration: BoxDecoration(
        color: _purple.withValues(
          alpha: 0.06,
        ),

        borderRadius: BorderRadius.circular(
          16,
        ),
      ),

      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Icon(
            Icons.verified_user_outlined,

            color: _purple,

            size: 18,
          ),

          SizedBox(
            width: 10,
          ),

          Expanded(
            child: Text(
              'Vídeo é uma camada adicional de confiança. Um convite precisa ser aceito antes de liberar essa opção.',

              style: TextStyle(
                color: Colors.white38,

                fontSize: 10,

                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // OUTGOING
  // ==========================================================

  Widget _buildOutgoingCall(
    ProjectCallModel call,
  ) {
    return Scaffold(
      backgroundColor: _background,

      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(
              30,
            ),

            child: Column(
              mainAxisSize: MainAxisSize.min,

              children: [
                // ============================================
                // ICON
                // ============================================
                Container(
                  width: 90,

                  height: 90,

                  decoration: BoxDecoration(
                    color: _purple.withValues(
                      alpha: 0.10,
                    ),

                    shape: BoxShape.circle,
                  ),

                  child: Icon(
                    call.startedAsVideo
                        ? Icons.videocam_rounded
                        : Icons.call_rounded,

                    color: _purple,

                    size: 34,
                  ),
                ),

                const SizedBox(
                  height: 24,
                ),

                // ============================================
                // STATUS
                // ============================================
                const Text(
                  'Chamando...',

                  style: TextStyle(
                    color: Colors.white,

                    fontSize: 20,

                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                Text(
                  call.startedAsVideo
                      ? 'Chamada de vídeo'
                      : 'Chamada de áudio',

                  style: const TextStyle(
                    color: Colors.white38,

                    fontSize: 11,
                  ),
                ),

                const SizedBox(
                  height: 38,
                ),

                // ============================================
                // CANCEL
                // ============================================
                GestureDetector(
                  onTap: _controller.isProcessing
                      ? null
                      : _cancelOutgoingCall,

                  child: Container(
                    width: 62,

                    height: 62,

                    decoration: const BoxDecoration(
                      color: Colors.redAccent,

                      shape: BoxShape.circle,
                    ),

                    child: const Icon(
                      Icons.call_end_rounded,

                      color: Colors.white,

                      size: 27,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 10,
                ),

                const Text(
                  'Cancelar',

                  style: TextStyle(
                    color: Colors.white38,

                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // CANCEL OUTGOING CALL
  // ==========================================================

  Future<
    void
  >
  _cancelOutgoingCall() async {
    await _controller.endCall();
  }

  // ==========================================================
  // MICROPHONE
  // ==========================================================

  void _toggleMicrophone() {
    if (!mounted) {
      return;
    }

    setState(
      () {
        _microphoneEnabled = !_microphoneEnabled;
      },
    );
  }

  // ==========================================================
  // CAMERA
  // ==========================================================

  void _toggleCamera() {
    if (!_videoAllowed) {
      _requestVideo();

      return;
    }

    if (!mounted) {
      return;
    }

    setState(
      () {
        _cameraEnabled = !_cameraEnabled;
      },
    );
  }

  // ==========================================================
  // REQUEST VIDEO
  // ==========================================================

  void _requestVideo() {
    _showMessage(
      'O fluxo de consentimento de vídeo será conectado ao CommunicationPermissionController.',
    );
  }

  // ==========================================================
  // SWITCH CAMERA
  // ==========================================================

  void _switchCamera() {
    _showMessage(
      'Troca de câmera será ativada junto ao WebRTC.',
    );
  }

  // ==========================================================
  // SPEAKER
  // ==========================================================

  void _toggleSpeaker() {
    if (!mounted) {
      return;
    }

    setState(
      () {
        _speakerEnabled = !_speakerEnabled;
      },
    );
  }

  // ==========================================================
  // ERROR
  // ==========================================================

  Widget _buildError() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(
        13,
      ),

      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(
          alpha: 0.07,
        ),

        borderRadius: BorderRadius.circular(
          14,
        ),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Icon(
            Icons.error_outline_rounded,

            color: Colors.redAccent,

            size: 17,
          ),

          const SizedBox(
            width: 8,
          ),

          Expanded(
            child: Text(
              _controller.errorMessage ??
                  'Erro ao processar chamada.',

              style: const TextStyle(
                color: Colors.redAccent,

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
  // MESSAGE
  // ==========================================================

  void _showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: Text(
          message,
        ),
      ),
    );
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }
}
