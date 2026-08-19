import 'package:flutter/material.dart';

import '../models/royalty_event_model.dart';
import '../models/royalty_member_model.dart';

// ============================================================
// ROYALTY TIMELINE WIDGET
// ============================================================
//
// Histórico real de royalties.
//
// Exibe:
//
// - proposta;
// - aprovação;
// - confirmação;
// - substituição.
//
// Os eventos vêm de royalty_events.
//
// ============================================================

class RoyaltyTimelineWidget
    extends
        StatelessWidget {
  final List<
    RoyaltyEventModel
  >
  events;

  final RoyaltyMemberModel? Function(
    String userId,
  )?
  resolveMember;

  const RoyaltyTimelineWidget({
    super.key,
    required this.events,
    this.resolveMember,
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
      child: events.isEmpty
          ? _buildEmpty()
          : Column(
              children: [
                for (
                  var index = 0;
                  index <
                      events.length;
                  index++
                ) ...[
                  _RoyaltyTimelineItem(
                    icon: _iconForEvent(
                      events[index],
                    ),
                    title: _titleForEvent(
                      events[index],
                    ),
                    subtitle: _subtitleForEvent(
                      events[index],
                    ),
                    time: _formatDateTime(
                      events[index].createdAt,
                    ),
                  ),

                  if (index <
                      events.length -
                          1)
                    const _RoyaltyTimelineDivider(),
                ],
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
      child: Column(
        children: [
          Icon(
            Icons.history_rounded,
            color: Colors.white24,
            size: 27,
          ),

          SizedBox(
            height: 8,
          ),

          Text(
            'Nenhuma atividade registrada',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 11,
            ),
          ),

          SizedBox(
            height: 4,
          ),

          Text(
            'As propostas e confirmações aparecerão aqui.',
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
  // TITLE
  // ============================================================

  String _titleForEvent(
    RoyaltyEventModel event,
  ) {
    final actor = _actorName(
      event,
    );

    switch (event.type) {
      case RoyaltyEventType.agreementProposed:
        return 'Nova divisão de royalties proposta';

      case RoyaltyEventType.agreementApproved:
        return actor ==
                null
            ? 'Participante confirmou a divisão'
            : '$actor confirmou a divisão';

      case RoyaltyEventType.agreementConfirmed:
        return 'Acordo de royalties confirmado';

      case RoyaltyEventType.agreementSuperseded:
        return 'Acordo substituído por nova versão';

      case RoyaltyEventType.unknown:
        return 'Evento de royalties';
    }
  }

  // ============================================================
  // SUBTITLE
  // ============================================================

  String _subtitleForEvent(
    RoyaltyEventModel event,
  ) {
    final version = event.agreementVersion;

    switch (event.type) {
      case RoyaltyEventType.agreementProposed:
        if (version !=
            null) {
          return 'Acordo versão $version';
        }

        return 'Nova proposta registrada';

      case RoyaltyEventType.agreementApproved:
        if (version !=
            null) {
          return 'Confirmação da versão $version';
        }

        return 'Confirmação registrada';

      case RoyaltyEventType.agreementConfirmed:
        final hash =
            event.payloadHash ??
            event.eventHash;

        if (hash?.trim().isNotEmpty ==
            true) {
          return 'Registro de integridade ${_shortHash(hash!)}';
        }

        return 'Todos os participantes confirmaram';

      case RoyaltyEventType.agreementSuperseded:
        return 'Uma nova proposta substituiu esta versão';

      case RoyaltyEventType.unknown:
        return event.rawEventType.isEmpty
            ? 'Evento registrado'
            : event.rawEventType;
    }
  }

  // ============================================================
  // ICON
  // ============================================================

  IconData _iconForEvent(
    RoyaltyEventModel event,
  ) {
    switch (event.type) {
      case RoyaltyEventType.agreementProposed:
        return Icons.percent_rounded;

      case RoyaltyEventType.agreementApproved:
        return Icons.how_to_reg_rounded;

      case RoyaltyEventType.agreementConfirmed:
        return Icons.verified_rounded;

      case RoyaltyEventType.agreementSuperseded:
        return Icons.history_rounded;

      case RoyaltyEventType.unknown:
        return Icons.circle_outlined;
    }
  }

  // ============================================================
  // ACTOR
  // ============================================================

  String? _actorName(
    RoyaltyEventModel event,
  ) {
    final actorId = event.actorUserId?.trim();

    if (actorId ==
            null ||
        actorId.isEmpty ||
        resolveMember ==
            null) {
      return null;
    }

    final member = resolveMember!(
      actorId,
    );

    return member?.displayName;
  }

  // ============================================================
  // DATE
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

  // ============================================================
  // SHORT HASH
  // ============================================================

  String _shortHash(
    String value,
  ) {
    final normalized = value.trim();

    if (normalized.length <=
        16) {
      return normalized;
    }

    return '${normalized.substring(0, 8)}'
        '...'
        '${normalized.substring(normalized.length - 8)}';
  }
}

// ============================================================
// TIMELINE ITEM
// ============================================================

class _RoyaltyTimelineItem
    extends
        StatelessWidget {
  final IconData icon;

  final String title;

  final String subtitle;

  final String time;

  const _RoyaltyTimelineItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 31,
          height: 31,
          decoration: BoxDecoration(
            color:
                const Color(
                  0xFFE100FF,
                ).withValues(
                  alpha: 0.08,
                ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: const Color(
              0xFFE100FF,
            ),
            size: 15,
          ),
        ),

        const SizedBox(
          width: 11,
        ),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
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
                ),
              ),

              const SizedBox(
                height: 3,
              ),

              Text(
                time,
                style: const TextStyle(
                  color: Colors.white24,
                  fontSize: 8,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// TIMELINE DIVIDER
// ============================================================

class _RoyaltyTimelineDivider
    extends
        StatelessWidget {
  const _RoyaltyTimelineDivider();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 15,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: 1,
          height: 17,
          color: Colors.white.withValues(
            alpha: 0.08,
          ),
        ),
      ),
    );
  }
}
