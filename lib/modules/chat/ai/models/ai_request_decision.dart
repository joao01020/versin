import 'ai_request_action.dart';
import '../../conversation/models/chat_intent.dart';

// ============================================================
// AI REQUEST DECISION
// ============================================================
//
// Resultado produzido pelo AiRequestGateService.
//
// O objeto responde duas perguntas:
//
// 1. Qual é a intenção do usuário?
//
//      ChatIntent
//
// 2. O que o aplicativo deve fazer?
//
//      AiRequestAction
//
// Também pode carregar:
//
// - resposta local;
// - termo para busca na biblioteca;
// - motivo interno da decisão.
//
// ============================================================

class AiRequestDecision {
  // ============================================================
  // INTENÇÃO
  // ============================================================

  final ChatIntent intent;

  // ============================================================
  // AÇÃO
  // ============================================================

  final AiRequestAction action;

  // ============================================================
  // RESPOSTA LOCAL
  // ============================================================
  //
  // Utilizada quando:
  //
  // action == AiRequestAction.localResponse
  //
  // Exemplo:
  //
  // "Manda o trecho que você quer analisar."
  //
  // ============================================================

  final String? localResponse;

  // ============================================================
  // CONSULTA DA BIBLIOTECA
  // ============================================================
  //
  // Utilizada quando:
  //
  // action == AiRequestAction.librarySearch
  //
  // Exemplo:
  //
  // mensagem:
  //
  // "rimas com coração"
  //
  // libraryQuery:
  //
  // "coração"
  //
  // ============================================================

  final String? libraryQuery;

  // ============================================================
  // MOTIVO INTERNO
  // ============================================================
  //
  // Útil para:
  //
  // - debug;
  // - logs;
  // - testes;
  // - entender por que uma chamada de IA foi bloqueada.
  //
  // Este valor não precisa ser exibido para o usuário.
  //
  // IMPORTANTE:
  //
  // Não armazenar dados sensíveis neste campo.
  //
  // ============================================================

  final String? reason;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  const AiRequestDecision({
    required this.intent,
    required this.action,
    this.localResponse,
    this.libraryQuery,
    this.reason,
  });

  // ============================================================
  // FACTORY
  // RESPOSTA LOCAL
  // ============================================================

  factory AiRequestDecision.local({
    required ChatIntent intent,
    required String response,
    String? reason,
  }) {
    return AiRequestDecision(
      intent: intent,
      action: AiRequestAction.localResponse,
      localResponse: response,
      reason: reason,
    );
  }

  // ============================================================
  // FACTORY
  // BIBLIOTECA
  // ============================================================

  factory AiRequestDecision.library({
    required ChatIntent intent,
    required String query,
    String? reason,
  }) {
    return AiRequestDecision(
      intent: intent,
      action: AiRequestAction.librarySearch,
      libraryQuery: query,
      reason: reason,
    );
  }

  // ============================================================
  // FACTORY
  // IA
  // ============================================================

  factory AiRequestDecision.ai({
    required ChatIntent intent,
    String? reason,
  }) {
    return AiRequestDecision(
      intent: intent,
      action: AiRequestAction.useAi,
      reason: reason,
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  bool get shouldUseAi {
    return action ==
        AiRequestAction.useAi;
  }

  bool get shouldRespondLocally {
    return action ==
        AiRequestAction.localResponse;
  }

  bool get shouldSearchLibrary {
    return action ==
        AiRequestAction.librarySearch;
  }

  // ============================================================
  // POSSUI RESPOSTA LOCAL
  // ============================================================

  bool get hasLocalResponse {
    final response = localResponse?.trim();

    return response !=
            null &&
        response.isNotEmpty;
  }

  // ============================================================
  // POSSUI CONSULTA
  // ============================================================

  bool get hasLibraryQuery {
    final query = libraryQuery?.trim();

    return query !=
            null &&
        query.isNotEmpty;
  }

  // ============================================================
  // VALIDAÇÃO
  // ============================================================
  //
  // Ajuda a detectar decisões inválidas durante desenvolvimento.
  //
  // ============================================================

  bool get isValid {
    switch (action) {
      case AiRequestAction.localResponse:
        return hasLocalResponse;

      case AiRequestAction.librarySearch:
        return hasLibraryQuery;

      case AiRequestAction.useAi:
        return true;
    }
  }

  // ============================================================
  // TO STRING
  // ============================================================
  //
  // Não imprime conteúdo da mensagem do usuário.
  //
  // ============================================================

  @override
  String toString() {
    return 'AiRequestDecision('
        'intent: ${intent.name}, '
        'action: ${action.name}, '
        'hasLocalResponse: $hasLocalResponse, '
        'hasLibraryQuery: $hasLibraryQuery, '
        'reason: $reason'
        ')';
  }
}
