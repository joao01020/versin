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
        4,
      ),

      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.035,
        ),

        borderRadius: BorderRadius.circular(
          14,
        ),

        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.06,
          ),
        ),
      ),

      child: Row(
        children: [
          // ====================================================
          // COMPATIBLE
          // ====================================================
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

          // ====================================================
          // NEARBY
          // ====================================================
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

          // ====================================================
          // AVAILABLE NOW
          // ====================================================
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
              // ================================================
              // ICON / LOADING
              // ================================================
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

              // ================================================
              // LABEL
              // ================================================
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
