import 'package:flutter/material.dart';

import '../models/royalty_member_model.dart';
import 'royalty_member_share_widget.dart';

// ============================================================
// ROYALTY DISTRIBUTION WIDGET
// ============================================================
//
// Mostra:
//
// - total distribuído;
// - barra de progresso;
// - participantes;
// - porcentagens.
//
// O estado editável continua fora deste Widget.
//
// ============================================================

class RoyaltyDistributionWidget
    extends
        StatelessWidget {
  final List<
    RoyaltyMemberModel
  >
  members;

  final Map<
    String,
    double
  >
  percentagesByUserId;

  final bool editable;

  final String? currentUserId;

  final void Function(
    RoyaltyMemberModel member,
    double percentage,
  )?
  onPercentageChanged;

  const RoyaltyDistributionWidget({
    super.key,
    required this.members,
    required this.percentagesByUserId,
    this.editable = false,
    this.currentUserId,
    this.onPercentageChanged,
  });

  // ============================================================
  // TOTAL
  // ============================================================

  double get totalPercentage {
    return members.fold<
      double
    >(
      0,
      (
        total,
        member,
      ) {
        return total +
            (percentagesByUserId[member.userId] ??
                0);
      },
    );
  }

  bool get hasCorrectTotal {
    return (totalPercentage -
                100)
            .abs() <
        0.0001;
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
        children: [
          // ====================================================
          // TOTAL
          // ====================================================
          Row(
            children: [
              const Expanded(
                child: Text(
                  'TOTAL DISTRIBUÍDO',
                  style: TextStyle(
                    color: Colors.white30,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),

              Text(
                _formattedPercentage(
                  totalPercentage,
                ),
                style: TextStyle(
                  color: hasCorrectTotal
                      ? Colors.greenAccent
                      : Colors.redAccent,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 12,
          ),

          // ====================================================
          // PROGRESS
          // ====================================================
          ClipRRect(
            borderRadius: BorderRadius.circular(
              20,
            ),
            child: LinearProgressIndicator(
              value:
                  (totalPercentage /
                          100)
                      .clamp(
                        0.0,
                        1.0,
                      ),
              minHeight: 6,
              backgroundColor: Colors.white.withValues(
                alpha: 0.05,
              ),
              color: hasCorrectTotal
                  ? Colors.greenAccent
                  : const Color(
                      0xFFE100FF,
                    ),
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          // ====================================================
          // EMPTY
          // ====================================================
          if (members.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(
                vertical: 18,
              ),
              child: Text(
                'Nenhum participante encontrado no projeto.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                ),
              ),
            )
          else
            for (
              var index = 0;
              index <
                  members.length;
              index++
            ) ...[
              RoyaltyMemberShareWidget(
                member: members[index],
                percentage:
                    percentagesByUserId[members[index].userId] ??
                    0,
                editable: editable,
                isCurrentUser:
                    currentUserId?.trim() ==
                    members[index].userId,
                onChanged:
                    onPercentageChanged ==
                        null
                    ? null
                    : (
                        value,
                      ) {
                        onPercentageChanged!(
                          members[index],
                          value,
                        );
                      },
              ),

              if (index <
                  members.length -
                      1)
                const SizedBox(
                  height: 10,
                ),
            ],
        ],
      ),
    );
  }

  // ============================================================
  // FORMAT
  // ============================================================

  String _formattedPercentage(
    double value,
  ) {
    if (value ==
        value.roundToDouble()) {
      return '${value.toStringAsFixed(0)}%';
    }

    return '${value.toStringAsFixed(2)}%';
  }
}
