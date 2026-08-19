import 'package:flutter/material.dart';

import '../models/project_contribution_model.dart';
import '../models/project_task_member_model.dart';

// ============================================================
// PROJECT NEXT ACTION WIDGET
// ============================================================
//
// Mostra rapidamente o que precisa acontecer agora.
//
// Exemplo:
//
// PRÓXIMA AÇÃO
//
// Ana precisa concluir Vocais
// Prazo: 24/08/2026
//
// [VER CONTRIBUIÇÃO]
//
// ============================================================

class ProjectNextActionWidget
    extends
        StatelessWidget {
  final ProjectTaskMemberModel? member;

  final ProjectContributionModel? contribution;

  final bool allCompleted;

  final VoidCallback? onOpen;

  const ProjectNextActionWidget({
    super.key,
    this.member,
    this.contribution,
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
    if (allCompleted) {
      return _buildCompleted();
    }

    if (member ==
            null ||
        contribution ==
            null) {
      return _buildEmpty();
    }

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
          // ====================================================
          // ICON
          // ====================================================
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

          // ====================================================
          // CONTENT
          // ====================================================
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
                  _buildTitle(),
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
                  _buildSubtitle(),
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
  // TITLE
  // ============================================================

  String _buildTitle() {
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
  // SUBTITLE
  // ============================================================

  String _buildSubtitle() {
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
            child: Text(
              'Todas as contribuições foram concluídas.',
              style: TextStyle(
                color: Colors.greenAccent,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
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
