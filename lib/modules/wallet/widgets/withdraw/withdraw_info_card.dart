import 'package:flutter/material.dart';

// ============================================================
// WITHDRAW INFO CARD
// ============================================================
//
// Aviso apresentado dentro do fluxo de saque.
//
// Widget reutilizável para explicar etapas, regras ou
// informações importantes.
//
// ============================================================

class WithdrawInfoCard
    extends
        StatelessWidget {
  // ============================================================
  // TEXTO
  // ============================================================

  final String message;

  // ============================================================
  // ÍCONE
  // ============================================================

  final IconData icon;

  // ============================================================
  // COR
  // ============================================================

  final Color accentColor;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  const WithdrawInfoCard({
    super.key,
    this.message = 'Antes da retirada ser concluída, você poderá revisar o valor e os dados de recebimento.',
    this.icon = Icons.info_outline_rounded,
    this.accentColor = const Color(
      0xFF9D6CFF,
    ),
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
        14,
      ),

      decoration: BoxDecoration(
        color: accentColor.withValues(
          alpha: 0.06,
        ),

        borderRadius: BorderRadius.circular(
          13,
        ),

        border: Border.all(
          color: accentColor.withValues(
            alpha: 0.13,
          ),
        ),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Icon(
            icon,

            color: accentColor,

            size: 18,
          ),

          const SizedBox(
            width: 10,
          ),

          Expanded(
            child: Text(
              message,

              style: const TextStyle(
                color: Colors.white54,

                fontSize: 11,

                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
