import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:versin/modules/dashboard/production/services/creative_activity_service.dart';

import '../models/contribution_approval_model.dart';
import '../models/contribution_delivery_model.dart';
import '../models/project_contribution_model.dart';
import '../models/project_record_event_model.dart';
import '../models/project_task_member_model.dart';
import '../repositories/project_tasks_repository.dart';

// ============================================================
// PROJECT TASKS WORKFLOW STAGE
// ============================================================
//
// Representa o estágio coletivo atual do fluxo de produção.
//
// IMPORTANTE:
//
// Este enum é derivado dos dados já carregados pelo controller.
// Ele não substitui os status individuais de cada contribuição.
//
// ============================================================

enum ProjectTasksWorkflowStage {
  definingPlan,
  awaitingApproval,
  awaitingFirstDelivery,
  deliveriesInProgress,
  awaitingDeliveryValidation,
  completed,
}

// ============================================================
// PROJECT TASKS CONTROLLER
// ============================================================
//
// Controller principal do módulo de produção / tarefas.
//
// Responsabilidades:
//
// - carregar projeto;
// - carregar membros;
// - carregar contribuições;
// - carregar aprovações;
// - carregar entregas;
// - carregar Versin Record;
// - manter estado;
// - controlar loading;
// - controlar erros;
// - iniciar Realtime;
// - relacionar membro -> contribuição;
// - relacionar contribuição -> aprovações;
// - relacionar contribuição -> última entrega;
// - calcular progresso;
// - descobrir próxima ação.
//
// NÃO:
//
// - acessa Supabase diretamente;
// - faz queries;
// - faz upload físico;
// - calcula hash;
// - desenha UI.
//
// ============================================================

class ProjectTasksController
    extends
        ChangeNotifier {
  // ============================================================
  // REPOSITORY
  // ============================================================

  final ProjectTasksRepository repository;

  // ============================================================
  // CREATIVE ACTIVITY
  // ============================================================
  //
  // Analytics de produção criativa.
  //
  // Falhas nesta camada nunca devem desfazer operações principais
  // como validar uma entrega ou concluir uma contribuição.
  //
  // ============================================================

  final CreativeActivityService _creativeActivityService = CreativeActivityService();

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  ProjectTasksController({
    required this.repository,
  });

  // ============================================================
  // PROJECT
  // ============================================================

  String? _projectId;

  String? get projectId => _projectId;

  bool get hasProject {
    return _projectId?.trim().isNotEmpty ==
        true;
  }

  // ============================================================
  // CURRENT USER
  // ============================================================

  String? _currentUserId;

  String? get currentUserId => _currentUserId;

  // ============================================================
  // MEMBERS
  // ============================================================

  List<
    ProjectTaskMemberModel
  >
  _members =
      const <
        ProjectTaskMemberModel
      >[];

  List<
    ProjectTaskMemberModel
  >
  get members {
    return List.unmodifiable(
      _members,
    );
  }

  int get memberCount => _members.length;

  bool get hasMembers => _members.isNotEmpty;

  // ============================================================
  // CONTRIBUTIONS
  // ============================================================

  List<
    ProjectContributionModel
  >
  _contributions =
      const <
        ProjectContributionModel
      >[];

  List<
    ProjectContributionModel
  >
  get contributions {
    return List.unmodifiable(
      _contributions,
    );
  }

  int get contributionCount => _contributions.length;

  bool get hasContributions => _contributions.isNotEmpty;

  // ============================================================
  // APPROVALS
  // ============================================================

  List<
    ContributionApprovalModel
  >
  _approvals =
      const <
        ContributionApprovalModel
      >[];

  List<
    ContributionApprovalModel
  >
  get approvals {
    return List.unmodifiable(
      _approvals,
    );
  }

  int get approvalCount => _approvals.length;

  // ============================================================
  // DELIVERIES
  // ============================================================

  List<
    ContributionDeliveryModel
  >
  _deliveries =
      const <
        ContributionDeliveryModel
      >[];

  List<
    ContributionDeliveryModel
  >
  get deliveries {
    return List.unmodifiable(
      _deliveries,
    );
  }

  int get deliveryCount => _deliveries.length;

  bool get hasDeliveries => _deliveries.isNotEmpty;

  // ============================================================
  // RECORD EVENTS
  // ============================================================

  List<
    ProjectRecordEventModel
  >
  _recordEvents =
      const <
        ProjectRecordEventModel
      >[];

  List<
    ProjectRecordEventModel
  >
  get recordEvents {
    return List.unmodifiable(
      _recordEvents,
    );
  }

  int get recordEventCount => _recordEvents.length;

  bool get hasRecordEvents => _recordEvents.isNotEmpty;

  // ============================================================
  // CURRENT MEMBER
  // ============================================================

  ProjectTaskMemberModel? get currentMember {
    final userId = _currentUserId?.trim();

    if (userId ==
            null ||
        userId.isEmpty) {
      return null;
    }

    return findMember(
      userId,
    );
  }

  bool get currentUserIsMember {
    return currentMember !=
        null;
  }

  bool get currentUserIsFounder {
    return currentMember?.isFounder ??
        false;
  }

  // ============================================================
  // CURRENT CONTRIBUTION
  // ============================================================

  ProjectContributionModel? get currentUserContribution {
    final userId = _currentUserId?.trim();

    if (userId ==
            null ||
        userId.isEmpty) {
      return null;
    }

    return contributionForUser(
      userId,
    );
  }

  // ============================================================
  // PROGRESS
  // ============================================================

  int get validatedContributionCount {
    return _contributions
        .where(
          (
            contribution,
          ) => contribution.isValidated,
        )
        .length;
  }

  double get progress {
    if (_contributions.isEmpty) {
      return 0.0;
    }

    return validatedContributionCount /
        _contributions.length;
  }

  bool get allContributionsValidated {
    return _contributions.isNotEmpty &&
        _contributions.every(
          (
            contribution,
          ) => contribution.isValidated,
        );
  }

  // ============================================================
  // CONTRIBUTION PLAN APPROVAL
  // ============================================================

  int get requiredApprovalCountPerContribution {
    return memberCount;
  }

  bool isContributionPlanApproved(
    ProjectContributionModel contribution,
  ) {
    switch (contribution.status) {
      case ProjectContributionStatus.ready:
      case ProjectContributionStatus.inProgress:
      case ProjectContributionStatus.delivered:
      case ProjectContributionStatus.validated:
        return true;

      case ProjectContributionStatus.draft:
      case ProjectContributionStatus.waitingApproval:
      case ProjectContributionStatus.blocked:
        break;
    }

    final requiredApprovals = requiredApprovalCountPerContribution;

    if (requiredApprovals <=
        0) {
      return false;
    }

    return approvalCountForContribution(
          contribution,
        ) >=
        requiredApprovals;
  }

  int get approvedContributionPlanCount {
    return _contributions
        .where(
          isContributionPlanApproved,
        )
        .length;
  }

  bool get allContributionPlansApproved {
    return _contributions.isNotEmpty &&
        approvedContributionPlanCount ==
            _contributions.length;
  }

  // ============================================================
  // DELIVERIES PROGRESS
  // ============================================================

  int get contributionWithDeliveryCount {
    if (_contributions.isEmpty ||
        _deliveries.isEmpty) {
      return 0;
    }

    final deliveredContributionIds = _deliveries
        .map(
          (
            delivery,
          ) => delivery.contributionId.trim(),
        )
        .where(
          (
            contributionId,
          ) => contributionId.isNotEmpty,
        )
        .toSet();

    return _contributions
        .where(
          (
            contribution,
          ) => deliveredContributionIds.contains(
            contribution.id,
          ),
        )
        .length;
  }

  bool get allContributionsDelivered {
    return _contributions.isNotEmpty &&
        contributionWithDeliveryCount ==
            _contributions.length;
  }

  bool get materialsReleased {
    return allContributionPlansApproved;
  }

  // ============================================================
  // WORKFLOW STAGE
  // ============================================================

  ProjectTasksWorkflowStage get workflowStage {
    if (_contributions.isEmpty ||
        _members.isEmpty ||
        _contributions.length <
            _members.length) {
      return ProjectTasksWorkflowStage.definingPlan;
    }

    if (!allContributionPlansApproved) {
      return ProjectTasksWorkflowStage.awaitingApproval;
    }

    if (!hasDeliveries) {
      return ProjectTasksWorkflowStage.awaitingFirstDelivery;
    }

    if (!allContributionsDelivered) {
      return ProjectTasksWorkflowStage.deliveriesInProgress;
    }

    if (!allContributionsValidated) {
      return ProjectTasksWorkflowStage.awaitingDeliveryValidation;
    }

    return ProjectTasksWorkflowStage.completed;
  }

  bool get isAwaitingPlanApproval {
    return workflowStage ==
        ProjectTasksWorkflowStage.awaitingApproval;
  }

  bool get isAwaitingFirstDelivery {
    return workflowStage ==
        ProjectTasksWorkflowStage.awaitingFirstDelivery;
  }

  bool get isDeliveryPhaseActive {
    switch (workflowStage) {
      case ProjectTasksWorkflowStage.awaitingFirstDelivery:
      case ProjectTasksWorkflowStage.deliveriesInProgress:
        return true;

      case ProjectTasksWorkflowStage.definingPlan:
      case ProjectTasksWorkflowStage.awaitingApproval:
      case ProjectTasksWorkflowStage.awaitingDeliveryValidation:
      case ProjectTasksWorkflowStage.completed:
        return false;
    }
  }

  bool get isAwaitingDeliveryValidation {
    return workflowStage ==
        ProjectTasksWorkflowStage.awaitingDeliveryValidation;
  }

  bool get isWorkflowCompleted {
    return workflowStage ==
        ProjectTasksWorkflowStage.completed;
  }

  // ============================================================
  // NEXT ACTION TEXT
  // ============================================================

  String get nextActionTitle {
    switch (workflowStage) {
      case ProjectTasksWorkflowStage.definingPlan:
        return 'Defina as contribuições do projeto.';

      case ProjectTasksWorkflowStage.awaitingApproval:
        return 'Aguardando aprovação do grupo.';

      case ProjectTasksWorkflowStage.awaitingFirstDelivery:
        return 'Aguardando primeira entrega.';

      case ProjectTasksWorkflowStage.deliveriesInProgress:
        return 'Contribuições em andamento.';

      case ProjectTasksWorkflowStage.awaitingDeliveryValidation:
        return 'Entregas aguardam validação.';

      case ProjectTasksWorkflowStage.completed:
        return 'Projeto pronto para finalização.';
    }
  }

  String get nextActionDescription {
    switch (workflowStage) {
      case ProjectTasksWorkflowStage.definingPlan:
        return 'Todos os participantes precisam definir suas responsabilidades.';

      case ProjectTasksWorkflowStage.awaitingApproval:
        return 'As contribuições precisam ser confirmadas por todos os participantes.';

      case ProjectTasksWorkflowStage.awaitingFirstDelivery:
        return 'O plano foi aprovado. Os responsáveis já podem enviar seus arquivos.';

      case ProjectTasksWorkflowStage.deliveriesInProgress:
        return 'Aguardando as contribuições que ainda não foram entregues.';

      case ProjectTasksWorkflowStage.awaitingDeliveryValidation:
        return 'Todos enviaram suas partes. Agora as entregas precisam ser confirmadas.';

      case ProjectTasksWorkflowStage.completed:
        return 'Todas as contribuições foram entregues e validadas.';
    }
  }

  // ============================================================
  // DEADLINE / UPLOAD
  // ============================================================

  bool contributionDeadlinePassed(
    ProjectContributionModel contribution, {
    DateTime? referenceDate,
  }) {
    final dueAt = contribution.dueAt;

    if (dueAt ==
        null) {
      return false;
    }

    final now =
        referenceDate ??
        DateTime.now();

    return now.isAfter(
      dueAt,
    );
  }

  bool canUploadContribution(
    ProjectContributionModel contribution, {
    DateTime? referenceDate,
  }) {
    if (!isContributionPlanApproved(
      contribution,
    )) {
      return false;
    }

    if (contribution.isValidated) {
      return false;
    }

    if (contributionDeadlinePassed(
      contribution,
      referenceDate: referenceDate,
    )) {
      return false;
    }

    return true;
  }

  bool canCurrentUserUploadContribution(
    ProjectContributionModel contribution, {
    DateTime? referenceDate,
  }) {
    final currentUserId = _currentUserId?.trim();

    if (currentUserId ==
            null ||
        currentUserId.isEmpty ||
        contribution.userId !=
            currentUserId) {
      return false;
    }

    return canUploadContribution(
      contribution,
      referenceDate: referenceDate,
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  // ============================================================
  // INITIALIZED
  // ============================================================

  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  // ============================================================
  // ERROR
  // ============================================================

  String? _errorMessage;

  String? get errorMessage => _errorMessage;

  bool get hasError {
    return _errorMessage?.trim().isNotEmpty ==
        true;
  }

  // ============================================================
  // REALTIME SUBSCRIPTIONS
  // ============================================================

  StreamSubscription<
    List<
      ProjectTaskMemberModel
    >
  >?
  _membersSubscription;

  StreamSubscription<
    List<
      ProjectContributionModel
    >
  >?
  _contributionsSubscription;

  StreamSubscription<
    List<
      ContributionApprovalModel
    >
  >?
  _approvalsSubscription;

  StreamSubscription<
    List<
      ContributionDeliveryModel
    >
  >?
  _deliveriesSubscription;

  StreamSubscription<
    List<
      ProjectRecordEventModel
    >
  >?
  _recordEventsSubscription;

  // ============================================================
  // LOAD
  // ============================================================

  Future<
    void
  >
  load({
    required String projectId,
    required String currentUserId,
  }) async {
    final normalizedProjectId = projectId.trim();

    final normalizedUserId = currentUserId.trim();

    // ==========================================================
    // VALIDATION
    // ==========================================================

    if (normalizedProjectId.isEmpty) {
      _setError(
        'ID do projeto inválido.',
      );

      return;
    }

    if (normalizedUserId.isEmpty) {
      _setError(
        'Usuário não identificado.',
      );

      return;
    }

    // ==========================================================
    // STATE
    // ==========================================================

    _projectId = normalizedProjectId;

    _currentUserId = normalizedUserId;

    _isLoading = true;

    _isInitialized = false;

    _errorMessage = null;

    // ==========================================================
    // ESTADO INICIAL ZERADO
    // ==========================================================

    _clearCollections();

    notifyListeners();

    try {
      // ========================================================
      // PROJECT EXISTS
      // ========================================================

      final exists = await repository.projectExists(
        projectId: normalizedProjectId,
      );

      if (!exists) {
        throw StateError(
          'Projeto não encontrado.',
        );
      }

      // ========================================================
      // CURRENT USER MEMBER
      // ========================================================

      final isMember = await repository.isProjectMember(
        projectId: normalizedProjectId,
        userId: normalizedUserId,
      );

      if (!isMember) {
        throw StateError(
          'Você não faz parte deste projeto.',
        );
      }

      // ========================================================
      // LOAD ALL
      // ========================================================

      await _loadAllData(
        normalizedProjectId,
      );

      // ========================================================
      // REALTIME
      // ========================================================

      await _startRealtime();

      // ========================================================
      // INITIALIZED
      // ========================================================

      _isInitialized = true;

      debugPrint(
        '[PROJECT TASKS] '
        'Projeto carregado: '
        '$normalizedProjectId',
      );

      debugPrint(
        '[PROJECT TASKS] '
        'Membros: '
        '${_members.length}',
      );

      debugPrint(
        '[PROJECT TASKS] '
        'Contribuições: '
        '${_contributions.length}',
      );

      debugPrint(
        '[PROJECT TASKS] '
        'Aprovações: '
        '${_approvals.length}',
      );

      debugPrint(
        '[PROJECT TASKS] '
        'Entregas: '
        '${_deliveries.length}',
      );

      debugPrint(
        '[PROJECT TASKS] '
        'Eventos: '
        '${_recordEvents.length}',
      );

      debugPrint(
        '[PROJECT TASKS] '
        'Estágio do fluxo: '
        '${workflowStage.name}',
      );

      debugPrint(
        '[PROJECT TASKS] '
        'Planos aprovados: '
        '$approvedContributionPlanCount/'
        '${_contributions.length}',
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[PROJECT TASKS] '
        'Erro ao carregar projeto: '
        '$error',
      );

      debugPrint(
        '[PROJECT TASKS] '
        '$stackTrace',
      );

      _clearCollections();

      _errorMessage = _resolveErrorMessage(
        error,
      );
    } finally {
      _isLoading = false;

      notifyListeners();
    }
  }

  // ============================================================
  // LOAD ALL DATA
  // ============================================================

  Future<
    void
  >
  _loadAllData(
    String projectId,
  ) async {
    final loadedMembers = await repository.getProjectMembers(
      projectId: projectId,
    );

    final loadedContributions = await repository.getContributions(
      projectId: projectId,
    );

    final loadedApprovals = await repository.getContributionApprovals(
      projectId: projectId,
    );

    final loadedDeliveries = await repository.getDeliveries(
      projectId: projectId,
    );

    final loadedRecordEvents = await repository.getProjectRecordEvents(
      projectId: projectId,
    );

    _members = _normalizeMembers(
      loadedMembers,
    );

    _contributions = _normalizeContributions(
      loadedContributions,
    );

    _approvals = _normalizeApprovals(
      loadedApprovals,
    );

    _deliveries = _normalizeDeliveries(
      loadedDeliveries,
    );

    _recordEvents = _normalizeRecordEvents(
      loadedRecordEvents,
    );
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<
    void
  >
  refresh() async {
    final projectId = _projectId?.trim();

    if (projectId ==
            null ||
        projectId.isEmpty) {
      return;
    }

    try {
      _errorMessage = null;

      await _loadAllData(
        projectId,
      );

      notifyListeners();
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[PROJECT TASKS] '
        'Erro ao atualizar projeto: '
        '$error',
      );

      debugPrint(
        '[PROJECT TASKS] '
        '$stackTrace',
      );

      _errorMessage = _resolveErrorMessage(
        error,
      );

      notifyListeners();
    }
  }

  // ============================================================
  // START REALTIME
  // ============================================================

  Future<
    void
  >
  _startRealtime() async {
    await _cancelRealtime();

    final projectId = _projectId?.trim();

    if (projectId ==
            null ||
        projectId.isEmpty) {
      return;
    }

    _membersSubscription = repository
        .watchProjectMembers(
          projectId: projectId,
        )
        .listen(
          (
            members,
          ) {
            _members = _normalizeMembers(
              members,
            );

            debugPrint(
              '[PROJECT TASKS] '
              'Membros atualizados em realtime: '
              '${_members.length}',
            );

            notifyListeners();
          },
          onError: _handleRealtimeError,
        );

    _contributionsSubscription = repository
        .watchContributions(
          projectId: projectId,
        )
        .listen(
          (
            contributions,
          ) {
            _contributions = _normalizeContributions(
              contributions,
            );

            debugPrint(
              '[PROJECT TASKS] '
              'Contribuições atualizadas em realtime: '
              '${_contributions.length}',
            );

            notifyListeners();
          },
          onError: _handleRealtimeError,
        );

    _approvalsSubscription = repository
        .watchContributionApprovals(
          projectId: projectId,
        )
        .listen(
          (
            approvals,
          ) {
            _approvals = _normalizeApprovals(
              approvals,
            );

            debugPrint(
              '[PROJECT TASKS] '
              'Aprovações atualizadas em realtime: '
              '${_approvals.length}',
            );

            debugPrint(
              '[PROJECT TASKS] '
              'Estágio após aprovação: '
              '${workflowStage.name}',
            );

            notifyListeners();
          },
          onError: _handleRealtimeError,
        );

    _deliveriesSubscription = repository
        .watchDeliveries(
          projectId: projectId,
        )
        .listen(
          (
            deliveries,
          ) {
            _deliveries = _normalizeDeliveries(
              deliveries,
            );

            debugPrint(
              '[PROJECT TASKS] '
              'Entregas atualizadas em realtime: '
              '${_deliveries.length}',
            );

            notifyListeners();
          },
          onError: _handleRealtimeError,
        );

    _recordEventsSubscription = repository
        .watchProjectRecordEvents(
          projectId: projectId,
        )
        .listen(
          (
            events,
          ) {
            _recordEvents = _normalizeRecordEvents(
              events,
            );

            debugPrint(
              '[PROJECT TASKS] '
              'Versin Record atualizado em realtime: '
              '${_recordEvents.length}',
            );

            notifyListeners();
          },
          onError: _handleRealtimeError,
        );
  }

  // ============================================================
  // REALTIME ERROR
  // ============================================================

  void _handleRealtimeError(
    Object error,
    StackTrace stackTrace,
  ) {
    debugPrint(
      '[PROJECT TASKS] '
      'Erro realtime: '
      '$error',
    );

    debugPrint(
      '[PROJECT TASKS] '
      '$stackTrace',
    );
  }

  // ============================================================
  // CONTRIBUTION FOR USER
  // ============================================================

  ProjectContributionModel? contributionForUser(
    String userId,
  ) {
    final normalizedUserId = userId.trim();

    if (normalizedUserId.isEmpty) {
      return null;
    }

    for (final contribution in _contributions) {
      if (contribution.userId ==
          normalizedUserId) {
        return contribution;
      }
    }

    return null;
  }

  // ============================================================
  // FIND CONTRIBUTION
  // ============================================================

  ProjectContributionModel? findContribution(
    String contributionId,
  ) {
    final normalizedContributionId = contributionId.trim();

    if (normalizedContributionId.isEmpty) {
      return null;
    }

    for (final contribution in _contributions) {
      if (contribution.id ==
          normalizedContributionId) {
        return contribution;
      }
    }

    return null;
  }

  // ============================================================
  // APPROVALS FOR CONTRIBUTION
  // ============================================================

  List<
    ContributionApprovalModel
  >
  approvalsForContribution(
    ProjectContributionModel contribution,
  ) {
    return _approvals
        .where(
          (
            approval,
          ) =>
              approval.contributionId ==
                  contribution.id &&
              approval.contributionVersion ==
                  contribution.version,
        )
        .toList();
  }

  // ============================================================
  // APPROVAL COUNT
  // ============================================================

  int approvalCountForContribution(
    ProjectContributionModel contribution,
  ) {
    return approvalsForContribution(
      contribution,
    ).length;
  }

  int remainingApprovalCountForContribution(
    ProjectContributionModel contribution,
  ) {
    final remaining =
        requiredApprovalCountPerContribution -
        approvalCountForContribution(
          contribution,
        );

    return remaining <
            0
        ? 0
        : remaining;
  }

  double approvalProgressForContribution(
    ProjectContributionModel contribution,
  ) {
    final requiredApprovals = requiredApprovalCountPerContribution;

    if (requiredApprovals <=
        0) {
      return 0.0;
    }

    return (approvalCountForContribution(
              contribution,
            ) /
            requiredApprovals)
        .clamp(
          0.0,
          1.0,
        )
        .toDouble();
  }

  // ============================================================
  // USER APPROVED CONTRIBUTION
  // ============================================================

  bool userApprovedContribution({
    required ProjectContributionModel contribution,
    required String userId,
  }) {
    final normalizedUserId = userId.trim();

    if (normalizedUserId.isEmpty) {
      return false;
    }

    return _approvals.any(
      (
        approval,
      ) => approval.approves(
        contributionId: contribution.id,
        userId: normalizedUserId,
        version: contribution.version,
      ),
    );
  }

  // ============================================================
  // CURRENT USER APPROVED
  // ============================================================

  bool currentUserApprovedContribution(
    ProjectContributionModel contribution,
  ) {
    final userId = _currentUserId?.trim();

    if (userId ==
            null ||
        userId.isEmpty) {
      return false;
    }

    return userApprovedContribution(
      contribution: contribution,
      userId: userId,
    );
  }

  // ============================================================
  // DELIVERIES FOR CONTRIBUTION
  // ============================================================

  List<
    ContributionDeliveryModel
  >
  deliveriesForContribution(
    String contributionId,
  ) {
    final normalizedContributionId = contributionId.trim();

    if (normalizedContributionId.isEmpty) {
      return const <
        ContributionDeliveryModel
      >[];
    }

    final result = _deliveries
        .where(
          (
            delivery,
          ) =>
              delivery.contributionId ==
              normalizedContributionId,
        )
        .toList();

    result.sort(
      (
        a,
        b,
      ) => b.version.compareTo(
        a.version,
      ),
    );

    return result;
  }

  // ============================================================
  // LATEST DELIVERY
  // ============================================================

  ContributionDeliveryModel? latestDeliveryForContribution(
    String contributionId,
  ) {
    final deliveries = deliveriesForContribution(
      contributionId,
    );

    if (deliveries.isEmpty) {
      return null;
    }

    return deliveries.first;
  }

  // ============================================================
  // NEXT ACTION
  // ============================================================

  ProjectContributionModel? get nextContributionAction {
    if (_contributions.isEmpty) {
      return null;
    }

    const priority =
        <
          ProjectContributionStatus,
          int
        >{
          ProjectContributionStatus.delivered: 0,
          ProjectContributionStatus.waitingApproval: 1,
          ProjectContributionStatus.ready: 2,
          ProjectContributionStatus.inProgress: 3,
          ProjectContributionStatus.blocked: 4,
          ProjectContributionStatus.draft: 5,
          ProjectContributionStatus.validated: 6,
        };

    final pending = _contributions
        .where(
          (
            contribution,
          ) => !contribution.isValidated,
        )
        .toList();

    if (pending.isEmpty) {
      return null;
    }

    pending.sort(
      (
        a,
        b,
      ) {
        final aPriority =
            a.status ==
                    ProjectContributionStatus.waitingApproval &&
                isContributionPlanApproved(
                  a,
                )
            ? priority[ProjectContributionStatus.ready] ??
                  999
            : priority[a.status] ??
                  999;

        final bPriority =
            b.status ==
                    ProjectContributionStatus.waitingApproval &&
                isContributionPlanApproved(
                  b,
                )
            ? priority[ProjectContributionStatus.ready] ??
                  999
            : priority[b.status] ??
                  999;

        if (aPriority !=
            bPriority) {
          return aPriority.compareTo(
            bPriority,
          );
        }

        final aDue = a.dueAt;

        final bDue = b.dueAt;

        if (aDue !=
                null &&
            bDue !=
                null) {
          return aDue.compareTo(
            bDue,
          );
        }

        if (aDue !=
            null) {
          return -1;
        }

        if (bDue !=
            null) {
          return 1;
        }

        return a.createdAt.compareTo(
          b.createdAt,
        );
      },
    );

    return pending.first;
  }

  // ============================================================
  // NEXT ACTION MEMBER
  // ============================================================

  ProjectTaskMemberModel? get nextActionMember {
    final contribution = nextContributionAction;

    if (contribution ==
        null) {
      return null;
    }

    return findMember(
      contribution.userId,
    );
  }

  // ============================================================
  // CREATE CONTRIBUTION
  // ============================================================

  Future<
    ProjectContributionModel
  >
  createContribution({
    required String title,
    required String description,
    String? dependencyContributionId,
    DateTime? dueAt,
  }) async {
    final projectId = _requireProjectId();

    final userId = _requireCurrentUserId();

    final member = currentMember;

    if (member ==
        null) {
      throw StateError(
        'Usuário não encontrado entre os membros do projeto.',
      );
    }

    if (currentUserContribution !=
        null) {
      throw StateError(
        'Você já possui uma contribuição neste projeto.',
      );
    }

    final created = await repository.createContribution(
      projectId: projectId,
      userId: userId,
      title: title,
      description: description,
      roleSnapshot: member.resolvedProfessionalRole,
      dependencyContributionId: dependencyContributionId,
      dueAt: dueAt,
    );

    await _createRecordEventSafely(
      eventNames:
          const <
            String
          >[
            'contributionCreated',
            'contribution_created',
            'contribution.created',
          ],
      actorUserId: userId,
      entityType: 'contribution',
      entityId: created.id,
      payload:
          <
            String,
            dynamic
          >{
            'contribution_id': created.id,
            'user_id': userId,
            'title': created.title,
            'version': created.version,
            'role': member.resolvedProfessionalRole,
            'due_at': created.dueAt?.toUtc().toIso8601String(),
          },
    );

    await refresh();

    return created;
  }

  // ============================================================
  // UPDATE CONTRIBUTION
  // ============================================================

  Future<
    ProjectContributionModel
  >
  updateContribution(
    ProjectContributionModel contribution,
  ) async {
    final currentUserId = _requireCurrentUserId();

    if (contribution.userId !=
        currentUserId) {
      throw StateError(
        'Você só pode editar sua própria contribuição.',
      );
    }

    if (!contribution.canBeEdited) {
      throw StateError(
        'Esta contribuição não pode mais ser editada.',
      );
    }

    final updated = await repository.updateContribution(
      contribution: contribution,
    );

    await _createRecordEventSafely(
      eventNames:
          const <
            String
          >[
            'contributionUpdated',
            'contribution_updated',
            'contribution.updated',
          ],
      actorUserId: currentUserId,
      entityType: 'contribution',
      entityId: updated.id,
      payload:
          <
            String,
            dynamic
          >{
            'contribution_id': updated.id,
            'user_id': updated.userId,
            'title': updated.title,
            'version': updated.version,
            'status': updated.statusDatabaseValue,
            'due_at': updated.dueAt?.toUtc().toIso8601String(),
          },
    );

    await refresh();

    return updated;
  }

  // ============================================================
  // SUBMIT CONTRIBUTION
  // ============================================================

  Future<
    ProjectContributionModel
  >
  submitContributionForApproval(
    ProjectContributionModel contribution,
  ) async {
    final currentUserId = _requireCurrentUserId();

    if (contribution.userId !=
        currentUserId) {
      throw StateError(
        'Você só pode enviar sua própria contribuição para aprovação.',
      );
    }

    final updated = await repository.submitContributionForApproval(
      contributionId: contribution.id,
    );

    await refresh();

    return updated;
  }

  // ============================================================
  // APPROVE CONTRIBUTION
  // ============================================================

  Future<
    ContributionApprovalModel
  >
  approveContribution(
    ProjectContributionModel contribution,
  ) async {
    final currentUserId = _requireCurrentUserId();

    if (currentUserApprovedContribution(
      contribution,
    )) {
      throw StateError(
        'Você já confirmou esta contribuição.',
      );
    }

    final approval = await repository.approveContribution(
      contributionId: contribution.id,
      userId: currentUserId,
      contributionVersion: contribution.version,
    );

    await refresh();

    final refreshedContribution =
        findContribution(
          contribution.id,
        ) ??
        contribution;

    if (isContributionPlanApproved(
      refreshedContribution,
    )) {
      await _createRecordEventSafely(
        eventNames:
            const <
              String
            >[
              'contributionApproved',
              'contribution_approved',
              'contribution.approved',
            ],
        actorUserId: currentUserId,
        entityType: 'contribution',
        entityId: refreshedContribution.id,
        payload:
            <
              String,
              dynamic
            >{
              'contribution_id': refreshedContribution.id,
              'user_id': refreshedContribution.userId,
              'title': refreshedContribution.title,
              'version': refreshedContribution.version,
              'approved_count': approvalCountForContribution(
                refreshedContribution,
              ),
              'required_approval_count': requiredApprovalCountPerContribution,
              'collective_approval': true,
            },
      );
    }

    return approval;
  }

  // ============================================================
  // START CONTRIBUTION
  // ============================================================

  Future<
    ProjectContributionModel
  >
  startContribution(
    ProjectContributionModel contribution,
  ) async {
    final currentUserId = _requireCurrentUserId();

    if (contribution.userId !=
        currentUserId) {
      throw StateError(
        'Você só pode iniciar sua própria contribuição.',
      );
    }

    final updated = await repository.startContribution(
      contributionId: contribution.id,
    );

    await _createRecordEventSafely(
      eventNames:
          const <
            String
          >[
            'contributionStarted',
            'contribution_started',
            'contribution.started',
          ],
      actorUserId: currentUserId,
      entityType: 'contribution',
      entityId: updated.id,
      payload:
          <
            String,
            dynamic
          >{
            'contribution_id': updated.id,
            'user_id': updated.userId,
            'title': updated.title,
            'version': updated.version,
          },
    );

    await refresh();

    return updated;
  }

  // ============================================================
  // CREATE DELIVERY METADATA
  // ============================================================

  Future<
    ContributionDeliveryModel
  >
  createDelivery({
    required ProjectContributionModel contribution,
    required String fileName,
    required String storagePath,
    required int version,
    required int fileSize,
    required String sha256,
    String? mimeType,
  }) async {
    final currentUserId = _requireCurrentUserId();

    if (contribution.userId !=
        currentUserId) {
      throw StateError(
        'Você só pode enviar arquivos para sua própria contribuição.',
      );
    }

    final delivery = await repository.createDelivery(
      contributionId: contribution.id,
      uploadedBy: currentUserId,
      fileName: fileName,
      storagePath: storagePath,
      version: version,
      fileSize: fileSize,
      sha256: sha256,
      mimeType: mimeType,
    );

    await repository.markContributionDelivered(
      contributionId: contribution.id,
    );

    await _createRecordEventSafely(
      eventNames:
          const <
            String
          >[
            'deliverySubmitted',
            'delivery_submitted',
            'delivery.submitted',
          ],
      actorUserId: currentUserId,
      entityType: 'delivery',
      entityId: delivery.id,
      payload:
          <
            String,
            dynamic
          >{
            'delivery_id': delivery.id,
            'contribution_id': contribution.id,
            'contribution_title': contribution.title,
            'uploaded_by': currentUserId,
            'file_name': fileName,
            'storage_path': storagePath,
            'version': version,
            'file_size': fileSize,
            'sha256': sha256,
            'mime_type': mimeType,
          },
    );

    // ==========================================================
    // PRODUÇÃO CRIATIVA — ARQUIVO ADICIONADO
    // ==========================================================
    //
    // O arquivo já foi persistido como delivery neste ponto.
    //
    // Usamos delivery.id como source_id, garantindo que um retry
    // não conte o mesmo arquivo duas vezes no gráfico.
    //
    // ==========================================================

    await _recordFileAddedSafely(
      deliveryId: delivery.id,
      contributionId: contribution.id,
      contributionTitle: contribution.title,
      fileName: fileName,
      storagePath: storagePath,
      fileSize: fileSize,
      version: version,
      mimeType: mimeType,
      sha256: sha256,
    );

    await refresh();

    return delivery;
  }

  // ============================================================
  // VALIDATE DELIVERY
  // ============================================================

  Future<
    ContributionDeliveryModel
  >
  validateDelivery(
    ContributionDeliveryModel delivery,
  ) async {
    final currentUserId = _requireCurrentUserId();

    final validated = await repository.validateDelivery(
      deliveryId: delivery.id,
    );

    await _createRecordEventSafely(
      eventNames:
          const <
            String
          >[
            'deliveryValidated',
            'delivery_validated',
            'delivery.validated',
          ],
      actorUserId: currentUserId,
      entityType: 'delivery',
      entityId: validated.id,
      payload:
          <
            String,
            dynamic
          >{
            'delivery_id': validated.id,
            'contribution_id': validated.contributionId,
            'validated_by': currentUserId,
            'version': validated.version,
          },
    );

    await refresh();

    // ==========================================================
    // PRODUÇÃO CRIATIVA — TAREFA CONCLUÍDA
    // ==========================================================
    //
    // Para o Dashboard, cada contribuição cuja entrega foi
    // validada representa uma tarefa concluída.
    //
    // Usamos contributionId como source_id para garantir
    // idempotência no Supabase.
    //
    // ==========================================================

    final validatedContribution = findContribution(
      validated.contributionId,
    );

    await _recordTaskCompletedSafely(
      contributionId: validated.contributionId,
      contributionTitle: validatedContribution?.title,
      validatedDeliveryId: validated.id,
    );

    if (isWorkflowCompleted) {
      await _createRecordEventSafely(
        eventNames:
            const <
              String
            >[
              'projectCompleted',
              'project_completed',
              'project.completed',
            ],
        actorUserId: currentUserId,
        entityType: 'project',
        entityId: _requireProjectId(),
        payload:
            <
              String,
              dynamic
            >{
              'project_id': _requireProjectId(),
              'contribution_count': contributionCount,
              'delivery_count': deliveryCount,
              'completed_at': DateTime.now().toUtc().toIso8601String(),
            },
      );

      await refresh();
    }

    return validated;
  }

  // ============================================================
  // REJECT DELIVERY
  // ============================================================

  Future<
    ContributionDeliveryModel
  >
  rejectDelivery(
    ContributionDeliveryModel delivery,
  ) async {
    final currentUserId = _requireCurrentUserId();

    final rejected = await repository.rejectDelivery(
      deliveryId: delivery.id,
    );

    await _createRecordEventSafely(
      eventNames:
          const <
            String
          >[
            'deliveryRejected',
            'delivery_rejected',
            'delivery.rejected',
          ],
      actorUserId: currentUserId,
      entityType: 'delivery',
      entityId: rejected.id,
      payload:
          <
            String,
            dynamic
          >{
            'delivery_id': rejected.id,
            'contribution_id': rejected.contributionId,
            'rejected_by': currentUserId,
            'version': rejected.version,
          },
    );

    await refresh();

    return rejected;
  }

  // ============================================================
  // ATTACH CALENDAR EVENT
  // ============================================================

  Future<
    ProjectContributionModel
  >
  attachCalendarEvent({
    required ProjectContributionModel contribution,
    required String calendarEventId,
  }) async {
    final updated = await repository.attachCalendarEvent(
      contributionId: contribution.id,
      calendarEventId: calendarEventId,
    );

    await refresh();

    return updated;
  }

  // ============================================================
  // DETACH CALENDAR EVENT
  // ============================================================

  Future<
    ProjectContributionModel
  >
  detachCalendarEvent(
    ProjectContributionModel contribution,
  ) async {
    final updated = await repository.detachCalendarEvent(
      contributionId: contribution.id,
    );

    await refresh();

    return updated;
  }

  // ============================================================
  // PRODUÇÃO CRIATIVA — FILE ADDED
  // ============================================================
  //
  // Registra um arquivo de entrega como atividade criativa.
  //
  // REGRAS:
  //
  // - deliveryId é usado como source_id;
  // - a mesma entrega só conta uma vez;
  // - retry não duplica a métrica;
  // - falha de analytics não desfaz o upload/registro da entrega.
  //
  // ============================================================

  Future<
    void
  >
  _recordFileAddedSafely({
    required String deliveryId,
    required String contributionId,
    required String contributionTitle,
    required String fileName,
    required String storagePath,
    required int fileSize,
    required int version,
    required String sha256,
    String? mimeType,
  }) async {
    final normalizedDeliveryId = deliveryId.trim();

    final normalizedContributionId = contributionId.trim();

    final normalizedFileName = fileName.trim();

    final normalizedStoragePath = storagePath.trim();

    final normalizedContributionTitle = contributionTitle.trim();

    final normalizedSha256 = sha256.trim();

    final normalizedMimeType = mimeType?.trim();

    if (normalizedDeliveryId.isEmpty) {
      return;
    }

    final projectId = _projectId?.trim();

    if (projectId ==
            null ||
        projectId.isEmpty) {
      return;
    }

    try {
      await _creativeActivityService.recordFileAdded(
        fileId: normalizedDeliveryId,
        projectId: projectId,
        metadata:
            <
              String,
              dynamic
            >{
              'origin': 'project_tasks',
              'entity_type': 'delivery',
              'delivery_id': normalizedDeliveryId,
              if (normalizedContributionId.isNotEmpty) 'contribution_id': normalizedContributionId,
              if (normalizedContributionTitle.isNotEmpty) 'contribution_title': normalizedContributionTitle,
              if (normalizedFileName.isNotEmpty) 'file_name': normalizedFileName,
              if (normalizedStoragePath.isNotEmpty) 'storage_path': normalizedStoragePath,
              'file_size': fileSize,
              'version': version,
              if (normalizedSha256.isNotEmpty) 'sha256': normalizedSha256,
              if (normalizedMimeType !=
                      null &&
                  normalizedMimeType.isNotEmpty)
                'mime_type': normalizedMimeType,
            },
      );

      debugPrint(
        '[PROJECT TASKS] '
        'Produção criativa registrada: file_added '
        'para $normalizedDeliveryId.',
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[PROJECT TASKS] '
        'Arquivo entregue, mas não foi possível registrar '
        'file_added: '
        '$error',
      );

      debugPrint(
        '[PROJECT TASKS] '
        '$stackTrace',
      );
    }
  }

  // ============================================================
  // PRODUÇÃO CRIATIVA — TASK COMPLETED
  // ============================================================
  //
  // Registra uma contribuição validada como tarefa concluída.
  //
  // REGRAS:
  //
  // - contributionId é o source_id;
  // - a mesma contribuição só pode contar uma vez;
  // - retry/revalidação não duplica a métrica;
  // - falha de analytics não desfaz a validação principal.
  //
  // ============================================================

  Future<
    void
  >
  _recordTaskCompletedSafely({
    required String contributionId,
    String? contributionTitle,
    String? validatedDeliveryId,
  }) async {
    final normalizedContributionId = contributionId.trim();

    if (normalizedContributionId.isEmpty) {
      return;
    }

    final projectId = _projectId?.trim();

    if (projectId ==
            null ||
        projectId.isEmpty) {
      return;
    }

    final normalizedTitle = contributionTitle?.trim();

    final normalizedDeliveryId = validatedDeliveryId?.trim();

    try {
      await _creativeActivityService.recordTaskCompleted(
        taskId: normalizedContributionId,
        projectId: projectId,
        metadata:
            <
              String,
              dynamic
            >{
              'origin': 'project_tasks',
              'entity_type': 'contribution',
              'contribution_id': normalizedContributionId,
              if (normalizedTitle !=
                      null &&
                  normalizedTitle.isNotEmpty)
                'contribution_title': normalizedTitle,
              if (normalizedDeliveryId !=
                      null &&
                  normalizedDeliveryId.isNotEmpty)
                'validated_delivery_id': normalizedDeliveryId,
            },
      );

      debugPrint(
        '[PROJECT TASKS] '
        'Produção criativa registrada: task_completed '
        'para $normalizedContributionId.',
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[PROJECT TASKS] '
        'Contribuição validada, mas não foi possível registrar '
        'task_completed: '
        '$error',
      );

      debugPrint(
        '[PROJECT TASKS] '
        '$stackTrace',
      );
    }
  }

  // ============================================================
  // VERSIN RECORD
  // ============================================================
  //
  // Registra somente eventos relevantes do fluxo.
  //
  // IMPORTANTE:
  //
  // - falha no histórico NÃO desfaz a ação principal;
  // - o Controller não calcula hashes;
  // - os hashes continuam sendo responsabilidade do
  //   ContributionIntegrityService;
  // - usamos resolução por nome para manter compatibilidade com
  //   diferentes versões do enum ProjectRecordEventType.
  //
  // ============================================================

  Future<
    void
  >
  _createRecordEventSafely({
    required List<
      String
    >
    eventNames,
    required Map<
      String,
      dynamic
    >
    payload,
    String? actorUserId,
    String? entityType,
    String? entityId,
  }) async {
    final projectId = _projectId?.trim();

    if (projectId ==
            null ||
        projectId.isEmpty) {
      return;
    }

    final eventType = _resolveRecordEventType(
      eventNames,
    );

    if (eventType ==
        null) {
      debugPrint(
        '[PROJECT TASKS] '
        'Versin Record ignorado: tipo de evento não encontrado. '
        'Tentativas: $eventNames',
      );

      return;
    }

    try {
      await repository.createProjectRecordEvent(
        projectId: projectId,
        eventType: eventType,
        payload: payload,
        createdAt: DateTime.now().toUtc(),
        actorUserId: actorUserId,
        entityType: entityType,
        entityId: entityId,
      );

      debugPrint(
        '[PROJECT TASKS] '
        'Versin Record criado: '
        '${eventType.name}',
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[PROJECT TASKS] '
        'Falha ao registrar Versin Record: '
        '$error',
      );

      debugPrint(
        '[PROJECT TASKS] '
        '$stackTrace',
      );
    }
  }

  // ============================================================
  // RESOLVE RECORD EVENT TYPE
  // ============================================================

  ProjectRecordEventType? _resolveRecordEventType(
    List<
      String
    >
    candidates,
  ) {
    final normalizedCandidates = candidates
        .map(
          _normalizeRecordEventName,
        )
        .where(
          (
            value,
          ) => value.isNotEmpty,
        )
        .toSet();

    for (final eventType in ProjectRecordEventType.values) {
      final names =
          <
            String
          >{
            _normalizeRecordEventName(
              eventType.name,
            ),
            _normalizeRecordEventName(
              eventType.toString(),
            ),
          };

      if (names.any(
        normalizedCandidates.contains,
      )) {
        return eventType;
      }
    }

    return null;
  }

  // ============================================================
  // NORMALIZE RECORD EVENT NAME
  // ============================================================

  String _normalizeRecordEventName(
    String value,
  ) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(
          'projectrecordeventtype.',
          '',
        )
        .replaceAll(
          RegExp(
            r'[^a-z0-9]',
          ),
          '',
        );
  }

  // ============================================================
  // FIND MEMBER
  // ============================================================

  ProjectTaskMemberModel? findMember(
    String userId,
  ) {
    final normalized = userId.trim();

    if (normalized.isEmpty) {
      return null;
    }

    for (final member in _members) {
      if (member.userId ==
          normalized) {
        return member;
      }
    }

    return null;
  }

  // ============================================================
  // NORMALIZE MEMBERS
  // ============================================================

  List<
    ProjectTaskMemberModel
  >
  _normalizeMembers(
    List<
      ProjectTaskMemberModel
    >
    members,
  ) {
    final unique =
        <
          String,
          ProjectTaskMemberModel
        >{};

    for (final member in members) {
      final userId = member.userId.trim();

      if (userId.isEmpty) {
        continue;
      }

      unique[userId] = member;
    }

    final result = unique.values.toList();

    result.sort(
      (
        a,
        b,
      ) {
        if (a.isFounder !=
            b.isFounder) {
          return a.isFounder
              ? -1
              : 1;
        }

        return a.resolvedDisplayName.toLowerCase().compareTo(
          b.resolvedDisplayName.toLowerCase(),
        );
      },
    );

    return result;
  }

  // ============================================================
  // NORMALIZE CONTRIBUTIONS
  // ============================================================

  List<
    ProjectContributionModel
  >
  _normalizeContributions(
    List<
      ProjectContributionModel
    >
    contributions,
  ) {
    final unique =
        <
          String,
          ProjectContributionModel
        >{};

    for (final contribution in contributions) {
      final id = contribution.id.trim();

      if (id.isEmpty) {
        continue;
      }

      final current = unique[id];

      if (current ==
              null ||
          contribution.version >=
              current.version) {
        unique[id] = contribution;
      }
    }

    final result = unique.values.toList();

    result.sort(
      (
        a,
        b,
      ) => a.createdAt.compareTo(
        b.createdAt,
      ),
    );

    return result;
  }

  // ============================================================
  // NORMALIZE APPROVALS
  // ============================================================

  List<
    ContributionApprovalModel
  >
  _normalizeApprovals(
    List<
      ContributionApprovalModel
    >
    approvals,
  ) {
    final unique =
        <
          String,
          ContributionApprovalModel
        >{};

    for (final approval in approvals) {
      final key =
          '${approval.contributionId}:'
          '${approval.userId}:'
          '${approval.contributionVersion}';

      unique[key] = approval;
    }

    final result = unique.values.toList();

    result.sort(
      (
        a,
        b,
      ) => a.approvedAt.compareTo(
        b.approvedAt,
      ),
    );

    return result;
  }

  // ============================================================
  // NORMALIZE DELIVERIES
  // ============================================================

  List<
    ContributionDeliveryModel
  >
  _normalizeDeliveries(
    List<
      ContributionDeliveryModel
    >
    deliveries,
  ) {
    final unique =
        <
          String,
          ContributionDeliveryModel
        >{};

    for (final delivery in deliveries) {
      final id = delivery.id.trim();

      if (id.isEmpty) {
        continue;
      }

      unique[id] = delivery;
    }

    final result = unique.values.toList();

    result.sort(
      (
        a,
        b,
      ) {
        final versionCompare = b.version.compareTo(
          a.version,
        );

        if (versionCompare !=
            0) {
          return versionCompare;
        }

        return b.createdAt.compareTo(
          a.createdAt,
        );
      },
    );

    return result;
  }

  // ============================================================
  // NORMALIZE RECORD EVENTS
  // ============================================================

  List<
    ProjectRecordEventModel
  >
  _normalizeRecordEvents(
    List<
      ProjectRecordEventModel
    >
    events,
  ) {
    final unique =
        <
          String,
          ProjectRecordEventModel
        >{};

    for (final event in events) {
      final id = event.id.trim();

      if (id.isEmpty) {
        continue;
      }

      unique[id] = event;
    }

    final result = unique.values.toList();

    result.sort(
      (
        a,
        b,
      ) => b.createdAt.compareTo(
        a.createdAt,
      ),
    );

    return result;
  }

  // ============================================================
  // CLEAR COLLECTIONS
  // ============================================================

  void _clearCollections() {
    _members =
        const <
          ProjectTaskMemberModel
        >[];

    _contributions =
        const <
          ProjectContributionModel
        >[];

    _approvals =
        const <
          ContributionApprovalModel
        >[];

    _deliveries =
        const <
          ContributionDeliveryModel
        >[];

    _recordEvents =
        const <
          ProjectRecordEventModel
        >[];
  }

  // ============================================================
  // CANCEL REALTIME
  // ============================================================

  Future<
    void
  >
  _cancelRealtime() async {
    await _membersSubscription?.cancel();

    await _contributionsSubscription?.cancel();

    await _approvalsSubscription?.cancel();

    await _deliveriesSubscription?.cancel();

    await _recordEventsSubscription?.cancel();

    _membersSubscription = null;

    _contributionsSubscription = null;

    _approvalsSubscription = null;

    _deliveriesSubscription = null;

    _recordEventsSubscription = null;
  }

  // ============================================================
  // REQUIRE PROJECT ID
  // ============================================================

  String _requireProjectId() {
    final value = _projectId?.trim();

    if (value ==
            null ||
        value.isEmpty) {
      throw StateError(
        'Projeto não inicializado.',
      );
    }

    return value;
  }

  // ============================================================
  // REQUIRE CURRENT USER
  // ============================================================

  String _requireCurrentUserId() {
    final value = _currentUserId?.trim();

    if (value ==
            null ||
        value.isEmpty) {
      throw StateError(
        'Usuário não identificado.',
      );
    }

    return value;
  }

  // ============================================================
  // CLEAR ERROR
  // ============================================================

  void clearError() {
    if (_errorMessage ==
        null) {
      return;
    }

    _errorMessage = null;

    notifyListeners();
  }

  // ============================================================
  // SET ERROR
  // ============================================================

  void _setError(
    String message,
  ) {
    _errorMessage = message;

    _isLoading = false;

    notifyListeners();
  }

  // ============================================================
  // RESOLVE ERROR
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

    return 'Não foi possível carregar '
        'os dados do projeto.';
  }

  // ============================================================
  // RESET
  // ============================================================

  Future<
    void
  >
  reset() async {
    await _cancelRealtime();

    _projectId = null;

    _currentUserId = null;

    _clearCollections();

    _isLoading = false;

    _isInitialized = false;

    _errorMessage = null;

    notifyListeners();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    unawaited(
      _cancelRealtime(),
    );

    super.dispose();
  }
}
