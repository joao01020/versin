import 'package:flutter/material.dart';

import '../models/project_record_event_model.dart';

// ============================================================
// PROJECT RECORD WIDGET
// ============================================================
//
// Representação visual do Versin Record.
//
// Mostra acontecimentos importantes da colaboração.
//
// NÃO exibe toda a complexidade técnica.
//
// O usuário vê:
//
// - o que aconteceu;
// - quando;
// - se existe registro de integridade.
//
// Caso queira:
//
// [VER REGISTRO TÉCNICO]
//
// ============================================================

class ProjectRecordWidget
    extends
        StatelessWidget {
  final List<
    ProjectRecordEventModel
  >
  events;

  final bool isIntegrityValid;

  final VoidCallback? onOpenTechnicalRecord;

  const ProjectRecordWidget({
    super.key,
    required this.events,
    this.isIntegrityValid = true,
    this.onOpenTechnicalRecord,
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
          // HEADER
          // ====================================================
          _buildHeader(),

          Divider(
            height: 1,
            color: Colors.white.withValues(
              alpha: 0.05,
            ),
          ),

          // ====================================================
          // EVENTS
          // ====================================================
          Padding(
            padding: const EdgeInsets.all(
              16,
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
                        _buildEvent(
                          events[index],
                        ),

                        if (index <
                            events.length -
                                1)
                          _buildConnector(),
                      ],
                    ],
                  ),
          ),

          // ====================================================
          // TECHNICAL RECORD
          // ====================================================
          if (onOpenTechnicalRecord !=
              null) ...[
            Divider(
              height: 1,
              color: Colors.white.withValues(
                alpha: 0.05,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(
                12,
              ),
              child: SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: onOpenTechnicalRecord,
                  icon: const Icon(
                    Icons.code_rounded,
                    size: 15,
                  ),
                  label: const Text(
                    'VER REGISTRO TÉCNICO',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(
        16,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color:
                  const Color(
                    0xFFE100FF,
                  ).withValues(
                    alpha: 0.08,
                  ),
              borderRadius: BorderRadius.circular(
                11,
              ),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: Color(
                0xFFE100FF,
              ),
              size: 18,
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
                  'Versin Record',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                SizedBox(
                  height: 2,
                ),

                Text(
                  'Ações relevantes são preservadas automaticamente.',
                  style: TextStyle(
                    color: Colors.white30,
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          ),

          _buildIntegrityBadge(),
        ],
      ),
    );
  }

  // ============================================================
  // INTEGRITY BADGE
  // ============================================================

  Widget _buildIntegrityBadge() {
    final color = isIntegrityValid
        ? Colors.greenAccent
        : Colors.redAccent;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.08,
        ),
        borderRadius: BorderRadius.circular(
          20,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.circle,
            color: color,
            size: 5,
          ),

          const SizedBox(
            width: 5,
          ),

          Text(
            isIntegrityValid
                ? 'INTEGRIDADE OK'
                : 'VERIFICAR',
            style: TextStyle(
              color: color,
              fontSize: 6,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EVENT
  // ============================================================

  Widget _buildEvent(
    ProjectRecordEventModel event,
  ) {
    final icon = _eventIcon(
      event.eventType,
    );

    final verified = event.hasIntegrityRecord;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ======================================================
        // ICON
        // ======================================================
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: verified
                ? Colors.green.withValues(
                    alpha: 0.08,
                  )
                : const Color(
                    0xFFE100FF,
                  ).withValues(
                    alpha: 0.08,
                  ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: verified
                ? Colors.greenAccent
                : const Color(
                    0xFFE100FF,
                  ),
            size: 15,
          ),
        ),

        const SizedBox(
          width: 11,
        ),

        // ======================================================
        // CONTENT
        // ======================================================
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _eventTitle(
                        event,
                      ),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  if (verified)
                    const Icon(
                      Icons.verified_rounded,
                      color: Colors.greenAccent,
                      size: 13,
                    ),
                ],
              ),

              const SizedBox(
                height: 3,
              ),

              Text(
                _eventSubtitle(
                  event,
                ),
                style: const TextStyle(
                  color: Colors.white30,
                  fontSize: 8,
                  height: 1.35,
                ),
              ),

              const SizedBox(
                height: 3,
              ),

              Text(
                _formatDateTime(
                  event.createdAt,
                ),
                style: const TextStyle(
                  color: Colors.white24,
                  fontSize: 7,
                ),
              ),

              if (event.hasEventHash) ...[
                const SizedBox(
                  height: 4,
                ),

                Text(
                  'HASH ${event.shortEventHash}',
                  style: const TextStyle(
                    color: Colors.white24,
                    fontSize: 7,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ],
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
        left: 15,
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
            'Nenhum evento registrado',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 11,
            ),
          ),

          SizedBox(
            height: 4,
          ),

          Text(
            'O histórico será criado conforme o projeto avançar.',
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
  // EVENT TITLE
  // ============================================================

  String _eventTitle(
    ProjectRecordEventModel event,
  ) {
    switch (event.eventType) {
      case ProjectRecordEventType.contributionCreated:
        return 'Contribuição criada';

      case ProjectRecordEventType.contributionUpdated:
        return 'Contribuição atualizada';

      case ProjectRecordEventType.contributionProposed:
        return 'Contribuição proposta';

      case ProjectRecordEventType.contributionApproved:
        return 'Contribuição aprovada';

      case ProjectRecordEventType.contributionLocked:
        return 'Contribuição confirmada';

      case ProjectRecordEventType.contributionStarted:
        return 'Produção iniciada';

      case ProjectRecordEventType.deliverySubmitted:
        return 'Nova entrega enviada';

      case ProjectRecordEventType.deliveryApproved:
        return 'Entrega aprovada';

      case ProjectRecordEventType.deliveryRejected:
        return 'Alteração solicitada';

      case ProjectRecordEventType.deliveryValidated:
        return 'Entrega validada';

      case ProjectRecordEventType.deadlineProposed:
        return 'Prazo proposto';

      case ProjectRecordEventType.deadlineApproved:
        return 'Compromisso confirmado';

      case ProjectRecordEventType.memberJoined:
        return 'Participante entrou no projeto';

      case ProjectRecordEventType.memberLeft:
        return 'Participante saiu do projeto';

      case ProjectRecordEventType.projectFinalized:
        return 'Projeto finalizado';
    }
  }

  // ============================================================
  // EVENT SUBTITLE
  // ============================================================

  String _eventSubtitle(
    ProjectRecordEventModel event,
  ) {
    final payload = event.payload;

    final title = payload['title']?.toString().trim();

    final fileName = payload['file_name']?.toString().trim();

    final version = payload['version']?.toString().trim();

    final displayName = payload['display_name']?.toString().trim();

    if (fileName !=
            null &&
        fileName.isNotEmpty) {
      if (version !=
              null &&
          version.isNotEmpty) {
        return '$fileName • versão $version';
      }

      return fileName;
    }

    if (title !=
            null &&
        title.isNotEmpty) {
      return title;
    }

    if (displayName !=
            null &&
        displayName.isNotEmpty) {
      return displayName;
    }

    return event.eventDatabaseValue;
  }

  // ============================================================
  // EVENT ICON
  // ============================================================

  IconData _eventIcon(
    ProjectRecordEventType type,
  ) {
    switch (type) {
      case ProjectRecordEventType.contributionCreated:
        return Icons.add_task_outlined;

      case ProjectRecordEventType.contributionUpdated:
        return Icons.edit_outlined;

      case ProjectRecordEventType.contributionProposed:
        return Icons.assignment_outlined;

      case ProjectRecordEventType.contributionApproved:
        return Icons.how_to_reg_outlined;

      case ProjectRecordEventType.contributionLocked:
        return Icons.lock_outline;

      case ProjectRecordEventType.contributionStarted:
        return Icons.play_arrow_rounded;

      case ProjectRecordEventType.deliverySubmitted:
        return Icons.upload_file_outlined;

      case ProjectRecordEventType.deliveryApproved:
        return Icons.thumb_up_alt_outlined;

      case ProjectRecordEventType.deliveryRejected:
        return Icons.rate_review_outlined;

      case ProjectRecordEventType.deliveryValidated:
        return Icons.verified_outlined;

      case ProjectRecordEventType.deadlineProposed:
        return Icons.event_outlined;

      case ProjectRecordEventType.deadlineApproved:
        return Icons.event_available_outlined;

      case ProjectRecordEventType.memberJoined:
        return Icons.person_add_alt_1_outlined;

      case ProjectRecordEventType.memberLeft:
        return Icons.person_remove_outlined;

      case ProjectRecordEventType.projectFinalized:
        return Icons.flag_circle_outlined;
    }
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
