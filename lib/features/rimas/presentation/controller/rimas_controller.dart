import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:versin/core/models/rima_model.dart';

class RimasController extends ChangeNotifier {
  Timer? _debounce;
  
  // No Linux (Debian), mantenha 127.0.0.1. 
  final String _baseUrl = "http://127.0.0.1:8000";

  // --- ESTADO ---
  String _sugestao = "";
  String get sugestao => _sugestao;

  bool _carregando = false;
  bool get carregando => _carregando;

  // --- CONFIGURAÇÕES DO USUÁRIO (SISTEMA PRO) ---
  final String _userId = "user_dev_01"; 
  
  String? _userApiKey; 
  String? get userApiKey => _userApiKey; 

  List<Rima> vocabulario = [
    Rima(palavra: "plano", isPrioridade: true),
    Rima(palavra: "insano"),
    Rima(palavra: "tango", isPrioridade: true),
    Rima(palavra: "cano"),
  ];

  // Verifica se o usuário tem qualquer tipo de chave ativa (Trial ou Privada)
  bool get isProActive => _userApiKey != null && _userApiKey!.isNotEmpty;

  void setApiKey(String key) {
    _userApiKey = key.trim().isEmpty ? null : key.trim();
    notifyListeners();
  }

  // --- CHAT COM MENTOR (VERSIN) ---
  Future<Map<String, String>> fetchAiResponse(String message) async {
    _carregando = true;
    notifyListeners();

    try {
      List<String> listaSimples = vocabulario.map((r) => r.palavra).toList();

      final response = await http.post(
        Uri.parse('$_baseUrl/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': _userId,
          'message': message,
          'lista_atual': listaSimples,
          'api_key_privada': _userApiKey, 
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          "role": "assistant",
          "content": data['content'] ?? "Mano, o **Mentor** ficou sem palavras."
        };
      } else {
        return {
          "role": "assistant",
          "content": "Erro **${response.statusCode}**. O estúdio caiu?"
        };
      }
    } on TimeoutException {
      return {"role": "assistant", "content": "A **banca** demorou muito. Tenta de novo?"};
    } catch (e) {
      return {"role": "assistant", "content": "Sem conexão com o **backend**. Verifique o servidor."};
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  // --- SUGESTÃO FONÉTICA E SEMÂNTICA (BALÃO) ---
  void onTextChanged(String texto) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (texto.trim().length < 3) {
      _sugestao = "";
      _carregando = false;
      notifyListeners();
      return;
    }

    // VELOCIDADE ADAPTATIVA: 
    // Se for PRO, o tempo de espera para processar a rima cai para 300ms (Mais rápido)
    // Se for FREE, mantém 600ms para não sobrecarregar o servidor
    int duration = isProActive ? 300 : 600;

    _debounce = Timer(Duration(milliseconds: duration), () async {
      _carregando = true;
      notifyListeners();

      try {
        List<String> listaParaEnvio = vocabulario.map((r) => r.palavra).toList();

        final response = await http.post(
          Uri.parse('$_baseUrl/processar'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'texto_usuario': texto,
            'lista_rimas': listaParaEnvio,
            'api_key_privada': _userApiKey,
          }),
        ).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          String result = data['resultado'] ?? "";
          _sugestao = (result == "NENHUMA") ? "" : result;
        } else {
          _sugestao = "";
        }
      } catch (e) {
        _sugestao = "";
      } finally {
        _carregando = false;
        notifyListeners();
      }
    });
  }

  // --- GERENCIAMENTO DO VOCABULÁRIO ---
  
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

  void aceitarSugestao() {
    if (_sugestao.isNotEmpty) {
      _sugestao = "";
      notifyListeners();
    }
  }

  void limparSugestao() {
    _sugestao = ""; 
    _carregando = false; 
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}