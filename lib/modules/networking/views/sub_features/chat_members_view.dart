import 'package:flutter/material.dart';

import '../../controllers/project_members_controller.dart';
import '../../data/models/project_member_model.dart';

// ============================================================
// CHAT MEMBERS VIEW
// ============================================================
//
// Exibe os membros atuais da Studio Session.
//
// Fluxo:
//
// ChatView
//    ↓
// ChatMembersView
//    ↓
// ProjectMembersController
//    ↓
// ProjectMembersService
//    ↓
// projects.members
//    ↓
// profiles
//
// Esta tela NÃO mantém uma lista própria de membros.
//
// Ela reutiliza a mesma fonte usada pelo módulo de membros,
// garantindo que o chat mostre a equipe atual da sessão.
//
// ============================================================

class ChatMembersView
    extends
        StatefulWidget {
  // ==========================================================
  // PROJECT
  // ==========================================================

  final String projectId;

  // ==========================================================
  // CONSTRUCTOR
  // ==========================================================

  const ChatMembersView({
    super.key,
    required this.projectId,
  });

  // ==========================================================
  // STATE
  // ==========================================================

  @override
  State<
    ChatMembersView
  >
  createState() => _ChatMembersViewState();
}

// ============================================================
// STATE
// ============================================================

class _ChatMembersViewState
    extends
        State<
          ChatMembersView
        > {
  // ==========================================================
  // COLORS
  // ==========================================================

  static const Color _background = Color(
    0xFF0F0F0F,
  );

  static const Color _surface = Color(
    0xFF171717,
  );

  static const Color _surfaceSecondary = Color(
    0xFF202020,
  );

  static const Color _purple = Color(
    0xFF8B5CF6,
  );

  static const Color _green = Color(
    0xFF34D399,
  );

  // ==========================================================
  // CONTROLLER
  // ==========================================================

  late final ProjectMembersController _controller;

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _controller = ProjectMembersController(
      projectId: widget.projectId,
    );

    _controller.addListener(
      _handleControllerUpdate,
    );

    _controller.load();
  }

  // ==========================================================
  // CONTROLLER UPDATE
  // ==========================================================

  void _handleControllerUpdate() {
    if (!mounted) {
      return;
    }

    setState(
      () {},
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

        elevation: 0,

        titleSpacing: 0,

        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              'Membros da Studio Session',

              style: TextStyle(
                color: Colors.white,

                fontSize: 16,

                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(
              height: 2,
            ),

            Text(
              _memberCountLabel,

              style: const TextStyle(
                color: Colors.white38,

                fontSize: 10,
              ),
            ),
          ],
        ),
      ),

      body: SafeArea(
        top: false,

        child: _buildBody(),
      ),
    );
  }

  // ==========================================================
  // BODY
  // ==========================================================

  Widget _buildBody() {
    if (_controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_controller.hasError) {
      return _buildErrorState();
    }

    if (!_controller.hasMembers) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _controller.reload,

      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),

        padding: const EdgeInsets.fromLTRB(
          16,
          12,
          16,
          24,
        ),

        itemCount: _controller.members.length,

        separatorBuilder:
            (
              _,
              __,
            ) => const SizedBox(
              height: 10,
            ),

        itemBuilder:
            (
              context,
              index,
            ) {
              final member = _controller.members[index];

              return _buildMemberCard(
                member,
              );
            },
      ),
    );
  }

  // ==========================================================
  // MEMBER CARD
  // ==========================================================

  Widget _buildMemberCard(
    ProjectMemberModel member,
  ) {
    final isCurrentUser = _controller.isCurrentUser(
      member,
    );

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(
        14,
      ),

      decoration: BoxDecoration(
        color: _surface,

        borderRadius: BorderRadius.circular(
          18,
        ),

        border: Border.all(
          color: isCurrentUser
              ? _purple.withValues(
                  alpha: 0.28,
                )
              : Colors.white.withValues(
                  alpha: 0.05,
                ),
        ),
      ),

      child: Row(
        children: [
          // ==================================================
          // AVATAR
          // ==================================================
          _buildAvatar(
            member,
          ),

          const SizedBox(
            width: 12,
          ),

          // ==================================================
          // INFO
          // ==================================================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        member.displayName,

                        maxLines: 1,

                        overflow: TextOverflow.ellipsis,

                        style: const TextStyle(
                          color: Colors.white,

                          fontSize: 13,

                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    if (isCurrentUser) ...[
                      const SizedBox(
                        width: 7,
                      ),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,

                          vertical: 2,
                        ),

                        decoration: BoxDecoration(
                          color: _purple.withValues(
                            alpha: 0.14,
                          ),

                          borderRadius: BorderRadius.circular(
                            20,
                          ),
                        ),

                        child: const Text(
                          'VOCÊ',

                          style: TextStyle(
                            color: _purple,

                            fontSize: 8,

                            fontWeight: FontWeight.w800,

                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                if (member.usernameLabel.isNotEmpty) ...[
                  const SizedBox(
                    height: 2,
                  ),

                  Text(
                    member.usernameLabel,

                    maxLines: 1,

                    overflow: TextOverflow.ellipsis,

                    style: const TextStyle(
                      color: Colors.white38,

                      fontSize: 10,
                    ),
                  ),
                ],

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
                          color: Colors.white.withValues(
                            alpha: 0.04,
                          ),

                          borderRadius: BorderRadius.circular(
                            20,
                          ),
                        ),

                        child: Text(
                          member.roleLabel,

                          maxLines: 1,

                          overflow: TextOverflow.ellipsis,

                          style: const TextStyle(
                            color: Colors.white54,

                            fontSize: 9,

                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    if (member.isOnline) ...[
                      const SizedBox(
                        width: 8,
                      ),

                      const Icon(
                        Icons.circle,

                        color: _green,

                        size: 7,
                      ),

                      const SizedBox(
                        width: 5,
                      ),

                      const Text(
                        'Online',

                        style: TextStyle(
                          color: _green,

                          fontSize: 9,

                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // ==================================================
          // STATUS
          // ==================================================
          const SizedBox(
            width: 10,
          ),

          Icon(
            Icons.chevron_right_rounded,

            color: Colors.white.withValues(
              alpha: 0.18,
            ),

            size: 20,
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // AVATAR
  // ==========================================================

  Widget _buildAvatar(
    ProjectMemberModel member,
  ) {
    final avatarUrl = member.avatarUrl?.trim();

    if (avatarUrl !=
            null &&
        avatarUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          avatarUrl,

          width: 46,

          height: 46,

          fit: BoxFit.cover,

          errorBuilder:
              (
                _,
                __,
                ___,
              ) {
                return _buildAvatarFallback(
                  member,
                );
              },
        ),
      );
    }

    return _buildAvatarFallback(
      member,
    );
  }

  // ==========================================================
  // AVATAR FALLBACK
  // ==========================================================

  Widget _buildAvatarFallback(
    ProjectMemberModel member,
  ) {
    return Container(
      width: 46,

      height: 46,

      alignment: Alignment.center,

      decoration: BoxDecoration(
        color: _surfaceSecondary,

        shape: BoxShape.circle,

        border: Border.all(
          color: _purple.withValues(
            alpha: 0.18,
          ),
        ),
      ),

      child: Text(
        _initialFor(
          member,
        ),

        style: const TextStyle(
          color: _purple,

          fontSize: 14,

          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // ==========================================================
  // INITIAL
  // ==========================================================

  String _initialFor(
    ProjectMemberModel member,
  ) {
    final value = member.displayName.trim();

    if (value.isEmpty) {
      return '?';
    }

    return value
        .substring(
          0,
          1,
        )
        .toUpperCase();
  }

  // ==========================================================
  // ERROR
  // ==========================================================

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(
          30,
        ),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            const Icon(
              Icons.error_outline_rounded,

              color: Colors.redAccent,

              size: 38,
            ),

            const SizedBox(
              height: 12,
            ),

            Text(
              _controller.errorMessage ??
                  'Não foi possível carregar os membros.',

              textAlign: TextAlign.center,

              style: const TextStyle(
                color: Colors.white54,

                fontSize: 12,
              ),
            ),

            const SizedBox(
              height: 14,
            ),

            OutlinedButton.icon(
              onPressed: _controller.reload,

              icon: const Icon(
                Icons.refresh_rounded,
              ),

              label: const Text(
                'Tentar novamente',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // EMPTY
  // ==========================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(
          30,
        ),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            const Icon(
              Icons.groups_2_outlined,

              color: Colors.white24,

              size: 42,
            ),

            const SizedBox(
              height: 14,
            ),

            const Text(
              'Nenhum membro encontrado',

              style: TextStyle(
                color: Colors.white70,

                fontSize: 14,

                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(
              height: 6,
            ),

            const Text(
              'Os membros da Studio Session aparecerão aqui.',

              textAlign: TextAlign.center,

              style: TextStyle(
                color: Colors.white38,

                fontSize: 11,
              ),
            ),

            const SizedBox(
              height: 14,
            ),

            TextButton.icon(
              onPressed: _controller.reload,

              icon: const Icon(
                Icons.refresh_rounded,
              ),

              label: const Text(
                'Atualizar',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // MEMBER COUNT
  // ==========================================================

  String get _memberCountLabel {
    if (_controller.isLoading) {
      return 'Carregando membros...';
    }

    final count = _controller.memberCount;

    if (count ==
        1) {
      return '1 membro';
    }

    return '$count membros';
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _controller.removeListener(
      _handleControllerUpdate,
    );

    _controller.dispose();

    super.dispose();
  }
}
