import 'package:flutter/material.dart';

import '../../../ai/models/ai_quota_warning_state.dart';
import '../../../ai/services/quota/ai_quota_warning_service.dart';

// ============================================================
// AI QUOTA EXHAUSTED CARD
// ============================================================
//
// Exibido quando:
//
// state.isBlocked == true
//
// Ou seja:
//
// os créditos de IA fornecidos pelo Versin para o ciclo atual
// foram utilizados.
//
// IMPORTANTE:
//
// Este card não deve transmitir:
//
// - punição;
// - erro;
// - medo;
// - necessidade obrigatória de pagamento.
//
// O objetivo é mostrar imediatamente uma solução:
//
// 1. recursos locais continuam funcionando;
// 2. os créditos Versin serão renovados;
// 3. o usuário pode conectar uma API própria;
// 4. podem existir opções gratuitas / cotas sem custo;
// 5. também existem alternativas premium.
//
// ============================================================

class AiQuotaExhaustedCard
    extends
        StatelessWidget {
  // ============================================================
  // ESTADO
  // ============================================================

  final AiQuotaWarningState state;

  // ============================================================
  // CALLBACK
  // ============================================================
  //
  // Abre posteriormente:
  //
  // PrivateApiOnboardingPage
  //
  // ============================================================

  final VoidCallback? onConfigurePrivateApi;

  // ============================================================
  // SERVICE
  // ============================================================

  final AiQuotaWarningService _warningService = AiQuotaWarningService();

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  AiQuotaExhaustedCard({
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
    // SOMENTE BLOCKED
    // ==========================================================

    if (!_warningService.shouldShowExhaustedCard(
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

    final renewal = _warningService.buildRenewalText(
      state,
    );

    final actionLabel = _warningService.buildActionLabel(
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
                  Icons.auto_awesome_rounded,
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
                      height: 5,
                    ),

                    Text(
                      'Você pode continuar usando o Versin.',
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
            height: 18,
          ),

          // ====================================================
          // EXPLICAÇÃO
          // ====================================================
          Text(
            'Os créditos de IA fornecidos pelo Versin '
            'para este ciclo foram utilizados.',
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.45,
              color: colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          Text(
            'Sua biblioteca, rimas e recursos locais '
            'continuam disponíveis normalmente.',
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.45,
              color: colorScheme.onSurfaceVariant,
            ),
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
                vertical: 11,
              ),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(
                  12,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.refresh_rounded,
                    size: 19,
                    color: colorScheme.primary,
                  ),

                  const SizedBox(
                    width: 9,
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

          const SizedBox(
            height: 20,
          ),

          // ====================================================
          // CONTINUAR AGORA
          // ====================================================
          Text(
            'Quer continuar com IA agora?',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(
            height: 7,
          ),

          Text(
            'Você pode conectar sua própria API ao Versin. '
            'Nós vamos mostrar o processo passo a passo.',
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.45,
              color: colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(
            height: 18,
          ),

          // ====================================================
          // OPÇÃO SEM CUSTO
          // ====================================================
          _buildOption(
            context: context,
            icon: Icons.volunteer_activism_outlined,
            title: 'Quero continuar sem custo',
            description:
                'Alguns provedores podem oferecer '
                'acesso gratuito ou cotas sem custo. '
                'O Versin pode te orientar na configuração.',
            emphasized: true,
          ),

          const SizedBox(
            height: 12,
          ),

          // ====================================================
          // OPÇÃO PREMIUM
          // ====================================================
          _buildOption(
            context: context,
            icon: Icons.workspace_premium_outlined,
            title: 'Também existem opções premium',
            description:
                'Se você precisar de mais capacidade, '
                'pode escolher um provedor ou plano pago.',
            emphasized: false,
          ),

          // ====================================================
          // INFORMAÇÃO DE SEGURANÇA / CONTROLE
          // ====================================================
          const SizedBox(
            height: 16,
          ),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.key_outlined,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),

              const SizedBox(
                width: 8,
              ),

              Expanded(
                child: Text(
                  'Você escolhe o provedor e a API que '
                  'deseja conectar.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    height: 1.35,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),

          // ====================================================
          // BOTÃO
          // ====================================================
          if (actionLabel !=
                  null &&
              onConfigurePrivateApi !=
                  null) ...[
            const SizedBox(
              height: 18,
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

  Widget _buildOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required bool emphasized,
  }) {
    final theme = Theme.of(
      context,
    );

    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        13,
      ),
      decoration: BoxDecoration(
        color: emphasized
            ? colorScheme.primaryContainer.withValues(
                alpha: 0.32,
              )
            : colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(
          13,
        ),
        border: Border.all(
          color: emphasized
              ? colorScheme.primary.withValues(
                  alpha: 0.25,
                )
              : colorScheme.outlineVariant.withValues(
                  alpha: 0.55,
                ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(
                alpha: 0.65,
              ),
              borderRadius: BorderRadius.circular(
                10,
              ),
            ),
            child: Icon(
              icon,
              size: 20,
              color: emphasized
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
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
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(
                  height: 4,
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
    );
  }
}
