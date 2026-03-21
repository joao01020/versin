import 'package:flutter/material.dart';

class ChatWelcomeCard extends StatelessWidget {
  const ChatWelcomeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Ocupa apenas o espaço necessário
          children: [
            // Ícone do Projeto
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.purpleAccent.withOpacity(0.1),
                border: Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
              ),
              child: const Icon(Icons.mic_external_on, color: Colors.purpleAccent, size: 40),
            ),
            const SizedBox(height: 25),
            
            // Texto de Boas-Vindas
            const Text(
              "Bem-vindo ao VERSIN",
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2),
            ),
            const SizedBox(height: 10),
            
            // Subtítulo
            const Text(
              "Qual é a ideia de hoje? Digite sua linha ou peça uma rima para começar.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}