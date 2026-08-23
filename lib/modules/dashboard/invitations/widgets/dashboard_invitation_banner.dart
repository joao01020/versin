import 'package:flutter/material.dart';

import 'package:versin/modules/networking/invitations/widgets/project_invitation_banner.dart';

import '../controllers/dashboard_invitation_controller.dart';

// ============================================================
// DASHBOARD INVITATION BANNER
// ============================================================
//
// Responsável pela integração visual entre:
//
// DashboardInvitationController
//
// e
//
// ProjectInvitationBanner.
//
// Faz:
//
// - observar convite atual;
// - mostrar banner;
// - aceitar;
// - recusar;
// - mostrar feedback;
// - solicitar abertura do projeto aceito.
//
// NÃO:
//
// - acessa Supabase;
// - conhece ProjectInvitationController diretamente;
// - cria/rejeita convite diretamente;
// - abre NetworkingSessionView diretamente.
//
// ============================================================

class DashboardInvitationBanner extends StatelessWidget {
  // ============================================================
  // CONTROLLER
  // ============================================================

  final DashboardInvitationController controller;

  // ============================================================
  // OPEN PROJECT
  // ============================================================

  final Future<void> Function(String projectId) onOpenProject;

  // ============================================================
  // INTERACTION GUARD
  // ============================================================
  //
  // Pode ser usado pelo Dashboard para impedir a ação enquanto
  // ainda falta nome público.
  //
  // Retorne true para permitir.
  //
  // ============================================================

  final bool Function()? canInteract;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  const DashboardInvitationBanner({
    super.key,
    required this.controller,
    required this.onOpenProject,
    this.canInteract,
  });

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,

      builder: (context, _) {
        final invitation = controller.currentInvitation;

        if (invitation == null) {
          return const SizedBox.shrink();
        }

        return ProjectInvitationBanner(
          invitation: invitation,

          isAccepting: controller.isAccepting,

          isRejecting: controller.isRejecting,

          onAccept: () async {
            if (!_canInteract()) {
              return;
            }

            await _accept(context);
          },

          onReject: () async {
            if (!_canInteract()) {
              return;
            }

            await _reject(context);
          },
        );
      },
    );
  }

  // ============================================================
  // CAN INTERACT
  // ============================================================

  bool _canInteract() {
    final guard = canInteract;

    if (guard == null) {
      return true;
    }

    return guard();
  }

  // ============================================================
  // ACCEPT
  // ============================================================

  Future<void> _accept(BuildContext context) async {
    final invitation = controller.currentInvitation;

    if (invitation == null || controller.isBusy) {
      return;
    }

    final result = await controller.accept(invitation);

    if (!context.mounted) {
      return;
    }

    // ==========================================================
    // ERROR
    // ==========================================================

    if (result.failed) {
      _showMessage(context, result.message, isError: true);

      return;
    }

    // ==========================================================
    // SUCCESS
    // ==========================================================

    _showMessage(context, result.message, success: true);

    final projectId = result.projectId?.trim();

    if (projectId == null || projectId.isEmpty) {
      return;
    }

    controller.clearAcceptedProject();

    await onOpenProject(projectId);
  }

  // ============================================================
  // REJECT
  // ============================================================

  Future<void> _reject(BuildContext context) async {
    final invitation = controller.currentInvitation;

    if (invitation == null || controller.isBusy) {
      return;
    }

    final result = await controller.reject(invitation);

    if (!context.mounted) {
      return;
    }

    if (result.failed) {
      _showMessage(context, result.message, isError: true);

      return;
    }

    _showMessage(context, result.message);
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    BuildContext context,
    String message, {
    bool isError = false,
    bool success = false,
  }) {
    final normalizedMessage = message.trim();

    if (normalizedMessage.isEmpty) {
      return;
    }

    final Color? backgroundColor;

    if (isError) {
      backgroundColor = Colors.red.shade900;
    } else if (success) {
      backgroundColor = Colors.green.shade800;
    } else {
      backgroundColor = null;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(normalizedMessage),

          backgroundColor: backgroundColor,
        ),
      );
  }
}
