import 'package:flutter/material.dart';
import '../widgets/chat_input_field.dart';
import '../widgets/chat_welcome_card.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();
  List<String> messages = []; // Por enquanto, apenas texto

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      // Adiciona a mensagem do usuário (João)
      messages.add("Eu: ${_messageController.text}");
      
      // Simula uma resposta da IA (Llama 3)
      // No futuro, isso chamará o UseCase -> Repository -> API Python
      messages.add("VERSIN AI: É o flow, rima com show..."); 
      
      _messageController.clear(); // Limpa o campo
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F), // Preto Profundo
      appBar: AppBar(
        title: const Text('VERSIN', style: TextStyle(letterSpacing: 4, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      
      // O 'body' é um Stack para o input ficar fixo embaixo
      body: Stack(
        children: [
          // 1. Área de Conteúdo (Mensagens ou Boas-Vindas)
          Positioned.fill(
            bottom: 70, // Espaço para o campo de texto não cobrir
            child: messages.isEmpty
                ? const ChatWelcomeCard()
                : _buildMessageList(),
          ),
          
          // 2. Campo de Texto (Fixado no Rodapé)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ChatInputField(
              controller: _messageController,
              onSend: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  // Widget simples para mostrar as mensagens (vamos melhorar depois)
  Widget _buildMessageList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final isUser = messages[index].startsWith("Eu:");
        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 5),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isUser ? Colors.purpleAccent.withOpacity(0.1) : const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isUser ? Colors.purpleAccent.withOpacity(0.3) : Colors.transparent),
            ),
            child: Text(messages[index], style: const TextStyle(color: Colors.white)),
          ),
        );
      },
    );
  }
}