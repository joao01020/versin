import 'package:versin/modules/networking/call/views/widgets/global_call_banner.dart';

class NetworkingCallBannerData {
  final String callId;
  final String participantUserId;
  final GlobalCallBannerState state;
  final GlobalCallMediaType mediaType;
  final Duration? duration;
  final bool canAccept;
  final bool canReject;
  final bool canEnd;

  const NetworkingCallBannerData({
    required this.callId,
    required this.participantUserId,
    required this.state,
    required this.mediaType,
    required this.duration,
    required this.canAccept,
    required this.canReject,
    required this.canEnd,
  });
}
