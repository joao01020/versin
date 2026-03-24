class Rima {
  final String palavra;
  bool isPrioridade;

  Rima({
    required this.palavra, 
    this.isPrioridade = false,
  });

  // Converte um JSON/Map vindo do Backend para o objeto Rima
  factory Rima.fromMap(Map<String, dynamic> map) {
    return Rima(
      palavra: map['palavra'] ?? '',
      isPrioridade: map['isPrioridade'] ?? false,
    );
  }

  // Converte o objeto Rima para JSON/Map para enviar ao Backend ou salvar
  Map<String, dynamic> toMap() {
    return {
      'palavra': palavra,
      'isPrioridade': isPrioridade,
    };
  }

  // Útil para depuração no console do Linux/VS Code
  @override
  String toString() => 'Rima(palavra: $palavra, prioridade: $isPrioridade)';
}