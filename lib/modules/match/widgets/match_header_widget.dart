import 'package:flutter/material.dart';

// ============================================================
// MATCH HEADER WIDGET
// ============================================================
//
// Cabeçalho da página Conectar.
//
// Responsabilidades:
//
// - título;
// - subtítulo;
// - botão abrir/fechar pesquisa.
//
// Este widget NÃO:
//
// - controla TextEditingController;
// - executa pesquisa;
// - acessa repository;
// - conhece MatchController.
//
// ============================================================

class MatchHeaderWidget
    extends
        StatelessWidget {
  final bool isSearchPanelOpen;

  final Color accentColor;

  final VoidCallback onSearchToggle;

  const MatchHeaderWidget({
    super.key,
    required this.isSearchPanelOpen,
    required this.accentColor,
    required this.onSearchToggle,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ======================================================
        // TÍTULO
        // ======================================================
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Conectar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(
                height: 3,
              ),

              Text(
                'Encontre pessoas para criar com você',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(
          width: 12,
        ),

        // ======================================================
        // PESQUISAR
        // ======================================================
        Tooltip(
          message: isSearchPanelOpen
              ? 'Fechar pesquisa'
              : 'Pesquisar usuário',
          child: InkWell(
            onTap: onSearchToggle,
            borderRadius: BorderRadius.circular(
              14,
            ),
            child: AnimatedContainer(
              duration: const Duration(
                milliseconds: 160,
              ),
              height: 42,
              padding: const EdgeInsets.symmetric(
                horizontal: 13,
              ),
              decoration: BoxDecoration(
                color: isSearchPanelOpen
                    ? accentColor.withValues(
                        alpha: 0.10,
                      )
                    : Colors.white.withValues(
                        alpha: 0.035,
                      ),
                borderRadius: BorderRadius.circular(
                  14,
                ),
                border: Border.all(
                  color: isSearchPanelOpen
                      ? accentColor.withValues(
                          alpha: 0.30,
                        )
                      : Colors.white.withValues(
                          alpha: 0.07,
                        ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSearchPanelOpen
                        ? Icons.close_rounded
                        : Icons.search_rounded,
                    color: isSearchPanelOpen
                        ? accentColor
                        : Colors.white60,
                    size: 18,
                  ),

                  const SizedBox(
                    width: 7,
                  ),

                  Text(
                    isSearchPanelOpen
                        ? 'FECHAR'
                        : 'PESQUISAR',
                    style: TextStyle(
                      color: isSearchPanelOpen
                          ? accentColor
                          : Colors.white60,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.7,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
