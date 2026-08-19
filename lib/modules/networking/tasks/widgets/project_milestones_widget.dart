import 'package:flutter/material.dart';

// ============================================================
// PROJECT MILESTONE MODEL
// ============================================================
//
// ViewModel simples para os marcos da colaboração.
//
// Não representa tabela do banco.
//
// ============================================================

class ProjectMilestoneItem {
  final String id;

  final String title;

  final String subtitle;

  final bool completed;

  final DateTime? completedAt;

  const ProjectMilestoneItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.completed,
    this.completedAt,
  });
}

// ============================================================
// PROJECT MILESTONES WIDGET
// ============================================================
//
// Mostra marcos coletivos do projeto.
//
// Exemplo:
//
// ✓ Plano de contribuição aprovado
// |
// ✓ Materiais iniciais liberados
// |
// ○ Vocais entregues
// |
// ○ Produção final concluída
// |
// ○ Obra pronta para finalização
//
// ============================================================

class ProjectMilestonesWidget
    extends
        StatelessWidget {
  final List<
    ProjectMilestoneItem
  >
  milestones;

  const ProjectMilestonesWidget({
    super.key,
    required this.milestones,
  });

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
      child: milestones.isEmpty
          ? _buildEmpty()
          : Column(
              children: [
                for (
                  var index = 0;
                  index <
                      milestones.length;
                  index++
                ) ...[
                  _buildMilestone(
                    milestone: milestones[index],
                    index: index,
                  ),

                  if (index <
                      milestones.length -
                          1)
                    _buildConnector(),
                ],
              ],
            ),
    );
  }

  // ============================================================
  // MILESTONE
  // ============================================================

  Widget _buildMilestone({
    required ProjectMilestoneItem milestone,
    required int index,
  }) {
    final completed = milestone.completed;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ======================================================
        // MARKER
        // ======================================================
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: completed
                ? Colors.green.withValues(
                    alpha: 0.10,
                  )
                : Colors.white.withValues(
                    alpha: 0.025,
                  ),
            shape: BoxShape.circle,
            border: Border.all(
              color: completed
                  ? Colors.greenAccent.withValues(
                      alpha: 0.28,
                    )
                  : Colors.white.withValues(
                      alpha: 0.06,
                    ),
            ),
          ),
          child: completed
              ? const Icon(
                  Icons.check_rounded,
                  color: Colors.greenAccent,
                  size: 17,
                )
              : Text(
                  '${index + 1}'.padLeft(
                    2,
                    '0',
                  ),
                  style: const TextStyle(
                    color: Colors.white24,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),

        const SizedBox(
          width: 11,
        ),

        // ======================================================
        // CONTENT
        // ======================================================
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(
              top: 2,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  milestone.title,
                  style: TextStyle(
                    color: completed
                        ? Colors.white70
                        : Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  milestone.subtitle,
                  style: const TextStyle(
                    color: Colors.white24,
                    fontSize: 8,
                    height: 1.35,
                  ),
                ),

                if (completed &&
                    milestone.completedAt !=
                        null) ...[
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    _formatDateTime(
                      milestone.completedAt!,
                    ),
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 7,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CONNECTOR
  // ============================================================

  Widget _buildConnector() {
    return Padding(
      padding: const EdgeInsets.only(
        left: 17,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: 1,
          height: 18,
          color: Colors.white.withValues(
            alpha: 0.07,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmpty() {
    return const Padding(
      padding: EdgeInsets.symmetric(
        vertical: 14,
      ),
      child: Column(
        children: [
          Icon(
            Icons.flag_outlined,
            color: Colors.white24,
            size: 25,
          ),

          SizedBox(
            height: 8,
          ),

          Text(
            'Nenhum marco registrado',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 11,
            ),
          ),

          SizedBox(
            height: 4,
          ),

          Text(
            'Os marcos aparecerão conforme a colaboração avançar.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white24,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String _formatDateTime(
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

    final hour = local.hour.toString().padLeft(
      2,
      '0',
    );

    final minute = local.minute.toString().padLeft(
      2,
      '0',
    );

    return '$day/$month/${local.year} • $hour:$minute';
  }
}
