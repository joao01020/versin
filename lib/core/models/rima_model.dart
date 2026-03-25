class Rima {
  final String palavra;
  bool isPrioridade;
  final String origem; // NOVO: "usuario" ou "versin"

  Rima({
    required this.palavra,
    this.isPrioridade = false,
    this.origem = "usuario", // Por padrão, o que você adiciona é seu
  });

  // Converte um JSON/Map vindo do Backend para o objeto Rima
  factory Rima.fromMap(Map<String, dynamic> map) {
    return Rima(
      palavra: map['palavra'] ?? '',
      isPrioridade: map['isPrioridade'] ?? false,
      origem: map['origem'] ?? 'usuario', // O backend dirá se a rima é dele
    );
  }

  // Converte o objeto Rima para JSON/Map para enviar ao Backend ou salvar
  Map<String, dynamic> toMap() {
    return {
      'palavra': palavra,
      'isPrioridade': isPrioridade,
      'origem': origem,
    };
  }

  // Identifica visualmente a procedência para o Mentor Sincero
  String get mensagemOrigem {
    return origem == "versin" 
      ? "Esta rima foi sugerida pelo Versin" 
      : "Esta rima foi configurada por você";
  }

  @override
  String toString() => 'Rima(palavra: $palavra, prioridade: $isPrioridade, origem: $origem)';
}