import 'package:flutter/material.dart';

// ============================================================
// MATCH SEARCH PANEL WIDGET
// ============================================================
//
// Campo visual de pesquisa do módulo Match.
//
// Responsabilidades:
//
// - mostrar campo de pesquisa;
// - exibir estado visual ativo;
// - disparar callback ao digitar;
// - disparar callback ao limpar.
//
// Este widget NÃO:
//
// - possui debounce;
// - executa consulta;
// - acessa repository;
// - acessa Supabase;
// - armazena resultados.
//
// ============================================================

class MatchSearchPanelWidget
    extends
        StatelessWidget {
  // ============================================================
  // CONTROLLER VISUAL
  // ============================================================

  final TextEditingController textController;

  final FocusNode focusNode;

  // ============================================================
  // ESTADO
  // ============================================================

  final bool isActive;

  final Color accentColor;

  // ============================================================
  // CALLBACKS
  // ============================================================

  final ValueChanged<
    String
  >
  onChanged;

  final VoidCallback onClear;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  const MatchSearchPanelWidget({
    super.key,
    required this.textController,
    required this.focusNode,
    required this.isActive,
    required this.accentColor,
    required this.onChanged,
    required this.onClear,
  });

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: const Color(
          0xFF17132D,
        ),
        borderRadius: BorderRadius.circular(
          15,
        ),
        border: Border.all(
          color: isActive
              ? accentColor.withValues(
                  alpha: 0.28,
                )
              : Colors.white.withValues(
                  alpha: 0.07,
                ),
        ),
      ),
      child: TextField(
        controller: textController,
        focusNode: focusNode,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,

          hintText: 'Pesquisar por nome ou @usuario',

          hintStyle: const TextStyle(
            color: Colors.white24,
            fontSize: 11,
          ),

          prefixIcon: Icon(
            Icons.search_rounded,
            color: isActive
                ? accentColor
                : Colors.white38,
            size: 20,
          ),

          suffixIcon: textController.text.isNotEmpty
              ? IconButton(
                  tooltip: 'Limpar',
                  onPressed: onClear,
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white38,
                    size: 18,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
