import 'package:flutter/material.dart';

class SuggestionController
    extends
        ChangeNotifier {
  // Estado
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Banco de rimas
  final Map<
    String,
    List<
      String
    >
  >
  _rhymes = {};

  // Palavras já utilizadas
  final Set<
    String
  >
  _usedWords = {};

  // Sugestões atuais
  List<
    String
  >
  _suggestions = [];

  List<
    String
  >
  get suggestions => List.unmodifiable(
    _suggestions,
  );

  // Índice atual
  int _currentIndex = 0;

  // Sugestão atual
  String get currentSuggestion {
    if (_suggestions.isEmpty) return "";
    return _suggestions[_currentIndex];
  }

  // ---------------------------
  // Loading
  // ---------------------------

  void setLoading(
    bool value,
  ) {
    _isLoading = value;
    notifyListeners();
  }

  // ---------------------------
  // Adiciona uma família de rimas
  // ---------------------------

  void addRhymes(
    String baseWord,
    List<
      String
    >
    words,
  ) {
    _rhymes[baseWord.toLowerCase()] = words;
  }

  // ---------------------------
  // Atualiza baseado no texto
  // ---------------------------

  void updateFromText(
    String text,
  ) {
    final words = text
        .trim()
        .split(
          RegExp(
            r'\s+',
          ),
        )
        .where(
          (
            e,
          ) => e.isNotEmpty,
        )
        .toList();

    if (words.isEmpty) {
      _suggestions = [];
      _currentIndex = 0;

      notifyListeners();
      return;
    }

    final lastWord = words.last.toLowerCase();

    if (_rhymes.containsKey(
      lastWord,
    )) {
      _suggestions = _rhymes[lastWord]!
          .where(
            (
              word,
            ) => !_usedWords.contains(
              word.toLowerCase(),
            ),
          )
          .toList();

      _currentIndex = 0;
    } else {
      _suggestions = [];
      _currentIndex = 0;
    }

    notifyListeners();
  }

  // ---------------------------
  // Próxima sugestão
  // ---------------------------

  void nextSuggestion() {
    if (_suggestions.isEmpty) return;

    _currentIndex++;

    if (_currentIndex >=
        _suggestions.length) {
      _currentIndex = 0;
    }

    notifyListeners();
  }

  // ---------------------------
  // Sugestão anterior
  // ---------------------------

  void previousSuggestion() {
    if (_suggestions.isEmpty) return;

    _currentIndex--;

    if (_currentIndex <
        0) {
      _currentIndex =
          _suggestions.length -
          1;
    }

    notifyListeners();
  }

  // ---------------------------
  // Marca uma palavra como usada
  // ---------------------------

  void useCurrentSuggestion() {
    if (_suggestions.isEmpty) return;

    final word = currentSuggestion;

    _usedWords.add(
      word.toLowerCase(),
    );

    _suggestions.remove(
      word,
    );

    if (_currentIndex >=
        _suggestions.length) {
      _currentIndex = 0;
    }

    notifyListeners();
  }

  void useWord(
    String word,
  ) {
    _usedWords.add(
      word.toLowerCase(),
    );

    _suggestions.remove(
      word,
    );

    if (_currentIndex >=
        _suggestions.length) {
      _currentIndex = 0;
    }

    notifyListeners();
  }

  // ---------------------------
  // Define sugestões manualmente
  // ---------------------------

  void setSuggestions(
    List<
      String
    >
    words,
  ) {
    _suggestions = words;

    _currentIndex = 0;

    notifyListeners();
  }

  // ---------------------------
  // Limpa sugestões
  // ---------------------------

  void clearSuggestions() {
    _suggestions.clear();

    _currentIndex = 0;

    notifyListeners();
  }

  // ---------------------------
  // Limpa histórico de usadas
  // ---------------------------

  void clearUsedWords() {
    _usedWords.clear();

    notifyListeners();
  }

  // ---------------------------
  // Reset geral
  // ---------------------------

  void reset() {
    _isLoading = false;

    _currentIndex = 0;

    _suggestions.clear();

    _usedWords.clear();

    notifyListeners();
  }
}
