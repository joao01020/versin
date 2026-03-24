import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
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
  bool _isAiTyping = false; 

  @override
  void initState() {
    super.initState();
    _iniciarFluxoBemVindo();
  }

  // Widget para mostrar o status da conta dinamicamente
  Widget _buildStatusBadge() {
    return ListenableBuilder(
      listenable: _rimasController,
      builder: (context, child) {
        String statusText = "FREE";
        Color statusColor = Colors.grey;

        if (_rimasController.userApiKey == "VERSIN-PRO-TRIAL-2026-FREE") {
          statusText = "PRO TRIAL";
          statusColor = Colors.cyanAccent;
        } else if (_rimasController.userApiKey != null && _rimasController.userApiKey!.isNotEmpty) {
          statusText = "API PRIVADA";
          statusColor = Colors.greenAccent;
        }

        return Text(
          statusText,
          style: TextStyle(
            color: statusColor.withOpacity(0.6),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        );
      },
    );
  }

  void _iniciarFluxoBemVindo() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (messages.isEmpty) {
        setState(() {
          messages.add({
            "role": "assistant",
            "content": "Seja bem vindo ao Versin. Você está pronto para se expressar de uma forma totalmente original e sincera? ✨"
          });
          _isAiTyping = true; 
        });

        Timer(const Duration(seconds: 4), () {
          if (mounted && messages.length == 1) {
            setState(() {
              messages.add({
                "role": "assistant",
                "content": "Salve! Sou o Versin, seu mentor de composição. 🎤\n\n"
                           "O que vamos compor hoje? **Trap**, **Funk**, **Emotrap**, **Sertanejo** ou **Samba**?"
              });
            });
            _scrollToBottom();

            Timer(const Duration(seconds: 4), () {
              if (mounted && messages.length == 2) {
                setState(() {
                  _isAiTyping = false; 
                  messages.add({
                    "role": "assistant",
                    "content": "Escolha um e me mande um resumo (mínimo **10 linhas**) "
                               "do que você está sentindo para a gente organizar essas ideias."
                  });
                });
                _scrollToBottom();
              }
            });
          }
        });
      }
    });
  }

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

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    if (text.startsWith("/list")) {
      final conteudo = text.replaceFirst("/list", "").trim();
      final rimas = conteudo.split(RegExp(r'[,,;]')); 
      for (var rima in rimas) {
        if (rima.trim().isNotEmpty) {
          _rimasController.adicionarPalavra(rima.trim(), true);
        }
      }
      _messageController.clear();
      return;
    }
    
    setState(() {
      messages.add({"role": "user", "content": text});
      _messageController.clear();
      _rimasController.limparSugestao();
      _isAiTyping = true; 
    });
    
    _scrollToBottom();
    
    final aiResponse = await _rimasController.fetchAiResponse(text);

    if (mounted) {
      setState(() {
        _isAiTyping = false;
        messages.add(aiResponse);
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF0F0F0F),
      drawer: VersinDrawer(
        rimasController: _rimasController,
        onNewChat: () {
          setState(() {
            messages.clear();
            _isAiTyping = false;
          });
          _iniciarFluxoBemVindo();
        },
      ),
      body: Stack(
        children: [
          // Título Centralizado + Badge de Status
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  "Versin",
                  style: TextStyle(
                    color: Colors.purpleAccent.withOpacity(0.8),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 2),
                _buildStatusBadge(),
              ],
            ),
          ),
          // Botão do Menu
          Positioned(
            top: 45,
            left: 15,
            child: IconButton(
              icon: const Icon(Icons.menu_rounded, color: Colors.purpleAccent, size: 32),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
          ),
          // Área das Mensagens
          Positioned.fill(
            top: 110, // Aumentado um pouco para acomodar o badge
            bottom: 120 + bottomPadding, 
            child: messages.isEmpty ? const ChatWelcomeCard() : _buildMessageList(),
          ),
          // Barra de Input e Sugestão
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
                    double offsetX = (_messageController.text.length * 8.0).clamp(0.0, MediaQuery.of(context).size.width * 0.6);
                    
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
                              _messageController.text = "$currentText ${_rimasController.sugestao} ".trim();
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
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          keyboardType: TextInputType.multiline,
                          maxLines: 5, 
                          minLines: 1,
                          textInputAction: TextInputAction.newline,
                          onChanged: (val) {
                            _rimasController.onTextChanged(val);
                            setState(() {}); 
                            if (val.isEmpty) _rimasController.limparSugestao();
                          },
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                          decoration: const InputDecoration(
                            hintText: "Manda o sentimento...",
                            hintStyle: TextStyle(color: Colors.grey, fontSize: 15),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: GestureDetector(
                          onTap: _sendMessage,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: Colors.purpleAccent, 
                              shape: BoxShape.circle
                            ),
                            child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: messages.length + (_isAiTyping ? 1 : 0),
      itemBuilder: (context, index) {
        // RESGATE DO CARREGAMENTO: Versin está digitando...
        if (index == messages.length && _isAiTyping) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Row(
              children: [
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.purpleAccent),
                ),
                const SizedBox(width: 10),
                Text(
                  "Versin está digitando...",
                  style: TextStyle(
                    color: Colors.purpleAccent.withOpacity(0.7), 
                    fontSize: 13, 
                    fontStyle: FontStyle.italic
                  ),
                ),
              ],
            ),
          );
        }

        final message = messages[index];
        final isUser = message['role'] == 'user';

        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
            decoration: BoxDecoration(
              color: isUser ? const Color(0xFF2D2D2D) : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
            ),
            child: isUser 
              ? Text(
                  message['content'] ?? "",
                  style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
                )
              : MarkdownBody(
                  data: message['content'] ?? "",
                  shrinkWrap: true,
                  styleSheet: MarkdownStyleSheet(
                    p: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.4, fontFamily: 'monospace'),
                    strong: const TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold),
                    listBullet: const TextStyle(color: Colors.purpleAccent),
                    blockSpacing: 10,
                  ),
                ),
          ),
        );
      },
    );
  }
}