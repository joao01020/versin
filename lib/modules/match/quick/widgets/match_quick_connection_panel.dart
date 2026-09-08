import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/match_quick_connection_service.dart';
import 'match_collaboration_confirmation_dialog.dart';

/// Estado compacto da conexão rápida. Não altera projetos ou chamadas.
class MatchQuickConnectionPanel extends StatefulWidget {
  final String? projectId;
  final String? targetId;
  final String? peerName;
  final Future<void> Function(String projectId)? onOpenProject;
  final Future<void> Function()? onAvailabilityChanged;
  final Future<void> Function()? onResume;
  final Future<void> Function(String projectId)? onCollaborationFinished;
  final bool showWhenInactive;

  /// Informa quando o painel já está dentro do Networking deste projeto.
  /// Mantém o construtor anterior compatível com as outras telas.
  final String? currentProjectId;

  const MatchQuickConnectionPanel({
    super.key,
    this.projectId,
    this.targetId,
    this.peerName,
    this.onOpenProject,
    this.onAvailabilityChanged,
    this.onResume,
    this.onCollaborationFinished,
    this.showWhenInactive = false,
    this.currentProjectId,
  });

  @override
  State<MatchQuickConnectionPanel> createState() =>
      _MatchQuickConnectionPanelState();
}

class _MatchQuickConnectionPanelState extends State<MatchQuickConnectionPanel> {
  final MatchQuickConnectionService service =
      MatchQuickConnectionService.instance;

  bool _working = false;
  bool _detailsExpanded = false;
  Timer? _clock;

  static const Color _surface = Color(0xFF1C1C22);
  static const Color _border = Color(0xFF34303E);
  static const Color _muted = Color(0xFF9BA1AD);
  static const Color _success = Color(0xFF34D399);

  @override
  void initState() {
    super.initState();
    service.watch();
    // Apenas atualiza o texto do prazo recebido do servidor.
    // Não decrementa nem modifica o tempo persistido.
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && service.isAvailable) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    service.unwatch();
    super.dispose();
  }

  String _error(Object error) =>
      error is PostgrestException ? error.message : error.toString();

  Future<bool> _run(Future<void> Function() action) async {
    if (_working || service.busy) return false;
    setState(() => _working = true);
    try {
      await action();
      await widget.onAvailabilityChanged?.call();
      return true;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.maybeOf(
          context,
        )?.showSnackBar(SnackBar(content: Text(_error(error))));
      }
      return false;
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _open(String? projectId) async {
    if (projectId == null || projectId.isEmpty) return;
    if (projectId == widget.currentProjectId) return;
    await widget.onOpenProject?.call(projectId);
  }

  Future<void> _end() async {
    final projectId = service.projectId ?? widget.projectId;
    if (projectId == null || projectId.isEmpty) return;
    Map<String, dynamic>? preview;
    final inspected = await _run(() async {
      preview = await service.previewCollaboration(projectId);
    });
    if (!inspected || !mounted || preview == null) return;
    final confirmed = await MatchCollaborationConfirmationDialog.show(
      context: context, preview: preview!,
    );
    if (!confirmed || !mounted) return;
    final completed = await _run(() async {
      await service.finishCollaboration(
        projectId,
        expectedMembers: (preview!['member_count'] as num).toInt(),
        expectedHasWork: preview!['has_work'] == true,
      );
    });
    if (completed && mounted) {
      await widget.onCollaborationFinished?.call(projectId);
    }
  }

  Future<void> _respond(Map<String, dynamic> invitation, bool accept) async {
    String? projectToOpen;
    String? projectFinished;
    final completed = await _run(() async {
      final result = await service.respond(invitation['id'].toString(), accept);
      if (accept && result['status'] == 'accepted') {
        projectToOpen = result['project_id']?.toString();
      }
      final collaboration = result['collaboration'];
      if (collaboration is Map && collaboration['action'] == 'closed') {
        projectFinished = collaboration['project_id']?.toString();
      }
    });
    if (!completed || !mounted) return;
    if (projectFinished != null) {
      await widget.onCollaborationFinished?.call(projectFinished!);
    } else {
      await _open(projectToOpen);
    }
  }

  Future<void> _resume() async {
    final completed = await _run(service.resume);
    if (completed && mounted && service.isAvailable) {
      await widget.onResume?.call();
    }
  }

  int get _remainingSeconds {
    if (!service.isAvailable) return service.remainingSeconds;
    final raw = service.data['available_until'];
    final deadline = raw == null ? null : DateTime.tryParse(raw.toString());
    if (deadline == null) return service.remainingSeconds;
    final seconds = deadline.difference(DateTime.now()).inSeconds;
    return seconds < 0 ? 0 : seconds;
  }

  String _remainingLabel() {
    final seconds = _remainingSeconds;
    if (seconds <= 0) return 'Tempo restante esgotado';
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) {
      return '$hours h ${minutes.toString().padLeft(2, '0')} min restantes';
    }
    if (minutes > 0) return '$minutes min restantes';
    return '$seconds s restantes';
  }

  String _name(Map<String, dynamic> invitation) {
    final value = invitation['name']?.toString().trim() ?? '';
    return value.isEmpty ? 'Um profissional' : value;
  }

  Widget _button(String label, VoidCallback action, {bool outlined = false}) {
    if (outlined) {
      return OutlinedButton(
        onPressed: _working || service.busy ? null : action,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white70,
          side: const BorderSide(color: Color(0xFF5A5662)),
          minimumSize: const Size(0, 34),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          textStyle: const TextStyle(
            decoration: TextDecoration.none,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(label),
      );
    }
    return FilledButton(
      onPressed: _working || service.busy ? null : action,
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 34),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        textStyle: const TextStyle(
          decoration: TextDecoration.none,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label),
    );
  }

  Widget _detailsButton() => TextButton(
    onPressed: () => setState(() => _detailsExpanded = !_detailsExpanded),
    style: TextButton.styleFrom(
      foregroundColor: _muted,
      minimumSize: const Size(0, 34),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      textStyle: const TextStyle(decoration: TextDecoration.none, fontSize: 12),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    child: Text(_detailsExpanded ? 'Ocultar detalhes' : 'Ver detalhes'),
  );

  Widget _statusBadge(String label, {bool success = false}) {
    final color = success ? _success : _muted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Text(
        label,
        style: TextStyle(
          decoration: TextDecoration.none,
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _header(String status, String subtitle, {bool success = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.people_outline_rounded,
            color: Colors.white70,
            size: 19,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  const Text(
                    'Conexão rápida',
                    style: TextStyle(
                      decoration: TextDecoration.none,
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  _statusBadge(status, success: success),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  decoration: TextDecoration.none,
                  color: _muted,
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _actions(List<Widget> children) => Wrap(
    alignment: WrapAlignment.end,
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 8,
    runSpacing: 8,
    children: children,
  );

  Widget _details(String text, {String? projectId}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Divider(height: 1, color: _border),
        const SizedBox(height: 12),
        Text(
          text,
          style: const TextStyle(
            decoration: TextDecoration.none,
            color: _muted,
            fontSize: 12,
            height: 1.5,
          ),
        ),
        if (projectId != null &&
            projectId.isNotEmpty &&
            projectId != widget.currentProjectId &&
            widget.onOpenProject != null) ...[
          const SizedBox(height: 8),
          _button('Abrir Networking', () => _open(projectId), outlined: true),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: service,
      builder: (context, _) {
        final active = service.isInSession;
        final paused = service.isPaused;
        final incoming = service.incoming;
        final outgoing = service.outgoing;
        final canInvite =
            service.isAvailable &&
            widget.projectId != null &&
            widget.targetId != null &&
            widget.targetId != Supabase.instance.client.auth.currentUser?.id;

        if (!active &&
            !paused &&
            incoming.isEmpty &&
            outgoing.isEmpty &&
            !canInvite &&
            !widget.showWhenInactive &&
            service.error == null) {
          return const SizedBox.shrink();
        }

        String status;
        String subtitle;
        final actions = <Widget>[];
        String? details;
        String? detailsProject;

        if (active) {
          status = 'Em andamento';
          subtitle = 'Disponibilidade pausada · ${_remainingLabel()}';
          details =
              'O tempo do Agora está guardado. Encerrar esta conexão '
              'não remove membros, apaga o projeto ou encerra uma chamada.';
          detailsProject = service.projectId;
          actions.add(_detailsButton());
          actions.add(
            _button('Encerrar conexão', () => _end(), outlined: true),
          );
        } else if (paused) {
          status = 'Encerrada';
          subtitle = 'Disponibilidade pausada · ${_remainingLabel()}';
          details =
              'O projeto foi mantido. Você pode retomar o tempo '
              'restante ou ficar indisponível.';
          detailsProject = widget.projectId;
          actions.add(_detailsButton());
          actions.add(_button('Retomar tempo restante', () => _resume()));
          actions.add(
            _button(
              'Ficar indisponível',
              () => _run(service.clear),
              outlined: true,
            ),
          );
        } else if (incoming.isNotEmpty) {
          status = 'Convite recebido';
          subtitle = '${_name(incoming.first)} quer iniciar uma conexão agora.';
          actions.add(_detailsButton());
          actions.add(_button('Aceitar', () => _respond(incoming.first, true)));
          actions.add(
            _button(
              'Recusar',
              () => _respond(incoming.first, false),
              outlined: true,
            ),
          );
        } else if (outgoing.isNotEmpty) {
          status = 'Aguardando';
          subtitle = 'Aguardando ${_name(outgoing.first)} aceitar…';
          actions.add(_detailsButton());
          actions.add(
            _button(
              'Cancelar convite',
              () => _run(() => service.cancel(outgoing.first['id'].toString())),
              outlined: true,
            ),
          );
        } else if (canInvite) {
          status = 'Disponível';
          subtitle =
              'Convide ${widget.peerName ?? "este profissional"} '
              'para começar agora.';
          actions.add(_detailsButton());
          actions.add(
            _button(
              'Iniciar conexão agora',
              () => _run(
                () => service.invite(widget.projectId!, widget.targetId!),
              ),
            ),
          );
        } else {
          status = 'Indisponível';
          subtitle = 'Nenhuma conexão rápida em andamento.';
          actions.add(_detailsButton());
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border),
          ),
          child: DefaultTextStyle.merge(
            style: const TextStyle(decoration: TextDecoration.none),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 650;
                    final header = _header(status, subtitle, success: active);
                    final buttons = _actions(actions);
                    if (compact) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          header,
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: buttons,
                          ),
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: header),
                        const SizedBox(width: 16),
                        Flexible(child: buttons),
                      ],
                    );
                  },
                ),
                if (_detailsExpanded) ...[
                  if (details != null)
                    _details(details, projectId: detailsProject),
                  if (!active && !paused && incoming.length > 1)
                    for (final invitation in incoming.skip(1)) ...[
                      const SizedBox(height: 10),
                      Text(
                        '${_name(invitation)} quer iniciar uma conexão agora.',
                        style: const TextStyle(
                          decoration: TextDecoration.none,
                          color: _muted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _actions([
                        _button('Aceitar', () => _respond(invitation, true)),
                        _button(
                          'Recusar',
                          () => _respond(invitation, false),
                          outlined: true,
                        ),
                      ]),
                    ],
                  if (!active && !paused && outgoing.length > 1)
                    for (final invitation in outgoing.skip(1)) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Aguardando ${_name(invitation)} aceitar…',
                        style: const TextStyle(
                          decoration: TextDecoration.none,
                          color: _muted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _actions([
                        _button(
                          'Cancelar convite',
                          () => _run(
                            () => service.cancel(invitation['id'].toString()),
                          ),
                          outlined: true,
                        ),
                      ]),
                    ],
                ],
                if (service.error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    service.error!,
                    style: const TextStyle(
                      decoration: TextDecoration.none,
                      color: Colors.orangeAccent,
                      fontSize: 12,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: service.busy ? null : () => service.refresh(),
                      child: const Text('Tentar novamente'),
                    ),
                  ),
                ],
                if (_working || service.busy) ...[
                  const SizedBox(height: 10),
                  const LinearProgressIndicator(minHeight: 2),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
