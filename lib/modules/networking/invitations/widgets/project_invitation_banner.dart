import 'dart:async';

import 'package:flutter/material.dart';

import '../controllers/project_invitation_controller.dart';
import '../models/project_invitation_model.dart';

// ============================================================
// PROJECT INVITATION BANNER
// ============================================================
//
// Banner global para convite de Studio Session.
//
// Exemplo:
//
// João Vitor está convidando você
// para participar da Studio Session.
//
// [RECUSAR] [ACEITAR]
//
// COMPORTAMENTO:
//
// - aparece imediatamente quando o convite chega;
// - permanece visível por alguns segundos;
// - depois sobe suavemente e desaparece;
// - NÃO remove o convite pendente;
// - NÃO altera o contador do badge;
// - aceitar/recusar continua sendo responsabilidade do controller.
//
// O Widget:
//
// - NÃO acessa Supabase;
// - NÃO executa RPC diretamente;
// - NÃO navega sozinho.
//
// Ele recebe callbacks do nível superior.
//
// ============================================================

class ProjectInvitationBanner
    extends
        StatefulWidget {
  // ============================================================
  // DATA
  // ============================================================

  final ProjectInvitationModel invitation;

  // ============================================================
  // STATE
  // ============================================================

  final bool isAccepting;

  final bool isRejecting;

  // ============================================================
  // AUTO HIDE
  // ============================================================

  final Duration visibleDuration;

  final Duration animationDuration;

  // ============================================================
  // CALLBACKS
  // ============================================================

  final Future<
    void
  >
  Function()?
  onAccept;

  final Future<
    void
  >
  Function()?
  onReject;

  final VoidCallback? onOpen;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  const ProjectInvitationBanner({
    super.key,
    required this.invitation,
    this.isAccepting = false,
    this.isRejecting = false,
    this.visibleDuration = const Duration(
      seconds: 6,
    ),
    this.animationDuration = const Duration(
      milliseconds: 320,
    ),
    this.onAccept,
    this.onReject,
    this.onOpen,
  });

  @override
  State<
    ProjectInvitationBanner
  >
  createState() => _ProjectInvitationBannerState();
}

// ============================================================
// STATE
// ============================================================

class _ProjectInvitationBannerState
    extends
        State<
          ProjectInvitationBanner
        > {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color _background = Color(
    0xFF121217,
  );

  static const Color _surface = Color(
    0xFF1A1A22,
  );

  static const Color _purple = Color(
    0xFF8B5CF6,
  );

  static const Color _purpleLight = Color(
    0xFFA78BFA,
  );

  static const Color _green = Color(
    0xFF34D399,
  );

  static const Color _red = Color(
    0xFFF87171,
  );

  // ============================================================
  // AUTO HIDE STATE
  // ============================================================

  Timer? _hideTimer;

  bool _visible = true;

  bool _collapsed = false;

  // Mantém o mesmo convite oculto caso a árvore recrie o banner
  // durante a mesma execução do app.
  static final Set<
    String
  >
  _autoHiddenInvitationIds =
      <
        String
      >{};

  // ============================================================
  // CURRENT ID
  // ============================================================

  String get _invitationId => widget.invitation.id.trim();

  bool get _isBusy =>
      widget.isAccepting ||
      widget.isRejecting;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    if (_invitationId.isNotEmpty &&
        _autoHiddenInvitationIds.contains(
          _invitationId,
        )) {
      _visible = false;
      _collapsed = true;

      return;
    }

    _startAutoHideTimer();
  }

  // ============================================================
  // DID UPDATE
  // ============================================================

  @override
  void didUpdateWidget(
    ProjectInvitationBanner oldWidget,
  ) {
    super.didUpdateWidget(
      oldWidget,
    );

    final oldId = oldWidget.invitation.id.trim();

    final newId = widget.invitation.id.trim();

    // ==========================================================
    // NOVO CONVITE
    // ==========================================================

    if (oldId !=
        newId) {
      _hideTimer?.cancel();

      if (newId.isNotEmpty &&
          _autoHiddenInvitationIds.contains(
            newId,
          )) {
        setState(
          () {
            _visible = false;
            _collapsed = true;
          },
        );

        return;
      }

      setState(
        () {
          _visible = true;
          _collapsed = false;
        },
      );

      _startAutoHideTimer();

      return;
    }

    // ==========================================================
    // PROCESSAMENTO
    // ==========================================================
    //
    // Enquanto aceita ou recusa, o banner não deve desaparecer.
    //
    // ==========================================================

    final wasBusy =
        oldWidget.isAccepting ||
        oldWidget.isRejecting;

    final isBusy =
        widget.isAccepting ||
        widget.isRejecting;

    if (!wasBusy &&
        isBusy) {
      _hideTimer?.cancel();

      _hideTimer = null;

      return;
    }

    if (wasBusy &&
        !isBusy &&
        _visible &&
        !_collapsed) {
      _startAutoHideTimer();
    }
  }

  // ============================================================
  // AUTO HIDE TIMER
  // ============================================================

  void _startAutoHideTimer() {
    _hideTimer?.cancel();

    if (_isBusy ||
        !_visible ||
        _collapsed) {
      return;
    }

    _hideTimer = Timer(
      widget.visibleDuration,
      _hideBanner,
    );
  }

  // ============================================================
  // HIDE BANNER
  // ============================================================

  void _hideBanner() {
    if (!mounted ||
        _isBusy ||
        !_visible ||
        _collapsed) {
      return;
    }

    final invitationId = _invitationId;

    if (invitationId.isNotEmpty) {
      _autoHiddenInvitationIds.add(
        invitationId,
      );
    }

    setState(
      () {
        _visible = false;
      },
    );

    // Após terminar a animação de subida, remove também o espaço
    // ocupado pelo banner.
    Future<
      void
    >.delayed(
      widget.animationDuration,
      () {
        if (!mounted) {
          return;
        }

        setState(
          () {
            _collapsed = true;
          },
        );
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    if (_collapsed) {
      return const SizedBox.shrink();
    }

    final inviterName = widget.invitation.inviterName.trim().isEmpty
        ? 'Membro'
        : widget.invitation.inviterName.trim();

    final projectTitle = widget.invitation.projectTitle.trim().isEmpty
        ? 'Studio Session'
        : widget.invitation.projectTitle.trim();

    return AnimatedSlide(
      offset: _visible
          ? Offset.zero
          : const Offset(
              0,
              -1.25,
            ),
      duration: widget.animationDuration,
      curve: Curves.easeInOutCubic,
      child: AnimatedOpacity(
        opacity: _visible
            ? 1
            : 0,
        duration: widget.animationDuration,
        curve: Curves.easeOut,
        child: SafeArea(
          minimum: const EdgeInsets.only(
            top: 8,
            left: 12,
            right: 12,
          ),
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(
                minHeight: 84,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: _background,
                borderRadius: BorderRadius.circular(
                  18,
                ),
                border: Border.all(
                  color: _purple.withValues(
                    alpha: 0.32,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: 0.36,
                    ),
                    blurRadius: 22,
                    offset: const Offset(
                      0,
                      8,
                    ),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ==============================================
                  // ICON
                  // ==============================================
                  _buildIcon(),

                  const SizedBox(
                    width: 12,
                  ),

                  // ==============================================
                  // CONTENT
                  // ==============================================
                  Expanded(
                    child: _buildContent(
                      inviterName: inviterName,
                      projectTitle: projectTitle,
                    ),
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  // ==============================================
                  // ACTIONS
                  // ==============================================
                  _buildActions(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ICON
  // ============================================================

  Widget _buildIcon() {
    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _purple.withValues(
          alpha: 0.14,
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: _purple.withValues(
            alpha: 0.28,
          ),
        ),
      ),
      child: const Icon(
        Icons.group_add_rounded,
        color: _purpleLight,
        size: 22,
      ),
    );
  }

  // ============================================================
  // CONTENT
  // ============================================================

  Widget _buildContent({
    required String inviterName,
    required String projectTitle,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ================================================
        // TITLE
        // ================================================
        const Text(
          'Convite para equipe',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.1,
          ),
        ),

        const SizedBox(
          height: 4,
        ),

        // ================================================
        // MESSAGE
        // ================================================
        RichText(
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          text: TextSpan(
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
              height: 1.35,
            ),
            children: [
              TextSpan(
                text: inviterName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const TextSpan(
                text: ' está convidando você para fazer parte de ',
              ),
              TextSpan(
                text: projectTitle,
                style: const TextStyle(
                  color: _purpleLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const TextSpan(
                text: '.',
              ),
            ],
          ),
        ),

        if (widget.onOpen !=
            null) ...[
          const SizedBox(
            height: 5,
          ),
          GestureDetector(
            onTap: widget.onOpen,
            child: const Text(
              'Ver equipe',
              style: TextStyle(
                color: _purpleLight,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  Widget _buildActions() {
    final busy =
        widget.isAccepting ||
        widget.isRejecting;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ================================================
        // REJECT
        // ================================================
        _buildRejectButton(
          busy,
        ),

        const SizedBox(
          width: 7,
        ),

        // ================================================
        // ACCEPT
        // ================================================
        _buildAcceptButton(
          busy,
        ),
      ],
    );
  }

  // ============================================================
  // REJECT
  // ============================================================

  Widget _buildRejectButton(
    bool busy,
  ) {
    return TextButton(
      onPressed:
          busy ||
              widget.onReject ==
                  null
          ? null
          : () {
              widget.onReject!();
            },
      style: TextButton.styleFrom(
        foregroundColor: _red,
        backgroundColor: _surface,
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 8,
        ),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            10,
          ),
        ),
      ),
      child: widget.isRejecting
          ? const SizedBox(
              width: 13,
              height: 13,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _red,
              ),
            )
          : const Text(
              'RECUSAR',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.45,
              ),
            ),
    );
  }

  // ============================================================
  // ACCEPT
  // ============================================================

  Widget _buildAcceptButton(
    bool busy,
  ) {
    return FilledButton(
      onPressed:
          busy ||
              widget.onAccept ==
                  null
          ? null
          : () {
              widget.onAccept!();
            },
      style: FilledButton.styleFrom(
        foregroundColor: Colors.black,
        backgroundColor: _green,
        disabledBackgroundColor: _green.withValues(
          alpha: 0.28,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 11,
          vertical: 8,
        ),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            10,
          ),
        ),
      ),
      child: widget.isAccepting
          ? const SizedBox(
              width: 13,
              height: 13,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.black,
              ),
            )
          : const Text(
              'ACEITAR',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.45,
              ),
            ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _hideTimer?.cancel();

    _hideTimer = null;

    super.dispose();
  }
}

// ============================================================
// PROJECT INVITATION CONTROLLER BUILDER
// ============================================================
//
// Widget auxiliar opcional.
//
// Permite usar diretamente:
//
// ProjectInvitationControllerBuilder(
//   controller: controller,
//   builder: (...),
// )
//
// sem repetir ListenableBuilder em todas as telas.
//
// ============================================================

class ProjectInvitationControllerBuilder
    extends
        StatelessWidget {
  final ProjectInvitationController controller;

  final Widget Function(
    BuildContext context,
    ProjectInvitationController controller,
  )
  builder;

  const ProjectInvitationControllerBuilder({
    super.key,
    required this.controller,
    required this.builder,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return ListenableBuilder(
      listenable: controller,

      builder:
          (
            context,
            _,
          ) {
            return builder(
              context,
              controller,
            );
          },
    );
  }
}
