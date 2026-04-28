import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:versin/core/models/rhyme_model.dart';

class RhymesController extends ChangeNotifier {
  Timer? _debounce;
  Timer? _connectionTimer; // Timer para o contador real
  final _supabase = Supabase.instance.client;
  final String _baseUrl = "https://versin.onrender.com";

  // --- ESTADOS ---
  List<String> _suggestionsList = [];
  List<String> get suggestionsList => _suggestionsList;
  List<String> get suggestions => _suggestionsList;
  String get suggestion => _suggestionsList.isNotEmpty ? _suggestionsList.first : "";

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  int connectionSeconds = 0; // Segundos reais passados na requisição

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
    return Colors.purpleAccent;
  }

  // --- LÓGICA DE DIGITAÇÃO E FEEDBACK ---
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
              return wordInVocab.endsWith(lastWord.substring(lastWord.length - 2)) || 
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
      final totalLinhas = texto.split('\n').where((l) => l.trim().isNotEmpty).length;
      starProgress = (totalLinhas / 10).clamp(0.0, 3.0);
    }
    notifyListeners();
  }

  // --- CONEXÃO COM IA DO CHAT COM TIMER REAL ---
  Future<Map<String, String>> fetchAiResponse(String message) async {
    _isLoading = true;
    connectionSeconds = 0; // Reseta o contador
    notifyListeners();

    // Inicia o contador de segundos real para o ChatListView
    _connectionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      connectionSeconds++;
      notifyListeners();
    });
    
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': "user_dev_01",
          'message': message,
          'current_list': vocabulary.map((r) => r.word).toList(),
          'private_api_key': _userApiKey,
        }),
      ).timeout(const Duration(seconds: 60)); // Aumentado para 60s (acordar o Render)

      _connectionTimer?.cancel();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return { "role": "assistant", "content": data['content'] ?? "" };
      }
      return {"role": "assistant", "content": "Erro no servidor (Status: ${response.statusCode})"};
    } catch (e) {
      _connectionTimer?.cancel();
      return {"role": "assistant", "content": "O servidor demorou muito. Tente enviar de novo!"};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- MÉTODOS DE SUPABASE ---
  Future<void> carregarDadosUsuario() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        final vocabData = await _supabase.from('user_vocabulary').select('word, is_priority').eq('profile_id', user.id);
        vocabulary = (vocabData as List).map((item) => Rhyme(word: item['word'], isPriority: item['is_priority'] ?? false)).toList();
        notifyListeners();
      } catch (e) { debugPrint("Erro ao carregar: $e"); }
    }
  }

  // --- MÉTODOS DE GERENCIAMENTO ---
  void addWord(String word, bool priority) {
    String p = word.trim().toLowerCase();
    if (p.isNotEmpty && !vocabulary.any((r) => r.word == p)) {
      vocabulary.insert(0, Rhyme(word: p, isPriority: priority));
      notifyListeners();
      final user = _supabase.auth.currentUser;
      if (user != null) {
        _supabase.from('user_vocabulary').insert({
          'word': p, 'profile_id': user.id, 'is_priority': priority
        }).then((_) => null);
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
        _supabase.from('user_vocabulary').delete().eq('word', wordToRemove).eq('profile_id', user.id).then((_) => null);
      }
    }
  }

  void togglePriority(int index) {
    if (index >= 0 && index < vocabulary.length) {
      vocabulary[index].isPriority = !vocabulary[index].isPriority;
      notifyListeners();
    }
  }

  void setApiKey(String key) { _userApiKey = key; notifyListeners(); }
  void updateGamification(dynamic v) { if (v is double) starProgress = v; notifyListeners(); }
  Future<void> fetchTrendingWords() async { /* Implementar se necessário */ }
  void incrementWordScore(String w) { /* Implementar se necessário */ }
  void updateProgress(int s, double p) { _currentStep = s; _stepProgress = p; notifyListeners(); }
  void clearSuggestions() { _suggestionsList = []; notifyListeners(); }

  @override
  void dispose() {
    _debounce?.cancel();
    _connectionTimer?.cancel();
    super.dispose();
  }
}