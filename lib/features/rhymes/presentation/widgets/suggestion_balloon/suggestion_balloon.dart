import 'package:flutter/material.dart';

class SuggestionBalloon extends StatelessWidget {
  final String suggestion;
  final VoidCallback onTap;
  final VoidCallback? onDismiss;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final VoidCallback? onAddCommand; // Novo parâmetro para o comando de pesquisa
  final bool isLoading;

  const SuggestionBalloon({
    super.key,
    required this.suggestion,
    required this.onTap,
    this.onDismiss,
    this.onNext,
    this.onPrevious,
    this.onAddCommand, // Adicionado ao construtor
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
          bottomRight: Radius.circular(15),
          bottomLeft: Radius.circular(2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 5,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: isLoading
          ? const Padding(
              padding: EdgeInsets.all(8.0),
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
                // Botão de Remover (X)
                if (onDismiss != null)
                  GestureDetector(
                    onTap: onDismiss,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(Icons.close, size: 14, color: Colors.redAccent),
                    ),
                  ),
                
                // Navegação Esquerda (<)
                if (onPrevious != null)
                  GestureDetector(
                    onTap: onPrevious,
                    child: const Icon(Icons.chevron_left, size: 20, color: Colors.black54),
                  ),

                // Texto da Rima (Onde o clique registra o uso)
                GestureDetector(
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      suggestion,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),

                // Navegação Direita (>)
                if (onNext != null)
                  GestureDetector(
                    onTap: onNext,
                    child: const Icon(Icons.chevron_right, size: 20, color: Colors.black54),
                  ),

                // Botão de Comando (+) - Só aparece se onAddCommand não for nulo
                if (onAddCommand != null)
                  GestureDetector(
                    onTap: onAddCommand,
                    child: const Padding(
                      padding: EdgeInsets.only(left: 4, right: 8),
                      child: Icon(Icons.add_circle_outline, size: 18, color: Colors.purpleAccent),
                    ),
                  ),
              ],
            ),
    );
  }
}