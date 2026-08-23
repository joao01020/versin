import '../../models/ai_request_decision.dart';
import '../../../conversation/models/chat_intent.dart';

import '../../../conversation/services/chat_local_response_service.dart';

// ============================================================
// AI REQUEST GATE SERVICE
// ============================================================
//
// Decide se uma mensagem realmente precisa utilizar IA.
//
// OBJETIVO PRINCIPAL:
//
// Evitar chamadas desnecessárias para:
//
// - conversa social;
// - saudações;
// - agradecimentos;
// - pedidos musicais incompletos;
// - buscas simples de rimas;
// - solicitações claramente fora do escopo.
//
// FLUXO:
//
// mensagem
//    ↓
// AiRequestGateService
//    │
//    ├── social
//    │      ↓
//    │   resposta local
//    │
//    ├── pedido incompleto
//    │      ↓
//    │   resposta local
//    │
//    ├── rimas
//    │      ↓
//    │   biblioteca
//    │
//    ├── fora do escopo
//    │      ↓
//    │   resposta local
//    │
//    └── trabalho criativo
//           ↓
//          IA
//
// IMPORTANTE:
//
// O Gate deve ser conservador.
//
// Se não for possível determinar com segurança que a mensagem
// é inútil para o contexto criativo, é melhor permitir a IA do
// que bloquear uma solicitação musical legítima.
//
// ============================================================

class AiRequestGateService {
  // ============================================================
  // RESPOSTAS LOCAIS
  // ============================================================

  final ChatLocalResponseService localResponseService;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  AiRequestGateService({
    ChatLocalResponseService? localResponseService,
  }) : localResponseService =
           localResponseService ??
           ChatLocalResponseService();

  // ============================================================
  // ANALISAR
  // ============================================================
  //
  // hasActiveCreativeContext:
  //
  // informa se existe uma conversa criativa imediatamente
  // anterior que permite interpretar mensagens como:
  //
  // "como assim?"
  // "por quê?"
  // "e essa parte?"
  // "melhor assim?"
  //
  // como continuações legítimas.
  //
  // ============================================================

  AiRequestDecision evaluate({
    required String message,
    bool hasActiveCreativeContext = false,
  }) {
    final original = message.trim();

    final normalized = _normalize(
      original,
    );

    // ==========================================================
    // MENSAGEM VAZIA
    // ==========================================================

    if (normalized.isEmpty) {
      return AiRequestDecision.local(
        intent: ChatIntent.incompleteRequest,
        response: 'Manda o que você quer trabalhar na música.',
        reason: 'Mensagem vazia.',
      );
    }

    // ==========================================================
    // REMOVER ABERTURA SOCIAL DA ANÁLISE PRINCIPAL
    // ==========================================================
    //
    // Exemplos:
    //
    // "Oi, bom dia, tudo bem? Analisa minha letra..."
    //
    // vira semanticMessage:
    //
    // "analisa minha letra..."
    //
    // A saudação continua existindo na mensagem original, mas não
    // impede o Gate de reconhecer a intenção principal.
    //
    // ==========================================================

    final semanticMessage = _stripLeadingSocialNoise(
      normalized,
    );

    final semanticForAnalysis = semanticMessage.isNotEmpty
        ? semanticMessage
        : normalized;

    // ==========================================================
    // CONTINUAÇÃO COM CONTEXTO CRIATIVO
    // ==========================================================
    //
    // "Como assim?"
    // "Por quê?"
    // "Melhor assim?"
    //
    // Se existe contexto criativo ativo, pode ser continuação
    // legítima e deve chegar à IA.
    //
    // ==========================================================

    if (_isContinuation(
          semanticForAnalysis,
        ) &&
        hasActiveCreativeContext) {
      return AiRequestDecision.ai(
        intent: ChatIntent.continuation,
        reason: 'Continuação de contexto criativo ativo.',
      );
    }

    // ==========================================================
    // ANÁLISE MUSICAL COMPLETA
    // ==========================================================
    //
    // Esta verificação vem ANTES da conversa social.
    //
    // Assim:
    //
    // "Oi, tudo bem? Analise esse verso: ..."
    //
    // continua sendo uma solicitação de IA.
    //
    // ==========================================================

    if (_isLyricAnalysis(
      semanticForAnalysis,
      original,
    )) {
      return AiRequestDecision.ai(
        intent: ChatIntent.lyricAnalysis,
        reason: 'Solicitação de análise com material disponível.',
      );
    }

    // ==========================================================
    // BUSCA SIMPLES DE RIMAS
    // ==========================================================
    //
    // Também vem antes do social:
    //
    // "Bom dia, o que rima com coração?"
    //
    // deve consultar a biblioteca e não ser tratado apenas como
    // uma saudação.
    //
    // ==========================================================

    final rhymeQuery = _extractSimpleRhymeQuery(
      original,
      semanticForAnalysis,
    );

    if (rhymeQuery !=
        null) {
      return AiRequestDecision.library(
        intent: ChatIntent.rhymeSearch,
        query: rhymeQuery,
        reason: 'Consulta simples que pode ser resolvida pela biblioteca.',
      );
    }

    // ==========================================================
    // PEDIDO MUSICAL INCOMPLETO
    // ==========================================================
    //
    // Exemplo:
    //
    // "Oi, tudo bem? Analisa minha letra."
    //
    // Existe intenção musical, mas ainda não há letra suficiente.
    // Nesse caso pedimos o material localmente e gastamos 0 tokens.
    //
    // ==========================================================

    if (_isIncompleteCreativeRequest(
      semanticForAnalysis,
      original,
    )) {
      return AiRequestDecision.local(
        intent: ChatIntent.incompleteRequest,
        response: localResponseService.incompleteRequestResponse(
          message: original,
        ),
        reason: 'Solicitação musical válida sem material suficiente.',
      );
    }

    // ==========================================================
    // PEDIDO CRIATIVO
    // ==========================================================
    //
    // Se existe intenção musical real, ela tem prioridade sobre a
    // saudação inicial.
    //
    // ==========================================================

    if (_isCreativeRequest(
      semanticForAnalysis,
    )) {
      return AiRequestDecision.ai(
        intent: ChatIntent.creativeRequest,
        reason: 'Solicitação criativa relacionada à música.',
      );
    }

    // ==========================================================
    // SOCIAL PURO
    // ==========================================================
    //
    // Só chega aqui quando NÃO existe uma solicitação musical que
    // tenha prioridade.
    //
    // Exemplos:
    //
    // "Oi"
    // "Oiiii"
    // "Bom diaaa"
    // "Oi chat, tudo bem?"
    //
    // ==========================================================

    if (_isSocial(
      normalized,
    )) {
      return AiRequestDecision.local(
        intent: ChatIntent.social,
        response: localResponseService.socialResponse(
          message: original,
        ),
        reason: 'Interação social simples.',
      );
    }

    // ==========================================================
    // FORA DO ESCOPO
    // ==========================================================

    if (_isClearlyOutOfScope(
      semanticForAnalysis,
    )) {
      return AiRequestDecision.local(
        intent: ChatIntent.outOfScope,
        response: localResponseService.outOfScopeResponse(),
        reason: 'Solicitação claramente fora do escopo musical.',
      );
    }

    // ==========================================================
    // CONTINUAÇÃO AMBÍGUA SEM CONTEXTO
    // ==========================================================

    if (_isContinuation(
      semanticForAnalysis,
    )) {
      return AiRequestDecision.local(
        intent: ChatIntent.incompleteRequest,
        response: localResponseService.genericCreativeResponse(),
        reason: 'Mensagem curta sem contexto criativo ativo.',
      );
    }

    // ==========================================================
    // DESCONHECIDO
    // ==========================================================
    //
    // O Gate continua conservador.
    //
    // Se não conseguimos afirmar com segurança que a mensagem é
    // inútil para o contexto criativo, permitimos IA.
    //
    // ==========================================================

    return AiRequestDecision.ai(
      intent: ChatIntent.unknown,
      reason: 'Mensagem ambígua; Gate conservador permitiu IA.',
    );
  }

  // ============================================================
  // SOCIAL
  // ============================================================

  bool _isSocial(
    String message,
  ) {
    final compact = _normalizeSocialText(
      message,
    );

    // ==========================================================
    // SEGURANÇA
    // ==========================================================
    //
    // Se ainda existir sinal criativo na mensagem completa,
    // não classificamos como social.
    //
    // Normalmente isso já foi resolvido antes no evaluate(), mas
    // mantemos esta proteção dentro do próprio método.
    //
    // ==========================================================

    if (_containsCreativeSignal(
      compact,
    )) {
      return false;
    }

    // ==========================================================
    // FRASES SOCIAIS EXATAS
    // ==========================================================

    const exactSocialMessages = {
      'oi',
      'ola',
      'opa',
      'eai',
      'eae',
      'fala',
      'salve',
      'hey',
      'hello',
      'bom dia',
      'boa tarde',
      'boa noite',
      'tudo bem',
      'tudo bom',
      'como vai',
      'como voce esta',
      'como vc esta',
      'como ce ta',
      'como esta',
      'ta bem',
      'beleza',
      'suave',
      'tranquilo',
      'valeu',
      'vlw',
      'obrigado',
      'obrigada',
      'obg',
      'brigado',
      'brigada',
      'tmj',
      'tchau',
      'falou',
      'flw',
      'ate mais',
      'ate logo',
    };

    if (exactSocialMessages.contains(
      compact,
    )) {
      return true;
    }

    // ==========================================================
    // COMBINAÇÕES SOCIAIS
    // ==========================================================
    //
    // Exemplos:
    //
    // "oi bom dia"
    // "oi tudo bem"
    // "bom dia tudo bem"
    // "oi chat tudo bem"
    //
    // ==========================================================

    final withoutChat = compact
        .replaceAll(
          RegExp(
            r'\bchat\b',
          ),
          ' ',
        )
        .replaceAll(
          RegExp(
            r'\s+',
          ),
          ' ',
        )
        .trim();

    final remaining = _stripLeadingSocialNoise(
      withoutChat,
    );

    if (remaining.isEmpty) {
      return true;
    }

    // ==========================================================
    // FRASES SOCIAIS CURTAS
    // ==========================================================

    if (compact.length <=
        50) {
      const socialFragments = [
        'tudo bem',
        'tudo bom',
        'como vai',
        'como voce esta',
        'como vc esta',
        'como ce ta',
        'beleza',
        'suave',
        'tranquilo',
      ];

      for (final fragment in socialFragments) {
        if (compact.contains(
          fragment,
        )) {
          return true;
        }
      }
    }

    return false;
  }

  // ============================================================
  // CONTINUAÇÃO
  // ============================================================

  bool _isContinuation(
    String message,
  ) {
    final compact = _compact(
      message,
    );

    const exactContinuations = {
      'como assim',
      'por que',
      'porque',
      'por que isso',
      'explica',
      'explica melhor',
      'e agora',
      'e essa',
      'e esse',
      'e essa parte',
      'e esse trecho',
      'melhor assim',
      'assim ficou melhor',
      'o que acha',
      'acha mesmo',
      'tem certeza',
      'e depois',
      'continua',
      'continue',
    };

    if (exactContinuations.contains(
      compact,
    )) {
      return true;
    }

    if (compact.length >
        45) {
      return false;
    }

    const continuationPrefixes = [
      'e se ',
      'mas por que',
      'mas porque',
      'e como ',
      'e nisso',
      'e aqui',
      'nessa parte',
      'nesse trecho',
    ];

    for (final prefix in continuationPrefixes) {
      if (compact.startsWith(
        prefix,
      )) {
        return true;
      }
    }

    return false;
  }

  // ============================================================
  // EXTRAIR BUSCA SIMPLES DE RIMA
  // ============================================================

  String? _extractSimpleRhymeQuery(
    String original,
    String normalized,
  ) {
    final compact = _compact(
      normalized,
    );

    // ==========================================================
    // NÃO INTERCEPTAR ANÁLISES MAIS COMPLEXAS
    // ==========================================================

    if (_containsAny(
      compact,
      const [
        'analisa',
        'analisar',
        'analise',
        'avalia',
        'avaliar',
        'avalie',
        'melhor',
        'encaixa',
        'encaixar',
        'contexto',
        'verso',
        'refrão',
        'refrao',
        'métrica',
        'metrica',
        'flow',
      ],
    )) {
      return null;
    }

    // ==========================================================
    // PADRÕES
    // ==========================================================

    final patterns =
        <
          RegExp
        >[
          RegExp(
            r'^(?:me\s+)?(?:de|dê|da|dá)?\s*rimas?\s+(?:com|para|pra)\s+(.+)$',
            caseSensitive: false,
          ),
          RegExp(
            r'^rimas?\s+(?:com|para|pra)\s+(.+)$',
            caseSensitive: false,
          ),
          RegExp(
            r'^(?:minhas?\s+)?rimas?\s+(?:de|com|para|pra)\s+(.+)$',
            caseSensitive: false,
          ),
          RegExp(
            r'^(?:palavras?\s+que\s+)?rimam?\s+com\s+(.+)$',
            caseSensitive: false,
          ),
          RegExp(
            r'^o\s+que\s+rima\s+com\s+(.+)$',
            caseSensitive: false,
          ),
        ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(
        compact,
      );

      if (match ==
          null) {
        continue;
      }

      final rawQuery = match.group(
        1,
      );

      if (rawQuery ==
          null) {
        continue;
      }

      final query = _cleanRhymeQuery(
        rawQuery,
      );

      if (query.isEmpty) {
        continue;
      }

      // Evita transformar uma frase inteira em termo de busca.
      if (query
              .split(
                ' ',
              )
              .length >
          4) {
        return null;
      }

      return query;
    }

    // ==========================================================
    // "RIMAS"
    // SEM PALAVRA
    // ==========================================================

    if (compact ==
            'rima' ||
        compact ==
            'rimas' ||
        compact ==
            'quero rimas' ||
        compact ==
            'preciso de rimas') {
      return null;
    }

    return null;
  }

  // ============================================================
  // PEDIDO INCOMPLETO
  // ============================================================

  bool _isIncompleteCreativeRequest(
    String normalized,
    String original,
  ) {
    final compact = _compact(
      normalized,
    );

    // ==========================================================
    // PRECISA EXISTIR INTENÇÃO DE ANÁLISE
    // ==========================================================

    final asksForEvaluation = _containsAny(
      compact,
      const [
        'analisa',
        'analise',
        'analisar',
        'avalia',
        'avalie',
        'avaliar',
        'o que acha',
        'oque acha',
        'esta boa',
        'esta bom',
        'ficou boa',
        'ficou bom',
        'como ficou',
        'ta boa',
        'ta bom',
        'melhora',
        'melhorar',
      ],
    );

    if (!asksForEvaluation) {
      return false;
    }

    // ==========================================================
    // PRECISA SER MUSICAL
    // ==========================================================

    if (!_containsCreativeSignal(
      compact,
    )) {
      return false;
    }

    // ==========================================================
    // MATERIAL PRESENTE?
    // ==========================================================

    if (_hasLikelyCreativeMaterial(
      original,
    )) {
      return false;
    }

    return true;
  }

  // ============================================================
  // ANÁLISE DE LETRA
  // ============================================================

  bool _isLyricAnalysis(
    String normalized,
    String original,
  ) {
    final compact = _compact(
      normalized,
    );

    final analysisSignal = _containsAny(
      compact,
      const [
        'analisa',
        'analise',
        'analisar',
        'avalia',
        'avalie',
        'avaliar',
        'o que acha',
        'oque acha',
        'como ficou',
        'ficou bom',
        'ficou boa',
        'esta bom',
        'esta boa',
        'ta bom',
        'ta boa',
        'melhora esse',
        'melhora essa',
      ],
    );

    if (!analysisSignal) {
      return false;
    }

    if (!_containsCreativeSignal(
      compact,
    )) {
      return false;
    }

    return _hasLikelyCreativeMaterial(
      original,
    );
  }

  // ============================================================
  // PEDIDO CRIATIVO
  // ============================================================

  bool _isCreativeRequest(
    String message,
  ) {
    return _containsCreativeSignal(
      message,
    );
  }

  // ============================================================
  // SINAL CRIATIVO
  // ============================================================

  bool _containsCreativeSignal(
    String message,
  ) {
    return _containsAny(
      message,
      const [
        'musica',
        'música',
        'letra',
        'verso',
        'versos',
        'refrão',
        'refrao',
        'hook',
        'barra',
        'barras',
        'rima',
        'rimas',
        'rimando',
        'rimam',
        'métrica',
        'metrica',
        'flow',
        'beat',
        'bpm',
        'melodia',
        'composição',
        'composicao',
        'compor',
        'compondo',
        'estrutura',
        'estrofe',
        'ponte',
        'intro',
        'rap',
        'trap',
        'boom bap',
        'boombap',
        'freestyle',
        'cypher',
        'punchline',
        'punch',
        'cadência',
        'cadencia',
        'encaixe',
        'lirica',
        'lírica',
        'lyric',
        'track',
        'som',
      ],
    );
  }

  // ============================================================
  // MATERIAL CRIATIVO PROVÁVEL
  // ============================================================
  //
  // Não tenta "entender" a letra.
  //
  // Apenas verifica sinais de que existe material suficiente
  // anexado ao pedido.
  //
  // ============================================================

  bool _hasLikelyCreativeMaterial(
    String original,
  ) {
    final trimmed = original.trim();

    // ==========================================================
    // ASPAS
    // ==========================================================

    if ((trimmed.contains(
              '"',
            ) &&
            trimmed
                    .split(
                      '"',
                    )
                    .length >=
                3) ||
        (trimmed.contains(
              '“',
            ) &&
            trimmed.contains(
              '”',
            ))) {
      return true;
    }

    // ==========================================================
    // QUEBRA DE LINHA
    // ==========================================================

    if (trimmed.contains(
      '\n',
    )) {
      final lines = trimmed
          .split(
            '\n',
          )
          .where(
            (
              line,
            ) => line.trim().isNotEmpty,
          )
          .toList();

      if (lines.length >=
          2) {
        return true;
      }
    }

    // ==========================================================
    // ":" SEGUIDO DE MATERIAL
    // ==========================================================

    final colonIndex = trimmed.indexOf(
      ':',
    );

    if (colonIndex >=
            0 &&
        colonIndex <
            trimmed.length -
                1) {
      final afterColon = trimmed
          .substring(
            colonIndex +
                1,
          )
          .trim();

      if (afterColon.length >=
          10) {
        return true;
      }
    }

    // ==========================================================
    // TEXTO LONGO
    // ==========================================================
    //
    // Serve como fallback para:
    //
    // "analisa meu verso eu vim de longe carregando..."
    //
    // mesmo sem aspas ou dois pontos.
    //
    // ==========================================================

    final words = trimmed
        .split(
          RegExp(
            r'\s+',
          ),
        )
        .where(
          (
            word,
          ) => word.isNotEmpty,
        )
        .toList();

    return words.length >=
        14;
  }

  // ============================================================
  // FORA DO ESCOPO
  // ============================================================
  //
  // Esta classificação é propositalmente conservadora.
  //
  // Só bloqueamos categorias muito claras.
  //
  // ============================================================

  bool _isClearlyOutOfScope(
    String message,
  ) {
    // Se existe qualquer sinal musical, não classificamos
    // automaticamente como fora do escopo.
    if (_containsCreativeSignal(
      message,
    )) {
      return false;
    }

    const outOfScopeSignals = [
      // Programação
      'python',
      'javascript',
      'flutter',
      'dart',
      'java ',
      'c++',
      'programar',
      'programação',
      'programacao',
      'codigo',
      'código',
      'linux',
      'windows',
      'api rest',
      'banco de dados',
      'sql',

      // Tecnologia
      'placa de video',
      'placa de vídeo',
      'processador',
      'computador',
      'celular',
      'android',

      // Clima
      'previsao do tempo',
      'previsão do tempo',
      'vai chover',
      'temperatura hoje',

      // Matemática
      'calcule',
      'calcula',
      'equacao',
      'equação',

      // Viagem
      'passagem aérea',
      'passagem aerea',
      'hotel perto',
      'restaurante perto',
    ];

    return _containsAny(
      message,
      outOfScopeSignals,
    );
  }

  // ============================================================
  // LIMPAR CONSULTA DE RIMA
  // ============================================================

  String _cleanRhymeQuery(
    String value,
  ) {
    var result = value.trim();

    result = result.replaceAll(
      RegExp(
        r'[?!.,;:]+$',
      ),
      '',
    );

    result = result.trim();

    return result;
  }

  // ============================================================
  // CONTAINS ANY
  // ============================================================

  bool _containsAny(
    String value,
    Iterable<
      String
    >
    candidates,
  ) {
    for (final candidate in candidates) {
      if (value.contains(
        candidate,
      )) {
        return true;
      }
    }

    return false;
  }

  // ============================================================
  // REMOVER ABERTURA SOCIAL
  // ============================================================
  //
  // Remove somente expressões sociais no INÍCIO da mensagem.
  //
  // Isso permite interpretar corretamente:
  //
  // "Oi, bom dia, tudo bem? Analisa esse verso..."
  //
  // sem destruir o restante do conteúdo.
  //
  // ============================================================

  String _stripLeadingSocialNoise(
    String value,
  ) {
    var result = _normalizeSocialText(
      value,
    );

    const socialOpenings = [
      'bom dia',
      'boa tarde',
      'boa noite',
      'tudo bem',
      'tudo bom',
      'como vai',
      'como voce esta',
      'como vc esta',
      'como ce ta',
      'como esta',
      'oi',
      'ola',
      'opa',
      'eai',
      'eae',
      'fala',
      'salve',
      'hey',
      'hello',
      'beleza',
      'suave',
      'tranquilo',
    ];

    var changed = true;

    while (changed &&
        result.isNotEmpty) {
      changed = false;

      // "chat" isolado logo após uma saudação também é ruído
      // conversacional.
      if (result ==
          'chat') {
        return '';
      }

      if (result.startsWith(
        'chat ',
      )) {
        result = result
            .substring(
              5,
            )
            .trim();

        changed = true;

        continue;
      }

      for (final opening in socialOpenings) {
        if (result ==
            opening) {
          return '';
        }

        if (result.startsWith(
          '$opening ',
        )) {
          result = result
              .substring(
                opening.length,
              )
              .trim();

          changed = true;

          break;
        }
      }
    }

    return result;
  }

  // ============================================================
  // NORMALIZAÇÃO SOCIAL
  // ============================================================
  //
  // Usada SOMENTE para reconhecer linguagem social.
  //
  // Exemplos:
  //
  // Oiiii       -> oi
  // Olááá       -> ola
  // Bom diaaa   -> bom dia
  // Valeeeu     -> valeu
  // Oi!!! 👋    -> oi
  //
  // Não usamos esta normalização para analisar letras.
  //
  // ============================================================

  String _normalizeSocialText(
    String value,
  ) {
    var result = _compact(
      value,
    );

    // Remove símbolos/emojis que não ajudam na classificação
    // social. Mantém letras, números e espaços.
    result = result.replaceAll(
      RegExp(
        r'[^a-z0-9\s]',
      ),
      ' ',
    );

    // ==========================================================
    // REDUZ REPETIÇÕES DE LETRAS
    // ==========================================================
    //
    // "oiiiii" -> "oi"
    // "olaaaa" -> "ola"
    //
    // O padrão é usado apenas no detector social para não alterar
    // estilizações legítimas dentro de letras.
    //
    // ==========================================================

    result = result.replaceAllMapped(
      RegExp(
        r'([a-z])\1+',
      ),
      (
        match,
      ) {
        return match.group(
          1,
        )!;
      },
    );

    result = result.replaceAll(
      RegExp(
        r'\s+',
      ),
      ' ',
    );

    return result.trim();
  }

  // ============================================================
  // NORMALIZAR
  // ============================================================

  String _normalize(
    String value,
  ) {
    return value.trim().toLowerCase();
  }

  // ============================================================
  // COMPACTAR
  // ============================================================
  //
  // Remove pontuação simples e espaços duplicados para facilitar
  // comparações locais.
  //
  // ============================================================

  String _compact(
    String value,
  ) {
    var result = _removeAccents(
      value.trim().toLowerCase(),
    );

    result = result.replaceAll(
      RegExp(
        r'[!?.,;:]+',
      ),
      ' ',
    );

    result = result.replaceAll(
      RegExp(
        r'\s+',
      ),
      ' ',
    );

    return result.trim();
  }

  // ============================================================
  // REMOVER ACENTOS
  // ============================================================

  String _removeAccents(
    String value,
  ) {
    const source = 'áàãâäéèêëíìîïóòõôöúùûüç';

    const target = 'aaaaaeeeeiiiiooooouuuuc';

    var result = value;

    for (
      var index = 0;
      index <
          source.length;
      index++
    ) {
      result = result.replaceAll(
        source[index],
        target[index],
      );
    }

    return result;
  }
}
