import 'package:flutter/material.dart';

// CONTROLLER E REPOSITÓRIO
import 'package:versin/modules/chat/controllers/chat_controller.dart';
import 'package:versin/modules/chat/domain/repositories/chat_repository.dart';
import 'package:versin/features/rhymes/presentation/controller/rhymes_controller.dart';

// CORE WIDGETS
import 'package:versin/core/widgets/timeline/versin_timeline.dart';
import 'package:versin/core/widgets/metronome/metronome_player.dart';

// COMPONENTES LOCAIS (Ajustado para buscar da sua pasta de widgets de áudio do módulo)
import 'widgets/audio/voice_studio_panel.dart';
import 'components/chat/list/chat_list_view.dart';
import 'components/chat/input/chat_bottom_bar.dart';
import 'components/editor/studio_toolbar.dart';
import 'components/editor/structure_editor_modal.dart';
import 'components/header/chat_header.dart';
import 'components/suggestion_balloon/suggestion_balloon.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with AutomaticKeepAliveClientMixin {
  late final ChatController _controller;
  bool _isSessionInitialized = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    
    // SÊNIOR: Se você já gerencia o RhymesController globalmente via Injeção de Dependência 
    // (ex: GetIt, Provider, BlocProvider), o ideal seria buscá-lo aqui em vez de instanciar um novo.
    // Ex: rhymesController: GetIt.I<RhymesController>()
    _controller = ChatController(
      repository: ChatRepositoryImpl(),
      rhymesController: RhymesController(), 
    );
    
    if (!_isSessionInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _controller.initChatSession(context);
        }
      });
      _isSessionInitialized = true;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // SÊNIOR: Função isolada e segura para invocar o painel de gravação do estúdio de forma sobreposta (Overlay/Sheet)
  void _abrirPainelDeVoz(BuildContext context, Color activeColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return VoiceStudioPanel(
          activeColor: activeColor,
          onFinished: () {
            // Callback quando o produtor desativa o microfone
            debugPrint("Gravação concluída no VoiceStudioPanel. Processando fluxo de rima na ChatPage...");
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // SÊNIOR: Listenable.merge garante que a UI reconstrua tanto quando o ChatController
    // adicionar uma nova mensagem quanto quando o RhymesController atualizar o timer da IA ou o BPM.
    return AnimatedBuilder(
      animation: Listenable.merge([_controller, _controller.rhymesController]),
      builder: (context, _) {
        final rhymesCtrl = _controller.rhymesController;
        final activeColor = rhymesCtrl.getActiveColor();

        return Scaffold(
          backgroundColor: const Color(0xFF0F0F0F),
          body: SafeArea(
            child: Column(
              children: [
                VersinTimeline(
                  currentStep: rhymesCtrl.currentStep,
                  stepProgress: rhymesCtrl.stepProgress,
                  activeColor: activeColor,
                ),
                
                ChatHeader(
                  activeColor: activeColor,
                  rhymesController: rhymesCtrl,
                ),
                
                Expanded(
                  child: ChatListView(
                    isInitializing: _controller.isInitializing,
                    // SÊNIOR: Cast explícito e seguro sem risco de runtime type exceptions
                    messages: _controller.messages.map<Map<String, dynamic>>((m) => m.toJson()).toList(),
                    isAiTyping: _controller.isAiTyping,
                    scrollController: _controller.scrollController,
                    activeColor: activeColor,
                    secondsActive: rhymesCtrl.connectionSeconds,
                  ),
                ),

                if (rhymesCtrl.isRhymeMode && rhymesCtrl.suggestions.isNotEmpty)
                  SuggestionBalloon(
                    suggestion: _controller.getCurrentSuggestion(),
                    onTap: () => _controller.addWordToText(_controller.getCurrentSuggestion()),
                    onDismiss: () => rhymesCtrl.clearSuggestions(),
                    onNext: _controller.nextSuggestion,
                    onPrevious: _controller.previousSuggestion,
                    onAddCommand: () => _controller.processMessage(
                      "Me dê um exemplo de rima com: ${_controller.getCurrentSuggestion()}"
                    ),
                  ),
                
                StudioToolbar(
                  isConfigFinished: true, 
                  projectName: _controller.projectName, 
                  onEditName: () => _controller.editProjectName(context), 
                  currentBpm: rhymesCtrl.currentBpm,
                  selectedVibe: rhymesCtrl.selectedVibe,
                  selectedTechnique: rhymesCtrl.selectedTechnique,
                  activeColor: activeColor,
                  onShowStructure: () => StructureEditorModal.show(
                    context: context,
                    initialStructure: _controller.lastConfirmedStructure,
                    activeColor: activeColor,
                    onSave: _controller.saveStructure,
                    onSendToChat: _controller.sendStructureToChat,
                    showQuickMenu: (title, opts, onSelect) => _controller.showStudioQuickMenu(context, title, opts, onSelect),
                  ),
                  onShowMenu: (title, opts, onSelect) => _controller.showStudioQuickMenu(context, title, opts, onSelect),
                  onBpmChanged: (val) => rhymesCtrl.updateStudioConfig(bpm: val),
                  onTechniqueChanged: (val) => rhymesCtrl.updateStudioConfig(technique: val),
                  onVibeChanged: (val) => rhymesCtrl.updateStudioConfig(vibe: val),
                ),

                Stack(
                  alignment: Alignment.centerRight,
                  children: [
                    ChatBottomBar(
                      messageController: _controller.messageController,
                      rhymesController: rhymesCtrl,
                      activeColor: activeColor,
                      isRhymeMode: rhymesCtrl.isRhymeMode,
                      // ➔ CORREÇÃO FINAL: Ignora o texto do callback, pois o Controller lê o messageController internamente
                      onSend: (_) => _controller.sendMessage(), 
                      currentSuggestionIndex: _controller.currentSuggestionIndex,
                      onUpdateSuggestionIndex: _controller.updateSuggestionIndex,
                      onAddRhyme: _controller.addWordToText,
                      onMicPressed: () => _abrirPainelDeVoz(context, activeColor),
                    ),
                    Positioned(
                      right: 55, 
                      child: MetronomePlayer(
                        isPlaying: rhymesCtrl.isBpmPlaying,
                        onTap: _controller.toggleBpm,
                        activeColor: activeColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}