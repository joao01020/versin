import 'dart:async';
import 'package:flutter/material.dart';
import 'package:versin/features/rimas/presentation/widgets/chat_welcome_card.dart';
import 'package:versin/features/rimas/presentation/widgets/versin_drawer.dart';
import 'package:versin/features/rimas/presentation/widgets/ai_suggestion/ai_suggestion_balloon.dart';
import 'package:versin/features/rimas/presentation/controller/rimas_controller.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();
  final RimasController _rimasController = RimasController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  Timer? _hideTimer;
  List<Map<String, String>> messages = [];

  @override
  void dispose() {
    _messageController.dispose();
    _rimasController.dispose();
    _scrollController.dispose();
    _hideTimer?.cancel();
    super.dispose();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && _rimasController.sugestao.isNotEmpty) {
        setState(() {
          _rimasController.limparSugestao();
        });
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    
    setState(() {
      messages.add({"role": "user", "content": text});
      _messageController.clear();
      _rimasController.limparSugestao();
    });
    
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF0F0F0F),
      drawer: VersinDrawer(
        rimasController: _rimasController,
        onNewChat: () => setState(() => messages.clear()),
      ),
      body: Stack(
        children: [
          // BOTÃO DAS LISTRAS (MENU) - ATUALIZADO PARA ROXO
          Positioned(
            top: 45,
            left: 15,
            child: IconButton(
              icon: const Icon(
                Icons.menu_rounded, 
                color: Colors.purpleAccent, // Cor das listras alterada para roxo
                size: 32,
              ),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
          ),

          // LISTA DE MENSAGENS ESTILO CHATGPT
          Positioned.fill(
            top: 100,
            bottom: 120 + bottomPadding, 
            child: messages.isEmpty ? const ChatWelcomeCard() : _buildMessageList(),
          ),

          // SUGESTÃO E INPUT
          Positioned(
            bottom: bottomPadding + 15,
            left: 15,
            right: 15,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListenableBuilder(
                  listenable: _rimasController,
                  builder: (context, child) {
                    if (_rimasController.sugestao.isNotEmpty && !(_hideTimer?.isActive ?? false)) {
                       _startHideTimer();
                    }
                    double offsetX = (_messageController.text.length * 8.0).clamp(0.0, 220.0);
                    return AnimatedOpacity(
                      opacity: (_rimasController.sugestao.isNotEmpty || _rimasController.carregando) ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        padding: EdgeInsets.only(left: offsetX),
                        child: AiSuggestionBalloon(
                          suggestion: _rimasController.sugestao,
                          isLoading: _rimasController.carregando,
                          onTap: () {
                            setState(() {
                              final currentText = _messageController.text;
                              _messageController.text = "$currentText ${_rimasController.sugestao}".trim();
                              _messageController.selection = TextSelection.fromPosition(
                                TextPosition(offset: _messageController.text.length),
                              );
                              _rimasController.aceitarSugestao();
                              _hideTimer?.cancel();
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          onChanged: (val) {
                            _rimasController.onTextChanged(val);
                            setState(() {});
                            if (val.isEmpty) _rimasController.limparSugestao();
                          },
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                          decoration: const InputDecoration(
                            hintText: "Manda a letra...",
                            hintStyle: TextStyle(color: Colors.grey),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _sendMessage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.purpleAccent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isUser = message['role'] == 'user';

        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
            decoration: BoxDecoration(
              color: isUser ? const Color(0xFF2D2D2D) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              message['content'] ?? "",
              style: TextStyle(
                color: isUser ? Colors.white : Colors.white70,
                fontSize: 16,
                height: 1.4,
                fontFamily: isUser ? 'sans-serif' : 'monospace',
              ),
            ),
          ),
        );
      },
    );
  }
}