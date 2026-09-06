import 'package:flutter/material.dart';

// ============================================================
// MATCH LOCKED INTERACTION
// ============================================================
//
// Wrapper visual de uma área do Match que depende do onboarding.
//
// Quando desbloqueado:
// - entrega interação normal.
//
// Quando bloqueado:
// - reduz opacidade;
// - bloqueia interação do conteúdo;
// - encaminha o clique para o guard de onboarding.
//
// Assim a MatchPageView não repete:
// GestureDetector -> IgnorePointer -> Opacity.
//
// ============================================================

class MatchLockedInteraction extends StatelessWidget {
  final bool unlocked;
  final VoidCallback onLockedTap;
  final Widget child;

  const MatchLockedInteraction({
    super.key,
    required this.unlocked,
    required this.onLockedTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: unlocked ? null : onLockedTap,
      child: IgnorePointer(
        ignoring: !unlocked,
        child: Opacity(opacity: unlocked ? 1 : 0.42, child: child),
      ),
    );
  }
}
