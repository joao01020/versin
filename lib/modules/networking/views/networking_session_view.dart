import 'package:flutter/material.dart';

import 'package:versin/modules/networking/page/networking_session_coordinator.dart';
import 'package:versin/modules/networking/page/networking_session_page_view.dart';

class NetworkingSessionView extends StatefulWidget {
  final String projectId;

  const NetworkingSessionView({super.key, required this.projectId});

  @override
  State<NetworkingSessionView> createState() => _NetworkingSessionViewState();
}

class _NetworkingSessionViewState extends State<NetworkingSessionView> {
  late final NetworkingSessionCoordinator _coordinator;

  @override
  void initState() {
    super.initState();

    _coordinator = NetworkingSessionCoordinator(projectId: widget.projectId);

    _coordinator.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _coordinator,
      builder: (context, _) {
        return NetworkingSessionPageView(coordinator: _coordinator);
      },
    );
  }

  @override
  void dispose() {
    _coordinator.dispose();

    super.dispose();
  }
}
