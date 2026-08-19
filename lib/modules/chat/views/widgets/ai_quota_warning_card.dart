import 'package:flutter/material.dart';

import '../../models/ai_quota_warning_state.dart';
import '../../services/ai_quota_warning_service.dart';

// ============================================================
// AI QUOTA WARNING CARD
// ============================================================
//
// Este card NÃO comunica medo de escassez.
//
// Ele aparece somente no estado:
//
// critical
//
// Objetivo:
//
// mostrar ao usuário que existe uma forma de deixar a IA
// disponível continuamente através de API própria.
//
// Também explica que:
//
// - podem existir opções gratuitas;
// - podem existir cotas sem custo;
// - existem opções premium;
//
// sem afirmar que todo provedor é gratuito.
//
// ============================================================

class AiQuotaWarningCard
    extends
        StatelessWidget {
  // ============================================================
  // ESTADO
  // ============================================================

  final AiQuotaWarningState state;

  // ============================================================
  // CALLBACK
  // ============================================================

  final VoidCallback? onConfigurePrivateApi;

  // ============================================================
  // SERVICE
  // ============================================================

  final AiQuotaWarningService _warningService = AiQuotaWarningService();

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  AiQuotaWarningCard({
    super.key,
    required this.state,
    this.onConfigurePrivateApi,
  });

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    // ==========================================================
    // SOMENTE CRITICAL
    // ==========================================================
    //
    // warning de 80% não aparece mais.
    //
    // ==========================================================

    if (!_warningService.shouldShowLowQuotaWarning(
      state,
    )) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(
      context,
    );

    final colorScheme = theme.colorScheme;

    final title = _warningService.buildTitle(
      state,
    );

    final message = _warningService.buildMessage(
      state,
    );

    final renewal = _warningService.buildRenewalText(
      state,
    );

    final actionLabel = _warningService.buildActionLabel(
      state,
    );

    final remaining = _warningService.buildRemainingText(
      state,
    );

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
      ),
      padding: const EdgeInsets.all(
        18,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.60,
        ),
        borderRadius: BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(
            alpha: 0.80,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ====================================================
          // HEADER
          // ====================================================
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(
                    12,
                  ),
                ),
                child: Icon(
                  Icons.all_inclusive_rounded,
                  size: 23,
                  color: colorScheme.primary,
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    Text(
                      remaining,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 16,
          ),

          // ====================================================
          // MENSAGEM
          // ====================================================
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.45,
              color: colorScheme.onSurfaceVariant,
            ),
          ),

          // ====================================================
          // OPÇÕES
          // ====================================================
          const SizedBox(
            height: 16,
          ),

          _buildOptionRow(
            context: context,
            icon: Icons.volunteer_activism_outlined,
            title: 'Opções sem custo',
            description:
                'Alguns provedores podem oferecer '
                'cotas gratuitas ou acesso sem custo.',
          ),

          const SizedBox(
            height: 12,
          ),

          _buildOptionRow(
            context: context,
            icon: Icons.workspace_premium_outlined,
            title: 'Opções premium',
            description:
                'Se quiser mais capacidade, também '
                'existem planos e provedores pagos.',
          ),

          // ====================================================
          // RENOVAÇÃO
          // ====================================================
          if (renewal.isNotEmpty) ...[
            const SizedBox(
              height: 16,
            ),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(
                  12,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.refresh_rounded,
                    size: 18,
                    color: colorScheme.primary,
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  Expanded(
                    child: Text(
                      renewal,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ====================================================
          // AÇÃO
          // ====================================================
          if (actionLabel !=
                  null &&
              onConfigurePrivateApi !=
                  null) ...[
            const SizedBox(
              height: 16,
            ),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onConfigurePrivateApi,
                icon: const Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                ),
                label: Text(
                  actionLabel,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // OPÇÃO
  // ============================================================

  Widget _buildOptionRow({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(
      context,
    );

    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            top: 2,
          ),
          child: Icon(
            icon,
            size: 19,
            color: colorScheme.primary,
          ),
        ),

        const SizedBox(
          width: 10,
        ),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(
                height: 2,
              ),

              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  height: 1.35,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
