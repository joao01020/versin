class CreativeVision {
  final List<String> originalWords;
  final List<String> emotions;
  final List<String> themes;
  final List<String> images;
  final List<String> states;
  final String summary;

  const CreativeVision({
    required this.originalWords,
    required this.emotions,
    required this.themes,
    required this.images,
    required this.states,
    required this.summary,
  });

  bool get isEmpty =>
      originalWords.isEmpty &&
      emotions.isEmpty &&
      themes.isEmpty &&
      images.isEmpty &&
      states.isEmpty;
}

class CreativeVisionService {
  // ============================================================
  // CONFIGURAÇÕES
  // ============================================================

  static const int _maxOriginalWords = 10;
  static const int _maxEmotions = 4;
  static const int _maxThemes = 4;
  static const int _maxImages = 4;
  static const int _maxStates = 4;

  // ============================================================
  // STOP WORDS
  // ============================================================

  static const Set<String> _stopWords = {
    'a',
    'ao',
    'aos',
    'aquela',
    'aquelas',
    'aquele',
    'aqueles',
    'aquilo',
    'as',
    'até',
    'com',
    'como',
    'da',
    'das',
    'de',
    'dela',
    'delas',
    'dele',
    'deles',
    'depois',
    'do',
    'dos',
    'e',
    'ela',
    'elas',
    'ele',
    'eles',
    'em',
    'essa',
    'essas',
    'esse',
    'esses',
    'esta',
    'está',
    'estão',
    'estava',
    'este',
    'estes',
    'eu',
    'foi',
    'já',
    'lá',
    'mais',
    'mas',
    'me',
    'meu',
    'meus',
    'minha',
    'minhas',
    'muito',
    'na',
    'nas',
    'no',
    'nos',
    'o',
    'os',
    'ou',
    'para',
    'pela',
    'pelas',
    'pelo',
    'pelos',
    'por',
    'porque',
    'que',
    'se',
    'sem',
    'só',
    'sua',
    'suas',
    'seu',
    'seus',
    'também',
    'tem',
    'tenho',
    'um',
    'uma',
    'umas',
    'uns',
    'vai',
    'você',
    'vocês',
  };

  // ============================================================
  // MAPA DE EMOÇÕES
  // ============================================================

  static const Map<String, List<String>> _emotionMap = {
    'amor': ['afeto', 'saudade', 'desejo', 'ausência'],
    'saudade': ['ausência', 'nostalgia', 'carência', 'memória'],
    'ódio': ['raiva', 'revolta', 'conflito'],
    'odio': ['raiva', 'revolta', 'conflito'],
    'raiva': ['revolta', 'tensão', 'conflito'],
    'medo': ['insegurança', 'ansiedade', 'tensão'],
    'ansiedade': ['inquietação', 'pressão', 'medo'],
    'silêncio': ['solidão', 'introspecção', 'distância', 'paz'],
    'silencio': ['solidão', 'introspecção', 'distância', 'paz'],
    'vazio': ['solidão', 'ausência', 'carência', 'desconexão'],
    'sozinho': ['solidão', 'introspecção', 'ausência'],
    'sozinha': ['solidão', 'introspecção', 'ausência'],
    'feliz': ['alegria', 'leveza', 'esperança'],
    'felicidade': ['alegria', 'leveza', 'esperança'],
    'triste': ['melancolia', 'solidão', 'saudade'],
    'tristeza': ['melancolia', 'solidão', 'saudade'],
    'culpa': ['arrependimento', 'peso', 'conflito'],
    'paz': ['calma', 'liberdade', 'aceitação'],
    'liberdade': ['leveza', 'autonomia', 'renascimento'],
  };

  // ============================================================
  // MAPA DE TEMAS
  // ============================================================

  static const Map<String, List<String>> _themeMap = {
    'amor': ['relacionamento', 'entrega', 'ausência'],
    'família': ['origem', 'pertencimento', 'memória'],
    'familia': ['origem', 'pertencimento', 'memória'],
    'mãe': ['família', 'origem', 'proteção'],
    'mae': ['família', 'origem', 'proteção'],
    'pai': ['família', 'origem', 'referência'],
    'rua': ['origem', 'sobrevivência', 'cidade'],
    'bairro': ['origem', 'pertencimento', 'memória'],
    'dinheiro': ['ambição', 'sobrevivência', 'poder'],
    'sucesso': ['ambição', 'conquista', 'mudança'],
    'fracasso': ['queda', 'medo', 'recomeço'],
    'passado': ['memória', 'arrependimento', 'mudança'],
    'futuro': ['esperança', 'direção', 'mudança'],
    'destino': ['direção', 'escolha', 'identidade'],
    'perdido': ['busca', 'direção', 'identidade'],
    'perdida': ['busca', 'direção', 'identidade'],
    'mudança': ['transformação', 'identidade', 'recomeço'],
    'mudanca': ['transformação', 'identidade', 'recomeço'],
    'cicatriz': ['passado', 'dor', 'superação'],
    'cicatrizes': ['passado', 'dor', 'superação'],
    'sonho': ['ambição', 'esperança', 'futuro'],
    'sonhos': ['ambição', 'esperança', 'futuro'],
  };

  // ============================================================
  // MAPA DE IMAGENS / CENAS
  // ============================================================

  static const Map<String, List<String>> _imageMap = {
    'madrugada': ['noite', 'silêncio', 'cidade', 'insônia'],
    'noite': ['escuridão', 'cidade', 'silêncio'],
    'chuva': ['vidro', 'rua', 'reflexo', 'frio'],
    'carro': ['estrada', 'janela', 'retrovisor', 'movimento'],
    'vidro': ['reflexo', 'chuva', 'janela', 'quebra'],
    'espelho': ['reflexo', 'identidade', 'imagem'],
    'reflexo': ['espelho', 'identidade', 'imagem'],
    'neon': ['cidade', 'noite', 'luz'],
    'fumaça': ['névoa', 'ambiente', 'mistério'],
    'fumaca': ['névoa', 'ambiente', 'mistério'],
    'quarto': ['isolamento', 'silêncio', 'memória'],
    'janela': ['distância', 'rua', 'visão'],
    'avenida': ['cidade', 'movimento', 'noite'],
    'farol': ['rua', 'luz', 'espera'],
    'telefone': ['mensagem', 'distância', 'contato'],
    'celular': ['mensagem', 'distância', 'contato'],
    'mensagem': ['espera', 'contato', 'ausência'],
  };

  // ============================================================
  // MAPA DE ESTADOS
  // ============================================================

  static const Map<String, List<String>> _stateMap = {
    'perdido': ['busca', 'confusão', 'direção'],
    'perdida': ['busca', 'confusão', 'direção'],
    'preso': ['limite', 'conflito', 'fuga'],
    'presa': ['limite', 'conflito', 'fuga'],
    'livre': ['liberdade', 'leveza', 'autonomia'],
    'cansado': ['peso', 'desgaste', 'limite'],
    'cansada': ['peso', 'desgaste', 'limite'],
    'confuso': ['dúvida', 'busca', 'direção'],
    'confusa': ['dúvida', 'busca', 'direção'],
    'quebrado': ['dor', 'queda', 'recomeço'],
    'quebrada': ['dor', 'queda', 'recomeço'],
    'distante': ['ausência', 'separação', 'silêncio'],
    'sozinho': ['isolamento', 'solidão', 'introspecção'],
    'sozinha': ['isolamento', 'solidão', 'introspecção'],
  };

  // ============================================================
  // ANALISAR TEXTO
  // ============================================================

  CreativeVision analyze(String text) {
    final originalWords = _extractRelevantWords(text);

    if (originalWords.isEmpty) {
      return const CreativeVision(
        originalWords: [],
        emotions: [],
        themes: [],
        images: [],
        states: [],
        summary:
            'Ainda não tenho material suficiente para enxergar um caminho.',
      );
    }

    final emotionScores = <String, int>{};

    final themeScores = <String, int>{};

    final imageScores = <String, int>{};

    final stateScores = <String, int>{};

    for (final word in originalWords) {
      _scoreAssociations(word, _emotionMap, emotionScores);

      _scoreAssociations(word, _themeMap, themeScores);

      _scoreAssociations(word, _imageMap, imageScores);

      _scoreAssociations(word, _stateMap, stateScores);
    }

    final emotions = _getTopResults(emotionScores, _maxEmotions);

    final themes = _getTopResults(themeScores, _maxThemes);

    final images = _getTopResults(imageScores, _maxImages);

    final states = _getTopResults(stateScores, _maxStates);

    final summary = _buildSummary(
      originalWords: originalWords,
      emotions: emotions,
      themes: themes,
      images: images,
      states: states,
    );

    return CreativeVision(
      originalWords: originalWords,
      emotions: emotions,
      themes: themes,
      images: images,
      states: states,
      summary: summary,
    );
  }

  // ============================================================
  // EXTRAÇÃO DE PALAVRAS
  // ============================================================

  List<String> _extractRelevantWords(String text) {
    final normalized = text.toLowerCase().replaceAll(
      RegExp(r'[^\p{L}\p{N}\s]', unicode: true),
      ' ',
    );

    final words = normalized.split(RegExp(r'\s+'));

    final result = <String>[];

    for (final rawWord in words) {
      final word = rawWord.trim();

      if (word.length < 3) {
        continue;
      }

      if (_stopWords.contains(word)) {
        continue;
      }

      if (result.contains(word)) {
        continue;
      }

      result.add(word);

      if (result.length >= _maxOriginalWords) {
        break;
      }
    }

    return result;
  }

  // ============================================================
  // PONTUAR ASSOCIAÇÕES
  // ============================================================

  void _scoreAssociations(
    String word,
    Map<String, List<String>> sourceMap,
    Map<String, int> scoreMap,
  ) {
    final associations = sourceMap[word];

    if (associations == null) {
      return;
    }

    for (final association in associations) {
      scoreMap.update(association, (score) => score + 1, ifAbsent: () => 1);
    }
  }

  // ============================================================
  // PEGAR MELHORES RESULTADOS
  // ============================================================

  List<String> _getTopResults(Map<String, int> scores, int limit) {
    final entries = scores.entries.toList();

    entries.sort((a, b) {
      final scoreComparison = b.value.compareTo(a.value);

      if (scoreComparison != 0) {
        return scoreComparison;
      }

      return a.key.compareTo(b.key);
    });

    return entries.take(limit).map((entry) => entry.key).toList();
  }

  // ============================================================
  // CRIAR RESUMO LOCAL
  // ============================================================

  String _buildSummary({
    required List<String> originalWords,
    required List<String> emotions,
    required List<String> themes,
    required List<String> images,
    required List<String> states,
  }) {
    final parts = <String>[];

    if (images.isNotEmpty) {
      parts.add(
        'Tem uma cena começando a aparecer em torno de ${_joinNatural(images.take(2).toList())}.',
      );
    }

    if (emotions.isNotEmpty) {
      parts.add(
        'Emocionalmente, estou percebendo ${_joinNatural(emotions.take(2).toList())}.',
      );
    }

    if (states.isNotEmpty) {
      parts.add(
        'Também existe uma sensação de ${_joinNatural(states.take(2).toList())}.',
      );
    }

    if (themes.isNotEmpty) {
      parts.add(
        'Isso pode abrir caminhos ligados a ${_joinNatural(themes.take(3).toList())}.',
      );
    }

    if (parts.isEmpty) {
      return 'Estou começando a enxergar algumas imagens, mas ainda está aberto. '
          'Continue colocando palavras, cenas ou sensações.';
    }

    return parts.join('\n');
  }

  // ============================================================
  // JUNÇÃO NATURAL
  // ============================================================

  String _joinNatural(List<String> values) {
    if (values.isEmpty) {
      return '';
    }

    if (values.length == 1) {
      return values.first;
    }

    if (values.length == 2) {
      return '${values[0]} e ${values[1]}';
    }

    final beginning = values.sublist(0, values.length - 1).join(', ');

    return '$beginning e ${values.last}';
  }
}
