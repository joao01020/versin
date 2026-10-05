import 'package:flutter/material.dart';

// ============================================================
// STORAGE EMPTY STATE
// ============================================================
//
// Exibido quando o usuário ainda não possui nenhuma obra
// registrada.
//
// Serve tanto para:
//
// - letras;
// - beats.
//
// ============================================================

class StorageEmptyState
    extends
        StatelessWidget {
  final String title;

  final String message;

  final IconData icon;

  final String buttonLabel;

  final VoidCallback? onPressed;

  final Color accentColor;

  const StorageEmptyState({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    required this.buttonLabel,
    required this.accentColor,
    this.onPressed,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(
          32,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 460,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // =================================================
              // ÍCONE
              // =================================================
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: accentColor.withValues(
                    alpha: 0.08,
                  ),
                  borderRadius: BorderRadius.circular(
                    24,
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
                  size: 36,
                ),
              ),

              const SizedBox(
                height: 24,
              ),

              // =================================================
              // TÍTULO
              // =================================================
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              // =================================================
              // DESCRIÇÃO
              // =================================================
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(
                    alpha: 0.45,
                  ),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),

              const SizedBox(
                height: 26,
              ),

              // =================================================
              // BOTÃO
              // =================================================
              if (onPressed !=
                  null)
                FilledButton.icon(
                  onPressed: onPressed,
                  style: FilledButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        14,
                      ),
                    ),
                  ),
                  icon: const Icon(
                    Icons.add_rounded,
                    size: 19,
                  ),
                  label: Text(
                    buttonLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
