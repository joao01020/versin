import 'package:flutter/material.dart';

// ============================================================
// STORAGE SUMMARY CARD
// ============================================================
//
// Pequeno card utilizado para mostrar estatísticas do Storage.
//
// Exemplos:
//
// - total;
// - letras;
// - beats;
// - obras íntegras.
//
// ============================================================

class StorageSummaryCard
    extends
        StatelessWidget {
  final String title;

  final String value;

  final IconData icon;

  final Color accentColor;

  const StorageSummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.all(
        16,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.045,
        ),
        borderRadius: BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.07,
          ),
        ),
      ),
      child: Row(
        children: [
          // ===================================================
          // ÍCONE
          // ===================================================
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accentColor.withValues(
                alpha: 0.10,
              ),
              borderRadius: BorderRadius.circular(
                12,
              ),
            ),
            child: Icon(
              icon,
              color: accentColor,
              size: 20,
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          // ===================================================
          // INFORMAÇÕES
          // ===================================================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(
                      alpha: 0.35,
                    ),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
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
