import 'package:flutter/material.dart';

import '../../data/models/call_participant_model.dart';

// ============================================================
// VIDEO PARTICIPANT TILE
// ============================================================
//
// Representa visualmente um participante que está utilizando
// vídeo dentro de uma chamada.
//
// Este widget NÃO conhece WebRTC diretamente.
//
// A superfície de vídeo é recebida externamente:
//
// RTCVideoView(renderer)
//
//            ↓
//
// videoSurface
//
// Dessa forma mantemos a camada visual desacoplada da
// infraestrutura de comunicação.
//
// ============================================================

class VideoParticipantTile extends StatelessWidget {
  // ==========================================================
  // COLORS
  // ==========================================================

  static const Color _background = Color(0xFF111116);

  static const Color _purple = Color(0xFF8B5CF6);

  static const Color _green = Color(0xFF34D399);

  static const Color _red = Color(0xFFEF4444);

  // ==========================================================
  // PARTICIPANTE
  // ==========================================================

  final CallParticipantModel participant;

  // ==========================================================
  // VIDEO
  // ==========================================================

  final Widget videoSurface;

  // ==========================================================
  // CALLBACK
  // ==========================================================

  final VoidCallback? onTap;

  // ==========================================================
  // ASPECT RATIO
  // ==========================================================

  final double aspectRatio;

  // ==========================================================
  // CONSTRUCTOR
  // ==========================================================

  const VideoParticipantTile({
    super.key,
    required this.participant,
    required this.videoSurface,
    this.onTap,
    this.aspectRatio = 16 / 9,
  });

  // ==========================================================
  // MUTED
  // ==========================================================
  //
  // Não armazenamos "isMuted" separadamente.
  //
  // O estado real já existe em:
  //
  // microphoneEnabled
  //
  // Portanto:
  //
  // microphoneEnabled = false
  // → muted = true
  //
  // ==========================================================

  bool get _isMuted => !participant.microphoneEnabled;

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,

      child: InkWell(
        onTap: onTap,

        borderRadius: BorderRadius.circular(20),

        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),

          clipBehavior: Clip.antiAlias,

          decoration: BoxDecoration(
            color: _background,

            borderRadius: BorderRadius.circular(20),

            border: Border.all(
              color: _borderColor,

              width: participant.isSpeaking ? 2 : 1,
            ),

            boxShadow: participant.isSpeaking
                ? [
                    BoxShadow(
                      color: _green.withValues(alpha: 0.14),

                      blurRadius: 20,
                    ),
                  ]
                : null,
          ),

          child: AspectRatio(
            aspectRatio: aspectRatio,

            child: Stack(
              fit: StackFit.expand,

              children: [
                // ============================================
                // VIDEO SURFACE
                // ============================================
                ColoredBox(color: _background, child: videoSurface),

                // ============================================
                // GRADIENT INFERIOR
                // ============================================
                const Positioned(
                  left: 0,

                  right: 0,

                  bottom: 0,

                  child: IgnorePointer(child: _VideoBottomGradient()),
                ),

                // ============================================
                // SPEAKING BADGE
                // ============================================
                if (participant.isSpeaking)
                  Positioned(top: 10, left: 10, child: _buildSpeakingBadge()),

                // ============================================
                // MICROPHONE STATUS
                // ============================================
                Positioned(top: 10, right: 10, child: _buildMicrophoneStatus()),

                // ============================================
                // PARTICIPANT INFO
                // ============================================
                Positioned(
                  left: 12,

                  right: 12,

                  bottom: 10,

                  child: _ParticipantOverlay(participant: participant),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // BORDER COLOR
  // ==========================================================

  Color get _borderColor {
    if (participant.isSpeaking) {
      return _green;
    }

    if (participant.isLocalUser) {
      return _purple.withValues(alpha: 0.35);
    }

    return Colors.white.withValues(alpha: 0.06);
  }

  // ==========================================================
  // MICROPHONE STATUS
  // ==========================================================

  Widget _buildMicrophoneStatus() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),

      width: 32,

      height: 32,

      decoration: BoxDecoration(
        color: _isMuted
            ? _red.withValues(alpha: 0.90)
            : Colors.black.withValues(alpha: 0.52),

        borderRadius: BorderRadius.circular(10),

        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),

      child: Icon(
        _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,

        color: Colors.white,

        size: 16,
      ),
    );
  }

  // ==========================================================
  // SPEAKING BADGE
  // ==========================================================

  Widget _buildSpeakingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),

      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),

        borderRadius: BorderRadius.circular(20),

        border: Border.all(color: _green.withValues(alpha: 0.45)),
      ),

      child: const Row(
        mainAxisSize: MainAxisSize.min,

        children: [
          Icon(Icons.graphic_eq_rounded, color: _green, size: 14),

          SizedBox(width: 4),

          Text(
            'Falando',

            style: TextStyle(
              color: _green,

              fontSize: 8,

              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// VIDEO BOTTOM GRADIENT
// ============================================================

class _VideoBottomGradient extends StatelessWidget {
  const _VideoBottomGradient();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,

      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,

          end: Alignment.bottomCenter,

          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.78)],
        ),
      ),
    );
  }
}

// ============================================================
// PARTICIPANT OVERLAY
// ============================================================

class _ParticipantOverlay extends StatelessWidget {
  // ==========================================================
  // COLORS
  // ==========================================================

  static const Color _purple = Color(0xFF8B5CF6);

  static const Color _green = Color(0xFF34D399);

  // ==========================================================
  // PARTICIPANT
  // ==========================================================

  final CallParticipantModel participant;

  // ==========================================================
  // CONSTRUCTOR
  // ==========================================================

  const _ParticipantOverlay({required this.participant});

  // ==========================================================
  // MUTED
  // ==========================================================

  bool get _isMuted => !participant.microphoneEnabled;

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,

      children: [
        // ====================================================
        // PARTICIPANT INFO
        // ====================================================
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              // ==============================================
              // NAME
              // ==============================================
              Row(
                children: [
                  Flexible(
                    child: Text(
                      _participantName,

                      maxLines: 1,

                      overflow: TextOverflow.ellipsis,

                      style: const TextStyle(
                        color: Colors.white,

                        fontSize: 12,

                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  // ==========================================
                  // LOCAL USER
                  // ==========================================
                  if (participant.isLocalUser) ...[
                    const SizedBox(width: 6),

                    _buildLocalBadge(),
                  ],
                ],
              ),

              // ==============================================
              // USERNAME
              // ==============================================
              if (_usernameLabel.isNotEmpty) ...[
                const SizedBox(height: 2),

                Text(
                  _usernameLabel,

                  maxLines: 1,

                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(color: Colors.white54, fontSize: 8),
                ),
              ],

              // ==============================================
              // CONNECTION
              // ==============================================
              const SizedBox(height: 4),

              _buildConnectionStatus(),
            ],
          ),
        ),

        // ====================================================
        // MICROPHONE
        // ====================================================
        const SizedBox(width: 8),

        Icon(
          _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,

          color: _isMuted ? Colors.white54 : Colors.white,

          size: 15,
        ),
      ],
    );
  }

  // ==========================================================
  // CONNECTION STATUS
  // ==========================================================

  Widget _buildConnectionStatus() {
    return Row(
      mainAxisSize: MainAxisSize.min,

      children: [
        Container(
          width: 5,

          height: 5,

          decoration: BoxDecoration(
            color: participant.connected ? _green : Colors.white30,

            shape: BoxShape.circle,
          ),
        ),

        const SizedBox(width: 4),

        Text(
          participant.connected ? 'Conectado' : 'Conectando',

          style: TextStyle(
            color: participant.connected ? _green : Colors.white38,

            fontSize: 7,
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // PARTICIPANT NAME
  // ==========================================================

  String get _participantName {
    final displayName = participant.displayName.trim();

    if (displayName.isNotEmpty) {
      return displayName;
    }

    final userId = participant.userId.trim();

    if (userId.isEmpty) {
      return 'Participante';
    }

    if (userId.length > 8) {
      return userId.substring(0, 8);
    }

    return userId;
  }

  // ==========================================================
  // USERNAME
  // ==========================================================

  String get _usernameLabel {
    final username = participant.username?.trim();

    if (username == null || username.isEmpty) {
      return '';
    }

    final normalized = username.replaceFirst(RegExp(r'^@+'), '');

    if (normalized.isEmpty) {
      return '';
    }

    return '@$normalized';
  }

  // ==========================================================
  // LOCAL BADGE
  // ==========================================================

  Widget _buildLocalBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),

      decoration: BoxDecoration(
        color: _purple.withValues(alpha: 0.90),

        borderRadius: BorderRadius.circular(20),
      ),

      child: const Text(
        'VOCÊ',

        style: TextStyle(
          color: Colors.white,

          fontSize: 7,

          fontWeight: FontWeight.w800,

          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
