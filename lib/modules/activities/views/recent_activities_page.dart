import 'package:flutter/material.dart';

import 'package:versin/modules/activities/page/recent_activities_page_coordinator.dart';
import 'package:versin/modules/activities/page/recent_activities_page_view.dart';

class RecentActivitiesPage extends StatefulWidget {
  const RecentActivitiesPage({super.key});

  @override
  State<RecentActivitiesPage> createState() => _RecentActivitiesPageState();
}

class _RecentActivitiesPageState extends State<RecentActivitiesPage> {
  late final RecentActivitiesPageCoordinator _coordinator;

  @override
  void initState() {
    super.initState();

    _coordinator = RecentActivitiesPageCoordinator();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      _coordinator.initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _coordinator,
      builder: (context, _) {
        return RecentActivitiesPageView(coordinator: _coordinator);
      },
    );
  }

  @override
  void dispose() {
    _coordinator.dispose();

    super.dispose();
  }
}
