import 'package:flutter/material.dart';

import 'package:versin/modules/settings/page/settings_page_coordinator.dart';
import 'package:versin/modules/settings/page/settings_page_view.dart';

// ============================================================
// SETTINGS PAGE
// ============================================================
//
// Composition root público.
//
// ============================================================

class SettingsPage extends StatefulWidget {
  static const String routeName = '/settings';

  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final SettingsPageCoordinator _coordinator;

  @override
  void initState() {
    super.initState();

    _coordinator = SettingsPageCoordinator();
  }

  @override
  Widget build(BuildContext context) {
    return const SettingsPageView();
  }

  @override
  void dispose() {
    _coordinator.dispose();

    super.dispose();
  }
}
