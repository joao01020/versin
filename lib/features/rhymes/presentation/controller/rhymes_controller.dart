import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:versin/core/models/rhyme_model.dart';

// Controller principal das rimas e lógica de gamificação
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

  // --- ESTADO DA GAMIFICAÇÃO (DINÂMICO) ---
  double starProgress = 0.0; 
  double fireProgress = 0.0;    
  String mentorFeedback = "Ouvindo sua frequência..."; 

  // --- ESTADO DE USO (Livre de bloqueios) ---
  int _rimasUsadas = 0;
  int get rimasUsadas => _rimasUsadas;
  bool get temSaldo => true; // Sempre liberado

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

  // Inicia vazio para o Onboarding dinâmico
  List<Rhyme> vocabulary = [];

  bool get isProActive => _userApiKey != null && _userApiKey!.isNotEmpty;

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
      await _supabase
          .from('profiles')
          .update({'rimas_usadas': _rimasUsadas})
          .eq('id', user.id);
    }
  }

  // NOVO: Busca as rimas em alta no ranking global para o Onboarding (Ponto 1)
  Future<List<Map<String, dynamic>>> fetchTrendingWords() async {
    try {
      final response = await _supabase
          .from('global_word_ranking')
          .select('word, score')
          .order('score', ascending: false)
          .limit(6);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("⚠️ Erro ao buscar trending words: $e");
      return [];
    }
  }

  // NOVO: Incrementa o score de uma rima no ranking global via RPC
  Future<void> incrementWordScore(String word) async {
    try {
      await _supabase.rpc('increment_word_score', params: {
        'word_param': word.toLowerCase().trim(),
      });
      debugPrint("🔥 Score incrementado globalmente para: $word");
    } catch (e) {
      debugPrint("❌ Erro ao incrementar score: $e");
    }
  }

  // ATUALIZADO: Foca em RECOMENDAR rimas e completar versos em vez de apenas julgar
  void updateGamification(dynamic rawLevel, {String? reason}) {
    int level = 0;
    if (rawLevel is int) {
      level = rawLevel;
    } else if (rawLevel is String) {
      level = int.tryParse(rawLevel) ?? 0;
    }

    if (level <= 0) {
      starProgress = 0.0; 
      fireProgress = 0.0;
      mentorFeedback = reason ?? "O estúdio está silencioso...";
    } 
    else {
      if (level >= 1 && level <= 3) {
        fireProgress = 0.0;
        starProgress = level.toDouble();
      } else if (level >= 4) {
        starProgress = 0.0; 
        fireProgress = (level - 3).toDouble().clamp(0.0, 3.0);
      }
      
      if (_suggestionsList.isNotEmpty) {
        String baseSuggestion = _suggestionsList.take(3).join(", ");
        mentorFeedback = "Pensei em completar com: $baseSuggestion... ou seguir por '$reason'";
      } else {
        mentorFeedback = reason ?? "Analisando métrica e flow...";
      }
    }
    notifyListeners();
  }

  void onTextChanged(String text) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    String t = text.trim();

    if (t.isEmpty) {
      _suggestionsList = [];
      mentorFeedback = "O estúdio está silencioso...";
      notifyListeners();
      return;
    }

    mentorFeedback = "...";
    notifyListeners();

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
              'genre': currentGenre,
              'subgenre': currentSubGenre,
              'bpm': currentBpm,
              'key': currentKey,
              'vocal_style': currentVocalStyle,
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
          
          updateGamification(data['impact_level'], reason: data['feedback_reason']);
          _incrementarUso();
        }
      } catch (e) {
        debugPrint("Erro Versin Processar: $e");
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
      notifyListeners();

      if (user != null) {
        try {
          await _supabase.from('user_vocabulary').insert({
            'word': p,
            'profile_id': user.id,
          });
        } catch (e) { debugPrint("Erro ao salvar: $e"); }
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
          'style_config': {
            'genre': currentGenre,
            'subgenre': currentSubGenre,
          }
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        updateGamification(data['impact_level'], reason: data['feedback_reason']);
        _incrementarUso();
        return {
          "role": "assistant", 
          "content": data['content'] ?? ""
        };
      }
      return {"role": "assistant", "content": "Erro no servidor do estúdio."};
    } catch (e) {
      return {"role": "assistant", "content": "Erro de conexão com o Versin."};
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