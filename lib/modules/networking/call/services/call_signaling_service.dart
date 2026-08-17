// ============================================================
// CALL CHANNEL NAME
// ============================================================
//
// Utilitário responsável por gerar nomes padronizados
// para canais utilizados pela funcionalidade de chamadas.
//
// Objetivos:
//
// - manter nomes consistentes;
// - evitar concatenação manual espalhada pelo projeto;
// - separar canais por finalidade;
// - normalizar IDs;
// - facilitar debugging;
// - evitar caracteres problemáticos.
//
// Exemplos:
//
// versin:call:project:<projectId>
//
// versin:call:room:<callId>
//
// versin:call:signaling:<callId>
//
// versin:call:presence:<callId>
//
// versin:call:user:<userId>
//
// ============================================================

class CallChannelName {
  // ==========================================================
  // PREFIX
  // ==========================================================

  static const String _root = 'versin';

  static const String _module = 'call';

  // ==========================================================
  // PRIVATE CONSTRUCTOR
  // ==========================================================

  CallChannelName._();

  // ==========================================================
  // PROJECT
  // ==========================================================
  //
  // Canal geral relacionado às chamadas de um projeto.
  //
  // Uso:
  //
  // - criação de chamada;
  // - término de chamada;
  // - alterações globais do projeto;
  // - descoberta de chamada ativa.
  //
  // Resultado:
  //
  // versin:call:project:<projectId>
  //
  // ==========================================================

  static String project(
    String projectId,
  ) {
    return _build(
      type: 'project',
      id: _requiredId(
        projectId,
        'projectId',
      ),
    );
  }

  // ==========================================================
  // CALL ROOM
  // ==========================================================
  //
  // Canal principal de uma chamada específica.
  //
  // Pode ser usado para eventos de alto nível da sala.
  //
  // Resultado:
  //
  // versin:call:room:<callId>
  //
  // ==========================================================

  static String room(
    String callId,
  ) {
    return _build(
      type: 'room',
      id: _requiredId(
        callId,
        'callId',
      ),
    );
  }

  // ==========================================================
  // SIGNALING
  // ==========================================================
  //
  // Canal utilizado pelo signaling WebRTC.
  //
  // Eventos futuros:
  //
  // - offer;
  // - answer;
  // - ICE candidate;
  // - renegotiation;
  // - hangup;
  // - media upgrade.
  //
  // Resultado:
  //
  // versin:call:signaling:<callId>
  //
  // ==========================================================

  static String signaling(
    String callId,
  ) {
    return _build(
      type: 'signaling',
      id: _requiredId(
        callId,
        'callId',
      ),
    );
  }

  // ==========================================================
  // PRESENCE
  // ==========================================================
  //
  // Canal de presença dos participantes.
  //
  // Pode representar:
  //
  // - conectado;
  // - entrou;
  // - saiu;
  // - microfone;
  // - câmera;
  // - speaking;
  //
  // Resultado:
  //
  // versin:call:presence:<callId>
  //
  // ==========================================================

  static String presence(
    String callId,
  ) {
    return _build(
      type: 'presence',
      id: _requiredId(
        callId,
        'callId',
      ),
    );
  }

  // ==========================================================
  // MEDIA STATE
  // ==========================================================
  //
  // Canal dedicado ao estado de mídia da chamada.
  //
  // Útil caso futuramente seja interessante separar
  // presença de atualizações de mídia.
  //
  // Exemplos:
  //
  // microphone_enabled
  // camera_enabled
  // audio_connected
  // video_connected
  //
  // Resultado:
  //
  // versin:call:media:<callId>
  //
  // ==========================================================

  static String media(
    String callId,
  ) {
    return _build(
      type: 'media',
      id: _requiredId(
        callId,
        'callId',
      ),
    );
  }

  // ==========================================================
  // COMMUNICATION REQUESTS
  // ==========================================================
  //
  // Canal para pedidos relacionados a consentimento.
  //
  // Exemplos:
  //
  // video_unlock
  // video_upgrade
  //
  // Resultado:
  //
  // versin:call:requests:<projectId>
  //
  // ==========================================================

  static String requests(
    String projectId,
  ) {
    return _build(
      type: 'requests',
      id: _requiredId(
        projectId,
        'projectId',
      ),
    );
  }

  // ==========================================================
  // USER
  // ==========================================================
  //
  // Canal pessoal de chamadas de um usuário.
  //
  // Pode ser usado futuramente para:
  //
  // - chamada recebida;
  // - convite;
  // - cancelamento;
  // - chamada perdida;
  //
  // Resultado:
  //
  // versin:call:user:<userId>
  //
  // ==========================================================

  static String user(
    String userId,
  ) {
    return _build(
      type: 'user',
      id: _requiredId(
        userId,
        'userId',
      ),
    );
  }

  // ==========================================================
  // DIRECT PEER
  // ==========================================================
  //
  // Nome determinístico para comunicação entre dois usuários
  // dentro da mesma chamada.
  //
  // IMPORTANTE:
  //
  // A ordem dos IDs não altera o resultado.
  //
  // Exemplo:
  //
  // peer(call, A, B)
  //
  // produz o mesmo canal que:
  //
  // peer(call, B, A)
  //
  // Isso evita criar dois canais diferentes para o mesmo par.
  //
  // Resultado:
  //
  // versin:call:peer:<callId>:<userA>:<userB>
  //
  // ==========================================================

  static String peer({
    required String callId,
    required String userA,
    required String userB,
  }) {
    final normalizedCallId = _requiredId(
      callId,
      'callId',
    );

    final normalizedUserA = _requiredId(
      userA,
      'userA',
    );

    final normalizedUserB = _requiredId(
      userB,
      'userB',
    );

    if (normalizedUserA ==
        normalizedUserB) {
      throw ArgumentError(
        'userA e userB não podem representar o mesmo usuário.',
      );
    }

    final users = [
      normalizedUserA,
      normalizedUserB,
    ]..sort();

    return [
      _root,
      _module,
      'peer',
      normalizedCallId,
      users[0],
      users[1],
    ].join(
      ':',
    );
  }

  // ==========================================================
  // PARTICIPANT
  // ==========================================================
  //
  // Canal específico de um participante dentro de uma chamada.
  //
  // Pode ser útil futuramente para comunicação direta
  // servidor/cliente ou eventos individuais.
  //
  // Resultado:
  //
  // versin:call:participant:<callId>:<userId>
  //
  // ==========================================================

  static String participant({
    required String callId,
    required String userId,
  }) {
    final normalizedCallId = _requiredId(
      callId,
      'callId',
    );

    final normalizedUserId = _requiredId(
      userId,
      'userId',
    );

    return [
      _root,
      _module,
      'participant',
      normalizedCallId,
      normalizedUserId,
    ].join(
      ':',
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  static String _build({
    required String type,
    required String id,
  }) {
    return [
      _root,
      _module,
      type,
      id,
    ].join(
      ':',
    );
  }

  // ==========================================================
  // REQUIRED ID
  // ==========================================================

  static String _requiredId(
    String value,
    String field,
  ) {
    final normalized = _normalizeId(
      value,
    );

    if (normalized.isEmpty) {
      throw ArgumentError(
        '$field não pode ser vazio.',
      );
    }

    return normalized;
  }

  // ==========================================================
  // NORMALIZE ID
  // ==========================================================
  //
  // IDs UUID do Supabase já são compatíveis.
  //
  // Mesmo assim fazemos uma normalização defensiva:
  //
  // - trim;
  // - lowercase;
  // - espaços → hífen;
  // - caracteres fora do conjunto seguro → hífen;
  // - múltiplos hífens → um;
  //
  // ==========================================================

  static String _normalizeId(
    String value,
  ) {
    var normalized = value.trim().toLowerCase();

    if (normalized.isEmpty) {
      return '';
    }

    normalized = normalized.replaceAll(
      RegExp(
        r'\s+',
      ),
      '-',
    );

    normalized = normalized.replaceAll(
      RegExp(
        r'[^a-z0-9_-]',
      ),
      '-',
    );

    normalized = normalized.replaceAll(
      RegExp(
        r'-+',
      ),
      '-',
    );

    normalized = normalized.replaceAll(
      RegExp(
        r'^-+|-+$',
      ),
      '',
    );

    return normalized;
  }

  // ==========================================================
  // DEBUG LABEL
  // ==========================================================
  //
  // Retorna uma versão menor de um ID para logs/UI.
  //
  // NÃO deve ser usada como identificador real de canal.
  //
  // ==========================================================

  static String shortId(
    String value, {
    int length = 8,
  }) {
    if (length <=
        0) {
      throw ArgumentError(
        'length deve ser maior que zero.',
      );
    }

    final normalized = value.trim();

    if (normalized.isEmpty) {
      return '';
    }

    if (normalized.length <=
        length) {
      return normalized;
    }

    return normalized.substring(
      0,
      length,
    );
  }
}
