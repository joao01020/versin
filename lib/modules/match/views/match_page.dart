import 'dart:async';

import 'package:flutter/material.dart';

import 'package:versin/modules/match/page/match_page_coordinator.dart';
import 'package:versin/modules/match/models/match_discovery_mode.dart';
import 'package:versin/modules/match/quick/services/match_quick_connection_service.dart';
import 'package:versin/modules/match/quick/widgets/match_quick_connection_panel.dart';
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
  final MatchQuickConnectionService _quick = MatchQuickConnectionService.instance;

  Future<void> _openQuickProject(String projectId) async {
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => NetworkingSessionView(projectId: projectId),
    ));
    if (mounted) {
      await _quick.refresh();
      await _coordinator.availabilityController.refresh();
    }
  }

  Future<void> _refreshQuickAvailability() async {
    if (!mounted || _coordinator.availabilityController.isLoading) return;
    await _coordinator.availabilityController.refresh();
  }

  Future<void> _resumeAgora() async {
    if (!mounted) return;
    await _coordinator.handleDiscoveryModeSelected(
      context, MatchDiscoveryMode.global,
    );
  }


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
        builder: (_) => MatchConfirmationDialog(
          confirmation: confirmation,
          allowQuickStart: _coordinator.matchController.discoveryMode ==
                  MatchDiscoveryMode.global &&
              _coordinator.availabilityController.isActive &&
              !_quick.isInSession,
        ),
      );
      if (!mounted) return;
      if (action == MatchConfirmationAction.startNow) {
        try {
          await _quick.invite(confirmation.projectId, confirmation.other.id);
        } catch (error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error.toString())),
            );
          }
        }
      }
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
    _quick.watch();
    unawaited(_coordinator.initialize());
  }

  @override
  Widget build(BuildContext context) {
    _scheduleConfirmation();
    return AnimatedBuilder(
      animation: Listenable.merge([_coordinator, _quick]),
      builder: (context, _) {
        final active = _quick.isInSession;
        final panel = MatchQuickConnectionPanel(
          onOpenProject: _openQuickProject,
          onAvailabilityChanged: _refreshQuickAvailability,
          onResume: _resumeAgora,
        );
        if (active) {
          return Scaffold(
            backgroundColor: const Color(0xFF0F0F0F),
            appBar: AppBar(title: const Text('Em conexão')),
            body: SafeArea(child: SingleChildScrollView(child: panel)),
          );
        }
        return Column(
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: SingleChildScrollView(child: panel),
            ),
            Expanded(child: MatchPageView(coordinator: _coordinator)),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _coordinator.removeListener(_scheduleConfirmation);
    _quick.unwatch();
    _coordinator.dispose();

    super.dispose();
  }
}
