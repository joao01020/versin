import 'package:flutter/material.dart';

import 'package:versin/modules/match/controllers/match_controllers.dart';

import 'profile_tile_widget.dart';

// ============================================================
// RECOMMENDATIONS SECTION WIDGET
// ============================================================
//
// Responsável por mostrar:
//
// - loading;
// - lista de recomendados;
// - estado vazio.
//
// Este widget NÃO:
//
// - calcula recomendação;
// - acessa repository;
// - acessa Supabase;
// - inicia sessão Match.
//
// ============================================================

class RecommendationsSectionWidget
    extends
        StatelessWidget {
  // ============================================================
  // CONTROLLER
  // ============================================================

  final MatchController controller;

  // ============================================================
  // ESTADO
  // ============================================================

  final bool isInitializingMatch;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  const RecommendationsSectionWidget({
    super.key,
    required this.controller,
    required this.isInitializingMatch,
  });

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    // ==========================================================
    // LOADING
    // ==========================================================

    if (controller.isLoading ||
        isInitializingMatch) {
      return const Center(
        child: Text(
          'Procurando profissionais compatíveis...',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 12,
          ),
        ),
      );
    }

    // ==========================================================
    // RESULTADOS
    // ==========================================================

    if (controller.recommendedUsers.isNotEmpty) {
      return Column(
        children: controller.recommendedUsers.map(
          (
            user,
          ) {
            return ProfileTileWidget(
              user: user,
              controller: controller,
            );
          },
        ).toList(),
      );
    }

    // ==========================================================
    // VAZIO
    // ==========================================================

    return const Padding(
      padding: EdgeInsets.symmetric(
        vertical: 20,
      ),
      child: Center(
        child: Text(
          'Nenhuma recomendação disponível.',
          style: TextStyle(
            color: Colors.white24,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
