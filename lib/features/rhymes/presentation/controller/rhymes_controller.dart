import 'package:flutter/material.dart';

import 'package:versin/core/models/rhyme_model.dart';
import 'package:versin/features/rhymes/domain/services/audio_service.dart';
import 'package:versin/modules/chat/ai/controllers/ai_quota_controller.dart';
import 'package:versin/modules/chat/ai/controllers/ai_source_controller.dart';
import 'package:versin/modules/chat/vocabulary/controllers/vocabulary_controller.dart';
import 'package:versin/modules/chat/rhymes/services/rhyme_suggestion_service.dart';
import 'package:versin/modules/chat/rhymes/services/rhymes_ai_service.dart';
import 'package:versin/modules/chat/vocabulary/services/vocabulary_service.dart';
import 'package:versin/modules/chat/views/components/suggestion_balloon/controllers/suggestion_controller.dart';

// ============================================================
// RHYMES CONTROLLER
// ============================================================
//
// Responsável por orquestrar o estado utilizado pela interface
// de composição.
//
// As responsabilidades maiores foram extraídas para:
//
// VocabularyController
// AiQuotaController
// AiSourceController
// RhymeSuggestionService
// RhymesAiService
//
// O RhymesController mantém uma camada de compatibilidade para
// os widgets que já utilizavam sua API pública.
//
// ============================================================

class RhymesController
    extends
        ChangeNotifier {
  // ============================================================
  // ÁUDIO
  // ============================================================

  final AudioService _audioService = AudioService();

  // ============================================================
  // SUGESTÕES
  // ============================================================

  final SuggestionController suggestionController = SuggestionController();

  late final RhymeSuggestionService _rhymeSuggestionService;

  // ============================================================
  // VOCABULARY
  // ============================================================

  final VocabularyController vocabularyController = VocabularyController(
    service: VocabularyService(),
  );

  // ============================================================
  // IA
  // ============================================================

  final AiQuotaController aiQuotaController = AiQuotaController();

  final AiSourceController aiSourceController = AiSourceController();

  final RhymesAiService _rhymesAiService = RhymesAiService();

  // ============================================================
  // PROGRESSO
  // ============================================================

  int _currentStep = 1;

  double _stepProgress = 0.0;

  // ============================================================
  // API KEY LEGADA
  // ============================================================

  String? _userApiKey;

  // ============================================================
  // ESTÚDIO
  // ============================================================

  String selectedTechnique = 'Melódico';

  String selectedVibe = 'Calmo';

  int currentBpm = 120;

  bool isBpmPlaying = false;

  // ============================================================
  // TRENDING
  // ============================================================

  List<
    Map<
      String,
      dynamic
    >
  >
  trendingWords = [];

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  RhymesController() {
    _rhymeSuggestionService = RhymeSuggestionService(
      suggestionController: suggestionController,
    );

    vocabularyController.addListener(
      _onChildControllerChanged,
    );

    aiQuotaController.addListener(
      _onChildControllerChanged,
    );

    aiSourceController.addListener(
      _onChildControllerChanged,
    );

    _rhymesAiService.addListener(
      _onChildControllerChanged,
    );
  }

  // ============================================================
  // PROPAGAR ALTERAÇÕES
  // ============================================================

  void _onChildControllerChanged() {
    notifyListeners();
  }

  // ============================================================
  // GETTERS GERAIS
  // ============================================================

  List<
    String
  >
  get suggestions => suggestionController.suggestions;

  bool get isLoading => _rhymesAiService.isLoading;

  bool get isVocabularyLoading => vocabularyController.isLoading;

  int get currentStep => _currentStep;

  double get stepProgress => _stepProgress;

  int get connectionSeconds => _rhymesAiService.connectionSeconds;

  // ============================================================
  // VOCABULARY GETTERS
  // ============================================================

  List<
    Rhyme
  >
  get vocabulary => vocabularyController.vocabulary;

  List<
    String
  >
  get vocabularyWords => vocabularyController.vocabularyWords;

  int get vocabularyCount => vocabularyController.vocabularyCount;

  // ============================================================
  // IA - QUOTA
  // ============================================================

  double get aiUsagePercentage => aiQuotaController.usagePercentage;

  double get aiUsageProgress => aiQuotaController.usageProgress;

  String get aiUsageLevel {
    if (usingPrivateApi) {
      return 'private';
    }

    return aiQuotaController.usageLevel;
  }

  String get aiUsageMessage {
    if (usingPrivateApi) {
      final provider = activeAiProvider?.trim();

      if (provider !=
              null &&
          provider.isNotEmpty &&
          provider.toLowerCase() !=
              'private') {
        return 'API privada $provider ativa. '
            'A cota mensal do Versin não está sendo consumida.';
      }

      return 'API privada ativa. '
          'A cota mensal do Versin não está sendo consumida.';
    }

    return aiQuotaController.usageMessage;
  }

  bool get aiQuotaBlocked {
    if (usingPrivateApi) {
      return false;
    }

    return aiQuotaController.quotaBlocked;
  }

  bool get aiCanUse {
    if (usingPrivateApi) {
      return true;
    }

    return aiQuotaController.canUse;
  }

  int get aiUsedTokens => aiQuotaController.usedTokens;

  int get aiRemainingTokens => aiQuotaController.remainingTokens;

  int get aiLimitTokens => aiQuotaController.limitTokens;

  // ============================================================
  // IA - SOURCE
  // ============================================================

  bool get usingPrivateApi => aiSourceController.usingPrivateApi;

  bool get usingVersinApi => aiSourceController.usingVersinApi;

  String? get activeAiProvider {
    final provider = aiSourceController.provider.trim();

    if (provider.isEmpty) {
      return null;
    }

    return provider;
  }

  String? get activeAiModel => aiSourceController.model;

  String? get userApiKey => _userApiKey;

  // ============================================================
  // VOCABULARY - CONTÉM
  // ============================================================

  bool containsWord(
    String word,
  ) {
    return vocabularyController.containsWord(
      word,
    );
  }

  // ============================================================
  // VOCABULARY - ADICIONAR
  // ============================================================

  Future<
    void
  >
  addWord(
    String word,
    bool priority,
  ) async {
    await vocabularyController.addWord(
      word,
      priority,
    );
  }

  // ============================================================
  // VOCABULARY - ADICIONAR VÁRIAS
  // ============================================================

  Future<
    int
  >
  addWords(
    Iterable<
      String
    >
    words, {
    bool priority = false,
  }) {
    return vocabularyController.addWords(
      words,
      priority: priority,
    );
  }

  // ============================================================
  // VOCABULARY - REMOVER ÍNDICE
  // ============================================================

  Future<
    void
  >
  removeWord(
    int index,
  ) async {
    await vocabularyController.removeWord(
      index,
    );
  }

  // ============================================================
  // VOCABULARY - REMOVER VALOR
  // ============================================================

  Future<
    void
  >
  removeWordByValue(
    String word,
  ) async {
    await vocabularyController.removeWordByValue(
      word,
    );
  }

  // ============================================================
  // VOCABULARY - REORDENAR
  // ============================================================
  //
  // A lista pública do VocabularyController é somente leitura.
  //
  // Por isso, toda a mutação deve acontecer dentro do próprio
  // VocabularyController através de reorder(...).
  //
  // ============================================================

  void reorderVocabulary(
    int oldIndex,
    int newIndex,
  ) {
    vocabularyController.reorder(
      oldIndex,
      newIndex,
    );
  }

  // ============================================================
  // VOCABULARY - CARREGAR
  // ============================================================

  Future<
    void
  >
  carregarDadosUsuario() {
    return vocabularyController.load();
  }

  // ============================================================
  // TRENDING
  // ============================================================

  Future<
    void
  >
  fetchTrendingWords() async {
    trendingWords = [
      {
        'word': 'Flow',
        'count': 150,
      },
      {
        'word': 'Beat',
        'count': 120,
      },
    ];

    notifyListeners();
  }

  // ============================================================
  // API KEY LEGADA
  // ============================================================

  void setApiKey(
    String key,
  ) {
    final normalized = key.trim();

    _userApiKey = normalized.isEmpty
        ? null
        : normalized;

    notifyListeners();
  }

  // ============================================================
  // DEFINIR FONTE DA IA
  // ============================================================

  void setAiSource({
    required bool usingPrivateApi,
    String? provider,
    String? model,
    bool notify = true,
  }) {
    if (usingPrivateApi) {
      aiSourceController.activatePrivate(
        provider: _normalizeProvider(
          provider,
        ),
        model: model,
        notify: notify,
      );

      return;
    }

    aiSourceController.activateVersin(
      notify: notify,
    );
  }

  // ============================================================
  // NORMALIZAR PROVIDER
  // ============================================================

  String _normalizeProvider(
    String? provider,
  ) {
    final normalized = provider?.trim();

    if (normalized ==
            null ||
        normalized.isEmpty) {
      return 'private';
    }

    return normalized;
  }

  // ============================================================
  // APLICAR METADADOS DA IA
  // ============================================================

  void applyAiResponseMetadata(
    Map<
      String,
      dynamic
    >
    data, {
    bool notify = true,
  }) {
    aiSourceController.applyMetadata(
      data,
    );

    if (aiSourceController.usingVersinApi) {
      aiQuotaController.updateFromMap(
        data,
      );
    }

    if (notify) {
      notifyListeners();
    }
  }

  // ============================================================
  // ATIVAR API PRIVADA
  // ============================================================

  void activatePrivateAi({
    String? provider,
    String? model,
  }) {
    aiSourceController.activatePrivate(
      provider: _normalizeProvider(
        provider,
      ),
      model: model,
    );
  }

  // ============================================================
  // ATIVAR IA VERSIN
  // ============================================================

  void activateVersinAi() {
    aiSourceController.activateVersin();
  }

  // ============================================================
  // METRÔNOMO
  // ============================================================

  void toggleMetronome() {
    isBpmPlaying = !isBpmPlaying;

    if (isBpmPlaying) {
      _audioService.startMetronome(
        currentBpm,
      );
    } else {
      _audioService.stopMetronome();
    }

    notifyListeners();
  }

  // ============================================================
  // TEXTO E SUGESTÕES
  // ============================================================

  void onTextChanged(
    String text,
  ) {
    _rhymeSuggestionService.onTextChanged(
      text: text,
      vocabulary: vocabularyController.vocabulary,
      onChanged: notifyListeners,
    );
  }

  // ============================================================
  // LIMPAR SUGESTÕES
  // ============================================================

  void clearSuggestions() {
    _rhymeSuggestionService.clear(
      onChanged: notifyListeners,
    );
  }

  // ============================================================
  // ATUALIZAR QUOTA
  // ============================================================

  void updateAiQuotaFromMap(
    Map<
      String,
      dynamic
    >
    quota, {
    bool notify = true,
  }) {
    aiQuotaController.updateFromMap(
      quota,
    );

    if (notify) {
      notifyListeners();
    }
  }

  // ============================================================
  // RESETAR QUOTA
  // ============================================================

  void resetAiQuota({
    bool notify = true,
  }) {
    aiQuotaController.reset();

    if (notify) {
      notifyListeners();
    }
  }

  // ============================================================
  // IA LEGADA
  // ============================================================

  Future<
    Map<
      String,
      String
    >
  >
  fetchAiResponse(
    String message,
  ) async {
    final normalizedMessage = message.trim();

    if (normalizedMessage.isEmpty) {
      return {
        'role': 'assistant',
        'content': 'Digite uma mensagem antes de enviar.',
      };
    }

    if (aiQuotaBlocked ||
        !aiCanUse) {
      return {
        'role': 'assistant',
        'content': aiUsageMessage.isNotEmpty
            ? aiUsageMessage
            : 'Limite mensal de IA atingido.',
      };
    }

    aiSourceController.activateVersin(
      notify: false,
    );

    final result = await _rhymesAiService.fetchAiResponse(
      message: normalizedMessage,
      vocabulary: vocabularyWords,
      bpm: currentBpm,
      vibe: selectedVibe,
      technique: selectedTechnique,
      apiKey: _userApiKey,
    );

    final quota = result.quota;

    if (quota !=
        null) {
      aiQuotaController.updateFromMap(
        quota,
      );
    }

    final rawData = result.rawData;

    if (rawData !=
        null) {
      final hasSourceMetadata =
          rawData['used_private_api'] ==
              true ||
          rawData['used_versin_api'] ==
              true ||
          rawData.containsKey(
            'source',
          );

      if (hasSourceMetadata) {
        aiSourceController.applyMetadata(
          rawData,
        );
      }
    }

    return result.toMessageMap();
  }

  // ============================================================
  // CONFIGURAÇÕES DO ESTÚDIO
  // ============================================================

  void updateStudioConfig({
    int? bpm,
    String? vibe,
    String? technique,
  }) {
    if (bpm !=
        null) {
      currentBpm = bpm;

      if (isBpmPlaying) {
        _audioService.startMetronome(
          currentBpm,
        );
      }
    }

    if (vibe !=
        null) {
      selectedVibe = vibe;
    }

    if (technique !=
        null) {
      selectedTechnique = technique;
    }

    notifyListeners();
  }

  // ============================================================
  // PROGRESSO
  // ============================================================

  void updateProgress(
    int step,
    double progress,
  ) {
    _currentStep = step;

    _stepProgress = progress;

    notifyListeners();
  }

  // ============================================================
  // COR
  // ============================================================

  Color getActiveColor() {
    return const Color(
      0xFFE100FF,
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    vocabularyController.removeListener(
      _onChildControllerChanged,
    );

    aiQuotaController.removeListener(
      _onChildControllerChanged,
    );

    aiSourceController.removeListener(
      _onChildControllerChanged,
    );

    _rhymesAiService.removeListener(
      _onChildControllerChanged,
    );

    _audioService.dispose();

    _rhymeSuggestionService.dispose();

    suggestionController.dispose();

    vocabularyController.dispose();

    aiQuotaController.dispose();

    aiSourceController.dispose();

    _rhymesAiService.dispose();

    super.dispose();
  }
}
