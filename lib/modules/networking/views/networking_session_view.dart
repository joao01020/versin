import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:versin/modules/networking/page/networking_session_coordinator.dart';
import 'package:versin/modules/match/quick/services/match_quick_project_resolver.dart';
import 'package:versin/modules/match/quick/services/match_quick_connection_service.dart';
import 'package:versin/modules/match/quick/widgets/match_quick_connection_panel.dart';
import 'package:versin/modules/match/views/match_page.dart';
import 'package:versin/modules/networking/page/networking_session_page_view.dart';

class NetworkingSessionView extends StatefulWidget {
  final String projectId;

  const NetworkingSessionView({super.key, required this.projectId});

  @override
  State<NetworkingSessionView> createState() => _NetworkingSessionViewState();
}

class _NetworkingSessionViewState extends State<NetworkingSessionView> {
  late final NetworkingSessionCoordinator _coordinator;
  late final Future<MatchQuickProjectTarget?> _quickTarget;
  Timer? _projectStateCheck;
  bool _closing = false;
  bool _checkingServer = false;
  DateTime? _lastServerCheck;

  Future<void> _checkServerProjectState() async {
    if (!mounted || _closing || _checkingServer) return;
    final project = _coordinator.controller.projectData;
    if (project == null || project['origin'] != 'match') return;
    _checkingServer = true;
    try {
      final status = await MatchQuickConnectionService.instance
          .previewCollaboration(widget.projectId);
      if (!mounted) return;
      if (status['status'] != 'active') {
        await _finishCurrentView();
      }
    } on PostgrestException catch (error) {
      if (error.code == 'P0001' &&
          error.message.contains('Projeto de Match não encontrado')) {
        await _finishCurrentView();
      } else {
        debugPrint('[NETWORKING] Verificação de projeto: ${error.message}');
      }
    } catch (error) {
      debugPrint('[NETWORKING] Verificação de projeto: $error');
    } finally {
      _checkingServer = false;
    }
  }

  void _checkProjectState() {
    if (!mounted || _closing) return;
    final project = _coordinator.controller.projectData;
    if (project == null) {
      if (!_coordinator.controller.isLoading &&
          ModalRoute.of(context)?.isCurrent == true) {
        unawaited(_finishCurrentView());
      }
      return;
    }
    final me = Supabase.instance.client.auth.currentUser?.id;
    final members = (project['members'] as List?)
        ?.map((value) => value.toString()).toSet() ?? <String>{};
    if (project['status'] == 'active' && me != null && members.contains(me)) {
      return;
    }
    if (ModalRoute.of(context)?.isCurrent != true) return;
    unawaited(_finishCurrentView());
  }

  Future<void> _finishCurrentView() async {
    if (!mounted || _closing) return;
    if (ModalRoute.of(context)?.isCurrent != true) return;
    _closing = true;
    try {
      await _coordinator.handleCollaborationFinished(context);
    } finally {
      // If navigation was temporarily blocked, the cached project state
      // will be checked again without another database request.
      if (mounted) _closing = false;
    }
  }


  @override
  void initState() {
    super.initState();

    _coordinator = NetworkingSessionCoordinator(projectId: widget.projectId);
    _quickTarget = MatchQuickProjectResolver.resolve(widget.projectId);
    _coordinator.initialize();
    _coordinator.controller.addListener(_checkProjectState);
    _projectStateCheck = Timer.periodic(const Duration(seconds: 2), (_) {
      _checkProjectState();
      final now = DateTime.now();
      if (_lastServerCheck == null ||
          now.difference(_lastServerCheck!) >= const Duration(seconds: 15)) {
        _lastServerCheck = now;
        unawaited(_checkServerProjectState());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _coordinator,
      builder: (context, _) {
        return FutureBuilder<MatchQuickProjectTarget?>(
          future: _quickTarget,
          builder: (context, snapshot) {
            final target = snapshot.data;
            return NetworkingSessionPageView(
              coordinator: _coordinator,
              quickConnectionPanel: MatchQuickConnectionPanel(
                projectId: widget.projectId,
                currentProjectId: widget.projectId,
                targetId: target?.userId,
                peerName: target?.name,
                onOpenProject: (projectId) async {
                  if (projectId == widget.projectId) return;
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          NetworkingSessionView(projectId: projectId),
                    ),
                  );
                },
                onCollaborationFinished: (projectId) async {
                  if (projectId == widget.projectId) {
                    await _finishCurrentView();
                  }
                },
                onResume: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const MatchPage()),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _projectStateCheck?.cancel();
    _coordinator.controller.removeListener(_checkProjectState);
    _coordinator.dispose();
    super.dispose();
  }
}
