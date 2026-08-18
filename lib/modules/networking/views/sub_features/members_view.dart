import 'package:flutter/material.dart';

import '../../call/controllers/communication_permission_controller.dart';

import '../../call/data/models/communication_request_model.dart';

import '../../call/views/widgets/communication_permission_card.dart';

import '../../controllers/project_members_controller.dart';
import '../../controllers/project_recruitment_controller.dart';

import '../../data/models/project_member_model.dart';
import '../../data/models/project_recruitment_model.dart';

import 'recruitment/create_recruitment_view.dart';
import 'recruitment/recruitment_candidates_view.dart';

class MembersView extends StatefulWidget {
  final String projectId;

  const MembersView({super.key, required this.projectId});

  @override
  State<MembersView> createState() => _MembersViewState();
}

class _MembersViewState extends State<MembersView> {
  static const Color _background = Color(0xFF08080B);

  static const Color _surface = Color(0xFF111116);

  static const Color _surfaceLight = Color(0xFF17171E);

  static const Color _purple = Color(0xFF8B5CF6);

  static const Color _green = Color(0xFF34D399);

  static const Color _orange = Color(0xFFF59E0B);

  static const Color _red = Color(0xFFEF4444);

  late final ProjectMembersController _membersController;

  late final ProjectRecruitmentController _recruitmentController;

  late final CommunicationPermissionController _communicationController;

  final Set<String> _selectedMemberIds = <String>{};

  final Set<String> _expandedMemberIds = <String>{};

  @override
  void initState() {
    super.initState();

    _membersController = ProjectMembersController(projectId: widget.projectId);

    _recruitmentController = ProjectRecruitmentController(
      projectId: widget.projectId,
    );

    _communicationController = CommunicationPermissionController(
      projectId: widget.projectId,
    );

    _initialize();
  }

  Future<void> _initialize() async {
    await _membersController.load();

    if (!mounted) {
      return;
    }

    await Future.wait([
      _recruitmentController.init(),

      _communicationController.init(),
    ]);

    if (!mounted) {
      return;
    }

    await _loadMemberAudioStates();
  }

  String get _projectHash {
    final id = widget.projectId.trim();

    if (id.length <= 8) {
      return id.toUpperCase();
    }

    return id.substring(0, 8).toUpperCase();
  }

  int get _selectedCount => _selectedMemberIds.length;

  bool get _hasSelection => _selectedMemberIds.isNotEmpty;

  Future<void> _reloadAll() async {
    await Future.wait([
      _membersController.reload(),

      _recruitmentController.init(),

      _communicationController.refresh(),
    ]);

    if (!mounted) {
      return;
    }

    await _loadMemberAudioStates();
  }

  Future<void> _loadMemberAudioStates() async {
    final futures = <Future<bool>>[];

    for (final member in _membersController.members) {
      futures.add(_communicationController.checkAudioAllowedFor(member.userId));
    }

    if (futures.isEmpty) {
      return;
    }

    await Future.wait(futures);
  }

  Future<void> _openCreateRecruitment() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateRecruitmentView(projectId: widget.projectId),
      ),
    );

    if (!mounted) {
      return;
    }

    await _recruitmentController.init();
  }

  Future<void> _openCandidates(ProjectRecruitmentModel recruitment) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecruitmentCandidatesView(
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

  Future<void> _closeRecruitment(ProjectRecruitmentModel recruitment) async {
    final confirmed = await showDialog<bool>(
      context: context,

      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _surfaceLight,

          title: const Text(
            'Encerrar busca?',

            style: TextStyle(color: Colors.white),
          ),

          content: Text(
            'A busca por ${recruitment.roleLabel} '
            'deixará de aparecer como ativa.',

            style: const TextStyle(color: Colors.white60),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },

              child: const Text('Cancelar'),
            ),

            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },

              child: const Text(
                'Encerrar',

                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await _recruitmentController.closeRecruitment(recruitment);

    if (!mounted) {
      return;
    }

    await _recruitmentController.init();
  }

  void _toggleMemberSelection(ProjectMemberModel member) {
    if (_membersController.isCurrentUser(member)) {
      return;
    }

    final userId = member.userId.trim();

    if (userId.isEmpty) {
      return;
    }

    setState(() {
      if (_selectedMemberIds.contains(userId)) {
        _selectedMemberIds.remove(userId);
      } else {
        _selectedMemberIds.add(userId);
      }
    });
  }

  bool _isMemberExpanded(String userId) {
    final normalized = userId.trim();

    if (normalized.isEmpty) {
      return false;
    }

    return _expandedMemberIds.contains(normalized);
  }

  void _toggleMemberExpanded(String userId) {
    final normalized = userId.trim();

    if (normalized.isEmpty) {
      return;
    }

    setState(() {
      if (_expandedMemberIds.contains(normalized)) {
        _expandedMemberIds.remove(normalized);
      } else {
        _expandedMemberIds.add(normalized);
      }
    });
  }

  void _clearSelection() {
    if (!_hasSelection) {
      return;
    }

    setState(() {
      _selectedMemberIds.clear();
    });
  }

  void _selectEligibleMembers() {
    final eligible = <String>{};

    for (final member in _membersController.members) {
      if (_membersController.isCurrentUser(member)) {
        continue;
      }

      final userId = member.userId.trim();

      if (userId.isEmpty) {
        continue;
      }

      if (_communicationController.canInviteVideo(userId)) {
        eligible.add(userId);
      }
    }

    setState(() {
      _selectedMemberIds
        ..clear()
        ..addAll(eligible);
    });
  }

  Future<void> _inviteSelectedMembers() async {
    if (!_hasSelection) {
      return;
    }

    final selected = _selectedMemberIds.toList(growable: false);

    final results = await _communicationController.requestVideoBulk(
      targetUserIds: selected,
    );

    if (!mounted) {
      return;
    }

    final successCount = results.where((result) => result.success).length;

    final failedCount = results.length - successCount;

    setState(() {
      _selectedMemberIds.clear();
    });

    if (results.isEmpty) {
      _showMessage(
        _communicationController.errorMessage ??
            'Não foi possível enviar os convites.',
        error: true,
      );

      return;
    }

    if (failedCount == 0) {
      _showMessage(
        successCount == 1
            ? 'Convite de vídeo enviado.'
            : '$successCount convites de vídeo enviados.',
      );

      return;
    }

    _showMessage(
      '$successCount enviados • '
      '$failedCount indisponíveis.',
      error: successCount == 0,
    );
  }

  Future<void> _inviteMember(ProjectMemberModel member) async {
    final request = await _communicationController.requestVideo(
      targetUserId: member.userId,
    );

    if (!mounted) {
      return;
    }

    if (request == null) {
      _showMessage(
        _communicationController.errorMessage ??
            'Não foi possível enviar o convite.',
        error: true,
      );

      return;
    }

    _showMessage('Convite enviado para ${member.displayName}.');
  }

  Future<void> _acceptRequest(CommunicationRequestModel request) async {
    final success = await _communicationController.acceptRequest(request);

    if (!mounted) {
      return;
    }

    if (success) {
      _showMessage('Vídeo liberado por consentimento.');

      return;
    }

    _showMessage(
      _communicationController.errorMessage ??
          'Não foi possível aceitar o convite.',
      error: true,
    );
  }

  Future<void> _rejectRequest(CommunicationRequestModel request) async {
    final confirmed = await showDialog<bool>(
      context: context,

      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _surfaceLight,

          title: const Text(
            'Recusar vídeo?',

            style: TextStyle(color: Colors.white),
          ),

          content: Text(
            _rejectionDialogMessage(request),

            style: const TextStyle(color: Colors.white60, height: 1.45),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },

              child: const Text('Cancelar'),
            ),

            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },

              child: const Text('Recusar', style: TextStyle(color: _red)),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final success = await _communicationController.rejectRequest(request);

    if (!mounted) {
      return;
    }

    if (success) {
      _showMessage('Solicitação recusada.');

      return;
    }

    _showMessage(
      _communicationController.errorMessage ?? 'Não foi possível recusar.',
      error: true,
    );
  }

  String _rejectionDialogMessage(CommunicationRequestModel request) {
    if (request.isFirstAttempt) {
      return 'Esta é a primeira solicitação. '
          'Ao recusar, este usuário precisará '
          'aguardar 2 dias para convidar novamente.';
    }

    if (request.isSecondAttempt) {
      return 'Esta é a segunda solicitação. '
          'Ao recusar, este usuário precisará '
          'aguardar 4 dias para convidar novamente.';
    }

    return 'Esta é a terceira solicitação. '
        'Ao recusar, novos convites deste usuário '
        'ficarão bloqueados até você permitir '
        'uma nova tentativa.';
  }

  Future<void> _allowNewInviteFrom(ProjectMemberModel member) async {
    final success = await _communicationController.allowNewInviteFrom(
      member.userId,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      _showMessage('${member.displayName} poderá enviar um novo convite.');

      return;
    }

    _showMessage(
      _communicationController.errorMessage ??
          'Não foi possível liberar uma nova tentativa.',
      error: true,
    );
  }

  Future<void> _revokeVideo(ProjectMemberModel member) async {
    final confirmed = await showDialog<bool>(
      context: context,

      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _surfaceLight,

          title: const Text(
            'Bloquear vídeo?',

            style: TextStyle(color: Colors.white),
          ),

          content: Text(
            'O consentimento de vídeo entre você e '
            '${member.displayName} será removido. '
            'Áudio continuará disponível.',

            style: const TextStyle(color: Colors.white60, height: 1.45),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },

              child: const Text('Cancelar'),
            ),

            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },

              child: const Text('Bloquear', style: TextStyle(color: _red)),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final success = await _communicationController.revokeVideoPermission(
      member.userId,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      _showMessage('Permissão de vídeo removida.');

      return;
    }

    _showMessage(
      _communicationController.errorMessage ??
          'Não foi possível remover a permissão.',
      error: true,
    );
  }

  void _showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),

          backgroundColor: error
              ? const Color(0xFF3B1218)
              : const Color(0xFF15151D),

          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  ProjectMemberModel? _memberByUserId(String userId) {
    final normalized = userId.trim();

    for (final member in _membersController.members) {
      if (member.userId == normalized) {
        return member;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
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

              style: const TextStyle(color: Colors.white38, fontSize: 10),
            ),
          ],
        ),

        actions: [
          if (_hasSelection)
            IconButton(
              tooltip: 'Limpar seleção',

              onPressed: _clearSelection,

              icon: const Icon(Icons.close_rounded, size: 19),
            ),

          IconButton(
            tooltip: 'Atualizar',

            onPressed: _reloadAll,

            icon: const Icon(Icons.refresh_rounded, size: 19),
          ),
        ],
      ),

      body: SafeArea(
        top: false,

        child: ListenableBuilder(
          listenable: Listenable.merge([
            _membersController,

            _recruitmentController,

            _communicationController,
          ]),

          builder: (context, _) {
            if (_membersController.isLoading &&
                !_membersController.hasMembers) {
              return const Center(child: CircularProgressIndicator());
            }

            if (_membersController.hasError && !_membersController.hasMembers) {
              return _buildError();
            }

            return RefreshIndicator(
              onRefresh: _reloadAll,

              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),

                padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),

                children: [
                  _buildHeader(),

                  const SizedBox(height: 16),

                  if (_communicationController
                      .pendingReceivedRequests
                      .isNotEmpty) ...[
                    _buildSectionTitle('CONVITES DE VÍDEO'),

                    const SizedBox(height: 10),

                    ..._communicationController.pendingReceivedRequests.map(
                      _buildIncomingVideoRequest,
                    ),

                    const SizedBox(height: 14),
                  ],

                  if (_communicationController.hasError) ...[
                    _buildCommunicationError(),

                    const SizedBox(height: 14),
                  ],

                  _buildRecruitmentButton(),

                  if (_recruitmentController.activeRecruitments.isNotEmpty) ...[
                    const SizedBox(height: 24),

                    _buildSectionTitle('BUSCAS ATIVAS'),

                    const SizedBox(height: 10),

                    ..._recruitmentController.activeRecruitments.map(
                      _buildRecruitmentCard,
                    ),
                  ],

                  if (_recruitmentController.hasError) ...[
                    const SizedBox(height: 14),

                    _buildRecruitmentError(),
                  ],

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(child: _buildSectionTitle('PARTICIPANTES')),

                      if (_membersController.memberCount > 1)
                        TextButton(
                          onPressed: _selectEligibleMembers,

                          child: const Text(
                            'Selecionar disponíveis',

                            style: TextStyle(fontSize: 9),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  if (_hasSelection) ...[
                    _buildSelectionBar(),

                    const SizedBox(height: 12),
                  ],

                  if (_membersController.members.isEmpty)
                    _buildEmptyMembersInline()
                  else
                    ..._membersController.members.map(_buildMemberCard),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
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

  Widget _buildHeader() {
    final count = _membersController.memberCount;

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),

        gradient: const LinearGradient(
          begin: Alignment.topLeft,

          end: Alignment.bottomRight,

          colors: [Color(0xFF21113E), _surface],
        ),

        border: Border.all(color: _purple.withValues(alpha: 0.22)),

        boxShadow: [
          BoxShadow(color: _purple.withValues(alpha: 0.06), blurRadius: 26),
        ],
      ),

      child: Row(
        children: [
          Container(
            width: 50,

            height: 50,

            decoration: BoxDecoration(
              color: _purple.withValues(alpha: 0.12),

              borderRadius: BorderRadius.circular(16),

              border: Border.all(color: _purple.withValues(alpha: 0.22)),
            ),

            child: const Icon(
              Icons.groups_2_outlined,

              color: _purple,

              size: 24,
            ),
          ),

          const SizedBox(width: 14),

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

                const SizedBox(height: 4),

                const Text(
                  'Construa conexões com consentimento e liberdade.',

                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionBar() {
    return Container(
      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(
        color: _purple.withValues(alpha: 0.07),

        borderRadius: BorderRadius.circular(16),

        border: Border.all(color: _purple.withValues(alpha: 0.22)),
      ),

      child: Row(
        children: [
          Container(
            width: 34,

            height: 34,

            alignment: Alignment.center,

            decoration: BoxDecoration(
              color: _purple.withValues(alpha: 0.13),

              shape: BoxShape.circle,
            ),

            child: Text(
              '$_selectedCount',

              style: const TextStyle(
                color: _purple,

                fontSize: 11,

                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              _selectedCount == 1
                  ? '1 membro selecionado'
                  : '$_selectedCount membros selecionados',

              style: const TextStyle(
                color: Colors.white70,

                fontSize: 11,

                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          FilledButton.icon(
            onPressed: _communicationController.isProcessing
                ? null
                : _inviteSelectedMembers,

            icon: _communicationController.isProcessing
                ? const SizedBox(
                    width: 13,

                    height: 13,

                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.videocam_rounded, size: 15),

            label: const Text(
              'Convidar',

              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
            ),

            style: FilledButton.styleFrom(
              backgroundColor: _purple,

              foregroundColor: Colors.white,

              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomingVideoRequest(CommunicationRequestModel request) {
    final member = _memberByUserId(request.senderId);

    final name = member?.displayName ?? 'Membro';

    return Container(
      margin: const EdgeInsets.only(bottom: 9),

      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: _surface,

        borderRadius: BorderRadius.circular(18),

        border: Border.all(color: _purple.withValues(alpha: 0.22)),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Container(
                width: 38,

                height: 38,

                decoration: BoxDecoration(
                  color: _purple.withValues(alpha: 0.12),

                  borderRadius: BorderRadius.circular(12),
                ),

                child: const Icon(
                  Icons.videocam_rounded,

                  color: _purple,

                  size: 19,
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      '$name quer liberar vídeo',

                      maxLines: 1,

                      overflow: TextOverflow.ellipsis,

                      style: const TextStyle(
                        color: Colors.white,

                        fontSize: 12,

                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      request.attemptLabel,

                      style: const TextStyle(
                        color: Colors.white38,

                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            _incomingRequestDescription(request),

            style: const TextStyle(
              color: Colors.white54,

              fontSize: 10,

              height: 1.4,
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _communicationController.isProcessing
                      ? null
                      : () {
                          _rejectRequest(request);
                        },

                  style: OutlinedButton.styleFrom(
                    foregroundColor: _red,

                    side: BorderSide(color: _red.withValues(alpha: 0.30)),

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),

                  child: const Text(
                    'Recusar',

                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: FilledButton(
                  onPressed: _communicationController.isProcessing
                      ? null
                      : () {
                          _acceptRequest(request);
                        },

                  style: FilledButton.styleFrom(
                    backgroundColor: _purple,

                    foregroundColor: Colors.white,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),

                  child: const Text(
                    'Aceitar',

                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _incomingRequestDescription(CommunicationRequestModel request) {
    if (request.isFirstAttempt) {
      return 'Ao aceitar, o vídeo ficará liberado '
          'entre vocês nesta Studio Session.';
    }

    if (request.isSecondAttempt) {
      return 'Este é o segundo convite deste membro. '
          'O vídeo continua dependendo da sua decisão.';
    }

    return 'Este é o terceiro convite. '
        'Se você recusar novamente, novos convites '
        'ficarão bloqueados até você liberar.';
  }

  Widget _buildRecruitmentButton() {
    return Material(
      color: Colors.transparent,

      child: InkWell(
        onTap: _openCreateRecruitment,

        borderRadius: BorderRadius.circular(18),

        child: Ink(
          padding: const EdgeInsets.all(15),

          decoration: BoxDecoration(
            color: _purple.withValues(alpha: 0.08),

            borderRadius: BorderRadius.circular(18),

            border: Border.all(color: _purple.withValues(alpha: 0.22)),
          ),

          child: Row(
            children: [
              Container(
                width: 42,

                height: 42,

                decoration: BoxDecoration(
                  color: _purple.withValues(alpha: 0.14),

                  borderRadius: BorderRadius.circular(13),
                ),

                child: const Icon(
                  Icons.person_search_rounded,

                  color: _purple,

                  size: 21,
                ),
              ),

              const SizedBox(width: 12),

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

                    SizedBox(height: 3),

                    Text(
                      'Abra uma busca por função para expandir a sessão.',

                      style: TextStyle(color: Colors.white38, fontSize: 10),
                    ),
                  ],
                ),
              ),

              const Icon(Icons.add_rounded, color: _purple, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecruitmentCard(ProjectRecruitmentModel recruitment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),

      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: _surface,

        borderRadius: BorderRadius.circular(18),

        border: Border.all(color: _orange.withValues(alpha: 0.16)),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Container(
                width: 38,

                height: 38,

                decoration: BoxDecoration(
                  color: _orange.withValues(alpha: 0.10),

                  borderRadius: BorderRadius.circular(12),
                ),

                child: const Icon(
                  Icons.radar_rounded,

                  color: _orange,

                  size: 19,
                ),
              ),

              const SizedBox(width: 11),

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

                    const SizedBox(height: 2),

                    const Row(
                      children: [
                        _RecruitmentStatusDot(),

                        SizedBox(width: 5),

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

          if (recruitment.description.trim().isNotEmpty) ...[
            const SizedBox(height: 12),

            Text(
              recruitment.description,

              style: const TextStyle(
                color: Colors.white54,

                fontSize: 11,

                height: 1.4,
              ),
            ),
          ],

          const SizedBox(height: 13),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _openCandidates(recruitment);
                  },

                  icon: const Icon(Icons.people_outline_rounded, size: 16),

                  label: const Text('Ver candidatos'),

                  style: OutlinedButton.styleFrom(
                    foregroundColor: _purple,

                    side: BorderSide(color: _purple.withValues(alpha: 0.40)),

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),

                    textStyle: const TextStyle(
                      fontSize: 10,

                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              IconButton(
                tooltip: 'Encerrar busca',

                onPressed: () {
                  _closeRecruitment(recruitment);
                },

                style: IconButton.styleFrom(
                  backgroundColor: Colors.redAccent.withValues(alpha: 0.07),
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

  Widget _buildMemberCard(ProjectMemberModel member) {
    final isCurrentUser = _membersController.isCurrentUser(member);

    final userId = member.userId;

    final selected = _selectedMemberIds.contains(userId);

    final expanded = !isCurrentUser && _isMemberExpanded(userId);

    final permission = isCurrentUser
        ? null
        : _communicationController.permissionForUser(userId);

    final inviteState = isCurrentUser
        ? null
        : _communicationController.inviteStateForUser(userId);

    final incomingState = isCurrentUser
        ? null
        : _communicationController.incomingInviteStateFrom(userId);

    final videoAllowed = permission?.videoAllowed ?? false;

    final processing = _communicationController.isProcessingUser(userId);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),

      decoration: BoxDecoration(
        color: _surface,

        borderRadius: BorderRadius.circular(18),

        border: Border.all(
          color: selected
              ? _purple.withValues(alpha: 0.55)
              : isCurrentUser
              ? _purple.withValues(alpha: 0.30)
              : Colors.white.withValues(alpha: 0.05),
        ),
      ),

      child: AnimatedSize(
        duration: const Duration(milliseconds: 180),

        curve: Curves.easeInOut,

        alignment: Alignment.topCenter,

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            Material(
              color: Colors.transparent,

              child: InkWell(
                onTap: isCurrentUser
                    ? null
                    : () {
                        _toggleMemberSelection(member);
                      },

                borderRadius: BorderRadius.circular(18),

                child: Padding(
                  padding: const EdgeInsets.all(14),

                  child: Row(
                    children: [
                      if (!isCurrentUser) ...[
                        _buildSelectionIndicator(selected),

                        const SizedBox(width: 11),
                      ],

                      _buildAvatar(member),

                      const SizedBox(width: 13),

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
                                  const SizedBox(width: 7),

                                  _buildYouBadge(),
                                ],
                              ],
                            ),

                            if (member.usernameLabel.isNotEmpty) ...[
                              const SizedBox(height: 2),

                              Text(
                                member.usernameLabel,

                                style: const TextStyle(
                                  color: Colors.white38,

                                  fontSize: 10,
                                ),
                              ),
                            ],

                            const SizedBox(height: 8),

                            Wrap(
                              spacing: 7,

                              runSpacing: 6,

                              children: [
                                _buildRoleChip(member.roleLabel),

                                _buildStatusChip(member.isOnline),

                                if (!isCurrentUser) _buildVideoChip(userId),
                              ],
                            ),
                          ],
                        ),
                      ),

                      if (!isCurrentUser) ...[
                        const SizedBox(width: 8),

                        Tooltip(
                          message: expanded ? 'Recolher' : 'Ver comunicação',

                          child: Material(
                            color: Colors.transparent,

                            child: InkWell(
                              onTap: () {
                                _toggleMemberExpanded(userId);
                              },

                              customBorder: const CircleBorder(),

                              child: Container(
                                width: 34,

                                height: 34,

                                alignment: Alignment.center,

                                decoration: BoxDecoration(
                                  color: expanded
                                      ? _purple.withValues(alpha: 0.12)
                                      : Colors.white.withValues(alpha: 0.035),

                                  shape: BoxShape.circle,

                                  border: Border.all(
                                    color: expanded
                                        ? _purple.withValues(alpha: 0.28)
                                        : Colors.white.withValues(alpha: 0.06),
                                  ),
                                ),

                                child: AnimatedRotation(
                                  turns: expanded ? 0.5 : 0,

                                  duration: const Duration(milliseconds: 180),

                                  child: Icon(
                                    Icons.keyboard_arrow_down_rounded,

                                    color: expanded ? _purple : Colors.white38,

                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            if (!isCurrentUser && expanded) ...[
              Container(
                height: 1,

                margin: const EdgeInsets.symmetric(horizontal: 14),

                color: Colors.white.withValues(alpha: 0.04),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),

                child: CommunicationPermissionCard(
                  permission: permission,

                  inviteState: inviteState,

                  audioAllowed: _communicationController.isAudioAllowedFor(
                    userId,
                  ),

                  displayName: member.displayName,

                  username: member.usernameLabel,

                  requestInProgress: processing,

                  onRequestVideo:
                      _communicationController.canInviteVideo(userId)
                      ? () {
                          _inviteMember(member);
                        }
                      : null,
                ),
              ),

              if (videoAllowed) _buildRevokeVideoAction(member),

              if (incomingState?.blockedAfterLimit == true)
                _buildAllowInviteAction(member),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionIndicator(bool selected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),

      width: 22,

      height: 22,

      decoration: BoxDecoration(
        color: selected ? _purple : Colors.transparent,

        borderRadius: BorderRadius.circular(7),

        border: Border.all(color: selected ? _purple : Colors.white24),
      ),

      child: selected
          ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
          : null,
    );
  }

  Widget _buildYouBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),

      decoration: BoxDecoration(
        color: _purple.withValues(alpha: 0.13),

        borderRadius: BorderRadius.circular(20),
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
    );
  }

  Widget _buildVideoChip(String userId) {
    final permission = _communicationController.permissionForUser(userId);

    final state = _communicationController.inviteStateForUser(userId);

    final pending = _communicationController.hasPendingRequestTo(userId);

    Color color;

    IconData icon;

    String text;

    if (permission?.videoAllowed == true) {
      color = _green;

      icon = Icons.videocam_rounded;

      text = 'Vídeo';
    } else if (pending) {
      color = _purple;

      icon = Icons.schedule_send_rounded;

      text = 'Pendente';
    } else if (state?.blockedAfterLimit == true) {
      color = _red;

      icon = Icons.block_rounded;

      text = 'Bloqueado';
    } else if (state?.hasCooldown == true) {
      color = _orange;

      icon = Icons.schedule_rounded;

      text = state!.cooldownLabel.isEmpty ? 'Aguardar' : state.cooldownLabel;
    } else {
      color = Colors.white30;

      icon = Icons.videocam_off_rounded;

      text = 'Áudio';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),

      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),

        borderRadius: BorderRadius.circular(20),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,

        children: [
          Icon(icon, color: color, size: 11),

          const SizedBox(width: 4),

          Text(
            text,

            style: TextStyle(
              color: color,

              fontSize: 8,

              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevokeVideoAction(ProjectMemberModel member) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),

      child: SizedBox(
        width: double.infinity,

        child: TextButton.icon(
          onPressed: _communicationController.isProcessing
              ? null
              : () {
                  _revokeVideo(member);
                },

          icon: const Icon(Icons.videocam_off_rounded, size: 15),

          label: const Text(
            'Remover consentimento de vídeo',

            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
          ),

          style: TextButton.styleFrom(foregroundColor: Colors.white38),
        ),
      ),
    );
  }

  Widget _buildAllowInviteAction(ProjectMemberModel member) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),

      child: Container(
        width: double.infinity,

        padding: const EdgeInsets.all(11),

        decoration: BoxDecoration(
          color: _orange.withValues(alpha: 0.055),

          borderRadius: BorderRadius.circular(13),

          border: Border.all(color: _orange.withValues(alpha: 0.12)),
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              'Você bloqueou novos convites deste membro',

              style: TextStyle(
                color: Colors.white70,

                fontSize: 10,

                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 3),

            const Text(
              'Se quiser, você pode permitir que ele '
              'faça uma nova solicitação de vídeo.',

              style: TextStyle(
                color: Colors.white38,

                fontSize: 9,

                height: 1.35,
              ),
            ),

            const SizedBox(height: 8),

            OutlinedButton.icon(
              onPressed: _communicationController.isProcessing
                  ? null
                  : () {
                      _allowNewInviteFrom(member);
                    },

              icon: const Icon(Icons.lock_open_rounded, size: 14),

              label: const Text(
                'Permitir novo convite',

                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
              ),

              style: OutlinedButton.styleFrom(
                foregroundColor: _orange,

                side: BorderSide(color: _orange.withValues(alpha: 0.30)),

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(ProjectMemberModel member) {
    final avatarUrl = member.avatarUrl;

    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return Container(
        width: 50,

        height: 50,

        decoration: BoxDecoration(
          shape: BoxShape.circle,

          border: Border.all(color: _purple.withValues(alpha: 0.18)),
        ),

        child: ClipOval(
          child: Image.network(
            avatarUrl,

            fit: BoxFit.cover,

            errorBuilder: (context, error, stackTrace) {
              return _buildInitialAvatar(member);
            },
          ),
        ),
      );
    }

    return _buildInitialAvatar(member);
  }

  Widget _buildInitialAvatar(ProjectMemberModel member) {
    final name = member.displayName.trim();

    final initial = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';

    return Container(
      width: 50,

      height: 50,

      alignment: Alignment.center,

      decoration: BoxDecoration(
        color: _purple.withValues(alpha: 0.12),

        shape: BoxShape.circle,

        border: Border.all(color: _purple.withValues(alpha: 0.18)),
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

  Widget _buildRoleChip(String role) {
    final formattedRole = _formatRole(role);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),

      decoration: BoxDecoration(
        color: _purple.withValues(alpha: 0.08),

        borderRadius: BorderRadius.circular(20),

        border: Border.all(color: _purple.withValues(alpha: 0.12)),
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

  Widget _buildStatusChip(bool online) {
    final color = online ? _green : Colors.white24;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),

      decoration: BoxDecoration(
        color: color.withValues(alpha: online ? 0.08 : 0.04),

        borderRadius: BorderRadius.circular(20),
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
                        color: color.withValues(alpha: 0.35),

                        blurRadius: 6,
                      ),
                    ]
                  : null,
            ),
          ),

          const SizedBox(width: 5),

          Text(
            online ? 'Online' : 'Offline',

            style: TextStyle(
              color: online ? color : Colors.white30,

              fontSize: 9,

              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunicationError() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.07),

        borderRadius: BorderRadius.circular(14),
      ),

      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,

            color: Colors.redAccent,

            size: 17,
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              _communicationController.errorMessage ??
                  'Erro nas permissões de comunicação.',

              style: const TextStyle(color: Colors.redAccent, fontSize: 10),
            ),
          ),

          IconButton(
            onPressed: _communicationController.clearError,

            icon: const Icon(
              Icons.close_rounded,

              size: 15,

              color: Colors.white38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecruitmentError() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.07),

        borderRadius: BorderRadius.circular(14),
      ),

      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,

            color: Colors.redAccent,

            size: 17,
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              _recruitmentController.errorMessage ?? 'Erro no recrutamento.',

              style: const TextStyle(color: Colors.redAccent, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  String _formatRole(String value) {
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

  Widget _buildEmptyMembersInline() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(22),

      decoration: BoxDecoration(
        color: _surface,

        borderRadius: BorderRadius.circular(18),
      ),

      child: const Column(
        children: [
          Icon(Icons.group_off_outlined, color: Colors.white24, size: 30),

          SizedBox(height: 10),

          Text(
            'Nenhum membro encontrado',

            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            Container(
              width: 64,

              height: 64,

              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.08),

                borderRadius: BorderRadius.circular(20),
              ),

              child: const Icon(
                Icons.error_outline_rounded,

                color: Colors.redAccent,

                size: 30,
              ),
            ),

            const SizedBox(height: 16),

            Text(
              _membersController.errorMessage ?? 'Erro ao carregar membros.',

              textAlign: TextAlign.center,

              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),

            const SizedBox(height: 16),

            TextButton.icon(
              onPressed: _reloadAll,

              icon: const Icon(Icons.refresh_rounded),

              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _membersController.dispose();

    _recruitmentController.dispose();

    _communicationController.dispose();

    _selectedMemberIds.clear();

    _expandedMemberIds.clear();

    super.dispose();
  }
}

class _RecruitmentStatusDot extends StatelessWidget {
  const _RecruitmentStatusDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,

      height: 6,

      decoration: BoxDecoration(
        color: _MembersViewState._orange,

        shape: BoxShape.circle,

        boxShadow: [
          BoxShadow(
            color: _MembersViewState._orange.withValues(alpha: 0.45),

            blurRadius: 6,
          ),
        ],
      ),
    );
  }
}
