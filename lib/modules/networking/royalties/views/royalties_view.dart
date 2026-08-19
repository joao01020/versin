import 'package:flutter/material.dart';

import '../controllers/royalties_controller.dart';
import '../models/royalty_member_model.dart';
import '../widgets/royalty_agreement_status_widget.dart';
import '../widgets/royalty_approvals_widget.dart';
import '../widgets/royalty_distribution_widget.dart';
import '../widgets/royalty_integrity_widget.dart';
import '../widgets/royalty_timeline_widget.dart';

// ============================================================
// ROYALTIES VIEW
// ============================================================
//
// Tela principal do módulo de royalties.
//
// RESPONSABILIDADES:
//
// - apresentar o estado do acordo;
// - permitir montar nova proposta;
// - permitir cada membro confirmar sua própria parte;
// - apresentar progresso do consenso;
// - apresentar integridade;
// - apresentar histórico.
//
// NÃO:
//
// - acessa Supabase;
// - executa RPC diretamente;
// - conhece RLS;
// - calcula hash oficial;
// - confirma acordo manualmente.
//
// FLUXO:
//
// Usuário propõe divisão
//        ↓
// PostgreSQL cria versão
//        ↓
// membros confirmam individualmente
//        ↓
// último membro confirma
//        ↓
// RPC fecha automaticamente
//        ↓
// SHA-256
//        ↓
// agreement = confirmed
//        ↓
// evento final
//
// ============================================================

class RoyaltiesView
    extends
        StatefulWidget {
  final String projectId;

  final RoyaltiesController controller;

  const RoyaltiesView({
    super.key,
    required this.projectId,
    required this.controller,
  });

  @override
  State<
    RoyaltiesView
  >
  createState() => _RoyaltiesViewState();
}

// ============================================================
// STATE
// ============================================================

class _RoyaltiesViewState
    extends
        State<
          RoyaltiesView
        > {
  // ============================================================
  // LOCAL DRAFT
  // ============================================================
  //
  // Estado temporário da proposta enquanto está sendo editada.
  //
  // Não representa estado oficial do banco.
  //
  // ============================================================

  final Map<
    String,
    double
  >
  _draftPercentages =
      <
        String,
        double
      >{};

  // ============================================================
  // EDITING
  // ============================================================

  bool _isEditing = false;

  bool _initializedDraft = false;

  // ============================================================
  // CONTROLLER
  // ============================================================

  RoyaltiesController get _controller => widget.controller;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _controller.addListener(
      _handleControllerChanged,
    );

    WidgetsBinding.instance.addPostFrameCallback(
      (
        _,
      ) {
        if (!mounted) {
          return;
        }

        _initialize();
      },
    );
  }

  // ============================================================
  // DID UPDATE WIDGET
  // ============================================================

  @override
  void didUpdateWidget(
    covariant RoyaltiesView oldWidget,
  ) {
    super.didUpdateWidget(
      oldWidget,
    );

    // ==========================================================
    // CONTROLLER CHANGED
    // ==========================================================

    if (oldWidget.controller !=
        widget.controller) {
      oldWidget.controller.removeListener(
        _handleControllerChanged,
      );

      widget.controller.addListener(
        _handleControllerChanged,
      );

      _resetLocalDraft();

      WidgetsBinding.instance.addPostFrameCallback(
        (
          _,
        ) {
          if (!mounted) {
            return;
          }

          _initialize();
        },
      );

      return;
    }

    // ==========================================================
    // PROJECT CHANGED
    // ==========================================================

    if (oldWidget.projectId !=
        widget.projectId) {
      _resetLocalDraft();

      WidgetsBinding.instance.addPostFrameCallback(
        (
          _,
        ) {
          if (!mounted) {
            return;
          }

          _initialize();
        },
      );
    }
  }

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<
    void
  >
  _initialize() async {
    final projectId = widget.projectId.trim();

    if (projectId.isEmpty) {
      return;
    }

    // ==========================================================
    // ALREADY INITIALIZED FOR SAME PROJECT
    // ==========================================================

    if (_controller.isInitialized &&
        _controller.projectId ==
            projectId) {
      _syncDraftFromController();

      return;
    }

    // ==========================================================
    // CURRENT USER
    // ==========================================================

    final currentUserId = _controller.currentUserId?.trim();

    if (currentUserId ==
            null ||
        currentUserId.isEmpty) {
      return;
    }

    // ==========================================================
    // LOAD
    // ==========================================================

    await _controller.load(
      projectId: projectId,
      currentUserId: currentUserId,
    );

    if (!mounted) {
      return;
    }

    _syncDraftFromController();
  }

  // ============================================================
  // CONTROLLER CHANGED
  // ============================================================

  void _handleControllerChanged() {
    if (!mounted) {
      return;
    }

    // ==========================================================
    // INITIAL DRAFT
    // ==========================================================

    if (!_isEditing &&
        !_initializedDraft &&
        !_controller.isLoading) {
      _syncDraftFromController(
        notify: false,
      );
    }

    setState(
      () {},
    );
  }

  // ============================================================
  // RESET LOCAL DRAFT
  // ============================================================

  void _resetLocalDraft() {
    _draftPercentages.clear();

    _initializedDraft = false;

    _isEditing = false;
  }

  // ============================================================
  // SYNC DRAFT
  // ============================================================

  void _syncDraftFromController({
    bool notify = true,
  }) {
    _draftPercentages.clear();

    // ==========================================================
    // CURRENT AGREEMENT
    // ==========================================================

    if (_controller.shares.isNotEmpty) {
      for (final member in _controller.members) {
        _draftPercentages[member.userId] = _controller.percentageForUser(
          member.userId,
        );
      }
    }
    // ==========================================================
    // NO AGREEMENT
    // ==========================================================
    else {
      for (final member in _controller.members) {
        _draftPercentages[member.userId] = 0;
      }
    }

    _initializedDraft = true;

    if (notify &&
        mounted) {
      setState(
        () {},
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: const Color(
        0xFF0F0F0F,
      ),

      // ========================================================
      // APP BAR
      // ========================================================
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        title: const Text(
          'Royalties',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_controller.isInitialized)
            IconButton(
              tooltip: 'Atualizar',
              onPressed: _controller.isLoading
                  ? null
                  : _refresh,
              icon: const Icon(
                Icons.refresh_rounded,
                size: 19,
              ),
            ),
        ],
      ),

      // ========================================================
      // BODY
      // ========================================================
      body: SafeArea(
        top: false,
        child: _buildBody(),
      ),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    // ==========================================================
    // LOADING
    // ==========================================================

    if (_controller.isLoading &&
        !_controller.isInitialized) {
      return _buildLoading();
    }

    // ==========================================================
    // NOT INITIALIZED
    // ==========================================================

    if (!_controller.isInitialized) {
      if (_controller.hasError) {
        return _buildError();
      }

      return _buildNotInitialized();
    }

    // ==========================================================
    // CONTENT
    // ==========================================================

    return RefreshIndicator(
      onRefresh: _refresh,
      color: const Color(
        0xFFE100FF,
      ),
      backgroundColor: const Color(
        0xFF18181D,
      ),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          16,
          10,
          16,
          32,
        ),
        children: [
          // ====================================================
          // INLINE ERROR
          // ====================================================
          if (_controller.hasError) ...[
            _buildInlineError(),

            const SizedBox(
              height: 14,
            ),
          ],

          // ====================================================
          // HEADER
          // ====================================================
          _buildHeader(),

          const SizedBox(
            height: 18,
          ),

          // ====================================================
          // AGREEMENT STATUS
          // ====================================================
          RoyaltyAgreementStatusWidget(
            agreement: _controller.currentAgreement,
            totalPercentage: _controller.totalPercentage,
            approvedCount: _controller.approvedCount,
            memberCount: _controller.memberCount,
            allApproved: _controller.allApproved,
          ),

          const SizedBox(
            height: 22,
          ),

          // ====================================================
          // DISTRIBUTION
          // ====================================================
          _buildSectionHeader(
            icon: Icons.pie_chart_outline_rounded,
            title: 'Divisão',
            subtitle: _distributionSubtitle,
            action: _buildDistributionAction(),
          ),

          const SizedBox(
            height: 10,
          ),

          RoyaltyDistributionWidget(
            members: _controller.members,
            percentagesByUserId: _displayPercentages,
            editable: _isEditing,
            currentUserId: _controller.currentUserId,
            onPercentageChanged: _isEditing
                ? _handlePercentageChanged
                : null,
          ),

          // ====================================================
          // DRAFT
          // ====================================================
          if (_isEditing) ...[
            const SizedBox(
              height: 12,
            ),

            _buildDraftStatus(),

            const SizedBox(
              height: 12,
            ),

            _buildProposalActions(),
          ],

          const SizedBox(
            height: 24,
          ),

          // ====================================================
          // CONSENSUS
          // ====================================================
          _buildSectionHeader(
            icon: Icons.how_to_reg_outlined,
            title: 'Consenso',
            subtitle: 'Cada participante confirma apenas a própria decisão.',
          ),

          const SizedBox(
            height: 10,
          ),

          RoyaltyApprovalsWidget(
            members: _controller.members,
            approvedUserIds: _approvedUserIds,
            currentUserId: _controller.currentUserId,
            agreementLocked: _controller.isLocked,
            canApproveCurrentUser: _controller.canApprove,
            isApproving: _controller.isApproving,
            onApproveCurrentUser: _approveCurrentUser,
          ),

          const SizedBox(
            height: 24,
          ),

          // ====================================================
          // INTEGRITY
          // ====================================================
          _buildSectionHeader(
            icon: Icons.security_rounded,
            title: 'Integridade',
            subtitle: 'Registro verificável da versão aprovada.',
          ),

          const SizedBox(
            height: 10,
          ),

          RoyaltyIntegrityWidget(
            agreement: _controller.currentAgreement,
            approvalCount: _controller.approvedCount,
            memberCount: _controller.memberCount,
            integrityValid: _controller.verifyCurrentAgreementIntegrity(),
            onCreateNewVersion:
                _controller.isConfirmed &&
                    !_controller.isPerformingAction
                ? _startNewVersion
                : null,
          ),

          const SizedBox(
            height: 24,
          ),

          // ====================================================
          // HISTORY
          // ====================================================
          _buildSectionHeader(
            icon: Icons.history_rounded,
            title: 'Histórico',
            subtitle: 'Registro das decisões relacionadas aos royalties.',
          ),

          const SizedBox(
            height: 10,
          ),

          RoyaltyTimelineWidget(
            events: _controller.events,
            resolveMember: _controller.findMember,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    final agreement = _controller.currentAgreement;

    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color:
                const Color(
                  0xFFE100FF,
                ).withValues(
                  alpha: 0.08,
                ),
            borderRadius: BorderRadius.circular(
              12,
            ),
          ),
          child: const Icon(
            Icons.percent_rounded,
            color: Color(
              0xFFE100FF,
            ),
            size: 19,
          ),
        ),

        const SizedBox(
          width: 11,
        ),

        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Acordo de royalties',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),

              SizedBox(
                height: 2,
              ),

              Text(
                'Construa a divisão junto com os participantes.',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),

        if (agreement !=
            null)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.035,
              ),
              borderRadius: BorderRadius.circular(
                20,
              ),
              border: Border.all(
                color: Colors.white.withValues(
                  alpha: 0.05,
                ),
              ),
            ),
            child: Text(
              'VERSÃO ${agreement.version}',
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 7,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // SECTION HEADER
  // ============================================================

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? action,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: Colors.white38,
          size: 16,
        ),

        const SizedBox(
          width: 7,
        ),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(
                height: 2,
              ),

              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.white30,
                  fontSize: 8,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),

        if (action !=
            null) ...[
          const SizedBox(
            width: 10,
          ),

          action,
        ],
      ],
    );
  }

  // ============================================================
  // DISTRIBUTION ACTION
  // ============================================================

  Widget? _buildDistributionAction() {
    if (_controller.members.isEmpty ||
        _controller.isPerformingAction) {
      return null;
    }

    // ==========================================================
    // EDITING
    // ==========================================================

    if (_isEditing) {
      return null;
    }

    // ==========================================================
    // CONFIRMED
    // ==========================================================

    if (_controller.isConfirmed) {
      return TextButton.icon(
        onPressed: _startNewVersion,
        icon: const Icon(
          Icons.add_rounded,
          size: 14,
        ),
        label: const Text(
          'NOVA PROPOSTA',
          style: TextStyle(
            fontSize: 7,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    // ==========================================================
    // EXISTING PROPOSAL
    // ==========================================================

    if (_controller.hasCurrentAgreement) {
      return TextButton.icon(
        onPressed: _startNewVersion,
        icon: const Icon(
          Icons.edit_outlined,
          size: 13,
        ),
        label: const Text(
          'REVISAR',
          style: TextStyle(
            fontSize: 7,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    // ==========================================================
    // FIRST PROPOSAL
    // ==========================================================

    if (_controller.canCreateProposal) {
      return TextButton.icon(
        onPressed: _startEditing,
        icon: const Icon(
          Icons.add_rounded,
          size: 14,
        ),
        label: const Text(
          'DEFINIR',
          style: TextStyle(
            fontSize: 7,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return null;
  }

  // ============================================================
  // DRAFT STATUS
  // ============================================================

  Widget _buildDraftStatus() {
    final total = _draftTotal;

    final valid = _draftHasCorrectTotal;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: valid
            ? Colors.green.withValues(
                alpha: 0.035,
              )
            : Colors.orange.withValues(
                alpha: 0.035,
              ),
        borderRadius: BorderRadius.circular(
          12,
        ),
        border: Border.all(
          color: valid
              ? Colors.greenAccent.withValues(
                  alpha: 0.12,
                )
              : Colors.orangeAccent.withValues(
                  alpha: 0.12,
                ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            valid
                ? Icons.check_circle_outline
                : Icons.info_outline_rounded,
            color: valid
                ? Colors.greenAccent
                : Colors.orangeAccent,
            size: 15,
          ),

          const SizedBox(
            width: 8,
          ),

          Expanded(
            child: Text(
              valid
                  ? 'A divisão está pronta para ser proposta.'
                  : 'Distribua exatamente 100% entre os participantes.',
              style: TextStyle(
                color: valid
                    ? Colors.greenAccent
                    : Colors.orangeAccent,
                fontSize: 9,
              ),
            ),
          ),

          Text(
            _formatPercentage(
              total,
            ),
            style: TextStyle(
              color: valid
                  ? Colors.greenAccent
                  : Colors.orangeAccent,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PROPOSAL ACTIONS
  // ============================================================

  Widget _buildProposalActions() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 42,
            child: OutlinedButton(
              onPressed: _controller.isSubmittingProposal
                  ? null
                  : _cancelEditing,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white54,
                side: BorderSide(
                  color: Colors.white.withValues(
                    alpha: 0.08,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    12,
                  ),
                ),
              ),
              child: const Text(
                'CANCELAR',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(
          width: 10,
        ),

        Expanded(
          flex: 2,
          child: SizedBox(
            height: 42,
            child: FilledButton.icon(
              onPressed:
                  !_draftHasCorrectTotal ||
                      _controller.isSubmittingProposal
                  ? null
                  : _submitProposal,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(
                  0xFFE100FF,
                ),
                foregroundColor: Colors.black,
                disabledBackgroundColor: Colors.white.withValues(
                  alpha: 0.04,
                ),
                disabledForegroundColor: Colors.white24,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    12,
                  ),
                ),
              ),
              icon: _controller.isSubmittingProposal
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.send_outlined,
                      size: 16,
                    ),
              label: Text(
                _controller.isSubmittingProposal
                    ? 'ENVIANDO...'
                    : 'PROPOR DIVISÃO',
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // INLINE ERROR
  // ============================================================

  Widget _buildInlineError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        12,
      ),
      decoration: BoxDecoration(
        color: Colors.red.withValues(
          alpha: 0.05,
        ),
        borderRadius: BorderRadius.circular(
          12,
        ),
        border: Border.all(
          color: Colors.redAccent.withValues(
            alpha: 0.14,
          ),
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
            width: 9,
          ),

          Expanded(
            child: Text(
              _controller.errorMessage ??
                  'Ocorreu um erro.',
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 9,
              ),
            ),
          ),

          IconButton(
            tooltip: 'Fechar',
            onPressed: _controller.clearError,
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              Icons.close_rounded,
              color: Colors.redAccent,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(
                0xFFE100FF,
              ),
            ),
          ),

          SizedBox(
            height: 12,
          ),

          Text(
            'Carregando royalties...',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(
          28,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent,
              size: 35,
            ),

            const SizedBox(
              height: 12,
            ),

            const Text(
              'Não foi possível carregar os royalties',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(
              height: 7,
            ),

            Text(
              _controller.errorMessage ??
                  'Tente novamente.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 9,
                height: 1.4,
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            OutlinedButton.icon(
              onPressed: _initialize,
              icon: const Icon(
                Icons.refresh_rounded,
                size: 16,
              ),
              label: const Text(
                'TENTAR NOVAMENTE',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // NOT INITIALIZED
  // ============================================================

  Widget _buildNotInitialized() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(
          28,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.percent_rounded,
              color: Colors.white24,
              size: 34,
            ),

            SizedBox(
              height: 12,
            ),

            Text(
              'Royalties ainda não inicializados',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),

            SizedBox(
              height: 6,
            ),

            Text(
              'O projeto e o usuário atual precisam estar definidos antes de carregar o acordo.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white30,
                fontSize: 9,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DISPLAY PERCENTAGES
  // ============================================================

  Map<
    String,
    double
  >
  get _displayPercentages {
    if (_isEditing) {
      return Map<
        String,
        double
      >.unmodifiable(
        _draftPercentages,
      );
    }

    final percentages =
        <
          String,
          double
        >{};

    for (final member in _controller.members) {
      percentages[member.userId] = _controller.percentageForUser(
        member.userId,
      );
    }

    return percentages;
  }

  // ============================================================
  // APPROVED USER IDS
  // ============================================================

  Set<
    String
  >
  get _approvedUserIds {
    return _controller.approvals
        .map(
          (
            approval,
          ) => approval.userId,
        )
        .where(
          (
            userId,
          ) => userId.trim().isNotEmpty,
        )
        .toSet();
  }

  // ============================================================
  // DISTRIBUTION SUBTITLE
  // ============================================================

  String get _distributionSubtitle {
    if (_isEditing) {
      return 'Ajuste a participação até totalizar 100%.';
    }

    if (_controller.isConfirmed) {
      return 'Divisão aprovada e registrada nesta versão.';
    }

    if (_controller.hasCurrentAgreement) {
      return 'Proposta atual enviada aos participantes.';
    }

    return 'Nenhuma porcentagem foi definida ainda.';
  }

  // ============================================================
  // DRAFT TOTAL
  // ============================================================

  double get _draftTotal {
    return _controller.members.fold<
      double
    >(
      0,
      (
        total,
        member,
      ) {
        return total +
            (_draftPercentages[member.userId] ??
                0);
      },
    );
  }

  // ============================================================
  // DRAFT VALID
  // ============================================================

  bool get _draftHasCorrectTotal {
    return (_draftTotal -
                100)
            .abs() <
        0.0001;
  }

  // ============================================================
  // START EDITING
  // ============================================================

  void _startEditing() {
    if (_controller.members.isEmpty) {
      _showMessage(
        'Nenhum participante encontrado no projeto.',
        error: true,
      );

      return;
    }

    _syncDraftFromController(
      notify: false,
    );

    setState(
      () {
        _isEditing = true;
      },
    );
  }

  // ============================================================
  // START NEW VERSION
  // ============================================================

  void _startNewVersion() {
    if (_controller.members.isEmpty) {
      return;
    }

    _syncDraftFromController(
      notify: false,
    );

    setState(
      () {
        _isEditing = true;
      },
    );
  }

  // ============================================================
  // CANCEL EDITING
  // ============================================================

  void _cancelEditing() {
    _syncDraftFromController(
      notify: false,
    );

    setState(
      () {
        _isEditing = false;
      },
    );
  }

  // ============================================================
  // CHANGE PERCENTAGE
  // ============================================================

  void _handlePercentageChanged(
    RoyaltyMemberModel member,
    double percentage,
  ) {
    if (!_isEditing) {
      return;
    }

    setState(
      () {
        _draftPercentages[member.userId] = percentage.clamp(
          0.0,
          100.0,
        );
      },
    );
  }

  // ============================================================
  // SUBMIT PROPOSAL
  // ============================================================

  Future<
    void
  >
  _submitProposal() async {
    if (!_draftHasCorrectTotal) {
      _showMessage(
        'A divisão precisa totalizar exatamente 100%.',
        error: true,
      );

      return;
    }

    try {
      final percentages =
          Map<
            String,
            double
          >.from(
            _draftPercentages,
          );

      await _controller.proposeDistribution(
        percentagesByUserId: percentages,
      );

      if (!mounted) {
        return;
      }

      _syncDraftFromController(
        notify: false,
      );

      setState(
        () {
          _isEditing = false;
        },
      );

      _showMessage(
        'Proposta enviada aos participantes.',
      );
    } catch (
      error
    ) {
      if (!mounted) {
        return;
      }

      _showMessage(
        _resolveErrorMessage(
          error,
        ),
        error: true,
      );
    }
  }

  // ============================================================
  // APPROVE CURRENT USER
  // ============================================================
  //
  // Esta é a ÚNICA ação de consenso.
  //
  // Se este usuário for o último:
  //
  // approve_royalty_agreement()
  //
  // já:
  //
  // - confirma o acordo;
  // - calcula SHA-256;
  // - registra evento final.
  //
  // ============================================================

  Future<
    void
  >
  _approveCurrentUser() async {
    try {
      final result = await _controller.approveCurrentAgreement();

      if (!mounted) {
        return;
      }

      // ========================================================
      // AGREEMENT COMPLETED
      // ========================================================

      if (result.completed ||
          result.isConfirmed) {
        _showMessage(
          'Todos confirmaram. '
          'O acordo foi finalizado e o registro de integridade foi criado.',
        );

        return;
      }

      // ========================================================
      // STILL WAITING
      // ========================================================

      final pending =
          result.requiredCount -
          result.approvedCount;

      if (pending <=
          0) {
        _showMessage(
          'Sua confirmação foi registrada.',
        );

        return;
      }

      if (pending ==
          1) {
        _showMessage(
          'Sua confirmação foi registrada. '
          'Falta 1 participante.',
        );

        return;
      }

      _showMessage(
        'Sua confirmação foi registrada. '
        'Faltam $pending participantes.',
      );
    } catch (
      error
    ) {
      if (!mounted) {
        return;
      }

      _showMessage(
        _resolveErrorMessage(
          error,
        ),
        error: true,
      );
    }
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<
    void
  >
  _refresh() async {
    try {
      await _controller.refresh();

      if (!mounted) {
        return;
      }

      if (!_isEditing) {
        _syncDraftFromController();
      }
    } catch (
      error
    ) {
      if (!mounted) {
        return;
      }

      _showMessage(
        _resolveErrorMessage(
          error,
        ),
        error: true,
      );
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message, {
    bool error = false,
  }) {
    if (!mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(
      context,
    );

    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
          ),
        ),
        backgroundColor: error
            ? const Color(
                0xFF7F1D1D,
              )
            : const Color(
                0xFF2D1734,
              ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // ERROR MESSAGE
  // ============================================================

  String _resolveErrorMessage(
    Object error,
  ) {
    if (error
        is StateError) {
      return error.message.toString();
    }

    if (error
        is ArgumentError) {
      return error.message?.toString() ??
          'Dados inválidos.';
    }

    final message = error.toString();

    if (message.startsWith(
      'Exception: ',
    )) {
      return message.substring(
        11,
      );
    }

    return message;
  }

  // ============================================================
  // FORMAT PERCENTAGE
  // ============================================================

  String _formatPercentage(
    double value,
  ) {
    if (value ==
        value.roundToDouble()) {
      return '${value.toStringAsFixed(0)}%';
    }

    return '${value.toStringAsFixed(2)}%';
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _controller.removeListener(
      _handleControllerChanged,
    );

    super.dispose();
  }
}
