// ============================================================
// COMMUNICATION REQUEST TYPE
// ============================================================
//
// Define QUAL consentimento está sendo solicitado.
//
// Atualmente:
//
// videoUnlock
//
// → libera o recurso de vídeo entre os participantes.
//
// videoUpgrade
//
// → dentro de uma chamada de áudio, solicita ativação de
//   vídeo naquele momento.
//
// IMPORTANTE:
//
// videoUnlock:
//
// "Podemos utilizar vídeo entre nós?"
//
// videoUpgrade:
//
// "Quer ativar vídeo nesta chamada agora?"
//
// São consentimentos diferentes.
//
// ============================================================

enum CommunicationRequestType {
  videoUnlock,
  videoUpgrade;

  // ==========================================================
  // DATABASE VALUE
  // ==========================================================

  String get value {
    switch (this) {
      case CommunicationRequestType.videoUnlock:
        return 'video_unlock';

      case CommunicationRequestType.videoUpgrade:
        return 'video_upgrade';
    }
  }

  // ==========================================================
  // LABEL
  // ==========================================================

  String get label {
    switch (this) {
      case CommunicationRequestType.videoUnlock:
        return 'Liberar vídeo';

      case CommunicationRequestType.videoUpgrade:
        return 'Ativar vídeo';
    }
  }

  // ==========================================================
  // TITLE
  // ==========================================================

  String get title {
    switch (this) {
      case CommunicationRequestType.videoUnlock:
        return 'Convite para vídeo';

      case CommunicationRequestType.videoUpgrade:
        return 'Ativar vídeo na chamada';
    }
  }

  // ==========================================================
  // DESCRIPTION
  // ==========================================================

  String get description {
    switch (this) {
      case CommunicationRequestType.videoUnlock:
        return 'Solicita permissão para liberar chamadas '
            'de vídeo nesta conexão.';

      case CommunicationRequestType.videoUpgrade:
        return 'Solicita a mudança da chamada atual '
            'de áudio para vídeo.';
    }
  }

  // ==========================================================
  // HELPERS
  // ==========================================================

  bool get isVideoUnlock =>
      this ==
      CommunicationRequestType.videoUnlock;

  bool get isVideoUpgrade =>
      this ==
      CommunicationRequestType.videoUpgrade;

  // ==========================================================
  // PRECISA DE CALL ID?
  // ==========================================================
  //
  // video_unlock:
  // não depende de uma chamada ativa.
  //
  // video_upgrade:
  // necessariamente pertence a uma chamada.
  //
  // ==========================================================

  bool get requiresCall {
    switch (this) {
      case CommunicationRequestType.videoUnlock:
        return false;

      case CommunicationRequestType.videoUpgrade:
        return true;
    }
  }

  // ==========================================================
  // PERMANENTE?
  // ==========================================================
  //
  // O desbloqueio altera a permissão da conexão.
  //
  // Upgrade apenas muda a mídia da chamada atual.
  //
  // ==========================================================

  bool get changesPersistentPermission {
    switch (this) {
      case CommunicationRequestType.videoUnlock:
        return true;

      case CommunicationRequestType.videoUpgrade:
        return false;
    }
  }

  // ==========================================================
  // FROM STRING
  // ==========================================================

  static CommunicationRequestType fromString(
    String? value,
  ) {
    final normalized = value?.trim().toLowerCase();

    switch (normalized) {
      case 'video_unlock':
        return CommunicationRequestType.videoUnlock;

      case 'video_upgrade':
        return CommunicationRequestType.videoUpgrade;

      default:
        throw ArgumentError(
          'CommunicationRequestType inválido: $value',
        );
    }
  }

  // ==========================================================
  // TRY FROM STRING
  // ==========================================================

  static CommunicationRequestType? tryFromString(
    String? value,
  ) {
    try {
      return fromString(
        value,
      );
    } catch (
      _
    ) {
      return null;
    }
  }

  // ==========================================================
  // DATABASE
  // ==========================================================

  static String toDatabase(
    CommunicationRequestType value,
  ) {
    return value.value;
  }
}
