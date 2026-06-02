import 'package:flutter/material.dart';
import '../controllers/match_controllers.dart';
import '../models/match_user_entity.dart';
import 'action_button_widget.dart';
import '../../networking/views/networking_session_view.dart';

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

class _DiscoveryCardWidgetState
    extends
        State<
          DiscoveryCardWidget
        > {
  bool _isWaitingForNetworking = false;

  Future<
    void
  >
  _handleMatchIntent() async {
    // Verificação de segurança para obter o ID de forma estável
    final String? userId = widget.controller.currentUserId;
    if (userId ==
        null) {
      debugPrint(
        "Erro: Usuário não está autenticado!",
      );
      return;
    }

    setState(
      () => _isWaitingForNetworking = true,
    );

    // 1. Registra o like no Supabase
    await widget.controller.registerLike(
      widget.user.id,
    );

    // 2. Tenta processar o match.
    // A navegação agora é controlada pela MatchPage via listener do stream.
    await widget.controller.checkAndStartNetworking(
      userId,
      widget.user.id,
    );
  }

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
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          24,
        ),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.1,
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          24,
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.network(
                widget.user.showcaseMediaUrl.isNotEmpty
                    ? widget.user.showcaseMediaUrl
                    : "https://images.unsplash.com/photo-1514525253361-bee8718a7439?q=80&w=500",
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
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomRight,
                    colors: [
                      widget.controller.primaryPurple.withValues(
                        alpha: 0.8,
                      ),
                      Colors.black54,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(
                20.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(
                            alpha: 0.4,
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
                              widget.user.preferredConnection.name.toUpperCase(),
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
                          "$minutes:$seconds",
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
                  Row(
                    children: [
                      Text(
                        widget.user.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
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
                  Text(
                    widget.user.bio,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  _isWaitingForNetworking
                      ? Container(
                          padding: const EdgeInsets.all(
                            12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(
                              12,
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              "ESPERANDO NETWORKING...",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        )
                      : Row(
                          children: [
                            ActionButtonWidget(
                              icon: Icons.close,
                              color: Colors.white24,
                              onTap: () {},
                            ),
                            const SizedBox(
                              width: 12,
                            ),
                            ActionButtonWidget(
                              icon: Icons.favorite,
                              color: widget.controller.accentNeon,
                              onTap: _handleMatchIntent,
                            ),
                            const Spacer(),
                            ElevatedButton(
                              onPressed: () => widget.controller.listenDemo(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: widget.controller.accentNeon,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    12,
                                  ),
                                ),
                              ),
                              child: const Text(
                                "OUVIR DEMO",
                                style: TextStyle(
                                  color: Colors.black,
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
}
