import 'package:flutter/material.dart';

class ChatWelcomeCard extends StatelessWidget {
  final Color activeColor;

  const ChatWelcomeCard({
    super.key, 
    this.activeColor = Colors.purpleAccent,
  });

  @override
  Widget build(BuildContext context) {
    // SingleChildScrollView evita o erro de "Bottom Overflow" em telas pequenas
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ícone de Microfone com tamanho ajustado para mobile
              Container(
                padding: const EdgeInsets.all(16), // Reduzido de 20 para 16
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: activeColor.withOpacity(0.1),
                  border: Border.all(color: activeColor.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: activeColor.withOpacity(0.05),
                      blurRadius: 15,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: Icon(Icons.mic_external_on, color: activeColor, size: 38), // Reduzido de 45 para 38
              ),
              const SizedBox(height: 20), // Reduzido de 30 para 20
              
              // Título Principal
              const Text(
                "VERSIN",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white, 
                  fontSize: 24, // Reduzido de 28 para 24
                  fontWeight: FontWeight.bold, 
                  letterSpacing: 4
                ),
              ),
              const SizedBox(height: 15), // Reduzido de 25 para 15
              
              // Texto de boas-vindas com quebras de linha automáticas para mobile
              Text(
                "uma letra organizada brota ouvintes até do chão,\n"
                "cultive sua reflexão que vamos te entregar sua melhor\n"
                "versão escrita",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade400, 
                  fontSize: 14, // Reduzido de 16 para 14
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}