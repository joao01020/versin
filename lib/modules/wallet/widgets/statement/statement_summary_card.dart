import 'package:flutter/material.dart';

// ============================================================
// STATEMENT SUMMARY CARD
// ============================================================
//
// Resumo exibido no início do extrato.
//
// Atualmente apresenta:
//
// - quantidade de movimentações.
//
// Futuramente pode apresentar:
//
// - total recebido;
// - total sacado;
// - royalties;
// - saldo do período.
//
// ============================================================

class StatementSummaryCard
    extends
        StatelessWidget {
  // ============================================================
  // DADOS
  // ============================================================

  final int transactionCount;

  // ============================================================
  // CORES
  // ============================================================

  final Color primaryColor;

  final Color secondaryColor;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  const StatementSummaryCard({
    super.key,
    required this.transactionCount,
    this.primaryColor = const Color(
      0xFF9D6CFF,
    ),
    this.secondaryColor = const Color(
      0xFF00E676,
    ),
  });

  // ============================================================
  // LABEL
  // ============================================================

  String get _transactionLabel {
    if (transactionCount ==
        1) {
      return '1 movimentação';
    }

    return '$transactionCount movimentações';
  }

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
        16,
      ),

      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,

          end: Alignment.bottomRight,

          colors: [
            primaryColor.withValues(
              alpha: 0.10,
            ),

            secondaryColor.withValues(
              alpha: 0.035,
            ),
          ],
        ),

        borderRadius: BorderRadius.circular(
          15,
        ),

        border: Border.all(
          color: primaryColor.withValues(
            alpha: 0.14,
          ),
        ),
      ),

      child: Row(
        children: [
          // ====================================================
          // ÍCONE
          // ====================================================
          Container(
            width: 42,

            height: 42,

            decoration: BoxDecoration(
              color: primaryColor.withValues(
                alpha: 0.08,
              ),

              borderRadius: BorderRadius.circular(
                12,
              ),
            ),

            child: Icon(
              Icons.history_rounded,

              color: primaryColor,

              size: 21,
            ),
          ),

          const SizedBox(
            width: 13,
          ),

          // ====================================================
          // CONTEÚDO
          // ====================================================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                const Text(
                  'TOTAL DE REGISTROS',

                  style: TextStyle(
                    color: Colors.white38,

                    fontSize: 9,

                    fontWeight: FontWeight.w700,

                    letterSpacing: 0.8,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  _transactionLabel,

                  style: const TextStyle(
                    color: Colors.white,

                    fontSize: 16,

                    fontWeight: FontWeight.w700,
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
