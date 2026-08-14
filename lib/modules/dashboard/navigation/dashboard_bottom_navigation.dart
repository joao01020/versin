import 'package:flutter/material.dart';

import '../controllers/dashboard_controller.dart';
import '../models/dashboard_menu_item.dart';
import 'dashboard_navigation.dart';

// ============================================================
// DASHBOARD BOTTOM NAVIGATION
// ============================================================
//
// Navegação inferior utilizada no layout mobile.
//
// Responsabilidades:
//
// - exibir itens visíveis;
// - destacar item atual;
// - chamar callback de navegação.
//
// Este widget NÃO:
//
// - controla PageView;
// - altera DashboardController diretamente;
// - decide quais módulos existem;
// - decide quais módulos são visíveis.
//
// Ele recebe tudo pronto.
//
// ============================================================

class DashboardBottomNavigation
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

  const DashboardBottomNavigation({
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
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final safeCurrentIndex =
        currentVisibleIndex >=
                0 &&
            currentVisibleIndex <
                items.length
        ? currentVisibleIndex
        : 0;

    return Container(
      decoration: BoxDecoration(
        color: const Color(
          0xFF0B0918,
        ),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(
              alpha: 0.06,
            ),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: BottomNavigationBar(
          currentIndex: safeCurrentIndex,

          onTap: onTap,

          backgroundColor: Colors.transparent,

          elevation: 0,

          selectedItemColor: controller.accentNeon,

          unselectedItemColor: Colors.white30,

          type: BottomNavigationBarType.fixed,

          showSelectedLabels: true,

          showUnselectedLabels: true,

          selectedFontSize: 10,

          unselectedFontSize: 9,

          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
          ),

          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w400,
          ),

          items: items.map(
            (
              item,
            ) {
              return BottomNavigationBarItem(
                icon: _buildIcon(
                  item: item,
                  selected: false,
                ),

                activeIcon: _buildIcon(
                  item: item,
                  selected: true,
                ),

                label: DashboardNavigation.mobileLabel(
                  item.label,
                ),
              );
            },
          ).toList(),
        ),
      ),
    );
  }

  // ============================================================
  // ÍCONE
  // ============================================================

  Widget _buildIcon({
    required DashboardMenuItem item,
    required bool selected,
  }) {
    return AnimatedContainer(
      duration: const Duration(
        milliseconds: 180,
      ),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(
        bottom: 3,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: selected
            ? controller.accentNeon.withValues(
                alpha: 0.10,
              )
            : Colors.transparent,
        borderRadius: BorderRadius.circular(
          12,
        ),
      ),
      child: Icon(
        item.icon,
        size: selected
            ? 22
            : 21,
        color: selected
            ? controller.accentNeon
            : Colors.white30,
      ),
    );
  }
}
