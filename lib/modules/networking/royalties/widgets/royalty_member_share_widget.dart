import 'package:flutter/material.dart';

import '../models/royalty_member_model.dart';

// ============================================================
// ROYALTY MEMBER SHARE WIDGET
// ============================================================
//
// Linha individual de um participante.
//
// Pode funcionar em:
//
// - modo leitura;
// - modo edição.
//
// A View/Controller decide se pode editar.
//
// ============================================================

class RoyaltyMemberShareWidget
    extends
        StatelessWidget {
  final RoyaltyMemberModel member;

  final double percentage;

  final bool editable;

  final bool isCurrentUser;

  final ValueChanged<
    double
  >?
  onChanged;

  final double step;

  const RoyaltyMemberShareWidget({
    super.key,
    required this.member,
    required this.percentage,
    this.editable = false,
    this.isCurrentUser = false,
    this.onChanged,
    this.step = 5,
  });

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.all(
        12,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.025,
        ),
        borderRadius: BorderRadius.circular(
          13,
        ),
        border: Border.all(
          color: isCurrentUser
              ? const Color(
                  0xFFE100FF,
                ).withValues(
                  alpha: 0.14,
                )
              : Colors.white.withValues(
                  alpha: 0.045,
                ),
        ),
      ),
      child: Row(
        children: [
          _buildAvatar(),

          const SizedBox(
            width: 10,
          ),

          Expanded(
            child: _buildMemberInfo(),
          ),

          if (editable) _buildEditor() else _buildPercentage(),
        ],
      ),
    );
  }

  // ============================================================
  // AVATAR
  // ============================================================

  Widget _buildAvatar() {
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(
          0xFF24242C,
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.06,
          ),
        ),
      ),
      child: Text(
        member.initial,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ============================================================
  // MEMBER INFO
  // ============================================================

  Widget _buildMemberInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                member.displayName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            if (isCurrentUser) ...[
              const SizedBox(
                width: 5,
              ),
              const Text(
                'você',
                style: TextStyle(
                  color: Color(
                    0xFFE100FF,
                  ),
                  fontSize: 8,
                ),
              ),
            ],
          ],
        ),

        const SizedBox(
          height: 2,
        ),

        Row(
          children: [
            Flexible(
              child: Text(
                member.role,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white30,
                  fontSize: 8,
                ),
              ),
            ),

            if (member.isFounder) ...[
              const SizedBox(
                width: 6,
              ),
              const Text(
                '• Fundador',
                style: TextStyle(
                  color: Colors.amberAccent,
                  fontSize: 7,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  // ============================================================
  // PERCENTAGE
  // ============================================================

  Widget _buildPercentage() {
    return Text(
      _formattedPercentage(
        percentage,
      ),
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  // ============================================================
  // EDITOR
  // ============================================================

  Widget _buildEditor() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Diminuir porcentagem',
          onPressed:
              percentage <=
                  0
              ? null
              : () {
                  _change(
                    -step,
                  );
                },
          icon: const Icon(
            Icons.remove_circle_outline,
            size: 18,
            color: Colors.white38,
          ),
        ),

        SizedBox(
          width: 50,
          child: Text(
            _formattedPercentage(
              percentage,
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        IconButton(
          tooltip: 'Aumentar porcentagem',
          onPressed:
              percentage >=
                  100
              ? null
              : () {
                  _change(
                    step,
                  );
                },
          icon: const Icon(
            Icons.add_circle_outline,
            size: 18,
            color: Color(
              0xFFE100FF,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CHANGE
  // ============================================================

  void _change(
    double amount,
  ) {
    if (onChanged ==
        null) {
      return;
    }

    final next =
        (percentage +
                amount)
            .clamp(
              0.0,
              100.0,
            );

    onChanged!(
      next.toDouble(),
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
