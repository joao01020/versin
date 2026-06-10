import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';

// Importe o modelo correto
import 'package:versin/core/models/rhyme_model.dart';

// Imports baseados no projeto
import 'package:versin/features/rhymes/data/repositories/rhymes_repository.dart';
import 'package:versin/features/rhymes/domain/services/audio_service.dart';

/// RhymesController: Classe base para a gestão de rimas e estado do estúdio.
/// O BrainController deve herdar desta classe para estender suas funcionalidades.
class RhymesController
    extends
        ChangeNotifier {
  final RhymesRepository _repository = RhymesRepository();
  final AudioService _audioService = AudioService();

  Timer? _debounce;
  Timer? _connectionTimer;

  // --- ESTADOS ---
  List<
    String
  >
  _suggestionsList = [];
  List<
    String
  >
  get suggestions => _suggestionsList;

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  int connectionSeconds = 0;

  int _currentStep = 1;
  int get currentStep => _currentStep;
  double _stepProgress = 0.0;
  double get stepProgress => _stepProgress;

  double starProgress = 0.0;
  double get fireProgress =>
      (starProgress *
              0.7)
          .clamp(
            0.0,
            1.0,
          );

  String currentFeedback = "Comece a escrever para validar sua letra...";

  String selectedTechnique = "Melódico";
  String selectedVibe = "Calmo";
  int currentBpm = 120;
  bool isBpmPlaying = false;

  List<
    Rhyme
  >
  vocabulary = [];
  List<
    Map<
      String,
      dynamic
    >
  >
  trendingWords = [];

  String? _userApiKey = "VERSIN-PRO-TRIAL-2026-FREE";
  String? get userApiKey => _userApiKey;

  // --- MÉTODOS DE DADOS ---

  void addWord(
    String word,
    bool priority,
  ) async {
    String p = word.trim().toLowerCase();
    if (p.isNotEmpty &&
        !vocabulary.any(
          (
            r,
          ) =>
              r.word ==
              p,
        )) {
      vocabulary.insert(
        0,
        Rhyme(
          word: p,
          isPriority: priority,
        ),
      );
      notifyListeners();

      try {
        await _repository.saveWord(
          p,
        );
      } catch (
        e
      ) {
        debugPrint(
          "Erro ao salvar palavra: $e",
        );
      }
    }
  }

  void removeWord(
    int index,
  ) async {
    if (index >=
            0 &&
        index <
            vocabulary.length) {
      final wordToRemove = vocabulary[index].word;
      vocabulary.removeAt(
        index,
      );
      notifyListeners();
      await _repository.deleteWord(
        wordToRemove,
      );
    }
  }

  // --- MÉTODOS DE INICIALIZAÇÃO E GAMIFICAÇÃO ---

  Future<
    void
  >
  fetchTrendingWords() async {
    trendingWords = [
      {
        "word": "Flow",
        "count": 150,
      },
      {
        "word": "Beat",
        "count": 120,
      },
    ];
    notifyListeners();
  }

  void updateGamification(
    double v,
  ) {
    starProgress = v;
    notifyListeners();
  }

  void setApiKey(
    String key,
  ) {
    _userApiKey = key;
    notifyListeners();
  }

  // --- LÓGICA DO METRÔNOMO ---
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

  // --- LÓGICA DE DIGITAÇÃO ---
  void onTextChanged(
    String text,
  ) {
    if (_debounce?.isActive ??
        false)
      _debounce!.cancel();

    _processarProgressoTecnico(
      text,
    );

    _debounce = Timer(
      const Duration(
        milliseconds: 300,
      ),
      () {
        String t = text.trim().toLowerCase();

        if (t.isEmpty) {
          _suggestionsList = [];
          notifyListeners();
          return;
        }

        final words = t.split(
          RegExp(
            r'\s+',
          ),
        );
        final lastWord = words.last;

        if (lastWord.length >=
            2) {
          String sufixo = lastWord.substring(
            lastWord.length -
                2,
          );

          _suggestionsList = vocabulary
              .where(
                (
                  item,
                ) {
                  String wordInVocab = item.word.trim().toLowerCase();
                  return wordInVocab.endsWith(
                        sufixo,
                      ) ||
                      wordInVocab.startsWith(
                        lastWord,
                      );
                },
              )
              .map(
                (
                  item,
                ) => item.word.trim(),
              )
              .where(
                (
                  word,
                ) =>
                    word !=
                    lastWord,
              )
              .toList();
        } else {
          _suggestionsList = [];
        }
        notifyListeners();
      },
    );
  }

  void _processarProgressoTecnico(
    String texto,
  ) {
    if (texto.trim().isEmpty) {
      starProgress = 0.0;
      currentFeedback = "Comece a escrever para validar sua letra...";
    } else {
      currentFeedback = "Versin analisando seu flow...";
      final totalLinhas = texto
          .split(
            '\n',
          )
          .where(
            (
              l,
            ) => l.trim().isNotEmpty,
          )
          .length;
      starProgress =
          (totalLinhas /
                  10)
              .clamp(
                0.0,
                3.0,
              );
    }
    notifyListeners();
  }

  // --- CONEXÃO COM IA ---
  Future<
    Map<
      String,
      String
    >
  >
  fetchAiResponse(
    String message,
  ) async {
    _isLoading = true;
    connectionSeconds = 0;
    notifyListeners();

    _connectionTimer = Timer.periodic(
      const Duration(
        seconds: 1,
      ),
      (
        timer,
      ) {
        connectionSeconds++;
        notifyListeners();
      },
    );

    try {
      final response = await _repository.postChat(
        message: message,
        currentList: vocabulary
            .map(
              (
                r,
              ) => r.word,
            )
            .toList(),
        apiKey: _userApiKey,
        context: {
          'bpm': currentBpm,
          'vibe': selectedVibe,
          'technique': selectedTechnique,
        },
      );

      _connectionTimer?.cancel();

      if (response.statusCode ==
          200) {
        final data = jsonDecode(
          response.body,
        );
        return {
          "role": "assistant",
          "content":
              data['content'] ??
              "",
        };
      }
      return {
        "role": "assistant",
        "content": "Erro no servidor (Status: ${response.statusCode})",
      };
    } catch (
      e
    ) {
      _connectionTimer?.cancel();
      return {
        "role": "assistant",
        "content": "Conexão instável. Tente novamente!",
      };
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<
    void
  >
  carregarDadosUsuario() async {
    try {
      vocabulary = await _repository.fetchVocabulary();
      notifyListeners();
    } catch (
      e
    ) {
      debugPrint(
        "Erro ao carregar vocabulário: $e",
      );
    }
  }

  void updateStudioConfig({
    int? bpm,
    String? vibe,
    String? technique,
  }) {
    if (bpm !=
        null) {
      currentBpm = bpm;
      if (isBpmPlaying)
        _audioService.startMetronome(
          currentBpm,
        );
    }
    if (vibe !=
        null)
      selectedVibe = vibe;
    if (technique !=
        null)
      selectedTechnique = technique;
    notifyListeners();
  }

  void updateProgress(
    int s,
    double p,
  ) {
    _currentStep = s;
    _stepProgress = p;
    notifyListeners();
  }

  Color getActiveColor() => const Color(
    0xFFE100FF,
  );

  void clearSuggestions() {
    _suggestionsList = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _connectionTimer?.cancel();
    _audioService.dispose();
    super.dispose();
  }
}
