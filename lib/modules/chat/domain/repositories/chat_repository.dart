// ============================================================
// CHAT REPOSITORY
// ============================================================
//
// Contrato principal do módulo de chat.
//
// A camada de apresentação não precisa conhecer detalhes de
// infraestrutura, como:
//
// - backend utilizado;
// - endpoint HTTP;
// - API privada;
// - provider;
// - autenticação;
// - armazenamento da quota.
//
// O repository define somente as operações que o restante do
// módulo pode executar.
//
// ============================================================

abstract class ChatRepository {
  // ============================================================
  // AI RESPONSE
  // ============================================================
  //
  // Solicita uma resposta de IA.
  //
  // A implementação decide automaticamente se deve utilizar:
  //
  // - IA oficial Versin;
  // - API privada configurada pelo usuário.
  //
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
  // AI QUOTA
  // ============================================================
  //
  // Busca a quota atual da IA oficial Versin.
  //
  // Esta operação não deve consumir tokens de IA.
  //
  // A implementação normalmente consulta o backend e retorna
  // informações como:
  //
  // - used_tokens;
  // - remaining_tokens;
  // - limit_tokens;
  // - usage_percentage;
  // - level;
  // - blocked;
  // - renewal information.
  //
  // O backend continua sendo a fonte da verdade.
  //
  // ============================================================

  Future<
    Map<
      String,
      dynamic
    >
  >
  fetchAiQuota();

  // ============================================================
  // SAVE PROJECT
  // ============================================================
  //
  // Persiste informações relacionadas ao projeto atual.
  //
  // A implementação concreta decide onde e como esses dados
  // serão armazenados.
  //
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
