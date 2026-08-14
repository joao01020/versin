import 'package:flutter/material.dart';

import '../controllers/dashboard_controller.dart';

// ============================================================
// ACTIVE PROJECT CARD WIDGET
// ============================================================
//
// Card responsável por indicar quando existe uma sessão
// ativa no Studio.
//
// Responsabilidades:
//
// - verificar se existe projeto ativo;
// - exibir indicador visual;
// - exibir status da sessão;
// - manter o visual isolado do Dashboard.
//
// Este widget NÃO:
//
// - controla navegação;
// - inicia sessão;
// - encerra sessão;
// - altera estado do projeto;
// - conhece PageView.
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

  @override
  Widget build(
    BuildContext context,
  ) {
    if (!controller.hasActiveProject) {
      return const SizedBox.shrink();
    }

    return Container(
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
          // ====================================================
          // INDICADOR
          // ====================================================
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

          // ====================================================
          // CONTEÚDO
          // ====================================================
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
              ],
            ),
          ),

          // ====================================================
          // STATUS
          // ====================================================
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
        ],
      ),
    );
  }
}
