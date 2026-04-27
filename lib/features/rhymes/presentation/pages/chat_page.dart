import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Widgets e Componentes de UI
import 'package:versin/features/rhymes/presentation/widgets/versin_drawer/versin_drawer.dart';
import 'package:versin/features/rhymes/presentation/pages/components/terminal_mode/chat_header.dart';
import 'package:versin/features/rhymes/presentation/pages/components/chat/chat_list_view.dart';
import 'package:versin/features/rhymes/presentation/pages/components/chat_command_overlay/chat_command_overlay.dart';
import 'package:versin/features/rhymes/presentation/pages/components/chat/chat_bottom_bar.dart';
import 'package:versin/features/rhymes/presentation/pages/components/chat_initializer/chat_initializer.dart';
import 'package:versin/features/rhymes/presentation/pages/components/auth_modal/auth_modal.dart';
import 'package:versin/features/rhymes/presentation/pages/components/timeline/versin_timeline.dart';

// Controladores e Lógica de Negócio
import 'package:versin/features/rhymes/presentation/controller/rhymes_controller.dart';
import 'package:versin/features/rhymes/presentation/utils/command_handler.dart'; 

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  // --- CONTROLLERS ---
  final _messageController = TextEditingController();
  final RhymesController _rhymesController = RhymesController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  
  // --- STATE VARIABLES ---
  late CommandHandler _commandHandler; 
  Timer? _authModalTimer; 
  StreamSubscription<AuthState>? _authSubscription; 
  
  List<Map<String, dynamic>> messages = [];
  bool _isAiTyping = false; 
  bool _isInitializing = true; 
  bool _showCommandMenu = false;
  int _currentSuggestionIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeLogic();
    _setupListeners();
    _checkInitialSession();
    _setupAuthListener(); 
    _loadInitialData();
    _startAuthTimer();
  }

  void _initializeLogic() {
    _commandHandler = CommandHandler(
      rhymesController: _rhymesController,
      onSystemMessage: _addSystemMessage,
      onClearChat: () => setState(() => messages.clear()),
      onUpdateModes: ({rhyme, compose, list, marketing}) {
        _rhymesController.updateModes(
          rhyme: rhyme, compose: compose, list: list, marketing: marketing
        );
        setState(() {}); // Atualiza a UI com as novas cores/modos do controller
      },
    );
    _rhymesController.updateGamification(0);
  }

  void _setupListeners() {
    _messageController.addListener(() {
      final text = _messageController.text;
      setState(() => _showCommandMenu = text.startsWith("/"));
      
      if (_rhymesController.currentStep == 2) {
        int lines = text.split('\n').where((l) => l.trim().isNotEmpty).length;
        double progress = (lines / 5).clamp(0.0, 1.0);
        _rhymesController.updateProgress(2, progress);
        if (progress >= 1.0) _completeStep(2); 
      }
      _rhymesController.onTextChanged(text);
    });
  }

  Future<void> _loadInitialData() async {
    await _rhymesController.fetchTrendingWords();
    if (mounted) {
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
      if (data.event == AuthChangeEvent.signedIn && data.session != null) {
        _authModalTimer?.cancel(); 
        _rhymesController.carregarDadosUsuario();
        if (mounted) Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
        // O feedback de sucesso agora é gerenciado internamente pelo AuthModal
      }
      if (data.event == AuthChangeEvent.signedOut) _startAuthTimer();
    });
  }

  void _startAuthTimer() {
    _authModalTimer?.cancel(); 
    _authModalTimer = Timer(const Duration(seconds: 35), () {
      if (!mounted) return;
      if (Supabase.instance.client.auth.currentUser == null) AuthModal.show(context);
    });
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
      if (_rhymesController.currentStep == 5) {
        _rhymesController.updateProgress(5, _rhymesController.stepProgress + 0.2);
      }
    }
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
      onProgressUpdate: (step, progress) => _rhymesController.updateProgress(step, progress),
      globalTrendingWords: _rhymesController.trendingWords,
      onWordSelected: (word) => _rhymesController.incrementWordScore(word),
    );
  }

  void _completeStep(int step) {
    _rhymesController.updateProgress(step + 1, 0.0);
    if (_rhymesController.currentStep == 4) {
      ChatInitializer.startStructureStep(
        addMessage: _addAiMessageWithWidget,
        onProgressUpdate: (s, p) => _rhymesController.updateProgress(s, p),
        scrollToBottom: _scrollToBottom,
        activeColor: _rhymesController.getActiveColor(),
      );
    }
  }

  void _addAiMessageWithWidget(String content, {Widget? customWidget}) {
    setState(() => messages.add({"role": "assistant", "content": content, "customWidget": customWidget}));
    _scrollToBottom();
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
    final activeColor = _rhymesController.getActiveColor();
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF0F0F0F),
      drawer: VersinDrawer(
        rhymesController: _rhymesController, 
        onNewChat: () {
          setState(() => messages.clear());
          _rhymesController.updateProgress(1, 0.0);
          _startWelcomeFlow();
        }
      ),
      body: Stack(
        children: [
          Positioned(top: 40, left: 0, right: 0,
            child: VersinTimeline(
              currentStep: _rhymesController.currentStep, 
              stepProgress: _rhymesController.stepProgress, 
              activeColor: activeColor
            ),
          ),
          Positioned(top: 100, left: 0, right: 0,
            child: ChatHeader(
              activeColor: activeColor, 
              rhymesController: _rhymesController, 
              isRhymeMode: _rhymesController.isRhymeMode, 
              isComposeMode: _rhymesController.isComposeMode,
              isListMode: _rhymesController.isListMode, 
              isMarketingMode: _rhymesController.isMarketingMode,
            ),
          ),
          Positioned(top: 95, left: 15,
            child: IconButton(icon: Icon(Icons.menu_rounded, color: activeColor, size: 32),
              onPressed: () => _scaffoldKey.currentState?.openDrawer()),
          ),
          Positioned.fill(top: 240, bottom: 140 + bottomPadding, 
            child: ChatListView(
              isInitializing: _isInitializing, messages: messages,
              isAiTyping: _isAiTyping, scrollController: _scrollController,
              activeColor: activeColor,
            ),
          ),
          Positioned(bottom: bottomPadding + 15, left: 15, right: 15,
            child: Column(
              children: [
                if (_showCommandMenu) ChatCommandOverlay(
                  commandHandler: _commandHandler, activeColor: activeColor,
                  onCommandSelected: (cmd) { _messageController.text = cmd; _sendMessage(); },
                ),
                ChatBottomBar(
                  messageController: _messageController, rhymesController: _rhymesController, 
                  activeColor: activeColor, isRhymeMode: _rhymesController.isRhymeMode, onSend: _sendMessage,
                  currentSuggestionIndex: _currentSuggestionIndex,
                  onUpdateSuggestionIndex: (index) => setState(() => _currentSuggestionIndex = index),
                  onAddRhyme: (word) async {
                    final completed = await _rhymesController.addSuggestedRhyme(word);
                    if (completed != null) {
                      setState(() {
                        _messageController.text = "${_messageController.text.trim()} $completed ";
                        _messageController.selection = TextSelection.fromPosition(
                          TextPosition(offset: _messageController.text.length)
                        );
                      });
                    }
                  }, 
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