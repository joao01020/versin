import 'package:flutter/material.dart';

import '../models/calendar_event.dart';
import '../models/calendar_event_type.dart';

// ============================================================
// CALENDAR EVENT CARD
// ============================================================
//
// Card responsável por exibir um compromisso real do
// calendário.
//
// Exibe:
//
// - horário;
// - título;
// - tipo;
// - localização;
// - ações de editar/excluir.
//
// ============================================================

class CalendarEventCard
    extends
        StatelessWidget {
  // ============================================================
  // EVENTO
  // ============================================================

  final CalendarEvent event;

  // ============================================================
  // COR
  // ============================================================

  final Color accentColor;

  // ============================================================
  // CALLBACKS
  // ============================================================

  final VoidCallback? onTap;

  final VoidCallback? onEdit;

  final VoidCallback? onDelete;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  const CalendarEventCard({
    super.key,
    required this.event,
    required this.accentColor,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  // ============================================================
  // HORÁRIO
  // ============================================================

  String _formatTime(
    DateTime date,
  ) {
    final local = date.toLocal();

    final hour = local.hour.toString().padLeft(
      2,
      '0',
    );

    final minute = local.minute.toString().padLeft(
      2,
      '0',
    );

    return '$hour:$minute';
  }

  // ============================================================
  // LABEL DO HORÁRIO
  // ============================================================

  String get _timeLabel {
    final start = _formatTime(
      event.startsAt,
    );

    final end = event.endsAt;

    if (end ==
        null) {
      return start;
    }

    return '$start - ${_formatTime(end)}';
  }

  // ============================================================
  // POSSUI AÇÕES
  // ============================================================

  bool get _hasActions {
    return onEdit !=
            null ||
        onDelete !=
            null;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color: Colors.transparent,

      child: InkWell(
        onTap: onTap,

        borderRadius: BorderRadius.circular(
          12,
        ),

        child: Container(
          width: double.infinity,

          margin: const EdgeInsets.symmetric(
            vertical: 4,
          ),

          padding: const EdgeInsets.all(
            12,
          ),

          decoration: BoxDecoration(
            color: Colors.black.withValues(
              alpha: 0.24,
            ),

            borderRadius: BorderRadius.circular(
              12,
            ),

            border: Border.all(
              color: Colors.white.withValues(
                alpha: 0.05,
              ),
            ),
          ),

          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              // ==================================================
              // HORÁRIO
              // ==================================================
              SizedBox(
                width: 76,

                child: Text(
                  _timeLabel,

                  style: TextStyle(
                    color: accentColor,

                    fontSize: 11,

                    fontWeight: FontWeight.bold,

                    fontFamily: 'monospace',
                  ),
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              // ==================================================
              // CONTEÚDO
              // ==================================================
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    // ==============================================
                    // TÍTULO
                    // ==============================================
                    Text(
                      event.title,

                      maxLines: 2,

                      overflow: TextOverflow.ellipsis,

                      style: const TextStyle(
                        color: Colors.white,

                        fontSize: 12,

                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    // ==============================================
                    // TIPO
                    // ==============================================
                    Row(
                      children: [
                        Icon(
                          event.isPersonal
                              ? Icons.person_outline_rounded
                              : Icons.groups_2_outlined,

                          size: 13,

                          color: Colors.white38,
                        ),

                        const SizedBox(
                          width: 4,
                        ),

                        Flexible(
                          child: Text(
                            event.type.label,

                            maxLines: 1,

                            overflow: TextOverflow.ellipsis,

                            style: const TextStyle(
                              color: Colors.white38,

                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // ==============================================
                    // LOCALIZAÇÃO
                    // ==============================================
                    if (event.hasLocation) ...[
                      const SizedBox(
                        height: 5,
                      ),

                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,

                            size: 13,

                            color: Colors.white30,
                          ),

                          const SizedBox(
                            width: 4,
                          ),

                          Expanded(
                            child: Text(
                              event.locationName!,

                              maxLines: 1,

                              overflow: TextOverflow.ellipsis,

                              style: const TextStyle(
                                color: Colors.white30,

                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    // ==============================================
                    // DESCRIÇÃO
                    // ==============================================
                    if (event.hasDescription) ...[
                      const SizedBox(
                        height: 6,
                      ),

                      Text(
                        event.description!,

                        maxLines: 2,

                        overflow: TextOverflow.ellipsis,

                        style: const TextStyle(
                          color: Colors.white30,

                          fontSize: 10,

                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // ==================================================
              // AÇÕES
              // ==================================================
              if (_hasActions)
                PopupMenuButton<
                  String
                >(
                  tooltip: 'Opções',

                  color: const Color(
                    0xFF1A1630,
                  ),

                  icon: const Icon(
                    Icons.more_vert_rounded,

                    color: Colors.white38,

                    size: 18,
                  ),

                  onSelected:
                      (
                        value,
                      ) {
                        switch (value) {
                          case 'edit':
                            onEdit?.call();

                          case 'delete':
                            onDelete?.call();
                        }
                      },

                  itemBuilder:
                      (
                        context,
                      ) {
                        return [
                          // ==========================================
                          // EDITAR
                          // ==========================================
                          if (onEdit !=
                              null)
                            const PopupMenuItem<
                              String
                            >(
                              value: 'edit',

                              child: Row(
                                children: [
                                  Icon(
                                    Icons.edit_outlined,

                                    color: Colors.white54,

                                    size: 17,
                                  ),

                                  SizedBox(
                                    width: 9,
                                  ),

                                  Text(
                                    'Editar',

                                    style: TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // ==========================================
                          // EXCLUIR
                          // ==========================================
                          if (onDelete !=
                              null)
                            const PopupMenuItem<
                              String
                            >(
                              value: 'delete',

                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete_outline_rounded,

                                    color: Colors.redAccent,

                                    size: 17,
                                  ),

                                  SizedBox(
                                    width: 9,
                                  ),

                                  Text(
                                    'Excluir',

                                    style: TextStyle(
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ];
                      },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
