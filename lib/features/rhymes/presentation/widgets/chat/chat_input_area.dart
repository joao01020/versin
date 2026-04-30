import 'package:flutter/material.dart';

class ChatInputArea extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final Color activeColor;
  final String hintText;
  final Function(String)? onAddRhyme;

  const ChatInputArea({
    super.key,
    required this.controller,
    required this.onSend,
    required this.activeColor,
    required this.hintText,
    this.onAddRhyme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        // Alinha o botão de enviar na base enquanto o campo de texto cresce
        crossAxisAlignment: CrossAxisAlignment.end, 
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              // Permite múltiplas linhas para compor a letra da música
              keyboardType: TextInputType.multiline,
              minLines: 1,
              // Limita a expansão visual para 5 linhas antes de ativar o scroll interno
              maxLines: 5, 
              // Garante que a tecla Enter execute a quebra de linha
              textInputAction: TextInputAction.newline,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(color: Colors.white24),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send_rounded, color: activeColor),
            onPressed: onSend,
          ),
        ],
      ),
    );
  }
}