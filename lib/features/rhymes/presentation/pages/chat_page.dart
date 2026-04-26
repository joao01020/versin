import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:versin/features/rhymes/presentation/widgets/chat/welcome_card/chat_welcome_card.dart';
import 'package:versin/features/rhymes/presentation/widgets/versin_drawer/versin_drawer.dart';
import 'package:versin/features/rhymes/presentation/widgets/ai_suggestion/ai_suggestion_balloon.dart';
import 'package:versin/features/rhymes/presentation/controller/rhymes_controller.dart';
import 'package:versin/features/rhymes/presentation/widgets/thermometer_gamification/thermometer_widget.dart';
import 'package:versin/features/rhymes/presentation/widgets/chat/chat_input_area.dart';
import 'package:versin/features/rhymes/presentation/widgets/chat/chat_message_bubble.dart';
import 'package:versin/features/rhymes/presentation/utils/command_handler.dart'; 

import 'package:versin/features/rhymes/presentation/pages/components/terminal_mode/chat_header.dart';
import 'package:versin/features/rhymes/presentation/pages/components/chat/chat_list_view.dart';
import 'package:versin/features/rhymes/presentation/pages/components/chat_command_overlay/chat_command_overlay.dart';
import 'package:versin/features/rhymes/presentation/pages/components/chat/chat_bottom_bar.dart';
import 'package:versin/features/rhymes/presentation/pages/components/chat_initializer/chat_initializer.dart';
import 'package:versin/features/rhymes/presentation/pages/components/auth_modal/auth_modal.dart';

import 'package:versin/features/rhymes/data/datasources/supabase_storage_service.dart';
import 'package:versin/features/rhymes/data/datasources/user/user_service.dart';

// Importações dos novos componentes de responsabilidade
import 'package:versin/features/rhymes/presentation/pages/components/timeline/versin_timeline.dart';
import 'package:versin/features/rhymes/data/datasources/utils/hash_helper.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();
  final RhymesController _rhymesController = RhymesController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  
  final SupabaseStorageService _storageService = SupabaseStorageService();
  final UserService _userService = UserService();
  
  late CommandHandler _commandHandler; 
  Timer? _authModalTimer; 
  StreamSubscription<AuthState>? _authSubscription; 
  
  List<Map<String, dynamic>> messages = [];
  bool _isAiTyping = false; 
  bool _isInitializing = true; 
  bool _showCommandMenu = false;

  bool _isRhymeMode = false;
  bool _isComposeMode = false;
  bool _isListMode = false;
  bool _isMarketingMode = false;
  int _currentSuggestionIndex = 0;

  // LÓGICA DE PROGRESSÃO REAL VERSIN
  int _currentStep = 1; 
  double _stepProgress = 0.0;
  final String _currentUsername = "joao01020";
  final String _userWallet = "0x7a...versin"; // Exemplo vindo do perfil

  // NOVO: Lista para armazenar as palavras reais do banco
  List<Map<String, dynamic>> _trendingWords = [];

  @override
  void initState() {
    super.initState();
    
    _commandHandler = CommandHandler(
      rhymesController: _rhymesController,
      onSystemMessage: _addSystemMessage,
      onClearChat: () => setState(() => messages.clear()),
      onUpdateModes: ({rhyme, compose, list, marketing}) {
        setState(() {
          if (rhyme != null) _isRhymeMode = rhyme;
          if (compose != null) _isComposeMode = compose;
          if (list != null) _isListMode = list;
          if (marketing != null) _isMarketingMode = marketing;
        });
      },
    );

    _rhymesController.updateGamification(0);
    _setupMessageListener();
    _checkInitialSession();
    _setupAuthListener(); 
    
    // NOVO: Carregar dados reais antes de liberar o initializer
    _loadInitialData();

    _startAuthTimer();
  }

  // NOVO: Busca dados reais para o Ponto 1 do ranking global
  Future<void> _loadInitialData() async {
    final words = await _rhymesController.fetchTrendingWords();
    if (mounted) {
      setState(() {
        _trendingWords = words;
      });
      
      ChatInitializer.run(
        mounted: mounted,
        onLoadingStatusChanged: (status) => setState(() => _isInitializing = status),
        onStartWelcomeFlow: _startWelcomeFlow,
      );
    }
  }

  void _checkInitialSession() {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      _authModalTimer?.cancel();
      _rhymesController.carregarDadosUsuario();
    }
  }

  void _setupAuthListener() {
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;

      if (event == AuthChangeEvent.signedIn && session != null) {
        _authModalTimer?.cancel(); 
        _rhymesController.carregarDadosUsuario();

        if (mounted) {
           Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
        }
        _showProfileSetupModal(); 
      }
      
      if (event == AuthChangeEvent.signedOut) {
        _startAuthTimer(); 
      }
    });
  }

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
            const Text("Autenticação concluída!", style: TextStyle(color: Colors.grey, fontSize: 14)),
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

  void _startAuthTimer() {
    _authModalTimer?.cancel(); 
    _authModalTimer = Timer(const Duration(seconds: 35), () {
      if (!mounted) return;
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        AuthModal.show(context);
      }
    });
  }

  void _startWelcomeFlow() {
    ChatInitializer.welcomeFlow(
      mounted: mounted,
      messages: messages,
      addMessage: (content, {Widget? customWidget}) => setState(() {
        messages.add({"role": "assistant", "content": content, "customWidget": customWidget});
      }),
      setAiTyping: (typing) => setState(() => _isAiTyping = typing),
      scrollToBottom: _scrollToBottom,
      userRhymes: _rhymesController.vocabulary.map((e) => e.word.toString()).toList(), 
      onProgressUpdate: (step, progress) => setState(() {
        _currentStep = step;
        _stepProgress = progress;
      }),
      // ATUALIZADO: Passando os parâmetros que faltavam para dados reais
      globalTrendingWords: _trendingWords,
      onWordSelected: (word) {
        _rhymesController.incrementWordScore(word);
      },
    );
  }

  void _setupMessageListener() {
    _messageController.addListener(() {
      final text = _messageController.text;
      setState(() => _showCommandMenu = text.startsWith("/"));
      
      // MONITORAMENTO REAL PONTO 2: EXPRESSÃO (MÍNIMO 5 LINHAS)
      if (_currentStep == 2) {
        int lines = text.split('\n').where((l) => l.trim().isNotEmpty).length;
        double progress = (lines / 5).clamp(0.0, 1.0);
        setState(() => _stepProgress = progress);
        
        if (progress >= 1.0) {
          _completeStep(2); // Avança para o Ponto 3 (Flow)
        }
      }

      _rhymesController.onTextChanged(text);
    });
  }

  void _completeStep(int step) {
    setState(() {
      _currentStep = step + 1;
      _stepProgress = 0.0;
    });
    
    if (_currentStep == 4) {
      ChatInitializer.startStructureStep(
        addMessage: _addAiMessageWithWidget,
        onProgressUpdate: (s, p) => setState(() { _currentStep = s; _stepProgress = p; }),
        scrollToBottom: _scrollToBottom,
        activeColor: _getActiveColor(),
      );
    }
  }

  void _addAiMessageWithWidget(String content, {Widget? customWidget}) {
    setState(() => messages.add({"role": "assistant", "content": content, "customWidget": customWidget}));
    _scrollToBottom();
  }

  void _onAddSuggestedRhyme(String word) async {
    final completedWord = await _rhymesController.addSuggestedRhyme(word);
    if (completedWord != null) {
      setState(() {
        _messageController.text = "${_messageController.text.trim()} $completedWord ";
        _messageController.selection = TextSelection.fromPosition(TextPosition(offset: _messageController.text.length));
      });
    }
  }

  Color _getActiveColor() {
    if (_isRhymeMode) return Colors.greenAccent;
    if (_isComposeMode) return Colors.blueAccent;
    if (_isListMode) return Colors.orangeAccent;
    if (_isMarketingMode) return Colors.yellowAccent;
    return Colors.purpleAccent;
  }

  // BOTÃO DE FINALIZAÇÃO E GERAÇÃO DE HASH (PONTO 6)
  void _finalizeLyric() {
    final fullLyric = messages.where((m) => m['role'] == 'user').map((m) => m['content']).join("\n");
    final lyricHash = HashHelper.generateVersinHash(
      lyric: fullLyric,
      userWallet: _userWallet,
      username: _currentUsername,
    );

    setState(() {
      _currentStep = 6;
      _stepProgress = 1.0;
    });

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F0F0F),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_user, color: Colors.greenAccent, size: 60),
            const SizedBox(height: 16),
            const Text("LETRA FINALIZADA", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Hash de Autoria: ${HashHelper.formatShortHash(lyricHash)}", style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white10),
                    onPressed: () {}, 
                    icon: const Icon(Icons.share, color: Colors.white),
                    label: const Text("COMPARTILHAR", style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent),
                    onPressed: () {
                      _storageService.saveLyric(fullLyric, lyricHash);
                      Navigator.pop(context);
                      _addSystemMessage("✅ Letra salva e assinada no Versin Genesis.");
                    },
                    icon: const Icon(Icons.save, color: Colors.black),
                    label: const Text("SALVAR", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    if (_commandHandler.handle(text)) {
      _messageController.clear();
      setState(() => _showCommandMenu = false);
      return;
    }

    setState(() {
      messages.add({"role": "user", "content": text});
      _messageController.clear();
      _isAiTyping = true;
    });
    _scrollToBottom();

    final aiResponse = await _rhymesController.fetchAiResponse(text);

    if (mounted) {
      setState(() { _isAiTyping = false; messages.add(aiResponse); });
      _scrollToBottom();
      // Se estiver no ponto 5, preenche conforme a IA sugere caminhos
      if (_currentStep == 5) setState(() => _stepProgress += 0.2);
    }
  }

  void _addSystemMessage(String content) {
    setState(() => messages.add({"role": "assistant", "content": content}));
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
        rhymesController: _rhymesController, 
        onNewChat: () {
          setState(() { 
            messages.clear(); 
            _currentStep = 1; _stepProgress = 0.0;
          });
          _startWelcomeFlow();
        }
      ),
      body: Stack(
        children: [
          Positioned(
            top: 40, left: 0, right: 0,
            child: VersinTimeline(
              currentStep: _currentStep,
              stepProgress: _stepProgress,
              activeColor: activeColor,
            ),
          ),
          Positioned(
            top: 100, left: 0, right: 0,
            child: ChatHeader(
              activeColor: activeColor,
              rhymesController: _rhymesController, 
              isRhymeMode: _isRhymeMode,
              isComposeMode: _isComposeMode,
              isListMode: _isListMode,
              isMarketingMode: _isMarketingMode,
            ),
          ),
          Positioned(
            top: 95, left: 15,
            child: IconButton(
              icon: Icon(Icons.menu_rounded, color: activeColor, size: 32),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
          ),
          Positioned.fill(
            top: 240, bottom: 140 + bottomPadding, 
            child: ChatListView(
              isInitializing: _isInitializing,
              messages: messages,
              isAiTyping: _isAiTyping,
              scrollController: _scrollController,
              activeColor: activeColor,
            ),
          ),
          // BOTÃO DE FINALIZAÇÃO DINÂMICO (APARECE NO PONTO 5/6)
          if (_currentStep >= 5)
            Positioned(
              bottom: bottomPadding + 110, right: 20,
              child: FloatingActionButton.extended(
                backgroundColor: Colors.greenAccent,
                onPressed: _finalizeLyric,
                label: const Text("FINALIZAR", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                icon: const Icon(Icons.check_circle, color: Colors.black),
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
                  rhymesController: _rhymesController, 
                  activeColor: activeColor,
                  isRhymeMode: _isRhymeMode,
                  onSend: _sendMessage,
                  currentSuggestionIndex: _currentSuggestionIndex,
                  onUpdateSuggestionIndex: (index) => setState(() => _currentSuggestionIndex = index),
                  onAddRhyme: _onAddSuggestedRhyme, 
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
    _rhymesController.dispose(); 
    _scrollController.dispose();
    super.dispose();
  }
}