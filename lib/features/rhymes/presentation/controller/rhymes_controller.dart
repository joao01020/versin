import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:versin/core/models/rhyme_model.dart';

class RhymesController extends ChangeNotifier {
  Timer? _debounce;
  Timer? _connectionTimer; 
  final _supabase = Supabase.instance.client;
  final String _baseUrl = "https://versin.onrender.com";

  // --- ESTADOS ---
  List<String> _suggestionsList = [];
  List<String> get suggestionsList => _suggestionsList;
  List<String> get suggestions => _suggestionsList;
  String get suggestion =>
      _suggestionsList.isNotEmpty ? _suggestionsList.first : "";

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  int connectionSeconds = 0; 

  // --- PROGRESSO E GAMIFICAÇÃO ---
  int _currentStep = 1;
  int get currentStep => _currentStep;
  double _stepProgress = 0.0;
  double get stepProgress => _stepProgress;

  double starProgress = 0.0;
  double fireProgress = 0.0;
  String currentFeedback = "Comece a escrever para validar sua letra...";

  // --- MODOS DE INTERFACE ---
  bool isRhymeMode = false;
  bool isComposeMode = false;
  bool isListMode = false;
  bool isMarketingMode = false;

  // --- CONFIGURAÇÕES DE SESSÃO ATUAL (ESTÚDIO) ---
  String selectedTechnique = "Melódico"; 
  String selectedVibe = "Calmo";
  int currentBpm = 120;

  // --- DADOS E API ---
  List<Rhyme> vocabulary = [];
  List<Map<String, dynamic>> trendingWords = [];
  String? _userApiKey = "VERSIN-PRO-TRIAL-2026-FREE";
  String? get userApiKey => _userApiKey;
  bool get isProActive => _userApiKey != null && _userApiKey!.isNotEmpty;

  // --- LÓGICA DE CORES ---
  Color getActiveColor() {
    if (isRhymeMode) return Colors.greenAccent;
    if (isComposeMode) return Colors.blueAccent;
    if (isListMode) return Colors.orangeAccent;
    if (isMarketingMode) return Colors.yellowAccent;
    return const Color(0xFFE100FF); 
  }

  // --- BUSCA DE TENDÊNCIAS ---
  Future<void> fetchTrendingWords() async {
    try {
      debugPrint("Versin: Buscando palavras em alta...");
      trendingWords = [
        {"word": "Flow", "count": 150},
        {"word": "Beat", "count": 120},
      ];
      notifyListeners();
    } catch (e) {
      debugPrint("Erro ao buscar trending words: $e");
    }
  }

  // --- LÓGICA DE DIGITAÇÃO ---
  void onTextChanged(String text) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _processarProgressoTecnico(text);

    _debounce = Timer(const Duration(milliseconds: 300), () {
      String t = text.trim().toLowerCase();
      if (t.isEmpty) {
        _suggestionsList = [];
        notifyListeners();
        return;
      }

      final words = t.split(RegExp(r'\s+'));
      final lastWord = words.last;

      if (lastWord.length >= 2) {
        _suggestionsList = vocabulary
            .where((item) {
              String wordInVocab = item.word.toLowerCase();
              return wordInVocab.endsWith(
                    lastWord.substring(lastWord.length - 2),
                  ) ||
                  wordInVocab.contains(lastWord);
            })
            .map((item) => item.word)
            .where((word) => word != lastWord)
            .toList();
      } else {
        _suggestionsList = [];
      }
      notifyListeners();
    });
  }

  void _processarProgressoTecnico(String texto) {
    if (texto.trim().isEmpty) {
      starProgress = 0.0;
      currentFeedback = "Comece a escrever para validar sua letra...";
    } else {
      currentFeedback = "Versin analisando seu flow...";
      final totalLinhas = texto
          .split('\n')
          .where((l) => l.trim().isNotEmpty)
          .length;
      starProgress = (totalLinhas / 10).clamp(0.0, 3.0);
    }
    notifyListeners();
  }

  // --- CONEXÃO COM IA ---
  Future<Map<String, String>> fetchAiResponse(String message) async {
    _isLoading = true;
    connectionSeconds = 0; 
    notifyListeners();

    _connectionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      connectionSeconds++;
      notifyListeners();
    });

    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/chat'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_id': _supabase.auth.currentUser?.id ?? "user_dev_01",
              'message': message,
              'current_list': vocabulary.map((r) => r.word).toList(),
              'private_api_key': _userApiKey,
              'context': {
                'bpm': currentBpm,
                'vibe': selectedVibe,
                'technique': selectedTechnique,
              }
            }),
          )
          .timeout(const Duration(seconds: 60)); 

      _connectionTimer?.cancel();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {"role": "assistant", "content": data['content'] ?? ""};
      }
      return {
        "role": "assistant", 
        "content": "Erro no servidor (Status: ${response.statusCode})"
      };
    } catch (e) {
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

  // --- MÉTODOS DE SUPABASE (REMOVIDO IS_PRIORITY / ATUALIZADO USER_ID) ---
  Future<void> carregarDadosUsuario() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        final vocabData = await _supabase
            .from('user_vocabulary')
            .select('word') // Removido is_priority
            .eq('user_id', user.id); // Atualizado para user_id
            
        vocabulary = (vocabData as List)
            .map(
              (item) => Rhyme(
                word: item['word'],
                isPriority: false, // Default falso já que removemos do banco
              ),
            )
            .toList();
        notifyListeners();
      } catch (e) {
        debugPrint("Erro ao carregar vocabulário: $e");
      }
    }
  }

  void addWord(String word, bool priority) {
    String p = word.trim().toLowerCase();
    if (p.isNotEmpty && !vocabulary.any((r) => r.word == p)) {
      vocabulary.insert(0, Rhyme(word: p, isPriority: false));
      notifyListeners();
      
      final user = _supabase.auth.currentUser;
      if (user != null) {
        _supabase
            .from('user_vocabulary')
            .insert({
              'word': p, 
              'user_id': user.id // Atualizado para user_id
              // Removido is_priority do insert
            })
            .then((_) => null)
            .catchError((e) => debugPrint("Erro ao salvar palavra: $e"));
      }
    }
  }

  void removeWord(int index) {
    if (index >= 0 && index < vocabulary.length) {
      final wordToRemove = vocabulary[index].word;
      vocabulary.removeAt(index);
      notifyListeners();
      
      final user = _supabase.auth.currentUser;
      if (user != null) {
        _supabase
            .from('user_vocabulary')
            .delete()
            .eq('word', wordToRemove)
            .eq('user_id', user.id) // Atualizado para user_id
            .then((_) => null);
      }
    }
  }

  // Método simplificado (não faz mais nada no banco, apenas interface)
  void togglePriority(int index) {
    if (index >= 0 && index < vocabulary.length) {
      vocabulary[index].isPriority = !vocabulary[index].isPriority;
      notifyListeners();
    }
  }

  // --- MÉTODOS DE GERENCIAMENTO ---
  void updateStudioConfig({int? bpm, String? vibe, String? technique}) {
    if (bpm != null) currentBpm = bpm;
    if (vibe != null) selectedVibe = vibe;
    if (technique != null) selectedTechnique = technique;
    notifyListeners();
  }

  void setApiKey(String key) {
    _userApiKey = key;
    notifyListeners();
  }

  void updateGamification(dynamic v) {
    if (v is double) starProgress = v;
    notifyListeners();
  }

  void updateProgress(int s, double p) {
    _currentStep = s;
    _stepProgress = p;
    notifyListeners();
  }

  void clearSuggestions() {
    _suggestionsList = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _connectionTimer?.cancel();
    super.dispose();
  }
}