import 'dart:async';

import 'package:flutter/material.dart';

import '../controllers/match_controllers.dart';

import '../../profile/controllers/professional_profile_controller.dart';

// ============================================================
// CONNECTION PROFILE CARD WIDGET
// ============================================================
//
// Card que resume:
//
// - função principal do usuário;
// - tipos de profissionais procurados;
// - acesso à edição do perfil profissional.
//
// COMPORTAMENTO:
//
// Ao abrir a tela:
//
// 1. inicia EXPANDIDO;
// 2. permanece expandido por alguns instantes;
// 3. anima automaticamente para o modo COMPACTO;
// 4. depois pode ser aberto/recolhido manualmente.
//
// OBJETIVO:
//
// O card apresenta a configuração ao entrar no Match,
// mas rapidamente libera espaço para:
//
// NOVAS CONEXÕES
//
// que passa a ser o conteúdo predominante da página.
//
// ============================================================

class ConnectionProfileCardWidget
    extends
        StatefulWidget {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final MatchController matchController;

  final ProfessionalProfileController profileController;

  // ============================================================
  // STATE
  // ============================================================

  final bool isInitializingMatch;

  // ============================================================
  // CALLBACK
  // ============================================================

  final Future<
    void
  >
  Function()
  onEditProfile;

  // ============================================================
  // AUTO COLLAPSE
  // ============================================================

  final Duration autoCollapseDelay;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  const ConnectionProfileCardWidget({
    super.key,
    required this.matchController,
    required this.profileController,
    required this.isInitializingMatch,
    required this.onEditProfile,
    this.autoCollapseDelay = const Duration(
      milliseconds: 1800,
    ),
  });

  // ============================================================
  // STATE
  // ============================================================

  @override
  State<
    ConnectionProfileCardWidget
  >
  createState() => _ConnectionProfileCardWidgetState();
}

// ============================================================
// CONNECTION PROFILE CARD STATE
// ============================================================

class _ConnectionProfileCardWidgetState
    extends
        State<
          ConnectionProfileCardWidget
        >
    with
        SingleTickerProviderStateMixin {
  // ============================================================
  // CONSTANTS
  // ============================================================

  static const Duration _animationDuration = Duration(
    milliseconds: 520,
  );

  // ============================================================
  // STATE
  // ============================================================

  bool _expanded = true;

  bool _editing = false;

  Timer? _autoCollapseTimer;

  late final AnimationController _glowController;

  late final Animation<
    double
  >
  _glowAnimation;

  int _lastAttentionRevision = 0;

  bool get _requiresProfessionalProfile => widget.matchController.requiresProfessionalProfile;

  bool get _shouldHighlightEditButton =>
      _requiresProfessionalProfile &&
      !widget.isInitializingMatch;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 950,
      ),
    );

    _glowAnimation = CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    );

    _lastAttentionRevision = widget.matchController.professionalProfileAttentionRevision;

    widget.matchController.addListener(
      _handleMatchControllerChanged,
    );

    _syncRequiredState(
      initial: true,
    );
  }

  // ============================================================
  // DID UPDATE WIDGET
  // ============================================================

  @override
  void didUpdateWidget(
    covariant ConnectionProfileCardWidget oldWidget,
  ) {
    super.didUpdateWidget(
      oldWidget,
    );

    if (!identical(
      oldWidget.matchController,
      widget.matchController,
    )) {
      oldWidget.matchController.removeListener(
        _handleMatchControllerChanged,
      );

      widget.matchController.addListener(
        _handleMatchControllerChanged,
      );

      _lastAttentionRevision = widget.matchController.professionalProfileAttentionRevision;
    }

    _syncRequiredState();
  }

  // ============================================================
  // MATCH CONTROLLER CHANGED
  // ============================================================

  void _handleMatchControllerChanged() {
    if (!mounted) {
      return;
    }

    final revision = widget.matchController.professionalProfileAttentionRevision;

    if (revision !=
        _lastAttentionRevision) {
      _lastAttentionRevision = revision;

      _triggerAttentionFlash();
    }

    _syncRequiredState();
  }

  // ============================================================
  // SINCRONIZAR ESTADO OBRIGATÓRIO
  // ============================================================

  void _syncRequiredState({
    bool initial = false,
  }) {
    if (!mounted &&
        !initial) {
      return;
    }

    if (_requiresProfessionalProfile) {
      _autoCollapseTimer?.cancel();

      if (!_expanded) {
        setState(
          () {
            _expanded = true;
          },
        );
      }

      if (!_glowController.isAnimating) {
        _glowController.repeat(
          reverse: true,
        );
      }

      return;
    }

    if (_glowController.isAnimating) {
      _glowController.stop();
    }

    _glowController.value = 0;

    if (!initial) {
      _scheduleAutoCollapse();
    } else {
      _scheduleAutoCollapse();
    }
  }

  // ============================================================
  // FLASH DE ATENÇÃO
  // ============================================================
  //
  // Chamado quando o usuário tenta interagir com alguma área do
  // Match enquanto ainda falta a função principal.
  //
  // O MatchController incrementa:
  //
  // professionalProfileAttentionRevision
  //
  // e este widget responde com um pulso rápido adicional.
  //
  // ============================================================

  Future<
    void
  >
  _triggerAttentionFlash() async {
    if (!mounted ||
        !_requiresProfessionalProfile) {
      return;
    }

    _autoCollapseTimer?.cancel();

    if (!_expanded) {
      setState(
        () {
          _expanded = true;
        },
      );
    }

    _glowController.stop();

    for (
      var index = 0;
      index <
          2;
      index++
    ) {
      if (!mounted) {
        return;
      }

      await _glowController.animateTo(
        1,
        duration: const Duration(
          milliseconds: 150,
        ),
        curve: Curves.easeOut,
      );

      if (!mounted) {
        return;
      }

      await _glowController.animateTo(
        0.22,
        duration: const Duration(
          milliseconds: 140,
        ),
        curve: Curves.easeIn,
      );
    }

    if (!mounted ||
        !_requiresProfessionalProfile) {
      return;
    }

    _glowController.repeat(
      reverse: true,
    );
  }

  // ============================================================
  // SCHEDULE AUTO COLLAPSE
  // ============================================================

  void _scheduleAutoCollapse() {
    _autoCollapseTimer?.cancel();

    if (_requiresProfessionalProfile) {
      return;
    }

    _autoCollapseTimer = Timer(
      widget.autoCollapseDelay,
      () {
        if (!mounted ||
            !_expanded ||
            _requiresProfessionalProfile) {
          return;
        }

        setState(
          () {
            _expanded = false;
          },
        );
      },
    );
  }

  // ============================================================
  // TOGGLE
  // ============================================================

  void _toggleExpanded() {
    _autoCollapseTimer?.cancel();

    if (_requiresProfessionalProfile &&
        _expanded) {
      _triggerAttentionFlash();

      return;
    }

    setState(
      () {
        _expanded = !_expanded;
      },
    );

    if (_expanded &&
        !_requiresProfessionalProfile) {
      _scheduleAutoCollapse();
    }
  }

  // ============================================================
  // EDIT
  // ============================================================

  Future<
    void
  >
  _handleEdit() async {
    if (_editing) {
      return;
    }

    setState(
      () {
        _editing = true;
      },
    );

    try {
      await widget.onEditProfile();
    } finally {
      if (!mounted) {
        return;
      }

      setState(
        () {
          _editing = false;
        },
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder:
          (
            context,
            child,
          ) {
            final glowValue = _shouldHighlightEditButton
                ? _glowAnimation.value
                : 0.0;

            final accentColor = widget.matchController.accentNeon;

            return Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color:
                    const Color(
                      0xFF17132D,
                    ).withValues(
                      alpha: 0.90,
                    ),
                borderRadius: BorderRadius.circular(
                  _expanded
                      ? 22
                      : 15,
                ),
                border: Border.all(
                  color: _shouldHighlightEditButton
                      ? accentColor.withValues(
                          alpha:
                              0.18 +
                              (glowValue *
                                  0.48),
                        )
                      : Colors.white.withValues(
                          alpha: 0.07,
                        ),
                  width: _shouldHighlightEditButton
                      ? 1.25
                      : 1,
                ),
                boxShadow: _shouldHighlightEditButton
                    ? [
                        BoxShadow(
                          color: accentColor.withValues(
                            alpha:
                                0.05 +
                                (glowValue *
                                    0.22),
                          ),
                          blurRadius:
                              14 +
                              (glowValue *
                                  20),
                          spreadRadius:
                              glowValue *
                              1.8,
                        ),
                      ]
                    : const [],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(),

                  if (_expanded) _buildExpandedContent(),
                ],
              ),
            );
          },
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    final controller = widget.profileController;

    final lookingFor = controller.lookingForRoleLabels;

    final subtitle =
        controller.isLoading ||
            widget.isInitializingMatch
        ? 'Carregando perfil...'
        : lookingFor.isEmpty
        ? 'Não informado'
        : lookingFor.length ==
              1
        ? '1 tipo de profissional'
        : '${lookingFor.length} tipos de profissionais';

    return Material(
      color: Colors.transparent,

      child: InkWell(
        onTap: _toggleExpanded,

        borderRadius: BorderRadius.circular(
          _expanded
              ? 22
              : 15,
        ),

        child: AnimatedPadding(
          duration: _animationDuration,

          curve: Curves.easeInOutCubic,

          padding: EdgeInsets.symmetric(
            horizontal: _expanded
                ? 16
                : 12,

            vertical: _expanded
                ? 16
                : 9,
          ),

          child: Row(
            children: [
              // ==================================================
              // ICON
              // ==================================================
              AnimatedContainer(
                duration: _animationDuration,

                curve: Curves.easeInOutCubic,

                width: _expanded
                    ? 46
                    : 32,

                height: _expanded
                    ? 46
                    : 32,

                decoration: BoxDecoration(
                  color: widget.matchController.accentNeon.withValues(
                    alpha: 0.10,
                  ),

                  shape: BoxShape.circle,

                  border: Border.all(
                    color: widget.matchController.accentNeon.withValues(
                      alpha: 0.30,
                    ),
                  ),
                ),

                child: Icon(
                  Icons.person_search_rounded,

                  color: widget.matchController.accentNeon,

                  size: _expanded
                      ? 22
                      : 16,
                ),
              ),

              SizedBox(
                width: _expanded
                    ? 13
                    : 10,
              ),

              // ==================================================
              // TITLE
              // ==================================================
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      'Você quer se conectar com',

                      maxLines: 1,

                      overflow: TextOverflow.ellipsis,

                      style: TextStyle(
                        color: Colors.white,

                        fontSize: _expanded
                            ? 14
                            : 12,

                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(
                      height: 2,
                    ),

                    Text(
                      subtitle,

                      maxLines: 1,

                      overflow: TextOverflow.ellipsis,

                      style: TextStyle(
                        color: Colors.white38,

                        fontSize: _expanded
                            ? 10
                            : 9,
                      ),
                    ),
                  ],
                ),
              ),

              // ==================================================
              // EDIT
              // ==================================================
              IconButton(
                tooltip: 'Editar perfil profissional',

                visualDensity: VisualDensity.compact,

                onPressed: _editing
                    ? null
                    : _handleEdit,

                icon: _editing
                    ? SizedBox(
                        width: 16,

                        height: 16,

                        child: CircularProgressIndicator(
                          strokeWidth: 1.8,

                          color: widget.matchController.accentNeon,
                        ),
                      )
                    : Icon(
                        Icons.edit_outlined,

                        color: widget.matchController.accentNeon,

                        size: _expanded
                            ? 18
                            : 16,
                      ),
              ),

              // ==================================================
              // EXPAND
              // ==================================================
              AnimatedRotation(
                turns: _expanded
                    ? 0.5
                    : 0,

                duration: _animationDuration,

                curve: Curves.easeInOutCubic,

                child: const Icon(
                  Icons.keyboard_arrow_down_rounded,

                  color: Colors.white54,

                  size: 21,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // EXPANDED CONTENT
  // ============================================================

  Widget _buildExpandedContent() {
    final controller = widget.profileController;

    if (controller.isLoading) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          18,
        ),

        child: Center(
          child: SizedBox(
            width: 20,

            height: 20,

            child: CircularProgressIndicator(
              strokeWidth: 2,

              color: Colors.purpleAccent,
            ),
          ),
        ),
      );
    }

    final lookingFor = controller.lookingForRoleLabels;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16,
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Divider(
            height: 1,
            color: Colors.white.withValues(
              alpha: 0.06,
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          // ======================================================
          // PRIMARY ROLE
          // ======================================================
          Row(
            children: [
              const Text(
                'Sua função principal:',

                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                ),
              ),

              const SizedBox(
                width: 6,
              ),

              Flexible(
                child: Text(
                  controller.primaryRoleLabel,

                  maxLines: 1,

                  overflow: TextOverflow.ellipsis,

                  style: TextStyle(
                    color: widget.matchController.accentNeon,

                    fontSize: 10,

                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 14,
          ),

          // ======================================================
          // LOOKING FOR
          // ======================================================
          const Text(
            'PROFISSIONAIS PROCURADOS',

            style: TextStyle(
              color: Colors.white38,

              fontSize: 9,

              fontWeight: FontWeight.w700,

              letterSpacing: 0.45,
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          if (lookingFor.isEmpty)
            const Text(
              'Nenhum profissional configurado.',

              style: TextStyle(
                color: Colors.white30,
                fontSize: 10,
              ),
            )
          else
            Wrap(
              spacing: 8,

              runSpacing: 8,

              children: lookingFor
                  .map(
                    (
                      label,
                    ) => _buildRoleChip(
                      label,
                    ),
                  )
                  .toList(
                    growable: false,
                  ),
            ),

          const SizedBox(
            height: 16,
          ),

          if (_requiresProfessionalProfile) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 11,
                vertical: 9,
              ),
              decoration: BoxDecoration(
                color: widget.matchController.accentNeon.withValues(
                  alpha: 0.06,
                ),
                borderRadius: BorderRadius.circular(
                  11,
                ),
                border: Border.all(
                  color: widget.matchController.accentNeon.withValues(
                    alpha: 0.18,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: widget.matchController.accentNeon,
                    size: 15,
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  const Expanded(
                    child: Text(
                      'Defina sua função principal para liberar o Match.',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 10,
            ),
          ],

          // ======================================================
          // EDIT BUTTON
          // ======================================================
          AnimatedBuilder(
            animation: _glowAnimation,
            builder:
                (
                  context,
                  child,
                ) {
                  final accentColor = widget.matchController.accentNeon;

                  final glowValue = _shouldHighlightEditButton
                      ? _glowAnimation.value
                      : 0.0;

                  return Container(
                    width: double.infinity,
                    height: 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        12,
                      ),
                      boxShadow: _shouldHighlightEditButton
                          ? [
                              BoxShadow(
                                color: accentColor.withValues(
                                  alpha:
                                      0.08 +
                                      (glowValue *
                                          0.34),
                                ),
                                blurRadius:
                                    8 +
                                    (glowValue *
                                        18),
                                spreadRadius:
                                    glowValue *
                                    1.4,
                              ),
                            ]
                          : const [],
                    ),
                    child: OutlinedButton.icon(
                      onPressed: _editing
                          ? null
                          : _handleEdit,
                      icon: _editing
                          ? SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.7,
                                color: accentColor,
                              ),
                            )
                          : Icon(
                              Icons.tune_rounded,
                              size: 15,
                              color: accentColor,
                            ),
                      label: Text(
                        'EDITAR PERFIL PROFISSIONAL',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: _shouldHighlightEditButton
                              ? 0.75
                              : 0.45,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: accentColor,
                        backgroundColor: _shouldHighlightEditButton
                            ? accentColor.withValues(
                                alpha:
                                    0.04 +
                                    (glowValue *
                                        0.08),
                              )
                            : Colors.transparent,
                        side: BorderSide(
                          color: accentColor.withValues(
                            alpha: _shouldHighlightEditButton
                                ? 0.42 +
                                      (glowValue *
                                          0.42)
                                : 0.38,
                          ),
                          width: _shouldHighlightEditButton
                              ? 1.35
                              : 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            11,
                          ),
                        ),
                      ),
                    ),
                  );
                },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ROLE CHIP
  // ============================================================

  Widget _buildRoleChip(
    String label,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),

      decoration: BoxDecoration(
        color: widget.matchController.accentNeon.withValues(
          alpha: 0.09,
        ),

        borderRadius: BorderRadius.circular(
          20,
        ),

        border: Border.all(
          color: widget.matchController.accentNeon.withValues(
            alpha: 0.26,
          ),
        ),
      ),

      child: Text(
        label,

        style: const TextStyle(
          color: Colors.white70,

          fontSize: 9,

          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _autoCollapseTimer?.cancel();

    widget.matchController.removeListener(
      _handleMatchControllerChanged,
    );

    _glowController.dispose();

    super.dispose();
  }
}
