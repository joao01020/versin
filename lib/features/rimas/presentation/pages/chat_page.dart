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
  List<String> messages = [];

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      messages.add("Eu: ${_messageController.text}");
      messages.add("VERSIN AI: É o flow, rima com show...");
      _messageController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F), 
      
      drawer: _buildVersinDrawer(),

      appBar: AppBar(
        // Aplicada a fonte com letterSpacing e peso reduzido para elegância
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

  // --- SEUS WIDGETS DO MENU LATERAL MANTIDOS ---
  Widget _buildVersinDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF121212),
      child: Container(
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: Colors.purpleAccent.withOpacity(0.3), width: 2)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 60, left: 16, right: 16, bottom: 10),
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.add, color: Colors.purpleAccent),
                label: const Text("Nova conversa", style: TextStyle(color: Colors.white)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.purpleAccent.withOpacity(0.4)),
                  minimumSize: const Size(double.infinity, 45),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),

            _drawerTile(Icons.book_outlined, "Dicionário", () {}),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: TextField(
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: "Pesquisar rimas...",
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                  prefixIcon: const Icon(Icons.search, color: Colors.purpleAccent, size: 20),
                  filled: true,
                  fillColor: Colors.purpleAccent.withOpacity(0.05),
                  contentPadding: const EdgeInsets.all(0),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
            ),

            const Divider(color: Colors.white10),

            const Padding(
              padding: EdgeInsets.only(left: 20, top: 10, bottom: 5),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("Conversas", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),

            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _drawerTile(Icons.chat_bubble_outline, "Beat Trap 140bpm - Agressivo", () {}),
                  _drawerTile(Icons.chat_bubble_outline, "Emo trap 90bpm - Melancolico ", () {}),
                ],
              ),
            ),

            const Divider(color: Colors.white10),

            _drawerTile(Icons.settings_outlined, "Configuração", () {}),
            _drawerTile(Icons.help_outline, "Ajuda", () {}),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _drawerTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.purpleAccent, size: 22),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15)),
      onTap: onTap,
      dense: true,
      visualDensity: VisualDensity.compact,
    );
  }

  // --- SEU WIDGET DE MENSAGENS MANTIDO ---
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