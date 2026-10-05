import 'package:flutter/material.dart';

import 'package:versin/modules/studio/page/studio_page_coordinator.dart';
import 'package:versin/modules/studio/page/studio_page_view.dart';

// ============================================================
// STUDIO PAGE
// ============================================================
//
// Composition root do Studio.
//
// Responsabilidade:
//
// - criar o coordinator;
// - inicializar depois do primeiro frame;
// - observar mudanças;
// - entregar o coordinator para a View;
// - remover listeners pertencentes à página.
//
// NÃO:
//
// - acessa GetIt diretamente;
// - registra analytics;
// - abre dialogs;
// - controla janelas externas;
// - desenha workspace;
// - conhece Timeline / Mind Map internamente.
//
// ============================================================

class StudioPage extends StatefulWidget {
  const StudioPage({super.key});

  @override
  State<StudioPage> createState() => _StudioPageState();
}

class _StudioPageState extends State<StudioPage> {
  late final StudioPageCoordinator _coordinator;

  @override
  void initState() {
    super.initState();

    _coordinator = StudioPageCoordinator();

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
        return StudioPageView(coordinator: _coordinator);
      },
    );
  }

  @override
  void dispose() {
    _coordinator.dispose();

    super.dispose();
  }
}
