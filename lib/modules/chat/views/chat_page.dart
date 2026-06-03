import 'package:flutter/material.dart';

// Importação da nova página
import 'package:versin/modules/rhymelibrary/views/rhyme_library_page.dart';

// CONTROLLER E REPOSITÓRIO
import 'package:versin/modules/chat/controllers/chat_controller.dart';
import 'package:versin/modules/chat/domain/repositories/chat_repository.dart';
import 'package:versin/features/rhymes/presentation/controller/rhymes_controller.dart';

// CORE WIDGETS
import 'package:versin/core/widgets/timeline/versin_timeline.dart';
import 'package:versin/core/widgets/metronome/metronome_player.dart';

// COMPONENTES LOCAIS
import 'widgets/audio/voice_studio_panel.dart';
import 'components/chat/input/chat_bottom_bar.dart';
import 'components/editor/studio_toolbar.dart';
import 'components/editor/structure_editor_modal.dart';
import 'components/header/chat_header.dart';
import 'package:versin/modules/chat/views/components/chat/list/chat_list_view.dart';
import 'package:versin/modules/chat/views/components/suggestion_balloon/suggestion_balloon.dart';

class ChatPage
    extends
        StatefulWidget {
  const ChatPage({
    super.key,
  });

  @override
  State<
    ChatPage
  >
  createState() => _ChatPageState();
}

class _ChatPageState
    extends
        State<
          ChatPage
        >
    with
        AutomaticKeepAliveClientMixin {
  late final ChatController _controller;
  late final RhymesController _rhymesController;
  bool _isSessionInitialized = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    _rhymesController = RhymesController();

    _controller = ChatController(
      repository: ChatRepositoryImpl(),
      rhymesController: _rhymesController,
    );

    if (!_isSessionInitialized) {
      WidgetsBinding.instance.addPostFrameCallback(
        (
          _,
        ) {
          if (mounted) {
            _controller.initChatSession(
              context,
            );
          }
        },
      );
      _isSessionInitialized = true;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _rhymesController.dispose();
    super.dispose();
  }

  void _abrirPainelDeVoz(
    BuildContext context,
    Color activeColor,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (
            context,
          ) {
            return VoiceStudioPanel(
              activeColor: activeColor,
              onFinished: () {
                debugPrint(
                  "Gravação concluída no VoiceStudioPanel.",
                );
              },
            );
          },
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    super.build(
      context,
    );

    return AnimatedBuilder(
      animation: Listenable.merge(
        [
          _controller,
          _rhymesController,
          _controller.messageController,
        ],
      ),
      builder:
          (
            context,
            _,
          ) {
            final rhymesCtrl = _rhymesController;
            final activeColor = rhymesCtrl.getActiveColor();

            // Cálculo da posição do cursor
            final textPainter =
                TextPainter(
                  text: TextSpan(
                    text: _controller.messageController.text,
                    style: const TextStyle(
                      fontSize: 15,
                    ),
                  ),
                  maxLines: 1,
                  textDirection: TextDirection.ltr,
                )..layout(
                  minWidth: 0,
                  maxWidth: double.infinity,
                );

            final double screenWidth = MediaQuery.of(
              context,
            ).size.width;
            final double baseLeftOffset = 33.0;
            final double cursorPositionLeft =
                (baseLeftOffset +
                        textPainter.size.width)
                    .clamp(
                      baseLeftOffset,
                      screenWidth -
                          160.0,
                    );

            return Scaffold(
              backgroundColor: const Color(
                0xFF0F0F0F,
              ),
              body: SafeArea(
                // ENVELOPAMOS TUDO EM UM STACK MESTRE
                // Isso garante que o balão flutue sobre toda a tela e receba cliques
                child: Stack(
                  children: [
                    // CONTEÚDO PRINCIPAL (EM BACKGROUND)
                    Column(
                      children: [
                        VersinTimeline(
                          currentStep: rhymesCtrl.currentStep,
                          activeColor: activeColor,
                          onRimaFinalizada:
                              (
                                rimas,
                              ) {},
                        ),

                        Stack(
                          alignment: Alignment.centerRight,
                          children: [
                            ChatHeader(
                              activeColor: activeColor,
                              rhymesController: rhymesCtrl,
                            ),
                            Positioned(
                              right: 16,
                              child: IconButton(
                                icon: Icon(
                                  Icons.library_books,
                                  color: activeColor,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (
                                            context,
                                          ) => RhymeLibraryPage(
                                            controller: _rhymesController,
                                          ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),

                        Expanded(
                          child: ChatListView(
                            isInitializing: _controller.isInitializing,
                            messages: _controller.messages
                                .map<
                                  Map<
                                    String,
                                    dynamic
                                  >
                                >(
                                  (
                                    m,
                                  ) => m.toJson(),
                                )
                                .toList(),
                            isAiTyping: _controller.isAiTyping,
                            scrollController: _controller.scrollController,
                            activeColor: activeColor,
                            secondsActive: rhymesCtrl.connectionSeconds,
                          ),
                        ),

                        StudioToolbar(
                          isConfigFinished: true,
                          projectName: _controller.projectName,
                          onEditName: () => _controller.editProjectName(
                            context,
                          ),
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
                            showQuickMenu:
                                (
                                  title,
                                  opts,
                                  onSelect,
                                ) => _controller.showStudioQuickMenu(
                                  context,
                                  title,
                                  opts,
                                  onSelect,
                                ),
                          ),
                          onShowMenu:
                              (
                                title,
                                opts,
                                onSelect,
                              ) => _controller.showStudioQuickMenu(
                                context,
                                title,
                                opts,
                                onSelect,
                              ),
                          onBpmChanged:
                              (
                                val,
                              ) => rhymesCtrl.updateStudioConfig(
                                bpm: val,
                              ),
                          onTechniqueChanged:
                              (
                                val,
                              ) => rhymesCtrl.updateStudioConfig(
                                technique: val,
                              ),
                          onVibeChanged:
                              (
                                val,
                              ) => rhymesCtrl.updateStudioConfig(
                                vibe: val,
                              ),
                        ),

                        // ÁREA DE INPUT
                        Stack(
                          alignment: Alignment.centerRight,
                          children: [
                            ChatBottomBar(
                              messageController: _controller.messageController,
                              rhymesController: rhymesCtrl,
                              activeColor: activeColor,
                              onSend:
                                  (
                                    _,
                                  ) => _controller.sendMessage(),
                              currentSuggestionIndex: _controller.currentSuggestionIndex,
                              onUpdateSuggestionIndex: _controller.updateSuggestionIndex,
                              onAddRhyme: _controller.addWordToText,
                              onMicPressed: () => _abrirPainelDeVoz(
                                context,
                                activeColor,
                              ),
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

                    // O BALÃO DE SUGESTÃO AGORA FICA NA CAMADA SUPERIOR
                    // Ele pode ser clicado livremente porque faz parte do Stack principal
                    if (rhymesCtrl.suggestions.isNotEmpty)
                      Positioned(
                        left: cursorPositionLeft,
                        bottom: 75, // Altura exata para flutuar acima da barra de input
                        child: SuggestionBalloon(
                          suggestion: _controller.getCurrentSuggestion(),
                          onTap: () {
                            // Lógica para substituir a letra incompleta pela rima escolhida
                            final suggestion = _controller.getCurrentSuggestion();
                            final text = _controller.messageController.text;
                            final words = text.trimRight().split(
                              RegExp(
                                r'\s+',
                              ),
                            );

                            if (words.isNotEmpty) {
                              words.removeLast(); // Tira a parte da palavra sendo digitada
                              words.add(
                                suggestion,
                              ); // Coloca a palavra inteira

                              final newText = "${words.join(' ')} "; // Adiciona o espaço extra pro flow não parar

                              _controller.messageController.value = TextEditingValue(
                                text: newText,
                                selection: TextSelection.collapsed(
                                  offset: newText.length,
                                ), // Joga o cursor pro fim
                              );
                            }

                            rhymesCtrl.clearSuggestions();
                          },
                          onDismiss: () => rhymesCtrl.clearSuggestions(),
                          onNext: _controller.nextSuggestion,
                          onPrevious: _controller.previousSuggestion,
                          onAddCommand: () {
                            final word = _controller.getCurrentSuggestion();
                            rhymesCtrl.clearSuggestions();
                            _controller.processMessage(
                              "Me dê um exemplo de rima com: $word",
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
    );
  }
}
