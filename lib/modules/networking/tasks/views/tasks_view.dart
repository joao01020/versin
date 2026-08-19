import 'package:flutter/material.dart';

import '../controllers/project_tasks_controller.dart';
import '../models/contribution_delivery_model.dart';
import '../models/project_contribution_model.dart';
import '../models/project_task_member_model.dart';
import '../widgets/production_flow_widget.dart';
import '../widgets/project_milestones_widget.dart';
import '../widgets/project_next_action_widget.dart';
import '../widgets/project_record_widget.dart';

// ============================================================
// TASKS VIEW
// ============================================================
//
// Tela principal do módulo de produção / tarefas.
//
// RESPONSABILIDADES:
//
// - montar a interface;
// - reagir ao Controller;
// - mostrar membros;
// - mostrar contribuições;
// - mostrar aprovações;
// - mostrar entregas;
// - mostrar marcos;
// - mostrar próxima ação;
// - mostrar Versin Record;
// - criar contribuição;
// - editar contribuição;
// - aprovar contribuição;
// - iniciar contribuição;
// - validar/rejeitar entrega.
//
// NÃO:
//
// - acessa Supabase;
// - faz queries;
// - calcula hashes;
// - implementa RLS;
// - executa Storage diretamente.
//
// ============================================================

class TasksView
    extends
        StatefulWidget {
  final String projectId;

  final ProjectTasksController controller;

  const TasksView({
    super.key,
    required this.projectId,
    required this.controller,
  });

  @override
  State<
    TasksView
  >
  createState() => _TasksViewState();
}

// ============================================================
// STATE
// ============================================================

class _TasksViewState
    extends
        State<
          TasksView
        > {
  // ============================================================
  // LOCAL ACTION STATE
  // ============================================================

  final Set<
    String
  >
  _approvingContributionIds =
      <
        String
      >{};

  final Set<
    String
  >
  _validatingDeliveryIds =
      <
        String
      >{};

  bool _isCreatingContribution = false;

  // ============================================================
  // GETTERS
  // ============================================================

  ProjectTasksController get _controller => widget.controller;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _controller.addListener(
      _handleControllerChange,
    );

    WidgetsBinding.instance.addPostFrameCallback(
      (
        _,
      ) {
        _initialize();
      },
    );
  }

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<
    void
  >
  _initialize() async {
    if (!mounted) {
      return;
    }

    if (_controller.isLoading ||
        _controller.isInitialized) {
      return;
    }

    final currentUserId = _controller.currentUserId?.trim();

    if (currentUserId ==
            null ||
        currentUserId.isEmpty) {
      return;
    }

    await _controller.load(
      projectId: widget.projectId,
      currentUserId: currentUserId,
    );
  }

  // ============================================================
  // CONTROLLER CHANGE
  // ============================================================

  void _handleControllerChange() {
    if (!mounted) {
      return;
    }

    setState(
      () {},
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _controller.removeListener(
      _handleControllerChange,
    );

    super.dispose();
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
        0xFF0B0B0F,
      ),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fluxo da Produção',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(
              height: 2,
            ),
            Text(
              'Contribuições do projeto',
              style: TextStyle(
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

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    if (_controller.isLoading &&
        !_controller.isInitialized) {
      return _buildLoading();
    }

    if (_controller.hasError &&
        !_controller.isInitialized) {
      return _buildError();
    }

    return RefreshIndicator(
      onRefresh: _controller.refresh,
      child: LayoutBuilder(
        builder:
            (
              context,
              constraints,
            ) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  32,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 850,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ======================================
                        // SUMMARY
                        // ======================================
                        _buildSummary(),

                        const SizedBox(
                          height: 16,
                        ),

                        // ======================================
                        // NEXT ACTION
                        // ======================================
                        _buildNextAction(),

                        const SizedBox(
                          height: 26,
                        ),

                        // ======================================
                        // PRODUCTION FLOW
                        // ======================================
                        _buildSectionHeader(
                          title: 'Produção',
                          subtitle: 'Responsabilidades, validações e entregas de cada participante.',
                        ),

                        const SizedBox(
                          height: 14,
                        ),

                        _buildProductionFlow(),

                        const SizedBox(
                          height: 26,
                        ),

                        // ======================================
                        // MILESTONES
                        // ======================================
                        _buildSectionHeader(
                          title: 'Marcos da colaboração',
                          subtitle: 'Etapas coletivas preservadas pelo projeto.',
                        ),

                        const SizedBox(
                          height: 14,
                        ),

                        _buildMilestones(),

                        const SizedBox(
                          height: 26,
                        ),

                        // ======================================
                        // RECORD
                        // ======================================
                        _buildSectionHeader(
                          title: 'Registro da colaboração',
                          subtitle: 'Histórico das ações relevantes do projeto.',
                        ),

                        const SizedBox(
                          height: 14,
                        ),

                        _buildProjectRecord(),
                      ],
                    ),
                  ),
                ),
              );
            },
      ),
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildSummary() {
    final members = _controller.members;

    final contributions = _controller.contributionCount;

    final validated = _controller.validatedContributionCount;

    final progress = _controller.progress;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        18,
      ),
      decoration: BoxDecoration(
        color: const Color(
          0xFF15151B,
        ),
        borderRadius: BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.06,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color:
                      const Color(
                        0xFFE100FF,
                      ).withValues(
                        alpha: 0.10,
                      ),
                  borderRadius: BorderRadius.circular(
                    13,
                  ),
                ),
                child: const Icon(
                  Icons.account_tree_outlined,
                  color: Color(
                    0xFFE100FF,
                  ),
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
                      'Progresso da colaboração',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(
                      height: 3,
                    ),
                    Text(
                      'Acompanhe as contribuições até a finalização.',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  color: Color(
                    0xFFE100FF,
                  ),
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 18,
          ),

          ClipRRect(
            borderRadius: BorderRadius.circular(
              20,
            ),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(
                alpha: 0.05,
              ),
              color: const Color(
                0xFFE100FF,
              ),
            ),
          ),

          const SizedBox(
            height: 15,
          ),

          Row(
            children: [
              Expanded(
                child: _buildSummaryValue(
                  value: '${members.length}',
                  label: 'Participantes',
                ),
              ),
              Expanded(
                child: _buildSummaryValue(
                  value: '$contributions',
                  label: 'Contribuições',
                ),
              ),
              Expanded(
                child: _buildSummaryValue(
                  value: '$validated',
                  label: 'Validadas',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NEXT ACTION
  // ============================================================

  Widget _buildNextAction() {
    final contribution = _controller.nextContributionAction;

    final member = _controller.nextActionMember;

    return ProjectNextActionWidget(
      member: member,
      contribution: contribution,
      allCompleted: _controller.allContributionsValidated,
      onOpen:
          contribution ==
              null
          ? null
          : () {
              _openContribution(
                contribution,
              );
            },
    );
  }

  // ============================================================
  // PRODUCTION FLOW
  // ============================================================

  Widget _buildProductionFlow() {
    return ProductionFlowWidget(
      items: _buildFlowItems(),
      currentUserId: _controller.currentUserId,
      onDefineContribution: _defineContribution,
      onEditContribution: _editContribution,
      onApproveContribution: _approveContribution,
      onUploadDelivery: _uploadDelivery,
      onOpenDelivery: _openDelivery,
    );
  }

  // ============================================================
  // FLOW ITEMS
  // ============================================================

  List<
    ProductionFlowItem
  >
  _buildFlowItems() {
    final currentUserId = _controller.currentUserId?.trim();

    return _controller.members.map(
      (
        member,
      ) {
        // ======================================================
        // CONTRIBUTION
        // ======================================================

        final contribution = _controller.contributionForUser(
          member.userId,
        );

        // ======================================================
        // NO CONTRIBUTION
        // ======================================================

        if (contribution ==
            null) {
          return ProductionFlowItem(
            member: member,
            contribution: null,
            delivery: null,
            approvedCount: 0,
            requiredApprovalCount: _controller.memberCount,
            currentUserApproved: false,
            canApprove: false,
            canUpload: false,
            isApproving: false,
            isUploading: false,
          );
        }

        // ======================================================
        // APPROVAL
        // ======================================================

        final approvedCount = _controller.approvalCountForContribution(
          contribution,
        );

        final currentUserApproved =
            currentUserId !=
                null &&
            currentUserId.isNotEmpty &&
            _controller.currentUserApprovedContribution(
              contribution,
            );

        // ======================================================
        // DELIVERY
        // ======================================================

        final delivery = _controller.latestDeliveryForContribution(
          contribution.id,
        );

        // ======================================================
        // PERMISSIONS
        // ======================================================

        final isCurrentUser =
            currentUserId !=
                null &&
            currentUserId ==
                member.userId;

        final canApprove =
            contribution.isWaitingApproval &&
            !currentUserApproved;

        final canUpload =
            isCurrentUser &&
            contribution.isInProgress;

        return ProductionFlowItem(
          member: member,
          contribution: contribution,
          delivery: delivery,
          approvedCount: approvedCount,
          requiredApprovalCount: _controller.memberCount,
          currentUserApproved: currentUserApproved,
          canApprove: canApprove,
          canUpload: canUpload,
          isApproving: _approvingContributionIds.contains(
            contribution.id,
          ),
          isUploading: false,
        );
      },
    ).toList();
  }

  // ============================================================
  // MILESTONES
  // ============================================================

  Widget _buildMilestones() {
    final members = _controller.members;

    final contributions = _controller.contributions;

    final deliveries = _controller.deliveries;

    // ==========================================================
    // PLAN DEFINED
    // ==========================================================

    final allMembersDefined =
        members.isNotEmpty &&
        contributions.length >=
            members.length &&
        members.every(
          (
            member,
          ) =>
              _controller.contributionForUser(
                member.userId,
              ) !=
              null,
        );

    // ==========================================================
    // PLAN APPROVED
    // ==========================================================

    final allPlansApproved =
        allMembersDefined &&
        contributions.every(
          (
            contribution,
          ) {
            return _controller.approvalCountForContribution(
                  contribution,
                ) >=
                _controller.memberCount;
          },
        );

    // ==========================================================
    // MATERIALS
    // ==========================================================

    final hasInitialMaterial = deliveries.isNotEmpty;

    // ==========================================================
    // ALL DELIVERED
    // ==========================================================

    final allDelivered =
        contributions.isNotEmpty &&
        contributions.every(
          (
            contribution,
          ) {
            return _controller.latestDeliveryForContribution(
                  contribution.id,
                ) !=
                null;
          },
        );

    // ==========================================================
    // ALL VALIDATED
    // ==========================================================

    final allValidated = _controller.allContributionsValidated;

    final milestones =
        <
          ProjectMilestoneItem
        >[
          ProjectMilestoneItem(
            id: 'plan',
            title: 'Plano de contribuição aprovado',
            subtitle: 'Responsabilidades definidas e confirmadas pelo grupo.',
            completed: allPlansApproved,
          ),

          ProjectMilestoneItem(
            id: 'materials',
            title: 'Materiais iniciais liberados',
            subtitle: 'O projeto recebeu sua primeira entrega.',
            completed: hasInitialMaterial,
          ),

          ProjectMilestoneItem(
            id: 'deliveries',
            title: 'Contribuições entregues',
            subtitle: 'Todos os participantes enviaram suas partes.',
            completed: allDelivered,
          ),

          ProjectMilestoneItem(
            id: 'validation',
            title: 'Entregas validadas',
            subtitle: 'As contribuições foram confirmadas pela equipe.',
            completed: allValidated,
          ),

          ProjectMilestoneItem(
            id: 'finalization',
            title: 'Obra pronta para finalização',
            subtitle: 'Todas as etapas foram concluídas.',
            completed:
                allValidated &&
                contributions.isNotEmpty,
          ),
        ];

    return ProjectMilestonesWidget(
      milestones: milestones,
    );
  }

  // ============================================================
  // PROJECT RECORD
  // ============================================================

  Widget _buildProjectRecord() {
    final events = _controller.recordEvents;

    final integrityValid = events.every(
      (
        event,
      ) {
        // Enquanto um evento ainda não possuir hashes,
        // não declaramos falha de integridade.
        //
        // A verificação criptográfica completa será feita pelo
        // ContributionIntegrityService em uma próxima etapa.

        if (!event.hasEventHash) {
          return true;
        }

        return event.hasIntegrityRecord;
      },
    );

    return ProjectRecordWidget(
      events: events,
      isIntegrityValid: integrityValid,
      onOpenTechnicalRecord: _openTechnicalRecord,
    );
  }

  // ============================================================
  // SECTION HEADER
  // ============================================================

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(
          height: 3,
        ),

        Text(
          subtitle,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SUMMARY VALUE
  // ============================================================

  Widget _buildSummaryValue({
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(
          height: 2,
        ),

        Text(
          label,
          style: const TextStyle(
            color: Colors.white30,
            fontSize: 8,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(
        color: Color(
          0xFFE100FF,
        ),
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
          24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.redAccent,
              size: 32,
            ),

            const SizedBox(
              height: 12,
            ),

            Text(
              _controller.errorMessage ??
                  'Não foi possível carregar o projeto.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 11,
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            OutlinedButton.icon(
              onPressed: _controller.refresh,
              icon: const Icon(
                Icons.refresh,
                size: 16,
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

  // ============================================================
  // DEFINE CONTRIBUTION
  // ============================================================

  Future<
    void
  >
  _defineContribution(
    ProjectTaskMemberModel member,
  ) async {
    if (_isCreatingContribution) {
      return;
    }

    final currentUserId = _controller.currentUserId?.trim();

    if (currentUserId ==
            null ||
        currentUserId !=
            member.userId) {
      _showMessage(
        'Você só pode definir a sua própria contribuição.',
        error: true,
      );

      return;
    }

    final result = await _showContributionEditor(
      member: member,
      contribution: null,
    );

    if (result ==
            null ||
        !mounted) {
      return;
    }

    setState(
      () {
        _isCreatingContribution = true;
      },
    );

    try {
      // ========================================================
      // CREATE DRAFT
      // ========================================================

      final created = await _controller.createContribution(
        title: result.title,
        description: result.description,
        dueAt: result.dueAt,
      );

      // ========================================================
      // SEND TO APPROVAL
      // ========================================================
      //
      // Fazemos automaticamente para evitar uma etapa
      // burocrática de:
      //
      // criar
      // ↓
      // salvar
      // ↓
      // clicar novamente em "enviar"
      //
      // ========================================================

      await _controller.submitContributionForApproval(
        created,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Contribuição enviada para confirmação do grupo.',
      );
    } catch (
      error
    ) {
      _showMessage(
        _actionError(
          error,
        ),
        error: true,
      );
    } finally {
      if (mounted) {
        setState(
          () {
            _isCreatingContribution = false;
          },
        );
      }
    }
  }

  // ============================================================
  // EDIT CONTRIBUTION
  // ============================================================

  Future<
    void
  >
  _editContribution(
    ProjectContributionModel contribution,
  ) async {
    final member = _controller.findMember(
      contribution.userId,
    );

    if (member ==
        null) {
      _showMessage(
        'Participante não encontrado.',
        error: true,
      );

      return;
    }

    final result = await _showContributionEditor(
      member: member,
      contribution: contribution,
    );

    if (result ==
            null ||
        !mounted) {
      return;
    }

    try {
      // ========================================================
      // NEW LOGICAL VERSION
      // ========================================================
      //
      // Se a proposta já estava em aprovação, qualquer alteração
      // cria uma nova versão.
      //
      // As aprovações antigas continuam vinculadas à versão
      // anterior e não valem para esta versão nova.
      //
      // ========================================================

      final updated = contribution.copyWith(
        title: result.title,
        description: result.description,
        dueAt: result.dueAt,
        clearDueAt:
            result.dueAt ==
            null,
        version:
            contribution.version +
            1,
        status: ProjectContributionStatus.waitingApproval,
        updatedAt: DateTime.now().toUtc(),
        clearLockedAt: true,
      );

      await _controller.updateContribution(
        updated,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Nova versão enviada para confirmação.',
      );
    } catch (
      error
    ) {
      _showMessage(
        _actionError(
          error,
        ),
        error: true,
      );
    }
  }

  // ============================================================
  // APPROVE CONTRIBUTION
  // ============================================================

  Future<
    void
  >
  _approveContribution(
    ProjectContributionModel contribution,
  ) async {
    if (_approvingContributionIds.contains(
      contribution.id,
    )) {
      return;
    }

    setState(
      () {
        _approvingContributionIds.add(
          contribution.id,
        );
      },
    );

    try {
      await _controller.approveContribution(
        contribution,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Contribuição confirmada.',
      );
    } catch (
      error
    ) {
      _showMessage(
        _actionError(
          error,
        ),
        error: true,
      );
    } finally {
      if (mounted) {
        setState(
          () {
            _approvingContributionIds.remove(
              contribution.id,
            );
          },
        );
      }
    }
  }

  // ============================================================
  // UPLOAD DELIVERY
  // ============================================================
  //
  // O fluxo de Storage já possui:
  //
  // ContributionUploadService
  //
  // Porém a seleção física do arquivo ainda precisa ser ligada
  // ao seletor de arquivos que o projeto utilizará.
  //
  // Não acessamos Storage diretamente nesta View.
  //
  // ============================================================

  void _uploadDelivery(
    ProjectContributionModel contribution,
  ) {
    _showMessage(
      'A contribuição já está pronta para receber arquivos. '
      'O próximo passo é conectar o seletor de arquivos ao '
      'ContributionUploadService.',
    );
  }

  // ============================================================
  // OPEN DELIVERY
  // ============================================================

  Future<
    void
  >
  _openDelivery(
    ContributionDeliveryModel delivery,
  ) async {
    if (!mounted) {
      return;
    }

    await showModalBottomSheet<
      void
    >(
      context: context,
      backgroundColor: const Color(
        0xFF15151B,
      ),
      showDragHandle: true,
      isScrollControlled: true,
      builder:
          (
            context,
          ) {
            final isProcessing = _validatingDeliveryIds.contains(
              delivery.id,
            );

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  4,
                  20,
                  28,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Entrega',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    _buildDeliveryDetail(
                      icon: Icons.insert_drive_file_outlined,
                      label: 'Arquivo',
                      value: delivery.fileName,
                    ),

                    _buildDeliveryDetail(
                      icon: Icons.history,
                      label: 'Versão',
                      value: '${delivery.version}',
                    ),

                    if (delivery.formattedFileSize.isNotEmpty)
                      _buildDeliveryDetail(
                        icon: Icons.data_usage_outlined,
                        label: 'Tamanho',
                        value: delivery.formattedFileSize,
                      ),

                    if (delivery.hasHash)
                      _buildDeliveryDetail(
                        icon: Icons.fingerprint,
                        label: 'SHA-256',
                        value:
                            delivery.sha256 ??
                            '',
                        monospace: true,
                      ),

                    _buildDeliveryDetail(
                      icon: Icons.info_outline,
                      label: 'Status',
                      value: delivery.statusDatabaseValue,
                    ),

                    if (!delivery.isValidated) ...[
                      const SizedBox(
                        height: 18,
                      ),

                      if (isProcessing)
                        const Center(
                          child: CircularProgressIndicator(
                            color: Color(
                              0xFFE100FF,
                            ),
                          ),
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.of(
                                    context,
                                  ).pop();

                                  _rejectDelivery(
                                    delivery,
                                  );
                                },
                                icon: const Icon(
                                  Icons.close,
                                  size: 16,
                                ),
                                label: const Text(
                                  'SOLICITAR REVISÃO',
                                  style: TextStyle(
                                    fontSize: 8,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(
                              width: 8,
                            ),

                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () {
                                  Navigator.of(
                                    context,
                                  ).pop();

                                  _validateDelivery(
                                    delivery,
                                  );
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.greenAccent,
                                  foregroundColor: Colors.black,
                                ),
                                icon: const Icon(
                                  Icons.verified_outlined,
                                  size: 16,
                                ),
                                label: const Text(
                                  'VALIDAR',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ],
                ),
              ),
            );
          },
    );
  }

  // ============================================================
  // VALIDATE DELIVERY
  // ============================================================

  Future<
    void
  >
  _validateDelivery(
    ContributionDeliveryModel delivery,
  ) async {
    if (_validatingDeliveryIds.contains(
      delivery.id,
    )) {
      return;
    }

    setState(
      () {
        _validatingDeliveryIds.add(
          delivery.id,
        );
      },
    );

    try {
      await _controller.validateDelivery(
        delivery,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Entrega validada.',
      );
    } catch (
      error
    ) {
      _showMessage(
        _actionError(
          error,
        ),
        error: true,
      );
    } finally {
      if (mounted) {
        setState(
          () {
            _validatingDeliveryIds.remove(
              delivery.id,
            );
          },
        );
      }
    }
  }

  // ============================================================
  // REJECT DELIVERY
  // ============================================================

  Future<
    void
  >
  _rejectDelivery(
    ContributionDeliveryModel delivery,
  ) async {
    if (_validatingDeliveryIds.contains(
      delivery.id,
    )) {
      return;
    }

    setState(
      () {
        _validatingDeliveryIds.add(
          delivery.id,
        );
      },
    );

    try {
      await _controller.rejectDelivery(
        delivery,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Entrega marcada para revisão.',
      );
    } catch (
      error
    ) {
      _showMessage(
        _actionError(
          error,
        ),
        error: true,
      );
    } finally {
      if (mounted) {
        setState(
          () {
            _validatingDeliveryIds.remove(
              delivery.id,
            );
          },
        );
      }
    }
  }

  // ============================================================
  // OPEN CONTRIBUTION
  // ============================================================

  Future<
    void
  >
  _openContribution(
    ProjectContributionModel contribution,
  ) async {
    final member = _controller.findMember(
      contribution.userId,
    );

    if (member ==
        null) {
      return;
    }

    final currentUserId = _controller.currentUserId?.trim();

    final isOwner =
        currentUserId !=
            null &&
        currentUserId ==
            contribution.userId;

    await showModalBottomSheet<
      void
    >(
      context: context,
      backgroundColor: const Color(
        0xFF15151B,
      ),
      showDragHandle: true,
      builder:
          (
            context,
          ) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  4,
                  20,
                  28,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contribution.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    Text(
                      '${member.resolvedDisplayName} • '
                      '${member.resolvedProfessionalRole}',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                      ),
                    ),

                    if (contribution.description.trim().isNotEmpty) ...[
                      const SizedBox(
                        height: 16,
                      ),
                      Text(
                        contribution.description,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 11,
                          height: 1.5,
                        ),
                      ),
                    ],

                    const SizedBox(
                      height: 16,
                    ),

                    _buildDeliveryDetail(
                      icon: Icons.history,
                      label: 'Versão',
                      value: '${contribution.version}',
                    ),

                    _buildDeliveryDetail(
                      icon: Icons.info_outline,
                      label: 'Status',
                      value: contribution.statusDatabaseValue,
                    ),

                    if (contribution.dueAt !=
                        null)
                      _buildDeliveryDetail(
                        icon: Icons.event_outlined,
                        label: 'Prazo',
                        value: _formatDate(
                          contribution.dueAt!,
                        ),
                      ),

                    if (isOwner &&
                        contribution.isReady) ...[
                      const SizedBox(
                        height: 18,
                      ),

                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.of(
                              context,
                            ).pop();

                            _startContribution(
                              contribution,
                            );
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(
                              0xFFE100FF,
                            ),
                            foregroundColor: Colors.black,
                          ),
                          icon: const Icon(
                            Icons.play_arrow_rounded,
                          ),
                          label: const Text(
                            'INICIAR CONTRIBUIÇÃO',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
    );
  }

  // ============================================================
  // START CONTRIBUTION
  // ============================================================

  Future<
    void
  >
  _startContribution(
    ProjectContributionModel contribution,
  ) async {
    try {
      await _controller.startContribution(
        contribution,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Contribuição iniciada.',
      );
    } catch (
      error
    ) {
      _showMessage(
        _actionError(
          error,
        ),
        error: true,
      );
    }
  }

  // ============================================================
  // CONTRIBUTION EDITOR
  // ============================================================

  Future<
    _ContributionEditorResult?
  >
  _showContributionEditor({
    required ProjectTaskMemberModel member,
    required ProjectContributionModel? contribution,
  }) async {
    final titleController = TextEditingController(
      text:
          contribution?.title ??
          '',
    );

    final descriptionController = TextEditingController(
      text:
          contribution?.description ??
          '',
    );

    DateTime? selectedDueAt = contribution?.dueAt;

    final result =
        await showDialog<
          _ContributionEditorResult
        >(
          context: context,
          barrierDismissible: false,
          builder:
              (
                dialogContext,
              ) {
                return StatefulBuilder(
                  builder:
                      (
                        context,
                        setDialogState,
                      ) {
                        return AlertDialog(
                          backgroundColor: const Color(
                            0xFF17171D,
                          ),
                          title: Text(
                            contribution ==
                                    null
                                ? 'Definir contribuição'
                                : 'Editar contribuição',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          content: SingleChildScrollView(
                            child: SizedBox(
                              width: 440,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    member.resolvedDisplayName,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 3,
                                  ),

                                  Text(
                                    member.resolvedProfessionalRole,
                                    style: const TextStyle(
                                      color: Color(
                                        0xFFE100FF,
                                      ),
                                      fontSize: 9,
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 18,
                                  ),

                                  TextField(
                                    controller: titleController,
                                    maxLength: 80,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                    decoration: const InputDecoration(
                                      labelText: 'O que você vai realizar?',
                                      hintText: 'Ex: Mixagem e masterização',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 10,
                                  ),

                                  TextField(
                                    controller: descriptionController,
                                    minLines: 3,
                                    maxLines: 6,
                                    maxLength: 500,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                    decoration: const InputDecoration(
                                      labelText: 'Descreva sua contribuição',
                                      hintText: 'Explique claramente o que você pretende entregar ao projeto.',
                                      alignLabelWithHint: true,
                                      border: OutlineInputBorder(),
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 8,
                                  ),

                                  InkWell(
                                    borderRadius: BorderRadius.circular(
                                      10,
                                    ),
                                    onTap: () async {
                                      final now = DateTime.now();

                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate:
                                            selectedDueAt?.toLocal() ??
                                            now,
                                        firstDate: DateTime(
                                          now.year,
                                          now.month,
                                          now.day,
                                        ),
                                        lastDate: DateTime(
                                          now.year +
                                              5,
                                        ),
                                      );

                                      if (picked ==
                                          null) {
                                        return;
                                      }

                                      setDialogState(
                                        () {
                                          selectedDueAt = DateTime(
                                            picked.year,
                                            picked.month,
                                            picked.day,
                                            23,
                                            59,
                                          ).toUtc();
                                        },
                                      );
                                    },
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(
                                        12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.03,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          10,
                                        ),
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.07,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.event_outlined,
                                            color: Colors.white38,
                                            size: 17,
                                          ),

                                          const SizedBox(
                                            width: 8,
                                          ),

                                          Expanded(
                                            child: Text(
                                              selectedDueAt ==
                                                      null
                                                  ? 'Definir prazo opcional'
                                                  : 'Prazo: ${_formatDate(selectedDueAt!)}',
                                              style: const TextStyle(
                                                color: Colors.white54,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),

                                          if (selectedDueAt !=
                                              null)
                                            IconButton(
                                              onPressed: () {
                                                setDialogState(
                                                  () {
                                                    selectedDueAt = null;
                                                  },
                                                );
                                              },
                                              icon: const Icon(
                                                Icons.close,
                                                color: Colors.white38,
                                                size: 16,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(
                                  dialogContext,
                                ).pop();
                              },
                              child: const Text(
                                'CANCELAR',
                              ),
                            ),

                            FilledButton(
                              onPressed: () {
                                final title = titleController.text.trim();

                                final description = descriptionController.text.trim();

                                if (title.isEmpty) {
                                  ScaffoldMessenger.of(
                                      dialogContext,
                                    )
                                    ..hideCurrentSnackBar()
                                    ..showSnackBar(
                                      const SnackBar(
                                        behavior: SnackBarBehavior.floating,
                                        content: Text(
                                          'Informe o que você vai realizar.',
                                        ),
                                      ),
                                    );

                                  return;
                                }

                                if (description.isEmpty) {
                                  ScaffoldMessenger.of(
                                      dialogContext,
                                    )
                                    ..hideCurrentSnackBar()
                                    ..showSnackBar(
                                      const SnackBar(
                                        behavior: SnackBarBehavior.floating,
                                        content: Text(
                                          'Descreva sua contribuição.',
                                        ),
                                      ),
                                    );

                                  return;
                                }

                                Navigator.of(
                                  dialogContext,
                                ).pop(
                                  _ContributionEditorResult(
                                    title: title,
                                    description: description,
                                    dueAt: selectedDueAt,
                                  ),
                                );
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(
                                  0xFFE100FF,
                                ),
                                foregroundColor: Colors.black,
                              ),
                              child: Text(
                                contribution ==
                                        null
                                    ? 'ENVIAR PARA O GRUPO'
                                    : 'SALVAR NOVA VERSÃO',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                );
              },
        );

    titleController.dispose();

    descriptionController.dispose();

    return result;
  }

  // ============================================================
  // TECHNICAL RECORD
  // ============================================================

  void _openTechnicalRecord() {
    final events = _controller.recordEvents;

    final latest = events.isEmpty
        ? null
        : events.first;

    showModalBottomSheet<
      void
    >(
      context: context,
      backgroundColor: const Color(
        0xFF15151B,
      ),
      showDragHandle: true,
      builder:
          (
            context,
          ) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  4,
                  20,
                  28,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Registro técnico',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    const Text(
                      'Informações técnicas da trilha de colaboração.',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 9,
                      ),
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    _buildTechnicalValue(
                      label: 'PROJECT',
                      value: widget.projectId,
                    ),

                    _buildTechnicalValue(
                      label: 'MEMBERS',
                      value: '${_controller.memberCount}',
                    ),

                    _buildTechnicalValue(
                      label: 'CONTRIBUTIONS',
                      value: '${_controller.contributionCount}',
                    ),

                    _buildTechnicalValue(
                      label: 'APPROVALS',
                      value: '${_controller.approvalCount}',
                    ),

                    _buildTechnicalValue(
                      label: 'DELIVERIES',
                      value: '${_controller.deliveryCount}',
                    ),

                    _buildTechnicalValue(
                      label: 'EVENTS',
                      value: '${_controller.recordEventCount}',
                    ),

                    _buildTechnicalValue(
                      label: 'LAST EVENT',
                      value:
                          latest?.eventDatabaseValue ??
                          'NONE',
                    ),

                    _buildTechnicalValue(
                      label: 'LAST EVENT HASH',
                      value:
                          latest?.eventHash ??
                          'NOT GENERATED',
                    ),

                    _buildTechnicalValue(
                      label: 'PREVIOUS EVENT HASH',
                      value:
                          latest?.previousEventHash ??
                          'NONE',
                    ),

                    _buildTechnicalValue(
                      label: 'STATUS',
                      value: events.isEmpty
                          ? 'AGUARDANDO EVENTOS'
                          : 'RECORD ACTIVE',
                      success: events.isNotEmpty,
                    ),
                  ],
                ),
              ),
            );
          },
    );
  }

  // ============================================================
  // TECHNICAL VALUE
  // ============================================================

  Widget _buildTechnicalValue({
    required String label,
    required String value,
    bool success = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white24,
              fontSize: 7,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),

          const SizedBox(
            height: 4,
          ),

          SelectableText(
            value,
            style: TextStyle(
              color: success
                  ? Colors.greenAccent
                  : Colors.white60,
              fontSize: 9,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DELIVERY DETAIL
  // ============================================================

  Widget _buildDeliveryDetail({
    required IconData icon,
    required String label,
    required String value,
    bool monospace = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 11,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Colors.white38,
            size: 16,
          ),

          const SizedBox(
            width: 8,
          ),

          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white30,
                fontSize: 9,
              ),
            ),
          ),

          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 9,
                fontFamily: monospace
                    ? 'monospace'
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String _formatDate(
    DateTime value,
  ) {
    final local = value.toLocal();

    final day = local.day.toString().padLeft(
      2,
      '0',
    );

    final month = local.month.toString().padLeft(
      2,
      '0',
    );

    return '$day/$month/${local.year}';
  }

  // ============================================================
  // ACTION ERROR
  // ============================================================

  String _actionError(
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

    return error.toString();
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

    ScaffoldMessenger.of(
        context,
      )
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: error
              ? Colors.red.shade900
              : null,
          content: Text(
            message,
          ),
        ),
      );
  }
}

// ============================================================
// CONTRIBUTION EDITOR RESULT
// ============================================================
//
// Objeto local da View.
//
// Não representa entidade do banco.
//
// ============================================================

class _ContributionEditorResult {
  final String title;

  final String description;

  final DateTime? dueAt;

  const _ContributionEditorResult({
    required this.title,
    required this.description,
    this.dueAt,
  });
}
