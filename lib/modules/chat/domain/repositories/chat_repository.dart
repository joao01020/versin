// ============================================================
// CHAT REPOSITORY
// ============================================================
//
// Contrato do módulo de chat.
//
// A UI e o ChatController não precisam saber:
//
// - se a resposta veio da Edge Function;
// - se veio de API privada;
// - qual provider foi utilizado.
//
// ============================================================

abstract class ChatRepository {
  // ============================================================
  // IA
  // ============================================================

  Future<
    Map<
      String,
      dynamic
    >
  >
  fetchAiResponse(
    String message,
  );

  // ============================================================
  // PROJETO
  // ============================================================

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
