import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'package:versin/core/widgets/metronome/metronome_player.dart';
import 'package:versin/core/widgets/timeline/versin_timeline.dart';
import 'package:versin/features/rhymes/presentation/controller/rhymes_controller.dart';
import 'package:versin/modules/brain/controller/brain_controller.dart';
import 'package:versin/modules/chat/controllers/chat_controller.dart';
import 'package:versin/modules/chat/data/datasources/chat_remote_datasource.dart';
import 'package:versin/modules/chat/services/ai_provider_service.dart';
import 'package:versin/modules/chat/services/private_api_service.dart';
import 'package:versin/modules/chat/services/private_ai_client.dart';
import 'package:versin/modules/chat/views/components/chat/list/chat_list_view.dart';
import 'package:versin/modules/chat/views/components/ai_guide/chat_ai_guide_modal.dart';
import 'package:versin/modules/chat/views/private_api_onboarding/private_api_onboarding_page.dart';
import 'package:versin/modules/chat/views/components/suggestion_balloon/suggestion_balloon.dart';
import 'package:versin/modules/rhymelibrary/views/rhyme_library_page.dart';
import 'package:versin/modules/profile/services/user_onboarding_preferences_service.dart';
import 'package:versin/modules/chat/domain/repositories/chat_repository_impl.dart';
// ============================================================
// STUDIO
// ============================================================

import 'package:versin/modules/studio/views/studio_page.dart';

import 'components/chat/input/chat_bottom_bar.dart';
import 'components/editor/structure_editor_modal.dart';
import 'components/editor/studio_toolbar.dart';
import 'components/header/chat_header.dart';
import 'widgets/audio/voice_studio_panel.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  late final ChatController _controller;

  late final RhymesController _rhymesController;

  // ============================================================
  // FONTE DE IA
  // ============================================================
  //
  // Mantemos a instância do AiProviderService na página para
  // conseguir sincronizar novamente a fonte de IA quando o
  // usuário voltar do onboarding/configuração da API privada.
  //
  // ============================================================

  late final AiProviderService _aiProviderService;

  bool _isSessionInitialized = false;

  bool _isReady = false;

  bool _controllerCreated = false;

  // ============================================================
  // GUIA DE IA - ONBOARDING
  // ============================================================

  final UserOnboardingPreferencesService _onboardingPreferences =
      UserOnboardingPreferencesService();

  late final AnimationController _guidePulseController;

  late final Animation<double> _guidePulseAnimation;

  bool _guidePulseCheckStarted = false;

  // ============================================================
  // KEEP ALIVE
  // ============================================================

  @override
  bool get wantKeepAlive => true;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _rhymesController = GetIt.I<BrainController>();

    _guidePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _guidePulseAnimation = CurvedAnimation(
      parent: _guidePulseController,
      curve: Curves.easeInOutCubic,
    );

    _initializeChat();
  }

  // ============================================================
  // INICIALIZAÇÃO DO CHAT
  // ============================================================

  Future<void> _initializeChat() async {
    final privateApiService = PrivateApiService();

    _aiProviderService = AiProviderService(
      privateApiService: privateApiService,
    );

    final privateAiClient = PrivateAiClient();

    final remoteDatasource = ChatRemoteDatasource();

    final chatRepository = ChatRepositoryImpl(
      remoteDatasource: remoteDatasource,
      aiProviderService: _aiProviderService,
      privateAiClient: privateAiClient,
    );

    _controller = ChatController(
      repository: chatRepository,
      rhymesController: _rhymesController,
      onConfigurePrivateApi: _openPrivateApiOnboarding,
    );

    _controllerCreated = true;

    await _rhymesController.carregarDadosUsuario();

    if (!mounted) {
      return;
    }

    debugPrint(
      '[CHAT PAGE] '
      'Vocabulário antes da sessão: '
      '${_rhymesController.vocabularyWords}',
    );

    // ==========================================================
    // ATUALIZAR QUOTA REAL
    // ==========================================================
    //
    // O AiQuotaController já tenta restaurar o último valor
    // conhecido do cache local.
    //
    // Agora consultamos o backend para substituir o cache pelo
    // estado real atual, sem precisar enviar mensagem para a IA.
    //
    // Se a rede/backend falhar, mantemos o cache existente.
    //
    // ==========================================================

    await _refreshAiQuota(chatRepository);

    if (!mounted) {
      return;
    }

    await _syncAiSource(_aiProviderService);

    if (!mounted) {
      return;
    }

    if (_isSessionInitialized) {
      return;
    }

    _isSessionInitialized = true;

    await _controller.initChatSession(context);

    if (!mounted) {
      return;
    }

    setState(() {
      _isReady = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showAiGuideHintIfNeeded();
    });
  }

  // ============================================================
  // GUIA DE IA - PRIMEIRA VISITA
  // ============================================================

  Future<void> _showAiGuideHintIfNeeded() async {
    if (!mounted || _guidePulseCheckStarted) {
      return;
    }

    _guidePulseCheckStarted = true;

    if (!_onboardingPreferences.hasAuthenticatedUser) {
      return;
    }

    final alreadySeen = await _onboardingPreferences.loadAiGuideHintSeen();

    if (!mounted || alreadySeen) {
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 500));

    if (!mounted) {
      return;
    }

    for (var pulse = 0; pulse < 3; pulse++) {
      await _guidePulseController.forward();

      if (!mounted) {
        return;
      }

      await _guidePulseController.reverse();

      if (!mounted) {
        return;
      }

      if (pulse < 2) {
        await Future<void>.delayed(const Duration(milliseconds: 110));

        if (!mounted) {
          return;
        }
      }
    }

    _guidePulseController.value = 0;

    final saved = await _onboardingPreferences.markAiGuideHintSeen();

    debugPrint(
      '[CHAT PAGE] '
      'Destaque inicial do guia de IA concluído. '
      'Preferência salva: $saved',
    );
  }

  // ============================================================
  // REFRESH AI QUOTA
  // ============================================================
  //
  // Busca a quota atual no backend ao iniciar o chat.
  //
  // Fluxo:
  //
  // cache local
  //      ↓
  // interface recebe último valor conhecido
  //      ↓
  // fetchAiQuota()
  //      ↓
  // backend / Redis
  //      ↓
  // updateAiQuotaFromMap()
  //      ↓
  // AiQuotaController
  //      ↓
  // interface + novo cache
  //
  // IMPORTANTE:
  //
  // Uma falha nesta consulta não deve impedir a abertura do chat.
  // Nesse caso, o último valor disponível em cache continua sendo
  // utilizado.
  //
  // ============================================================

  Future<void> _refreshAiQuota(ChatRepositoryImpl chatRepository) async {
    try {
      debugPrint(
        '[CHAT PAGE] '
        'Atualizando quota real da IA Versin.',
      );

      final quota = await chatRepository.fetchAiQuota();

      if (!mounted) {
        return;
      }

      if (quota.isEmpty) {
        debugPrint(
          '[CHAT PAGE] '
          'Backend retornou quota vazia. '
          'Mantendo estado atual/cache.',
        );

        return;
      }

      _rhymesController.updateAiQuotaFromMap(quota, notify: true);

      debugPrint(
        '[CHAT PAGE] '
        'Quota real atualizada com sucesso.',
      );

      debugPrint(
        '[CHAT PAGE] '
        'Tokens usados: '
        '${_rhymesController.aiUsedTokens}',
      );

      debugPrint(
        '[CHAT PAGE] '
        'Tokens restantes: '
        '${_rhymesController.aiRemainingTokens}',
      );

      debugPrint(
        '[CHAT PAGE] '
        'Limite: '
        '${_rhymesController.aiLimitTokens}',
      );
    } catch (error, stackTrace) {
      debugPrint(
        '[CHAT PAGE] '
        'Não foi possível atualizar a quota real.',
      );

      debugPrint(
        '[CHAT PAGE] '
        'Mantendo último estado disponível em cache.',
      );

      debugPrint(
        '[CHAT PAGE] '
        'Erro: $error',
      );

      debugPrint(
        '[CHAT PAGE] '
        'Stack trace: $stackTrace',
      );
    }
  }

  // ============================================================
  // SINCRONIZAR FONTE DA IA
  // ============================================================

  Future<void> _syncAiSource(AiProviderService aiProviderService) async {
    try {
      final config = await aiProviderService.getPrivateConfig();

      if (!mounted) {
        return;
      }

      if (config.canUsePrivateApi) {
        _rhymesController.activatePrivateAi(
          provider: config.provider,

          model: config.model,
        );

        debugPrint(
          '[CHAT PAGE] '
          'API privada ativa: ${config.provider}',
        );

        return;
      }

      _rhymesController.activateVersinAi();

      debugPrint(
        '[CHAT PAGE] '
        'IA Versin ativa.',
      );
    } catch (error, stackTrace) {
      debugPrint(
        '[CHAT PAGE] '
        'Erro ao sincronizar fonte da IA: $error',
      );

      debugPrint(
        '[CHAT PAGE] '
        'Stack trace: $stackTrace',
      );

      if (mounted) {
        _rhymesController.activateVersinAi();
      }
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _guidePulseController.dispose();

    if (_controllerCreated) {
      _controller.dispose();
    }

    super.dispose();
  }

  // ============================================================
  // ABRIR ONBOARDING DA API PRIVADA
  // ============================================================
  //
  // Chamado pelos cards de continuidade da quota:
  //
  // - AiQuotaWarningCard;
  // - AiQuotaExhaustedCard.
  //
  // O ChatController recebe este método como callback e não
  // precisa conhecer Navigator nem a página de onboarding.
  //
  // ============================================================

  Future<void> _openPrivateApiOnboarding() async {
    if (!mounted) {
      return;
    }

    // ==========================================================
    // ABRIR ONBOARDING
    // ==========================================================
    //
    // Aguardamos o usuário concluir ou sair do fluxo.
    //
    // Depois que a rota fechar, verificamos novamente qual fonte
    // de IA está configurada.
    //
    // Isso evita exigir reinício do app ou reabertura do Chat.
    //
    // ==========================================================

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) {
          return const PrivateApiOnboardingPage();
        },
      ),
    );

    if (!mounted) {
      return;
    }

    // ==========================================================
    // RECARREGAR FONTE DE IA
    // ==========================================================

    await _syncAiSource(_aiProviderService);

    if (!mounted) {
      return;
    }

    // ==========================================================
    // ATUALIZAR INTERFACE
    // ==========================================================

    setState(() {});

    debugPrint(
      '[CHAT PAGE] '
      'Fonte de IA sincronizada após retornar '
      'da configuração privada.',
    );
  }

  // ============================================================
  // ABRIR GUIA DE USO DA IA
  // ============================================================
  //
  // O guia é apenas educativo.
  //
  // Ao clicar em "USAR":
  //
  // - NÃO envia a mensagem automaticamente;
  // - apenas preenche o campo do Chat;
  // - posiciona o cursor no final;
  // - o usuário pode editar antes de enviar.
  //
  // ============================================================

  Future<void> _openAiGuide() async {
    if (!mounted || !_controllerCreated) {
      return;
    }

    await ChatAiGuideModal.show(
      context: context,
      onUseExample: (example) {
        if (!mounted) {
          return;
        }

        final normalized = example.trim();

        if (normalized.isEmpty) {
          return;
        }

        _controller.messageController.value = TextEditingValue(
          text: normalized,
          selection: TextSelection.collapsed(offset: normalized.length),
        );
      },
    );
  }

  // ============================================================
  // ABRIR STUDIO
  // ============================================================

  void _abrirStudio() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) {
          return const StudioPage();
        },
      ),
    );
  }

  // ============================================================
  // ABRIR BIBLIOTECA
  // ============================================================

  void _abrirBiblioteca() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) {
          return RhymeLibraryPage(controller: _rhymesController);
        },
      ),
    );
  }

  // ============================================================
  // VOZ
  // ============================================================

  void _abrirPainelDeVoz(BuildContext context, Color activeColor) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return VoiceStudioPanel(
          activeColor: activeColor,
          onFinished: () {
            debugPrint('Gravação concluída no VoiceStudioPanel.');
          },
        );
      },
    );
  }

  // ============================================================
  // TIMELINE
  // ============================================================

  Future<void> _adicionarRimaTimeline(String rima) async {
    await _rhymesController.addWord(rima, false);
  }

  Future<void> _removerRimaTimeline(String rima) async {
    await _rhymesController.removeWordByValue(rima);
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (!_isReady) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F0F0F),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return AnimatedBuilder(
      animation: Listenable.merge([
        _controller,
        _rhymesController,
        _controller.messageController,
      ]),
      builder: (context, _) {
        final rhymesCtrl = _rhymesController;

        final activeColor = rhymesCtrl.getActiveColor();

        final savedRhymes = rhymesCtrl.vocabularyWords;

        return Scaffold(
          backgroundColor: const Color(0xFF0F0F0F),
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    // ==================================================
                    // TIMELINE
                    // ==================================================
                    VersinTimeline(
                      currentStep: rhymesCtrl.currentStep,
                      activeColor: activeColor,
                      savedRhymes: savedRhymes,
                      onAddRhyme: _adicionarRimaTimeline,
                      onRemoveRhyme: _removerRimaTimeline,
                      onTextChanged: rhymesCtrl.onTextChanged,
                    ),

                    // ==================================================
                    // HEADER
                    // ==================================================
                    Stack(
                      alignment: Alignment.centerRight,
                      children: [
                        ChatHeader(
                          activeColor: activeColor,
                          rhymesController: rhymesCtrl,
                        ),

                        // ==============================================
                        // AÇÕES DO HEADER
                        // ==============================================
                        Positioned(
                          right: 12,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // ========================================
                              // COMO USAR A IA
                              // ========================================
                              AnimatedBuilder(
                                animation: _guidePulseAnimation,
                                child: Tooltip(
                                  message: 'Como usar a IA',
                                  child: IconButton(
                                    onPressed: _openAiGuide,
                                    icon: Icon(
                                      Icons.info_outline_rounded,
                                      color: activeColor,
                                      size: 21,
                                    ),
                                  ),
                                ),
                                builder: (context, child) {
                                  final pulse = _guidePulseAnimation.value;

                                  return Transform.scale(
                                    scale: 1.0 + (0.08 * pulse),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: activeColor.withValues(
                                              alpha: 0.42 * pulse,
                                            ),
                                            blurRadius: 18 * pulse,
                                            spreadRadius: 3 * pulse,
                                          ),
                                        ],
                                      ),
                                      child: child,
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(width: 2),

                              // ========================================
                              // STUDIO
                              // ========================================
                              Tooltip(
                                message: 'Abrir Studio',
                                child: IconButton(
                                  onPressed: _abrirStudio,
                                  icon: Icon(
                                    Icons.edit_note_rounded,
                                    color: activeColor,
                                    size: 25,
                                  ),
                                ),
                              ),

                              const SizedBox(width: 2),

                              // ========================================
                              // BIBLIOTECA
                              // ========================================
                              Tooltip(
                                message: 'Biblioteca de Rimas',
                                child: IconButton(
                                  onPressed: _abrirBiblioteca,
                                  icon: Icon(
                                    Icons.library_books_outlined,
                                    color: activeColor,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // ==================================================
                    // CHAT
                    // ==================================================
                    Expanded(
                      child: ChatListView(
                        isInitializing: _controller.isInitializing,

                        messages: _controller.messages
                            .map<Map<String, dynamic>>((message) {
                              final data = message.toJson();

                              // =========================================
                              // WIDGET CUSTOMIZADO
                              // =========================================
                              //
                              // ChatMessage.toJson() não serializa Widget
                              // (e não deve serializar).
                              //
                              // Para a renderização em memória do chat,
                              // preservamos explicitamente customWidget.
                              //
                              // Isso permite que:
                              //
                              // - AiQuotaWarningCard;
                              // - AiQuotaExhaustedCard;
                              // - futuros cards do sistema;
                              //
                              // cheguem corretamente ao ChatListView.
                              //
                              // =========================================

                              if (message.customWidget != null) {
                                data['customWidget'] = message.customWidget;
                              }

                              return data;
                            })
                            .toList(),

                        isAiTyping: _controller.isAiTyping,

                        scrollController: _controller.scrollController,

                        activeColor: activeColor,

                        secondsActive: rhymesCtrl.connectionSeconds,

                        // ==============================================
                        // ADICIONAR RIMA PELO BOTÃO DIREITO
                        // ==============================================
                        onAddRhyme: (word) async {
                          final normalized = word.trim();

                          if (normalized.isEmpty) {
                            return;
                          }

                          await _rhymesController.addWord(normalized, false);
                        },

                        // ==============================================
                        // METRÔNOMO / BPM
                        // ==============================================
                        isBpmPlaying: rhymesCtrl.isBpmPlaying,

                        currentBpm: _controller.projectBpm,

                        onToggleBpm: _controller.toggleBpm,
                      ),
                    ),

                    // ==================================================
                    // TOOLBAR
                    // ==================================================
                    StudioToolbar(
                      isConfigFinished: true,
                      projectName: _controller.projectName,
                      onEditName: () {
                        _controller.editProjectName(context);
                      },
                      currentBpm: _controller.projectBpm,
                      selectedVibe: _controller.projectVibe,
                      selectedTechnique: _controller.projectTechnique,
                      activeColor: activeColor,

                      // ================================================
                      // ESTRUTURA
                      // ================================================
                      onShowStructure: () {
                        StructureEditorModal.show(
                          context: context,
                          initialStructure: _controller.lastConfirmedStructure,
                          activeColor: activeColor,
                          onSave: _controller.saveStructure,
                          onSendToChat: _controller.sendStructureToChat,
                          showQuickMenu: (title, options, onSelect) {
                            _controller.showStudioQuickMenu(
                              context,
                              title,
                              options,
                              onSelect,
                            );
                          },
                        );
                      },

                      // ================================================
                      // MENU
                      // ================================================
                      onShowMenu: (title, options, onSelect) {
                        _controller.showStudioQuickMenu(
                          context,
                          title,
                          options,
                          onSelect,
                        );
                      },

                      // ================================================
                      // BPM
                      // ================================================
                      onBpmChanged: (value) {
                        _controller.updateProjectBpm(value);
                      },

                      // ================================================
                      // TÉCNICA
                      // ================================================
                      onTechniqueChanged: (value) {
                        _controller.updateProjectTechnique(value);
                      },

                      // ================================================
                      // VIBE
                      // ================================================
                      onVibeChanged: (value) {
                        _controller.updateProjectVibe(value);
                      },
                    ),

                    // ==================================================
                    // INPUT
                    // ==================================================
                    Builder(
                      builder: (context) {
                        final hasSuggestion =
                            _controller.creationStage ==
                                ChatCreationStage.writing &&
                            rhymesCtrl.suggestions.isNotEmpty;

                        return Stack(
                          alignment: Alignment.centerRight,
                          children: [
                            ChatBottomBar(
                              messageController: _controller.messageController,
                              rhymesController: rhymesCtrl,
                              activeColor: activeColor,
                              creationStage: _controller.creationStage,

                              // =========================================
                              // SUGESTÃO DENTRO DO CAMPO
                              // =========================================
                              showSuggestion: hasSuggestion,

                              suggestionWidget: hasSuggestion
                                  ? SuggestionBalloon(
                                      controller:
                                          rhymesCtrl.suggestionController,
                                      suggestion: _controller
                                          .getCurrentSuggestion(),

                                      // =============================
                                      // USAR SUGESTÃO
                                      // =============================
                                      onTap: () {
                                        final suggestion = _controller
                                            .getCurrentSuggestion();

                                        final text =
                                            _controller.messageController.text;

                                        final words = text.trimRight().split(
                                          RegExp(r'\s+'),
                                        );

                                        if (words.isNotEmpty) {
                                          words.removeLast();

                                          words.add(suggestion);

                                          final newText = '${words.join(' ')} ';

                                          _controller
                                              .messageController
                                              .value = TextEditingValue(
                                            text: newText,
                                            selection: TextSelection.collapsed(
                                              offset: newText.length,
                                            ),
                                          );
                                        }

                                        rhymesCtrl.clearSuggestions();
                                      },

                                      // =============================
                                      // FECHAR
                                      // =============================
                                      onDismiss: () {
                                        rhymesCtrl.clearSuggestions();
                                      },

                                      // =============================
                                      // PEDIR EXEMPLO AO VERSIN
                                      // =============================
                                      onAddCommand: () {
                                        final word = _controller
                                            .getCurrentSuggestion();

                                        rhymesCtrl.clearSuggestions();

                                        _controller.processMessage(
                                          'Me dê um exemplo de rima com: $word',
                                        );
                                      },
                                    )
                                  : null,

                              // =========================================
                              // ENVIAR
                              // =========================================
                              onSend: (_) {
                                _controller.sendMessage();
                              },

                              currentSuggestionIndex:
                                  _controller.currentSuggestionIndex,

                              onUpdateSuggestionIndex:
                                  _controller.updateSuggestionIndex,

                              onAddRhyme: _controller.addWordToText,

                              // =========================================
                              // MICROFONE
                              // =========================================
                              onMicPressed: () {
                                _abrirPainelDeVoz(context, activeColor);
                              },
                            ),

                            // ===========================================
                            // METRÔNOMO
                            // ===========================================
                            Positioned(
                              right: 55,
                              bottom: 10,
                              child: MetronomePlayer(
                                isPlaying: rhymesCtrl.isBpmPlaying,
                                onTap: _controller.toggleBpm,
                                activeColor: activeColor,
                              ),
                            ),
                          ],
                        );
                      },
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
