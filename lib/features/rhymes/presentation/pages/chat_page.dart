import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:versin/features/rhymes/presentation/widgets/versin_drawer/versin_drawer.dart';
import 'package:versin/features/rhymes/presentation/pages/components/header/chat_header.dart';
import 'package:versin/features/rhymes/presentation/pages/components/chat/chat_list_view.dart';
import 'package:versin/features/rhymes/presentation/pages/components/chat/chat_bottom_bar.dart';
import 'package:versin/features/rhymes/presentation/pages/components/chat_initializer/chat_initializer.dart';
import 'package:versin/features/rhymes/presentation/pages/components/auth_modal/auth_modal.dart';
import 'package:versin/features/rhymes/presentation/pages/components/timeline/versin_timeline.dart';
import 'package:versin/features/rhymes/presentation/controller/rhymes_controller.dart';

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
  
  Timer? _authModalTimer; 
  StreamSubscription<AuthState>? _authSubscription; 
  
  List<Map<String, dynamic>> messages = [];
  bool _isAiTyping = false; 
  bool _isInitializing = true; 
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
    
    // Wake up do servidor (Keep-alive inicial)
    _rhymesController.fetchTrendingWords(); 
  }

  void _initializeLogic() {
    _rhymesController.updateGamification(0.0);
    _rhymesController.addListener(_handleControllerChanges);
  }

  void _handleControllerChanges() {
    if (mounted) setState(() {});
  }

  void _setupListeners() {
    _messageController.addListener(() {
      final text = _messageController.text;
      _rhymesController.onTextChanged(text); 
      
      if (_rhymesController.currentStep == 2) {
        int lines = text.split('\n').where((l) => l.trim().isNotEmpty).length;
        double progress = (lines / 5).clamp(0.0, 1.0);
        _rhymesController.updateProgress(2, progress);
        if (progress >= 1.0) _completeStep(2); 
      }
    });
  }

  Future<void> _loadInitialData() async {
    await _rhymesController.carregarDadosUsuario();
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
    if (session != null) _authModalTimer?.cancel();
  }

  void _setupAuthListener() {
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn && data.session != null) {
        _authModalTimer?.cancel(); 
        _rhymesController.carregarDadosUsuario();
      }
      if (data.event == AuthChangeEvent.signedOut) _startAuthTimer();
    });
  }

  void _startAuthTimer() {
    _authModalTimer?.cancel(); 
    _authModalTimer = Timer(const Duration(seconds: 45), () {
      if (!mounted) return;
      if (Supabase.instance.client.auth.currentUser == null) AuthModal.show(context);
    });
  }

  // Função centralizada para processar mensagens e gatilhos de IA
  void _processMessage(String text) async {
    if (text.isEmpty) return;

    setState(() {
      messages.add({"role": "user", "content": text});
      _isAiTyping = true; 
    });
    
    _scrollToBottom();

    final response = await _rhymesController.fetchAiResponse(text);

    if (mounted) {
      setState(() {
        messages.add(response);
        _isAiTyping = false; 
      });
      _scrollToBottom();
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    _processMessage(text);
    _messageController.clear();
  }

  void _startWelcomeFlow() {
    ChatInitializer.welcomeFlow(
      mounted: mounted,
      messages: messages,
      // Agora permitimos que o customWidget (BPM/Chips) seja renderizado
      addMessage: (content, {Widget? customWidget}) => setState(() {
        messages.add({
          "role": "assistant", 
          "content": content, 
          "customWidget": customWidget 
        });
      }),
      setAiTyping: (typing) => setState(() => _isAiTyping = typing),
      scrollToBottom: _scrollToBottom,
      onProgressUpdate: (step, progress) => _rhymesController.updateProgress(step, progress),
      activeColor: _rhymesController.getActiveColor(),
      // Quando o usuário clica em "Confirmar Estúdio" no início:
      onStructureConfirmed: (configEstudio) {
        _processMessage("Configuração do Estúdio: $configEstudio. Agora, me diga o tema da sua letra.");
      },
    );
  }

  void _completeStep(int step) {
    _rhymesController.updateProgress(step + 1, 0.0);
    // Lógica para passos manuais se necessário futuramente
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent, 
          duration: const Duration(milliseconds: 400), 
          curve: Curves.easeOut
        );
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
          // Timeline Superior
          Positioned(top: 40, left: 0, right: 0,
            child: VersinTimeline(
              currentStep: _rhymesController.currentStep, 
              stepProgress: _rhymesController.stepProgress, 
              activeColor: activeColor
            ),
          ),
          // Logo e Header (Genesis)
          Positioned(top: 100, left: 0, right: 0,
            child: Column(
              children: [
                const Text("Versin", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                const Text("GENESIS", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 5)),
                const SizedBox(height: 15),
                ChatHeader(activeColor: activeColor, rhymesController: _rhymesController),
              ],
            ),
          ),
          // Botão Menu
          Positioned(top: 95, left: 15,
            child: IconButton(
              icon: Icon(Icons.menu_rounded, color: activeColor, size: 32),
              onPressed: () => _scaffoldKey.currentState?.openDrawer()
            ),
          ),
          // LISTA DE MENSAGENS (Padding ajustado para respiro do teclado e input)
          Positioned.fill(
            top: 240, 
            bottom: 110 + bottomPadding, 
            child: ChatListView(
              isInitializing: _isInitializing, 
              messages: messages,
              isAiTyping: _isAiTyping, 
              scrollController: _scrollController,
              activeColor: activeColor,
              secondsActive: _rhymesController.connectionSeconds,
            ),
          ),
          // Barra de Digitação Inferior (ChatBottomBar)
          Positioned(bottom: bottomPadding + 15, left: 15, right: 15,
            child: ChatBottomBar(
              messageController: _messageController, 
              rhymesController: _rhymesController, 
              activeColor: activeColor, 
              isRhymeMode: _rhymesController.isRhymeMode, 
              onSend: _sendMessage,
              currentSuggestionIndex: _currentSuggestionIndex,
              onUpdateSuggestionIndex: (index) => setState(() => _currentSuggestionIndex = index),
              onAddRhyme: (word) {
                setState(() {
                  String currentText = _messageController.text;
                  _messageController.text = "$currentText $word ";
                  _messageController.selection = TextSelection.fromPosition(
                    TextPosition(offset: _messageController.text.length)
                  );
                });
              }, 
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _rhymesController.removeListener(_handleControllerChanges);
    _authSubscription?.cancel();
    _authModalTimer?.cancel();
    _messageController.dispose(); 
    _scrollController.dispose();
    super.dispose();
  }
}