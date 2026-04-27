import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:versin/core/models/rhyme_model.dart';

class RhymesController extends ChangeNotifier {
  Timer? _debounce;
  final String _baseUrl = "https://versin.onrender.com";
  final _supabase = Supabase.instance.client;

  // --- ESTADO DO CHAT E SUGESTÕES ---
  List<String> _suggestionsList = [];
  List<String> get suggestionsList => _suggestionsList;
  String get suggestion => _suggestionsList.isNotEmpty ? _suggestionsList.first : "";

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // --- ESTADO DA TIMELINE E PROGRESSO (NOVO) ---
  int _currentStep = 1;
  int get currentStep => _currentStep;
  
  double _stepProgress = 0.0;
  double get stepProgress => _stepProgress;

  // --- ESTADOS DE MODO DE INTERFACE (NOVO) ---
  bool isRhymeMode = false;
  bool isComposeMode = false;
  bool isListMode = false;
  bool isMarketingMode = false;

  // --- ESTADO DA GAMIFICAÇÃO ---
  double starProgress = 0.0;
  double fireProgress = 0.0;
  String currentFeedback = "Comece a escrever para validar sua letra...";

  // --- ESTADO DE USO ---
  int _rimasUsadas = 0;
  int get rimasUsadas => _rimasUsadas;
  bool get temSaldo => true;

  // --- CONFIGURAÇÕES DE ESTILO ---
  String currentGenre = 'Automático';
  String currentSubGenre = 'Padrão';
  String currentBpm = 'Automático';
  String currentKey = 'Automático';
  String currentVocalStyle = 'Automático';
  bool shareDictionary = false;

  final String _userId = "user_dev_01";
  String? _userApiKey = "VERSIN-PRO-TRIAL-2026-FREE";
  String? get userApiKey => _userApiKey;

  List<Rhyme> vocabulary = [];
  List<Map<String, dynamic>> trendingWords = [];

  bool get isProActive => _userApiKey != null && _userApiKey!.isNotEmpty;

  // --- LÓGICA DE UI (CORES) ---
  Color getActiveColor() {
    if (isRhymeMode) return Colors.greenAccent;
    if (isComposeMode) return Colors.blueAccent;
    if (isListMode) return Colors.orangeAccent;
    if (isMarketingMode) return Colors.yellowAccent;
    return Colors.purpleAccent;
  }

  // --- ATUALIZAÇÃO DE ESTADOS DE FLUXO ---
  void updateProgress(int step, double progress) {
    _currentStep = step;
    _stepProgress = progress;
    notifyListeners();
  }

  void updateModes({bool? rhyme, bool? compose, bool? list, bool? marketing}) {
    if (rhyme != null) isRhymeMode = rhyme;
    if (compose != null) isComposeMode = compose;
    if (list != null) isListMode = list;
    if (marketing != null) isMarketingMode = marketing;
    notifyListeners();
  }

  void searchSuggestion(String word) {
    onTextChanged(word);
  }

  void updateSetup({
    String? genre,
    String? subGenre,
    String? bpm,
    String? key,
    String? vocalStyle,
    bool? share,
  }) {
    if (genre != null) currentGenre = genre;
    if (subGenre != null) currentSubGenre = subGenre;
    if (bpm != null) currentBpm = bpm;
    if (key != null) currentKey = key;
    if (vocalStyle != null) currentVocalStyle = vocalStyle;
    if (share != null) shareDictionary = share;
    notifyListeners();
  }

  void setApiKey(String key) {
    _userApiKey = key.trim().isEmpty ? null : key.trim();
    notifyListeners();
  }

  // --- LÓGICA DE GAMIFICAÇÃO LOCAL (SEM EMOJIS) ---
  void _processarProgressoTecnico(String texto) {
    if (texto.trim().isEmpty) {
      starProgress = 0.0;
      fireProgress = 0.0;
      currentFeedback = "Comece a escrever para validar sua letra...";
      notifyListeners();
      return;
    }

    final String t = texto.toUpperCase();
    final List<String> linhasRaw = texto.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final List<String> palavras = t.split(RegExp(r'\s+')).where((p) => p.length > 2).toList();
    
    int caracteres = texto.trim().length;
    int rimasNoVocabulario = vocabulary.length;
    int totalLinhas = linhasRaw.length;

    Set<String> palavrasUnicas = palavras.toSet();
    double diversidadeLexica = palavras.isEmpty ? 0 : palavrasUnicas.length / palavras.length;
    int palavrasLargas = palavrasUnicas.where((p) => p.length > 9).length;

    double varianciaFlow = 0;
    if (totalLinhas > 2) {
      List<int> tamanhos = linhasRaw.map((l) => l.length).toList();
      int media = tamanhos.reduce((a, b) => a + b) ~/ totalLinhas;
      varianciaFlow = tamanhos.where((l) => (l - media).abs() < 15).length / totalLinhas;
    }

    int punchlines = t.allMatches("!").length + t.allMatches("\\?").length;
    bool temRimaInterna = false;
    for (var linha in linhasRaw) {
      List<String> pLinha = linha.split(" ");
      if (pLinha.length > 4) {
        String p2 = pLinha[1].toLowerCase();
        String p4 = pLinha[3].toLowerCase();
        if (p2.length > 3 && p4.length > 3 && p2.substring(p2.length - 2) == p4.substring(p4.length - 2)) {
          temRimaInterna = true;
        }
      }
    }

    if ((rimasNoVocabulario >= 15 || totalLinhas >= 20) && diversidadeLexica > 0.55) {
      starProgress = 3.0;
      currentFeedback = "Nivel Maximo! Vocabulario de mestre e lirica impecavel.";
    } else if ((rimasNoVocabulario >= 8 || totalLinhas >= 10) && palavrasLargas >= 3) {
      starProgress = 2.0;
      currentFeedback = "Evolucao nitida. Voce esta construindo frases mais complexas.";
    } else if (caracteres >= 60 || totalLinhas >= 4) {
      starProgress = 1.0;
      currentFeedback = "Fundamentos solidos. Continue expandindo as estrofes.";
    } else {
      starProgress = 0.5;
      currentFeedback = "Escrevendo... O sistema esta analisando seu flow.";
    }

    int firePoints = 0;
    bool temEstrutura = t.contains("INTRO") || t.contains("REFRÃO") || t.contains("REFRAO") || t.contains("FINAL");
    if (temEstrutura) firePoints++;
    if (varianciaFlow > 0.7 && totalLinhas >= 8) firePoints++;
    if (punchlines >= 2 || temRimaInterna) firePoints++;

    if (caracteres > 150 && firePoints > 0) {
      fireProgress = firePoints.toDouble().clamp(0.0, 3.0);
      starProgress = 0.0;
      if (fireProgress == 3.0) {
        currentFeedback = "HIT DETECTADO! Metrica perfeita e estrutura profissional.";
      } else if (fireProgress == 2.0) {
        currentFeedback = "Flow constante. A cadencia da sua letra esta excelente.";
      } else {
        currentFeedback = "Calor aumentando. Sua estrutura esta ganhando peso.";
      }
    } else {
      fireProgress = 0.0;
    }
    notifyListeners();
  }

  // --- SINCRONIZAÇÃO COM SUPABASE ---
  Future<void> carregarDadosUsuario() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        final data = await _supabase
            .from('profiles')
            .select('rimas_usadas')
            .eq('id', user.id)
            .single();
        _rimasUsadas = data['rimas_usadas'] ?? 0;
        notifyListeners();
      } catch (e) {
        debugPrint("Erro ao sincronizar uso: $e");
      }
    }
  }

  Future<void> _incrementarUso() async {
    _rimasUsadas++;
    notifyListeners();
    final user = _supabase.auth.currentUser;
    if (user != null) {
      await _supabase.from('profiles').update({'rimas_usadas': _rimasUsadas}).eq('id', user.id);
    }
  }

  Future<List<Map<String, dynamic>>> fetchTrendingWords() async {
    try {
      final response = await _supabase.from('global_word_ranking').select('word, score').order('score', ascending: false).limit(6);
      trendingWords = List<Map<String, dynamic>>.from(response);
      notifyListeners();
      return trendingWords;
    } catch (e) {
      return [];
    }
  }

  Future<void> incrementWordScore(String word) async {
    try {
      await _supabase.rpc('increment_word_score', params: {'word_param': word.toLowerCase().trim()});
    } catch (e) {
      debugPrint("Erro ao incrementar score: $e");
    }
  }

  void updateGamification(dynamic rawLevel) {}

  void onTextChanged(String text) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    String t = text.trim();

    if (t.isEmpty) {
      _suggestionsList = [];
      starProgress = 0.0;
      fireProgress = 0.0;
      notifyListeners();
      return;
    }

    _processarProgressoTecnico(text);
    int duration = isProActive ? 400 : 800;

    _debounce = Timer(Duration(milliseconds: duration), () async {
      _isLoading = true;
      notifyListeners();
      try {
        final response = await http.post(
          Uri.parse('$_baseUrl/process'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_text': t,
            'rhyme_list': vocabulary.map((r) => r.word).toList(),
            'private_api_key': _userApiKey,
            'style_config': {
              'genre': currentGenre, 'subgenre': currentSubGenre, 'bpm': currentBpm, 'key': currentKey, 'vocal_style': currentVocalStyle,
            }
          }),
        ).timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['result'] is List) {
            _suggestionsList = List<String>.from(data['result']);
          } else {
            String res = data['result'] ?? "";
            _suggestionsList = (res == "NENHUMA" || res.isEmpty) ? [] : [res];
          }
          _incrementarUso();
        }
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  Future<String?> addSuggestedRhyme(String word) async {
    final user = _supabase.auth.currentUser;
    String p = word.trim().toLowerCase();
    if (p.isNotEmpty && !vocabulary.any((r) => r.word == p)) {
      vocabulary.insert(0, Rhyme(word: p, isPriority: false));
      _suggestionsList.remove(word);
      _processarProgressoTecnico(p); 
      notifyListeners();
      if (user != null) {
        try {
          await _supabase.from('user_vocabulary').insert({'word': p, 'profile_id': user.id});
        } catch (e) {}
      }
      return word;
    }
    return null;
  }

  void registerUsedRhyme(String rhyme) {
    _suggestionsList.remove(rhyme);
    notifyListeners();
  }

  void removeFromList(String rhyme) {
    _suggestionsList.remove(rhyme);
    notifyListeners();
  }

  void clearSuggestions() {
    _suggestionsList = [];
    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, String>> fetchAiResponse(String message) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': _userId,
          'message': message,
          'current_list': vocabulary.map((r) => r.word).toList(),
          'private_api_key': _userApiKey,
          'style_config': { 'genre': currentGenre, 'subgenre': currentSubGenre }
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _incrementarUso();
        return { "role": "assistant", "content": data['content'] ?? "" };
      }
      return {"role": "assistant", "content": "Erro no servidor."};
    } catch (e) {
      return {"role": "assistant", "content": "Erro de conexão."};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void addWord(String word, bool priority) {
    String p = word.trim().toLowerCase();
    if (p.isNotEmpty && !vocabulary.any((r) => r.word == p)) {
      vocabulary.insert(0, Rhyme(word: p, isPriority: priority));
      notifyListeners();
    }
  }

  void togglePriority(int index) {
    if (index >= 0 && index < vocabulary.length) {
      vocabulary[index].isPriority = !vocabulary[index].isPriority;
      notifyListeners();
    }
  }

  void removeWord(int index) {
    if (index >= 0 && index < vocabulary.length) {
      vocabulary.removeAt(index);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}