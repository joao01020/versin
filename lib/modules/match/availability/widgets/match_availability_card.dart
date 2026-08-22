import 'package:flutter/material.dart';

import '../controllers/match_availability_controller.dart';

// ============================================================
// MATCH AVAILABILITY CARD
// ============================================================
//
// Card compacto utilizado dentro da MatchPage.
//
// Responsável somente por:
//
// - mostrar estado atual;
// - mostrar tempo restante;
// - apresentar loading;
// - solicitar ativação;
// - solicitar encerramento.
//
// NÃO:
//
// - acessa Supabase;
// - abre modal;
// - altera disponibilidade diretamente;
// - controla Timer.
//
// ============================================================

class MatchAvailabilityCard
    extends
        StatelessWidget {
  // ============================================================
  // CONTROLLER
  // ============================================================

  final MatchAvailabilityController controller;

  // ============================================================
  // COLOR
  // ============================================================

  final Color accentColor;

  // ============================================================
  // CALLBACKS
  // ============================================================

  final VoidCallback? onActivate;

  final VoidCallback? onClear;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  const MatchAvailabilityCard({
    super.key,
    required this.controller,
    required this.accentColor,
    this.onActivate,
    this.onClear,
  });

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return AnimatedBuilder(
      animation: controller,
      builder:
          (
            context,
            child,
          ) {
            final state = controller.state;

            final active = state.isActive;

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(
                14,
              ),
              decoration: BoxDecoration(
                color: accentColor.withValues(
                  alpha: 0.055,
                ),
                borderRadius: BorderRadius.circular(
                  16,
                ),
                border: Border.all(
                  color: accentColor.withValues(
                    alpha: 0.18,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // ==================================================
                  // ICON
                  // ==================================================
                  _buildIcon(),

                  const SizedBox(
                    width: 11,
                  ),

                  // ==================================================
                  // CONTENT
                  // ==================================================
                  Expanded(
                    child: _buildContent(
                      active: active,
                    ),
                  ),

                  const SizedBox(
                    width: 10,
                  ),

                  // ==================================================
                  // ACTION
                  // ==================================================
                  if (active) _buildClearButton() else _buildActivateButton(),
                ],
              ),
            );
          },
    );
  }

  // ============================================================
  // ICON
  // ============================================================

  Widget _buildIcon() {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: accentColor.withValues(
          alpha: 0.11,
        ),
        shape: BoxShape.circle,
      ),
      child: controller.isLoading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 1.8,
                color: accentColor,
              ),
            )
          : Icon(
              Icons.bolt_rounded,
              color: accentColor,
              size: 19,
            ),
    );
  }

  // ============================================================
  // CONTENT
  // ============================================================

  Widget _buildContent({
    required bool active,
  }) {
    final state = controller.state;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          active
              ? 'Você está disponível agora'
              : 'Ative sua disponibilidade',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(
          height: 3,
        ),

        Text(
          active
              ? '${state.remainingLabel}. '
                    'Você aparece para quem procura suas habilidades.'
              : 'Escolha 30 min, 1 hora ou 2 horas '
                    'para aparecer neste modo.',
          style: TextStyle(
            color: Colors.white.withValues(
              alpha: 0.48,
            ),
            fontSize: 9.5,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ACTIVATE BUTTON
  // ============================================================

  Widget _buildActivateButton() {
    return TextButton(
      onPressed: controller.isLoading
          ? null
          : onActivate,
      child: const Text(
        'ATIVAR',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ============================================================
  // CLEAR BUTTON
  // ============================================================

  Widget _buildClearButton() {
    return TextButton(
      onPressed: controller.isLoading
          ? null
          : onClear,
      child: const Text(
        'ENCERRAR',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
