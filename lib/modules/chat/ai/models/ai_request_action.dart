// ============================================================
// AI REQUEST ACTION
// ============================================================
//
// Representa a ação que o Versin deve executar depois que
// AiRequestGateService analisar a mensagem.
//
// IMPORTANTE:
//
// ChatIntent:
//     identifica O QUE o usuário deseja.
//
// AiRequestAction:
//     determina COMO o Versin atenderá aquela solicitação.
//
// Isso mantém classificação e execução separadas.
//
// ============================================================

enum AiRequestAction {
  // ==========================================================
  // RESPOSTA LOCAL
  // ==========================================================
  //
  // Nenhuma chamada de IA deve acontecer.
  //
  // Exemplos:
  //
  // "Oi"
  //
  // "Tudo bem?"
  //
  // "Minha música está boa?"
  // sem fornecer a música.
  //
  // "Me ensina Python."
  //
  // A resposta pode ser produzida pelo
  // ChatLocalResponseService.
  //
  // CUSTO DE IA:
  //
  // 0 tokens.
  //
  // ==========================================================
  localResponse,

  // ==========================================================
  // BUSCAR NA BIBLIOTECA
  // ==========================================================
  //
  // A solicitação pode ser resolvida consultando dados
  // existentes do usuário.
  //
  // Principal utilização inicial:
  //
  // biblioteca de rimas.
  //
  // Exemplo:
  //
  // "Minhas rimas com coração"
  //
  // Não deve chamar a IA quando a biblioteca conseguir
  // resolver a solicitação.
  //
  // ==========================================================
  librarySearch,

  // ==========================================================
  // UTILIZAR IA
  // ==========================================================
  //
  // Existe uma solicitação criativa válida que realmente
  // necessita do modelo de IA.
  //
  // Exemplos:
  //
  // - análise de letra;
  // - análise de métrica;
  // - desenvolvimento criativo;
  // - avaliação contextual;
  // - continuação de uma análise.
  //
  // Somente neste caminho o fluxo deve chegar ao:
  //
  // AiProviderService
  //
  // e consequentemente:
  //
  // IA Versin
  //
  // ou
  //
  // API privada.
  //
  // ==========================================================
  useAi,
}
