import 'package:flutter/material.dart';

// ============================================================
// EMPTY STATEMENT WIDGET
// ============================================================
//
// Estado vazio do extrato.
//
// Apresentado quando o usuário ainda não possui movimentações.
//
// ============================================================

class EmptyStatementWidget
    extends
        StatelessWidget {
  // ============================================================
  // CORES
  // ============================================================

  final Color primaryColor;

  final Color secondaryColor;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  const EmptyStatementWidget({
    super.key,
    this.primaryColor = const Color(
      0xFF9D6CFF,
    ),
    this.secondaryColor = const Color(
      0xFF00E676,
    ),
  });

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),

        padding: const EdgeInsets.all(
          30,
        ),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            // ==================================================
            // ÍCONE
            // ==================================================
            Container(
              width: 70,

              height: 70,

              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,

                  end: Alignment.bottomRight,

                  colors: [
                    primaryColor.withValues(
                      alpha: 0.09,
                    ),

                    secondaryColor.withValues(
                      alpha: 0.03,
                    ),
                  ],
                ),

                shape: BoxShape.circle,

                border: Border.all(
                  color: primaryColor.withValues(
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

            // ==================================================
            // TÍTULO
            // ==================================================
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

            // ==================================================
            // DESCRIÇÃO
            // ==================================================
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 340,
              ),

              child: const Text(
                'Quando houver entradas, royalties ou saques, eles aparecerão aqui.',

                textAlign: TextAlign.center,

                style: TextStyle(
                  color: Colors.white38,

                  fontSize: 11,

                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
