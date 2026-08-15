import 'package:flutter/material.dart';

// ============================================================
// WALLET BOTTOM SHEET
// ============================================================
//
// Estrutura visual reutilizável para painéis que sobem de
// baixo para cima.
//
// Pode ser utilizada por:
//
// - saque;
// - extrato;
// - filtros;
// - detalhes de transação;
// - futuros recursos da carteira.
//
// ============================================================

class WalletBottomSheet
    extends
        StatelessWidget {
  // ============================================================
  // CONFIGURAÇÃO
  // ============================================================

  final String title;

  final String subtitle;

  final IconData icon;

  final Color accentColor;

  final Widget child;

  final double heightFactor;

  final bool showCloseButton;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  const WalletBottomSheet({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.child,
    this.heightFactor = 0.82,
    this.showCloseButton = true,
  });

  // ============================================================
  // CORES
  // ============================================================

  static const Color _backgroundColor = Color(
    0xFF151126,
  );

  static const Color _purple = Color(
    0xFF9D6CFF,
  );

  // ============================================================
  // ABRIR
  // ============================================================

  static Future<
    T?
  >
  show<
    T
  >({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required Widget child,
    double heightFactor = 0.82,
    bool showCloseButton = true,
    bool isDismissible = true,
  }) {
    return showModalBottomSheet<
      T
    >(
      context: context,

      isScrollControlled: true,

      useSafeArea: true,

      isDismissible: isDismissible,

      enableDrag: true,

      backgroundColor: Colors.transparent,

      barrierColor: Colors.black.withValues(
        alpha: 0.68,
      ),

      builder:
          (
            context,
          ) {
            return FractionallySizedBox(
              heightFactor: heightFactor.clamp(
                0.30,
                0.96,
              ),

              child: WalletBottomSheet(
                title: title,

                subtitle: subtitle,

                icon: icon,

                accentColor: accentColor,

                heightFactor: heightFactor,

                showCloseButton: showCloseButton,

                child: child,
              ),
            );
          },
    );
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

      clipBehavior: Clip.antiAlias,

      decoration: BoxDecoration(
        color: _backgroundColor,

        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(
            28,
          ),
        ),

        border: Border(
          top: BorderSide(
            color: accentColor.withValues(
              alpha: 0.18,
            ),
          ),
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.45,
            ),

            blurRadius: 36,

            offset: const Offset(
              0,
              -8,
            ),
          ),

          BoxShadow(
            color: _purple.withValues(
              alpha: 0.04,
            ),

            blurRadius: 30,
          ),
        ],
      ),

      child: Column(
        children: [
          // ======================================================
          // HANDLE
          // ======================================================
          Padding(
            padding: const EdgeInsets.only(
              top: 10,

              bottom: 4,
            ),

            child: Container(
              width: 44,

              height: 4,

              decoration: BoxDecoration(
                color: Colors.white.withValues(
                  alpha: 0.18,
                ),

                borderRadius: BorderRadius.circular(
                  999,
                ),
              ),
            ),
          ),

          // ======================================================
          // HEADER
          // ======================================================
          Padding(
            padding: const EdgeInsets.fromLTRB(
              22,
              10,
              14,
              17,
            ),

            child: Row(
              children: [
                // ==================================================
                // ÍCONE
                // ==================================================
                Container(
                  width: 42,

                  height: 42,

                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,

                      end: Alignment.bottomRight,

                      colors: [
                        accentColor.withValues(
                          alpha: 0.15,
                        ),

                        _purple.withValues(
                          alpha: 0.07,
                        ),
                      ],
                    ),

                    borderRadius: BorderRadius.circular(
                      12,
                    ),

                    border: Border.all(
                      color: accentColor.withValues(
                        alpha: 0.18,
                      ),
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

                // ==================================================
                // TEXTO
                // ==================================================
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Text(
                        title,

                        maxLines: 1,

                        overflow: TextOverflow.ellipsis,

                        style: const TextStyle(
                          color: Colors.white,

                          fontSize: 16,

                          fontWeight: FontWeight.w800,

                          letterSpacing: 0.7,
                        ),
                      ),

                      const SizedBox(
                        height: 2,
                      ),

                      Text(
                        subtitle,

                        maxLines: 2,

                        overflow: TextOverflow.ellipsis,

                        style: const TextStyle(
                          color: Colors.white38,

                          fontSize: 10,

                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),

                // ==================================================
                // FECHAR
                // ==================================================
                if (showCloseButton)
                  IconButton(
                    tooltip: 'Fechar',

                    onPressed: () {
                      Navigator.of(
                        context,
                      ).maybePop();
                    },

                    icon: const Icon(
                      Icons.close_rounded,

                      color: Colors.white54,
                    ),
                  ),
              ],
            ),
          ),

          // ======================================================
          // DIVISOR
          // ======================================================
          Container(
            width: double.infinity,

            height: 1,

            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accentColor.withValues(
                    alpha: 0.20,
                  ),

                  _purple.withValues(
                    alpha: 0.10,
                  ),

                  Colors.transparent,
                ],
              ),
            ),
          ),

          // ======================================================
          // CONTEÚDO
          // ======================================================
          Expanded(
            child: child,
          ),
        ],
      ),
    );
  }
}
