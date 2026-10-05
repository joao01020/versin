// ============================================================
// CALL MEDIA TYPE
// ============================================================
//
// Define como uma chamada foi iniciada.
//
// IMPORTANTE:
//
// Esse tipo NÃO obriga todos os participantes a utilizarem
// a mesma mídia.
//
// Exemplo:
//
// CallMediaType.video
//
// Participante A:
// áudio + vídeo
//
// Participante B:
// somente áudio
//
// ============================================================

enum CallMediaType {
  audio,
  video;

  // ==========================================================
  // DATABASE VALUE
  // ==========================================================

  String get value {
    switch (this) {
      case CallMediaType.audio:
        return 'audio';

      case CallMediaType.video:
        return 'video';
    }
  }

  // ==========================================================
  // LABEL
  // ==========================================================

  String get label {
    switch (this) {
      case CallMediaType.audio:
        return 'Áudio';

      case CallMediaType.video:
        return 'Vídeo';
    }
  }

  // ==========================================================
  // ICON SEMANTIC NAME
  // ==========================================================
  //
  // Mantemos apenas uma identificação textual aqui.
  //
  // O model/type não deve depender do Flutter/Material.
  //
  // A UI escolhe o IconData correspondente.
  //
  // ==========================================================

  String get iconName {
    switch (this) {
      case CallMediaType.audio:
        return 'call';

      case CallMediaType.video:
        return 'videocam';
    }
  }

  // ==========================================================
  // HELPERS
  // ==========================================================

  bool get isAudio =>
      this ==
      CallMediaType.audio;

  bool get isVideo =>
      this ==
      CallMediaType.video;

  bool get startsWithCamera => isVideo;

  // ==========================================================
  // FROM STRING
  // ==========================================================

  static CallMediaType fromString(
    String? value,
  ) {
    final normalized = value?.trim().toLowerCase();

    switch (normalized) {
      case 'audio':
        return CallMediaType.audio;

      case 'video':
        return CallMediaType.video;

      default:
        throw ArgumentError(
          'CallMediaType inválido: $value',
        );
    }
  }

  // ==========================================================
  // FROM STRING OR NULL
  // ==========================================================

  static CallMediaType? tryFromString(
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
    CallMediaType value,
  ) {
    return value.value;
  }
}
