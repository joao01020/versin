import 'package:flutter/material.dart';

import '../controllers/match_controllers.dart';
import '../models/match_user_entity.dart';
import 'action_button_widget.dart';

// ============================================================
// DISCOVERY CARD WIDGET
// ============================================================
//
// Card principal do módulo Match.
//
// Exibe:
//
// - showcase;
// - nome artístico;
// - username;
// - função principal;
// - bio;
// - tipo de conexão;
// - timer;
// - profissionais procurados;
// - ações.
//
// ============================================================

class DiscoveryCardWidget
    extends
        StatefulWidget {
  final MatchController controller;
  final MatchUserEntity user;

  const DiscoveryCardWidget({
    super.key,
    required this.controller,
    required this.user,
  });

  @override
  State<
    DiscoveryCardWidget
  >
  createState() => _DiscoveryCardWidgetState();
}

// ============================================================
// STATE
// ============================================================

class _DiscoveryCardWidgetState
    extends
        State<
          DiscoveryCardWidget
        > {
  // ============================================================
  // ESTADO
  // ============================================================

  bool _isWaitingForNetworking = false;

  // ============================================================
  // MATCH INTENT
  // ============================================================

  Future<
    void
  >
  _handleMatchIntent() async {
    final userId = widget.controller.currentUserId;

    if (userId ==
        null) {
      debugPrint(
        '[DISCOVERY] Usuário não autenticado.',
      );

      return;
    }

    if (_isWaitingForNetworking) {
      return;
    }

    setState(
      () {
        _isWaitingForNetworking = true;
      },
    );

    try {
      // ========================================================
      // LIKE
      // ========================================================

      await widget.controller.registerLike(
        widget.user.id,
      );

      // ========================================================
      // VERIFICAR MATCH MÚTUO
      // ========================================================

      final started = await widget.controller.checkAndStartNetworking(
        userId,
        widget.user.id,
      );

      // ========================================================
      // AINDA NÃO É MATCH MÚTUO
      // ========================================================

      if (!started &&
          mounted) {
        setState(
          () {
            _isWaitingForNetworking = false;
          },
        );
      }
    } catch (
      error
    ) {
      debugPrint(
        '[DISCOVERY] '
        'Erro ao processar conexão: $error',
      );

      if (mounted) {
        setState(
          () {
            _isWaitingForNetworking = false;
          },
        );
      }
    }
  }

  // ============================================================
  // CONNECTION ICON
  // ============================================================

  IconData _getConnectionIcon(
    ConnectionType type,
  ) {
    switch (type) {
      case ConnectionType.chat:
        return Icons.chat_bubble_outline;

      case ConnectionType.video:
        return Icons.videocam_outlined;

      case ConnectionType.proximity:
        return Icons.location_on_outlined;
    }
  }

  // ============================================================
  // CONNECTION LABEL
  // ============================================================

  String _getConnectionLabel(
    ConnectionType type,
  ) {
    switch (type) {
      case ConnectionType.chat:
        return 'CHAT';

      case ConnectionType.video:
        return 'VÍDEO';

      case ConnectionType.proximity:
        return 'PROXIMIDADE';
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final minutes =
        (widget.controller.remainingSeconds ~/
                60)
            .toString()
            .padLeft(
              2,
              '0',
            );

    final seconds =
        (widget.controller.remainingSeconds %
                60)
            .toString()
            .padLeft(
              2,
              '0',
            );

    return Container(
      height: 270,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          24,
        ),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.10,
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          24,
        ),
        child: Stack(
          children: [
            // ==================================================
            // BACKGROUND
            // ==================================================
            Positioned.fill(
              child: Image.network(
                widget.user.showcaseMediaUrl.isNotEmpty
                    ? widget.user.showcaseMediaUrl
                    : 'https://images.unsplash.com/photo-1514525253361-bee8718a7439?q=80&w=500',
                fit: BoxFit.cover,
                errorBuilder:
                    (
                      context,
                      error,
                      stackTrace,
                    ) {
                      return Container(
                        color: Colors.black45,
                        child: const Icon(
                          Icons.music_note,
                          color: Colors.white24,
                          size: 50,
                        ),
                      );
                    },
              ),
            ),

            // ==================================================
            // GRADIENT
            // ==================================================
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomRight,
                    end: Alignment.topLeft,
                    colors: [
                      widget.controller.primaryPurple.withValues(
                        alpha: 0.85,
                      ),
                      Colors.black.withValues(
                        alpha: 0.78,
                      ),
                      Colors.black26,
                    ],
                  ),
                ),
              ),
            ),

            // ==================================================
            // CONTENT
            // ==================================================
            Padding(
              padding: const EdgeInsets.all(
                20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // ==================================================
                  // TOP BAR
                  // ==================================================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // ==========================================
                      // CONNECTION TYPE
                      // ==========================================
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(
                            alpha: 0.45,
                          ),
                          borderRadius: BorderRadius.circular(
                            8,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _getConnectionIcon(
                                widget.user.preferredConnection,
                              ),
                              color: Colors.white70,
                              size: 14,
                            ),

                            const SizedBox(
                              width: 4,
                            ),

                            Text(
                              _getConnectionLabel(
                                widget.user.preferredConnection,
                              ),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ==========================================
                      // TIMER
                      // ==========================================
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(
                            alpha: 0.86,
                          ),
                          borderRadius: BorderRadius.circular(
                            8,
                          ),
                        ),
                        child: Text(
                          '$minutes:$seconds',
                          style: TextStyle(
                            color: widget.controller.accentNeon,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // ==================================================
                  // NOME
                  // ==================================================
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.user.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(
                        width: 8,
                      ),

                      Icon(
                        Icons.verified,
                        color: widget.controller.accentNeon,
                        size: 18,
                      ),
                    ],
                  ),

                  // ==================================================
                  // USERNAME
                  // ==================================================
                  if (widget.user.hasUsername) ...[
                    const SizedBox(
                      height: 2,
                    ),

                    Text(
                      widget.user.usernameLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],

                  const SizedBox(
                    height: 4,
                  ),

                  // ==================================================
                  // FUNÇÃO PRINCIPAL
                  // ==================================================
                  Text(
                    widget.user.primaryRoleLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: widget.controller.accentNeon,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(
                    height: 6,
                  ),

                  // ==================================================
                  // BIO
                  // ==================================================
                  Text(
                    widget.user.bio.trim().isEmpty
                        ? 'Sem bio informada.'
                        : widget.user.bio,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),

                  // ==================================================
                  // QUEM PROCURA
                  // ==================================================
                  if (widget.user.lookingForRoles.isNotEmpty) ...[
                    const SizedBox(
                      height: 8,
                    ),

                    _buildLookingForRow(),
                  ],

                  const SizedBox(
                    height: 14,
                  ),

                  // ==================================================
                  // AÇÕES
                  // ==================================================
                  _isWaitingForNetworking
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(
                            12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(
                              alpha: 0.10,
                            ),
                            borderRadius: BorderRadius.circular(
                              12,
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              'ESPERANDO NETWORKING...',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        )
                      : Row(
                          children: [
                            // ======================================
                            // PASSAR
                            // ======================================
                            ActionButtonWidget(
                              icon: Icons.close,
                              color: Colors.white24,
                              onTap: () {
                                debugPrint(
                                  '[DISCOVERY] '
                                  'Perfil ignorado: '
                                  '${widget.user.id}',
                                );
                              },
                            ),

                            const SizedBox(
                              width: 12,
                            ),

                            // ======================================
                            // LIKE
                            // ======================================
                            ActionButtonWidget(
                              icon: Icons.favorite,
                              color: widget.controller.accentNeon,
                              onTap: _handleMatchIntent,
                            ),

                            const Spacer(),

                            // ======================================
                            // DEMO
                            // ======================================
                            ElevatedButton.icon(
                              onPressed: widget.controller.listenDemo,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: widget.controller.accentNeon,
                                foregroundColor: Colors.black,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    12,
                                  ),
                                ),
                              ),
                              icon: const Icon(
                                Icons.play_arrow_rounded,
                                size: 17,
                              ),
                              label: const Text(
                                'OUVIR DEMO',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // QUEM PROCURA
  // ============================================================

  Widget _buildLookingForRow() {
    final roles = widget.user.lookingForRoles;

    final visibleRoles = roles.take(
      3,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(
          Icons.person_search_outlined,
          color: Colors.white38,
          size: 13,
        ),

        const SizedBox(
          width: 5,
        ),

        const Text(
          'Procura:',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(
          width: 6,
        ),

        Expanded(
          child: Text(
            visibleRoles
                .map(
                  (
                    role,
                  ) => role.label,
                )
                .join(
                  ' • ',
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 9,
            ),
          ),
        ),

        if (roles.length >
            3)
          Text(
            '+${roles.length - 3}',
            style: TextStyle(
              color: widget.controller.accentNeon,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }
}
