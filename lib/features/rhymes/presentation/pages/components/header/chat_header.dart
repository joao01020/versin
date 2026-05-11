import 'package:flutter/material.dart';
import 'package:versin/features/rhymes/presentation/controller/rhymes_controller.dart';
import 'package:versin/features/rhymes/presentation/widgets/thermometer_gamification/thermometer_widget.dart';

class ChatHeader extends StatelessWidget {
  final Color activeColor;
  final RhymesController rhymesController;
  final GlobalKey<ScaffoldState> scaffoldKey;

  const ChatHeader({
    super.key,
    required this.activeColor,
    required this.rhymesController,
    required this.scaffoldKey,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: rhymesController,
      builder: (context, _) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: const BoxDecoration(
            color: Color(0xFF0F0F0F),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Barra superior: Menu + Branding (VERSIN GENESIS)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => scaffoldKey.currentState?.openDrawer(),
                    icon: const Icon(Icons.menu, color: Colors.white70, size: 22),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "VERSIN",
                        style: TextStyle(
                          color: activeColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w900, // Corrigido de .black para .w900
                          letterSpacing: 2.0,
                        ),
                      ),
                      const Text(
                        "GENESIS",
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  // Espaçador para equilibrar o IconButton e manter o texto centralizado
                  const SizedBox(width: 48), 
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Widget de Gamificação (Termômetro/Estrelas)
              ThermometerFeedback(
                starProgress: rhymesController.starProgress,
                fireProgress: rhymesController.fireProgress,
                feedbackText: rhymesController.currentFeedback,
              ),
              
              const SizedBox(height: 8),
              
              // Instrução sutil para o usuário
              Text(
                "Comece a escrever para analisar sua letra...",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        );
      },
    );
  }
}