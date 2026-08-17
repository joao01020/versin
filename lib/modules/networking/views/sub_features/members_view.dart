import 'package:flutter/material.dart';

import '../../controllers/project_members_controller.dart';
import '../../controllers/project_recruitment_controller.dart';

import '../../data/models/project_member_model.dart';
import '../../data/models/project_recruitment_model.dart';

import 'recruitment/create_recruitment_view.dart';
import 'recruitment/recruitment_candidates_view.dart';

// ============================================================
// MEMBERS VIEW
// ============================================================
//
// Responsável por:
//
// - listar participantes da Studio Session;
// - mostrar status dos membros;
// - abrir busca por novos membros;
// - listar recrutamentos ativos;
// - abrir candidatos;
// - encerrar recrutamentos.
//
// Fluxo:
//
// MembersView
//    ↓
// ProjectMembersController
//    ↓
// projects.members
//    ↓
// profiles
//
// E:
//
// MembersView
//    ↓
// ProjectRecruitmentController
//    ↓
// project_recruitments
//
// ============================================================

class MembersView
    extends
        StatefulWidget {
  final String projectId;

  const MembersView({
    super.key,
    required this.projectId,
  });

  @override
  State<
    MembersView
  >
  createState() => _MembersViewState();
}

// ============================================================
// STATE
// ============================================================

class _MembersViewState
    extends
        State<
          MembersView
        > {
  // ==========================================================
  // CORES
  // ==========================================================

  static const Color _background = Color(
    0xFF08080B,
  );

  static const Color _surface = Color(
    0xFF111116,
  );

  static const Color _surfaceLight = Color(
    0xFF17171E,
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

  // ==========================================================
  // CONTROLLERS
  // ==========================================================

  late final ProjectMembersController _membersController;

  late final ProjectRecruitmentController _recruitmentController;

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _membersController = ProjectMembersController(
      projectId: widget.projectId,
    );

    _recruitmentController = ProjectRecruitmentController(
      projectId: widget.projectId,
    );

    _membersController.load();

    _recruitmentController.init();
  }

  // ==========================================================
  // PROJECT HASH
  // ==========================================================

  String get _projectHash {
    final id = widget.projectId.trim();

    if (id.length <=
        8) {
      return id.toUpperCase();
    }

    return id
        .substring(
          0,
          8,
        )
        .toUpperCase();
  }

  // ==========================================================
  // RELOAD
  // ==========================================================

  Future<
    void
  >
  _reloadAll() async {
    await Future.wait(
      [
        _membersController.reload(),
        _recruitmentController.init(),
      ],
    );
  }

  // ==========================================================
  // ABRIR CRIAÇÃO
  // ==========================================================

  Future<
    void
  >
  _openCreateRecruitment() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (
              _,
            ) => CreateRecruitmentView(
              projectId: widget.projectId,
            ),
      ),
    );

    if (!mounted) {
      return;
    }

    await _recruitmentController.init();
  }

  // ==========================================================
  // ABRIR CANDIDATOS
  // ==========================================================

  Future<
    void
  >
  _openCandidates(
    ProjectRecruitmentModel recruitment,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (
              _,
            ) => RecruitmentCandidatesView(
              projectId: widget.projectId,

              recruitment: recruitment,
            ),
      ),
    );

    if (!mounted) {
      return;
    }

    await _reloadAll();
  }

  // ==========================================================
  // ENCERRAR BUSCA
  // ==========================================================

  Future<
    void
  >
  _closeRecruitment(
    ProjectRecruitmentModel recruitment,
  ) async {
    final confirmed =
        await showDialog<
          bool
        >(
          context: context,

          builder:
              (
                dialogContext,
              ) {
                return AlertDialog(
                  backgroundColor: _surfaceLight,

                  title: const Text(
                    'Encerrar busca?',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),

                  content: Text(
                    'A busca por ${recruitment.roleLabel} deixará de aparecer como ativa.',
                    style: const TextStyle(
                      color: Colors.white60,
                    ),
                  ),

                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(
                          dialogContext,
                          false,
                        );
                      },

                      child: const Text(
                        'Cancelar',
                      ),
                    ),

                    TextButton(
                      onPressed: () {
                        Navigator.pop(
                          dialogContext,
                          true,
                        );
                      },

                      child: const Text(
                        'Encerrar',
                        style: TextStyle(
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                  ],
                );
              },
        );

    if (confirmed !=
        true) {
      return;
    }

    await _recruitmentController.closeRecruitment(
      recruitment,
    );

    if (!mounted) {
      return;
    }

    await _recruitmentController.init();
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

        elevation: 0,

        titleSpacing: 4,

        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              'Membros',
              style: TextStyle(
                color: Colors.white,

                fontSize: 16,

                fontWeight: FontWeight.w700,
              ),
            ),

            Text(
              'Studio Session #$_projectHash',
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

            onPressed: _reloadAll,

            icon: const Icon(
              Icons.refresh_rounded,

              size: 19,
            ),
          ),
        ],
      ),

      body: SafeArea(
        top: false,

        child: ListenableBuilder(
          listenable: Listenable.merge(
            [
              _membersController,
              _recruitmentController,
            ],
          ),

          builder:
              (
                context,
                _,
              ) {
                // ================================================
                // LOADING INICIAL
                // ================================================

                if (_membersController.isLoading &&
                    !_membersController.hasMembers) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                // ================================================
                // ERRO DOS MEMBROS
                // ================================================

                if (_membersController.hasError &&
                    !_membersController.hasMembers) {
                  return _buildError();
                }

                // ================================================
                // CONTEÚDO
                // ================================================

                return RefreshIndicator(
                  onRefresh: _reloadAll,

                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),

                    padding: const EdgeInsets.fromLTRB(
                      18,
                      12,
                      18,
                      28,
                    ),

                    children: [
                      // ==========================================
                      // HEADER
                      // ==========================================
                      _buildHeader(),

                      const SizedBox(
                        height: 16,
                      ),

                      // ==========================================
                      // PROCURAR MEMBRO
                      // ==========================================
                      _buildRecruitmentButton(),

                      // ==========================================
                      // BUSCAS ATIVAS
                      // ==========================================
                      if (_recruitmentController.activeRecruitments.isNotEmpty) ...[
                        const SizedBox(
                          height: 24,
                        ),

                        _buildSectionTitle(
                          'BUSCAS ATIVAS',
                        ),

                        const SizedBox(
                          height: 10,
                        ),

                        ..._recruitmentController.activeRecruitments.map(
                          _buildRecruitmentCard,
                        ),
                      ],

                      // ==========================================
                      // ERRO RECRUTAMENTO
                      // ==========================================
                      if (_recruitmentController.hasError) ...[
                        const SizedBox(
                          height: 14,
                        ),

                        _buildRecruitmentError(),
                      ],

                      const SizedBox(
                        height: 24,
                      ),

                      // ==========================================
                      // PARTICIPANTES
                      // ==========================================
                      _buildSectionTitle(
                        'PARTICIPANTES',
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      if (_membersController.members.isEmpty)
                        _buildEmptyMembersInline()
                      else
                        ..._membersController.members.map(
                          _buildMemberCard,
                        ),
                    ],
                  ),
                );
              },
        ),
      ),
    );
  }

  // ==========================================================
  // SECTION TITLE
  // ==========================================================

  Widget _buildSectionTitle(
    String text,
  ) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white38,

        fontSize: 10,

        fontWeight: FontWeight.w700,

        letterSpacing: 1.2,
      ),
    );
  }

  // ==========================================================
  // HEADER
  // ==========================================================

  Widget _buildHeader() {
    final count = _membersController.memberCount;

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(
        18,
      ),

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          22,
        ),

        gradient: const LinearGradient(
          begin: Alignment.topLeft,

          end: Alignment.bottomRight,

          colors: [
            Color(
              0xFF21113E,
            ),

            _surface,
          ],
        ),

        border: Border.all(
          color: _purple.withValues(
            alpha: 0.22,
          ),
        ),

        boxShadow: [
          BoxShadow(
            color: _purple.withValues(
              alpha: 0.06,
            ),

            blurRadius: 26,
          ),
        ],
      ),

      child: Row(
        children: [
          Container(
            width: 50,

            height: 50,

            decoration: BoxDecoration(
              color: _purple.withValues(
                alpha: 0.12,
              ),

              borderRadius: BorderRadius.circular(
                16,
              ),

              border: Border.all(
                color: _purple.withValues(
                  alpha: 0.22,
                ),
              ),
            ),

            child: const Icon(
              Icons.groups_2_outlined,

              color: _purple,

              size: 24,
            ),
          ),

          const SizedBox(
            width: 14,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  '$count '
                  '${count == 1 ? "participante" : "participantes"}',
                  style: const TextStyle(
                    color: Colors.white,

                    fontSize: 16,

                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                const Text(
                  'Construa a equipe ideal para esta sessão.',
                  style: TextStyle(
                    color: Colors.white38,

                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // BOTÃO RECRUTAMENTO
  // ==========================================================

  Widget _buildRecruitmentButton() {
    return Material(
      color: Colors.transparent,

      child: InkWell(
        onTap: _openCreateRecruitment,

        borderRadius: BorderRadius.circular(
          18,
        ),

        child: Ink(
          padding: const EdgeInsets.all(
            15,
          ),

          decoration: BoxDecoration(
            color: _purple.withValues(
              alpha: 0.08,
            ),

            borderRadius: BorderRadius.circular(
              18,
            ),

            border: Border.all(
              color: _purple.withValues(
                alpha: 0.22,
              ),
            ),
          ),

          child: Row(
            children: [
              Container(
                width: 42,

                height: 42,

                decoration: BoxDecoration(
                  color: _purple.withValues(
                    alpha: 0.14,
                  ),

                  borderRadius: BorderRadius.circular(
                    13,
                  ),
                ),

                child: const Icon(
                  Icons.person_search_rounded,

                  color: _purple,

                  size: 21,
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      'Procurar membro',
                      style: TextStyle(
                        color: Colors.white,

                        fontSize: 13,

                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    SizedBox(
                      height: 3,
                    ),

                    Text(
                      'Abra uma busca por função para expandir a sessão.',
                      style: TextStyle(
                        color: Colors.white38,

                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.add_rounded,

                color: _purple,

                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // RECRUITMENT CARD
  // ==========================================================

  Widget _buildRecruitmentCard(
    ProjectRecruitmentModel recruitment,
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
          color: _orange.withValues(
            alpha: 0.16,
          ),
        ),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          // ================================================
          // CABEÇALHO
          // ================================================
          Row(
            children: [
              Container(
                width: 38,

                height: 38,

                decoration: BoxDecoration(
                  color: _orange.withValues(
                    alpha: 0.10,
                  ),

                  borderRadius: BorderRadius.circular(
                    12,
                  ),
                ),

                child: const Icon(
                  Icons.radar_rounded,

                  color: _orange,

                  size: 19,
                ),
              ),

              const SizedBox(
                width: 11,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      recruitment.roleLabel,

                      style: const TextStyle(
                        color: Colors.white,

                        fontSize: 13,

                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(
                      height: 2,
                    ),

                    const Row(
                      children: [
                        _RecruitmentStatusDot(),

                        SizedBox(
                          width: 5,
                        ),

                        Text(
                          'Busca ativa',
                          style: TextStyle(
                            color: _orange,

                            fontSize: 9,

                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ================================================
          // DESCRIÇÃO
          // ================================================
          if (recruitment.description.trim().isNotEmpty) ...[
            const SizedBox(
              height: 12,
            ),

            Text(
              recruitment.description,

              style: const TextStyle(
                color: Colors.white54,

                fontSize: 11,

                height: 1.4,
              ),
            ),
          ],

          const SizedBox(
            height: 13,
          ),

          // ================================================
          // AÇÕES
          // ================================================
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _openCandidates(
                      recruitment,
                    );
                  },

                  icon: const Icon(
                    Icons.people_outline_rounded,

                    size: 16,
                  ),

                  label: const Text(
                    'Ver candidatos',
                  ),

                  style: OutlinedButton.styleFrom(
                    foregroundColor: _purple,

                    side: BorderSide(
                      color: _purple.withValues(
                        alpha: 0.40,
                      ),
                    ),

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        12,
                      ),
                    ),

                    textStyle: const TextStyle(
                      fontSize: 10,

                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              IconButton(
                tooltip: 'Encerrar busca',

                onPressed: () {
                  _closeRecruitment(
                    recruitment,
                  );
                },

                style: IconButton.styleFrom(
                  backgroundColor: Colors.redAccent.withValues(
                    alpha: 0.07,
                  ),
                ),

                icon: const Icon(
                  Icons.close_rounded,

                  color: Colors.redAccent,

                  size: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // RECRUITMENT ERROR
  // ==========================================================

  Widget _buildRecruitmentError() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(
        12,
      ),

      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(
          alpha: 0.07,
        ),

        borderRadius: BorderRadius.circular(
          14,
        ),
      ),

      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,

            color: Colors.redAccent,

            size: 17,
          ),

          const SizedBox(
            width: 8,
          ),

          Expanded(
            child: Text(
              _recruitmentController.errorMessage ??
                  'Erro no recrutamento.',

              style: const TextStyle(
                color: Colors.redAccent,

                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // MEMBER CARD
  // ==========================================================

  Widget _buildMemberCard(
    ProjectMemberModel member,
  ) {
    final isCurrentUser = _membersController.isCurrentUser(
      member,
    );

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
          color: isCurrentUser
              ? _purple.withValues(
                  alpha: 0.30,
                )
              : Colors.white.withValues(
                  alpha: 0.05,
                ),
        ),
      ),

      child: Row(
        children: [
          _buildAvatar(
            member,
          ),

          const SizedBox(
            width: 13,
          ),

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

                          fontSize: 14,

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

                          vertical: 3,
                        ),

                        decoration: BoxDecoration(
                          color: _purple.withValues(
                            alpha: 0.13,
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

                            letterSpacing: 0.6,
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

                    style: const TextStyle(
                      color: Colors.white38,

                      fontSize: 10,
                    ),
                  ),
                ],

                const SizedBox(
                  height: 8,
                ),

                Wrap(
                  spacing: 7,

                  runSpacing: 6,

                  children: [
                    _buildRoleChip(
                      member.roleLabel,
                    ),

                    _buildStatusChip(
                      member.isOnline,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(
            width: 8,
          ),

          Icon(
            Icons.chevron_right_rounded,

            color: Colors.white.withValues(
              alpha: 0.18,
            ),
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
    final avatarUrl = member.avatarUrl;

    if (avatarUrl !=
            null &&
        avatarUrl.isNotEmpty) {
      return Container(
        width: 50,

        height: 50,

        decoration: BoxDecoration(
          shape: BoxShape.circle,

          border: Border.all(
            color: _purple.withValues(
              alpha: 0.18,
            ),
          ),
        ),

        child: ClipOval(
          child: Image.network(
            avatarUrl,

            fit: BoxFit.cover,

            errorBuilder:
                (
                  context,
                  error,
                  stackTrace,
                ) {
                  return _buildInitialAvatar(
                    member,
                  );
                },
          ),
        ),
      );
    }

    return _buildInitialAvatar(
      member,
    );
  }

  // ==========================================================
  // INITIAL AVATAR
  // ==========================================================

  Widget _buildInitialAvatar(
    ProjectMemberModel member,
  ) {
    final name = member.displayName.trim();

    final initial = name.isNotEmpty
        ? name
              .substring(
                0,
                1,
              )
              .toUpperCase()
        : '?';

    return Container(
      width: 50,

      height: 50,

      alignment: Alignment.center,

      decoration: BoxDecoration(
        color: _purple.withValues(
          alpha: 0.12,
        ),

        shape: BoxShape.circle,

        border: Border.all(
          color: _purple.withValues(
            alpha: 0.18,
          ),
        ),
      ),

      child: Text(
        initial,

        style: const TextStyle(
          color: _purple,

          fontSize: 17,

          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // ==========================================================
  // ROLE CHIP
  // ==========================================================

  Widget _buildRoleChip(
    String role,
  ) {
    final formattedRole = _formatRole(
      role,
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,

        vertical: 4,
      ),

      decoration: BoxDecoration(
        color: _purple.withValues(
          alpha: 0.08,
        ),

        borderRadius: BorderRadius.circular(
          20,
        ),

        border: Border.all(
          color: _purple.withValues(
            alpha: 0.12,
          ),
        ),
      ),

      child: Text(
        formattedRole,

        style: const TextStyle(
          color: Colors.white60,

          fontSize: 9,

          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ==========================================================
  // STATUS CHIP
  // ==========================================================

  Widget _buildStatusChip(
    bool online,
  ) {
    final color = online
        ? _green
        : Colors.white24;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,

        vertical: 4,
      ),

      decoration: BoxDecoration(
        color: color.withValues(
          alpha: online
              ? 0.08
              : 0.04,
        ),

        borderRadius: BorderRadius.circular(
          20,
        ),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,

        children: [
          Container(
            width: 6,

            height: 6,

            decoration: BoxDecoration(
              color: color,

              shape: BoxShape.circle,

              boxShadow: online
                  ? [
                      BoxShadow(
                        color: color.withValues(
                          alpha: 0.35,
                        ),

                        blurRadius: 6,
                      ),
                    ]
                  : null,
            ),
          ),

          const SizedBox(
            width: 5,
          ),

          Text(
            online
                ? 'Online'
                : 'Offline',

            style: TextStyle(
              color: online
                  ? color
                  : Colors.white30,

              fontSize: 9,

              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // FORMAT ROLE
  // ==========================================================

  String _formatRole(
    String value,
  ) {
    final normalized = value.trim().toLowerCase();

    switch (normalized) {
      case 'artist':
        return 'Artista';

      case 'producer':
        return 'Produtor';

      case 'beatmaker':
        return 'Beatmaker';

      case 'singer':
        return 'Cantor';

      case 'rapper':
        return 'Rapper';

      case 'songwriter':
        return 'Compositor';

      case 'engineer':
        return 'Engenheiro';

      case 'mixer':
        return 'Mixagem';

      default:
        if (normalized.isEmpty) {
          return 'Membro';
        }

        return value;
    }
  }

  // ==========================================================
  // EMPTY MEMBERS INLINE
  // ==========================================================

  Widget _buildEmptyMembersInline() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(
        22,
      ),

      decoration: BoxDecoration(
        color: _surface,

        borderRadius: BorderRadius.circular(
          18,
        ),
      ),

      child: const Column(
        children: [
          Icon(
            Icons.group_off_outlined,

            color: Colors.white24,

            size: 30,
          ),

          SizedBox(
            height: 10,
          ),

          Text(
            'Nenhum membro encontrado',
            style: TextStyle(
              color: Colors.white54,

              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ERROR
  // ==========================================================

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(
          24,
        ),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            Container(
              width: 64,

              height: 64,

              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(
                  alpha: 0.08,
                ),

                borderRadius: BorderRadius.circular(
                  20,
                ),
              ),

              child: const Icon(
                Icons.error_outline_rounded,

                color: Colors.redAccent,

                size: 30,
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            Text(
              _membersController.errorMessage ??
                  'Erro ao carregar membros.',

              textAlign: TextAlign.center,

              style: const TextStyle(
                color: Colors.white54,

                fontSize: 12,
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            TextButton.icon(
              onPressed: _reloadAll,

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
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _membersController.dispose();

    _recruitmentController.dispose();

    super.dispose();
  }
}

// ============================================================
// STATUS DOT
// ============================================================

class _RecruitmentStatusDot
    extends
        StatelessWidget {
  const _RecruitmentStatusDot();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: 6,

      height: 6,

      decoration: BoxDecoration(
        color: _MembersViewState._orange,

        shape: BoxShape.circle,

        boxShadow: [
          BoxShadow(
            color: _MembersViewState._orange.withValues(
              alpha: 0.45,
            ),

            blurRadius: 6,
          ),
        ],
      ),
    );
  }
}
