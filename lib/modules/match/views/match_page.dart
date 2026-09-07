import 'dart:async';

import 'package:flutter/material.dart';

import 'package:versin/modules/match/page/match_page_coordinator.dart';
import 'package:versin/modules/match/page/match_page_view.dart';
import 'package:versin/modules/match/page/dialogs/match_confirmation_dialog.dart';
import 'package:versin/modules/networking/views/networking_session_view.dart';

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
  bool _confirmationBusy = false;
  bool _confirmationScheduled = false;

  void _scheduleConfirmation() {
    if (!mounted ||
        _confirmationBusy ||
        _confirmationScheduled ||
        !_coordinator.hasPendingConfirmation)
      return;
    _confirmationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _confirmationScheduled = false;
      if (!mounted ||
          _confirmationBusy ||
          ModalRoute.of(context)?.isCurrent != true)
        return;
      unawaited(_showNextConfirmation());
    });
  }

  Future<void> _showNextConfirmation() async {
    if (_confirmationBusy || !mounted) return;
    final confirmation = _coordinator.takeNextConfirmation();
    if (confirmation == null) return;
    _confirmationBusy = true;
    try {
      await _coordinator.acknowledgeConfirmation(confirmation);
      if (!mounted) return;
      final action = await showDialog<MatchConfirmationAction>(
        context: context,
        barrierDismissible: false,
        builder: (_) => MatchConfirmationDialog(confirmation: confirmation),
      );
      if (!mounted) return;
      if (action == MatchConfirmationAction.viewProject) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                NetworkingSessionView(projectId: confirmation.projectId),
          ),
        );
      }
    } finally {
      _confirmationBusy = false;
      if (mounted) _scheduleConfirmation();
    }
  }

  @override
  void initState() {
    super.initState();

    _coordinator = MatchPageCoordinator(
      targetProjectId: widget.targetProjectId,
      targetProjectTitle: widget.targetProjectTitle,
    );

    _coordinator.addListener(_scheduleConfirmation);
    unawaited(_coordinator.initialize());
  }

  @override
  Widget build(BuildContext context) {
    _scheduleConfirmation();
    return AnimatedBuilder(
      animation: _coordinator,
      builder: (context, _) {
        return MatchPageView(coordinator: _coordinator);
      },
    );
  }

  @override
  void dispose() {
    _coordinator.removeListener(_scheduleConfirmation);
    _coordinator.dispose();

    super.dispose();
  }
}
