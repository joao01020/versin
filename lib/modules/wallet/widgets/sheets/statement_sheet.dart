import 'package:flutter/material.dart';

import '../../controllers/wallet_controller.dart';
import '../../models/transaction_entity.dart';
import '../transaction_tile_widget.dart';
import 'wallet_bottom_sheet.dart';

// ============================================================
// STATEMENT SHEET
// ============================================================
//
// Exibe o extrato da carteira em um painel inferior.
//
// Por enquanto utiliza:
//
// WalletController.transactions
//
// Futuramente pode receber:
//
// - paginação;
// - filtros;
// - intervalo de datas;
// - entradas;
// - saídas;
// - royalties;
// - saques.
//
// ============================================================

class StatementSheet
    extends
        StatelessWidget {
  // ============================================================
  // CONTROLLER
  // ============================================================

  final WalletController controller;

  // ============================================================
  // CORES
  // ============================================================

  static const Color purple = Color(
    0xFF9D6CFF,
  );

  static const Color green = Color(
    0xFF00E676,
  );

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  const StatementSheet({
    super.key,
    required this.controller,
  });

  // ============================================================
  // ABRIR
  // ============================================================

  static Future<
    void
  >
  show({
    required BuildContext context,
    required WalletController controller,
  }) {
    return WalletBottomSheet.show<
      void
    >(
      context: context,

      title: 'EXTRATO',

      subtitle: 'Histórico das suas movimentações financeiras',

      icon: Icons.receipt_long_outlined,

      accentColor: purple,

      heightFactor: 0.88,

      child: StatementSheet(
        controller: controller,
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
    return ListenableBuilder(
      listenable: controller,

      builder:
          (
            context,
            _,
          ) {
            final transactions = controller.transactions;

            return Column(
              children: [
                // ====================================================
                // RESUMO
                // ====================================================
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    22,
                    18,
                    22,
                    12,
                  ),

                  child: _buildSummaryCard(
                    transactions.length,
                  ),
                ),

                // ====================================================
                // LABEL
                // ====================================================
                if (transactions.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(
                      22,
                      8,
                      22,
                      10,
                    ),

                    child: Align(
                      alignment: Alignment.centerLeft,

                      child: Text(
                        'MOVIMENTAÇÕES',

                        style: TextStyle(
                          color: Colors.white38,

                          fontSize: 9,

                          fontWeight: FontWeight.w700,

                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),

                // ====================================================
                // CONTEÚDO
                // ====================================================
                Expanded(
                  child: transactions.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          physics: const BouncingScrollPhysics(),

                          padding: const EdgeInsets.fromLTRB(
                            22,
                            4,
                            22,
                            30,
                          ),

                          itemCount: transactions.length,

                          separatorBuilder:
                              (
                                context,
                                index,
                              ) {
                                return const SizedBox(
                                  height: 8,
                                );
                              },

                          itemBuilder:
                              (
                                context,
                                index,
                              ) {
                                final TransactionEntity transaction = transactions[index];

                                return TransactionTileWidget(
                                  controller: controller,

                                  transaction: transaction,
                                );
                              },
                        ),
                ),
              ],
            );
          },
    );
  }

  // ============================================================
  // RESUMO
  // ============================================================

  Widget _buildSummaryCard(
    int transactionCount,
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
            purple.withValues(
              alpha: 0.10,
            ),

            green.withValues(
              alpha: 0.035,
            ),
          ],
        ),

        borderRadius: BorderRadius.circular(
          15,
        ),

        border: Border.all(
          color: purple.withValues(
            alpha: 0.14,
          ),
        ),
      ),

      child: Row(
        children: [
          // ======================================================
          // ÍCONE
          // ======================================================
          Container(
            width: 42,

            height: 42,

            decoration: BoxDecoration(
              color: purple.withValues(
                alpha: 0.08,
              ),

              borderRadius: BorderRadius.circular(
                12,
              ),
            ),

            child: const Icon(
              Icons.history_rounded,

              color: purple,

              size: 21,
            ),
          ),

          const SizedBox(
            width: 13,
          ),

          // ======================================================
          // TOTAL
          // ======================================================
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
                  '$transactionCount movimentação${transactionCount == 1 ? '' : 'ões'}',

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

  // ============================================================
  // VAZIO
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(
          30,
        ),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            Container(
              width: 70,

              height: 70,

              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,

                  end: Alignment.bottomRight,

                  colors: [
                    purple.withValues(
                      alpha: 0.09,
                    ),

                    green.withValues(
                      alpha: 0.03,
                    ),
                  ],
                ),

                shape: BoxShape.circle,

                border: Border.all(
                  color: purple.withValues(
                    alpha: 0.10,
                  ),
                ),
              ),

              child: const Icon(
                Icons.receipt_long_outlined,

                color: Colors.white24,

                size: 31,
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            const Text(
              'Nenhuma movimentação',

              textAlign: TextAlign.center,

              style: TextStyle(
                color: Colors.white,

                fontSize: 14,

                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(
              height: 6,
            ),

            const Text(
              'Quando houver entradas, royalties ou saques, eles aparecerão aqui.',

              textAlign: TextAlign.center,

              style: TextStyle(
                color: Colors.white38,

                fontSize: 11,

                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
