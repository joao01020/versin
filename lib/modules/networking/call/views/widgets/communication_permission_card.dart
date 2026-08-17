import 'package:flutter/material.dart';

import '../../data/models/communication_permission_model.dart';

// ============================================================
// COMMUNICATION PERMISSION CARD
// ============================================================
//
// Mostra as capacidades liberadas para um participante:
//
// Áudio
// Vídeo
//
// Pode também oferecer:
//
// "Solicitar vídeo"
//
// ============================================================

class CommunicationPermissionCard
    extends
        StatelessWidget {
  static const Color _surface = Color(
    0xFF111116,
  );

  static const Color _purple = Color(
    0xFF8B5CF6,
  );

  static const Color _green = Color(
    0xFF34D399,
  );

  static const Color _orange = Color(
    0xFFF59E0B,
  );

  final CommunicationPermissionModel permission;

  final String? displayName;

  final String? username;

  final VoidCallback? onRequestVideo;

  final bool requestInProgress;

  const CommunicationPermissionCard({
    super.key,
    required this.permission,
    this.displayName,
    this.username,
    this.onRequestVideo,
    this.requestInProgress = false,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(
        16,
      ),

      decoration: BoxDecoration(
        color: _surface,

        borderRadius: BorderRadius.circular(
          20,
        ),

        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.05,
          ),
        ),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          // ================================================
          // HEADER
          // ================================================
          if (_hasIdentity) ...[
            Row(
              children: [
                Container(
                  width: 38,

                  height: 38,

                  alignment: Alignment.center,

                  decoration: BoxDecoration(
                    color: _purple.withValues(
                      alpha: 0.12,
                    ),

                    shape: BoxShape.circle,
                  ),

                  child: Text(
                    _initial,

                    style: const TextStyle(
                      color: _purple,

                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),

                const SizedBox(
                  width: 11,
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      if (_name.isNotEmpty)
                        Text(
                          _name,

                          maxLines: 1,

                          overflow: TextOverflow.ellipsis,

                          style: const TextStyle(
                            color: Colors.white,

                            fontSize: 13,

                            fontWeight: FontWeight.w700,
                          ),
                        ),

                      if (_usernameLabel.isNotEmpty)
                        Text(
                          _usernameLabel,

                          style: const TextStyle(
                            color: Colors.white38,

                            fontSize: 9,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 16,
            ),
          ],

          // ================================================
          // ACCESS
          // ================================================
          const Text(
            'COMUNICAÇÃO',

            style: TextStyle(
              color: Colors.white30,

              fontSize: 9,

              fontWeight: FontWeight.w700,

              letterSpacing: 1,
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          _buildPermissionRow(
            icon: Icons.call_rounded,

            title: 'Áudio',

            description: permission.audioAllowed
                ? 'Chamadas de voz liberadas'
                : 'Áudio indisponível',

            allowed: permission.audioAllowed,
          ),

          const SizedBox(
            height: 8,
          ),

          _buildPermissionRow(
            icon: Icons.videocam_rounded,

            title: 'Vídeo',

            description: permission.videoAllowed
                ? 'Vídeo liberado por consentimento'
                : 'Requer consentimento',

            allowed: permission.videoAllowed,
          ),

          // ================================================
          // REQUEST VIDEO
          // ================================================
          if (!permission.videoAllowed &&
              onRequestVideo !=
                  null) ...[
            const SizedBox(
              height: 15,
            ),

            SizedBox(
              width: double.infinity,

              child: OutlinedButton.icon(
                onPressed: requestInProgress
                    ? null
                    : onRequestVideo,

                icon: requestInProgress
                    ? const SizedBox(
                        width: 15,

                        height: 15,

                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.lock_open_rounded,

                        size: 16,
                      ),

                label: Text(
                  requestInProgress
                      ? 'Enviando...'
                      : 'Solicitar vídeo',
                ),

                style: OutlinedButton.styleFrom(
                  foregroundColor: _purple,

                  side: BorderSide(
                    color: _purple.withValues(
                      alpha: 0.35,
                    ),
                  ),

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      13,
                    ),
                  ),

                  textStyle: const TextStyle(
                    fontSize: 11,

                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================================
  // ROW
  // ==========================================================

  Widget _buildPermissionRow({
    required IconData icon,
    required String title,
    required String description,
    required bool allowed,
  }) {
    final color = allowed
        ? _green
        : _orange;

    return Container(
      padding: const EdgeInsets.all(
        11,
      ),

      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.055,
        ),

        borderRadius: BorderRadius.circular(
          14,
        ),
      ),

      child: Row(
        children: [
          Container(
            width: 35,

            height: 35,

            decoration: BoxDecoration(
              color: color.withValues(
                alpha: 0.10,
              ),

              borderRadius: BorderRadius.circular(
                11,
              ),
            ),

            child: Icon(
              icon,

              color: color,

              size: 17,
            ),
          ),

          const SizedBox(
            width: 10,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  title,

                  style: const TextStyle(
                    color: Colors.white,

                    fontSize: 11,

                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(
                  height: 2,
                ),

                Text(
                  description,

                  style: const TextStyle(
                    color: Colors.white38,

                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),

          Icon(
            allowed
                ? Icons.check_circle_rounded
                : Icons.lock_rounded,

            color: color,

            size: 18,
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // IDENTIDADE
  // ==========================================================

  bool get _hasIdentity =>
      _name.isNotEmpty ||
      _usernameLabel.isNotEmpty;

  String get _name =>
      displayName?.trim() ??
      '';

  String get _usernameLabel {
    final value = username?.trim();

    if (value ==
            null ||
        value.isEmpty) {
      return '';
    }

    return '@${value.replaceFirst(RegExp(r'^@+'), '')}';
  }

  String get _initial {
    final value = _name.isNotEmpty
        ? _name
        : _usernameLabel;

    if (value.isEmpty) {
      return '?';
    }

    final cleaned = value.replaceFirst(
      '@',
      '',
    );

    if (cleaned.isEmpty) {
      return '?';
    }

    return cleaned
        .substring(
          0,
          1,
        )
        .toUpperCase();
  }
}
