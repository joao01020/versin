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
import 'package:versin/features/rhymes/presentation/widgets/mood_selector_slider/mood_selector_slider.dart';

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

  bool _configuracaoFinalizada = false; 
  int _currentBpm = 120;
  String _selectedVibe = "Calmo";
  String _selectedTechnique = "Melódico";
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
        onLoadingStatusChanged: (status) =>
            setState(() => _isInitializing = status),
        onStartWelcomeFlow: _startWelcomeFlow,
      );
    }
  }

  void _checkInitialSession() {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) _authModalTimer?.cancel();
  }

  void _setupAuthListener() {
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) {
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

  Future<void> _iniciarSessaoNoBanco() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() {
      messages.clear(); 
      _configuracaoFinalizada = true; 
      _isAiTyping = true;
    });

    try {
      await Supabase.instance.client.from('lyrics_history').insert({
        'user_id': user.id,
        'bpm': _currentBpm,
        'structure': _lastConfirmedStructure,
        'theme': _messageController.text.isNotEmpty ? _messageController.text : "Tema Livre",
        'vibe': _selectedVibe,
        'vocal_technique': _selectedTechnique,
        'created_at': DateTime.now().toIso8601String(),
      });

      setState(() {
        messages.add({
          "role": "assistant",
          "content": "✨ **Estúdio Iniciado!**\n\nA estrutura foi salva. Comece a compor agora!\n\n*Dica: Use **Enter** para pular linha.*",
        });
      });

      String prompt = "Inicie a composição. Estrutura: $_lastConfirmedStructure. Vibe: $_selectedVibe. Técnica: $_selectedTechnique. Tema: ${_messageController.text}";
      final response = await _rhymesController.fetchAiResponse(prompt);

      if (mounted) {
        setState(() {
          messages.add(response);
          _isAiTyping = false;
          _rhymesController.updateProgress(1, 1.0);
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint("Erro ao salvar sessão: $e");
      setState(() => _isAiTyping = false);
    }
  }

  Widget _buildEstudioToolbar(Color activeColor) {
    if (!_configuracaoFinalizada) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToolbarItem(
            icon: Icons.speed,
            label: "$_currentBpm BPM",
            onTap: () => _showQuickMenu("Ajustar BPM", ["80", "90", "100", "120", "140", "160"], (val) {
              setState(() => _currentBpm = int.parse(val));
            }),
            activeColor: activeColor,
          ),
          const SizedBox(width: 12),
          _buildToolbarItem(
            icon: Icons.account_tree_outlined,
            label: "Estrutura",
            onTap: () => _showStructureEditor(activeColor),
            activeColor: activeColor,
          ),
          const SizedBox(width: 12),
          // ITEM DE PERFORMANCE (TÉCNICA VOCAL) - REF: Captura de imagem_20260430_001439.png
          _buildToolbarItem(
            icon: Icons.mic_external_on_outlined,
            label: _selectedTechnique,
            onTap: () => _showQuickMenu("Performance Vocal", ["Melódico", "Agressivo", "Flow Rápido", "Sussurrado", "Falsete"], (val) {
              setState(() => _selectedTechnique = val);
            }),
            activeColor: activeColor,
          ),
          const SizedBox(width: 12),
          _buildToolbarItem(
            icon: Icons.auto_awesome,
            label: _selectedVibe,
            onTap: () => _showQuickMenu("Alterar Vibe", ["Calmo", "Energético", "Agressivo", "Triste", "Melancólico"], (val) {
              setState(() => _selectedVibe = val);
            }),
            activeColor: activeColor,
          ),
        ],
      ),
    );
  }

  void _showStructureEditor(Color activeColor) {
    List<String> estruturaLista = _lastConfirmedStructure.split(', ').where((s) => s.isNotEmpty).toList();
    if (estruturaLista.isEmpty) estruturaLista = ["Intro", "Verso 1", "Refrão", "Verso 2", "Final"];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Organizar Estrutura", style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text("Arraste os itens para mudar a ordem da letra", style: TextStyle(color: Colors.white24, fontSize: 11)),
                  const SizedBox(height: 15),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                    child: ReorderableListView(
                      shrinkWrap: true,
                      children: [
                        for (int i = 0; i < estruturaLista.length; i++)
                          ListTile(
                            key: ValueKey("$i-${estruturaLista[i]}"),
                            leading: Icon(Icons.drag_handle_rounded, color: activeColor.withOpacity(0.5)),
                            title: Text(estruturaLista[i], style: const TextStyle(color: Colors.white, fontSize: 14)),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.white10, size: 18),
                              onPressed: () => setModalState(() => estruturaLista.removeAt(i)),
                            ),
                          ),
                      ],
                      onReorder: (oldIdx, newIdx) {
                        setModalState(() {
                          if (newIdx > oldIdx) newIdx -= 1;
                          final item = estruturaLista.removeAt(oldIdx);
                          estruturaLista.insert(newIdx, item);
                        });
                      },
                    ),
                  ),
                  const Divider(color: Colors.white10),
                  TextButton.icon(
                    onPressed: () {
                      _showQuickMenu("Adicionar Bloco", ["Intro", "Verso", "Refrão", "Ponte", "Solo", "Final"], (val) {
                        setModalState(() => estruturaLista.add(val));
                      });
                    },
                    icon: Icon(Icons.add, color: activeColor, size: 18),
                    label: Text("ADICIONAR BLOCO", style: TextStyle(color: activeColor)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: activeColor),
                        onPressed: () {
                          setState(() => _lastConfirmedStructure = estruturaLista.join(', '));
                          Navigator.pop(context);
                        },
                        child: const Text("SALVAR NOVA ORDEM", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildToolbarItem({required IconData icon, required String label, required VoidCallback onTap, required Color activeColor}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.white54),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          const Icon(Icons.keyboard_arrow_down, size: 14, color: Colors.white30),
        ],
      ),
    );
  }

  void _showQuickMenu(String title, List<String> options, Function(String) onSelect) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(title, style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
          ),
          ...options.map((opt) => ListTile(
            title: Text(opt, style: const TextStyle(color: Colors.white)),
            onTap: () {
              onSelect(opt);
              Navigator.pop(context);
            },
          )),
        ],
      ),
    );
  }

  void _processMessage(String text) async {
    if (text.isEmpty) return;
    setState(() {
      messages.add({"role": "user", "content": text});
      _isAiTyping = true;
    });
    _scrollToBottom();
    final response = await _rhymesController.fetchAiResponse(
      "$text [Vibe: $_selectedVibe | Técnica: $_selectedTechnique | Estrutura: $_lastConfirmedStructure]",
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
        messages.add({
          "role": "assistant",
          "content": content,
          "customWidget": customWidget,
        });
      }),
      setAiTyping: (typing) => setState(() => _isAiTyping = typing),
      scrollToBottom: _scrollToBottom,
      onProgressUpdate: (step, progress) =>
          _rhymesController.updateProgress(step, progress),
      activeColor: _rhymesController.getActiveColor(),
      onStructureConfirmed: (configEstudio) {
        _lastConfirmedStructure = configEstudio;
        setState(() {
          messages.add({
            "role": "assistant",
            "content": "Estrutura definida! Defina o tema e use o slider para configurar a performance:",
            "customWidget": MoodSelectorSlider(
              onSelectionChanged: (valor, nome, isFinalStep) {
                if (!isFinalStep) {
                  _selectedVibe = nome;
                } else {
                  _selectedTechnique = nome;
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

  void _completeStep(int step) =>
      _rhymesController.updateProgress(step + 1, 0.0);

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
            _lastConfirmedStructure = "";
            _configuracaoFinalizada = false;
          });
          _rhymesController.updateProgress(1, 0.0);
          _startWelcomeFlow();
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 5),
              child: VersinTimeline(
                currentStep: _rhymesController.currentStep,
                stepProgress: _rhymesController.stepProgress,
                activeColor: activeColor,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: SizedBox(
                height: 50,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: Icon(Icons.menu_rounded, color: activeColor, size: 30),
                        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                      ),
                    ),
                    const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("Versin", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                        Text("GENESIS", style: TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 4)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ChatHeader(
                activeColor: activeColor,
                rhymesController: _rhymesController,
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
              ),
            ),
            if (_configuracaoFinalizada)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildEstudioToolbar(activeColor),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 5, 15, 15),
              child: ChatBottomBar(
                messageController: _messageController,
                rhymesController: _rhymesController,
                activeColor: activeColor,
                isRhymeMode: _rhymesController.isRhymeMode,
                onSend: _sendMessage,
                currentSuggestionIndex: _currentSuggestionIndex,
                onUpdateSuggestionIndex: (index) =>
                    setState(() => _currentSuggestionIndex = index),
                onAddRhyme: (word) {
                  setState(() {
                    String currentText = _messageController.text;
                    _messageController.text = "$currentText $word ";
                    _messageController.selection = TextSelection.fromPosition(
                      TextPosition(offset: _messageController.text.length),
                    );
                  });
                },
              ),
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