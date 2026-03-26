class Rhyme {
  final String word; // Em inglês: word
  bool isPriority; // Em inglês: isPriority
  final String origin; // Em inglês: origin (NOVO: "user" ou "versin")

  Rhyme({
    required this.word,
    this.isPriority = false,
    this.origin = "user", // Por padrão, o que você adiciona é seu
  });

  // Converte um JSON/Map vindo do Backend para o objeto Rhyme
  factory Rhyme.fromMap(Map<String, dynamic> map) {
    return Rhyme(
      word: map['word'] ?? '',
      isPriority: map['isPriority'] ?? false,
      origin: map['origin'] ?? 'user', // O backend dirá se a rima é dele
    );
  }

  // Converte o objeto Rhyme para JSON/Map para enviar ao Backend ou salvar
  Map<String, dynamic> toMap() {
    return {
      'word': word,
      'isPriority': isPriority,
      'origin': origin,
    };
  }

  // Identifica visualmente a procedência para o Mentor Sincero
  String get originMessage {
    return origin == "versin" 
      ? "Esta rima foi sugerida pelo Versin" 
      : "Esta rima foi configurada por você";
  }

  @override
  String toString() => 'Rhyme(word: $word, priority: $isPriority, origin: $origin)';
}