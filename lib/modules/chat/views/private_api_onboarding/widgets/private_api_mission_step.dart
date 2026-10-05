import 'package:flutter/material.dart';

// ============================================================
// PRIVATE API MISSION STEP
// ============================================================
//
// Componente visual reutilizável para representar uma etapa da
// missão de configuração da API privada.
//
// Pode ser utilizado para:
//
// - passo atual;
// - passo concluído;
// - passo futuro.
//
// Este widget não possui regra de negócio.
//
// ============================================================

class PrivateApiMissionStep
    extends
        StatelessWidget {
  // ============================================================
  // ÍNDICE
  // ============================================================

  final int stepNumber;

  // ============================================================
  // TOTAL
  // ============================================================

  final int totalSteps;

  // ============================================================
  // CONTEÚDO
  // ============================================================

  final String title;

  final String description;

  // ============================================================
  // ESTADOS
  // ============================================================

  final bool isActive;

  final bool isCompleted;

  // ============================================================
  // ÍCONE
  // ============================================================

  final IconData? icon;

  // ============================================================
  // CALLBACK
  // ============================================================

  final VoidCallback? onTap;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  const PrivateApiMissionStep({
    super.key,
    required this.stepNumber,
    required this.totalSteps,
    required this.title,
    required this.description,
    this.isActive = false,
    this.isCompleted = false,
    this.icon,
    this.onTap,
  });

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = Theme.of(
      context,
    );

    final colorScheme = theme.colorScheme;

    final foregroundColor =
        isCompleted ||
            isActive
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(
        16,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(
          14,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? colorScheme.primaryContainer.withValues(
                  alpha: 0.22,
                )
              : colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.35,
                ),
          borderRadius: BorderRadius.circular(
            16,
          ),
          border: Border.all(
            color: isActive
                ? colorScheme.primary.withValues(
                    alpha: 0.35,
                  )
                : colorScheme.outlineVariant.withValues(
                    alpha: 0.55,
                  ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================================================
            // INDICADOR
            // ==================================================
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isCompleted
                    ? colorScheme.primary
                    : colorScheme.surface,
                borderRadius: BorderRadius.circular(
                  12,
                ),
                border: Border.all(
                  color: foregroundColor.withValues(
                    alpha: 0.45,
                  ),
                ),
              ),
              child: isCompleted
                  ? Icon(
                      Icons.check_rounded,
                      size: 21,
                      color: colorScheme.onPrimary,
                    )
                  : icon !=
                        null
                  ? Icon(
                      icon,
                      size: 20,
                      color: foregroundColor,
                    )
                  : Text(
                      '$stepNumber',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: foregroundColor,
                      ),
                    ),
            ),

            const SizedBox(
              width: 12,
            ),

            // ==================================================
            // CONTEÚDO
            // ==================================================
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),

                      const SizedBox(
                        width: 8,
                      ),

                      Text(
                        '$stepNumber/$totalSteps',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 5,
                  ),

                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      height: 1.4,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
