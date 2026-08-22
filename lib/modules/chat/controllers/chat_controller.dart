import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'package:versin/features/rhymes/presentation/controller/rhymes_controller.dart';
import 'package:versin/modules/brain/controller/brain_controller.dart';
import 'package:versin/modules/chat/domain/repositories/chat_repository.dart';
import 'package:versin/modules/chat/models/chat_intent.dart';
import 'package:versin/modules/chat/models/ai_quota_warning_state.dart';
import 'package:versin/modules/chat/services/ai_request_gate_service.dart' as ai_gate;
import 'package:versin/modules/chat/services/ai_quota_warning_service.dart' as quota_warning;
import 'package:versin/modules/chat/views/widgets/ai_quota_exhausted_card.dart';
import 'package:versin/modules/chat/views/widgets/ai_quota_warning_card.dart';
import 'package:versin/modules/studio/controllers/studio_controller.dart';

// ============================================================
// CHAT ROLE
// ============================================================

enum ChatRole {
  user,
  assistant,
}

// ============================================================
// CHAT CREATION STAGE
// ============================================================

enum ChatCreationStage {
  imagination,
  writing,
}

// ============================================================
// CHAT MESSAGE
// ============================================================

class ChatMessage {
  final ChatRole role;

  final String content;

  final DateTime timestamp;

  final Widget? customWidget;

  ChatMessage({
    required this.role,
    required this.content,
    DateTime? timestamp,
    this.customWidget,
  }) : timestamp =
           timestamp ??
           DateTime.now();

  factory ChatMessage.fromJson(
    Map<
      String,
      dynamic
    >
    json,
  ) {
    return ChatMessage(
      role:
          json['role'] ==
              'user'
          ? ChatRole.user
          : ChatRole.assistant,
      content:
          json['content']?.toString() ??
          '',
      timestamp:
          json['timestamp'] !=
              null
          ? DateTime.parse(
              json['timestamp'],
            )
          : DateTime.now(),
    );
  }

  Map<
    String,
    dynamic
  >
  toJson() {
    return {
      'role': role.name,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  bool get isUser =>
      role ==
      ChatRole.user;
}

// ============================================================
// CHAT CONTROLLER
// ============================================================

class ChatController
    extends
        ChangeNotifier {
  // ============================================================
  // DEPENDÊNCIAS
  // ============================================================

  final ChatRepository repository;

  final RhymesController rhymesController;

  // ============================================================
  // ECONOMIA DE IA
  // ============================================================
  //
  // Filtra mensagens que podem ser resolvidas localmente antes
  // de qualquer chamada para Groq/API privada.
  //
  // ============================================================

  final ai_gate.AiRequestGateService _aiRequestGateService = ai_gate.AiRequestGateService();

  // ============================================================
  // AVISOS DE QUOTA
  // ============================================================
  //
  // O backend continua sendo a fonte da verdade da quota.
  //
  // Este service apenas transforma o estado recebido em decisão
  // de apresentação para o chat.
  //
  // ============================================================

  final quota_warning.AiQuotaWarningService _aiQuotaWarningService = quota_warning.AiQuotaWarningService();

  // ============================================================
  // CALLBACK DE CONFIGURAÇÃO DA API PRIVADA
  // ============================================================
  //
  // A tela que cria o ChatController pode fornecer este callback
  // para abrir o onboarding/configuração da API privada.
  //
  // O callback é opcional para manter compatibilidade com os
  // pontos existentes que já constroem o ChatController.
  //
  // ============================================================

  final VoidCallback? onConfigurePrivateApi;

  // ============================================================
  // AVISOS JÁ EXIBIDOS
  // ============================================================
  //
  // Evita inserir o mesmo card novamente em toda resposta.
  //
  // O ID inclui:
  //
  // - nível;
  // - data de renovação.
  //
  // Portanto um novo ciclo mensal gera novos IDs naturalmente.
  //
  // ============================================================

  final Set<
    String
  >
  _shownQuotaWarningIds =
      <
        String
      >{};

  late final StudioController studioController;

  // ============================================================
  // ÚLTIMO ESTADO SINCRONIZADO DO STUDIO
  // ============================================================

  late String _lastStudioTitle;

  late int _lastStudioBpm;

  String? _lastStudioVibe;

  String? _lastStudioTechnique;

  // ============================================================
  // BRAIN
  // ============================================================

  BrainController? get brain =>
      rhymesController
          is BrainController
      ? rhymesController
            as BrainController
      : null;

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController messageController = TextEditingController();

  final ScrollController scrollController = ScrollController();

  // ============================================================
  // MENSAGENS
  // ============================================================

  final List<
    ChatMessage
  >
  messages =
      <
        ChatMessage
      >[];

  // ============================================================
  // CREATION STAGE
  // ============================================================

  ChatCreationStage creationStage = ChatCreationStage.imagination;

  // ============================================================
  // ESTADO
  // ============================================================

  bool isAiTyping = false;

  final bool isInitializing = false;

  bool _isDisposed = false;

  // ============================================================
  // PROJETO COMPARTILHADO COM O STUDIO
  // ============================================================

  String get projectName => studioController.title;

  int get projectBpm => studioController.bpm;

  String get projectVibe =>
      studioController.vibe ??
      rhymesController.selectedVibe;

  String get projectTechnique =>
      studioController.technique ??
      rhymesController.selectedTechnique;

  // ============================================================
  // ESTRUTURA
  // ============================================================

  String lastConfirmedStructure = '';

  // ============================================================
  // SUGESTÕES
  // ============================================================

  int currentSuggestionIndex = 0;

  // ============================================================
  // TIMER
  // ============================================================

  Timer? _creativeHelpTimer;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  ChatController({
    required this.repository,
    required this.rhymesController,
    this.onConfigurePrivateApi,
  }) {
    // ==========================================================
    // STUDIO CONTROLLER GLOBAL
    // ==========================================================

    if (!GetIt.I
        .isRegistered<
          StudioController
        >()) {
      GetIt.I.registerLazySingleton<
        StudioController
      >(
        () => StudioController(
          rhymesController: rhymesController,
        ),
      );
    }

    studioController =
        GetIt.I<
          StudioController
        >();

    // ==========================================================
    // ESTADO INICIAL DA SESSÃO
    // ==========================================================

    _lastStudioTitle = studioController.title;

    _lastStudioBpm = studioController.bpm;

    _lastStudioVibe = studioController.vibe;

    _lastStudioTechnique = studioController.technique;

    studioController.addListener(
      _onStudioChanged,
    );

    // ==========================================================
    // SINCRONIZAR CONFIGURAÇÃO DA IA
    // ==========================================================

    rhymesController.updateStudioConfig(
      bpm: studioController.bpm,
      vibe:
          studioController.vibe ??
          rhymesController.selectedVibe,
      technique:
          studioController.technique ??
          rhymesController.selectedTechnique,
    );
  }

  // ============================================================
  // ALTERAÇÃO VINDO DO STUDIO
  // ============================================================

  void _onStudioChanged() {
    if (_isDisposed) {
      return;
    }

    final currentTitle = studioController.title;

    final currentBpm = studioController.bpm;

    final currentVibe = studioController.vibe;

    final currentTechnique = studioController.technique;

    // ==========================================================
    // BPM
    // ==========================================================

    if (currentBpm !=
        _lastStudioBpm) {
      _lastStudioBpm = currentBpm;

      rhymesController.updateStudioConfig(
        bpm: currentBpm,
      );
    }

    // ==========================================================
    // VIBE
    // ==========================================================

    if (currentVibe !=
        _lastStudioVibe) {
      _lastStudioVibe = currentVibe;

      if (currentVibe !=
              null &&
          currentVibe.trim().isNotEmpty) {
        rhymesController.updateStudioConfig(
          vibe: currentVibe,
        );
      }
    }

    // ==========================================================
    // TÉCNICA
    // ==========================================================

    if (currentTechnique !=
        _lastStudioTechnique) {
      _lastStudioTechnique = currentTechnique;

      if (currentTechnique !=
              null &&
          currentTechnique.trim().isNotEmpty) {
        rhymesController.updateStudioConfig(
          technique: currentTechnique,
        );
      }
    }

    // ==========================================================
    // TÍTULO
    // ==========================================================

    if (currentTitle !=
        _lastStudioTitle) {
      _lastStudioTitle = currentTitle;
    }

    notifyListeners();
  }

  // ============================================================
  // TÍTULO COMPARTILHADO
  // ============================================================

  void updateProjectName(
    String value,
  ) {
    final normalized = value.trim();

    if (normalized.isEmpty) {
      return;
    }

    _lastStudioTitle = normalized;

    studioController.updateTitle(
      normalized,
    );

    notifyListeners();
  }

  // ============================================================
  // BPM COMPARTILHADO
  // ============================================================

  void updateProjectBpm(
    int value,
  ) {
    if (value <=
        0) {
      return;
    }

    _lastStudioBpm = value;

    studioController.updateBpm(
      value,
    );

    rhymesController.updateStudioConfig(
      bpm: value,
    );

    notifyListeners();
  }

  // ============================================================
  // VIBE COMPARTILHADA
  // ============================================================

  void updateProjectVibe(
    String value,
  ) {
    final normalized = value.trim();

    if (normalized.isEmpty) {
      return;
    }

    _lastStudioVibe = normalized;

    studioController.updateVibe(
      normalized,
    );

    rhymesController.updateStudioConfig(
      vibe: normalized,
    );

    notifyListeners();
  }

  // ============================================================
  // TÉCNICA COMPARTILHADA
  // ============================================================

  void updateProjectTechnique(
    String value,
  ) {
    final normalized = value.trim();

    if (normalized.isEmpty) {
      return;
    }

    _lastStudioTechnique = normalized;

    studioController.updateTechnique(
      normalized,
    );

    rhymesController.updateStudioConfig(
      technique: normalized,
    );

    notifyListeners();
  }

  // ============================================================
  // STOP WORDS
  // ============================================================

  static const Set<
    String
  >
  _stopWords = {
    'a',
    'ao',
    'aos',
    'aquela',
    'aquele',
    'aqueles',
    'aquilo',
    'as',
    'até',
    'com',
    'como',
    'da',
    'das',
    'de',
    'dela',
    'dele',
    'deles',
    'depois',
    'do',
    'dos',
    'e',
    'ela',
    'ele',
    'eles',
    'em',
    'essa',
    'esse',
    'esta',
    'está',
    'estava',
    'este',
    'eu',
    'fica',
    'fico',
    'foi',
    'já',
    'lá',
    'mais',
    'mas',
    'me',
    'meu',
    'minha',
    'muito',
    'na',
    'nas',
    'no',
    'nos',
    'o',
    'os',
    'ou',
    'para',
    'pela',
    'pelo',
    'por',
    'porque',
    'que',
    'se',
    'sem',
    'só',
    'sou',
    'sua',
    'também',
    'tem',
    'tenho',
    'um',
    'uma',
    'vai',
    'vejo',
    'você',
  };

  // ============================================================
  // NOTIFY
  // ============================================================

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  // ============================================================
  // SUGESTÕES
  // ============================================================

  void nextSuggestion() {
    updateSuggestionIndex(
      currentSuggestionIndex +
          1,
    );
  }

  void previousSuggestion() {
    updateSuggestionIndex(
      currentSuggestionIndex -
          1,
    );
  }

  void updateSuggestionIndex(
    int index,
  ) {
    final total = rhymesController.suggestions.length;

    if (total ==
        0) {
      return;
    }

    currentSuggestionIndex =
        index %
        total;

    if (currentSuggestionIndex <
        0) {
      currentSuggestionIndex += total;
    }

    notifyListeners();
  }

  String getCurrentSuggestion() {
    final suggestions = rhymesController.suggestions;

    if (suggestions.isEmpty) {
      return 'Métrica';
    }

    return suggestions[currentSuggestionIndex %
        suggestions.length];
  }

  // ============================================================
  // PROCESS MESSAGE
  // ============================================================

  Future<
    void
  >
  processMessage(
    String message,
  ) async {
    messageController.text = message;

    await sendMessage();
  }

  // ============================================================
  // SEND MESSAGE
  // ============================================================

  Future<
    void
  >
  sendMessage() async {
    final text = messageController.text.trim();

    if (text.isEmpty) {
      return;
    }

    _cancelCreativeHelp();

    messages.add(
      ChatMessage(
        role: ChatRole.user,
        content: text,
      ),
    );

    messageController.clear();

    notifyListeners();

    _scrollToBottom();

    // ========================================================
    // GATE DE ECONOMIA
    // ========================================================
    //
    // O Gate sempre roda ANTES da IA.
    //
    // Social / fora do escopo / pedido incompleto:
    //     resposta local -> 0 tokens
    //
    // Busca simples de rima:
    //     biblioteca local -> 0 tokens
    //
    // Trabalho criativo real:
    //     segue o fluxo normal
    //
    // ========================================================

    final decision = _aiRequestGateService.evaluate(
      message: text,
      hasActiveCreativeContext: _hasActiveCreativeContext(),
    );

    debugPrint(
      '[CHAT GATE] Intent: ${decision.intent.name}',
    );

    debugPrint(
      '[CHAT GATE] Motivo: ${decision.reason}',
    );

    // ========================================================
    // RESPOSTA LOCAL
    // ========================================================

    if (decision.intent ==
            ChatIntent.social ||
        decision.intent ==
            ChatIntent.incompleteRequest ||
        decision.intent ==
            ChatIntent.outOfScope) {
      _addLocalAssistantMessage(
        decision.localResponse ??
            _aiRequestGateService.localResponseService.responseFor(
              intent: decision.intent,
              message: text,
            ),
      );

      return;
    }

    // ========================================================
    // BUSCA DE RIMA NA BIBLIOTECA
    // ========================================================

    if (decision.intent ==
        ChatIntent.rhymeSearch) {
      await _handleLibraryRhymeSearch(
        query:
            decision.libraryQuery ??
            _extractRhymeTerm(
              text,
            ),
      );

      return;
    }

    // ========================================================
    // CHAT NORMAL
    // ========================================================
    //
    // Desde a primeira mensagem:
    //
    // - NÃO extraímos palavras automaticamente;
    // - NÃO salvamos conteúdo na biblioteca;
    // - NÃO usamos a etapa de imaginação como interceptador;
    // - a mensagem segue o fluxo normal da conversa.
    //
    // Rimas explícitas continuam sendo tratadas acima pelo
    // ChatIntent.rhymeSearch.
    //
    // ========================================================

    creationStage = ChatCreationStage.writing;

    await _sendToAi(
      text,
    );
  }

  // ============================================================
  // CONTEXTO CRIATIVO ATIVO
  // ============================================================

  bool _hasActiveCreativeContext() {
    if (creationStage !=
        ChatCreationStage.writing) {
      return false;
    }

    if (messages.length <
        2) {
      return false;
    }

    final recent =
        messages.length <=
            8
        ? messages
        : messages.sublist(
            messages.length -
                8,
          );

    final hasUserMessage = recent.any(
      (
        message,
      ) =>
          message.role ==
          ChatRole.user,
    );

    final hasAssistantMessage = recent.any(
      (
        message,
      ) =>
          message.role ==
          ChatRole.assistant,
    );

    return hasUserMessage &&
        hasAssistantMessage;
  }

  // ============================================================
  // ADICIONAR RESPOSTA LOCAL
  // ============================================================

  void _addLocalAssistantMessage(
    String content,
  ) {
    final normalized = content.trim();

    if (normalized.isEmpty) {
      return;
    }

    messages.add(
      ChatMessage(
        role: ChatRole.assistant,
        content: normalized,
      ),
    );

    debugPrint(
      '[CHAT GATE] Resposta local. 0 tokens consumidos.',
    );

    notifyListeners();

    _scrollToBottom();
  }

  // ============================================================
  // BUSCAR RIMAS NA BIBLIOTECA
  // ============================================================

  Future<
    void
  >
  _handleLibraryRhymeSearch({
    required String query,
  }) async {
    final normalizedQuery = query.trim();

    if (normalizedQuery.isEmpty) {
      _addLocalAssistantMessage(
        _aiRequestGateService.localResponseService.rhymeSearchFallback(),
      );

      return;
    }

    // Garante que a memória criativa esteja disponível.
    await rhymesController.carregarDadosUsuario();

    if (_isDisposed) {
      return;
    }

    final matches = _findLibraryRhymes(
      normalizedQuery,
    );

    if (matches.isEmpty) {
      _addLocalAssistantMessage(
        'Não encontrei rimas para "$normalizedQuery" na sua biblioteca ainda. '
        'Se quiser uma busca criativa nova, me manda o contexto em que você quer usar a palavra.',
      );

      return;
    }

    final preview = matches
        .take(
          12,
        )
        .join(
          ' • ',
        );

    _addLocalAssistantMessage(
      'Na sua biblioteca, encontrei para "$normalizedQuery":\n\n$preview',
    );
  }

  // ============================================================
  // FILTRAR RIMAS LOCAIS
  // ============================================================
  //
  // A biblioteca atual guarda palavras. Como ainda não existe um
  // índice fonético dedicado, usamos terminações como filtro local.
  // Isso é propositalmente barato e não chama IA.
  //
  // ============================================================

  List<
    String
  >
  _findLibraryRhymes(
    String query,
  ) {
    final normalizedQuery = _normalizeRhymeWord(
      query,
    );

    if (normalizedQuery.isEmpty) {
      return const [];
    }

    final queryEnding = _rhymeEnding(
      normalizedQuery,
    );

    final results =
        <
          String
        >[];

    for (final rawWord in rhymesController.vocabularyWords) {
      final word = rawWord.trim();

      if (word.isEmpty) {
        continue;
      }

      final normalizedWord = _normalizeRhymeWord(
        word,
      );

      if (normalizedWord.isEmpty ||
          normalizedWord ==
              normalizedQuery) {
        continue;
      }

      final wordEnding = _rhymeEnding(
        normalizedWord,
      );

      if (wordEnding !=
          queryEnding) {
        continue;
      }

      if (results.any(
        (
          existing,
        ) =>
            _normalizeRhymeWord(
              existing,
            ) ==
            normalizedWord,
      )) {
        continue;
      }

      results.add(
        word,
      );
    }

    return results;
  }

  String _normalizeRhymeWord(
    String value,
  ) {
    var normalized = value.trim().toLowerCase();

    const source = 'áàãâäéèêëíìîïóòõôöúùûüç';

    const target = 'aaaaaeeeeiiiiooooouuuuc';

    for (
      var index = 0;
      index <
          source.length;
      index++
    ) {
      normalized = normalized.replaceAll(
        source[index],
        target[index],
      );
    }

    normalized = normalized.replaceAll(
      RegExp(
        r'[^a-z0-9]',
      ),
      '',
    );

    return normalized;
  }

  String _rhymeEnding(
    String word,
  ) {
    if (word.length <=
        3) {
      return word;
    }

    return word.substring(
      word.length -
          3,
    );
  }

  // ============================================================
  // EXTRAIR TERMO DE RIMA — FALLBACK
  // ============================================================

  String _extractRhymeTerm(
    String message,
  ) {
    final normalized = message.trim();

    final patterns =
        <
          RegExp
        >[
          RegExp(
            r'(?:rimas?|rima)\s+(?:com|para|pra|de)\s+(.+)$',
            caseSensitive: false,
          ),
          RegExp(
            r'rimam?\s+com\s+(.+)$',
            caseSensitive: false,
          ),
          RegExp(
            r'o\s+que\s+rima\s+com\s+(.+)$',
            caseSensitive: false,
          ),
        ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(
        normalized,
      );

      final value = match
          ?.group(
            1,
          )
          ?.replaceAll(
            RegExp(
              r'[?!.,;:]+$',
            ),
            '',
          )
          .trim();

      if (value !=
              null &&
          value.isNotEmpty) {
        return value;
      }
    }

    return '';
  }

  // ============================================================
  // PROCESSAR IMAGINAÇÃO
  // ============================================================

  Future<
    void
  >
  _processInitialImagination(
    String text,
  ) async {
    // ==========================================================
    // COMPATIBILIDADE
    // ==========================================================
    //
    // O fluxo antigo analisava a primeira mensagem e salvava
    // palavras automaticamente na biblioteca.
    //
    // Isso foi removido.
    //
    // A biblioteca agora só deve ser alterada por ações
    // explícitas do usuário em recursos próprios de vocabulário,
    // rimas ou Studio.
    //
    // ==========================================================

    final normalized = text.trim();

    if (normalized.isEmpty ||
        _isDisposed) {
      return;
    }

    creationStage = ChatCreationStage.writing;

    notifyListeners();
  }

  // ============================================================
  // EXTRAIR PALAVRAS CRIATIVAS
  // ============================================================

  List<
    String
  >
  _extractCreativeWords(
    String text,
  ) {
    final normalized = text.toLowerCase().replaceAll(
      RegExp(
        r'[^\p{L}\p{N}\s]',
        unicode: true,
      ),
      ' ',
    );

    final words = normalized.split(
      RegExp(
        r'\s+',
      ),
    );

    final extracted =
        <
          String
        >[];

    for (final rawWord in words) {
      final word = rawWord.trim();

      if (word.length <
          4) {
        continue;
      }

      if (_stopWords.contains(
        word,
      )) {
        continue;
      }

      if (extracted.contains(
        word,
      )) {
        continue;
      }

      extracted.add(
        word,
      );

      if (extracted.length >=
          8) {
        break;
      }
    }

    return extracted;
  }

  // ============================================================
  // SEND TO AI
  // ============================================================

  Future<
    void
  >
  _sendToAi(
    String text,
  ) async {
    final normalizedText = text.trim();

    if (normalizedText.isEmpty) {
      return;
    }

    isAiTyping = true;

    notifyListeners();

    _scrollToBottom();

    try {
      // ========================================================
      // REQUEST
      // ========================================================

      final response = await repository.fetchAiResponse(
        normalizedText,
      );

      // ========================================================
      // METADADOS
      // ========================================================
      //
      // Mantém compatibilidade com o fluxo já existente.
      //
      // ========================================================

      rhymesController.applyAiResponseMetadata(
        response,
      );

      // ========================================================
      // QUOTA
      // ========================================================
      //
      // Agora o repository preserva:
      //
      // response['quota']
      //
      // vindo do backend.
      //
      // Fazemos atualização explícita para garantir:
      //
      // backend
      //   ↓
      // quota
      //   ↓
      // ChatController
      //   ↓
      // RhymesController
      //   ↓
      // AiQuotaController
      //   ↓
      // card IA mensal
      //
      // ========================================================

      final quota = _extractMap(
        response['quota'],
      );

      if (quota !=
          null) {
        rhymesController.updateAiQuotaFromMap(
          quota,
          notify: true,
        );

        // ======================================================
        // AVISO DE QUOTA NO CHAT
        // ======================================================
        //
        // O mesmo Map retornado pelo backend é convertido para o
        // estado tipado utilizado pelos cards.
        //
        // Nenhuma chamada extra ao backend é feita aqui.
        //
        // ======================================================

        _handleQuotaWarning(
          quota,
        );

        debugPrint(
          '[CHAT CONTROLLER] '
          'Quota Versin atualizada.',
        );

        debugPrint(
          '[CHAT CONTROLLER] '
          'Tokens usados: '
          '${rhymesController.aiUsedTokens}',
        );

        debugPrint(
          '[CHAT CONTROLLER] '
          'Tokens restantes: '
          '${rhymesController.aiRemainingTokens}',
        );

        debugPrint(
          '[CHAT CONTROLLER] '
          'Limite: '
          '${rhymesController.aiLimitTokens}',
        );
      } else {
        debugPrint(
          '[CHAT CONTROLLER] '
          'Resposta sem quota.',
        );
      }

      // ========================================================
      // CONTENT
      // ========================================================

      final content = response['content']?.toString().trim();

      if (content !=
              null &&
          content.isNotEmpty) {
        messages.add(
          ChatMessage(
            role: ChatRole.assistant,
            content: content,
          ),
        );
      } else {
        messages.add(
          ChatMessage(
            role: ChatRole.assistant,
            content: 'Resposta em branco.',
          ),
        );
      }

      // ========================================================
      // SOURCE
      // ========================================================

      final usedVersinApi =
          response['used_versin_api'] ==
          true;

      final usedPrivateApi =
          response['used_private_api'] ==
          true;

      final provider = response['provider']?.toString().trim();

      final model = response['model']?.toString().trim();

      // ========================================================
      // LOG
      // ========================================================

      debugPrint(
        '[CHAT CONTROLLER] '
        'Resposta recebida.',
      );

      debugPrint(
        '[CHAT CONTROLLER] '
        'IA Versin: '
        '$usedVersinApi',
      );

      debugPrint(
        '[CHAT CONTROLLER] '
        'API privada: '
        '$usedPrivateApi',
      );

      if (provider !=
              null &&
          provider.isNotEmpty) {
        debugPrint(
          '[CHAT CONTROLLER] '
          'Provider: '
          '$provider',
        );
      }

      if (model !=
              null &&
          model.isNotEmpty) {
        debugPrint(
          '[CHAT CONTROLLER] '
          'Modelo: '
          '$model',
        );
      }
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[CHAT CONTROLLER] '
        'Erro ao enviar mensagem: '
        '$error',
      );

      debugPrint(
        '[CHAT CONTROLLER] '
        'Stack trace: '
        '$stackTrace',
      );

      messages.add(
        ChatMessage(
          role: ChatRole.assistant,
          content: _buildAiErrorMessage(
            error,
          ),
        ),
      );
    } finally {
      isAiTyping = false;

      notifyListeners();

      _scrollToBottom();
    }
  }

  // ============================================================
  // PROCESSAR AVISO DE QUOTA
  // ============================================================
  //
  // Fluxo:
  //
  // quota do backend
  //      ↓
  // AiQuotaWarningState
  //      ↓
  // normal
  //      → não mostra nada
  //
  // warning / critical
  //      → AiQuotaWarningCard
  //
  // blocked
  //      → AiQuotaExhaustedCard
  //
  // ============================================================

  void _handleQuotaWarning(
    Map<
      String,
      dynamic
    >
    quota,
  ) {
    final state = AiQuotaWarningState.fromMap(
      quota,
    );

    // ==========================================================
    // NORMAL
    // ==========================================================

    if (!_aiQuotaWarningService.shouldShowWarning(
      state,
    )) {
      return;
    }

    // ==========================================================
    // ID ÚNICO DO AVISO
    // ==========================================================

    final warningId = _aiQuotaWarningService.buildWarningId(
      state,
    );

    if (_shownQuotaWarningIds.contains(
      warningId,
    )) {
      debugPrint(
        '[CHAT QUOTA] '
        'Aviso já exibido: $warningId',
      );

      return;
    }

    _shownQuotaWarningIds.add(
      warningId,
    );

    // ==========================================================
    // ESGOTADO
    // ==========================================================

    if (_aiQuotaWarningService.shouldShowExhaustedCard(
      state,
    )) {
      messages.add(
        ChatMessage(
          role: ChatRole.assistant,
          content: '',
          customWidget: AiQuotaExhaustedCard(
            state: state,
            onConfigurePrivateApi: _requestPrivateApiConfiguration,
          ),
        ),
      );

      debugPrint(
        '[CHAT QUOTA] '
        'Card de créditos esgotados adicionado.',
      );

      return;
    }

    // ==========================================================
    // WARNING / CRITICAL
    // ==========================================================

    if (_aiQuotaWarningService.shouldShowLowQuotaWarning(
      state,
    )) {
      messages.add(
        ChatMessage(
          role: ChatRole.assistant,
          content: '',
          customWidget: AiQuotaWarningCard(
            state: state,
            onConfigurePrivateApi: state.isCritical
                ? _requestPrivateApiConfiguration
                : null,
          ),
        ),
      );

      debugPrint(
        '[CHAT QUOTA] '
        'Aviso de quota adicionado. '
        'Nível: ${state.level.name}',
      );
    }
  }

  // ============================================================
  // SOLICITAR CONFIGURAÇÃO DA API PRIVADA
  // ============================================================
  //
  // O controller não conhece Navigator nem uma página específica.
  //
  // Isso mantém:
  //
  // Controller
  //      ↓
  // callback
  //      ↓
  // UI decide qual tela abrir
  //
  // ============================================================

  void _requestPrivateApiConfiguration() {
    final callback = onConfigurePrivateApi;

    if (callback !=
        null) {
      callback();

      return;
    }

    debugPrint(
      '[CHAT QUOTA] '
      'Configuração de API privada solicitada, '
      'mas nenhum callback foi fornecido ao ChatController.',
    );
  }

  // ============================================================
  // LIMPAR HISTÓRICO DE AVISOS
  // ============================================================
  //
  // Útil em testes ou quando uma sessão for reiniciada
  // explicitamente.
  //
  // Não altera a quota do backend.
  //
  // ============================================================

  void clearQuotaWarningHistory() {
    _shownQuotaWarningIds.clear();
  }

  // ============================================================
  // EXTRAIR MAP
  // ============================================================

  static Map<
    String,
    dynamic
  >?
  _extractMap(
    dynamic value,
  ) {
    if (value ==
        null) {
      return null;
    }

    if (value
        is Map<
          String,
          dynamic
        >) {
      if (value.isEmpty) {
        return null;
      }

      return Map<
        String,
        dynamic
      >.from(
        value,
      );
    }

    if (value
        is Map) {
      try {
        final converted =
            Map<
              String,
              dynamic
            >.from(
              value,
            );

        if (converted.isEmpty) {
          return null;
        }

        return converted;
      } catch (
        _
      ) {
        return null;
      }
    }

    return null;
  }

  // ============================================================
  // AI ERROR MESSAGE
  // ============================================================

  String _buildAiErrorMessage(
    Object error,
  ) {
    final normalized = error.toString().toLowerCase();

    if (normalized.contains(
      'unimplemented',
    )) {
      return 'A API privada está configurada, '
          'mas o cliente desse provedor ainda não foi conectado.';
    }

    if (normalized.contains(
          'timeout',
        ) ||
        normalized.contains(
          'timed out',
        )) {
      return 'A IA demorou demais para responder. '
          'Tente novamente.';
    }

    if (normalized.contains(
          '401',
        ) ||
        normalized.contains(
          'unauthorized',
        ) ||
        normalized.contains(
          'não autorizado',
        )) {
      return 'Não foi possível autenticar a API. '
          'Verifique a credencial configurada.';
    }

    if (normalized.contains(
          '429',
        ) ||
        normalized.contains(
          'quota',
        ) ||
        normalized.contains(
          'limite',
        )) {
      return 'O limite de uso da IA foi atingido '
          'ou o provedor recusou novas requisições.';
    }

    return 'Erro de conexão com a IA. '
        'Tente novamente.';
  }

  // ============================================================
  // SEND STRUCTURE
  // ============================================================

  void sendStructureToChat(
    List<
      String
    >
    structure,
  ) {
    final structureText = structure.join(
      ' - ',
    );

    messages.add(
      ChatMessage(
        role: ChatRole.assistant,
        content:
            'Estrutura definida: '
            '$structureText',
      ),
    );

    notifyListeners();

    _scrollToBottom();
  }

  // ============================================================
  // SAVE STRUCTURE
  // ============================================================

  void saveStructure(
    String structure,
  ) {
    lastConfirmedStructure = structure;

    notifyListeners();
  }

  // ============================================================
  // ADD WORD
  // ============================================================

  void addWordToText(
    String word,
  ) {
    final current = messageController.text.trim();

    messageController.text = current.isEmpty
        ? '$word '
        : '$current $word ';

    messageController.selection = TextSelection.collapsed(
      offset: messageController.text.length,
    );

    notifyListeners();
  }

  // ============================================================
  // BPM
  // ============================================================

  void toggleBpm() {
    rhymesController.isBpmPlaying = !rhymesController.isBpmPlaying;

    notifyListeners();
  }

  // ============================================================
  // EDIT PROJECT NAME
  // ============================================================

  void editProjectName(
    BuildContext context,
  ) {
    String draftName = projectName;

    showDialog<
      void
    >(
      context: context,
      barrierDismissible: true,
      builder:
          (
            dialogContext,
          ) {
            return AlertDialog(
              backgroundColor: const Color(
                0xFF1A1A1A,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  18,
                ),
              ),
              title: const Text(
                'Nome do Projeto',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: TextFormField(
                initialValue: projectName,
                autofocus: true,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                cursorColor: const Color(
                  0xFFE100FF,
                ),
                textInputAction: TextInputAction.done,
                onChanged:
                    (
                      value,
                    ) {
                      draftName = value;
                    },
                onFieldSubmitted:
                    (
                      value,
                    ) {
                      final name = value.trim();

                      if (name.isEmpty) {
                        return;
                      }

                      updateProjectName(
                        name,
                      );

                      Navigator.of(
                        dialogContext,
                      ).pop();
                    },
                decoration: InputDecoration(
                  hintText: 'Nome da música',
                  hintStyle: const TextStyle(
                    color: Colors.white30,
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(
                    alpha: 0.04,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      12,
                    ),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(
                        alpha: 0.08,
                      ),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      12,
                    ),
                    borderSide: const BorderSide(
                      color: Color(
                        0xFFE100FF,
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(
                      dialogContext,
                    ).pop();
                  },
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(
                      color: Colors.white54,
                    ),
                  ),
                ),
                FilledButton(
                  onPressed: () {
                    final name = draftName.trim();

                    if (name.isEmpty) {
                      return;
                    }

                    updateProjectName(
                      name,
                    );

                    Navigator.of(
                      dialogContext,
                    ).pop();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(
                      0xFFE100FF,
                    ),
                    foregroundColor: Colors.black,
                  ),
                  child: const Text(
                    'Salvar',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            );
          },
    );
  }

  // ============================================================
  // STUDIO QUICK MENU
  // ============================================================

  void showStudioQuickMenu(
    BuildContext context,
    String title,
    List<
      String
    >
    options,
    Function(
      String,
    )
    onSelect,
  ) {
    showModalBottomSheet(
      context: context,
      builder:
          (
            context,
          ) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(
                      16,
                    ),
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ...options.map(
                  (
                    option,
                  ) {
                    return ListTile(
                      title: Text(
                        option,
                      ),
                      onTap: () {
                        onSelect(
                          option,
                        );

                        Navigator.pop(
                          context,
                        );
                      },
                    );
                  },
                ),
              ],
            );
          },
    );
  }

  // ============================================================
  // INIT CHAT SESSION
  // ============================================================

  Future<
    void
  >
  initChatSession(
    BuildContext context,
  ) async {
    if (messages.isNotEmpty) {
      return;
    }

    // ==========================================================
    // CARREGAR MEMÓRIA DO USUÁRIO
    // ==========================================================
    //
    // O vocabulário continua disponível para recursos explícitos
    // de rima/biblioteca, mas NÃO controla mais a primeira
    // mensagem do Chat.
    //
    // ==========================================================

    await rhymesController.carregarDadosUsuario();

    if (_isDisposed) {
      return;
    }

    // ==========================================================
    // CHAT NORMAL DESDE O INÍCIO
    // ==========================================================
    //
    // Nenhuma mensagem automática.
    // Nenhum salvamento automático na biblioteca.
    // A primeira mensagem do usuário segue para a IA normalmente.
    //
    // ==========================================================

    creationStage = ChatCreationStage.writing;

    notifyListeners();

    _scrollToBottom();
  }

  // ============================================================
  // CREATIVE HELP
  // ============================================================

  void _startCreativeHelpTimer() {
    // Mensagens automáticas de ajuda inicial desativadas.
    _creativeHelpTimer?.cancel();
    _creativeHelpTimer = null;
  }

  // ============================================================
  // CANCEL CREATIVE HELP
  // ============================================================

  void _cancelCreativeHelp() {
    _creativeHelpTimer?.cancel();

    _creativeHelpTimer = null;
  }

  // ============================================================
  // SCROLL
  // ============================================================

  void _scrollToBottom() {
    if (_isDisposed) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback(
      (
        _,
      ) {
        if (_isDisposed ||
            !scrollController.hasClients) {
          return;
        }

        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(
            milliseconds: 300,
          ),
          curve: Curves.easeOut,
        );
      },
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _isDisposed = true;

    studioController.removeListener(
      _onStudioChanged,
    );

    _creativeHelpTimer?.cancel();

    _shownQuotaWarningIds.clear();

    messageController.dispose();

    scrollController.dispose();

    super.dispose();
  }
}
