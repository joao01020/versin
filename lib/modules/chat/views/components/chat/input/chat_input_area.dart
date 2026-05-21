import 'package:flutter/material.dart';

class ChatInputArea extends StatefulWidget {
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
  State<ChatInputArea> createState() => _ChatInputAreaState();
}

class _ChatInputAreaState extends State<ChatInputArea> {
  // Controle de estado para alternar entre modo compacto e expansivo
  bool _isCompactMode = false;

  @override
  Widget build(BuildContext context) {
    // ConstrainedBox evita o erro de "Bottom Overflow" ao limitar a altura máxima
    return ConstrainedBox(
      constraints: BoxConstraints(
        // Define que o chat não pode ocupar mais de 45% da altura da tela
        maxHeight: MediaQuery.of(context).size.height * 0.45,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF121212), // Cor escura sólida para combinar com o fundo
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: widget.activeColor.withOpacity(0.1)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Ícone lateral para alternar o tamanho (Minimizar/Maximizar)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isCompactMode = !_isCompactMode;
                  });
                },
                child: Icon(
                  _isCompactMode ? Icons.unfold_more_rounded : Icons.unfold_less_rounded,
                  color: widget.activeColor.withOpacity(0.5),
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: widget.controller,
                keyboardType: TextInputType.multiline,
                // Inicia com 1 linha, mas cresce conforme a estrutura enviada
                minLines: 1,
                // Se compactado, mostra 3 linhas; se não, cresce até o limite do ConstrainedBox
                maxLines: _isCompactMode ? 3 : null, 
                textInputAction: TextInputAction.newline,
                style: const TextStyle(
                  color: Colors.white, 
                  fontSize: 16, 
                  height: 1.8, // Aumentado para 1.8 para dar o espaço da foto 221242
                ),
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: const TextStyle(color: Colors.white24),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                ),
              ),
            ),
            // Botão de enviar posicionado sempre no canto inferior direito
            IconButton(
              icon: Icon(Icons.send_rounded, color: widget.activeColor),
              onPressed: widget.onSend,
            ),
          ],
        ),
      ),
    );
  }
}