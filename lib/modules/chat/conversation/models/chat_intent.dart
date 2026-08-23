// ============================================================
// CHAT INTENT
// ============================================================
//
// Representa a intenção identificada na mensagem do usuário.
//
// IMPORTANTE:
//
// ChatIntent descreve O QUE o usuário está tentando fazer.
//
// Ele não determina diretamente se a IA será utilizada.
// Essa responsabilidade pertence ao AiRequestAction.
//
// Exemplos:
//
// "Oi"
//      → social
//
// "Rimas com coração"
//      → rhymeSearch
//
// "Minha música está boa?"
//      → incompleteRequest
//
// "Analise este verso: ..."
//      → lyricAnalysis
//
// "Me ajude a desenvolver essa ideia..."
//      → creativeRequest
//
// "Por que você falou isso?"
//      → continuation
//
// "Como programar em Python?"
//      → outOfScope
//
// ============================================================

enum ChatIntent {
  // ==========================================================
  // CONVERSA SOCIAL
  // ==========================================================
  //
  // Saudações e interações humanas simples.
  //
  // Exemplos:
  //
  // - oi
  // - olá
  // - bom dia
  // - tudo bem?
  // - valeu
  // - obrigado
  //
  // Normalmente não precisa utilizar IA.
  //
  // ==========================================================
  social,

  // ==========================================================
  // FORA DO ESCOPO
  // ==========================================================
  //
  // Solicitação claramente não relacionada ao propósito
  // criativo/musical do Versin.
  //
  // Exemplos:
  //
  // - programação
  // - previsão do tempo
  // - matemática sem contexto musical
  //
  // IMPORTANTE:
  //
  // O Gate deve ser conservador ao classificar este estado.
  // Mensagens ambíguas não devem ser bloqueadas simplesmente
  // porque não possuem palavras como "música" ou "rima".
  //
  // ==========================================================
  outOfScope,

  // ==========================================================
  // BUSCA DE RIMAS
  // ==========================================================
  //
  // Consulta que potencialmente pode ser resolvida utilizando
  // a biblioteca de rimas do próprio usuário.
  //
  // Exemplos:
  //
  // - rimas com vida
  // - minhas rimas para coração
  // - palavras que rimam com madrugada
  //
  // Nem toda rhymeSearch necessariamente precisa de IA.
  //
  // ==========================================================
  rhymeSearch,

  // ==========================================================
  // ANÁLISE DE LETRA
  // ==========================================================
  //
  // O usuário forneceu material suficiente e deseja análise.
  //
  // Exemplos:
  //
  // - analise esse verso: "..."
  // - avalie esse refrão: "..."
  // - como está a métrica desse trecho: "..."
  //
  // Normalmente exige IA.
  //
  // ==========================================================
  lyricAnalysis,

  // ==========================================================
  // SOLICITAÇÃO CRIATIVA
  // ==========================================================
  //
  // Solicitação musical/criativa válida que exige raciocínio,
  // desenvolvimento ou geração.
  //
  // Exemplos:
  //
  // - me ajude a desenvolver essa ideia
  // - como posso melhorar esse refrão?
  // - quero trabalhar esse conceito na música
  //
  // ==========================================================
  creativeRequest,

  // ==========================================================
  // SOLICITAÇÃO INCOMPLETA
  // ==========================================================
  //
  // Existe uma intenção musical válida, mas faltam informações
  // necessárias para executar a tarefa.
  //
  // Exemplos:
  //
  // "Minha música está boa?"
  //
  // sem enviar a música.
  //
  // "Analisa meu refrão"
  //
  // sem enviar o refrão.
  //
  // O Versin pode pedir o material localmente sem gastar IA.
  //
  // ==========================================================
  incompleteRequest,

  // ==========================================================
  // CONTINUAÇÃO
  // ==========================================================
  //
  // Mensagem curta que depende diretamente da interação
  // criativa anterior.
  //
  // Exemplos:
  //
  // IA:
  // "O fechamento desse verso está previsível."
  //
  // Usuário:
  // "Como assim?"
  //
  // Nesse caso a mensagem isolada é curta, mas possui sentido
  // dentro da sessão criativa atual.
  //
  // ==========================================================
  continuation,

  // ==========================================================
  // DESCONHECIDO
  // ==========================================================
  //
  // O Gate não conseguiu classificar a intenção com segurança.
  //
  // É importante possuir este estado para evitar classificar
  // agressivamente mensagens ambíguas como outOfScope.
  //
  // ==========================================================
  unknown,
}
