import 'package:flutter/material.dart';

import 'package:versin/modules/networking/chat/widgets/global_chat_banner.dart';

import '../controllers/dashboard_global_chat_controller.dart';

// ============================================================
// DASHBOARD GLOBAL CHAT BANNER
// ============================================================
//
// Ponte visual entre:
//
// DashboardGlobalChatController
//
// e
//
// GlobalChatBanner.
//
// Responsabilidades:
//
// - observar notificações;
// - resolver nome;
// - escolher tipo message/audio;
// - exibir quantidade não lida;
// - encaminhar abertura;
// - encaminhar dismiss.
//
// NÃO:
//
// - abre ChatView diretamente;
// - acessa Supabase;
// - resolve nomes diretamente;
// - controla GlobalChatController diretamente.
//
// ============================================================

class DashboardGlobalChatBanner
    extends
        StatelessWidget {
  // ============================================================
  // CONTROLLER
  // ============================================================

  final DashboardGlobalChatController controller;

  // ============================================================
  // OPEN
  // ============================================================

  final Future<
    void
  >
  Function(
    String projectId,
  )
  onOpen;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  const DashboardGlobalChatBanner({
    super.key,
    required this.controller,
    required this.onOpen,
  });

  // ============================================================
  // BUILD
  // ============================================================

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
            // ================================================
            // SEM NOTIFICAÇÃO
            // ================================================

            if (!controller.hasNotification) {
              return const SizedBox.shrink();
            }

            // ================================================
            // PROJECT
            // ================================================

            final projectId = controller.latestProjectId;

            if (projectId ==
                    null ||
                projectId.isEmpty) {
              return const SizedBox.shrink();
            }

            // ================================================
            // MESSAGE
            // ================================================

            if (!controller.hasMessage) {
              return const SizedBox.shrink();
            }

            // ================================================
            // NAME
            // ================================================

            return FutureBuilder<
              String
            >(
              future: controller.resolveSenderName(),

              builder:
                  (
                    context,
                    snapshot,
                  ) {
                    final senderName =
                        snapshot.data ??
                        controller.senderName;

                    // ========================================
                    // GLOBAL BANNER
                    // ========================================

                    return GlobalChatBanner(
                      type: controller.latestIsAudio
                          ? GlobalChatBannerType.audio
                          : GlobalChatBannerType.message,

                      senderName: senderName,

                      preview: controller.preview,

                      unreadCount: controller.unreadCount,

                      onOpen: () {
                        _open(
                          projectId,
                        );
                      },

                      onDismiss: controller.dismissBanner,
                    );
                  },
            );
          },
    );
  }

  // ============================================================
  // OPEN
  // ============================================================

  Future<
    void
  >
  _open(
    String projectId,
  ) async {
    final normalizedProjectId = projectId.trim();

    if (normalizedProjectId.isEmpty) {
      return;
    }

    await onOpen(
      normalizedProjectId,
    );
  }
}
