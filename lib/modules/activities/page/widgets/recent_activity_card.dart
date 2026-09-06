import 'package:flutter/material.dart';

import 'package:versin/modules/activities/models/recent_activity_model.dart';
import 'package:versin/modules/activities/models/recent_activity_type.dart';

class RecentActivityCard extends StatelessWidget {
  final RecentActivityModel activity;
  final Future<void> Function() onDelete;

  const RecentActivityCard({
    super.key,
    required this.activity,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final visual = _visualForType(activity.type);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: visual.color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: visual.color.withValues(alpha: 0.18)),
            ),
            child: Icon(visual.icon, color: visual.color, size: 19),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activity.description,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      color: Colors.white24,
                      size: 11,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDateTime(activity.createdAt),
                      style: const TextStyle(
                        color: Colors.white24,
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            tooltip: 'Opções',
            color: const Color(0xFF211C38),
            icon: const Icon(
              Icons.more_vert_rounded,
              color: Colors.white30,
              size: 18,
            ),
            onSelected: (value) async {
              if (value == 'delete') {
                await onDelete();
              }
            },
            itemBuilder: (context) {
              return const [
                PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.redAccent,
                        size: 17,
                      ),
                      SizedBox(width: 9),
                      Text(
                        'Excluir atividade',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
    );
  }

  static _RecentActivityVisual _visualForType(RecentActivityType type) {
    switch (type) {
      case RecentActivityType.welcome:
        return const _RecentActivityVisual(
          icon: Icons.waving_hand_rounded,
          color: Colors.amberAccent,
        );

      case RecentActivityType.profileUpdated:
        return const _RecentActivityVisual(
          icon: Icons.music_note_rounded,
          color: Colors.purpleAccent,
        );

      case RecentActivityType.connection:
        return const _RecentActivityVisual(
          icon: Icons.handshake_outlined,
          color: Colors.cyanAccent,
        );

      case RecentActivityType.favorite:
        return const _RecentActivityVisual(
          icon: Icons.star_rounded,
          color: Colors.yellowAccent,
        );

      case RecentActivityType.fileAdded:
        return const _RecentActivityVisual(
          icon: Icons.folder_rounded,
          color: Colors.lightBlueAccent,
        );
    }
  }

  static String _formatDateTime(DateTime date) {
    final localDate = date.toLocal();
    final now = DateTime.now();

    final difference = now.difference(localDate);

    if (!difference.isNegative && difference.inSeconds < 60) {
      return 'Agora';
    }

    if (!difference.isNegative && difference.inMinutes < 60) {
      return '${difference.inMinutes} min atrás';
    }

    if (!difference.isNegative && difference.inHours < 24) {
      return '${difference.inHours}h atrás';
    }

    if (!difference.isNegative && difference.inDays == 1) {
      return 'Ontem';
    }

    final day = localDate.day.toString().padLeft(2, '0');

    final month = localDate.month.toString().padLeft(2, '0');

    final hour = localDate.hour.toString().padLeft(2, '0');

    final minute = localDate.minute.toString().padLeft(2, '0');

    return '$day/$month às $hour:$minute';
  }
}

class _RecentActivityVisual {
  final IconData icon;
  final Color color;

  const _RecentActivityVisual({required this.icon, required this.color});
}
