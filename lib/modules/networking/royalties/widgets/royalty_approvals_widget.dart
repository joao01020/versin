import 'package:flutter/material.dart';

import '../models/royalty_member_model.dart';

// ============================================================
// ROYALTY APPROVALS WIDGET
// ============================================================
//
// Exibe o consenso dos participantes.
//
// REGRA:
//
// Cada usuário pode confirmar apenas a própria participação.
//
// O widget NÃO:
//
// - confirma o acordo final;
// - calcula consenso;
// - acessa banco;
// - executa RPC;
// - conhece RLS.
//
// Quando o último usuário aprova:
//
// approve_royalty_agreement()
//        ↓
// PostgreSQL
//        ↓
// status = confirmed
//        ↓
// SHA-256
//        ↓
// evento final
//
// Portanto não existe mais botão:
//
// "CONFIRMAR ACORDO"
//
// ============================================================

class RoyaltyApprovalsWidget
    extends
        StatelessWidget {
  // ============================================================
  // MEMBERS
  // ============================================================

  final List<
    RoyaltyMemberModel
  >
  members;

  // ============================================================
  // APPROVED USERS
  // ============================================================

  final Set<
    String
  >
  approvedUserIds;

  // ============================================================
  // CURRENT USER
  // ============================================================

  final String? currentUserId;

  // ============================================================
  // AGREEMENT STATE
  // ============================================================

  final bool agreementLocked;

  // ============================================================
  // CURRENT USER ACTION
  // ============================================================

  final bool canApproveCurrentUser;

  final bool isApproving;

  final VoidCallback? onApproveCurrentUser;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  const RoyaltyApprovalsWidget({
    super.key,
    required this.members,
    required this.approvedUserIds,
    this.currentUserId,
    this.agreementLocked = false,
    this.canApproveCurrentUser = false,
    this.isApproving = false,
    this.onApproveCurrentUser,
  });

  // ============================================================
  // APPROVED COUNT
  // ============================================================

  int get approvedCount {
    return members
        .where(
          (
            member,
          ) => approvedUserIds.contains(
            member.userId,
          ),
        )
        .length;
  }

  // ============================================================
  // PENDING COUNT
  // ============================================================

  int get pendingCount {
    final value =
        members.length -
        approvedCount;

    return value <
            0
        ? 0
        : value;
  }

  // ============================================================
  // ALL APPROVED
  // ============================================================

  bool get allApproved {
    return members.isNotEmpty &&
        approvedCount ==
            members.length;
  }

  // ============================================================
  // CURRENT USER APPROVED
  // ============================================================

  bool get currentUserApproved {
    final normalizedUserId = currentUserId?.trim();

    if (normalizedUserId ==
            null ||
        normalizedUserId.isEmpty) {
      return false;
    }

    return approvedUserIds.contains(
      normalizedUserId,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        16,
      ),
      decoration: BoxDecoration(
        color: const Color(
          0xFF141419,
        ),
        borderRadius: BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.05,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ====================================================
          // HEADER
          // ====================================================
          _buildHeader(),

          const SizedBox(
            height: 14,
          ),

          // ====================================================
          // MEMBERS
          // ====================================================
          if (members.isEmpty) _buildEmpty() else _buildMembers(),

          // ====================================================
          // CURRENT USER ACTION
          // ====================================================
          if (_shouldShowApproveButton) ...[
            const SizedBox(
              height: 16,
            ),

            _buildApproveButton(),
          ],

          // ====================================================
          // CURRENT USER ALREADY APPROVED
          // ====================================================
          if (!agreementLocked &&
              currentUserApproved &&
              !allApproved) ...[
            const SizedBox(
              height: 14,
            ),

            _buildWaitingOthers(),
          ],

          // ====================================================
          // ALL APPROVED
          // ====================================================
          if (allApproved) ...[
            const SizedBox(
              height: 14,
            ),

            _buildCompletedState(),
          ],

          // ====================================================
          // LOCKED
          // ====================================================
          if (agreementLocked &&
              !allApproved) ...[
            const SizedBox(
              height: 14,
            ),

            _buildLockedState(),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color:
                const Color(
                  0xFFE100FF,
                ).withValues(
                  alpha: 0.07,
                ),
            borderRadius: BorderRadius.circular(
              11,
            ),
          ),
          child: const Icon(
            Icons.how_to_reg_outlined,
            color: Color(
              0xFFE100FF,
            ),
            size: 17,
          ),
        ),

        const SizedBox(
          width: 10,
        ),

        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Consenso dos participantes',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),

              SizedBox(
                height: 2,
              ),

              Text(
                'Cada membro confirma a própria participação.',
                style: TextStyle(
                  color: Colors.white30,
                  fontSize: 8,
                ),
              ),
            ],
          ),
        ),

        _buildCounter(),
      ],
    );
  }

  // ============================================================
  // COUNTER
  // ============================================================

  Widget _buildCounter() {
    final completed =
        allApproved ||
        agreementLocked;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: completed
            ? Colors.green.withValues(
                alpha: 0.08,
              )
            : Colors.orange.withValues(
                alpha: 0.07,
              ),
        borderRadius: BorderRadius.circular(
          20,
        ),
      ),
      child: Text(
        '$approvedCount/${members.length}',
        style: TextStyle(
          color: completed
              ? Colors.greenAccent
              : Colors.orangeAccent,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ============================================================
  // MEMBERS
  // ============================================================

  Widget _buildMembers() {
    return Column(
      children: [
        for (
          var index = 0;
          index <
              members.length;
          index++
        ) ...[
          _buildMember(
            members[index],
          ),

          if (index <
              members.length -
                  1)
            Padding(
              padding: const EdgeInsets.only(
                left: 40,
              ),
              child: Divider(
                height: 14,
                color: Colors.white.withValues(
                  alpha: 0.035,
                ),
              ),
            ),
        ],
      ],
    );
  }

  // ============================================================
  // MEMBER
  // ============================================================

  Widget _buildMember(
    RoyaltyMemberModel member,
  ) {
    final approved = approvedUserIds.contains(
      member.userId,
    );

    final current =
        currentUserId?.trim() ==
        member.userId;

    return Row(
      children: [
        // ======================================================
        // AVATAR
        // ======================================================
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: approved
                ? Colors.green.withValues(
                    alpha: 0.08,
                  )
                : Colors.white.withValues(
                    alpha: 0.035,
                  ),
            shape: BoxShape.circle,
            border: Border.all(
              color: approved
                  ? Colors.greenAccent.withValues(
                      alpha: 0.12,
                    )
                  : Colors.white.withValues(
                      alpha: 0.05,
                    ),
            ),
          ),
          child: approved
              ? const Icon(
                  Icons.check_rounded,
                  color: Colors.greenAccent,
                  size: 15,
                )
              : Text(
                  member.initial,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),

        const SizedBox(
          width: 9,
        ),

        // ======================================================
        // MEMBER INFO
        // ======================================================
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      member.displayName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  if (current) ...[
                    const SizedBox(
                      width: 5,
                    ),

                    const Text(
                      'você',
                      style: TextStyle(
                        color: Color(
                          0xFFE100FF,
                        ),
                        fontSize: 7,
                      ),
                    ),
                  ],

                  if (member.isFounder) ...[
                    const SizedBox(
                      width: 5,
                    ),

                    const Text(
                      '• fundador',
                      style: TextStyle(
                        color: Colors.amberAccent,
                        fontSize: 7,
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(
                height: 2,
              ),

              Text(
                member.role,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white24,
                  fontSize: 8,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(
          width: 8,
        ),

        // ======================================================
        // STATUS
        // ======================================================
        _buildMemberStatus(
          approved: approved,
        ),
      ],
    );
  }

  // ============================================================
  // MEMBER STATUS
  // ============================================================

  Widget _buildMemberStatus({
    required bool approved,
  }) {
    if (approved) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: Colors.greenAccent,
            size: 14,
          ),

          SizedBox(
            width: 4,
          ),

          Text(
            'CONFIRMADO',
            style: TextStyle(
              color: Colors.greenAccent,
              fontSize: 7,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }

    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.schedule_rounded,
          color: Colors.orangeAccent,
          size: 13,
        ),

        SizedBox(
          width: 4,
        ),

        Text(
          'PENDENTE',
          style: TextStyle(
            color: Colors.orangeAccent,
            fontSize: 7,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // APPROVE BUTTON VISIBILITY
  // ============================================================

  bool get _shouldShowApproveButton {
    return !agreementLocked &&
        !allApproved &&
        canApproveCurrentUser &&
        !currentUserApproved;
  }

  // ============================================================
  // APPROVE BUTTON
  // ============================================================

  Widget _buildApproveButton() {
    return SizedBox(
      width: double.infinity,
      height: 43,
      child: FilledButton.icon(
        onPressed: isApproving
            ? null
            : onApproveCurrentUser,
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
        icon: isApproving
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
            : const Icon(
                Icons.check_circle_outline_rounded,
                size: 17,
              ),
        label: Text(
          isApproving
              ? 'REGISTRANDO...'
              : 'CONFIRMAR MINHA PARTE',
          style: const TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.45,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // WAITING OTHERS
  // ============================================================

  Widget _buildWaitingOthers() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        11,
      ),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(
          alpha: 0.035,
        ),
        borderRadius: BorderRadius.circular(
          11,
        ),
        border: Border.all(
          color: Colors.orangeAccent.withValues(
            alpha: 0.09,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.hourglass_top_rounded,
            color: Colors.orangeAccent,
            size: 15,
          ),

          const SizedBox(
            width: 8,
          ),

          Expanded(
            child: Text(
              pendingCount ==
                      1
                  ? 'Sua confirmação foi registrada. Falta 1 participante.'
                  : 'Sua confirmação foi registrada. Faltam $pendingCount participantes.',
              style: const TextStyle(
                color: Colors.orangeAccent,
                fontSize: 8,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COMPLETED
  // ============================================================

  Widget _buildCompletedState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        12,
      ),
      decoration: BoxDecoration(
        color: Colors.green.withValues(
          alpha: 0.045,
        ),
        borderRadius: BorderRadius.circular(
          12,
        ),
        border: Border.all(
          color: Colors.greenAccent.withValues(
            alpha: 0.12,
          ),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.verified_rounded,
            color: Colors.greenAccent,
            size: 17,
          ),

          SizedBox(
            width: 9,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Consenso concluído',
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                SizedBox(
                  height: 3,
                ),

                Text(
                  'Todos os participantes confirmaram esta divisão. O banco finaliza o acordo e registra a integridade automaticamente.',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 8,
                    height: 1.4,
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
  // LOCKED
  // ============================================================

  Widget _buildLockedState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        11,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.025,
        ),
        borderRadius: BorderRadius.circular(
          11,
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
            Icons.lock_outline_rounded,
            color: Colors.white30,
            size: 15,
          ),

          SizedBox(
            width: 8,
          ),

          Expanded(
            child: Text(
              'Este acordo já foi encerrado e não aceita novas confirmações.',
              style: TextStyle(
                color: Colors.white30,
                fontSize: 8,
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
    return const Padding(
      padding: EdgeInsets.symmetric(
        vertical: 16,
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.groups_outlined,
              color: Colors.white24,
              size: 25,
            ),

            SizedBox(
              height: 8,
            ),

            Text(
              'Nenhum participante encontrado',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
