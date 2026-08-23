import 'dart:math';

import '../models/chat_intent.dart';

// ============================================================
// CHAT LOCAL RESPONSE SERVICE
// ============================================================
//
// Responsável por gerar respostas que NÃO precisam utilizar IA.
//
// OBJETIVO:
//
// Evitar chamadas desnecessárias para:
//
// - saudações;
// - agradecimentos;
// - despedidas;
// - conversa social simples;
// - solicitações musicais incompletas;
// - solicitações claramente fora do escopo.
//
// IMPORTANTE:
//
// Este serviço:
//
// - não chama Groq;
// - não chama API privada;
// - não consome tokens;
// - não altera quota;
// - não acessa Supabase.
//
// As respostas possuem pequenas variações para evitar que o chat
// pareça excessivamente robótico.
//
// ============================================================

class ChatLocalResponseService {
  // ============================================================
  // RANDOM
  // ============================================================

  final Random _random;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  ChatLocalResponseService({
    Random? random,
  }) : _random =
           random ??
           Random();

  // ============================================================
  // RESPOSTA POR INTENÇÃO
  // ============================================================

  String responseFor({
    required ChatIntent intent,
    String? message,
  }) {
    switch (intent) {
      case ChatIntent.social:
        return socialResponse(
          message: message,
        );

      case ChatIntent.incompleteRequest:
        return incompleteRequestResponse(
          message: message,
        );

      case ChatIntent.outOfScope:
        return outOfScopeResponse();

      case ChatIntent.rhymeSearch:
        return rhymeSearchFallback();

      case ChatIntent.lyricAnalysis:
      case ChatIntent.creativeRequest:
      case ChatIntent.continuation:
      case ChatIntent.unknown:
        return genericCreativeResponse();
    }
  }

  // ============================================================
  // SOCIAL
  // ============================================================

  String socialResponse({
    String? message,
  }) {
    final normalized = _normalize(
      message ??
          '',
    );

    // ==========================================================
    // AGRADECIMENTO
    // ==========================================================

    if (_containsAny(
      normalized,
      const [
        'obrigado',
        'obrigada',
        'obg',
        'vlw',
        'valeu',
        'brigado',
        'brigada',
        'tmj',
      ],
    )) {
      return _pick(
        const [
          'Tamo junto. Quando quiser, manda a próxima ideia.',
          'Valeu. Quando quiser continuar, manda o que você está criando.',
          'Fechado. Se quiser trabalhar outra parte da música, manda aí.',
        ],
      );
    }

    // ==========================================================
    // DESPEDIDA
    // ==========================================================

    if (_containsAny(
      normalized,
      const [
        'tchau',
        'ate mais',
        'falou',
        'flw',
        'ate logo',
      ],
    )) {
      return _pick(
        const [
          'Falou. Quando quiser continuar a música, tô por aqui.',
          'Até mais. Depois a gente continua de onde parou.',
          'Fechado. Quando voltar, manda a próxima ideia.',
        ],
      );
    }

    // ==========================================================
    // BOM DIA
    // ==========================================================

    if (normalized.contains(
      'bom dia',
    )) {
      return _pick(
        const [
          'Bom dia! O que você quer trabalhar na música hoje?',
          'Bom dia! Manda o que você está criando.',
          'Bom dia! Qual parte da música você quer trabalhar?',
        ],
      );
    }

    // ==========================================================
    // BOA TARDE
    // ==========================================================

    if (normalized.contains(
      'boa tarde',
    )) {
      return _pick(
        const [
          'Boa tarde! O que estamos criando hoje?',
          'Boa tarde! Manda a ideia que você quer trabalhar.',
          'Boa tarde! Em que parte da música você está?',
        ],
      );
    }

    // ==========================================================
    // BOA NOITE
    // ==========================================================

    if (normalized.contains(
      'boa noite',
    )) {
      return _pick(
        const [
          'Boa noite! O que você quer trabalhar na música?',
          'Boa noite! Manda a ideia que está na cabeça.',
          'Boa noite! Em que parte da música você está agora?',
        ],
      );
    }

    // ==========================================================
    // TUDO BEM
    // ==========================================================

    if (_containsAny(
      normalized,
      const [
        'tudo bem',
        'como vai',
        'como voce esta',
        'como esta',
        'ta bem',
      ],
    )) {
      return _pick(
        const [
          'Tudo certo. E a música, em que parte você está?',
          'Tudo certo por aqui. O que você quer trabalhar?',
          'Tudo bem. Manda o que você está criando.',
        ],
      );
    }

    // ==========================================================
    // SAUDAÇÃO GENÉRICA
    // ==========================================================

    return _pick(
      const [
        'E aí. O que estamos criando hoje?',
        'Fala. Em que parte da música você está?',
        'Tô por aqui. O que você quer trabalhar?',
        'Manda aí. O que você está criando?',
      ],
    );
  }

  // ============================================================
  // PEDIDO MUSICAL INCOMPLETO
  // ============================================================

  String incompleteRequestResponse({
    String? message,
  }) {
    final normalized = _normalize(
      message ??
          '',
    );

    // ==========================================================
    // REFRÃO
    // ==========================================================

    if (_containsAny(
      normalized,
      const [
        'refrao',
        'refrão',
        'hook',
      ],
    )) {
      return _pick(
        const [
          'Manda o refrão. Posso olhar impacto, métrica, rimas e encaixe.',
          'Me mostra o refrão. Aí consigo analisar o que está funcionando e o que pode melhorar.',
          'Manda esse refrão. Posso olhar tudo junto ou focar no que está te incomodando.',
        ],
      );
    }

    // ==========================================================
    // VERSO
    // ==========================================================

    if (_containsAny(
      normalized,
      const [
        'verso',
        'barra',
        'linha',
      ],
    )) {
      return _pick(
        const [
          'Manda o verso. Aí consigo analisar métrica, rima, clareza e impacto.',
          'Me mostra esse verso. Aí consigo avaliar de verdade.',
          'Manda a barra que você quer analisar e eu olho o encaixe dela.',
        ],
      );
    }

    // ==========================================================
    // LETRA / MÚSICA
    // ==========================================================

    if (_containsAny(
      normalized,
      const [
        'letra',
        'musica',
        'música',
        'som',
        'track',
      ],
    )) {
      return _pick(
        const [
          'Manda o trecho que você quer analisar. Posso olhar letra, métrica, rimas e impacto.',
          'Me mostra a parte da música que está te deixando em dúvida.',
          'Manda o trecho. Aí consigo olhar o que está funcionando e onde dá para melhorar.',
        ],
      );
    }

    // ==========================================================
    // MÉTRICA
    // ==========================================================

    if (_containsAny(
      normalized,
      const [
        'metrica',
        'métrica',
        'flow',
        'encaixe',
      ],
    )) {
      return _pick(
        const [
          'Manda o trecho que você quer testar. Aí consigo olhar métrica e encaixe.',
          'Me mostra as linhas. Sem o trecho eu não consigo avaliar a métrica direito.',
          'Manda o trecho e eu olho o encaixe com você.',
        ],
      );
    }

    // ==========================================================
    // GENÉRICO
    // ==========================================================

    return _pick(
      const [
        'Manda o trecho ou a ideia que você quer trabalhar. Aí consigo analisar de verdade.',
        'Me dá um pouco mais de material. Pode ser um verso, refrão, ideia ou palavra.',
        'Manda o que você já tem. A partir disso consigo trabalhar com você.',
      ],
    );
  }

  // ============================================================
  // FORA DO ESCOPO
  // ============================================================

  String outOfScopeResponse() {
    return ('Posso te ajudar com composição, rimas, '
        'letras, métrica, estrutura e desenvolvimento '
        'criativo da música.');
  }

  // ============================================================
  // FALLBACK DA BIBLIOTECA
  // ============================================================
  //
  // Usado futuramente quando uma busca na biblioteca não puder
  // ser realizada ou não possuir termo válido.
  //
  // ============================================================

  String rhymeSearchFallback() {
    return _pick(
      const [
        'Me diz a palavra que você quer usar como base para as rimas.',
        'Qual palavra você quer buscar na sua biblioteca de rimas?',
        'Manda a palavra principal e eu procuro as rimas para você.',
      ],
    );
  }

  // ============================================================
  // RESPOSTA CRIATIVA GENÉRICA
  // ============================================================
  //
  // Normalmente não deve ser utilizada quando a intenção exige
  // IA. Existe apenas como fallback seguro.
  //
  // ============================================================

  String genericCreativeResponse() {
    return _pick(
      const [
        'Manda a ideia ou o trecho que você quer trabalhar.',
        'Me mostra o material e a gente trabalha em cima dele.',
        'Manda o que você está criando e me diz onde quer chegar.',
      ],
    );
  }

  // ============================================================
  // ESCOLHER VARIAÇÃO
  // ============================================================

  String _pick(
    List<
      String
    >
    values,
  ) {
    if (values.isEmpty) {
      return '';
    }

    if (values.length ==
        1) {
      return values.first;
    }

    return values[_random.nextInt(
      values.length,
    )];
  }

  // ============================================================
  // CONTAINS ANY
  // ============================================================

  bool _containsAny(
    String value,
    List<
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
  // NORMALIZAÇÃO
  // ============================================================

  String _normalize(
    String value,
  ) {
    return value.trim().toLowerCase();
  }
}
