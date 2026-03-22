import 'package:flutter/material.dart';
import '../widgets/chat_input_field.dart';
import '../widgets/chat_welcome_card.dart';
import '../widgets/versin_drawer.dart'; 

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();
  List<String> messages = [];

  // O dispose é chamado automaticamente quando o Widget é removido da árvore
  @override
  void dispose() {
    _messageController.dispose(); // Descarta o controlador para liberar memória
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      messages.add("Eu: ${_messageController.text}");
      messages.add("VERSIN AI: Analisando o beat..."); 
      _messageController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F), 
      
      // Drawer atualizado com a função de limpar o chat
      drawer: VersinDrawer(
        onNewChat: () {
          setState(() {
            messages.clear();
          });
        },
      ),

      appBar: AppBar(
        title: const Text('VERSIN', 
          style: TextStyle(
            letterSpacing: 8, 
            fontWeight: FontWeight.w200, 
            color: Colors.white,
            fontSize: 18,
          )),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.purpleAccent),
      ),
      
      body: Stack(
        children: [
          Positioned.fill(
            bottom: 70, 
            child: messages.isEmpty
                ? const ChatWelcomeCard()
                : _buildMessageList(),
          ),
          
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