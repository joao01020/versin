import 'package:flutter/material.dart';
import 'controllers/suggestion_controller.dart';

class SuggestionBalloon
    extends
        StatelessWidget {
  final SuggestionController controller;
  final String suggestion; // Parâmetro adicionado para compatibilidade com o ChatPage
  final VoidCallback onTap;
  final VoidCallback? onDismiss;
  final VoidCallback? onAddCommand;

  const SuggestionBalloon({
    super.key,
    required this.controller,
    required this.suggestion, // Requerido para resolver o erro na ChatPage
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
            child,
          ) {
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(
                    15,
                  ),
                  topRight: Radius.circular(
                    15,
                  ),
                  bottomRight: Radius.circular(
                    15,
                  ),
                  bottomLeft: Radius.circular(
                    2,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: 0.3,
                    ),
                    blurRadius: 5,
                    offset: const Offset(
                      0,
                      2,
                    ),
                  ),
                ],
              ),
              child: controller.isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(
                        8.0,
                      ),
                      child: SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.purpleAccent,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (onDismiss !=
                            null)
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              size: 14,
                              color: Colors.redAccent,
                            ),
                            onPressed: onDismiss,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            padding: EdgeInsets.zero,
                          ),
                        IconButton(
                          icon: const Icon(
                            Icons.chevron_left,
                            size: 20,
                            color: Colors.black54,
                          ),
                          onPressed: controller.previousSuggestion,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        GestureDetector(
                          onTap: onTap,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Text(
                              suggestion, // Usando o parâmetro recebido da ChatPage
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.chevron_right,
                            size: 20,
                            color: Colors.black54,
                          ),
                          onPressed: controller.nextSuggestion,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        if (onAddCommand !=
                            null)
                          IconButton(
                            icon: const Icon(
                              Icons.add_circle_outline,
                              size: 18,
                              color: Colors.purpleAccent,
                            ),
                            onPressed: onAddCommand,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            padding: EdgeInsets.zero,
                          ),
                      ],
                    ),
            );
          },
    );
  }
}
