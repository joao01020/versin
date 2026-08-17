import 'package:flutter/material.dart';

// ============================================================
// CALL CONTROLS
// ============================================================
//
// Barra visual de controles de uma chamada.
//
// Este widget NÃO possui lógica de:
//
// - WebRTC;
// - Supabase;
// - signaling;
// - câmera;
// - microfone.
//
// Ele recebe somente:
//
// - estado;
// - callbacks.
//
// ============================================================

class CallControls
    extends
        StatelessWidget {
  // ==========================================================
  // COLORS
  // ==========================================================

  static const Color _surface = Color(
    0xFF111116,
  );

  static const Color _purple = Color(
    0xFF8B5CF6,
  );

  static const Color _red = Color(
    0xFFEF4444,
  );

  // ==========================================================
  // STATE
  // ==========================================================

  final bool microphoneEnabled;

  final bool cameraEnabled;

  final bool videoAllowed;

  final bool speakerEnabled;

  final bool canSwitchCamera;

  final bool isProcessing;

  // ==========================================================
  // CALLBACKS
  // ==========================================================

  final VoidCallback? onToggleMicrophone;

  final VoidCallback? onToggleCamera;

  final VoidCallback? onRequestVideo;

  final VoidCallback? onSwitchCamera;

  final VoidCallback? onToggleSpeaker;

  final VoidCallback? onEndCall;

  // ==========================================================
  // CONSTRUCTOR
  // ==========================================================

  const CallControls({
    super.key,
    required this.microphoneEnabled,
    required this.cameraEnabled,
    required this.videoAllowed,
    required this.speakerEnabled,
    this.canSwitchCamera = true,
    this.isProcessing = false,
    this.onToggleMicrophone,
    this.onToggleCamera,
    this.onRequestVideo,
    this.onSwitchCamera,
    this.onToggleSpeaker,
    this.onEndCall,
  });

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return SafeArea(
      top: false,

      child: Container(
        margin: const EdgeInsets.fromLTRB(
          14,
          8,
          14,
          12,
        ),

        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 11,
        ),

        decoration: BoxDecoration(
          color: _surface.withValues(
            alpha: 0.96,
          ),

          borderRadius: BorderRadius.circular(
            24,
          ),

          border: Border.all(
            color: Colors.white.withValues(
              alpha: 0.06,
            ),
          ),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: 0.30,
              ),

              blurRadius: 24,

              offset: const Offset(
                0,
                8,
              ),
            ),
          ],
        ),

        child: Row(
          children: [
            // ==================================================
            // MICROPHONE
            // ==================================================
            _buildControl(
              icon: microphoneEnabled
                  ? Icons.mic_rounded
                  : Icons.mic_off_rounded,

              label: microphoneEnabled
                  ? 'Mic'
                  : 'Mudo',

              active: microphoneEnabled,

              onTap: isProcessing
                  ? null
                  : onToggleMicrophone,
            ),

            // ==================================================
            // VIDEO
            // ==================================================
            if (videoAllowed)
              _buildControl(
                icon: cameraEnabled
                    ? Icons.videocam_rounded
                    : Icons.videocam_off_rounded,

                label: cameraEnabled
                    ? 'Vídeo'
                    : 'Câmera',

                active: cameraEnabled,

                onTap: isProcessing
                    ? null
                    : onToggleCamera,
              )
            else
              _buildControl(
                icon: Icons.lock_outline_rounded,

                label: 'Vídeo',

                active: false,

                highlighted: true,

                onTap: isProcessing
                    ? null
                    : onRequestVideo,
              ),

            // ==================================================
            // SWITCH CAMERA
            // ==================================================
            if (videoAllowed &&
                cameraEnabled &&
                canSwitchCamera)
              _buildControl(
                icon: Icons.cameraswitch_rounded,

                label: 'Trocar',

                active: false,

                onTap: isProcessing
                    ? null
                    : onSwitchCamera,
              ),

            // ==================================================
            // SPEAKER
            // ==================================================
            _buildControl(
              icon: speakerEnabled
                  ? Icons.volume_up_rounded
                  : Icons.volume_off_rounded,

              label: 'Áudio',

              active: speakerEnabled,

              onTap: isProcessing
                  ? null
                  : onToggleSpeaker,
            ),

            // ==================================================
            // END
            // ==================================================
            _buildControl(
              icon: Icons.call_end_rounded,

              label: 'Sair',

              active: false,

              danger: true,

              onTap: isProcessing
                  ? null
                  : onEndCall,
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // CONTROL
  // ==========================================================

  Widget _buildControl({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback? onTap,
    bool danger = false,
    bool highlighted = false,
  }) {
    final Color backgroundColor;

    final Color foregroundColor;

    if (danger) {
      backgroundColor = _red;

      foregroundColor = Colors.white;
    } else if (highlighted) {
      backgroundColor = _purple.withValues(
        alpha: 0.14,
      );

      foregroundColor = _purple;
    } else if (active) {
      backgroundColor = Colors.white.withValues(
        alpha: 0.12,
      );

      foregroundColor = Colors.white;
    } else {
      backgroundColor = Colors.white.withValues(
        alpha: 0.055,
      );

      foregroundColor = Colors.white54;
    }

    return Expanded(
      child: Opacity(
        opacity:
            onTap ==
                null
            ? 0.40
            : 1,

        child: InkWell(
          onTap: onTap,

          borderRadius: BorderRadius.circular(
            16,
          ),

          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 2,
            ),

            child: Column(
              mainAxisSize: MainAxisSize.min,

              children: [
                // ============================================
                // BUTTON
                // ============================================
                AnimatedContainer(
                  duration: const Duration(
                    milliseconds: 160,
                  ),

                  width: 43,

                  height: 43,

                  decoration: BoxDecoration(
                    color: backgroundColor,

                    shape: BoxShape.circle,

                    border: highlighted
                        ? Border.all(
                            color: _purple.withValues(
                              alpha: 0.30,
                            ),
                          )
                        : null,
                  ),

                  child: Icon(
                    icon,

                    color: foregroundColor,

                    size: 19,
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),

                // ============================================
                // LABEL
                // ============================================
                Text(
                  label,

                  maxLines: 1,

                  overflow: TextOverflow.ellipsis,

                  style: TextStyle(
                    color: foregroundColor.withValues(
                      alpha: danger
                          ? 0.90
                          : 0.70,
                    ),

                    fontSize: 8,

                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
