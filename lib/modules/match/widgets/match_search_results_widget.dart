import 'package:flutter/material.dart';

import 'package:versin/modules/match/controllers/match_controllers.dart';
import 'package:versin/modules/match/models/match_user_entity.dart';

import 'profile_tile_widget.dart';

// ============================================================
// MATCH SEARCH RESULTS WIDGET
// ============================================================
//
// Responsável por mostrar:
//
// - loading;
// - erro;
// - estado vazio;
// - quantidade de resultados;
// - lista de usuários.
//
// Este widget NÃO:
//
// - executa pesquisa;
// - acessa repository;
// - possui debounce;
// - acessa Supabase.
//
// ============================================================

class MatchSearchResultsWidget
    extends
        StatelessWidget {
  // ============================================================
  // CONTROLLER
  // ============================================================

  final MatchController controller;

  // ============================================================
  // ESTADO
  // ============================================================

  final bool isSearching;

  final String query;

  final String? errorMessage;

  final List<
    MatchUserEntity
  >
  results;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  const MatchSearchResultsWidget({
    super.key,
    required this.controller,
    required this.isSearching,
    required this.query,
    required this.errorMessage,
    required this.results,
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

    if (isSearching) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          vertical: 28,
        ),
        decoration: _decoration(),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.purpleAccent,
            ),
          ),
        ),
      );
    }

    // ==========================================================
    // ERRO
    // ==========================================================

    if (errorMessage !=
            null &&
        errorMessage!.trim().isNotEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(
          16,
        ),
        decoration: _decoration(),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent,
              size: 18,
            ),

            const SizedBox(
              width: 9,
            ),

            Expanded(
              child: Text(
                errorMessage!,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ==========================================================
    // VAZIO
    // ==========================================================

    if (results.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          vertical: 24,
          horizontal: 16,
        ),
        decoration: _decoration(),
        child: Column(
          children: [
            const Icon(
              Icons.person_search_outlined,
              color: Colors.white24,
              size: 26,
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              'Nenhum usuário encontrado para "$query".',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    }

    // ==========================================================
    // RESULTADOS
    // ==========================================================

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ======================================================
        // HEADER
        // ======================================================
        Row(
          children: [
            const Text(
              'Resultados',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(
              width: 8,
            ),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 7,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: controller.accentNeon.withValues(
                  alpha: 0.08,
                ),
                borderRadius: BorderRadius.circular(
                  20,
                ),
              ),
              child: Text(
                '${results.length}',
                style: TextStyle(
                  color: controller.accentNeon,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 12,
        ),

        // ======================================================
        // LISTA
        // ======================================================
        ...results.map(
          (
            user,
          ) {
            return ProfileTileWidget(
              user: user,
              controller: controller,
            );
          },
        ),
      ],
    );
  }

  // ============================================================
  // DECORAÇÃO
  // ============================================================

  BoxDecoration _decoration() {
    return BoxDecoration(
      color:
          const Color(
            0xFF17132D,
          ).withValues(
            alpha: 0.65,
          ),
      borderRadius: BorderRadius.circular(
        16,
      ),
      border: Border.all(
        color: Colors.white.withValues(
          alpha: 0.05,
        ),
      ),
    );
  }
}
