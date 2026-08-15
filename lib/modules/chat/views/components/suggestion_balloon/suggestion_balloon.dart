import 'package:flutter/material.dart';

import 'controllers/suggestion_controller.dart';

// ============================================================
// SUGGESTION BALLOON
// ============================================================
//
// Autocomplete de rimas exibido dentro da área de digitação.
//
// ============================================================

class SuggestionBalloon
    extends
        StatelessWidget {
  final SuggestionController controller;

  final String suggestion;

  final VoidCallback onTap;

  final VoidCallback? onDismiss;

  final VoidCallback? onAddCommand;

  const SuggestionBalloon({
    super.key,
    required this.controller,
    required this.suggestion,
    required this.onTap,
    this.onDismiss,
    this.onAddCommand,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return ListenableBuilder(
      listenable: controller,
      builder:
          (
            context,
            _,
          ) {
            return AnimatedSwitcher(
              duration: const Duration(
                milliseconds: 180,
              ),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: controller.isLoading
                  ? _buildLoading()
                  : _buildSuggestion(),
            );
          },
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoading() {
    return Container(
      key: const ValueKey(
        'suggestion-loading',
      ),
      height: 34,
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
      ),
      decoration: BoxDecoration(
        color: const Color(
          0xFF1B1625,
        ),
        borderRadius: BorderRadius.circular(
          10,
        ),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.06,
          ),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 1.7,
              color: Colors.purpleAccent,
            ),
          ),

          SizedBox(
            width: 8,
          ),

          Text(
            'Buscando...',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUGESTÃO
  // ============================================================

  Widget _buildSuggestion() {
    return Container(
      key: ValueKey(
        suggestion,
      ),
      constraints: const BoxConstraints(
        minHeight: 34,
        maxWidth: 300,
      ),
      padding: const EdgeInsets.only(
        left: 4,
        right: 4,
      ),
      decoration: BoxDecoration(
        color: const Color(
          0xFF1B1625,
        ),
        borderRadius: BorderRadius.circular(
          11,
        ),
        border: Border.all(
          color: Colors.purpleAccent.withValues(
            alpha: 0.18,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.30,
            ),
            blurRadius: 12,
            offset: const Offset(
              0,
              4,
            ),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ====================================================
          // ANTERIOR
          // ====================================================
          _buildSmallButton(
            icon: Icons.chevron_left_rounded,
            tooltip: 'Anterior',
            onPressed: controller.previousSuggestion,
          ),

          // ====================================================
          // PALAVRA
          // ====================================================
          Flexible(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(
                  8,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 7,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.purpleAccent.withValues(
                          alpha: 0.75,
                        ),
                        size: 12,
                      ),

                      const SizedBox(
                        width: 5,
                      ),

                      Flexible(
                        child: Text(
                          suggestion,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ====================================================
          // PRÓXIMO
          // ====================================================
          _buildSmallButton(
            icon: Icons.chevron_right_rounded,
            tooltip: 'Próxima',
            onPressed: controller.nextSuggestion,
          ),

          // ====================================================
          // EXEMPLO COM IA
          // ====================================================
          if (onAddCommand !=
              null)
            _buildSmallButton(
              icon: Icons.auto_fix_high_rounded,
              tooltip: 'Pedir exemplo',
              color: Colors.purpleAccent,
              onPressed: onAddCommand!,
            ),

          // ====================================================
          // FECHAR
          // ====================================================
          if (onDismiss !=
              null)
            _buildSmallButton(
              icon: Icons.close_rounded,
              tooltip: 'Fechar',
              color: Colors.white30,
              onPressed: onDismiss!,
            ),
        ],
      ),
    );
  }

  // ============================================================
  // BOTÃO PEQUENO
  // ============================================================

  Widget _buildSmallButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    Color color = Colors.white38,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(
            8,
          ),
          child: SizedBox(
            width: 28,
            height: 28,
            child: Icon(
              icon,
              size: 16,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
