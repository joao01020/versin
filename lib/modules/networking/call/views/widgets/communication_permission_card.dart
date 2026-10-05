import 'package:flutter/material.dart';

import '../../data/models/communication_permission_model.dart';
import '../../data/models/communication_video_invite_state_model.dart';

// ============================================================
// COMMUNICATION PERMISSION CARD
// ============================================================
//
// Mostra o estado de comunicação entre:
//
// usuário atual <-> outro usuário.
//
// ÁUDIO
// ------------------------------------------------------------
//
// O áudio NÃO faz parte de CommunicationPermissionModel.
//
// Ele é informado separadamente através de:
//
// audioAllowed
//
// VÍDEO
// ------------------------------------------------------------
//
// O vídeo depende de consentimento bilateral:
//
// usuário atual <-> outro usuário
//
// O estado do convite é fornecido por:
//
// CommunicationVideoInviteStateModel
//
// Isso permite mostrar:
//
// - vídeo liberado;
// - convite disponível;
// - cooldown após recusa;
// - bloqueio após terceira recusa.
//
// ============================================================

class CommunicationPermissionCard
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

  static const Color _green = Color(
    0xFF34D399,
  );

  static const Color _orange = Color(
    0xFFF59E0B,
  );

  static const Color _red = Color(
    0xFFEF4444,
  );

  // ==========================================================
  // PERMISSION
  // ==========================================================

  final CommunicationPermissionModel? permission;

  // ==========================================================
  // INVITE STATE
  // ==========================================================

  final CommunicationVideoInviteStateModel? inviteState;

  // ==========================================================
  // AUDIO
  // ==========================================================

  final bool audioAllowed;

  // ==========================================================
  // IDENTIDADE
  // ==========================================================

  final String? displayName;

  final String? username;

  // ==========================================================
  // REQUEST VIDEO
  // ==========================================================

  final VoidCallback? onRequestVideo;

  final bool requestInProgress;

  // ==========================================================
  // CONSTRUCTOR
  // ==========================================================

  const CommunicationPermissionCard({
    super.key,
    this.permission,
    this.inviteState,
    this.audioAllowed = true,
    this.displayName,
    this.username,
    this.onRequestVideo,
    this.requestInProgress = false,
  });

  // ==========================================================
  // BUILD
  // ==========================================================

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

                          maxLines: 1,

                          overflow: TextOverflow.ellipsis,

                          style: const TextStyle(
                            color: Colors.white38,

                            fontSize: 9,
                          ),
                        ),
                    ],
                  ),
                ),

                // ==========================================
                // VIDEO STATUS BADGE
                // ==========================================
                _buildVideoStatusBadge(),
              ],
            ),

            const SizedBox(
              height: 16,
            ),
          ],

          // ================================================
          // ACCESS TITLE
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

          // ================================================
          // AUDIO
          // ================================================
          _buildPermissionRow(
            icon: Icons.call_rounded,

            title: 'Áudio',

            description: audioAllowed
                ? 'Chamadas de voz liberadas'
                : 'Áudio indisponível',

            allowed: audioAllowed,
          ),

          const SizedBox(
            height: 8,
          ),

          // ================================================
          // VIDEO
          // ================================================
          _buildPermissionRow(
            icon: Icons.videocam_rounded,

            title: 'Vídeo',

            description: _videoDescription,

            allowed: _videoAllowed,

            blocked: _videoBlocked,
          ),

          // ================================================
          // INVITE INFORMATION
          // ================================================
          if (!_videoAllowed &&
              inviteState !=
                  null) ...[
            const SizedBox(
              height: 12,
            ),

            _buildInviteInformation(),
          ],

          // ================================================
          // REQUEST VIDEO
          // ================================================
          if (_showRequestButton) ...[
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
                      : _requestButtonLabel,
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

          // ================================================
          // COOLDOWN
          // ================================================
          if (_showCooldownMessage) ...[
            const SizedBox(
              height: 15,
            ),

            _buildCooldownMessage(),
          ],

          // ================================================
          // BLOCKED
          // ================================================
          if (_videoBlocked) ...[
            const SizedBox(
              height: 15,
            ),

            _buildBlockedMessage(),
          ],
        ],
      ),
    );
  }

  // ==========================================================
  // PERMISSION ROW
  // ==========================================================

  Widget _buildPermissionRow({
    required IconData icon,
    required String title,
    required String description,
    required bool allowed,
    bool blocked = false,
  }) {
    final Color color;

    if (allowed) {
      color = _green;
    } else if (blocked) {
      color = _red;
    } else {
      color = _orange;
    }

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
                : blocked
                ? Icons.block_rounded
                : Icons.lock_rounded,

            color: color,

            size: 18,
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // VIDEO STATUS BADGE
  // ==========================================================

  Widget _buildVideoStatusBadge() {
    final Color color;

    final String label;

    final IconData icon;

    if (_videoAllowed) {
      color = _green;

      label = 'VÍDEO';

      icon = Icons.videocam_rounded;
    } else if (_videoBlocked) {
      color = _red;

      label = 'BLOQUEADO';

      icon = Icons.block_rounded;
    } else if (_hasCooldown) {
      color = _orange;

      label = 'AGUARDANDO';

      icon = Icons.schedule_rounded;
    } else {
      color = _purple;

      label = 'ÁUDIO';

      icon = Icons.call_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),

      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.08,
        ),

        borderRadius: BorderRadius.circular(
          20,
        ),

        border: Border.all(
          color: color.withValues(
            alpha: 0.18,
          ),
        ),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,

        children: [
          Icon(
            icon,

            color: color,

            size: 11,
          ),

          const SizedBox(
            width: 5,
          ),

          Text(
            label,

            style: TextStyle(
              color: color,

              fontSize: 7,

              fontWeight: FontWeight.w800,

              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // INVITE INFORMATION
  // ==========================================================

  Widget _buildInviteInformation() {
    final state = inviteState;

    if (state ==
        null) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        Icon(
          Icons.history_rounded,

          color: Colors.white.withValues(
            alpha: 0.28,
          ),

          size: 14,
        ),

        const SizedBox(
          width: 7,
        ),

        Expanded(
          child: Text(
            _inviteInformationText,

            style: const TextStyle(
              color: Colors.white38,

              fontSize: 9,

              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // COOLDOWN MESSAGE
  // ==========================================================

  Widget _buildCooldownMessage() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(
        11,
      ),

      decoration: BoxDecoration(
        color: _orange.withValues(
          alpha: 0.055,
        ),

        borderRadius: BorderRadius.circular(
          13,
        ),

        border: Border.all(
          color: _orange.withValues(
            alpha: 0.12,
          ),
        ),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Icon(
            Icons.schedule_rounded,

            color: _orange,

            size: 16,
          ),

          const SizedBox(
            width: 8,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                const Text(
                  'Novo convite indisponível',

                  style: TextStyle(
                    color: Colors.white70,

                    fontSize: 10,

                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  'Você poderá convidar novamente em '
                  '${inviteState?.cooldownLabel ?? ''}.',

                  style: const TextStyle(
                    color: Colors.white38,

                    fontSize: 9,

                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // BLOCKED MESSAGE
  // ==========================================================

  Widget _buildBlockedMessage() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(
        11,
      ),

      decoration: BoxDecoration(
        color: _red.withValues(
          alpha: 0.055,
        ),

        borderRadius: BorderRadius.circular(
          13,
        ),

        border: Border.all(
          color: _red.withValues(
            alpha: 0.12,
          ),
        ),
      ),

      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Icon(
            Icons.block_rounded,

            color: _red,

            size: 16,
          ),

          SizedBox(
            width: 8,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  'Convites de vídeo bloqueados',

                  style: TextStyle(
                    color: Colors.white70,

                    fontSize: 10,

                    fontWeight: FontWeight.w700,
                  ),
                ),

                SizedBox(
                  height: 3,
                ),

                Text(
                  'O limite de recusas foi atingido. '
                  'Somente este usuário pode liberar uma nova tentativa.',

                  style: TextStyle(
                    color: Colors.white38,

                    fontSize: 9,

                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // VIDEO ALLOWED
  // ==========================================================

  bool get _videoAllowed =>
      permission?.videoAllowed ??
      false;

  // ==========================================================
  // VIDEO BLOCKED
  // ==========================================================

  bool get _videoBlocked =>
      !_videoAllowed &&
      (inviteState?.blockedAfterLimit ??
          false);

  // ==========================================================
  // COOLDOWN
  // ==========================================================

  bool get _hasCooldown =>
      !_videoAllowed &&
      (inviteState?.hasCooldown ??
          false);

  // ==========================================================
  // SHOW REQUEST BUTTON
  // ==========================================================

  bool get _showRequestButton {
    if (_videoAllowed) {
      return false;
    }

    if (onRequestVideo ==
        null) {
      return false;
    }

    final state = inviteState;

    // Nunca houve convite.
    if (state ==
        null) {
      return true;
    }

    return state.canRequestVideo;
  }

  // ==========================================================
  // SHOW COOLDOWN
  // ==========================================================

  bool get _showCooldownMessage {
    if (_videoAllowed) {
      return false;
    }

    return inviteState?.hasCooldown ??
        false;
  }

  // ==========================================================
  // VIDEO DESCRIPTION
  // ==========================================================

  String get _videoDescription {
    if (_videoAllowed) {
      return 'Vídeo liberado por consentimento';
    }

    if (_videoBlocked) {
      return 'Limite de convites atingido';
    }

    if (_hasCooldown) {
      final label = inviteState?.cooldownLabel;

      if (label !=
              null &&
          label.isNotEmpty) {
        return 'Novo convite em $label';
      }

      return 'Aguardando novo convite';
    }

    final state = inviteState;

    if (state ==
            null ||
        state.rejectionCount ==
            0) {
      return 'Requer consentimento';
    }

    return 'Pode solicitar novamente';
  }

  // ==========================================================
  // REQUEST BUTTON LABEL
  // ==========================================================

  String get _requestButtonLabel {
    final state = inviteState;

    if (state ==
            null ||
        state.rejectionCount ==
            0) {
      return 'Solicitar vídeo';
    }

    return 'Enviar convite ${state.nextAttempt}/3';
  }

  // ==========================================================
  // INVITE INFORMATION TEXT
  // ==========================================================

  String get _inviteInformationText {
    final state = inviteState;

    if (state ==
        null) {
      return '';
    }

    if (state.blockedAfterLimit) {
      return '3 recusas registradas.';
    }

    if (state.rejectionCount ==
        0) {
      return 'Nenhuma recusa registrada.';
    }

    if (state.rejectionCount ==
        1) {
      return '1ª solicitação recusada.';
    }

    if (state.rejectionCount ==
        2) {
      return '2 solicitações recusadas.';
    }

    return '3 solicitações recusadas.';
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
