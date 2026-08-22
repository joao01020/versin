import 'package:flutter/material.dart';

import '../services/match_availability_service.dart';

// ============================================================
// MATCH AVAILABILITY DURATION SHEET
// ============================================================
//
// Bottom sheet responsável somente por permitir que o usuário
// escolha por quanto tempo ficará disponível.
//
// Retorna:
//
// - 30 minutos;
// - 60 minutos;
// - 120 minutos.
//
// NÃO:
//
// - acessa Supabase;
// - altera disponibilidade;
// - conhece controller;
// - mostra SnackBars.
//
// ============================================================

class MatchAvailabilityDurationSheet {
  // ============================================================
  // SHOW
  // ============================================================

  static Future<
    int?
  >
  show({
    required BuildContext context,
    required Color accentColor,
  }) {
    return showModalBottomSheet<
      int
    >(
      context: context,
      backgroundColor: const Color(
        0xFF17132D,
      ),
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(
            24,
          ),
        ),
      ),
      builder:
          (
            sheetContext,
          ) {
            return _MatchAvailabilityDurationSheetContent(
              accentColor: accentColor,
            );
          },
    );
  }
}

// ============================================================
// CONTENT
// ============================================================

class _MatchAvailabilityDurationSheetContent
    extends
        StatelessWidget {
  final Color accentColor;

  const _MatchAvailabilityDurationSheetContent({
    required this.accentColor,
  });

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ====================================================
          // HEADER
          // ====================================================
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accentColor.withValues(
                    alpha: 0.10,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.bolt_rounded,
                  color: accentColor,
                  size: 20,
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Disponíveis agora',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    SizedBox(
                      height: 3,
                    ),

                    Text(
                      'Escolha por quanto tempo você quer '
                      'aparecer para conexões rápidas.',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 18,
          ),

          // ====================================================
          // DESCRIPTION
          // ====================================================
          const Text(
            'Você será mostrado somente para pessoas '
            'que procuram suas habilidades.',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 11,
              height: 1.4,
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          // ====================================================
          // OPTIONS
          // ====================================================
          Row(
            children: [
              Expanded(
                child: _DurationButton(
                  accentColor: accentColor,
                  label: '30 MIN',
                  subtitle: 'rápido',
                  minutes: MatchAvailabilityService.thirtyMinutes,
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              Expanded(
                child: _DurationButton(
                  accentColor: accentColor,
                  label: '1 HORA',
                  subtitle: 'equilibrado',
                  minutes: MatchAvailabilityService.oneHour,
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              Expanded(
                child: _DurationButton(
                  accentColor: accentColor,
                  label: '2 HORAS',
                  subtitle: 'máximo',
                  minutes: MatchAvailabilityService.twoHours,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// DURATION BUTTON
// ============================================================

class _DurationButton
    extends
        StatelessWidget {
  final Color accentColor;

  final String label;

  final String subtitle;

  final int minutes;

  const _DurationButton({
    required this.accentColor,
    required this.label,
    required this.subtitle,
    required this.minutes,
  });

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
        borderRadius: BorderRadius.circular(
          14,
        ),
        onTap: () {
          Navigator.of(
            context,
          ).pop(
            minutes,
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 16,
          ),
          decoration: BoxDecoration(
            color: accentColor.withValues(
              alpha: 0.08,
            ),
            borderRadius: BorderRadius.circular(
              14,
            ),
            border: Border.all(
              color: accentColor.withValues(
                alpha: 0.24,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(
                height: 4,
              ),

              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
