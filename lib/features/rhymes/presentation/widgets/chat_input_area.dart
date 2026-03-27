import 'package:flutter/material.dart';

class ChatInputArea extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final Color activeColor;
  final String hintText;
  // NOVO: Adicionando o parâmetro para receber a função de salvar rima
  final Function(String)? onAddRhyme; 

  const ChatInputArea({
    super.key,
    required this.controller,
    required this.onSend,
    required this.activeColor,
    this.hintText = "Manda o sentimento...",
    this.onAddRhyme, // Inicializando aqui
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: activeColor.withOpacity(0.3), width: 0.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              // Configurado para permitir quebra de linha em vez de enviar
              maxLines: null,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(color: Colors.grey.withOpacity(0.6)),
                border: InputBorder.none,
              ),
              // Removido o onSubmitted para o envio ser apenas pelo botão
            ),
          ),
          // Botão de envio exclusivo (será o local da animação lápis/microfone)
          IconButton(
            icon: Icon(Icons.send_rounded, color: activeColor),
            onPressed: onSend,
          ),
        ],
      ),
    );
  }
}