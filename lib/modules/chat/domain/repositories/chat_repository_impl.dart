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
  ) async {}
}
