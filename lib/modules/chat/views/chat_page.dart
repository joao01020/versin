import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'package:versin/core/widgets/metronome/metronome_player.dart';
import 'package:versin/core/widgets/timeline/versin_timeline.dart';
import 'package:versin/features/rhymes/presentation/controller/rhymes_controller.dart';
import 'package:versin/modules/brain/controller/brain_controller.dart';
import 'package:versin/modules/chat/controllers/chat_controller.dart';
import 'package:versin/modules/chat/domain/repositories/chat_repository.dart';
import 'package:versin/modules/chat/views/components/chat/list/chat_list_view.dart';
import 'package:versin/modules/chat/views/components/suggestion_balloon/suggestion_balloon.dart';
import 'package:versin/modules/rhymelibrary/views/rhyme_library_page.dart';

import 'components/chat/input/chat_bottom_bar.dart';
import 'components/editor/structure_editor_modal.dart';
import 'components/editor/studio_toolbar.dart';
import 'components/header/chat_header.dart';
import 'widgets/audio/voice_studio_panel.dart';

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

    _rhymesController =
        GetIt.I<
          BrainController
        >();

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
    super.dispose();
  }

  void _abrirPainelDeVoz(
    BuildContext context,
    Color activeColor,
  ) {
    showModalBottomSheet<
      void
    >(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (
            _,
          ) {
            return VoiceStudioPanel(
              activeColor: activeColor,
              onFinished: () {
                debugPrint(
                  'Gravação concluída no VoiceStudioPanel.',
                );
              },
            );
          },
    );
  }

  Future<
    void
  >
  _salvarRimasDaTimeline(
    List<
      String
    >
    rimas,
  ) async {
    for (final rima in rimas) {
      await _rhymesController.addWord(
        rima,
        false,
      );
    }
  }

  void _abrirBiblioteca() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (
              _,
            ) => RhymeLibraryPage(
              controller: _rhymesController,
            ),
      ),
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

            final screenWidth = MediaQuery.sizeOf(
              context,
            ).width;

            const baseLeftOffset = 33.0;

            final cursorPositionLeft =
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
                child: Stack(
                  children: [
                    Column(
                      children: [
                        VersinTimeline(
                          currentStep: rhymesCtrl.currentStep,
                          activeColor: activeColor,
                          onRimaFinalizada: _salvarRimasDaTimeline,
                          onTextChanged: rhymesCtrl.onTextChanged,
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
                                onPressed: _abrirBiblioteca,
                                icon: Icon(
                                  Icons.library_books,
                                  color: activeColor,
                                ),
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
                                    message,
                                  ) => message.toJson(),
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
                          onEditName: () {
                            _controller.editProjectName(
                              context,
                            );
                          },
                          currentBpm: rhymesCtrl.currentBpm,
                          selectedVibe: rhymesCtrl.selectedVibe,
                          selectedTechnique: rhymesCtrl.selectedTechnique,
                          activeColor: activeColor,
                          onShowStructure: () {
                            StructureEditorModal.show(
                              context: context,
                              initialStructure: _controller.lastConfirmedStructure,
                              activeColor: activeColor,
                              onSave: _controller.saveStructure,
                              onSendToChat: _controller.sendStructureToChat,
                              showQuickMenu:
                                  (
                                    title,
                                    options,
                                    onSelect,
                                  ) {
                                    _controller.showStudioQuickMenu(
                                      context,
                                      title,
                                      options,
                                      onSelect,
                                    );
                                  },
                            );
                          },
                          onShowMenu:
                              (
                                title,
                                options,
                                onSelect,
                              ) {
                                _controller.showStudioQuickMenu(
                                  context,
                                  title,
                                  options,
                                  onSelect,
                                );
                              },
                          onBpmChanged:
                              (
                                value,
                              ) {
                                rhymesCtrl.updateStudioConfig(
                                  bpm: value,
                                );
                              },
                          onTechniqueChanged:
                              (
                                value,
                              ) {
                                rhymesCtrl.updateStudioConfig(
                                  technique: value,
                                );
                              },
                          onVibeChanged:
                              (
                                value,
                              ) {
                                rhymesCtrl.updateStudioConfig(
                                  vibe: value,
                                );
                              },
                        ),

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
                                  ) {
                                    _controller.sendMessage();
                                  },
                              currentSuggestionIndex: _controller.currentSuggestionIndex,
                              onUpdateSuggestionIndex: _controller.updateSuggestionIndex,
                              onAddRhyme: _controller.addWordToText,
                              onMicPressed: () {
                                _abrirPainelDeVoz(
                                  context,
                                  activeColor,
                                );
                              },
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

                    if (rhymesCtrl.suggestions.isNotEmpty)
                      Positioned(
                        left: cursorPositionLeft,
                        bottom: 75,
                        child: SuggestionBalloon(
                          controller: rhymesCtrl.suggestionController,
                          suggestion: _controller.getCurrentSuggestion(),
                          onTap: () {
                            final suggestion = _controller.getCurrentSuggestion();

                            final text = _controller.messageController.text;

                            final words = text.trimRight().split(
                              RegExp(
                                r'\s+',
                              ),
                            );

                            if (words.isNotEmpty) {
                              words.removeLast();
                              words.add(
                                suggestion,
                              );

                              final newText = '${words.join(' ')} ';

                              _controller.messageController.value = TextEditingValue(
                                text: newText,
                                selection: TextSelection.collapsed(
                                  offset: newText.length,
                                ),
                              );
                            }

                            rhymesCtrl.clearSuggestions();
                          },
                          onDismiss: () {
                            rhymesCtrl.clearSuggestions();
                          },
                          onAddCommand: () {
                            final word = _controller.getCurrentSuggestion();

                            rhymesCtrl.clearSuggestions();

                            _controller.processMessage(
                              'Me dê um exemplo de rima com: $word',
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
