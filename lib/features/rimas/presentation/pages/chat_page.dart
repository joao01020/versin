import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Import necessário para verificar sessão
import 'package:versin/features/rimas/presentation/widgets/chat_welcome_card.dart';
import 'package:versin/features/rimas/presentation/widgets/versin_drawer.dart';
import 'package:versin/features/rimas/presentation/widgets/ai_suggestion/ai_suggestion_balloon.dart';
import 'package:versin/features/rimas/presentation/controller/rimas_controller.dart';
import 'package:versin/features/rimas/presentation/widgets/thermometer_gamification/thermometer_widget.dart';
import 'package:versin/features/rimas/presentation/widgets/chat_input_area.dart';
import 'package:versin/features/rimas/presentation/widgets/chat_message_bubble.dart';
import 'package:versin/features/rimas/presentation/utils/command_handler.dart'; 

// Importações dos novos componentes modulares
import 'package:versin/features/rimas/presentation/pages/components/modosterminal/chat_header.dart';
import 'package:versin/features/rimas/presentation/pages/components/chat_list_view.dart';
import 'package:versin/features/rimas/presentation/pages/components/chat_command_overlay/chat_command_overlay.dart';
import 'package:versin/features/rimas/presentation/pages/components/chat_bottom_bar.dart';
// Import do novo componente de inicialização
import 'package:versin/features/rimas/presentation/pages/components/chat_initializer/chat_initializer.dart';
// Import Modular do Modal de Autenticação
import 'package:versin/features/rimas/presentation/pages/components/auth_modal/auth_modal.dart';

// NOVOS IMPORTS DE STORAGE E USUÁRIO (Caminhos definitivos)
import 'package:versin/features/rimas/data/datasources/supabase_storage_service.dart';
import 'package:versin/features/rimas/data/datasources/user/user_service.dart';

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
  
  // Instâncias dos Services de Dados
  final SupabaseStorageService _storageService = SupabaseStorageService();
  final UserService _userService = UserService();
  
  late CommandHandler _commandHandler; 
  Timer? _authModalTimer; // Timer para o modal modular
  StreamSubscription<AuthState>? _authSubscription; // Escuta o login em tempo real
  
  List<Map<String, String>> messages = [];
  bool _isAiTyping = false; 
  bool _isInitializing = true; 
  bool _showCommandMenu = false;

  bool _isRhymeMode = false;
  bool _isComporMode = false;
  bool _isListarMode = false;
  bool _isMarketingMode = false;
  int _currentSuggestionIndex = 0;

  // Nome do usuário logado (ex: joao01020)
  final String _currentUsername = "joao01020"; 

  @override
  void initState() {
    super.initState();
    
    _commandHandler = CommandHandler(
      rimasController: _rimasController,
      onSystemMessage: _addSystemMessage,
      onClearChat: () => setState(() => messages.clear()),
      onUpdateModes: ({rhyme, compor, listar, marketing}) {
        setState(() {
          if (rhyme != null) _isRhymeMode = rhyme;
          if (compor != null) _isComporMode = compor;
          if (listar != null) _isListarMode = listar;
          if (marketing != null) _isMarketingMode = marketing;
        });
      },
    );

    _rimasController.atualizarGamificacao(0);
    _setupMessageListener();
    
    // Verificação de sessão existente e escuta de eventos
    _checkInitialSession();
    _setupAuthListener(); 
    
    // CHAMADA DA INICIALIZAÇÃO EXTERNA
    ChatInitializer.run(
      mounted: mounted,
      onLoadingStatusChanged: (status) => setState(() => _isInitializing = status),
      onStartWelcomeFlow: _iniciarFluxoBemVindo,
    );

    // DISPARO DO TIMER INTELIGENTE (35 Segundos)
    _startAuthTimer();
  }

  // Verifica se já existe um usuário logado ao abrir a página
  void _checkInitialSession() {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      _authModalTimer?.cancel();
    }
  }

  // Escuta mudanças de autenticação (Deep Link do e-mail)
  void _setupAuthListener() {
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;

      if (event == AuthChangeEvent.signedIn && session != null) {
        _authModalTimer?.cancel(); 
        // Remove qualquer modal aberto (AuthModal ou AuthOptionsModal)
        if (mounted && Navigator.canPop(context)) {
          Navigator.of(context, rootNavigator: true).pop();
        }
        _showProfileSetupModal(); // Abre o formulário de Username/Carteira
      }
    });
  }

  // Modal automático para novos usuários autenticados via Magic Link
  void _showProfileSetupModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF121212),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.purpleAccent, width: 0.5)),
        title: const Text("VERSIN GENESIS: PERFIL", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Autenticação concluída! Defina seu usuário e carteira para registrar suas rimas.", style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 20),
            TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(labelText: "Username", labelStyle: const TextStyle(color: Colors.purpleAccent), filled: true, fillColor: Colors.white10, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
            ),
            const SizedBox(height: 12),
            TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(labelText: "Carteira (0x...)", labelStyle: const TextStyle(color: Colors.purpleAccent), filled: true, fillColor: Colors.white10, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent),
            onPressed: () => Navigator.pop(context),
            child: const Text("SALVAR PERFIL", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  // Lógica modular: Verifica se o usuário está logado antes de exibir
  void _startAuthTimer() {
    _authModalTimer = Timer(const Duration(seconds: 35), () {
      if (!mounted) return;

      final currentUser = Supabase.instance.client.auth.currentUser;
      
      if (currentUser == null) {
        AuthModal.show(context);
      }
    });
  }

  void _iniciarFluxoBemVindo() {
    ChatInitializer.welcomeFlow(
      mounted: mounted,
      messages: messages,
      addMessage: (content) => setState(() => messages.add({"role": "assistant", "content": content})),
      setAiTyping: (typing) => setState(() => _isAiTyping = typing),
      scrollToBottom: _scrollToBottom,
    );
  }

  void _setupMessageListener() {
    _messageController.addListener(() {
      final text = _messageController.text;
      setState(() => _showCommandMenu = text.startsWith("/"));
      if (text.isNotEmpty && text.endsWith(" ")) {
        final words = text.trim().split(" ");
        if (words.isNotEmpty && words.last.length > 2) {
          _rimasController.buscarSugestao(words.last);
        }
      }
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

  void _favoritarUltimaResposta() async {
    if (messages.length >= 2) {
      final lastUserQuery = messages[messages.length - 2]['content'] ?? "";
      final lastAiResponse = messages.last['content'] ?? "";
      
      await _userService.saveToFavorites(_currentUsername, lastUserQuery, lastAiResponse);
      _addSystemMessage("⭐ Rima favoritada no seu histórico do Versin Genesis.");
    }
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    if (text == "/fav") {
      _favoritarUltimaResposta();
      _messageController.clear();
      return;
    }

    if (_commandHandler.handle(text)) {
      _messageController.clear();
      setState(() => _showCommandMenu = false);
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
      setState(() { _isAiTyping = false; messages.add(aiResponse); });
      _scrollToBottom();
    }
  }

  void _addSystemMessage(String content) {
    setState(() => messages.add({"role": "assistant", "content": content}));
    _messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, 
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = _getActiveColor();
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF0F0F0F),
      drawer: VersinDrawer(
        rimasController: _rimasController, 
        onNewChat: () {
          setState(() { 
            messages.clear(); 
            _isRhymeMode = false; _isComporMode = false; 
            _isListarMode = false; _isMarketingMode = false;
            _isInitializing = false; 
            _rimasController.atualizarGamificacao(0);
          });
          _iniciarFluxoBemVindo();
        }
      ),
      body: Stack(
        children: [
          Positioned(
            top: 50, left: 0, right: 0,
            child: ChatHeader(
              activeColor: activeColor,
              rimasController: _rimasController,
              isRhymeMode: _isRhymeMode,
              isComporMode: _isComporMode,
              isListarMode: _isListarMode,
              isMarketingMode: _isMarketingMode,
            ),
          ),
          Positioned(
            top: 45, left: 15,
            child: IconButton(
              icon: Icon(Icons.menu_rounded, color: activeColor, size: 32),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
          ),
          Positioned.fill(
            top: 190, bottom: 140 + bottomPadding, 
            child: ChatListView(
              isInitializing: _isInitializing,
              messages: messages,
              isAiTyping: _isAiTyping,
              scrollController: _scrollController,
              activeColor: activeColor,
            ),
          ),
          Positioned(
            bottom: bottomPadding + 15, left: 15, right: 15,
            child: Column(
              children: [
                if (_showCommandMenu) ChatCommandOverlay(
                  commandHandler: _commandHandler,
                  activeColor: activeColor,
                  onCommandSelected: (cmd) {
                    _messageController.text = cmd;
                    _sendMessage();
                  },
                ),
                ChatBottomBar(
                  messageController: _messageController,
                  rimasController: _rimasController,
                  activeColor: activeColor,
                  isRhymeMode: _isRhymeMode,
                  onSend: _sendMessage,
                  currentSuggestionIndex: _currentSuggestionIndex,
                  onUpdateSuggestionIndex: (index) => setState(() => _currentSuggestionIndex = index),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _authModalTimer?.cancel();
    _messageController.dispose(); 
    _rimasController.dispose(); 
    _scrollController.dispose();
    super.dispose();
  }
}