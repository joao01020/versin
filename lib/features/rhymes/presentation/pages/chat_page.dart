import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqflite/sqflite.dart';

// PERSISTÊNCIA CORE
import 'package:versin/core/database/database_helper.dart';

// SERVIÇOS E REPOSITÓRIOS
import 'package:versin/features/rhymes/domain/services/session_service.dart';
import 'package:versin/features/rhymes/presentation/widgets/project_check_modal/project_check_modal.dart';

// CONTROLLER
import 'package:versin/features/rhymes/presentation/controller/rhymes_controller.dart';

// COMPONENTES
import 'package:versin/features/rhymes/presentation/pages/components/chat/studio_toolbar.dart';
import 'package:versin/features/rhymes/presentation/pages/components/chat/structure_editor_modal.dart';
import 'package:versin/features/rhymes/presentation/widgets/common/versin_bottom_menu.dart';
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
  final _messageController = TextEditingController();
  final RhymesController _rhymesController = RhymesController();
  final SessionService _sessionService = SessionService(); 
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  
  Timer? _authModalTimer;
  StreamSubscription<AuthState>? _authSubscription;
  List<Map<String, dynamic>> messages = [];
  bool _isAiTyping = false;
  bool _isInitializing = true;
  int _currentSuggestionIndex = 0;
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

  void _initializeLogic() {
    _rhymesController.updateGamification(0.0);
    _rhymesController.addListener(_handleControllerChanges);
  }

  void _handleControllerChanges() {
    if (mounted) {
      _autosaveProject();
      setState(() {});
    }
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

  // --- PERSISTÊNCIA E VERIFICAÇÃO ---
  
  Future<void> _autosaveProject() async {
    final db = await DatabaseHelper.instance.database;
    final user = Supabase.instance.client.auth.currentUser;
    
    await db.insert('rhymes', {
      'id': 'current_session',
      'content': _messageController.text,
      'bpm': _rhymesController.currentBpm,
      'genre': _rhymesController.selectedVibe, 
      'mood': _rhymesController.selectedTechnique,
      'status': _configuracaoFinalizada ? 'active' : 'draft',
      'created_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    if (user != null) {
      await db.insert('user_profile', {
        'id': user.id,
        'name': user.userMetadata?['full_name'] ?? 'Artista',
        'wallet': 'wallet@${user.email?.split('@')[0]}',
        'synced': 0
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> _loadInitialData() async {
    final pendingProject = await _sessionService.hasPendingSession();

    if (pendingProject != null && mounted) {
      ProjectCheckModal.show(
        context,
        project: pendingProject,
        onResume: () => _resumeProject(pendingProject),
        onDiscard: () => _startNewFreshProject(),
      );
    } else {
      _startNewFreshProject();
    }

    await _rhymesController.carregarDadosUsuario();
  }

  void _resumeProject(Map<String, dynamic> project) {
    setState(() {
      _messageController.text = project['content'] ?? "";
      _rhymesController.updateStudioConfig(
        bpm: project['bpm'] ?? 140, // Padrão Trap se nulo
        vibe: project['genre'] ?? "Trap",
        technique: project['mood'] ?? "Agressiva"
      );
      _configuracaoFinalizada = true; 
      _isInitializing = false;
      messages.add({
        "role": "assistant",
        "content": "✨ **Workflow Restaurado.** O estúdio está pronto para continuar a letra.",
      });
    });
    _rhymesController.updateProgress(4, 1.0);
    _scrollToBottom();
  }

  void _startNewFreshProject() async {
    await _sessionService.startFreshSession();
    
    // ATUALIZAÇÃO: Garante que as configs padrão apareçam mesmo sem projeto anterior
    if (mounted) {
      setState(() {
        _rhymesController.updateStudioConfig(
          bpm: 140, // BPM Sugerido para Trap
          vibe: "Trap",
          technique: "Melódica"
        );
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
    if (session != null) _authModalTimer?.cancel();
  }

  void _setupAuthListener() {
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn && data.session != null) {
        _authModalTimer?.cancel();
        _rhymesController.carregarDadosUsuario();
        _autosaveProject();
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

  void _toggleBpm() => _rhymesController.toggleMetronome();

  void _enviarEstruturaParaChat(List<String> blocos) {
    String textoEstrutura = blocos.map((b) => "[$b]\n\n\n\n").join("\n");
    setState(() {
      _messageController.text = textoEstrutura;
      _messageController.selection = TextSelection.fromPosition(const TextPosition(offset: 0));
    });
    _autosaveProject();
  }

  Future<void> _finalizarConfiguracaoEstudio() async {
    setState(() {
      messages.clear(); 
      _configuracaoFinalizada = true; 
      _isAiTyping = true;
    });
    setState(() {
      messages.add({
        "role": "assistant",
        "content": "✨ **Estúdio Configurado!**\nSua sessão foi iniciada no seu workflow profissional. Manda ver!",
      });
    });
    _processMessage("O estúdio está pronto. Vamos começar a letra?");
    _autosaveProject();
  }

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
                  _finalizarConfiguracaoEstudio();
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
        _scrollController.animateTo(_scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
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
            VersinTimeline(currentStep: _rhymesController.currentStep, stepProgress: _rhymesController.stepProgress, activeColor: activeColor),
            ChatHeader(activeColor: activeColor, rhymesController: _rhymesController, scaffoldKey: _scaffoldKey),
            
            // Header: Exibe sempre que houver uma config (mesmo inicial)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border(bottom: BorderSide(color: activeColor.withOpacity(0.3), width: 0.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mic_none, color: activeColor, size: 14),
                  const SizedBox(width: 8),
                  Text(
                    "ESTÚDIO: ${_rhymesController.selectedVibe.toUpperCase()} | ${_rhymesController.selectedTechnique.toUpperCase()} | ${_rhymesController.currentBpm} BPM",
                    style: TextStyle(color: activeColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                ],
              ),
            ),

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
                suggestion: _rhymesController.suggestions[_currentSuggestionIndex % _rhymesController.suggestions.length],
                onTap: () {
                  setState(() {
                    _messageController.text += " ${_rhymesController.suggestions[_currentSuggestionIndex % _rhymesController.suggestions.length]} ";
                    _rhymesController.clearSuggestions();
                  });
                },
                onDismiss: () => _rhymesController.clearSuggestions(),
                onNext: () => setState(() => _currentSuggestionIndex++),
                onPrevious: () => setState(() => _currentSuggestionIndex--),
                onAddCommand: () => _processMessage("Me dê um exemplo de rima com: ${_rhymesController.suggestions[_currentSuggestionIndex % _rhymesController.suggestions.length]}"),
              ),
            
            // StudioToolbar: Sempre visível para facilitar o workflow
            StudioToolbar(
              configuracaoFinalizada: true, 
              currentBpm: _rhymesController.currentBpm,
              selectedVibe: _rhymesController.selectedVibe,
              selectedTechnique: _rhymesController.selectedTechnique,
              activeColor: activeColor,
              onShowStructure: () => StructureEditorModal.show(
                context: context, initialStructure: _lastConfirmedStructure, activeColor: activeColor,
                onSave: (val) => setState(() => _lastConfirmedStructure = val),
                onSendToChat: _enviarEstruturaParaChat,
                showQuickMenu: (title, opts, onSelect) => VersinBottomMenu.show(context: context, title: title, options: opts, onSelect: onSelect),
              ),
              onShowMenu: (title, opts, onSelect) => VersinBottomMenu.show(context: context, title: title, options: opts, onSelect: onSelect),
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