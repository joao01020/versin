import 'dart:async';

import 'package:flutter/material.dart';

import 'package:versin/modules/networking/call/views/widgets/global_call_banner.dart';
import 'package:versin/modules/networking/chat/widgets/global_chat_banner.dart';
import 'package:versin/modules/networking/invitations/widgets/project_invitation_banner.dart';
import 'package:versin/modules/networking/page/networking_session_coordinator.dart';

class NetworkingSessionOverlays extends StatelessWidget {
  final NetworkingSessionCoordinator coordinator;

  const NetworkingSessionOverlays({super.key, required this.coordinator});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ProjectInvitationOverlay(coordinator: coordinator),
        _GlobalCallOverlay(coordinator: coordinator),
        _GlobalChatOverlay(coordinator: coordinator),
      ],
    );
  }
}

class _ProjectInvitationOverlay extends StatelessWidget {
  final NetworkingSessionCoordinator coordinator;

  const _ProjectInvitationOverlay({required this.coordinator});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: coordinator.invitationController,
      builder: (context, _) {
        final invitation = coordinator.invitationController.currentInvitation;

        if (invitation == null) {
          return const SizedBox.shrink();
        }

        return ProjectInvitationBanner(
          invitation: invitation,
          isAccepting: coordinator.invitationController.isAccepting,
          isRejecting: coordinator.invitationController.isRejecting,
          onAccept: () async {
            await coordinator.acceptProjectInvitation(context, invitation);
          },
          onReject: () async {
            await coordinator.rejectProjectInvitation(context, invitation);
          },
        );
      },
    );
  }
}

class _GlobalChatOverlay extends StatelessWidget {
  final NetworkingSessionCoordinator coordinator;

  const _GlobalChatOverlay({required this.coordinator});

  @override
  Widget build(BuildContext context) {
    final controller = coordinator.globalChatController;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (!controller.hasNotification) {
          return const SizedBox.shrink();
        }

        final latestMessage = controller.latestMessage;

        if (latestMessage == null) {
          return const SizedBox.shrink();
        }

        final senderId = latestMessage.senderId.trim();

        return FutureBuilder<String>(
          future: coordinator.resolveChatSenderName(senderId),
          builder: (context, snapshot) {
            final resolvedName =
                snapshot.data ??
                coordinator.cachedName(senderId) ??
                controller.senderName;

            return GlobalChatBanner(
              type: controller.latestIsAudio
                  ? GlobalChatBannerType.audio
                  : GlobalChatBannerType.message,
              senderName: resolvedName,
              preview: controller.preview,
              unreadCount: controller.unreadCount,
              onOpen: () {
                unawaited(coordinator.openChat(context));
              },
              onDismiss: controller.dismissBanner,
            );
          },
        );
      },
    );
  }
}

class _GlobalCallOverlay extends StatelessWidget {
  final NetworkingSessionCoordinator coordinator;

  const _GlobalCallOverlay({required this.coordinator});

  @override
  Widget build(BuildContext context) {
    if (coordinator.currentUserId == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: coordinator.projectCallsStream,
      builder: (context, snapshot) {
        final rows = snapshot.data ?? const <Map<String, dynamic>>[];

        final activeRow = coordinator.selectActiveCallRow(rows);

        if (activeRow == null) {
          return const SizedBox.shrink();
        }

        final data = coordinator.callBannerDataFor(activeRow);

        if (data == null) {
          return const SizedBox.shrink();
        }

        return FutureBuilder<String>(
          future: coordinator.resolveCallParticipantName(
            data.participantUserId,
          ),
          builder: (context, snapshot) {
            final participantName =
                snapshot.data ??
                coordinator.cachedName(data.participantUserId) ??
                'Membro da sessão';

            return GlobalCallBanner(
              state: data.state,
              mediaType: data.mediaType,
              participantName: participantName,
              duration: data.duration,
              onOpen: () {
                unawaited(
                  coordinator.openCall(
                    context,
                    participantName: participantName,
                  ),
                );
              },
              onAccept: data.canAccept
                  ? () {
                      unawaited(
                        coordinator.acceptGlobalCall(
                          context,
                          data.callId,
                          participantName,
                        ),
                      );
                    }
                  : null,
              onReject: data.canReject
                  ? () {
                      unawaited(coordinator.rejectGlobalCall(data.callId));
                    }
                  : null,
              onEnd: data.canEnd
                  ? () {
                      unawaited(coordinator.endGlobalCall(data.callId));
                    }
                  : null,
            );
          },
        );
      },
    );
  }
}
