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
        > {
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

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _scheduleAutoCollapse();
  }

  // ============================================================
  // SCHEDULE AUTO COLLAPSE
  // ============================================================

  void _scheduleAutoCollapse() {
    _autoCollapseTimer?.cancel();

    _autoCollapseTimer = Timer(
      widget.autoCollapseDelay,
      () {
        if (!mounted ||
            !_expanded) {
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

    setState(
      () {
        _expanded = !_expanded;
      },
    );
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
    return AnimatedSize(
      duration: _animationDuration,

      curve: Curves.easeInOutCubic,

      alignment: Alignment.topCenter,

      child: Container(
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
            color: Colors.white.withValues(
              alpha: 0.07,
            ),
          ),
        ),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            _buildHeader(),

            AnimatedCrossFade(
              duration: _animationDuration,

              sizeCurve: Curves.easeInOutCubic,

              firstCurve: Curves.easeOut,

              secondCurve: Curves.easeIn,

              crossFadeState: _expanded
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,

              firstChild: _buildExpandedContent(),

              secondChild: const SizedBox(
                width: double.infinity,

                height: 0,
              ),
            ),
          ],
        ),
      ),
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

          // ======================================================
          // EDIT BUTTON
          // ======================================================
          SizedBox(
            width: double.infinity,

            height: 34,

            child: OutlinedButton.icon(
              onPressed: _editing
                  ? null
                  : _handleEdit,

              icon: const Icon(
                Icons.tune_rounded,

                size: 15,
              ),

              label: const Text(
                'EDITAR PERFIL PROFISSIONAL',
              ),

              style: OutlinedButton.styleFrom(
                foregroundColor: widget.matchController.accentNeon,

                side: BorderSide(
                  color: widget.matchController.accentNeon.withValues(
                    alpha: 0.38,
                  ),
                ),

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    11,
                  ),
                ),

                textStyle: const TextStyle(
                  fontSize: 9,

                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
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

    super.dispose();
  }
}
