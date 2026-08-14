import '../models/dashboard_menu_item.dart';

// ============================================================
// DASHBOARD NAVIGATION
// ============================================================
//
// Classe utilitária responsável por:
//
// - trabalhar com itens visíveis;
// - converter índice visual em índice original;
// - converter índice original em posição visual;
// - localizar itens do menu.
//
// Esta classe NÃO:
//
// - desenha widgets;
// - acessa BuildContext;
// - controla PageController;
// - acessa DashboardController.
//
// Ela apenas centraliza regras de navegação.
//
// ============================================================

abstract final class DashboardNavigation {
  // ==========================================================
  // ITENS VISÍVEIS
  // ==========================================================

  static List<
    DashboardMenuItem
  >
  visibleItems(
    List<
      DashboardMenuItem
    >
    items,
  ) {
    return items
        .where(
          (
            item,
          ) => item.visible,
        )
        .toList(
          growable: false,
        );
  }

  // ==========================================================
  // ÍNDICE ORIGINAL A PARTIR DA POSIÇÃO VISUAL
  // ==========================================================

  static int? originalIndexFromVisibleIndex({
    required List<
      DashboardMenuItem
    >
    items,
    required int visibleIndex,
  }) {
    final visible = visibleItems(
      items,
    );

    if (visibleIndex <
            0 ||
        visibleIndex >=
            visible.length) {
      return null;
    }

    return visible[visibleIndex].originalIndex;
  }

  // ==========================================================
  // POSIÇÃO VISUAL A PARTIR DO ÍNDICE ORIGINAL
  // ==========================================================

  static int visibleIndexFromOriginalIndex({
    required List<
      DashboardMenuItem
    >
    items,
    required int originalIndex,
  }) {
    final visible = visibleItems(
      items,
    );

    final index = visible.indexWhere(
      (
        item,
      ) =>
          item.originalIndex ==
          originalIndex,
    );

    if (index <
        0) {
      return 0;
    }

    return index;
  }

  // ==========================================================
  // BUSCAR ITEM PELO ÍNDICE ORIGINAL
  // ==========================================================

  static DashboardMenuItem? findByOriginalIndex({
    required List<
      DashboardMenuItem
    >
    items,
    required int originalIndex,
  }) {
    for (final item in items) {
      if (item.originalIndex ==
          originalIndex) {
        return item;
      }
    }

    return null;
  }

  // ==========================================================
  // BUSCAR ITEM PELA POSIÇÃO VISUAL
  // ==========================================================

  static DashboardMenuItem? findByVisibleIndex({
    required List<
      DashboardMenuItem
    >
    items,
    required int visibleIndex,
  }) {
    final visible = visibleItems(
      items,
    );

    if (visibleIndex <
            0 ||
        visibleIndex >=
            visible.length) {
      return null;
    }

    return visible[visibleIndex];
  }

  // ==========================================================
  // BUSCAR ITEM PELA ROTA
  // ==========================================================

  static DashboardMenuItem? findByRoute({
    required List<
      DashboardMenuItem
    >
    items,
    required String route,
  }) {
    final normalizedRoute = route.trim();

    if (normalizedRoute.isEmpty) {
      return null;
    }

    for (final item in items) {
      if (item.route ==
          normalizedRoute) {
        return item;
      }
    }

    return null;
  }

  // ==========================================================
  // VERIFICAR ÍNDICE VISUAL
  // ==========================================================

  static bool isValidVisibleIndex({
    required List<
      DashboardMenuItem
    >
    items,
    required int visibleIndex,
  }) {
    final visible = visibleItems(
      items,
    );

    return visibleIndex >=
            0 &&
        visibleIndex <
            visible.length;
  }

  // ==========================================================
  // VERIFICAR ÍNDICE ORIGINAL
  // ==========================================================

  static bool containsOriginalIndex({
    required List<
      DashboardMenuItem
    >
    items,
    required int originalIndex,
  }) {
    return items.any(
      (
        item,
      ) =>
          item.originalIndex ==
          originalIndex,
    );
  }

  // ==========================================================
  // LABEL MOBILE
  // ==========================================================

  static String mobileLabel(
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
