import 'package:flutter/material.dart';

import 'package:versin/modules/match/views/projects/match_projects_view.dart';

import '../controllers/dashboard_controller.dart';

// ============================================================
// ACTIVE PROJECT CARD WIDGET
// ============================================================
//
// Card responsável por indicar quando existe uma sessão
// ativa originada pelo Match.
//
// Responsabilidades:
//
// - verificar se existe projeto ativo;
// - exibir indicador visual;
// - exibir status da sessão;
// - permitir abrir os projetos do Match.
//
// A existência do projeto continua sendo controlada pelo:
//
// DashboardController
//
// A navegação abre:
//
// MatchProjectsView
//
// ============================================================

class ActiveProjectCardWidget
    extends
        StatelessWidget {
  final DashboardController controller;

  const ActiveProjectCardWidget({
    super.key,
    required this.controller,
  });

  // ============================================================
  // ABRIR PROJETOS DO MATCH
  // ============================================================

  void _openMatchProjects(
    BuildContext context,
  ) {
    Navigator.of(
      context,
    ).push(
      MaterialPageRoute<
        void
      >(
        builder:
            (
              _,
            ) {
              return const MatchProjectsView();
            },
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    // ==========================================================
    // SEM PROJETO ATIVO
    // ==========================================================

    if (!controller.hasActiveProject) {
      return const SizedBox.shrink();
    }

    // ==========================================================
    // CARD
    // ==========================================================

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _openMatchProjects(
            context,
          );
        },
        borderRadius: BorderRadius.circular(
          16,
        ),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(
            16,
          ),
          decoration: BoxDecoration(
            color: Colors.green.withValues(
              alpha: 0.10,
            ),
            borderRadius: BorderRadius.circular(
              16,
            ),
            border: Border.all(
              color: Colors.green.withValues(
                alpha: 0.30,
              ),
            ),
          ),
          child: Row(
            children: [
              // ==================================================
              // INDICADOR
              // ==================================================
              Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              // ==================================================
              // CONTEÚDO
              // ==================================================
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Conexão sincronizada com o projeto',
                      style: TextStyle(
                        color: Colors.green.shade300,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(
                      height: 2,
                    ),

                    const Text(
                      'Existe um projeto em andamento.',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 9,
                      ),
                    ),

                    const SizedBox(
                      height: 7,
                    ),

                    // ============================================
                    // ABRIR PROJETOS
                    // ============================================
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Ver projetos',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        SizedBox(
                          width: 3,
                        ),

                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white54,
                          size: 12,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              // ==================================================
              // STATUS
              // ==================================================
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius: BorderRadius.circular(
                    20,
                  ),
                  border: Border.all(
                    color: Colors.green.withValues(
                      alpha: 0.20,
                    ),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.circle,
                      color: Colors.green,
                      size: 6,
                    ),

                    SizedBox(
                      width: 5,
                    ),

                    Text(
                      'ATIVO',
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                width: 6,
              ),

              // ==================================================
              // SETA
              // ==================================================
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white38,
                size: 19,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
