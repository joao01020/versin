import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqflite/sqflite.dart';

// CONTROLLER (Centralizador de lógica)
import 'package:versin/features/rhymes/presentation/controller/rhymes_controller.dart';

// COMPONENTES
import 'package:versin/features/rhymes/presentation/pages/components/chat/studio_toolbar.dart';
import 'package:versin/features/rhymes/presentation/pages/components/chat/structure_editor_modal.dart';
import 'package:versin/features/rhymes/presentation/widgets/common/versin_bottom_menu.dart';
import 'package:versin/features/rhymes/presentation/widgets/versin_drawer/versin_drawer.dart';
import 'package:versin/features/rhymes/presentation/pages/components/header/chat_header.dart';
import 'package:versin/features/rhymes/presentation/pages/components/chat/chat_list_view.dart';
import 'package:versin/features/rhymes/presentation/pages/components/chat/chat_bottom_bar.dart';
import 'package:versin/features/rhymes/presentation/pages/components/auth_modal/auth_modal.dart';
import 'package:versin/features/rhymes/presentation/pages/components/timeline/versin_timeline.dart';
import 'package:versin/features/rhymes/presentation/pages/components/chat/suggestion_balloon/suggestion_balloon.dart';
// NOVO COMPONENTE - METRONOME
import 'package:versin/features/rhymes/presentation/pages/components/chat/metronome_player.dart';

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
  
  List<Map<String, dynamic>> messages = [];
  bool _isAiTyping = false;
  bool _isInitializing = false; 
  int _currentSuggestionIndex = 0;
  bool _configuracaoFinalizada = true; 
  String _lastConfirmedStructure = "";
  
  // NOVA VARIÁVEL PARA O NOME DO PROJETO
  String _projectName = "SEM TÍTULO";

  @override
  void initState() {
    super.initState();
    _initializeLogic();
    _setupListeners();
    _loadInitialData();
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
      if (text.isNotEmpty) {
        int lines = text.split('\n').where((l) => l.trim().isNotEmpty).length;
        double progress = (lines / 5).clamp(0.0, 1.0);
        _rhymesController.updateProgress(2, progress);
      }
    });
  }

  // MÉTODO PARA EDITAR O NOME DO PROJETO
  void _editProjectName() {
    final textController = TextEditingController(text: _projectName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text("Nome do Projeto", style: TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: textController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Digite o nome...",
            hintStyle: const TextStyle(color: Colors.white24),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: _rhymesController.getActiveColor())),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar", style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              setState(() => _projectName = textController.text.toUpperCase());
              _autosaveProject();
              Navigator.pop(context);
            },
            child: Text("Salvar", style: TextStyle(color: _rhymesController.getActiveColor())),
          ),
        ],
      ),
    );
  }

  // --- PERSISTÊNCIA ---
  
  Future<void> _autosaveProject() async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('rhymes', {
      'id': 'current_session',
      'name': _projectName, // SALVANDO O NOME
      'content': _messageController.text,
      'bpm': _rhymesController.currentBpm,
      'genre': _rhymesController.selectedVibe, 
      'mood': _rhymesController.selectedTechnique,
      'status': 'active',
      'created_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
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
      _projectName = project['name'] ?? "SEM TÍTULO";
      _messageController.text = project['content'] ?? "";
      _rhymesController.updateStudioConfig(
        bpm: project['bpm'] ?? 100,
        vibe: project['genre'] ?? "Calmo",
        technique: project['mood'] ?? "Melódico"
      );
      _configuracaoFinalizada = true; 
      messages.add({
        "role": "assistant",
        "content": "✨ **Workflow Restaurado.** O estúdio está pronto.",
      });
    });
    _scrollToBottom();
  }

  void _startNewFreshProject() async {
    await _sessionService.startFreshSession();
    if (mounted) {
      setState(() {
        _projectName = "SEM TÍTULO";
        _configuracaoFinalizada = true;
        _rhymesController.updateStudioConfig(
          bpm: 100,
          vibe: "Calmo",
          technique: "Melódico"
        );
      });
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

  // --- LÓGICA DE ESTÚDIO ---
  void _toggleBpm() {
    _rhymesController.toggleMetronome();
  }

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

    // O Controller agora cuida da inteligência de início
    setState(() {
      messages.add({
        "role": "assistant",
        "content": "✨ **Estúdio Configurado!**\nSua sessão foi iniciada no seu workflow profissional. Manda ver!",
      });
    });
    _processMessage("O estúdio está pronto. Vamos começar a letra?");
  }

  // --- FLUXO DE MENSAGENS ---
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
            _messageController.clear();
            _projectName = "SEM TÍTULO";
            if (_rhymesController.isBpmPlaying) _rhymesController.toggleMetronome();
          });
          _startNewFreshProject();
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            VersinTimeline(currentStep: _rhymesController.currentStep, stepProgress: _rhymesController.stepProgress, activeColor: activeColor),
            ChatHeader(activeColor: activeColor, rhymesController: _rhymesController, scaffoldKey: _scaffoldKey),
            
            // HEADER DO ESTÚDIO ATUALIZADO (Captura 225148) - APENAS TÍTULO E TEMA
            GestureDetector(
              onTap: _editProjectName,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border(bottom: BorderSide(color: activeColor.withOpacity(0.3), width: 0.5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.edit_note, color: activeColor, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      "$_projectName | ${_rhymesController.selectedVibe.toUpperCase()}",
                      style: TextStyle(color: activeColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                  ],
                ),
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
            
            // STUDIO TOOLBAR COM OS PARÂMETROS OBRIGATÓRIOS
            StudioToolbar(
              configuracaoFinalizada: true, 
              projectName: _projectName, 
              onEditName: _editProjectName, 
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

            Stack(
              alignment: Alignment.centerRight,
              children: [
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
                Positioned(
                  right: 55, 
                  child: MetronomePlayer(
                    isPlaying: _rhymesController.isBpmPlaying,
                    onTap: _toggleBpm,
                    activeColor: activeColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _rhymesController.removeListener(_handleControllerChanges);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}