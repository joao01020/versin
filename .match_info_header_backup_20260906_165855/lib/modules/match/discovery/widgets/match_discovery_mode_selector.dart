import 'dart:async';

import 'package:flutter/material.dart';

import 'package:versin/modules/match/models/match_discovery_mode.dart';

// ============================================================
// MATCH DISCOVERY MODE SELECTOR
// ============================================================
//
// UI de seleção:
//
// - Compatíveis;
// - Próximos;
// - Agora.
//
// O widget NÃO decide:
//
// - consentimento de localização;
// - disponibilidade;
// - presença online.
//
// Ele apenas informa ao nível superior qual modo foi solicitado.
//
// ============================================================

class MatchDiscoveryModeSelector
    extends
        StatelessWidget {
  // ============================================================
  // STATE
  // ============================================================

  final MatchDiscoveryMode activeMode;
  final bool disabled;

  // ============================================================
  // STYLE
  // ============================================================

  final Color accentColor;

  // ============================================================
  // CALLBACK
  // ============================================================

  final Future<
    void
  >
  Function(
    MatchDiscoveryMode mode,
  )
  onModeSelected;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  const MatchDiscoveryModeSelector({
    super.key,
    required this.activeMode,
    required this.disabled,
    required this.accentColor,
    required this.onModeSelected,
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
        12,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.035,
        ),
        borderRadius: BorderRadius.circular(
          16,
        ),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.06,
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
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Formas de conectar',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(
                      height: 2,
                    ),
                    Text(
                      'Escolha como o Versin deve priorizar as conexões.',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                width: 8,
              ),
              _InfoButton(
                accentColor: accentColor,
                onTap: () {
                  _showModesInfoSheet(
                    context,
                  );
                },
              ),
            ],
          ),

          const SizedBox(
            height: 12,
          ),

          // ====================================================
          // MODES
          // ====================================================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(
              4,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(
                alpha: 0.10,
              ),
              borderRadius: BorderRadius.circular(
                14,
              ),
              border: Border.all(
                color: Colors.white.withValues(
                  alpha: 0.04,
                ),
              ),
            ),
            child: Row(
              children: [
                // ==============================================
                // COMPATÍVEIS
                // ==============================================
                Expanded(
                  child: _ModeButton(
                    mode: MatchDiscoveryMode.compatible,
                    icon: Icons.auto_awesome_rounded,
                    label: 'COMPATÍVEIS',
                    selected:
                        activeMode ==
                        MatchDiscoveryMode.compatible,
                    disabled: disabled,
                    accentColor: accentColor,
                    onPressed: onModeSelected,
                  ),
                ),

                const SizedBox(
                  width: 6,
                ),

                // ==============================================
                // PRÓXIMOS
                // ==============================================
                Expanded(
                  child: _ModeButton(
                    mode: MatchDiscoveryMode.nearby,
                    icon: Icons.near_me_rounded,
                    label: 'PRÓXIMOS',
                    selected:
                        activeMode ==
                        MatchDiscoveryMode.nearby,
                    disabled: disabled,
                    accentColor: accentColor,
                    onPressed: onModeSelected,
                  ),
                ),

                const SizedBox(
                  width: 6,
                ),

                // ==============================================
                // AGORA
                // ==============================================
                Expanded(
                  child: _ModeButton(
                    mode: MatchDiscoveryMode.global,
                    icon: Icons.bolt_rounded,
                    label: 'AGORA',
                    selected:
                        activeMode ==
                        MatchDiscoveryMode.global,
                    disabled: disabled,
                    accentColor: accentColor,
                    onPressed: onModeSelected,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INFO SHEET
  // ============================================================

  void _showModesInfoSheet(
    BuildContext context,
  ) {
    showModalBottomSheet<
      void
    >(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (
            _,
          ) {
            return _DiscoveryModesInfoSheet(
              accentColor: accentColor,
            );
          },
    );
  }
}

// ============================================================
// INFO BUTTON
// ============================================================

class _InfoButton
    extends
        StatelessWidget {
  final Color accentColor;
  final VoidCallback onTap;

  const _InfoButton({
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          100,
        ),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: accentColor.withValues(
              alpha: 0.08,
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: accentColor.withValues(
                alpha: 0.20,
              ),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            'i',
            style: TextStyle(
              color: accentColor,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// DISCOVERY MODES INFO SHEET
// ============================================================

class _DiscoveryModesInfoSheet
    extends
        StatelessWidget {
  final Color accentColor;

  const _DiscoveryModesInfoSheet({
    required this.accentColor,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        12,
        0,
        12,
        12,
      ),
      padding: const EdgeInsets.all(
        18,
      ),
      decoration: BoxDecoration(
        color: const Color(
          0xFF12101F,
        ),
        borderRadius: BorderRadius.circular(
          22,
        ),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.06,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: 0.12,
                  ),
                  borderRadius: BorderRadius.circular(
                    100,
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(
                      alpha: 0.10,
                    ),
                    borderRadius: BorderRadius.circular(
                      12,
                    ),
                    border: Border.all(
                      color: accentColor.withValues(
                        alpha: 0.20,
                      ),
                    ),
                  ),
                  child: Icon(
                    Icons.info_outline_rounded,
                    color: accentColor,
                    size: 20,
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
                        'Como funcionam as conexões',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(
                        height: 3,
                      ),
                      Text(
                        'Entenda como cada modo prioriza os perfis.',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
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

            _ModeInfoTile(
              accentColor: accentColor,
              icon: Icons.auto_awesome_rounded,
              title: 'Compatíveis',
              description:
                  'Mostra primeiro os profissionais com maior compatibilidade '
                  'com o seu perfil, com base nas áreas em que você atua e no '
                  'tipo de pessoa que você procura.',
            ),

            const SizedBox(
              height: 10,
            ),

            _ModeInfoTile(
              accentColor: accentColor,
              icon: Icons.near_me_rounded,
              title: 'Próximos',
              description:
                  'Prioriza pessoas perto de você. Esse modo pode solicitar '
                  'permissão de localização para encontrar conexões próximas.',
            ),

            const SizedBox(
              height: 10,
            ),

            _ModeInfoTile(
              accentColor: accentColor,
              icon: Icons.bolt_rounded,
              title: 'Agora',
              description:
                  'Prioriza profissionais online ou disponíveis neste momento, '
                  'ideal para conexões rápidas e imediatas.',
            ),

            const SizedBox(
              height: 16,
            ),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(
                12,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(
                  alpha: 0.03,
                ),
                borderRadius: BorderRadius.circular(
                  14,
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
                  Icon(
                    Icons.tips_and_updates_outlined,
                    color: accentColor,
                    size: 16,
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  const Expanded(
                    child: Text(
                      'Dica: você pode trocar o modo a qualquer momento para '
                      'mudar a prioridade das conexões exibidas.',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 10.5,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(
                    context,
                  ).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      14,
                    ),
                  ),
                ),
                child: const Text(
                  'Entendi',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// MODE INFO TILE
// ============================================================

class _ModeInfoTile
    extends
        StatelessWidget {
  final Color accentColor;
  final IconData icon;
  final String title;
  final String description;

  const _ModeInfoTile({
    required this.accentColor,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        13,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.025,
        ),
        borderRadius: BorderRadius.circular(
          16,
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
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accentColor.withValues(
                alpha: 0.08,
              ),
              borderRadius: BorderRadius.circular(
                11,
              ),
            ),
            child: Icon(
              icon,
              color: accentColor,
              size: 18,
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(
                  height: 4,
                ),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 10.5,
                    height: 1.45,
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

// ============================================================
// MODE BUTTON
// ============================================================

class _ModeButton
    extends
        StatelessWidget {
  final MatchDiscoveryMode mode;
  final IconData icon;
  final String label;
  final bool selected;
  final bool disabled;
  final Color accentColor;

  final Future<
    void
  >
  Function(
    MatchDiscoveryMode mode,
  )
  onPressed;

  const _ModeButton({
    required this.mode,
    required this.icon,
    required this.label,
    required this.selected,
    required this.disabled,
    required this.accentColor,
    required this.onPressed,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: disabled
            ? null
            : () {
                unawaited(
                  onPressed(
                    mode,
                  ),
                );
              },
        borderRadius: BorderRadius.circular(
          10,
        ),
        child: AnimatedContainer(
          duration: const Duration(
            milliseconds: 180,
          ),
          curve: Curves.easeOut,
          height: 42,
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
          ),
          decoration: BoxDecoration(
            color: selected
                ? accentColor.withValues(
                    alpha: 0.16,
                  )
                : Colors.transparent,
            borderRadius: BorderRadius.circular(
              10,
            ),
            border: Border.all(
              color: selected
                  ? accentColor.withValues(
                      alpha: 0.36,
                    )
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (disabled &&
                  selected)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.7,
                    color: accentColor,
                  ),
                )
              else
                Icon(
                  icon,
                  size: 16,
                  color: selected
                      ? accentColor
                      : Colors.white38,
                ),
              const SizedBox(
                width: 7,
              ),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected
                        ? accentColor
                        : Colors.white38,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.55,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
