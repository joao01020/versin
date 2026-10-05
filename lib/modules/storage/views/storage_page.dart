import 'package:flutter/material.dart';

import 'package:versin/modules/storage/page/storage_page_coordinator.dart';
import 'package:versin/modules/storage/page/storage_page_view.dart';

class StoragePage extends StatefulWidget {
  const StoragePage({super.key});

  @override
  State<StoragePage> createState() => _StoragePageState();
}

class _StoragePageState extends State<StoragePage>
    with SingleTickerProviderStateMixin {
  late final StoragePageCoordinator _coordinator;

  @override
  void initState() {
    super.initState();

    _coordinator = StoragePageCoordinator(vsync: this);

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
        return StoragePageView(coordinator: _coordinator);
      },
    );
  }

  @override
  void dispose() {
    _coordinator.dispose();

    super.dispose();
  }
}
