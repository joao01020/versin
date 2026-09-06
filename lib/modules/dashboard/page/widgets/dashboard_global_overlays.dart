import 'package:flutter/material.dart';

import 'package:versin/modules/dashboard/global_call/controllers/dashboard_global_call_controller.dart';
import 'package:versin/modules/dashboard/global_call/widgets/dashboard_global_call_banner.dart';
import 'package:versin/modules/dashboard/global_chat/controllers/dashboard_global_chat_controller.dart';
import 'package:versin/modules/dashboard/global_chat/widgets/dashboard_global_chat_banner.dart';
import 'package:versin/modules/dashboard/invitations/controllers/dashboard_invitation_controller.dart';
import 'package:versin/modules/dashboard/invitations/widgets/dashboard_invitation_banner.dart';

// ============================================================
// DASHBOARD GLOBAL OVERLAYS
// ============================================================
//
// Agrupa os banners que ficam acima do conteúdo:
//
// - convites;
// - chamadas;
// - chat global.
//
// Cada banner continua observando seu próprio controller.
//
// ============================================================

class DashboardGlobalOverlays extends StatelessWidget {
  final DashboardInvitationController invitationController;

  final DashboardGlobalCallController globalCallController;

  final DashboardGlobalChatController globalChatController;

  final bool Function() canInteract;

  final Future<void> Function(String projectId) onOpenProject;

  final Future<void> Function(String projectId) onOpenCall;

  final Future<void> Function(String projectId) onOpenChat;

  const DashboardGlobalOverlays({
    super.key,
    required this.invitationController,
    required this.globalCallController,
    required this.globalChatController,
    required this.canInteract,
    required this.onOpenProject,
    required this.onOpenCall,
    required this.onOpenChat,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DashboardInvitationBanner(
          controller: invitationController,
          canInteract: canInteract,
          onOpenProject: onOpenProject,
        ),
        DashboardGlobalCallBanner(
          controller: globalCallController,
          onOpenCall: onOpenCall,
        ),
        DashboardGlobalChatBanner(
          controller: globalChatController,
          onOpen: onOpenChat,
        ),
      ],
    );
  }
}
