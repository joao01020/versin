import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:versin/core/models/rhyme_model.dart';
import 'package:versin/features/rhymes/data/repositories/rhymes_repository.dart';
import 'package:versin/features/rhymes/domain/services/audio_service.dart';
import 'package:versin/modules/chat/views/components/suggestion_balloon/controllers/suggestion_controller.dart';

class RhymesController extends ChangeNotifier {
  final RhymesRepository _repository = RhymesRepository();
  final AudioService _audioService = AudioService();

  final SuggestionController suggestionController = SuggestionController();

  Timer? _debounce;
  Timer? _connectionTimer;

  bool _isLoading = false;

  int _currentStep = 1;
  double _stepProgress = 0.0;

  String? _userApiKey = 'VERSIN-PRO-TRIAL-2026-FREE';

  int connectionSeconds = 0;
  double starProgress = 0.0;

  String currentFeedback = 'Comece a escrever para validar sua letra...';

  String selectedTechnique = 'Melódico';
  String selectedVibe = 'Calmo';

  int currentBpm = 120;
  bool isBpmPlaying = false;

  List<Rhyme> vocabulary = [];

  List<Map<String, dynamic>> trendingWords = [];

  List<String> get suggestions => suggestionController.suggestions;

  bool get isLoading => _isLoading;

  int get currentStep => _currentStep;

  double get stepProgress => _stepProgress;

  String? get userApiKey => _userApiKey;

  double get fireProgress => (starProgress * 0.7).clamp(0.0, 1.0);

  // =========================================================
  // VOCABULÁRIO
  // =========================================================

  Future<void> addWord(String word, bool priority) async {
    final normalized = word.trim().toLowerCase();

    if (normalized.isEmpty ||
        vocabulary.any((rhyme) => rhyme.word == normalized)) {
      return;
    }

    vocabulary.insert(0, Rhyme(word: normalized, isPriority: priority));

    notifyListeners();

    try {
      await _repository.saveWord(normalized);
    } catch (e) {
      debugPrint('Erro ao salvar palavra: $e');
    }
  }

  Future<void> removeWord(int index) async {
    if (index < 0 || index >= vocabulary.length) {
      return;
    }

    final word = vocabulary[index].word;

    vocabulary.removeAt(index);
    notifyListeners();

    try {
      await _repository.deleteWord(word);
    } catch (e) {
      debugPrint('Erro ao remover palavra: $e');
    }
  }

  // =========================================================
  // TRENDING
  // =========================================================

  Future<void> fetchTrendingWords() async {
    trendingWords = [
      {'word': 'Flow', 'count': 150},
      {'word': 'Beat', 'count': 120},
    ];

    notifyListeners();
  }

  // =========================================================
  // GAMIFICAÇÃO
  // =========================================================

  void updateGamification(double value) {
    starProgress = value;
    notifyListeners();
  }

  // =========================================================
  // API KEY
  // =========================================================

  void setApiKey(String key) {
    final normalized = key.trim();

    _userApiKey = normalized.isEmpty ? null : normalized;

    notifyListeners();
  }

  // =========================================================
  // METRÔNOMO
  // =========================================================

  void toggleMetronome() {
    isBpmPlaying = !isBpmPlaying;

    if (isBpmPlaying) {
      _audioService.startMetronome(currentBpm);
    } else {
      _audioService.stopMetronome();
    }

    notifyListeners();
  }

  // =========================================================
  // TEXTO E SUGESTÕES
  // =========================================================

  void onTextChanged(String text) {
    _debounce?.cancel();

    _processarProgressoTecnico(text);

    suggestionController.updateFromText(text);

    _debounce = Timer(const Duration(milliseconds: 300), () {
      final normalized = text.trim().toLowerCase();

      if (normalized.isEmpty) {
        suggestionController.clearSuggestions();

        notifyListeners();
        return;
      }

      final words = normalized.split(RegExp(r'\s+'));

      final lastWord = words.last;

      if (lastWord.length < 2) {
        if (suggestionController.suggestions.isEmpty) {
          suggestionController.clearSuggestions();
        }

        notifyListeners();
        return;
      }

      final suffix = lastWord.substring(lastWord.length - 2);

      final localSuggestions = vocabulary
          .map((item) => item.word.trim().toLowerCase())
          .where(
            (word) =>
                word != lastWord &&
                (word.endsWith(suffix) || word.startsWith(lastWord)),
          )
          .toList();

      if (localSuggestions.isNotEmpty) {
        final combined = {
          ...suggestionController.suggestions,
          ...localSuggestions,
        }.toList();

        suggestionController.setSuggestions(combined);
      }

      notifyListeners();
    });
  }

  void _processarProgressoTecnico(String texto) {
    if (texto.trim().isEmpty) {
      starProgress = 0.0;

      currentFeedback = 'Comece a escrever para validar sua letra...';

      notifyListeners();
      return;
    }

    currentFeedback = 'Versin analisando seu flow...';

    final totalLinhas = texto
        .split('\n')
        .where((linha) => linha.trim().isNotEmpty)
        .length;

    starProgress = (totalLinhas / 10).clamp(0.0, 3.0);

    notifyListeners();
  }

  // =========================================================
  // IA
  // =========================================================

  Future<Map<String, String>> fetchAiResponse(String message) async {
    final normalizedMessage = message.trim();

    if (normalizedMessage.isEmpty) {
      return {
        'role': 'assistant',
        'content': 'Digite uma mensagem antes de enviar.',
      };
    }

    _isLoading = true;
    connectionSeconds = 0;

    notifyListeners();

    _connectionTimer?.cancel();

    _connectionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      connectionSeconds++;
      notifyListeners();
    });

    try {
      debugPrint('');
      debugPrint('================ IA REQUEST ================');
      debugPrint('Mensagem: $normalizedMessage');
      debugPrint('BPM: $currentBpm');
      debugPrint('Vibe: $selectedVibe');
      debugPrint('Técnica: $selectedTechnique');
      debugPrint('Vocabulário: ${vocabulary.length} palavras');

      final response = await _repository.postChat(
        message: normalizedMessage,
        currentList: vocabulary.map((rhyme) => rhyme.word).toList(),
        apiKey: _userApiKey,
        context: {
          'bpm': currentBpm,
          'vibe': selectedVibe,
          'technique': selectedTechnique,
        },
      );

      debugPrint('---------------- IA RESPONSE ----------------');
      debugPrint('Status: ${response.statusCode}');
      debugPrint('Body: ${response.body}');
      debugPrint('Headers: ${response.headers}');
      debugPrint('=============================================');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return {
          'role': 'assistant',
          'content': _buildServerErrorMessage(
            response.statusCode,
            response.body,
          ),
        };
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map) {
        debugPrint('Resposta da IA não é um objeto JSON.');

        return {
          'role': 'assistant',
          'content': 'O servidor respondeu em um formato inválido.',
        };
      }

      final data = Map<String, dynamic>.from(decoded);

      final content = data['content']?.toString().trim();

      if (content == null || content.isEmpty) {
        return {
          'role': 'assistant',
          'content': 'O servidor respondeu sem conteúdo.',
        };
      }

      return {'role': 'assistant', 'content': content};
    } on FormatException catch (e) {
      debugPrint('Erro ao decodificar JSON da IA: $e');

      return {
        'role': 'assistant',
        'content': 'O servidor respondeu em um formato inválido.',
      };
    } on TimeoutException catch (e) {
      debugPrint('Timeout na conexão com IA: $e');

      return {
        'role': 'assistant',
        'content': 'O servidor demorou demais para responder. Tente novamente.',
      };
    } catch (e, stackTrace) {
      debugPrint('');
      debugPrint('================ ERRO IA ====================');
      debugPrint('Erro: $e');
      debugPrint('Stack: $stackTrace');
      debugPrint('=============================================');

      return {
        'role': 'assistant',
        'content': 'Conexão instável. Tente novamente!',
      };
    } finally {
      _connectionTimer?.cancel();
      _connectionTimer = null;

      _isLoading = false;

      notifyListeners();
    }
  }

  String _buildServerErrorMessage(int statusCode, String responseBody) {
    String? serverMessage;

    try {
      final decoded = jsonDecode(responseBody);

      if (decoded is Map) {
        final data = Map<String, dynamic>.from(decoded);

        serverMessage =
            data['error']?.toString() ??
            data['message']?.toString() ??
            data['detail']?.toString();
      }
    } catch (_) {
      if (responseBody.trim().isNotEmpty) {
        serverMessage = responseBody.trim();
      }
    }

    switch (statusCode) {
      case 401:
        return serverMessage != null
            ? 'Não autorizado: $serverMessage'
            : 'Não autorizado. Verifique sua API Key.';

      case 403:
        return serverMessage != null
            ? 'Acesso negado: $serverMessage'
            : 'Acesso negado pelo servidor.';

      case 404:
        return serverMessage != null
            ? 'Serviço não encontrado: $serverMessage'
            : 'O serviço da IA não foi encontrado.';

      case 429:
        return serverMessage != null
            ? 'Limite de requisições atingido: $serverMessage'
            : 'Muitas requisições. Aguarde um pouco e tente novamente.';

      case 500:
        return serverMessage != null
            ? 'Erro interno do servidor: $serverMessage'
            : 'Erro interno do servidor.';

      case 502:
        return serverMessage != null
            ? 'Gateway inválido: $serverMessage'
            : 'O servidor intermediário falhou.';

      case 503:
        return serverMessage != null
            ? 'Servidor temporariamente indisponível: $serverMessage'
            : 'Servidor temporariamente indisponível. Tente novamente em instantes.';

      case 504:
        return serverMessage != null
            ? 'Tempo limite do servidor: $serverMessage'
            : 'O servidor demorou demais para responder.';

      default:
        return serverMessage != null
            ? 'Erro no servidor ($statusCode): $serverMessage'
            : 'Erro no servidor (Status: $statusCode)';
    }
  }

  // =========================================================
  // CARREGAMENTO DE DADOS
  // =========================================================

  Future<void> carregarDadosUsuario() async {
    try {
      vocabulary = await _repository.fetchVocabulary();

      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar vocabulário: $e');
    }
  }

  // =========================================================
  // CONFIGURAÇÕES DO ESTÚDIO
  // =========================================================

  void updateStudioConfig({int? bpm, String? vibe, String? technique}) {
    if (bpm != null) {
      currentBpm = bpm;

      if (isBpmPlaying) {
        _audioService.startMetronome(currentBpm);
      }
    }

    if (vibe != null) {
      selectedVibe = vibe;
    }

    if (technique != null) {
      selectedTechnique = technique;
    }

    notifyListeners();
  }

  void updateProgress(int step, double progress) {
    _currentStep = step;
    _stepProgress = progress;

    notifyListeners();
  }

  Color getActiveColor() {
    return const Color(0xFFE100FF);
  }

  void clearSuggestions() {
    suggestionController.clearSuggestions();
    notifyListeners();
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    _debounce?.cancel();
    _connectionTimer?.cancel();

    _audioService.dispose();
    suggestionController.dispose();

    super.dispose();
  }
}
