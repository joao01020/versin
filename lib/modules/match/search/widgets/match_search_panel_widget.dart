import 'package:flutter/material.dart';

// ============================================================
// MATCH SEARCH PANEL WIDGET
// ============================================================
//
// Campo visual da pesquisa.
//
// Responsável somente por:
//
// - mostrar TextField;
// - mostrar ícone;
// - mostrar botão limpar;
// - encaminhar alteração de texto.
//
// NÃO:
//
// - pesquisa usuários;
// - acessa repository;
// - possui debounce;
// - acessa Supabase.
//
// ============================================================

class MatchSearchPanelWidget
    extends
        StatelessWidget {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController textController;

  final FocusNode focusNode;

  // ============================================================
  // STATE
  // ============================================================

  final bool isActive;

  // ============================================================
  // STYLE
  // ============================================================

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
  // CONSTRUCTOR
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
    return AnimatedContainer(
      duration: const Duration(
        milliseconds: 180,
      ),

      curve: Curves.easeOut,

      width: double.infinity,

      decoration: BoxDecoration(
        color:
            const Color(
              0xFF17132D,
            ).withValues(
              alpha: 0.85,
            ),

        borderRadius: BorderRadius.circular(
          16,
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

      child:
          ValueListenableBuilder<
            TextEditingValue
          >(
            valueListenable: textController,

            builder:
                (
                  context,
                  value,
                  child,
                ) {
                  final hasText = value.text.trim().isNotEmpty;

                  return TextField(
                    controller: textController,

                    focusNode: focusNode,

                    onChanged: onChanged,

                    textInputAction: TextInputAction.search,

                    autocorrect: false,

                    enableSuggestions: true,

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

                      suffixIcon: hasText
                          ? IconButton(
                              tooltip: 'Limpar pesquisa',

                              onPressed: onClear,

                              icon: const Icon(
                                Icons.close_rounded,

                                color: Colors.white38,

                                size: 18,
                              ),
                            )
                          : null,

                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 15,
                      ),
                    ),
                  );
                },
          ),
    );
  }
}
