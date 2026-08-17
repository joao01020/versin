// ============================================================
// CALL CHANNEL NAME
// ============================================================
//
// Utilitário responsável por gerar nomes padronizados
// para os canais Realtime usados pelo módulo de chamadas.
//
// Objetivos:
//
// - manter nomes consistentes;
// - evitar concatenação manual espalhada pelo projeto;
// - separar canais por responsabilidade;
// - gerar nomes determinísticos;
// - facilitar logs e debugging.
//
// Exemplos:
//
// versin:call:project:<projectId>
// versin:call:room:<callId>
// versin:call:signaling:<callId>
// versin:call:presence:<callId>
// versin:call:media:<callId>
// versin:call:user:<userId>
//
// ============================================================

class CallChannelName {
  // ==========================================================
  // ROOT
  // ==========================================================

  static const String _root = 'versin';

  // ==========================================================
  // MODULE
  // ==========================================================

  static const String _module = 'call';

  // ==========================================================
  // PRIVATE CONSTRUCTOR
  // ==========================================================

  CallChannelName._();

  // ==========================================================
  // PROJECT
  // ==========================================================
  //
  // Canal geral das chamadas de um projeto.
  //
  // Pode ser usado para:
  //
  // - detectar criação de chamada;
  // - detectar encerramento;
  // - sincronizar estado geral;
  // - avisar membros do projeto.
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
  // ROOM
  // ==========================================================
  //
  // Canal principal de uma chamada específica.
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
  // Eventos:
  //
  // - offer;
  // - answer;
  // - ICE candidate;
  // - renegotiation;
  // - hangup;
  // - media state.
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
  // Canal destinado à presença dos participantes.
  //
  // Exemplos:
  //
  // - entrou;
  // - saiu;
  // - online;
  // - reconnect;
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
  // MEDIA
  // ==========================================================
  //
  // Canal opcional para sincronização de estado de mídia.
  //
  // Exemplos:
  //
  // microphone_enabled
  // camera_enabled
  // audio_connected
  // video_connected
  // speaking
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
  // REQUESTS
  // ==========================================================
  //
  // Canal relacionado aos pedidos de consentimento.
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
  // Pode receber:
  //
  // - chamada recebida;
  // - convite;
  // - cancelamento;
  // - chamada perdida.
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
  // PARTICIPANT
  // ==========================================================
  //
  // Canal específico de um participante dentro da chamada.
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
  // PEER
  // ==========================================================
  //
  // Canal determinístico entre dois participantes.
  //
  // IMPORTANTE:
  //
  // A ordem dos usuários não altera o resultado.
  //
  // peer(
  //   userA: A,
  //   userB: B,
  // )
  //
  // produz o mesmo resultado que:
  //
  // peer(
  //   userA: B,
  //   userB: A,
  // )
  //
  // Isso é útil para signaling P2P.
  //
  // Resultado:
  //
  // versin:call:peer:<callId>:<user1>:<user2>
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
        'userA e userB não podem ser o mesmo usuário.',
      );
    }

    final users =
        <
            String
          >[
            normalizedUserA,
            normalizedUserB,
          ]
          ..sort();

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
  // SIGNALING PEER
  // ==========================================================
  //
  // Variante específica para signaling entre dois peers.
  //
  // Resultado:
  //
  // versin:call:signaling-peer:<callId>:<user1>:<user2>
  //
  // ==========================================================

  static String signalingPeer({
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
        'userA e userB não podem ser o mesmo usuário.',
      );
    }

    final users =
        <
            String
          >[
            normalizedUserA,
            normalizedUserB,
          ]
          ..sort();

    return [
      _root,
      _module,
      'signaling-peer',
      normalizedCallId,
      users[0],
      users[1],
    ].join(
      ':',
    );
  }

  // ==========================================================
  // PROJECT USER
  // ==========================================================
  //
  // Canal de um usuário dentro de um projeto.
  //
  // Pode ser útil antes de uma chamada existir.
  //
  // Resultado:
  //
  // versin:call:project-user:<projectId>:<userId>
  //
  // ==========================================================

  static String projectUser({
    required String projectId,
    required String userId,
  }) {
    final normalizedProjectId = _requiredId(
      projectId,
      'projectId',
    );

    final normalizedUserId = _requiredId(
      userId,
      'userId',
    );

    return [
      _root,
      _module,
      'project-user',
      normalizedProjectId,
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
    final normalizedType = _requiredSegment(
      type,
      'type',
    );

    return [
      _root,
      _module,
      normalizedType,
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
    final normalized = _normalizeSegment(
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
  // REQUIRED SEGMENT
  // ==========================================================

  static String _requiredSegment(
    String value,
    String field,
  ) {
    final normalized = _normalizeSegment(
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
  // NORMALIZE SEGMENT
  // ==========================================================
  //
  // UUIDs do Supabase já funcionam sem alteração.
  //
  // Ainda assim normalizamos defensivamente:
  //
  // - trim;
  // - lowercase;
  // - espaço → hífen;
  // - caracteres especiais → hífen;
  // - hífens repetidos → um;
  // - remove hífen do começo/fim.
  //
  // ==========================================================

  static String _normalizeSegment(
    String value,
  ) {
    var normalized = value.trim().toLowerCase();

    if (normalized.isEmpty) {
      return '';
    }

    // ========================================================
    // WHITESPACE
    // ========================================================

    normalized = normalized.replaceAll(
      RegExp(
        r'\s+',
      ),
      '-',
    );

    // ========================================================
    // UNSAFE CHARACTERS
    // ========================================================

    normalized = normalized.replaceAll(
      RegExp(
        r'[^a-z0-9_-]',
      ),
      '-',
    );

    // ========================================================
    // MULTIPLE HYPHENS
    // ========================================================

    normalized = normalized.replaceAll(
      RegExp(
        r'-+',
      ),
      '-',
    );

    // ========================================================
    // START / END HYPHENS
    // ========================================================

    normalized = normalized.replaceAll(
      RegExp(
        r'^-+|-+$',
      ),
      '',
    );

    return normalized;
  }

  // ==========================================================
  // SHORT ID
  // ==========================================================
  //
  // Gera uma versão curta para:
  //
  // - logs;
  // - debug;
  // - UI.
  //
  // NÃO deve ser usada como identificador único real.
  //
  // ==========================================================

  static String shortId(
    String value, {
    int length = 8,
  }) {
    if (length <=
        0) {
      throw ArgumentError(
        'length precisa ser maior que zero.',
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

  // ==========================================================
  // IS VALID CHANNEL
  // ==========================================================
  //
  // Validação simples para debug e testes.
  //
  // ==========================================================

  static bool isValid(
    String value,
  ) {
    final normalized = value.trim();

    if (normalized.isEmpty) {
      return false;
    }

    if (!normalized.startsWith(
      '$_root:$_module:',
    )) {
      return false;
    }

    return true;
  }

  // ==========================================================
  // MODULE PREFIX
  // ==========================================================

  static String get prefix => '$_root:$_module';
}
