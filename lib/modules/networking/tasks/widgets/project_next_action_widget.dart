import 'package:flutter/material.dart';

import '../controllers/project_tasks_controller.dart';
import '../models/project_contribution_model.dart';
import '../models/project_task_member_model.dart';

// ============================================================
// PROJECT NEXT ACTION WIDGET
// ============================================================
//
// Mostra rapidamente o que precisa acontecer agora.
//
// A partir desta versão, o widget também entende o estágio
// coletivo calculado pelo ProjectTasksController.
//
// Isso evita inconsistências como:
//
// 2/2 aprovações
// ↓
// ainda mostrar:
// "aguarda aprovação do grupo"
//
// ============================================================

class ProjectNextActionWidget
    extends
        StatelessWidget {
  final ProjectTaskMemberModel? member;

  final ProjectContributionModel? contribution;

  final ProjectTasksWorkflowStage? workflowStage;

  final String? workflowTitle;

  final String? workflowDescription;

  final bool allCompleted;

  final VoidCallback? onOpen;

  const ProjectNextActionWidget({
    super.key,
    this.member,
    this.contribution,
    this.workflowStage,
    this.workflowTitle,
    this.workflowDescription,
    this.allCompleted = false,
    this.onOpen,
  });

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    if (allCompleted ||
        workflowStage ==
            ProjectTasksWorkflowStage.completed) {
      return _buildCompleted();
    }

    // ==========================================================
    // COLLECTIVE WORKFLOW
    // ==========================================================
    //
    // Quando o controller informa o estágio do fluxo, ele tem
    // prioridade sobre o status individual da contribuição.
    //
    // ==========================================================

    if (workflowStage !=
        null) {
      return _buildWorkflowCard();
    }

    // ==========================================================
    // LEGACY FALLBACK
    // ==========================================================
    //
    // Mantém compatibilidade caso algum ponto antigo do projeto
    // ainda construa este widget sem workflowStage.
    //
    // ==========================================================

    if (member ==
            null ||
        contribution ==
            null) {
      return _buildEmpty();
    }

    return _buildLegacyCard();
  }

  // ============================================================
  // WORKFLOW CARD
  // ============================================================

  Widget _buildWorkflowCard() {
    final stage = workflowStage!;

    final contribution = this.contribution;

    final member = this.member;

    final title = _resolveWorkflowTitle(
      stage,
      member: member,
      contribution: contribution,
    );

    final subtitle = _resolveWorkflowSubtitle(
      stage,
      contribution: contribution,
    );

    final visual = _visualForStage(
      stage,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        16,
      ),
      decoration: BoxDecoration(
        color: visual.color.withValues(
          alpha: 0.055,
        ),
        borderRadius: BorderRadius.circular(
          16,
        ),
        border: Border.all(
          color: visual.color.withValues(
            alpha: 0.20,
          ),
        ),
      ),
      child: Row(
        children: [
          // ====================================================
          // ICON
          // ====================================================
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: visual.color.withValues(
                alpha: 0.11,
              ),
              borderRadius: BorderRadius.circular(
                12,
              ),
            ),
            child: Icon(
              visual.icon,
              color: visual.color,
              size: 20,
            ),
          ),

          const SizedBox(
            width: 11,
          ),

          // ====================================================
          // CONTENT
          // ====================================================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PRÓXIMA AÇÃO',
                  style: TextStyle(
                    color: visual.color,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),

                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 9,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),

          if (onOpen !=
                  null &&
              contribution !=
                  null)
            TextButton(
              onPressed: onOpen,
              child: const Text(
                'VER',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // WORKFLOW TITLE
  // ============================================================

  String _resolveWorkflowTitle(
    ProjectTasksWorkflowStage stage, {
    required ProjectTaskMemberModel? member,
    required ProjectContributionModel? contribution,
  }) {
    final explicitTitle = workflowTitle?.trim();

    if (explicitTitle !=
            null &&
        explicitTitle.isNotEmpty) {
      return explicitTitle;
    }

    switch (stage) {
      case ProjectTasksWorkflowStage.definingPlan:
        if (member !=
            null) {
          return '${member.resolvedDisplayName} precisa definir a contribuição.';
        }

        return 'Defina as contribuições do projeto.';

      case ProjectTasksWorkflowStage.awaitingApproval:
        if (contribution !=
            null) {
          return '${contribution.title} aguarda aprovação do grupo.';
        }

        return 'Aguardando aprovação do grupo.';

      case ProjectTasksWorkflowStage.awaitingFirstDelivery:
        return 'Aguardando primeira entrega.';

      case ProjectTasksWorkflowStage.deliveriesInProgress:
        if (member !=
                null &&
            contribution !=
                null) {
          return '${member.resolvedDisplayName} precisa enviar ${contribution.title.toLowerCase()}.';
        }

        return 'Contribuições em andamento.';

      case ProjectTasksWorkflowStage.awaitingDeliveryValidation:
        if (contribution !=
            null) {
          return '${contribution.title} aguarda validação da entrega.';
        }

        return 'Entregas aguardam validação.';

      case ProjectTasksWorkflowStage.completed:
        return 'Projeto pronto para finalização.';
    }
  }

  // ============================================================
  // WORKFLOW SUBTITLE
  // ============================================================

  String _resolveWorkflowSubtitle(
    ProjectTasksWorkflowStage stage, {
    required ProjectContributionModel? contribution,
  }) {
    final explicitDescription = workflowDescription?.trim();

    if (explicitDescription !=
            null &&
        explicitDescription.isNotEmpty) {
      return _appendDeadline(
        explicitDescription,
        contribution,
      );
    }

    switch (stage) {
      case ProjectTasksWorkflowStage.definingPlan:
        return 'Todos os participantes precisam definir suas responsabilidades.';

      case ProjectTasksWorkflowStage.awaitingApproval:
        return 'As contribuições precisam ser confirmadas por todos os participantes.';

      case ProjectTasksWorkflowStage.awaitingFirstDelivery:
        return _appendDeadline(
          'O plano foi aprovado. Os responsáveis já podem enviar seus arquivos.',
          contribution,
        );

      case ProjectTasksWorkflowStage.deliveriesInProgress:
        return _appendDeadline(
          'Aguardando as contribuições que ainda não foram entregues.',
          contribution,
        );

      case ProjectTasksWorkflowStage.awaitingDeliveryValidation:
        return 'Todos enviaram suas partes. Agora as entregas precisam ser confirmadas.';

      case ProjectTasksWorkflowStage.completed:
        return 'Todas as contribuições foram entregues e validadas.';
    }
  }

  // ============================================================
  // APPEND DEADLINE
  // ============================================================

  String _appendDeadline(
    String text,
    ProjectContributionModel? contribution,
  ) {
    final dueAt = contribution?.dueAt;

    if (dueAt ==
        null) {
      return text;
    }

    return '$text  Prazo: ${_formatDate(dueAt)}';
  }

  // ============================================================
  // WORKFLOW VISUAL
  // ============================================================

  _NextActionVisual _visualForStage(
    ProjectTasksWorkflowStage stage,
  ) {
    switch (stage) {
      case ProjectTasksWorkflowStage.definingPlan:
        return const _NextActionVisual(
          color: Colors.white54,
          icon: Icons.edit_note_rounded,
        );

      case ProjectTasksWorkflowStage.awaitingApproval:
        return const _NextActionVisual(
          color: Colors.amberAccent,
          icon: Icons.how_to_vote_outlined,
        );

      case ProjectTasksWorkflowStage.awaitingFirstDelivery:
        return const _NextActionVisual(
          color: Color(
            0xFFE100FF,
          ),
          icon: Icons.upload_file_outlined,
        );

      case ProjectTasksWorkflowStage.deliveriesInProgress:
        return const _NextActionVisual(
          color: Colors.lightBlueAccent,
          icon: Icons.cloud_upload_outlined,
        );

      case ProjectTasksWorkflowStage.awaitingDeliveryValidation:
        return const _NextActionVisual(
          color: Colors.orangeAccent,
          icon: Icons.fact_check_outlined,
        );

      case ProjectTasksWorkflowStage.completed:
        return const _NextActionVisual(
          color: Colors.greenAccent,
          icon: Icons.verified_rounded,
        );
    }
  }

  // ============================================================
  // LEGACY CARD
  // ============================================================

  Widget _buildLegacyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        16,
      ),
      decoration: BoxDecoration(
        color:
            const Color(
              0xFFE100FF,
            ).withValues(
              alpha: 0.055,
            ),
        borderRadius: BorderRadius.circular(
          16,
        ),
        border: Border.all(
          color:
              const Color(
                0xFFE100FF,
              ).withValues(
                alpha: 0.20,
              ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color:
                  const Color(
                    0xFFE100FF,
                  ).withValues(
                    alpha: 0.11,
                  ),
              borderRadius: BorderRadius.circular(
                12,
              ),
            ),
            child: const Icon(
              Icons.bolt_rounded,
              color: Color(
                0xFFE100FF,
              ),
              size: 20,
            ),
          ),

          const SizedBox(
            width: 11,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PRÓXIMA AÇÃO',
                  style: TextStyle(
                    color: Color(
                      0xFFE100FF,
                    ),
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),

                Text(
                  _buildLegacyTitle(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  _buildLegacySubtitle(),
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),

          if (onOpen !=
              null)
            TextButton(
              onPressed: onOpen,
              child: const Text(
                'VER',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // LEGACY TITLE
  // ============================================================

  String _buildLegacyTitle() {
    final currentMember = member!;

    final currentContribution = contribution!;

    switch (currentContribution.status) {
      case ProjectContributionStatus.draft:
        return '${currentMember.resolvedDisplayName} precisa definir a contribuição.';

      case ProjectContributionStatus.waitingApproval:
        return '${currentContribution.title} aguarda aprovação do grupo.';

      case ProjectContributionStatus.blocked:
        return '${currentContribution.title} está aguardando a etapa anterior.';

      case ProjectContributionStatus.ready:
        return '${currentMember.resolvedDisplayName} já pode iniciar ${currentContribution.title.toLowerCase()}.';

      case ProjectContributionStatus.inProgress:
        return '${currentMember.resolvedDisplayName} está trabalhando em ${currentContribution.title.toLowerCase()}.';

      case ProjectContributionStatus.delivered:
        return '${currentContribution.title} precisa ser validado pelo grupo.';

      case ProjectContributionStatus.validated:
        return '${currentContribution.title} foi concluído.';
    }
  }

  // ============================================================
  // LEGACY SUBTITLE
  // ============================================================

  String _buildLegacySubtitle() {
    final currentContribution = contribution!;

    if (currentContribution.dueAt !=
        null) {
      return 'Prazo: ${_formatDate(currentContribution.dueAt!)}';
    }

    switch (currentContribution.status) {
      case ProjectContributionStatus.draft:
        return 'Ainda não existe um compromisso formalizado.';

      case ProjectContributionStatus.waitingApproval:
        return 'Os participantes precisam confirmar a responsabilidade.';

      case ProjectContributionStatus.blocked:
        return 'Uma dependência precisa ser concluída primeiro.';

      case ProjectContributionStatus.ready:
        return 'A contribuição já foi aprovada.';

      case ProjectContributionStatus.inProgress:
        return 'Aguardando entrega.';

      case ProjectContributionStatus.delivered:
        return 'A entrega foi enviada e aguarda confirmação.';

      case ProjectContributionStatus.validated:
        return 'Contribuição concluída e registrada.';
    }
  }

  // ============================================================
  // COMPLETED
  // ============================================================

  Widget _buildCompleted() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        16,
      ),
      decoration: BoxDecoration(
        color: Colors.green.withValues(
          alpha: 0.06,
        ),
        borderRadius: BorderRadius.circular(
          16,
        ),
        border: Border.all(
          color: Colors.green.withValues(
            alpha: 0.18,
          ),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.verified_rounded,
            color: Colors.greenAccent,
            size: 20,
          ),

          SizedBox(
            width: 10,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Projeto pronto para finalização.',
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(
                  height: 3,
                ),
                Text(
                  'Todas as contribuições foram entregues e validadas.',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmpty() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        16,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.025,
        ),
        borderRadius: BorderRadius.circular(
          16,
        ),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.05,
          ),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.pending_actions_outlined,
            color: Colors.white24,
            size: 19,
          ),

          SizedBox(
            width: 10,
          ),

          Expanded(
            child: Text(
              'Ainda não existe uma próxima ação definida.',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 10,
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
}

// ============================================================
// NEXT ACTION VISUAL
// ============================================================

class _NextActionVisual {
  final Color color;

  final IconData icon;

  const _NextActionVisual({
    required this.color,
    required this.icon,
  });
}
