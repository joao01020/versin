import 'package:flutter/material.dart';

// ============================================================
// DASHBOARD MENU ITEM
// ============================================================
//
// Modelo responsável por representar um item de navegação
// disponível no Dashboard.
//
// Este model NÃO possui:
// - lógica de navegação;
// - regras de interface;
// - estado;
// - acesso ao controller.
//
// Ele apenas descreve um item do menu.
//
// Exemplo:
//
// DashboardMenuItem(
//   originalIndex: 0,
//   label: 'Dashboard',
//   icon: Icons.dashboard_outlined,
//   route: '/',
//   visible: true,
// )
//
// ============================================================

class DashboardMenuItem {
  // ============================================================
  // ÍNDICE ORIGINAL
  // ============================================================
  //
  // Índice utilizado pelo DashboardController e pelo PageView.
  //
  // Ele permanece independente da posição visual do item.
  //
  // Isso permite esconder um menu sem alterar os índices das
  // páginas existentes.
  //
  // ============================================================

  final int originalIndex;

  // ============================================================
  // LABEL
  // ============================================================
  //
  // Nome apresentado ao usuário.
  //
  // Exemplos:
  //
  // Dashboard
  // Estudio
  // IA
  // Conectar
  // Carteira
  // Hub
  //
  // ============================================================

  final String label;

  // ============================================================
  // ÍCONE
  // ============================================================

  final IconData icon;

  // ============================================================
  // ROTA
  // ============================================================
  //
  // Mantemos a rota no model porque alguns módulos ainda podem
  // utilizar AppRoutes ou navegação externa no futuro.
  //
  // Para páginas controladas diretamente pelo PageView,
  // este valor pode ser uma String vazia.
  //
  // ============================================================

  final String route;

  // ============================================================
  // VISIBILIDADE
  // ============================================================
  //
  // true:
  // item aparece nos menus.
  //
  // false:
  // página continua existindo no PageView, mas o item não é
  // apresentado na navegação.
  //
  // ============================================================

  final bool visible;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  const DashboardMenuItem({
    required this.originalIndex,
    required this.label,
    required this.icon,
    required this.route,
    required this.visible,
  });

  // ============================================================
  // COPY WITH
  // ============================================================
  //
  // Permite criar uma nova configuração baseada em outra sem
  // modificar o objeto original.
  //
  // Útil futuramente caso a configuração dos menus passe a ser
  // dinâmica.
  //
  // ============================================================

  DashboardMenuItem copyWith({
    int? originalIndex,
    String? label,
    IconData? icon,
    String? route,
    bool? visible,
  }) {
    return DashboardMenuItem(
      originalIndex:
          originalIndex ??
          this.originalIndex,
      label:
          label ??
          this.label,
      icon:
          icon ??
          this.icon,
      route:
          route ??
          this.route,
      visible:
          visible ??
          this.visible,
    );
  }

  // ============================================================
  // DEBUG
  // ============================================================

  @override
  String toString() {
    return 'DashboardMenuItem('
        'originalIndex: $originalIndex, '
        'label: $label, '
        'route: $route, '
        'visible: $visible'
        ')';
  }
}
