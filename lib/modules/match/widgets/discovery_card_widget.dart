import 'package:flutter/material.dart';

import 'package:versin/core/utils/network_image_url_helper.dart';

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
// - status ONLINE AGORA;
// - nome artístico;
// - username;
// - função principal;
// - bio;
// - timer;
// - profissionais procurados;
// - ações;
// - botão para ouvir demo.
//
// AÇÕES:
//
// X
// -> ignora o usuário atual;
// -> tenta mostrar o próximo.
//
// Coração
// -> registra like;
// -> verifica match;
// -> tenta mostrar o próximo.
//
// IMPORTANTE:
//
// Se não existir próximo usuário:
//
// - o card atual permanece;
// - o usuário não desaparece.
//
// NÃO:
//
// - consulta Supabase diretamente;
// - carrega música;
// - gera signed URL;
// - reproduz áudio;
// - cria projeto;
// - navega para Networking.
//
// O fluxo da demo é delegado para onListenDemo.
//
// O fluxo do X é delegado para onDismiss.
//
// O fluxo do coração é delegado para onLike.
//
// ============================================================

class DiscoveryCardWidget
    extends
        StatefulWidget {
  // ============================================================
  // MATCH
  // ============================================================

  final MatchController controller;

  // ============================================================
  // USUÁRIO
  // ============================================================

  final MatchUserEntity user;

  // ============================================================
  // ACTIONS
  // ============================================================

  final VoidCallback? onDismiss;

  final Future<
    void
  >
  Function()?
  onLike;

  // ============================================================
  // DEMO
  // ============================================================
  //
  // O widget superior decide:
  //
  // - buscar demo;
  // - solicitar URL de reprodução;
  // - abrir modal;
  // - reproduzir;
  // - mostrar estado vazio.
  //
  // O DiscoveryCardWidget apenas dispara a ação.
  //
  // ============================================================

  final Future<
    void
  >
  Function()?
  onListenDemo;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  const DiscoveryCardWidget({
    super.key,
    required this.controller,
    required this.user,
    this.onDismiss,
    this.onLike,
    this.onListenDemo,
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

  bool _isOpeningDemo = false;

  static const String _fallbackShowcaseUrl = 'https://images.unsplash.com/photo-1514525253361-bee8718a7439?q=80&w=500';

  // ============================================================
  // DID UPDATE WIDGET
  // ============================================================
  //
  // Quando o controller troca o usuário principal, garantimos
  // que o novo card não herde o estado visual de processamento
  // do usuário anterior.
  //
  // ============================================================

  @override
  void didUpdateWidget(
    covariant DiscoveryCardWidget oldWidget,
  ) {
    super.didUpdateWidget(
      oldWidget,
    );

    if (oldWidget.user.id !=
        widget.user.id) {
      _isWaitingForNetworking = false;

      _isOpeningDemo = false;
    }
  }

  // ============================================================
  // MATCH INTENT
  // ============================================================

  Future<
    void
  >
  _handleMatchIntent() async {
    final callback = widget.onLike;

    if (callback ==
        null) {
      debugPrint(
        '[DISCOVERY] '
        'Callback de like não configurado.',
      );

      return;
    }

    if (_isWaitingForNetworking) {
      return;
    }

    if (mounted) {
      setState(
        () {
          _isWaitingForNetworking = true;
        },
      );
    }

    try {
      await callback();
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[DISCOVERY] '
        'Erro ao processar conexão: '
        '$error',
      );

      debugPrint(
        '[DISCOVERY] '
        'Stack trace: '
        '$stackTrace',
      );
    } finally {
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
  // DISMISS
  // ============================================================

  void _handleDismiss() {
    if (_isWaitingForNetworking ||
        _isOpeningDemo) {
      return;
    }

    debugPrint(
      '[DISCOVERY] '
      'Perfil ignorado: '
      '${widget.user.id}',
    );

    widget.onDismiss?.call();
  }

  // ============================================================
  // OUVIR DEMO
  // ============================================================

  Future<
    void
  >
  _handleListenDemo() async {
    final callback = widget.onListenDemo;

    if (callback ==
        null) {
      debugPrint(
        '[DISCOVERY] '
        'Callback de demo não configurado para: '
        '${widget.user.id}',
      );

      return;
    }

    // ========================================================
    // EVITAR CLIQUES DUPLOS
    // ========================================================

    if (_isOpeningDemo) {
      debugPrint(
        '[DISCOVERY] '
        'Abertura da demo já está em andamento.',
      );

      return;
    }

    // ========================================================
    // BLOQUEAR BOTÃO
    // ========================================================

    if (mounted) {
      setState(
        () {
          _isOpeningDemo = true;
        },
      );
    }

    try {
      debugPrint(
        '[DISCOVERY] '
        'Abrindo demo de: '
        '${widget.user.id}',
      );

      // ======================================================
      // DELEGAR TODO O FLUXO
      // ======================================================
      //
      // IMPORTANTE:
      //
      // O callback superior é responsável por:
      //
      // 1. buscar a track;
      // 2. gerar UMA playback URL;
      // 3. abrir o player;
      // 4. usar a mesma URL no player.
      //
      // Este widget NÃO solicita outra URL.
      //
      // ======================================================

      await callback();

      debugPrint(
        '[DISCOVERY] '
        'Fluxo da demo finalizado.',
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[DISCOVERY] '
        'Erro ao abrir demo: '
        '$error',
      );

      debugPrint(
        '[DISCOVERY] '
        'Stack trace: '
        '$stackTrace',
      );
    } finally {
      if (mounted) {
        setState(
          () {
            _isOpeningDemo = false;
          },
        );
      }
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
              child: _buildShowcaseBackground(),
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
                      // ONLINE AGORA
                      // ==========================================
                      _buildOnlineBadge(),

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
                      ? _buildWaiting()
                      : _buildActions(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SHOWCASE BACKGROUND
  // ============================================================

  Widget _buildShowcaseBackground() {
    final showcaseUrl = NetworkImageUrlHelper.validUrlOrNull(
      widget.user.showcaseMediaUrl,
    );

    final imageUrl =
        showcaseUrl ??
        _fallbackShowcaseUrl;

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder:
          (
            context,
            error,
            stackTrace,
          ) {
            return Container(
              color: Colors.black45,
              alignment: Alignment.center,
              child: const Icon(
                Icons.music_note,
                color: Colors.white24,
                size: 50,
              ),
            );
          },
    );
  }

  // ============================================================
  // ONLINE BADGE
  // ============================================================

  Widget _buildOnlineBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,

        vertical: 5,
      ),

      decoration: BoxDecoration(
        color: Colors.black.withValues(
          alpha: 0.48,
        ),

        borderRadius: BorderRadius.circular(
          8,
        ),

        border: Border.all(
          color:
              const Color(
                0xFF34D399,
              ).withValues(
                alpha: 0.18,
              ),
        ),
      ),

      child: const Row(
        mainAxisSize: MainAxisSize.min,

        children: [
          // ====================================================
          // DOT
          // ====================================================
          _OnlineDot(),

          SizedBox(
            width: 6,
          ),

          // ====================================================
          // LABEL
          // ====================================================
          Text(
            'ONLINE AGORA',

            style: TextStyle(
              color: Color(
                0xFF34D399,
              ),

              fontSize: 9,

              fontWeight: FontWeight.w800,

              letterSpacing: 0.55,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WAITING
  // ============================================================

  Widget _buildWaiting() {
    return Container(
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
          'VERIFICANDO NETWORKING...',

          style: TextStyle(
            color: Colors.white70,

            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // AÇÕES
  // ============================================================

  Widget _buildActions() {
    return Row(
      children: [
        // ======================================================
        // PASSAR
        // ======================================================
        ActionButtonWidget(
          icon: Icons.close,

          color: Colors.white24,

          onTap:
              widget.onDismiss ==
                  null
              ? null
              : _handleDismiss,
        ),

        const SizedBox(
          width: 12,
        ),

        // ======================================================
        // LIKE
        // ======================================================
        ActionButtonWidget(
          icon: Icons.favorite,

          color: widget.controller.accentNeon,

          onTap:
              widget.onLike ==
                  null
              ? null
              : _handleMatchIntent,
        ),

        const Spacer(),

        // ======================================================
        // OUVIR DEMO
        // ======================================================
        ElevatedButton.icon(
          onPressed:
              widget.onListenDemo ==
                      null ||
                  _isOpeningDemo
              ? null
              : _handleListenDemo,

          style: ElevatedButton.styleFrom(
            backgroundColor: widget.controller.accentNeon,

            disabledBackgroundColor: Colors.white12,

            foregroundColor: Colors.black,

            disabledForegroundColor: Colors.white38,

            elevation: 0,

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                12,
              ),
            ),
          ),

          icon: _isOpeningDemo
              ? const SizedBox(
                  width: 14,

                  height: 14,

                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : const Icon(
                  Icons.play_arrow_rounded,

                  size: 17,
                ),

          label: Text(
            _isOpeningDemo
                ? 'CARREGANDO...'
                : 'OUVIR DEMO',

            style: const TextStyle(
              fontSize: 10,

              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
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

// ============================================================
// ONLINE DOT
// ============================================================

class _OnlineDot
    extends
        StatelessWidget {
  const _OnlineDot();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: 7,

      height: 7,

      decoration: BoxDecoration(
        color: const Color(
          0xFF34D399,
        ),

        shape: BoxShape.circle,

        boxShadow: [
          BoxShadow(
            color:
                const Color(
                  0xFF34D399,
                ).withValues(
                  alpha: 0.50,
                ),

            blurRadius: 6,
          ),
        ],
      ),
    );
  }
}
