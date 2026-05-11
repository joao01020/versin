import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// REPOSITÓRIO E CONTROLLER
import 'package:versin/features/rhymes/data/repositories/studio_repository.dart';
import 'package:versin/features/rhymes/presentation/controller/rhymes_controller.dart';

// COMPONENTES EXTRAÍDOS E MODAIS
import 'package:versin/features/rhymes/presentation/pages/components/chat/studio_toolbar.dart';
import 'package:versin/features/rhymes/presentation/pages/components/chat/structure_editor_modal.dart';
import 'package:versin/features/rhymes/presentation/widgets/common/versin_bottom_menu.dart';

// COMPONENTES DE UI CORE
import 'package:versin/features/rhymes/presentation/widgets/versin_drawer/versin_drawer.dart';
import 'package:versin/features/rhymes/presentation/pages/components/header/chat_header.dart';
import 'package:versin/features/rhymes/presentation/pages/components/chat/chat_list_view.dart';
import 'package:versin/features/rhymes/presentation/pages/components/chat/chat_bottom_bar.dart';
import 'package:versin/features/rhymes/presentation/pages/components/chat_initializer/chat_initializer.dart';
import 'package:versin/features/rhymes/presentation/pages/components/auth_modal/auth_modal.dart';
import 'package:versin/features/rhymes/presentation/pages/components/timeline/versin_timeline.dart';
import 'package:versin/features/rhymes/presentation/widgets/mood_selector_slider/mood_selector_slider.dart';
import 'package:versin/features/rhymes/presentation/pages/components/chat/suggestion_balloon/suggestion_balloon.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  // --- CONTROLLERS E ESTADOS CORE ---
  final _messageController = TextEditingController();
  final RhymesController _rhymesController = RhymesController();
  final StudioRepository _studioRepo = StudioRepository(); 
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();

  Timer? _authModalTimer;
  StreamSubscription<AuthState>? _authSubscription;

  List<Map<String, dynamic>> messages = [];
  bool _isAiTyping = false;
  bool _isInitializing = true;
  int _currentSuggestionIndex = 0;

  // --- ESTADOS DO MENU DE ESTÚDIO ---
  bool _configuracaoFinalizada = false; 
  String _lastConfirmedStructure = "";

  @override
  void initState() {
    super.initState();
    _initializeLogic();
    _setupListeners();
    _checkInitialSession();
    _setupAuthListener();
    _loadInitialData();
    _startAuthTimer();
    _rhymesController.fetchTrendingWords();
  }

  // --- MÉTODOS DE INICIALIZAÇÃO ---

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
        if (progress >= 1.0) _rhymesController.updateProgress(3, 0.0);
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

  // --- GESTÃO DE SESSÃO ---

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
      if (Supabase.instance.client.auth.currentUser == null) {
        AuthModal.show(context);
      }
    });
  }

  // --- LÓGICA DE ESTÚDIO E ÁUDIO ---

  void _toggleBpm() {
    // Agora o controller gerencia o loop de som e o estado isBpmPlaying
    _rhymesController.toggleMetronome();
  }

  void _enviarEstruturaParaChat(List<String> blocos) {
    String textoEstrutura = blocos.map((b) => "[$b]\n\n\n\n").join("\n");
    setState(() {
      _messageController.text = textoEstrutura;
      _messageController.selection = TextSelection.fromPosition(const TextPosition(offset: 0));
    });
  }

  Future<void> _iniciarSessaoNoBanco() async {
    setState(() {
      messages.clear(); 
      _configuracaoFinalizada = true; 
      _isAiTyping = true;
    });

    try {
      await _studioRepo.inserirSessaoNoBanco(
        bpm: _rhymesController.currentBpm,
        structure: _lastConfirmedStructure,
        theme: _messageController.text.isNotEmpty ? _messageController.text : "Tema Livre",
        vibe: _rhymesController.selectedVibe,
        technique: _rhymesController.selectedTechnique,
      );

      setState(() {
        messages.add({
          "role": "assistant",
          "content": "✨ **Estúdio Configurado!**\nSua sessão foi salva. Manda ver na composição!",
        });
      });
      _processMessage("O estúdio está pronto. Vamos começar a letra?");
    } catch (e) {
      debugPrint("Erro ao salvar: $e");
      setState(() => _isAiTyping = false);
    }
  }

  // --- FLUXO DE MENSAGENS ---

  void _processMessage(String text) async {
    if (text.isEmpty) return;
    setState(() {
      messages.add({"role": "user", "content": text});
      _isAiTyping = true;
    });
    _scrollToBottom();

    final response = await _rhymesController.fetchAiResponse(
      "$text [Contexto: ${_rhymesController.selectedVibe}, ${_rhymesController.selectedTechnique}, ${_rhymesController.currentBpm} BPM]",
    );

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
    if (text.isNotEmpty) {
      _processMessage(text);
      _messageController.clear();
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
      onProgressUpdate: (step, progress) => _rhymesController.updateProgress(step, progress),
      activeColor: _rhymesController.getActiveColor(),
      onStructureConfirmed: (config) {
        _lastConfirmedStructure = config;
        setState(() {
          messages.add({
            "role": "assistant",
            "content": "Boa! Agora defina a vibe e técnica usando o slider:",
            "customWidget": MoodSelectorSlider(
              onSelectionChanged: (valor, nome, isFinalStep) {
                if (!isFinalStep) {
                  _rhymesController.updateStudioConfig(vibe: nome);
                } else {
                  _rhymesController.updateStudioConfig(technique: nome);
                  _iniciarSessaoNoBanco();
                }
              },
            ),
          });
        });
        _scrollToBottom();
      },
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = _rhymesController.getActiveColor();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF0F0F0F),
      drawer: VersinDrawer(
        rhymesController: _rhymesController,
        onNewChat: () {
          setState(() {
            messages.clear();
            _configuracaoFinalizada = false;
            if (_rhymesController.isBpmPlaying) _rhymesController.toggleMetronome();
          });
          _rhymesController.updateProgress(1, 0.0);
          _startWelcomeFlow();
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            VersinTimeline(
              currentStep: _rhymesController.currentStep,
              stepProgress: _rhymesController.stepProgress,
              activeColor: activeColor,
            ),
            ChatHeader(activeColor: activeColor, rhymesController: _rhymesController, scaffoldKey: _scaffoldKey),
            Expanded(
              child: ChatListView(
                isInitializing: _isInitializing,
                messages: messages,
                isAiTyping: _isAiTyping,
                scrollController: _scrollController,
                activeColor: activeColor,
                secondsActive: _rhymesController.connectionSeconds,
                isBpmPlaying: _rhymesController.isBpmPlaying,
                currentBpm: _rhymesController.currentBpm,
                onToggleBpm: _toggleBpm,
              ),
            ),
            
            if (_rhymesController.isRhymeMode && _rhymesController.suggestions.isNotEmpty)
              SuggestionBalloon(
                suggestion: _rhymesController.suggestions[_currentSuggestionIndex],
                onTap: () {
                  setState(() {
                    _messageController.text += " ${_rhymesController.suggestions[_currentSuggestionIndex]} ";
                    _rhymesController.clearSuggestions();
                  });
                },
                onDismiss: () => _rhymesController.clearSuggestions(),
                onNext: () => setState(() => _currentSuggestionIndex = (_currentSuggestionIndex + 1) % _rhymesController.suggestions.length),
                onPrevious: () => setState(() => _currentSuggestionIndex = (_currentSuggestionIndex - 1 + _rhymesController.suggestions.length) % _rhymesController.suggestions.length),
                onAddCommand: () => _processMessage("Exemplo de verso com: ${_rhymesController.suggestions[_currentSuggestionIndex]}"),
              ),

            StudioToolbar(
              configuracaoFinalizada: _configuracaoFinalizada,
              currentBpm: _rhymesController.currentBpm,
              selectedVibe: _rhymesController.selectedVibe,
              selectedTechnique: _rhymesController.selectedTechnique,
              activeColor: activeColor,
              onShowStructure: () => StructureEditorModal.show(
                context: context,
                initialStructure: _lastConfirmedStructure,
                activeColor: activeColor,
                onSave: (val) => setState(() => _lastConfirmedStructure = val),
                onSendToChat: _enviarEstruturaParaChat,
                showQuickMenu: (title, opts, onSelect) => VersinBottomMenu.show(
                  context: context,
                  title: title,
                  options: opts,
                  onSelect: onSelect,
                ),
              ),
              onShowMenu: (title, opts, onSelect) => VersinBottomMenu.show(
                context: context,
                title: title,
                options: opts,
                onSelect: onSelect,
              ),
              onBpmChanged: (val) => _rhymesController.updateStudioConfig(bpm: val),
              onTechniqueChanged: (val) => _rhymesController.updateStudioConfig(technique: val),
              onVibeChanged: (val) => _rhymesController.updateStudioConfig(vibe: val),
            ),

            ChatBottomBar(
              messageController: _messageController,
              rhymesController: _rhymesController,
              activeColor: activeColor,
              isRhymeMode: _rhymesController.isRhymeMode,
              onSend: _sendMessage,
              currentSuggestionIndex: _currentSuggestionIndex,
              onUpdateSuggestionIndex: (index) => setState(() => _currentSuggestionIndex = index),
              onAddRhyme: (word) => setState(() => _messageController.text += " $word "),
            ),
          ],
        ),
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