import 'package:flutter/material.dart';

class ChatInputField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final ValueChanged<String>? onChanged; // Necessário para a IA ouvir a digitação
  final LayerLink? layerLink; // Necessário para o balão "seguir" o campo

  const ChatInputField({
    super.key,
    required this.controller,
    required this.onSend,
    this.onChanged,
    this.layerLink,
  });

  @override
  Widget build(BuildContext context) {
    // Usamos o CompositedTransformTarget para o balão saber onde o input está
    return CompositedTransformTarget(
      link: layerLink ?? LayerLink(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05), // Fundo sutil para o input interno
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged, // Conecta com o RimasController
                style: const TextStyle(color: Colors.white, fontSize: 16),
                maxLines: null, // Deixa o campo crescer se a rima for longa
                decoration: const InputDecoration(
                  hintText: "Mande o papo...",
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            // O botão de enviar agora fica "lá dentro" como você pediu
            IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.purpleAccent, size: 22),
              onPressed: onSend,
            ),
          ],
        ),
      ),
    );
  }
}