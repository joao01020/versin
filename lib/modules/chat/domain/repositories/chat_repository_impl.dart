/// 1. A Interface (O contrato)
/// Nota: A camada de domínio não deve depender de modelos de dados da UI.
/// Se você precisar de modelos aqui, eles devem ser definidos na camada de domínio.
abstract class ChatRepository {
  Future<
    List<
      Map<
        String,
        dynamic
      >
    >
  >
  fetchAiResponse(
    String message,
  );
  Future<
    void
  >
  saveProject(
    Map<
      String,
      dynamic
    >
    projectData,
  );
}

/// 2. A Implementação (A classe concreta)
class ChatRepositoryImpl
    implements
        ChatRepository {
  @override
  Future<
    List<
      Map<
        String,
        dynamic
      >
    >
  >
  fetchAiResponse(
    String message,
  ) async {
    // TODO: Implementar a lógica de chamada da API aqui
    return [];
  }

  @override
  Future<
    void
  >
  saveProject(
    Map<
      String,
      dynamic
    >
    projectData,
  ) async {
    // TODO: Implementar a lógica para persistência (ex: Supabase)
  }
}
