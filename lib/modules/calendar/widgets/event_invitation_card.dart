import 'package:flutter/material.dart';

import '../models/calendar_event.dart';
import '../models/calendar_event_member.dart';

// ============================================================
// EVENT INVITATION CARD
// ============================================================
//
// Exibe uma solicitação de compromisso recebida.
//
// ============================================================

class EventInvitationCard
    extends
        StatelessWidget {
  final CalendarEvent event;

  final CalendarEventMember invitation;

  final Color accentColor;

  final bool isLoading;

  final Future<
    void
  >
  Function()
  onAccept;

  final Future<
    void
  >
  Function()
  onDecline;

  const EventInvitationCard({
    super.key,
    required this.event,
    required this.invitation,
    required this.accentColor,
    required this.onAccept,
    required this.onDecline,
    this.isLoading = false,
  });

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
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(
        14,
      ),

      margin: const EdgeInsets.only(
        bottom: 10,
      ),

      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.04,
        ),

        borderRadius: BorderRadius.circular(
          14,
        ),

        border: Border.all(
          color: accentColor.withValues(
            alpha: 0.18,
          ),
        ),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Icon(
                Icons.event_available_outlined,

                color: accentColor,

                size: 18,
              ),

              const SizedBox(
                width: 8,
              ),

              const Expanded(
                child: Text(
                  'Solicitação de compromisso',

                  style: TextStyle(
                    color: Colors.white,

                    fontSize: 12,

                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 12,
          ),

          Text(
            event.title,

            style: const TextStyle(
              color: Colors.white70,

              fontSize: 13,

              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(
            height: 4,
          ),

          Text(
            _formatDateTime(
              event.startsAt,
            ),

            style: const TextStyle(
              color: Colors.white38,

              fontSize: 11,
            ),
          ),

          if (event.hasLocation) ...[
            const SizedBox(
              height: 5,
            ),

            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,

                  color: Colors.white30,

                  size: 13,
                ),

                const SizedBox(
                  width: 4,
                ),

                Expanded(
                  child: Text(
                    event.locationName!,

                    style: const TextStyle(
                      color: Colors.white30,

                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(
            height: 14,
          ),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          onDecline();
                        },

                  child: const Text(
                    'RECUSAR',
                  ),
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              Expanded(
                child: FilledButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          onAccept();
                        },

                  style: FilledButton.styleFrom(
                    backgroundColor: accentColor,

                    foregroundColor: Colors.black,
                  ),

                  child: isLoading
                      ? const SizedBox(
                          width: 14,

                          height: 14,

                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'ACEITAR',
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
