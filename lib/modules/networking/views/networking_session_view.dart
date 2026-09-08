import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:versin/modules/networking/page/networking_session_coordinator.dart';
import 'package:versin/modules/match/history/services/match_project_history_service.dart';
import 'package:versin/modules/match/quick/widgets/match_solo_project_dialog.dart';
import 'package:versin/modules/networking/recruitment/views/create_recruitment_view.dart';
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
  late Future<MatchQuickProjectTarget?> _quickTarget;
  String? _targetMembersSignature;
  final MatchProjectHistoryService _history = MatchProjectHistoryService();
  bool _checkingSolo = false;
  bool _soloDialogOpen = false;
  int? _lastSoloEvent;
  DateTime? _lastSoloCheck;
  Timer? _projectStateCheck;
  bool _closing = false;
  bool _checkingServer = false;
  DateTime? _lastServerCheck;

  Future<MatchQuickProjectTarget?> _resolveQuickTarget() async {
    try {
      return await MatchQuickProjectResolver.resolve(widget.projectId);
    } catch (error) {
      debugPrint('[NETWORKING] Alvo da conexão rápida: $error');
      return null;
    }
  }

  void _refreshQuickTarget(Map<String, dynamic> project) {
    final members =
        (project['members'] as List?)
            ?.map((value) => value.toString())
            .toList() ??
        <String>[];
    final signature = (List<String>.from(members)..sort()).join(',');
    if (signature == _targetMembersSignature) return;
    _targetMembersSignature = signature;
    final future = _resolveQuickTarget();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _quickTarget = future);
    });
  }

  Future<void> _checkSoloNotice() async {
    if (!mounted ||
        _closing ||
        _checkingSolo ||
        _soloDialogOpen ||
        ModalRoute.of(context)?.isCurrent != true)
      return;
    final project = _coordinator.controller.projectData;
    if (project == null ||
        project['origin'] != 'match' ||
        project['status'] != 'active')
      return;
    final me = Supabase.instance.client.auth.currentUser?.id;
    final members =
        (project['members'] as List?)
            ?.map((value) => value.toString())
            .toList() ??
        <String>[];
    if (members.length != 1 || members.first != me) return;
    _checkingSolo = true;
    try {
      final notice = await _history.soloStatus(widget.projectId);
      if (!mounted ||
          notice['pending'] != true ||
          ModalRoute.of(context)?.isCurrent != true)
        return;
      final eventId = (notice['event_id'] as num).toInt();
      if (_lastSoloEvent == eventId) return;
      _lastSoloEvent = eventId;
      _soloDialogOpen = true;
      try {
        await _showSoloChoices(notice, eventId);
      } finally {
        _soloDialogOpen = false;
      }
    } catch (error) {
      debugPrint('[NETWORKING] Aviso solo: $error');
    } finally {
      _checkingSolo = false;
    }
  }

  Future<void> _showSoloChoices(
    Map<String, dynamic> notice,
    int eventId,
  ) async {
    while (mounted && !_closing) {
      final choice = await MatchSoloProjectDialog.show(
        context: context,
        title: notice['title']?.toString() ?? 'Studio Session',
      );
      if (!mounted) return;
      if (choice == MatchSoloChoice.archive) {
        final archived = await _coordinator.requestArchiveProject(context);
        if (archived || !mounted) return;
        final current = await _history.soloStatus(widget.projectId);
        if (current['pending'] != true ||
            current['event_id']?.toString() != eventId.toString())
          return;
        continue;
      }
      try {
        await _history.acknowledgeSolo(widget.projectId, eventId);
      } on PostgrestException {
        // Um novo participante pode ter entrado enquanto o modal estava aberto.
        return;
      }
      if (!mounted) return;
      if (choice == MatchSoloChoice.find) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => CreateRecruitmentView(projectId: widget.projectId),
          ),
        );
      }
      return;
    }
  }

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
    final members =
        (project['members'] as List?)
            ?.map((value) => value.toString())
            .toSet() ??
        <String>{};
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
    _quickTarget = _resolveQuickTarget();
    _coordinator.initialize();
    _coordinator.controller.addListener(_checkProjectState);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _checkProjectState();
    });
    _projectStateCheck = Timer.periodic(const Duration(seconds: 2), (_) {
      _checkProjectState();
      final now = DateTime.now();
      if (_lastSoloCheck == null ||
          now.difference(_lastSoloCheck!) >= const Duration(seconds: 10)) {
        _lastSoloCheck = now;
        unawaited(_checkSoloNotice());
      }
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
