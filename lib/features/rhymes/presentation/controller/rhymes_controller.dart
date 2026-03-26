import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:versin/core/models/rhyme_model.dart';

// Controller principal das rimas e lógica de gamificação
class RhymesController extends ChangeNotifier {
  Timer? _debounce;
  final String _baseUrl = "http://127.0.0.1:8000";

  // --- ESTADO DO CHAT E SUGESTÕES ---
  List<String> _suggestionsList = [];
  List<String> get suggestionsList => _suggestionsList;

  // Mantido para compatibilidade com a interface
  String get suggestion => _suggestionsList.isNotEmpty ? _suggestionsList.first : "";

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // --- ESTADO DA GAMIFICAÇÃO (DINÂMICO) ---
  double starProgress = 0.0; 
  double fireProgress = 0.0;    
  String mentorFeedback = "Ouvindo sua frequência..."; // Início neutro para a IA assumir

  // --- CONFIGURAÇÕES DE ESTILO (Sincronizadas com RhymeLevelPage) ---
  String currentGenre = 'Automático';
  String currentSubGenre = 'Padrão';
  String currentBpm = 'Automático';
  String currentKey = 'Automático';
  String currentVocalStyle = 'Automático';
  bool shareDictionary = false;

  // --- CONFIGURAÇÕES DO USUÁRIO ---
  final String _userId = "user_dev_01"; 
  String? _userApiKey = "VERSIN-PRO-TRIAL-2026-FREE"; 
  String? get userApiKey => _userApiKey; 

  List<Rhyme> vocabulary = [
    Rhyme(word: "plano", isPriority: true),
    Rhyme(word: "insano"),
    Rhyme(word: "mano", isPriority: true),
  ];

  bool get isProActive => _userApiKey != null && _userApiKey!.isNotEmpty;

  // --- MÉTODO ESPERADO PELA CHATPAGE ---
  void searchSuggestion(String word) {
    // Redireciona para o processamento com debounce
    onTextChanged(word);
  }

  // --- ATUALIZAR SETUP DA RHYME LEVEL PAGE ---
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

  // --- LÓGICA DE EVOLUÇÃO (IA ADAPTATIVA) ---
  void updateGamification(dynamic rawLevel, {String? reason}) {
    int level = 0;
    if (rawLevel is int) {
      level = rawLevel;
    } else if (rawLevel is String) {
      level = int.tryParse(rawLevel) ?? 0;
    }

    // A IA agora define o mentorFeedback via 'reason' (feedback_reason do backend)
    if (level <= 0) {
      starProgress = 0.0; 
      fireProgress = 0.0;
      mentorFeedback = reason ?? "O estúdio está silencioso...";
    } 
    else if (level >= 1 && level <= 3) {
      fireProgress = 0.0;
      starProgress = level.toDouble();
      mentorFeedback = reason ?? "Analisando métrica e flow...";
    } 
    else if (level >= 4) {
      starProgress = 0.0; 
      fireProgress = (level - 3).toDouble().clamp(0.0, 3.0);
      mentorFeedback = reason ?? "Sua linha atingiu o pico de impacto! 🔥";
    }
    notifyListeners();
  }

  // --- SUGESTÃO E PREENCHIMENTO AO DIGITAR ---
  void onTextChanged(String text) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    String t = text.trim();

    if (t.isEmpty) {
      _suggestionsList = [];
      notifyListeners();
      return;
    }

    int duration = isProActive ? 300 : 700; 

    _debounce = Timer(Duration(milliseconds: duration), () async {
      _isLoading = true;
      notifyListeners();

      try {
        final response = await http.post(
          Uri.parse('$_baseUrl/processar'),
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
        ).timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          
          if (data['result'] is List) {
            _suggestionsList = List<String>.from(data['result']);
          } else {
            String res = data['result'] ?? "";
            _suggestionsList = (res == "NENHUMA" || res.isEmpty) ? [] : [res];
          }
          
          // Sincroniza a gamificação com o feedback textual dinâmico da IA
          updateGamification(data['impact_level'], reason: data['feedback_reason']);
        }
      } catch (e) {
        debugPrint("Erro Versin Processar: $e");
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  // --- MÉTODOS DE MANIPULAÇÃO DE LISTA ---
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

  // --- CHAT COM MENTOR (Feedback pós-resposta) ---
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
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Atualiza o mentor e o termômetro baseado na última interação do chat
        updateGamification(data['impact_level'], reason: data['feedback_reason']);
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

  // --- MANUTENÇÃO DO VOCABULÁRIO ---
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