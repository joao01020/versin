import 'package:flutter/material.dart';

import '../models/contribution_delivery_model.dart';
import '../models/project_contribution_model.dart';
import '../models/project_task_member_model.dart';
import 'contribution_approval_widget.dart';
import 'contribution_delivery_widget.dart';

// ============================================================
// PRODUCTION CONTRIBUTION CARD
// ============================================================
//
// Card principal de um participante.
//
// Exemplo:
//
// ┌──────────────────────────────────────────┐
// │ JV  João                         Produtor│
// │     Fundador                            │
// │                                          │
// │ Mixagem e masterização                  │
// │ Finalizar mix e master do projeto       │
// │                                          │
// │ Validação da equipe              2/3     │
// │ ████████████░░░░                         │
// │                                          │
// │ beat_master.wav                  Enviado │
// │ SHA-256  a12bc...9ff2                    │
// └──────────────────────────────────────────┘
//
// ============================================================

class ProductionContributionCard
    extends
        StatelessWidget {
  final ProjectTaskMemberModel member;

  final ProjectContributionModel? contribution;

  final ContributionDeliveryModel? delivery;

  final int approvedCount;

  final int requiredApprovalCount;

  final bool currentUserApproved;

  final bool isCurrentUser;

  final bool canApprove;

  final bool canUpload;

  final bool isApproving;

  final bool isUploading;

  final double? uploadProgress;

  final VoidCallback? onDefineContribution;

  final VoidCallback? onEditContribution;

  final VoidCallback? onApprove;

  final VoidCallback? onUpload;

  final VoidCallback? onOpenDelivery;

  const ProductionContributionCard({
    super.key,
    required this.member,
    this.contribution,
    this.delivery,
    this.approvedCount = 0,
    this.requiredApprovalCount = 0,
    this.currentUserApproved = false,
    this.isCurrentUser = false,
    this.canApprove = false,
    this.canUpload = false,
    this.isApproving = false,
    this.isUploading = false,
    this.uploadProgress,
    this.onDefineContribution,
    this.onEditContribution,
    this.onApprove,
    this.onUpload,
    this.onOpenDelivery,
  });

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(
          0xFF121212,
        ),
        borderRadius: BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: isCurrentUser
              ? const Color(
                  0xFFE100FF,
                ).withValues(
                  alpha: 0.28,
                )
              : Colors.white.withValues(
                  alpha: 0.07,
                ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ====================================================
          // MEMBER
          // ====================================================
          Padding(
            padding: const EdgeInsets.all(
              16,
            ),
            child: _buildMemberHeader(),
          ),

          Divider(
            height: 1,
            color: Colors.white.withValues(
              alpha: 0.06,
            ),
          ),

          // ====================================================
          // CONTRIBUTION
          // ====================================================
          Padding(
            padding: const EdgeInsets.all(
              16,
            ),
            child:
                contribution ==
                    null
                ? _buildEmptyContribution()
                : _buildContribution(),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MEMBER HEADER
  // ============================================================

  Widget _buildMemberHeader() {
    return Row(
      children: [
        // ======================================================
        // AVATAR
        // ======================================================
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(
              0xFF211A3D,
            ),
            border: Border.all(
              color:
                  const Color(
                    0xFFE100FF,
                  ).withValues(
                    alpha: 0.25,
                  ),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            member.initials,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(
          width: 11,
        ),

        // ======================================================
        // NAME
        // ======================================================
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      member.resolvedDisplayName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  if (isCurrentUser) ...[
                    const SizedBox(
                      width: 6,
                    ),
                    const Text(
                      'você',
                      style: TextStyle(
                        color: Color(
                          0xFFE100FF,
                        ),
                        fontSize: 9,
                      ),
                    ),
                  ],
                ],
              ),

              if (member.isFounder)
                const Padding(
                  padding: EdgeInsets.only(
                    top: 3,
                  ),
                  child: Text(
                    'Fundador',
                    style: TextStyle(
                      color: Colors.amberAccent,
                      fontSize: 9,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // ======================================================
        // ROLE
        // ======================================================
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color:
                const Color(
                  0xFFE100FF,
                ).withValues(
                  alpha: 0.08,
                ),
            borderRadius: BorderRadius.circular(
              20,
            ),
          ),
          child: Text(
            member.resolvedProfessionalRole,
            style: const TextStyle(
              color: Color(
                0xFFE100FF,
              ),
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EMPTY CONTRIBUTION
  // ============================================================

  Widget _buildEmptyContribution() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Contribuição ainda não definida',
          style: TextStyle(
            color: Colors.white60,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(
          height: 6,
        ),

        Text(
          isCurrentUser
              ? 'Defina o que você pretende realizar neste projeto.'
              : 'Este participante ainda não definiu sua responsabilidade.',
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 11,
            height: 1.4,
          ),
        ),

        if (isCurrentUser &&
            onDefineContribution !=
                null) ...[
          const SizedBox(
            height: 13,
          ),
          OutlinedButton.icon(
            onPressed: onDefineContribution,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(
                0xFFE100FF,
              ),
            ),
            icon: const Icon(
              Icons.add,
              size: 16,
            ),
            label: const Text(
              'Definir minha contribuição',
              style: TextStyle(
                fontSize: 11,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ============================================================
  // CONTRIBUTION
  // ============================================================

  Widget _buildContribution() {
    final currentContribution = contribution!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ======================================================
        // TITLE
        // ======================================================
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentContribution.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  if (currentContribution.description.trim().isNotEmpty) ...[
                    const SizedBox(
                      height: 6,
                    ),
                    Text(
                      currentContribution.description,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        height: 1.45,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            if (isCurrentUser &&
                currentContribution.canBeEdited &&
                onEditContribution !=
                    null)
              IconButton(
                onPressed: onEditContribution,
                tooltip: 'Editar contribuição',
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 17,
                  color: Colors.white38,
                ),
              ),
          ],
        ),

        // ======================================================
        // VERSION / DEADLINE
        // ======================================================
        const SizedBox(
          height: 10,
        ),

        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            _buildMetadataChip(
              icon: Icons.history,
              text: 'Versão ${currentContribution.version}',
            ),

            if (currentContribution.dueAt !=
                null)
              _buildMetadataChip(
                icon: Icons.event_outlined,
                text: _formatDate(
                  currentContribution.dueAt!,
                ),
              ),

            _buildStatusChip(
              currentContribution,
            ),
          ],
        ),

        // ======================================================
        // APPROVAL
        // ======================================================
        if (currentContribution.isWaitingApproval ||
            currentContribution.isReady ||
            currentContribution.isBlocked) ...[
          const SizedBox(
            height: 14,
          ),
          ContributionApprovalWidget(
            approvedCount: approvedCount,
            requiredCount: requiredApprovalCount,
            currentUserApproved: currentUserApproved,
            canApprove: canApprove,
            isLoading: isApproving,
            onApprove: onApprove,
          ),
        ],

        // ======================================================
        // DELIVERY
        // ======================================================
        if (currentContribution.isInProgress ||
            currentContribution.isDelivered ||
            currentContribution.isValidated ||
            delivery !=
                null) ...[
          const SizedBox(
            height: 14,
          ),
          ContributionDeliveryWidget(
            delivery: delivery,
            canUpload: canUpload,
            isUploading: isUploading,
            uploadProgress: uploadProgress,
            onUpload: onUpload,
            onOpen: onOpenDelivery,
          ),
        ],
      ],
    );
  }

  // ============================================================
  // METADATA CHIP
  // ============================================================

  Widget _buildMetadataChip({
    required IconData icon,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.04,
        ),
        borderRadius: BorderRadius.circular(
          20,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 11,
            color: Colors.white38,
          ),
          const SizedBox(
            width: 4,
          ),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS CHIP
  // ============================================================

  Widget _buildStatusChip(
    ProjectContributionModel contribution,
  ) {
    late final String text;

    late final Color color;

    switch (contribution.status) {
      case ProjectContributionStatus.draft:
        text = 'Rascunho';

        color = Colors.white54;

      case ProjectContributionStatus.waitingApproval:
        text = 'Aguardando validação';

        color = Colors.amberAccent;

      case ProjectContributionStatus.blocked:
        text = 'Bloqueado';

        color = Colors.redAccent;

      case ProjectContributionStatus.ready:
        text = 'Aprovado';

        color = Colors.greenAccent;

      case ProjectContributionStatus.inProgress:
        text = 'Em produção';

        color = Colors.lightBlueAccent;

      case ProjectContributionStatus.delivered:
        text = 'Entregue';

        color = Colors.amberAccent;

      case ProjectContributionStatus.validated:
        text = 'Concluído';

        color = Colors.greenAccent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.07,
        ),
        borderRadius: BorderRadius.circular(
          20,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ============================================================
  // DATE
  // ============================================================

  String _formatDate(
    DateTime date,
  ) {
    final local = date.toLocal();

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
