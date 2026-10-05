import 'package:flutter/material.dart';

import 'package:versin/core/utils/network_image_url_helper.dart';

import '../../data/models/call_participant_model.dart';

// ============================================================
// AUDIO PARTICIPANT TILE
// ============================================================
//
// Representação visual de um participante sem vídeo ativo.
//
// Responsabilidade:
//
// - avatar;
// - nome;
// - username;
// - status do microfone;
// - indicador de fala;
// - identificação do usuário local.
//
// Não contém lógica de WebRTC.
//
// ============================================================

class AudioParticipantTile
    extends
        StatelessWidget {
  // ==========================================================
  // COLORS
  // ==========================================================

  static const Color _surface = Color(
    0xFF111116,
  );

  static const Color _surfaceLight = Color(
    0xFF17171E,
  );

  static const Color _purple = Color(
    0xFF8B5CF6,
  );

  static const Color _green = Color(
    0xFF34D399,
  );

  static const Color _red = Color(
    0xFFEF4444,
  );

  // ==========================================================
  // DATA
  // ==========================================================

  final CallParticipantModel participant;

  final VoidCallback? onTap;

  final bool compact;

  // ==========================================================
  // CONSTRUCTOR
  // ==========================================================

  const AudioParticipantTile({
    super.key,
    required this.participant,
    this.onTap,
    this.compact = false,
  });

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color: Colors.transparent,

      child: InkWell(
        onTap: onTap,

        borderRadius: BorderRadius.circular(
          compact
              ? 16
              : 20,
        ),

        child: AnimatedContainer(
          duration: const Duration(
            milliseconds: 180,
          ),

          padding: EdgeInsets.all(
            compact
                ? 12
                : 16,
          ),

          decoration: BoxDecoration(
            color: _surface,

            borderRadius: BorderRadius.circular(
              compact
                  ? 16
                  : 20,
            ),

            border: Border.all(
              color: participant.isSpeaking
                  ? _green.withValues(
                      alpha: 0.65,
                    )
                  : participant.isLocalUser
                  ? _purple.withValues(
                      alpha: 0.30,
                    )
                  : Colors.white.withValues(
                      alpha: 0.05,
                    ),

              width: participant.isSpeaking
                  ? 1.4
                  : 1,
            ),

            boxShadow: participant.isSpeaking
                ? [
                    BoxShadow(
                      color: _green.withValues(
                        alpha: 0.12,
                      ),

                      blurRadius: 18,
                    ),
                  ]
                : null,
          ),

          child: Row(
            children: [
              // ==============================================
              // AVATAR
              // ==============================================
              _buildAvatar(),

              SizedBox(
                width: compact
                    ? 10
                    : 13,
              ),

              // ==============================================
              // INFO
              // ==============================================
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    // ========================================
                    // NAME
                    // ========================================
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            participant.displayName,

                            maxLines: 1,

                            overflow: TextOverflow.ellipsis,

                            style: TextStyle(
                              color: Colors.white,

                              fontSize: compact
                                  ? 12
                                  : 14,

                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),

                        if (participant.isLocalUser) ...[
                          const SizedBox(
                            width: 7,
                          ),

                          _buildYouBadge(),
                        ],
                      ],
                    ),

                    // ========================================
                    // USERNAME
                    // ========================================
                    if (_usernameLabel.isNotEmpty) ...[
                      const SizedBox(
                        height: 2,
                      ),

                      Text(
                        _usernameLabel,

                        maxLines: 1,

                        overflow: TextOverflow.ellipsis,

                        style: const TextStyle(
                          color: Colors.white38,

                          fontSize: 9,
                        ),
                      ),
                    ],

                    SizedBox(
                      height: compact
                          ? 6
                          : 8,
                    ),

                    // ========================================
                    // STATUS
                    // ========================================
                    Wrap(
                      spacing: 7,

                      runSpacing: 5,

                      children: [
                        _buildAudioStatus(),

                        if (participant.isSpeaking) _buildSpeakingStatus(),
                      ],
                    ),
                  ],
                ),
              ),

              // ==============================================
              // MICROPHONE
              // ==============================================
              Container(
                width: compact
                    ? 34
                    : 38,

                height: compact
                    ? 34
                    : 38,

                decoration: BoxDecoration(
                  color: participant.microphoneEnabled
                      ? _surfaceLight
                      : _red.withValues(
                          alpha: 0.10,
                        ),

                  borderRadius: BorderRadius.circular(
                    12,
                  ),
                ),

                child: Icon(
                  participant.microphoneEnabled
                      ? Icons.mic_rounded
                      : Icons.mic_off_rounded,

                  color: participant.microphoneEnabled
                      ? Colors.white60
                      : _red,

                  size: compact
                      ? 16
                      : 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // USERNAME
  // ==========================================================

  String get _usernameLabel {
    final username = participant.username?.trim();

    if (username ==
            null ||
        username.isEmpty) {
      return '';
    }

    final normalized = username.replaceFirst(
      RegExp(
        r'^@+',
      ),
      '',
    );

    return '@$normalized';
  }

  // ==========================================================
  // AVATAR
  // ==========================================================

  Widget _buildAvatar() {
    final size = compact
        ? 44.0
        : 52.0;

    final avatarUrl = NetworkImageUrlHelper.validUrlOrNull(
      participant.avatarUrl,
    );

    return AnimatedContainer(
      duration: const Duration(
        milliseconds: 180,
      ),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: participant.isSpeaking
              ? _green
              : _purple.withValues(
                  alpha: 0.25,
                ),
          width: participant.isSpeaking
              ? 2
              : 1,
        ),
      ),
      child: ClipOval(
        child:
            avatarUrl !=
                null
            ? Image.network(
                avatarUrl,
                fit: BoxFit.cover,
                errorBuilder:
                    (
                      context,
                      error,
                      stackTrace,
                    ) {
                      return _buildInitial();
                    },
              )
            : _buildInitial(),
      ),
    );
  }

  // ==========================================================
  // INITIAL
  // ==========================================================

  Widget _buildInitial() {
    final name = participant.displayName.trim();

    final initial = name.isEmpty
        ? '?'
        : name
              .substring(
                0,
                1,
              )
              .toUpperCase();

    return Container(
      color: _purple.withValues(
        alpha: 0.12,
      ),

      alignment: Alignment.center,

      child: Text(
        initial,

        style: TextStyle(
          color: _purple,

          fontSize: compact
              ? 15
              : 18,

          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // ==========================================================
  // YOU
  // ==========================================================

  Widget _buildYouBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 2,
      ),

      decoration: BoxDecoration(
        color: _purple.withValues(
          alpha: 0.12,
        ),

        borderRadius: BorderRadius.circular(
          20,
        ),
      ),

      child: const Text(
        'VOCÊ',

        style: TextStyle(
          color: _purple,

          fontSize: 7,

          fontWeight: FontWeight.w800,

          letterSpacing: 0.6,
        ),
      ),
    );
  }

  // ==========================================================
  // AUDIO STATUS
  // ==========================================================

  Widget _buildAudioStatus() {
    final connected = participant.audioConnected;

    return Row(
      mainAxisSize: MainAxisSize.min,

      children: [
        Container(
          width: 6,

          height: 6,

          decoration: BoxDecoration(
            color: connected
                ? _green
                : Colors.white24,

            shape: BoxShape.circle,
          ),
        ),

        const SizedBox(
          width: 5,
        ),

        Text(
          connected
              ? 'Áudio conectado'
              : 'Conectando',

          style: TextStyle(
            color: connected
                ? _green
                : Colors.white30,

            fontSize: 8,

            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // SPEAKING
  // ==========================================================

  Widget _buildSpeakingStatus() {
    return const Row(
      mainAxisSize: MainAxisSize.min,

      children: [
        Icon(
          Icons.graphic_eq_rounded,
          color: _green,
          size: 13,
        ),

        SizedBox(
          width: 3,
        ),

        Text(
          'Falando',

          style: TextStyle(
            color: _green,

            fontSize: 8,

            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
