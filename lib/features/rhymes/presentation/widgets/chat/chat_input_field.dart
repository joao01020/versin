import 'package:flutter/material.dart';

class ChatInputArea
    extends
        StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final Color activeColor;
  final String hintText;

  const ChatInputArea({
    super.key,
    required this.controller,
    required this.onSend,
    required this.activeColor,
    required this.hintText,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      // Aumentamos o vertical para 12 para dar mais distância das bordas externas
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: const Color(
          0xFF1A1A1A,
        ),
        borderRadius: BorderRadius.circular(
          22,
        ),
        // Corrigido o deprecated withOpacity para withValues
        border: Border.all(
          color: activeColor.withValues(
            alpha: 0.3,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end, // Mantém o botão de enviar fixo embaixo
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.multiline,
              // ALTERAÇÕES CHAVE AQUI:
              maxLines: null, // Permite que o chat aumente sem parar para caber a letra
              minLines: 4, // Deixa o chat grande
              style: TextStyle(
                color: activeColor,
                fontSize: 16,
                height: 1.5,
              ), // height melhora o espaçamento entre as linhas da letra
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                ),
                border: InputBorder.none,
                // Ajuste interno do texto
                contentPadding: const EdgeInsets.fromLTRB(
                  8,
                  12,
                  8,
                  12,
                ),
              ),
            ),
          ),
          // O IconButton fica alinhado ao final da última linha
          Padding(
            padding: const EdgeInsets.only(
              bottom: 4,
            ),
            child: IconButton(
              icon: Icon(
                Icons.send_rounded,
                color: activeColor,
              ),
              onPressed: onSend,
            ),
          ),
        ],
      ),
    );
  }
}
