import 'package:flutter/material.dart';

// ============================================================
// WITHDRAW BALANCE CARD
// ============================================================
//
// Card responsável por apresentar o saldo disponível para
// saque.
//
// Não possui lógica de negócio.
//
// ============================================================

class WithdrawBalanceCard
    extends
        StatelessWidget {
  // ============================================================
  // SALDO
  // ============================================================

  final double availableBalance;

  // ============================================================
  // CORES
  // ============================================================

  final Color primaryColor;

  final Color secondaryColor;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  const WithdrawBalanceCard({
    super.key,
    required this.availableBalance,
    this.primaryColor = const Color(
      0xFF00E676,
    ),
    this.secondaryColor = const Color(
      0xFF9D6CFF,
    ),
  });

  // ============================================================
  // FORMATAR DINHEIRO
  // ============================================================

  String _formatMoney(
    double value,
  ) {
    final parts = value
        .toStringAsFixed(
          2,
        )
        .split(
          '.',
        );

    var integerPart = parts[0];

    final decimalPart = parts[1];

    final buffer = StringBuffer();

    for (
      var index = 0;
      index <
          integerPart.length;
      index++
    ) {
      final positionFromEnd =
          integerPart.length -
          index;

      buffer.write(
        integerPart[index],
      );

      if (positionFromEnd >
              1 &&
          (positionFromEnd -
                      1) %
                  3 ==
              0) {
        buffer.write(
          '.',
        );
      }
    }

    integerPart = buffer.toString();

    return 'R\$ $integerPart,$decimalPart';
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
        18,
      ),

      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,

          end: Alignment.bottomRight,

          colors: [
            primaryColor.withValues(
              alpha: 0.11,
            ),

            secondaryColor.withValues(
              alpha: 0.06,
            ),
          ],
        ),

        borderRadius: BorderRadius.circular(
          16,
        ),

        border: Border.all(
          color: primaryColor.withValues(
            alpha: 0.15,
          ),
        ),
      ),

      child: Row(
        children: [
          // ====================================================
          // ÍCONE
          // ====================================================
          Container(
            width: 44,

            height: 44,

            decoration: BoxDecoration(
              color: primaryColor.withValues(
                alpha: 0.08,
              ),

              borderRadius: BorderRadius.circular(
                12,
              ),
            ),

            child: Icon(
              Icons.savings_outlined,

              color: primaryColor,

              size: 22,
            ),
          ),

          const SizedBox(
            width: 14,
          ),

          // ====================================================
          // SALDO
          // ====================================================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                const Text(
                  'SALDO DISPONÍVEL',

                  style: TextStyle(
                    color: Colors.white38,

                    fontSize: 9,

                    fontWeight: FontWeight.w700,

                    letterSpacing: 0.8,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  _formatMoney(
                    availableBalance,
                  ),

                  maxLines: 1,

                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    color: Colors.white,

                    fontSize: 22,

                    fontWeight: FontWeight.w800,
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
