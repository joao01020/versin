import 'dart:async';
import 'package:flutter/material.dart';
import 'package:versin/core/services/ai_service.dart';
import 'package:versin/core/models/rima_model.dart';

class RimasController extends ChangeNotifier {
  final AIService _aiService = AIService();
  Timer? _debounce;
  
  String _sugestao = "";
  String get sugestao => _sugestao;

  bool _carregando = false;
  bool get carregando => _carregando;

  // LISTA DE OBJETOS RIMA
  List<Rima> vocabulario = [
    Rima(palavra: "plano", isPrioridade: true),
    Rima(palavra: "insano"),
    Rima(palavra: "tango", isPrioridade: true),
    Rima(palavra: "cano"),
  ];

  void adicionarPalavra(String palavra, bool prioridade) {
    if (palavra.isNotEmpty) {
      vocabulario.add(Rima(palavra: palavra.toLowerCase(), isPrioridade: prioridade));
      notifyListeners();
    }
  }

  void alternarPrioridade(int index) {
    vocabulario[index].isPrioridade = !vocabulario[index].isPrioridade;
    notifyListeners();
  }

  void removerPalavra(int index) {
    vocabulario.removeAt(index);
    notifyListeners();
  }

  void onTextChanged(String texto) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (texto.trim().length < 3) {
      _sugestao = "";
      _carregando = false;
      notifyListeners();
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      _carregando = true;
      _sugestao = ""; 
      notifyListeners();

      try {
        // Criamos uma lista de strings enviando as prioridades PRIMEIRO
        List<String> listaParaEnvio = [
          ...vocabulario.where((r) => r.isPrioridade).map((r) => r.palavra),
          ...vocabulario.where((r) => !r.isPrioridade).map((r) => r.palavra),
        ];

        final resultado = await _aiService.buscarSugestao(
          texto: texto,
          rimasUsuario: listaParaEnvio,
          isComando: false,
        );

        _sugestao = resultado.trim();
      } finally {
        _carregando = false; 
        notifyListeners();
      }
    });
  }

  void aceitarSugestao() {
    if (_sugestao.isNotEmpty) {
      vocabulario.removeWhere((r) => r.palavra == _sugestao.toLowerCase());
      _sugestao = "";
      notifyListeners();
    }
  }

  void limparSugestao() => { _sugestao = "", _carregando = false, notifyListeners() };
}