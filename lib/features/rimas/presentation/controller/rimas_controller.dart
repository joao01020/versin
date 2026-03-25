import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:versin/core/models/rima_model.dart';

class RimasController extends ChangeNotifier {
  Timer? _debounce;
  final String _baseUrl = "http://127.0.0.1:8000";

  // --- ESTADO DO CHAT E SUGESTÕES ---
  List<String> _listaSugestoes = [];
  List<String> get listaSugestoes => _listaSugestoes;

  // Mantido para compatibilidade
  String get sugestao => _listaSugestoes.isNotEmpty ? _listaSugestoes.first : "";

  bool _carregando = false;
  bool get carregando => _carregando;

  // --- ESTADO DA GAMIFICAÇÃO (GRADUAL) ---
  double progressoEstrelas = 0.0; 
  double progressoFogos = 0.0;    
  String feedbackMentor = "Solte a sua primeira rima...";

  // --- CONFIGURAÇÕES DE ESTILO (Sincronizadas com RhymeLevelPage) ---
  String generoAtual = 'Automático';
  String subGeneroAtual = 'Padrão';
  String bpmAtual = 'Automático';
  String tomAtual = 'Automático';
  String estiloVocalAtual = 'Automático';
  bool compartilharDicionario = false;

  // --- CONFIGURAÇÕES DO USUÁRIO ---
  final String _userId = "user_dev_01"; 
  String? _userApiKey = "VERSIN-PRO-TRIAL-2026-FREE"; 
  String? get userApiKey => _userApiKey; 

  List<Rima> vocabulario = [
    Rima(palavra: "plano", isPrioridade: true),
    Rima(palavra: "insano"),
    Rima(palavra: "tango", isPrioridade: true),
    Rima(palavra: "cano"),
  ];

  bool get isProActive => _userApiKey != null && _userApiKey!.isNotEmpty;

  // --- SOLUÇÃO DO ERRO: Método esperado pela ChatPage ---
  void buscarSugestao(String palavra) {
    // Redireciona para o processamento que já tem o debounce e chamada API
    onTextChanged(palavra);
  }

  // --- ATUALIZAR SETUP DA RHYME LEVEL PAGE ---
  void atualizarSetup({
    String? genero,
    String? subGenero,
    String? bpm,
    String? tom,
    String? estiloVocal,
    bool? compartilhar,
  }) {
    if (genero != null) generoAtual = genero;
    if (subGenero != null) subGeneroAtual = subGenero;
    if (bpm != null) bpmAtual = bpm;
    if (tom != null) tomAtual = tom;
    if (estiloVocal != null) estiloVocalAtual = estiloVocal;
    if (compartilhar != null) compartilharDicionario = compartilhar;
    notifyListeners();
  }

  void setApiKey(String key) {
    _userApiKey = key.trim().isEmpty ? null : key.trim();
    notifyListeners();
  }

  // --- LÓGICA DE EVOLUÇÃO (TERMÔMETRO DE FOGO) ---
  void atualizarGamificacao(dynamic nivelRaw, {String? motivo}) {
    int nivel = 0;
    if (nivelRaw is int) {
      nivel = nivelRaw;
    } else if (nivelRaw is String) {
      nivel = int.tryParse(nivelRaw) ?? 0;
    }

    if (nivel <= 0) {
      progressoEstrelas = 0.0; 
      progressoFogos = 0.0;
      feedbackMentor = "O estúdio está silencioso...";
    } 
    else if (nivel >= 1 && nivel <= 3) {
      progressoFogos = 0.0;
      progressoEstrelas = nivel.toDouble();
      feedbackMentor = motivo ?? "O flow está encaixando!";
    } 
    else if (nivel >= 4) {
      progressoEstrelas = 0.0; 
      progressoFogos = (nivel - 3).toDouble().clamp(0.0, 3.0);
      feedbackMentor = motivo ?? "NÍVEL MÁXIMO! 🚀 Hit detectado.";
    }
    notifyListeners();
  }

  // --- SUGESTÃO E PREENCHIMENTO AO DIGITAR ---
  void onTextChanged(String texto) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    String t = texto.trim();

    if (t.isEmpty) {
      _listaSugestoes = [];
      notifyListeners();
      return;
    }

    int duration = isProActive ? 300 : 700; 

    _debounce = Timer(Duration(milliseconds: duration), () async {
      _carregando = true;
      notifyListeners();

      try {
        final response = await http.post(
          Uri.parse('$_baseUrl/processar'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'texto_usuario': t,
            'lista_rimas': vocabulario.map((r) => r.palavra).toList(),
            'api_key_privada': _userApiKey,
            'config_estilo': {
              'genero': generoAtual,
              'subgenero': subGeneroAtual,
              'bpm': bpmAtual,
              'tom': tomAtual,
              'estilo_vocal': estiloVocalAtual,
            }
          }),
        ).timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          
          if (data['resultado'] is List) {
            _listaSugestoes = List<String>.from(data['resultado']);
          } else {
            String res = data['resultado'] ?? "";
            _listaSugestoes = (res == "NENHUMA" || res.isEmpty) ? [] : [res];
          }
          
          atualizarGamificacao(data['nivel_impacto'], motivo: data['motivo_feedback']);
        }
      } catch (e) {
        debugPrint("Erro Versin Processar: $e");
      } finally {
        _carregando = false;
        notifyListeners();
      }
    });
  }

  // --- MÉTODOS DE MANIPULAÇÃO DE LISTA ---
  void registrarRimaUsada(String rima) {
    _listaSugestoes.remove(rima);
    notifyListeners();
  }

  void removerSugestaoDaLista(String rima) {
    _listaSugestoes.remove(rima);
    notifyListeners();
  }

  void limparSugestao() {
    _listaSugestoes = [];
    _carregando = false;
    notifyListeners();
  }

  // --- CHAT COM MENTOR ---
  Future<Map<String, String>> fetchAiResponse(String message) async {
    _carregando = true;
    notifyListeners();
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': _userId,
          'message': message,
          'lista_atual': vocabulario.map((r) => r.palavra).toList(),
          'api_key_privada': _userApiKey,
          'config_estilo': {
            'genero': generoAtual,
            'subgenero': subGeneroAtual,
          }
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        atualizarGamificacao(data['nivel_impacto'], motivo: data['motivo_feedback']);
        return {
          "role": "assistant", 
          "content": data['content'] ?? ""
        };
      }
      return {"role": "assistant", "content": "Erro no servidor do estúdio."};
    } catch (e) {
      return {"role": "assistant", "content": "Erro de conexão com o Versin."};
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  // --- MANUTENÇÃO DO VOCABULÁRIO ---
  void adicionarPalavra(String palavra, bool prioridade) {
    String p = palavra.trim().toLowerCase();
    if (p.isNotEmpty && !vocabulario.any((r) => r.palavra == p)) {
      vocabulario.insert(0, Rima(palavra: p, isPrioridade: prioridade));
      notifyListeners();
    }
  }

  void alternarPrioridade(int index) {
    if (index >= 0 && index < vocabulario.length) {
      vocabulario[index].isPrioridade = !vocabulario[index].isPrioridade;
      notifyListeners();
    }
  }

  void removerPalavra(int index) {
    if (index >= 0 && index < vocabulario.length) {
      vocabulario.removeAt(index);
      notifyListeners();
    }
  }

  @override
  void dispose() { 
    _debounce?.cancel(); 
    super.dispose(); 
  }
}