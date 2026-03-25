import 'package:flutter/material.dart';

class ChatWelcomeCard extends StatelessWidget {
  final Color activeColor;

  const ChatWelcomeCard({
    super.key, 
    this.activeColor = Colors.purpleAccent,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ícone de Microfone com efeito de brilho suave
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: activeColor.withOpacity(0.1),
                border: Border.all(color: activeColor.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: activeColor.withOpacity(0.05),
                    blurRadius: 20,
                    spreadRadius: 5,
                  )
                ],
              ),
              child: Icon(Icons.mic_external_on, color: activeColor, size: 45),
            ),
            const SizedBox(height: 30),
            
            // Título Principal
            const Text(
              "VERSIN",
              style: TextStyle(
                color: Colors.white, 
                fontSize: 28, 
                fontWeight: FontWeight.bold, 
                letterSpacing: 4
              ),
            ),
            const SizedBox(height: 25),
            
            // O texto solicitado com a formatação específica
            Text(
              "uma letra organizada brota ouvintes até do chão, \n"
              "cultive sua reflexão que vamos te entregar sua melhor\n"
              "versão escrita",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade400, 
                fontSize: 16,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}