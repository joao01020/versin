import 'package:flutter/material.dart';

import '../models/recent_activity_model.dart';
import '../models/recent_activity_type.dart';

// ============================================================
// RECENT ACTIVITY ITEM WIDGET
// ============================================================
//
// Representa uma única atividade na lista.
//
// Exemplo:
//
// 👋 Bem-vindo ao Versin
//    Seu espaço criativo está pronto.
//    Agora
//
// ============================================================

class RecentActivityItemWidget
    extends
        StatelessWidget {
  final RecentActivityModel activity;

  final Color accentColor;

  const RecentActivityItemWidget({
    super.key,
    required this.activity,
    this.accentColor = const Color(
      0xFFE100FF,
    ),
  });

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final typeColor = _colorForType(
      activity.type,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 9,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ====================================================
          // ÍCONE
          // ====================================================
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: typeColor.withValues(
                alpha: 0.10,
              ),
              borderRadius: BorderRadius.circular(
                11,
              ),
              border: Border.all(
                color: typeColor.withValues(
                  alpha: 0.16,
                ),
              ),
            ),
            child: Center(
              child: Text(
                _emojiForType(
                  activity.type,
                ),
                style: const TextStyle(
                  fontSize: 17,
                ),
              ),
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          // ====================================================
          // CONTEÚDO
          // ====================================================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==================================================
                // TÍTULO
                // ==================================================
                Text(
                  activity.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                // ==================================================
                // DESCRIÇÃO
                // ==================================================
                Text(
                  activity.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    height: 1.35,
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),

                // ==================================================
                // DATA RELATIVA
                // ==================================================
                Text(
                  _formatRelativeTime(
                    activity.createdAt,
                  ),
                  style: TextStyle(
                    color: typeColor.withValues(
                      alpha: 0.72,
                    ),
                    fontSize: 8,
                    fontWeight: FontWeight.w500,
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
  // EMOJI POR TIPO
  // ============================================================

  String _emojiForType(
    RecentActivityType type,
  ) {
    switch (type) {
      case RecentActivityType.welcome:
        return '👋';

      case RecentActivityType.profileUpdated:
        return '🎵';

      case RecentActivityType.connection:
        return '🤝';

      case RecentActivityType.favorite:
        return '⭐';

      case RecentActivityType.fileAdded:
        return '📁';
    }
  }

  // ============================================================
  // COR POR TIPO
  // ============================================================

  Color _colorForType(
    RecentActivityType type,
  ) {
    switch (type) {
      case RecentActivityType.welcome:
        return accentColor;

      case RecentActivityType.profileUpdated:
        return Colors.cyanAccent;

      case RecentActivityType.connection:
        return Colors.greenAccent;

      case RecentActivityType.favorite:
        return Colors.amberAccent;

      case RecentActivityType.fileAdded:
        return Colors.lightBlueAccent;
    }
  }

  // ============================================================
  // DATA RELATIVA
  // ============================================================

  String _formatRelativeTime(
    DateTime date,
  ) {
    final now = DateTime.now();

    final localDate = date.toLocal();

    final difference = now.difference(
      localDate,
    );

    if (difference.isNegative) {
      return 'Agora';
    }

    if (difference.inSeconds <
        60) {
      return 'Agora';
    }

    if (difference.inMinutes <
        60) {
      final minutes = difference.inMinutes;

      if (minutes ==
          1) {
        return '1 min atrás';
      }

      return '$minutes min atrás';
    }

    if (difference.inHours <
        24) {
      final hours = difference.inHours;

      if (hours ==
          1) {
        return '1h atrás';
      }

      return '${hours}h atrás';
    }

    if (difference.inDays ==
        1) {
      return 'Ontem';
    }

    if (difference.inDays <
        7) {
      return '${difference.inDays} dias atrás';
    }

    final day = localDate.day.toString().padLeft(
      2,
      '0',
    );

    final month = localDate.month.toString().padLeft(
      2,
      '0',
    );

    return '$day/$month';
  }
}
