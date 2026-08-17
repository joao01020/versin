import 'package:flutter/material.dart';

import '../controllers/project_call_controller.dart';
import '../data/models/call_participant_model.dart';
import '../data/models/project_call_model.dart';

import 'widgets/call_controls.dart';
import 'widgets/call_participant_tile.dart';
import 'widgets/call_status_badge.dart';

// ============================================================
// ACTIVE CALL VIEW
// ============================================================
//
// Tela responsável pela chamada em andamento.
//
// Responsabilidades:
//
// - mostrar informações da chamada;
// - mostrar status;
// - mostrar participantes;
// - suportar chamada híbrida;
// - mostrar controles locais;
// - encerrar a chamada.
//
// IMPORTANTE:
//
// Este arquivo NÃO implementa:
//
// - WebRTC;
// - RTCPeerConnection;
// - RTCVideoRenderer;
// - SDP;
// - ICE;
// - captura de microfone;
// - captura de câmera.
//
// Essas responsabilidades serão ligadas posteriormente através
// dos services da camada de chamada.
//
// ============================================================

class ActiveCallView
    extends
        StatefulWidget {
  // ==========================================================
  // PROJECT
  // ==========================================================

  final String projectId;

  // ==========================================================
  // CONTROLLER
  // ==========================================================

  final ProjectCallController controller;

  // ==========================================================
  // CALL
  // ==========================================================

  final ProjectCallModel call;

  // ==========================================================
  // PARTICIPANTS
  // ==========================================================

  final List<
    CallParticipantModel
  >
  participants;

  // ==========================================================
  // VIDEO SURFACES
  // ==========================================================
  //
  // Chave:
  // userId
  //
  // Valor:
  // Widget responsável pela superfície real do vídeo.
  //
  // Exemplo futuro:
  //
  // {
  //   userId: RTCVideoView(renderer),
  // }
  //
  // ==========================================================

  final Map<
    String,
    Widget
  >
  videoSurfaces;

  // ==========================================================
  // LOCAL MEDIA STATE
  // ==========================================================

  final bool microphoneEnabled;

  final bool cameraEnabled;

  final bool videoAllowed;

  final bool speakerEnabled;

  final bool canSwitchCamera;

  // ==========================================================
  // CALLBACKS
  // ==========================================================

  final VoidCallback? onToggleMicrophone;

  final VoidCallback? onToggleCamera;

  final VoidCallback? onRequestVideo;

  final VoidCallback? onSwitchCamera;

  final VoidCallback? onToggleSpeaker;

  // ==========================================================
  // CONSTRUCTOR
  // ==========================================================

  const ActiveCallView({
    super.key,
    required this.projectId,
    required this.controller,
    required this.call,
    required this.participants,
    this.videoSurfaces =
        const <
          String,
          Widget
        >{},
    this.microphoneEnabled = true,
    this.cameraEnabled = false,
    this.videoAllowed = false,
    this.speakerEnabled = true,
    this.canSwitchCamera = true,
    this.onToggleMicrophone,
    this.onToggleCamera,
    this.onRequestVideo,
    this.onSwitchCamera,
    this.onToggleSpeaker,
  });

  // ==========================================================
  // STATE
  // ==========================================================

  @override
  State<
    ActiveCallView
  >
  createState() => _ActiveCallViewState();
}

// ============================================================
// ACTIVE CALL VIEW STATE
// ============================================================

class _ActiveCallViewState
    extends
        State<
          ActiveCallView
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

  static const Color _green = Color(
    0xFF34D399,
  );

  // ==========================================================
  // END CALL
  // ==========================================================

  Future<
    void
  >
  _endCall() async {
    if (widget.controller.isProcessing) {
      return;
    }

    final success = await widget.controller.endCall();

    if (!mounted ||
        !success) {
      return;
    }

    Navigator.of(
      context,
    ).maybePop();
  }

  // ==========================================================
  // MINIMIZE
  // ==========================================================

  void _minimizeCall() {
    Navigator.of(
      context,
    ).maybePop();
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: _background,

      body: SafeArea(
        child: Column(
          children: [
            // ================================================
            // HEADER
            // ================================================
            _buildHeader(),

            // ================================================
            // DIVIDER
            // ================================================
            _buildDivider(),

            // ================================================
            // PARTICIPANTS
            // ================================================
            Expanded(
              child: _buildParticipants(),
            ),

            // ================================================
            // CONTROLS
            // ================================================
            _buildControls(),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // HEADER
  // ==========================================================

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        12,
        10,
        18,
        10,
      ),

      child: Row(
        children: [
          // ================================================
          // MINIMIZE
          // ================================================
          IconButton(
            tooltip: 'Minimizar chamada',

            onPressed: _minimizeCall,

            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,

              color: Colors.white70,

              size: 26,
            ),
          ),

          const SizedBox(
            width: 2,
          ),

          // ================================================
          // CALL INFO
          // ================================================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                const Text(
                  'Studio Call',

                  maxLines: 1,

                  overflow: TextOverflow.ellipsis,

                  style: TextStyle(
                    color: Colors.white,

                    fontSize: 15,

                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Row(
                  children: [
                    // ========================================
                    // PROJECT HASH
                    // ========================================
                    Flexible(
                      child: Text(
                        '#$_projectHash',

                        maxLines: 1,

                        overflow: TextOverflow.ellipsis,

                        style: const TextStyle(
                          color: Colors.white30,

                          fontSize: 9,

                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    // ========================================
                    // PARTICIPANTS COUNT
                    // ========================================
                    if (widget.participants.isNotEmpty) ...[
                      const SizedBox(
                        width: 8,
                      ),

                      Container(
                        width: 3,

                        height: 3,

                        decoration: const BoxDecoration(
                          color: Colors.white24,

                          shape: BoxShape.circle,
                        ),
                      ),

                      const SizedBox(
                        width: 8,
                      ),

                      Text(
                        _participantsLabel,

                        style: const TextStyle(
                          color: Colors.white30,

                          fontSize: 9,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(
            width: 10,
          ),

          // ================================================
          // STATUS
          // ================================================
          CallStatusBadge(
            status: widget.call.status,
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // DIVIDER
  // ==========================================================

  Widget _buildDivider() {
    return Container(
      height: 1,

      margin: const EdgeInsets.symmetric(
        horizontal: 18,
      ),

      color: Colors.white.withValues(
        alpha: 0.04,
      ),
    );
  }

  // ==========================================================
  // CONTROLS
  // ==========================================================

  Widget _buildControls() {
    return ListenableBuilder(
      listenable: widget.controller,

      builder:
          (
            context,
            _,
          ) {
            return CallControls(
              microphoneEnabled: widget.microphoneEnabled,

              cameraEnabled: widget.cameraEnabled,

              videoAllowed: widget.videoAllowed,

              speakerEnabled: widget.speakerEnabled,

              canSwitchCamera: widget.canSwitchCamera,

              isProcessing: widget.controller.isProcessing,

              onToggleMicrophone: widget.onToggleMicrophone,

              onToggleCamera: widget.onToggleCamera,

              onRequestVideo: widget.onRequestVideo,

              onSwitchCamera: widget.onSwitchCamera,

              onToggleSpeaker: widget.onToggleSpeaker,

              onEndCall: _endCall,
            );
          },
    );
  }

  // ==========================================================
  // PARTICIPANTS
  // ==========================================================

  Widget _buildParticipants() {
    if (widget.participants.isEmpty) {
      return _buildEmptyParticipants();
    }

    if (_hasRenderableVideo) {
      return _buildHybridParticipants();
    }

    return _buildAudioParticipants();
  }

  // ==========================================================
  // HAS RENDERABLE VIDEO
  // ==========================================================

  bool get _hasRenderableVideo {
    for (final participant in widget.participants) {
      if (!participant.hasVideo) {
        continue;
      }

      if (widget.videoSurfaces.containsKey(
        participant.userId,
      )) {
        return true;
      }
    }

    return false;
  }

  // ==========================================================
  // AUDIO PARTICIPANTS
  // ==========================================================

  Widget _buildAudioParticipants() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        18,
        18,
        18,
        24,
      ),

      itemCount: widget.participants.length,

      separatorBuilder:
          (
            context,
            index,
          ) {
            return const SizedBox(
              height: 10,
            );
          },

      itemBuilder:
          (
            context,
            index,
          ) {
            final participant = widget.participants[index];

            return CallParticipantTile(
              participant: participant,

              videoSurface: widget.videoSurfaces[participant.userId],

              compactAudio: false,
            );
          },
    );
  }

  // ==========================================================
  // HYBRID PARTICIPANTS
  // ==========================================================
  //
  // Uma mesma chamada pode ter:
  //
  // A → vídeo
  // B → áudio
  // C → vídeo
  // D → áudio
  //
  // CallParticipantTile decide individualmente como cada
  // participante será renderizado.
  //
  // ==========================================================

  Widget _buildHybridParticipants() {
    return LayoutBuilder(
      builder:
          (
            context,
            constraints,
          ) {
            final columns = _calculateColumns(
              constraints.maxWidth,
            );

            return GridView.builder(
              padding: const EdgeInsets.fromLTRB(
                14,
                14,
                14,
                24,
              ),

              itemCount: widget.participants.length,

              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,

                crossAxisSpacing: 10,

                mainAxisSpacing: 10,

                childAspectRatio: _calculateGridAspectRatio(
                  columns,
                ),
              ),

              itemBuilder:
                  (
                    context,
                    index,
                  ) {
                    final participant = widget.participants[index];

                    return CallParticipantTile(
                      participant: participant,

                      videoSurface: widget.videoSurfaces[participant.userId],

                      compactAudio: true,

                      videoAspectRatio: _calculateVideoAspectRatio(
                        columns,
                      ),
                    );
                  },
            );
          },
    );
  }

  // ==========================================================
  // GRID COLUMNS
  // ==========================================================

  int _calculateColumns(
    double width,
  ) {
    if (width >=
        1100) {
      return 4;
    }

    if (width >=
        820) {
      return 3;
    }

    if (width >=
        520) {
      return 2;
    }

    return 1;
  }

  // ==========================================================
  // GRID ASPECT RATIO
  // ==========================================================

  double _calculateGridAspectRatio(
    int columns,
  ) {
    switch (columns) {
      case 1:
        return 1.55;

      case 2:
        return 0.95;

      case 3:
      case 4:
        return 1.0;

      default:
        return 1.0;
    }
  }

  // ==========================================================
  // VIDEO ASPECT RATIO
  // ==========================================================

  double _calculateVideoAspectRatio(
    int columns,
  ) {
    if (columns ==
        1) {
      return 16 /
          9;
    }

    return 3 /
        4;
  }

  // ==========================================================
  // EMPTY PARTICIPANTS
  // ==========================================================

  Widget _buildEmptyParticipants() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(
          24,
        ),

        child: Container(
          width: 360,

          padding: const EdgeInsets.all(
            26,
          ),

          decoration: BoxDecoration(
            color: _surface,

            borderRadius: BorderRadius.circular(
              24,
            ),

            border: Border.all(
              color: _purple.withValues(
                alpha: 0.12,
              ),
            ),

            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: 0.15,
                ),

                blurRadius: 24,

                offset: const Offset(
                  0,
                  8,
                ),
              ),
            ],
          ),

          child: const Column(
            mainAxisSize: MainAxisSize.min,

            children: [
              // ==============================================
              // ICON
              // ==============================================
              _WaitingParticipantsIcon(),

              SizedBox(
                height: 16,
              ),

              // ==============================================
              // TITLE
              // ==============================================
              Text(
                'Aguardando participantes',

                textAlign: TextAlign.center,

                style: TextStyle(
                  color: Colors.white,

                  fontSize: 14,

                  fontWeight: FontWeight.w700,
                ),
              ),

              SizedBox(
                height: 7,
              ),

              // ==============================================
              // DESCRIPTION
              // ==============================================
              Text(
                'Os membros conectados à Studio Session aparecerão aqui.',

                textAlign: TextAlign.center,

                style: TextStyle(
                  color: Colors.white38,

                  fontSize: 10,

                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // PROJECT HASH
  // ==========================================================

  String get _projectHash {
    final normalized = widget.projectId.trim();

    if (normalized.isEmpty) {
      return '--------';
    }

    if (normalized.length <=
        8) {
      return normalized.toUpperCase();
    }

    return normalized
        .substring(
          0,
          8,
        )
        .toUpperCase();
  }

  // ==========================================================
  // PARTICIPANTS LABEL
  // ==========================================================

  String get _participantsLabel {
    final count = widget.participants.length;

    if (count ==
        1) {
      return '1 participante';
    }

    return '$count participantes';
  }
}

// ============================================================
// WAITING PARTICIPANTS ICON
// ============================================================

class _WaitingParticipantsIcon
    extends
        StatelessWidget {
  const _WaitingParticipantsIcon();

  static const Color _purple = Color(
    0xFF8B5CF6,
  );

  static const Color _green = Color(
    0xFF34D399,
  );

  @override
  Widget build(
    BuildContext context,
  ) {
    return Stack(
      clipBehavior: Clip.none,

      children: [
        // ====================================================
        // MAIN CIRCLE
        // ====================================================
        Container(
          width: 64,

          height: 64,

          decoration: BoxDecoration(
            color: _purple.withValues(
              alpha: 0.10,
            ),

            shape: BoxShape.circle,

            border: Border.all(
              color: _purple.withValues(
                alpha: 0.18,
              ),
            ),
          ),

          child: const Icon(
            Icons.groups_rounded,

            color: _purple,

            size: 28,
          ),
        ),

        // ====================================================
        // ONLINE DOT
        // ====================================================
        Positioned(
          right: 1,

          bottom: 3,

          child: Container(
            width: 15,

            height: 15,

            decoration: BoxDecoration(
              color: _green,

              shape: BoxShape.circle,

              border: Border.all(
                color: Color(
                  0xFF111116,
                ),

                width: 3,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
