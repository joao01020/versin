/// 1. A Interface (O contrato)
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

/// 2. Implementação Concreta
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
    // Aqui você conectará sua API no futuro
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
    // Lógica para salvar projeto
  }
}
