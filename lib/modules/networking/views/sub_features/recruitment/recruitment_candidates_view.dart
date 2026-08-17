import 'package:flutter/material.dart';

import '../../../controllers/project_recruitment_controller.dart';
import '../../../data/models/project_recruitment_model.dart';

// ============================================================
// RECRUITMENT CANDIDATES VIEW
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

  late final ProjectRecruitmentController _controller;

  @override
  void initState() {
    super.initState();

    _controller = ProjectRecruitmentController(
      projectId: widget.projectId,
    );

    _controller.loadCandidates(
      widget.recruitment,
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

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
            onPressed: () {
              _controller.loadCandidates(
                widget.recruitment,
              );
            },

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

              return ListView.builder(
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
              );
            },
      ),
    );
  }

  // ==========================================================
  // CANDIDATE
  // ==========================================================

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

                  style: const TextStyle(
                    color: Colors.white,

                    fontSize: 14,

                    fontWeight: FontWeight.w700,
                  ),
                ),

                if (candidate.usernameLabel.isNotEmpty)
                  Text(
                    candidate.usernameLabel,

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
                    Container(
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

                        style: const TextStyle(
                          color: _purple,

                          fontSize: 9,
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

          _buildAction(
            candidate,
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ACTION
  // ==========================================================

  Widget _buildAction(
    ProjectRecruitmentCandidateModel candidate,
  ) {
    if (candidate.isApproved) {
      return const Icon(
        Icons.check_circle_rounded,

        color: _green,
      );
    }

    if (candidate.isInterested) {
      return ElevatedButton(
        onPressed: () async {
          final success = await _controller.approveCandidate(
            recruitment: widget.recruitment,

            candidate: candidate,
          );

          if (!mounted ||
              !success) {
            return;
          }

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(
            SnackBar(
              content: Text(
                '${candidate.displayName} entrou na sessão.',
              ),
            ),
          );
        },

        style: ElevatedButton.styleFrom(
          backgroundColor: _green,

          foregroundColor: Colors.black,
        ),

        child: const Text(
          'Aceitar',
        ),
      );
    }

    if (candidate.isInvited) {
      return const Text(
        'Convidado',

        style: TextStyle(
          color: Colors.white38,

          fontSize: 10,
        ),
      );
    }

    return OutlinedButton(
      onPressed: () async {
        await _controller.inviteCandidate(
          recruitment: widget.recruitment,

          candidate: candidate,
        );
      },

      style: OutlinedButton.styleFrom(
        foregroundColor: _purple,

        side: const BorderSide(
          color: _purple,
        ),
      ),

      child: const Text(
        'Convidar',
      ),
    );
  }

  // ==========================================================
  // AVATAR
  // ==========================================================

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

  // ==========================================================
  // EMPTY
  // ==========================================================

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

    super.dispose();
  }
}
