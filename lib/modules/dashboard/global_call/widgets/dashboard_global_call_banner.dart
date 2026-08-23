import 'package:flutter/material.dart';

import 'package:versin/modules/networking/call/views/widgets/global_call_banner.dart';

import '../controllers/dashboard_global_call_controller.dart';

// ============================================================
// DASHBOARD GLOBAL CALL BANNER
// ============================================================
//
// Widget responsável por:
//
// - observar DashboardGlobalCallController;
// - converter estado do controller para GlobalCallBanner;
// - resolver nome do participante;
// - disparar callbacks de navegação.
//
// Não acessa Supabase diretamente.
//
// ============================================================

class DashboardGlobalCallBanner
    extends
        StatelessWidget {
  // ============================================================
  // CONTROLLER
  // ============================================================

  final DashboardGlobalCallController controller;

  // ============================================================
  // CALLBACKS
  // ============================================================

  final Future<
    void
  >
  Function(
    String projectId,
  )
  onOpenCall;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  const DashboardGlobalCallBanner({
    super.key,
    required this.controller,
    required this.onOpenCall,
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
            if (!controller.hasCall) {
              return const SizedBox.shrink();
            }

            return _buildBanner();
          },
    );
  }

  // ============================================================
  // BANNER
  // ============================================================

  Widget _buildBanner() {
    final state = _resolveState();

    if (state ==
        GlobalCallBannerState.hidden) {
      return const SizedBox.shrink();
    }

    final mediaType =
        controller.mediaType ==
            'video'
        ? GlobalCallMediaType.video
        : GlobalCallMediaType.audio;

    return FutureBuilder<
      String
    >(
      future: controller.resolveParticipantName(),

      builder:
          (
            context,
            snapshot,
          ) {
            final participantName =
                snapshot.data ??
                'Membro da sessão';

            return GlobalCallBanner(
              state: state,

              mediaType: mediaType,

              participantName: participantName,

              ringingDuration: controller.ringingDuration,

              duration: controller.duration,

              onOpen: controller.projectId.isEmpty
                  ? null
                  : () {
                      onOpenCall(
                        controller.projectId,
                      );
                    },

              onAccept:
                  controller.isIncoming &&
                      controller.callId.isNotEmpty
                  ? () {
                      _accept();
                    }
                  : null,

              onReject:
                  controller.isIncoming &&
                      controller.callId.isNotEmpty
                  ? () {
                      _reject();
                    }
                  : null,

              onEnd:
                  (controller.isOutgoing ||
                          controller.isActive) &&
                      controller.callId.isNotEmpty
                  ? () {
                      _end();
                    }
                  : null,
            );
          },
    );
  }

  // ============================================================
  // RESOLVE STATE
  // ============================================================

  GlobalCallBannerState _resolveState() {
    if (controller.isEnding) {
      return GlobalCallBannerState.ending;
    }

    if (controller.isIncoming) {
      return GlobalCallBannerState.incoming;
    }

    if (controller.isOutgoing) {
      return GlobalCallBannerState.calling;
    }

    if (controller.isActive) {
      return GlobalCallBannerState.active;
    }

    return GlobalCallBannerState.hidden;
  }

  // ============================================================
  // ACCEPT
  // ============================================================

  Future<
    void
  >
  _accept() async {
    final projectId = controller.projectId;

    final accepted = await controller.accept();

    if (!accepted ||
        projectId.trim().isEmpty) {
      return;
    }

    await onOpenCall(
      projectId,
    );
  }

  // ============================================================
  // REJECT
  // ============================================================

  Future<
    void
  >
  _reject() async {
    await controller.reject();
  }

  // ============================================================
  // END
  // ============================================================

  Future<
    void
  >
  _end() async {
    await controller.end();
  }
}
