import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:versin/features/rimas/presentation/widgets/chat_welcome_card.dart';
import 'package:versin/features/rimas/presentation/widgets/versin_drawer.dart';
import 'package:versin/features/rimas/presentation/widgets/ai_suggestion/ai_suggestion_balloon.dart';
import 'package:versin/features/rimas/presentation/controller/rimas_controller.dart';
import 'package:versin/features/rimas/presentation/widgets/thermometer_gamification/thermometer_widget.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();
  
  // CORREÇÃO: Usamos uma única instância e garantimos que o Listeners sejam notificados
  final RimasController _rimasController = RimasController();
  
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  Timer? _hideTimer;
  List<Map<String, String>> messages = [];
  bool _isAiTyping = false; 

  // ESTADOS DOS MODOS TERMINAL
  bool _isRhymeMode = false;
  bool _isComporMode = false;
  bool _isListarMode = false;
  bool _isMarketingMode = false;

  int _currentSuggestionIndex = 0;

  @override
  void initState() {
    super.initState();
    _inicializarConfiguracoes();
    _iniciarFluxoBemVindo();

    // Ouvinte para sugestões de rima conforme escreve
    _messageController.addListener(() {
      final text = _messageController.text;
      
      // Lógica de busca automática ao digitar espaço
      if (text.isNotEmpty && text.endsWith(" ")) {
        final words = text.trim().split(" ");
        if (words.isNotEmpty) {
          final lastWord = words.last;
          if (lastWord.length > 2) {
            _rimasController.buscarSugestao(lastWord);
          }
        }
      }
      
      // Sincroniza o progresso visual do termômetro enquanto digita
      _rimasController.onTextChanged(text);
    });
  }

  Color _getActiveColor() {
    if (_isRhymeMode) return Colors.greenAccent;
    if (_isComporMode) return Colors.blueAccent;
    if (_isListarMode) return Colors.orangeAccent;
    if (_isMarketingMode) return Colors.yellowAccent;
    return Colors.purpleAccent;
  }

  String _getActiveStatusText() {
    if (_isRhymeMode) return "RHYME MODE";
    if (_isComporMode) return "COMPOSING MODE";
    if (_isListarMode) return "LIST MODE";
    if (_isMarketingMode) return "MARKETING MODE";
    return "FREE";
  }

  void _inicializarConfiguracoes() {
    try {
      // Garante que o controller comece limpo ou com dados iniciais
      _rimasController.atualizarGamificacao(0);
    } catch (e) {
      debugPrint("Erro setup inicial: $e");
    }
  }

  Widget _buildStatusBadge() {
    return ListenableBuilder(
      listenable: _rimasController,
      builder: (context, child) {
        bool anyMode = _isRhymeMode || _isComporMode || _isListarMode || _isMarketingMode;
        String statusText = anyMode ? _getActiveStatusText() : "FREE";
        Color statusColor = anyMode ? _getActiveColor() : Colors.purpleAccent;

        final key = _rimasController.userApiKey;
        if (!anyMode && key != null && key.isNotEmpty && !key.contains("FREE")) {
          statusText = "API PRIVADA";
          statusColor = Colors.greenAccent;
        }

        return Text(
          statusText,
          style: TextStyle(
            color: statusColor.withOpacity(0.8),
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

        Timer(const Duration(seconds: 3), () {
          if (mounted && messages.length == 1) {
            setState(() {
              messages.add({
                "role": "assistant",
                "content": "Salve! Sou o Versin, seu mentor de composição. 🎤\n\nEscolha um estilo: **Trap**, **Funk**, **Emotrap**, **Rap**."
              });
            });
            _scrollToBottom();

            Timer(const Duration(seconds: 3), () {
              if (mounted && messages.length == 2) {
                setState(() {
                  _isAiTyping = false; 
                  messages.add({
                    "role": "assistant",
                    "content": "Mande um resumo do que você está sentindo (mínimo **10 linhas**) para organizarmos as ideias."
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
    _hideTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && _rimasController.listaSugestoes.isNotEmpty) {
        _rimasController.limparSugestao();
        _currentSuggestionIndex = 0;
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

  void _resetModes() {
    setState(() {
      _isRhymeMode = false;
      _isComporMode = false;
      _isListarMode = false;
      _isMarketingMode = false;
    });
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // COMANDOS DE MODO
    if (text.startsWith("/desligarmodo")) {
      _resetModes();
      _addSystemMessage("> **SISTEMA RESETADO.** Voltando ao modo padrão.");
      return;
    }

    if (text.toLowerCase() == "/modorima") {
      _resetModes();
      setState(() => _isRhymeMode = true);
      _addSystemMessage("> **MODO RIMA ATIVADO.**\n\nFoco em fonética e rimas multissilábicas.");
      return;
    }

    if (text.toLowerCase() == "/modocompor") {
      _resetModes();
      setState(() => _isComporMode = true);
      _addSystemMessage("> **MODO COMPOR ATIVADO.**\n\nAnálise de estrutura e storytelling.");
      return;
    }

    if (text.toLowerCase() == "/modolistar") {
      _resetModes();
      setState(() => _isListarMode = true);
      _addSystemMessage("> **MODO LISTAR ATIVADO.**\n\nVerificando biblioteca de rimas salvas...");
      return;
    }

    if (text.startsWith("/list")) {
      final conteudo = text.replaceFirst("/list", "").trim();
      final rimas = conteudo.split(RegExp(r'[,,;]')); 
      for (var rima in rimas) {
        if (rima.trim().isNotEmpty) {
          _rimasController.adicionarPalavra(rima.trim(), true);
        }
      }
      _messageController.clear();
      // Notifica o Drawer que a lista mudou
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

  void _addSystemMessage(String content) {
    setState(() {
      messages.add({"role": "assistant", "content": content});
      _messageController.clear();
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final activeColor = _getActiveColor();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF0F0F0F),
      // CORREÇÃO: Passando a instância que contém os dados reais para o Drawer
      drawer: VersinDrawer(
        rimasController: _rimasController, 
        onNewChat: () {
          setState(() {
            messages.clear();
            _isAiTyping = false;
            _resetModes();
            _rimasController.atualizarGamificacao(0);
          });
          _iniciarFluxoBemVindo();
        },
      ),
      body: Stack(
        children: [
          Positioned(
            top: 50, left: 0, right: 0,
            child: Column(
              children: [
                Text("Versin", style: TextStyle(color: activeColor.withOpacity(0.8), fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2)),
                const SizedBox(height: 2),
                _buildStatusBadge(),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ListenableBuilder(
                    listenable: _rimasController,
                    builder: (context, _) => TermometroFeedback(
                      progressoEstrelas: _rimasController.progressoEstrelas,
                      progressoFogos: _rimasController.progressoFogos,
                      feedbackMentor: _rimasController.feedbackMentor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 45, left: 15,
            child: IconButton(
              icon: Icon(Icons.menu_rounded, color: activeColor, size: 32), 
              onPressed: () => _scaffoldKey.currentState?.openDrawer()
            ),
          ),
          Positioned.fill(
            top: 190, bottom: 140 + bottomPadding, 
            child: messages.isEmpty ? const ChatWelcomeCard() : _buildMessageList(),
          ),
          Positioned(
            bottom: bottomPadding + 15,
            left: 15, right: 15,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListenableBuilder(
                  listenable: _rimasController,
                  builder: (context, child) {
                    final rimas = _rimasController.listaSugestoes;
                    if (rimas.isNotEmpty) _startHideTimer();
                    
                    return AnimatedOpacity(
                      opacity: (rimas.isNotEmpty || _rimasController.carregando) ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: (rimas.isNotEmpty || _rimasController.carregando) 
                        ? AiSuggestionBalloon(
                            suggestion: _rimasController.carregando ? "..." : rimas[_currentSuggestionIndex],
                            isLoading: _rimasController.carregando,
                            onDismiss: () => _rimasController.removerSugestaoDaLista(rimas[_currentSuggestionIndex]),
                            onNext: rimas.length > 1 ? () => setState(() => _currentSuggestionIndex = (_currentSuggestionIndex + 1) % rimas.length) : null,
                            onPrevious: rimas.length > 1 ? () => setState(() => _currentSuggestionIndex = (_currentSuggestionIndex - 1 + rimas.length) % rimas.length) : null,
                            onTap: () {
                              final rima = rimas[_currentSuggestionIndex];
                              final text = _messageController.text;
                              _messageController.text = "$text $rima ".trimLeft();
                              _messageController.selection = TextSelection.fromPosition(TextPosition(offset: _messageController.text.length));
                              _rimasController.registrarRimaUsada(rima);
                            },
                          )
                        : const SizedBox.shrink(),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _buildInputArea(activeColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(Color activeColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A), 
        borderRadius: BorderRadius.circular(22), 
        border: Border.all(color: activeColor.withOpacity(0.3))
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              keyboardType: TextInputType.multiline,
              maxLines: 5, minLines: 1,
              style: TextStyle(color: activeColor, fontSize: 16),
              decoration: InputDecoration(
                hintText: _isRhymeMode ? "Buscar rima..." : "Manda o sentimento...", 
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 15), 
                border: InputBorder.none, 
                contentPadding: const EdgeInsets.symmetric(vertical: 12)
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send_rounded, color: activeColor),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    final activeColor = _getActiveColor();
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: messages.length + (_isAiTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == messages.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Row(children: [SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: activeColor)), const SizedBox(width: 10), Text("Versin analisando...", style: TextStyle(color: activeColor.withOpacity(0.7), fontSize: 13))]),
          );
        }

        final message = messages[index];
        final isUser = message['role'] == 'user';
        final content = message['content'] ?? "";

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
              ? Text(content, style: const TextStyle(color: Colors.white, fontSize: 15))
              : MarkdownBody(
                  data: content,
                  styleSheet: MarkdownStyleSheet(
                    p: TextStyle(color: activeColor.withOpacity(0.9), fontSize: 16, fontFamily: 'monospace'),
                    strong: TextStyle(color: activeColor, fontWeight: FontWeight.bold),
                  ),
                ),
          ),
        );
      },
    );
  }
}