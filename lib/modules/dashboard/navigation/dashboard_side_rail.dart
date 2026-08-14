import 'package:flutter/material.dart';

import '../controllers/dashboard_controller.dart';
import '../models/dashboard_menu_item.dart';

// ============================================================
// DASHBOARD SIDE RAIL
// ============================================================
//
// Menu lateral do Dashboard para layout desktop.
//
// Responsabilidades:
//
// - exibir logo;
// - exibir itens visíveis;
// - destacar item selecionado;
// - disparar callback de navegação.
//
// Este widget NÃO:
//
// - controla PageView;
// - altera índice do controller;
// - conhece regras de visibilidade;
// - conhece configuração dos módulos.
//
// Ele recebe tudo pronto.
//
// ============================================================

class DashboardSideRail
    extends
        StatelessWidget {
  // ============================================================
  // DEPENDÊNCIAS
  // ============================================================

  final DashboardController controller;

  final List<
    DashboardMenuItem
  >
  items;

  final int currentVisibleIndex;

  final ValueChanged<
    int
  >
  onTap;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  const DashboardSideRail({
    super.key,
    required this.controller,
    required this.items,
    required this.currentVisibleIndex,
    required this.onTap,
  });

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: 92,
      decoration: BoxDecoration(
        color: Colors.black.withValues(
          alpha: 0.30,
        ),
        border: const Border(
          right: BorderSide(
            color: Colors.white10,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(
              height: 18,
            ),

            // ==================================================
            // LOGO
            // ==================================================
            _buildLogo(),

            const SizedBox(
              height: 24,
            ),

            // ==================================================
            // MENU
            // ==================================================
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  vertical: 4,
                ),
                itemCount: items.length,
                itemBuilder:
                    (
                      context,
                      index,
                    ) {
                      final item = items[index];

                      final selected =
                          index ==
                          currentVisibleIndex;

                      return _buildMenuItem(
                        item: item,
                        index: index,
                        selected: selected,
                      );
                    },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LOGO
  // ============================================================

  Widget _buildLogo() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: controller.accentNeon.withValues(
          alpha: 0.10,
        ),
        borderRadius: BorderRadius.circular(
          14,
        ),
        border: Border.all(
          color: controller.accentNeon.withValues(
            alpha: 0.25,
          ),
        ),
      ),
      child: Icon(
        Icons.graphic_eq_rounded,
        color: controller.accentNeon,
      ),
    );
  }

  // ============================================================
  // ITEM DO MENU
  // ============================================================

  Widget _buildMenuItem({
    required DashboardMenuItem item,
    required int index,
    required bool selected,
  }) {
    final foregroundColor = selected
        ? controller.accentNeon
        : Colors.white38;

    return Tooltip(
      message: item.label,
      child: InkWell(
        onTap: () {
          onTap(
            index,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(
            milliseconds: 180,
          ),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 4,
          ),
          padding: const EdgeInsets.symmetric(
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: selected
                ? controller.accentNeon.withValues(
                    alpha: 0.12,
                  )
                : Colors.transparent,
            borderRadius: BorderRadius.circular(
              12,
            ),
            border: Border.all(
              color: selected
                  ? controller.accentNeon.withValues(
                      alpha: 0.25,
                    )
                  : Colors.transparent,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ================================================
              // ÍCONE
              // ================================================
              Icon(
                item.icon,
                color: foregroundColor,
                size: 22,
              ),

              const SizedBox(
                height: 5,
              ),

              // ================================================
              // LABEL
              // ================================================
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 3,
                ),
                child: Text(
                  _railLabel(
                    item.label,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foregroundColor,
                    fontSize: 9,
                    fontWeight: selected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LABEL COMPACTA
  // ============================================================

  String _railLabel(
    String label,
  ) {
    switch (label) {
      case 'Dashboard':
        return 'Dash';

      case 'VNode Network':
      case 'VNode':
        return 'VNode';

      default:
        return label;
    }
  }
}
