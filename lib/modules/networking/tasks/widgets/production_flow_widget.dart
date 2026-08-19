import 'package:flutter/material.dart';

import '../models/contribution_delivery_model.dart';
import '../models/project_contribution_model.dart';
import '../models/project_task_member_model.dart';
import 'production_contribution_card.dart';

// ============================================================
// PRODUCTION FLOW ITEM
// ============================================================
//
// Une os dados necessários para desenhar UM participante.
//
// Não é model do banco.
//
// É um View Model simples da UI.
//
// ============================================================

class ProductionFlowItem {
  final ProjectTaskMemberModel member;

  final ProjectContributionModel? contribution;

  final ContributionDeliveryModel? delivery;

  final int approvedCount;

  final int requiredApprovalCount;

  final bool currentUserApproved;

  final bool canApprove;

  final bool canUpload;

  final bool isApproving;

  final bool isUploading;

  final double? uploadProgress;

  const ProductionFlowItem({
    required this.member,
    this.contribution,
    this.delivery,
    this.approvedCount = 0,
    this.requiredApprovalCount = 0,
    this.currentUserApproved = false,
    this.canApprove = false,
    this.canUpload = false,
    this.isApproving = false,
    this.isUploading = false,
    this.uploadProgress,
  });
}

// ============================================================
// PRODUCTION FLOW WIDGET
// ============================================================
//
// Exibe o fluxo de colaboração.
//
// Exemplo:
//
// João • Beatmaker
//     │
//     ▼
// Ana • Artista
//     │
//     ▼
// Lucas • Produtor
//
// Cada participante possui:
//
// - responsabilidade;
// - aprovação;
// - entrega;
// - hash;
// - status.
//
// ============================================================

class ProductionFlowWidget
    extends
        StatelessWidget {
  final List<
    ProductionFlowItem
  >
  items;

  final String? currentUserId;

  final void Function(
    ProjectTaskMemberModel member,
  )?
  onDefineContribution;

  final void Function(
    ProjectContributionModel contribution,
  )?
  onEditContribution;

  final void Function(
    ProjectContributionModel contribution,
  )?
  onApproveContribution;

  final void Function(
    ProjectContributionModel contribution,
  )?
  onUploadDelivery;

  final void Function(
    ContributionDeliveryModel delivery,
  )?
  onOpenDelivery;

  const ProductionFlowWidget({
    super.key,
    required this.items,
    this.currentUserId,
    this.onDefineContribution,
    this.onEditContribution,
    this.onApproveContribution,
    this.onUploadDelivery,
    this.onOpenDelivery,
  });

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    if (items.isEmpty) {
      return _buildEmpty();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ======================================================
        // HEADER
        // ======================================================
        const Row(
          children: [
            Icon(
              Icons.account_tree_outlined,
              size: 18,
              color: Color(
                0xFFE100FF,
              ),
            ),
            SizedBox(
              width: 8,
            ),
            Text(
              'Fluxo de produção',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 6,
        ),

        const Text(
          'Responsabilidades, validações e entregas da equipe.',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 11,
          ),
        ),

        const SizedBox(
          height: 18,
        ),

        // ======================================================
        // FLOW
        // ======================================================
        for (
          var index = 0;
          index <
              items.length;
          index++
        ) ...[
          _buildItem(
            items[index],
          ),

          if (index <
              items.length -
                  1)
            _buildConnector(),
        ],
      ],
    );
  }

  // ============================================================
  // ITEM
  // ============================================================

  Widget _buildItem(
    ProductionFlowItem item,
  ) {
    final contribution = item.contribution;

    final delivery = item.delivery;

    final isCurrentUser =
        currentUserId?.trim().isNotEmpty ==
            true &&
        item.member.userId ==
            currentUserId!.trim();

    return ProductionContributionCard(
      member: item.member,

      contribution: contribution,

      delivery: delivery,

      approvedCount: item.approvedCount,

      requiredApprovalCount: item.requiredApprovalCount,

      currentUserApproved: item.currentUserApproved,

      isCurrentUser: isCurrentUser,

      canApprove: item.canApprove,

      canUpload: item.canUpload,

      isApproving: item.isApproving,

      isUploading: item.isUploading,

      uploadProgress: item.uploadProgress,

      onDefineContribution:
          onDefineContribution ==
              null
          ? null
          : () {
              onDefineContribution!(
                item.member,
              );
            },

      onEditContribution:
          contribution ==
                  null ||
              onEditContribution ==
                  null
          ? null
          : () {
              onEditContribution!(
                contribution,
              );
            },

      onApprove:
          contribution ==
                  null ||
              onApproveContribution ==
                  null
          ? null
          : () {
              onApproveContribution!(
                contribution,
              );
            },

      onUpload:
          contribution ==
                  null ||
              onUploadDelivery ==
                  null
          ? null
          : () {
              onUploadDelivery!(
                contribution,
              );
            },

      onOpenDelivery:
          delivery ==
                  null ||
              onOpenDelivery ==
                  null
          ? null
          : () {
              onOpenDelivery!(
                delivery,
              );
            },
    );
  }

  // ============================================================
  // CONNECTOR
  // ============================================================

  Widget _buildConnector() {
    return Padding(
      padding: const EdgeInsets.only(
        left: 28,
      ),
      child: SizedBox(
        height: 30,
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 1,
                color:
                    const Color(
                      0xFFE100FF,
                    ).withValues(
                      alpha: 0.22,
                    ),
              ),
            ),

            Positioned(
              left: -6,
              bottom: 1,
              child: Icon(
                Icons.keyboard_arrow_down,
                size: 13,
                color:
                    const Color(
                      0xFFE100FF,
                    ).withValues(
                      alpha: 0.45,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmpty() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 30,
      ),
      decoration: BoxDecoration(
        color: const Color(
          0xFF121212,
        ),
        borderRadius: BorderRadius.circular(
          16,
        ),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.06,
          ),
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.account_tree_outlined,
            size: 30,
            color: Colors.white24,
          ),

          SizedBox(
            height: 10,
          ),

          Text(
            'Fluxo ainda não iniciado',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),

          SizedBox(
            height: 5,
          ),

          Text(
            'As contribuições dos participantes aparecerão aqui.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white30,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
