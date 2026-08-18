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
        StatelessWidget {
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
    this.onAccept,
    this.onReject,
    this.onOpen,
  });

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
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final inviterName = invitation.inviterName.trim().isEmpty
        ? 'Membro'
        : invitation.inviterName.trim();

    final projectTitle = invitation.projectTitle.trim().isEmpty
        ? 'Studio Session'
        : invitation.projectTitle.trim();

    return SafeArea(
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

        if (onOpen !=
            null) ...[
          const SizedBox(
            height: 5,
          ),

          GestureDetector(
            onTap: onOpen,

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
        isAccepting ||
        isRejecting;

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
              onReject ==
                  null
          ? null
          : () {
              onReject!();
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

      child: isRejecting
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
              onAccept ==
                  null
          ? null
          : () {
              onAccept!();
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

      child: isAccepting
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
