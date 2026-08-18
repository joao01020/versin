import 'package:flutter/material.dart';

import 'package:versin/app/locator.dart';

import '../../../controllers/project_recruitment_controller.dart';
import '../../../data/models/project_recruitment_model.dart';

import '../../../invitations/services/project_invitation_service.dart';

// ============================================================
// RECRUITMENT CANDIDATES VIEW
// ============================================================
//
// Lista candidatos de um recrutamento.
//
// REGRA DE ENTRADA NA EQUIPE:
//
// - esta tela NUNCA adiciona alguém diretamente em projects.members;
// - ao escolher um candidato, cria project_invitations;
// - o candidato recebe um convite;
// - somente após ACEITAR ele entra na Studio Session.
//
// ============================================================

class RecruitmentCandidatesView
    extends
        StatefulWidget {
  final String projectId;
  final ProjectRecruitmentModel recruitment;

  const RecruitmentCandidatesView({
    super.key,
    required this.projectId,
    required this.recruitment,
  });

  @override
  State<
    RecruitmentCandidatesView
  >
  createState() => _RecruitmentCandidatesViewState();
}

class _RecruitmentCandidatesViewState
    extends
        State<
          RecruitmentCandidatesView
        > {
  static const Color _background = Color(
    0xFF08080B,
  );
  static const Color _surface = Color(
    0xFF111116,
  );
  static const Color _purple = Color(
    0xFF8B5CF6,
  );
  static const Color _green = Color(
    0xFF34D399,
  );
  static const Color _orange = Color(
    0xFFF59E0B,
  );

  late final ProjectRecruitmentController _controller;

  late final ProjectInvitationService _invitationService;

  final Set<
    String
  >
  _sendingInvitationUserIds =
      <
        String
      >{};
  final Set<
    String
  >
  _pendingInvitationUserIds =
      <
        String
      >{};

  @override
  void initState() {
    super.initState();

    _controller = ProjectRecruitmentController(
      projectId: widget.projectId,
    );

    _invitationService =
        sl<
          ProjectInvitationService
        >();

    _initialize();
  }

  Future<
    void
  >
  _initialize() async {
    await Future.wait(
      [
        _controller.loadCandidates(
          widget.recruitment,
        ),
        _loadPendingProjectInvitations(),
      ],
    );
  }

  Future<
    void
  >
  _reload() async {
    await Future.wait(
      [
        _controller.loadCandidates(
          widget.recruitment,
        ),
        _loadPendingProjectInvitations(),
      ],
    );
  }

  Future<
    void
  >
  _loadPendingProjectInvitations() async {
    final projectId = widget.projectId.trim();

    if (projectId.isEmpty) {
      return;
    }

    try {
      final ids = await _invitationService.loadPendingInvitedUserIds(
        projectId,
      );

      if (!mounted) {
        return;
      }

      setState(
        () {
          _pendingInvitationUserIds
            ..clear()
            ..addAll(
              ids,
            );
        },
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[RECRUITMENT CANDIDATES] '
        'Erro ao carregar convites pendentes: $error',
      );

      debugPrint(
        '$stackTrace',
      );
    }
  }

  Future<
    void
  >
  _inviteCandidate(
    ProjectRecruitmentCandidateModel candidate,
  ) async {
    final projectId = widget.projectId.trim();
    final invitedUserId = candidate.userId.trim();

    if (projectId.isEmpty ||
        invitedUserId.isEmpty) {
      _showMessage(
        'Não foi possível identificar o projeto ou candidato.',
        error: true,
      );

      return;
    }

    if (_sendingInvitationUserIds.contains(
      invitedUserId,
    )) {
      return;
    }

    if (_pendingInvitationUserIds.contains(
      invitedUserId,
    )) {
      _showMessage(
        '${candidate.displayName} já possui um convite pendente.',
      );

      return;
    }

    setState(
      () {
        _sendingInvitationUserIds.add(
          invitedUserId,
        );
      },
    );

    try {
      await _invitationService.createInvitation(
        projectId: projectId,
        invitedUserId: invitedUserId,
      );

      if (!mounted) {
        return;
      }

      setState(
        () {
          _pendingInvitationUserIds.add(
            invitedUserId,
          );
        },
      );

      _showMessage(
        'Convite enviado para ${candidate.displayName}.',
      );
    } on StateError catch (
      error
    ) {
      if (!mounted) {
        return;
      }

      final message = error.message.toString();

      if (message.toLowerCase().contains(
        'já faz parte',
      )) {
        _showMessage(
          '${candidate.displayName} já faz parte da equipe.',
        );

        return;
      }

      if (message.toLowerCase().contains(
        'fundador',
      )) {
        _showMessage(
          'Somente fundadores podem convidar novos membros.',
          error: true,
        );

        return;
      }

      _showMessage(
        message,
        error: true,
      );
    } on ArgumentError catch (
      error
    ) {
      if (!mounted) {
        return;
      }

      _showMessage(
        error.message?.toString() ??
            'Dados inválidos para enviar o convite.',
        error: true,
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[RECRUITMENT CANDIDATES] '
        'Erro ao enviar convite: $error',
      );

      debugPrint(
        '$stackTrace',
      );

      if (!mounted) {
        return;
      }

      final message = error.toString();

      if (message.toLowerCase().contains(
            'duplicate',
          ) ||
          message.contains(
            '23505',
          )) {
        setState(
          () {
            _pendingInvitationUserIds.add(
              invitedUserId,
            );
          },
        );

        _showMessage(
          '${candidate.displayName} já possui um convite pendente.',
        );

        return;
      }

      _showMessage(
        'Não foi possível enviar o convite.',
        error: true,
      );
    } finally {
      if (mounted) {
        setState(
          () {
            _sendingInvitationUserIds.remove(
              invitedUserId,
            );
          },
        );
      }
    }
  }

  void _showMessage(
    String message, {
    bool error = false,
  }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
        context,
      )
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
          ),
          backgroundColor: error
              ? const Color(
                  0xFF3B1218,
                )
              : const Color(
                  0xFF15151D,
                ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Candidatos',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              widget.recruitment.roleLabel,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 10,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _reload,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder:
            (
              context,
              _,
            ) {
              if (_controller.isLoadingCandidates) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (_controller.candidates.isEmpty) {
                return _buildEmpty();
              }

              return RefreshIndicator(
                onRefresh: _reload,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(
                    18,
                  ),
                  itemCount: _controller.candidates.length,
                  itemBuilder:
                      (
                        context,
                        index,
                      ) {
                        return _buildCandidate(
                          _controller.candidates[index],
                        );
                      },
                ),
              );
            },
      ),
    );
  }

  Widget _buildCandidate(
    ProjectRecruitmentCandidateModel candidate,
  ) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      padding: const EdgeInsets.all(
        14,
      ),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.05,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildAvatar(
            candidate,
          ),
          const SizedBox(
            width: 13,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  candidate.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (candidate.usernameLabel.isNotEmpty)
                  Text(
                    candidate.usernameLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                    ),
                  ),
                const SizedBox(
                  height: 7,
                ),
                Row(
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _purple.withValues(
                            alpha: 0.10,
                          ),
                          borderRadius: BorderRadius.circular(
                            20,
                          ),
                        ),
                        child: Text(
                          candidate.primaryRole,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _purple,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 7,
                    ),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: candidate.isOnline
                            ? _green
                            : Colors.white24,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          _buildAction(
            candidate,
          ),
        ],
      ),
    );
  }

  Widget _buildAction(
    ProjectRecruitmentCandidateModel candidate,
  ) {
    final userId = candidate.userId.trim();

    if (candidate.isApproved) {
      return const Tooltip(
        message: 'Já faz parte da sessão',
        child: Icon(
          Icons.check_circle_rounded,
          color: _green,
        ),
      );
    }

    if (_sendingInvitationUserIds.contains(
      userId,
    )) {
      return const SizedBox(
        width: 34,
        height: 34,
        child: Padding(
          padding: EdgeInsets.all(
            7,
          ),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: _purple,
          ),
        ),
      );
    }

    if (_pendingInvitationUserIds.contains(
      userId,
    )) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: _orange.withValues(
            alpha: 0.08,
          ),
          borderRadius: BorderRadius.circular(
            10,
          ),
          border: Border.all(
            color: _orange.withValues(
              alpha: 0.18,
            ),
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.schedule_send_rounded,
              color: _orange,
              size: 13,
            ),
            SizedBox(
              width: 5,
            ),
            Text(
              'Pendente',
              style: TextStyle(
                color: _orange,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: () {
        _inviteCandidate(
          candidate,
        );
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: _purple,
        side: const BorderSide(
          color: _purple,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 11,
          vertical: 9,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            11,
          ),
        ),
      ),
      icon: Icon(
        candidate.isInterested
            ? Icons.how_to_reg_rounded
            : Icons.person_add_alt_1_rounded,
        size: 14,
      ),
      label: const Text(
        'Convidar',
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildAvatar(
    ProjectRecruitmentCandidateModel candidate,
  ) {
    final url = candidate.avatarUrl;

    if (url !=
            null &&
        url.isNotEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundImage: NetworkImage(
          url,
        ),
      );
    }

    final name = candidate.displayName.trim();
    final initial = name.isEmpty
        ? '?'
        : name
              .substring(
                0,
                1,
              )
              .toUpperCase();

    return CircleAvatar(
      radius: 24,
      backgroundColor: _purple.withValues(
        alpha: 0.12,
      ),
      child: Text(
        initial,
        style: const TextStyle(
          color: _purple,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(
          30,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.radar_rounded,
              color: Colors.white24,
              size: 45,
            ),
            const SizedBox(
              height: 15,
            ),
            Text(
              'Buscando ${widget.recruitment.roleLabel}s',
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(
              height: 5,
            ),
            const Text(
              'A busca continua ativa mesmo quando você sair desta tela.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white30,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _sendingInvitationUserIds.clear();
    _pendingInvitationUserIds.clear();
    super.dispose();
  }
}
