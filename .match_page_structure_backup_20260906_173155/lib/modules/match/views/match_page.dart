import 'dart:async';

import 'package:flutter/material.dart';

import 'package:versin/modules/match/presentation/match_page_coordinator.dart';
import 'package:versin/modules/match/presentation/match_page_view.dart';

// ============================================================
// MATCH PAGE
// ============================================================
//
// RESPONSABILIDADE:
//
// - criar o coordinator da página;
// - iniciar o fluxo;
// - observar o estado;
// - entregar estado/callbacks para a View;
// - encerrar recursos pertencentes à página.
//
// NÃO:
//
// - conhece Supabase;
// - cria controllers de feature;
// - abre dialogs/sheets;
// - executa lógica de localização;
// - executa lógica de disponibilidade;
// - executa busca;
// - executa fluxo de demo;
// - contém layout da tela.
//
// ============================================================

class MatchPage extends StatefulWidget {
  static const String routeName = '/match';

  final String? targetProjectId;
  final String? targetProjectTitle;

  const MatchPage({super.key, this.targetProjectId, this.targetProjectTitle});

  @override
  State<MatchPage> createState() => _MatchPageState();
}

class _MatchPageState extends State<MatchPage> {
  late final MatchPageCoordinator _coordinator;

  @override
  void initState() {
    super.initState();

    _coordinator = MatchPageCoordinator(
      targetProjectId: widget.targetProjectId,
      targetProjectTitle: widget.targetProjectTitle,
    );

    unawaited(_coordinator.initialize());
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _coordinator,
      builder: (context, _) {
        return MatchPageView(coordinator: _coordinator);
      },
    );
  }

  @override
  void dispose() {
    _coordinator.dispose();

    super.dispose();
  }
}
