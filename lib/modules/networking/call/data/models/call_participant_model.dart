// ============================================================
// CALL PARTICIPANT MODEL
// ============================================================
//
// Representa um participante dentro de uma chamada.
//
// IMPORTANTE:
//
// Permissão:
// → define o que o usuário PODE fazer.
//
// Participante:
// → define o que o usuário ESTÁ fazendo agora.
//
// Exemplo:
//
// videoAllowed = true
// cameraEnabled = false
//
// Significa:
// o usuário possui permissão para vídeo,
// mas decidiu manter a câmera desligada.
//
// ============================================================

class CallParticipantModel {
  // ==========================================================
  // IDENTIDADE
  // ==========================================================

  final String userId;

  final String? name;

  final String? username;

  final String? avatarUrl;

  // ==========================================================
  // ESTADO DE CONEXÃO
  // ==========================================================

  final bool connected;

  final DateTime? joinedAt;

  final DateTime? leftAt;

  // ==========================================================
  // ÁUDIO
  // ==========================================================

  final bool microphoneEnabled;

  final bool audioConnected;

  // ==========================================================
  // VÍDEO
  // ==========================================================

  final bool cameraEnabled;

  final bool videoConnected;

  // ==========================================================
  // CONTROLE
  // ==========================================================

  final bool isSpeaking;

  final bool isLocalUser;

  // ==========================================================
  // CONSTRUCTOR
  // ==========================================================

  const CallParticipantModel({
    required this.userId,
    this.name,
    this.username,
    this.avatarUrl,
    this.connected = false,
    this.joinedAt,
    this.leftAt,
    this.microphoneEnabled = true,
    this.audioConnected = false,
    this.cameraEnabled = false,
    this.videoConnected = false,
    this.isSpeaking = false,
    this.isLocalUser = false,
  });

  // ==========================================================
  // FACTORY FROM MAP
  // ==========================================================

  factory CallParticipantModel.fromMap(
    Map<
      String,
      dynamic
    >
    map,
  ) {
    return CallParticipantModel(
      userId: _readString(
        map['user_id'] ??
            map['id'],
      ),
      name: _readNullableString(
        map['name'] ??
            map['display_name'],
      ),
      username: _readNullableString(
        map['username'],
      ),
      avatarUrl: _readNullableString(
        map['avatar_url'],
      ),
      connected: _readBool(
        map['connected'],
      ),
      joinedAt: _readDateTime(
        map['joined_at'],
      ),
      leftAt: _readDateTime(
        map['left_at'],
      ),
      microphoneEnabled: _readBool(
        map['microphone_enabled'],
        fallback: true,
      ),
      audioConnected: _readBool(
        map['audio_connected'],
      ),
      cameraEnabled: _readBool(
        map['camera_enabled'],
      ),
      videoConnected: _readBool(
        map['video_connected'],
      ),
      isSpeaking: _readBool(
        map['is_speaking'],
      ),
      isLocalUser: _readBool(
        map['is_local_user'],
      ),
    );
  }

  // ==========================================================
  // TO MAP
  // ==========================================================

  Map<
    String,
    dynamic
  >
  toMap() {
    return {
      'user_id': userId,
      'name': name,
      'username': username,
      'avatar_url': avatarUrl,
      'connected': connected,
      'joined_at': joinedAt?.toIso8601String(),
      'left_at': leftAt?.toIso8601String(),
      'microphone_enabled': microphoneEnabled,
      'audio_connected': audioConnected,
      'camera_enabled': cameraEnabled,
      'video_connected': videoConnected,
      'is_speaking': isSpeaking,
      'is_local_user': isLocalUser,
    };
  }

  // ==========================================================
  // COPY WITH
  // ==========================================================

  CallParticipantModel copyWith({
    String? userId,
    String? name,
    String? username,
    String? avatarUrl,
    bool? connected,
    DateTime? joinedAt,
    DateTime? leftAt,
    bool? microphoneEnabled,
    bool? audioConnected,
    bool? cameraEnabled,
    bool? videoConnected,
    bool? isSpeaking,
    bool? isLocalUser,
  }) {
    return CallParticipantModel(
      userId:
          userId ??
          this.userId,
      name:
          name ??
          this.name,
      username:
          username ??
          this.username,
      avatarUrl:
          avatarUrl ??
          this.avatarUrl,
      connected:
          connected ??
          this.connected,
      joinedAt:
          joinedAt ??
          this.joinedAt,
      leftAt:
          leftAt ??
          this.leftAt,
      microphoneEnabled:
          microphoneEnabled ??
          this.microphoneEnabled,
      audioConnected:
          audioConnected ??
          this.audioConnected,
      cameraEnabled:
          cameraEnabled ??
          this.cameraEnabled,
      videoConnected:
          videoConnected ??
          this.videoConnected,
      isSpeaking:
          isSpeaking ??
          this.isSpeaking,
      isLocalUser:
          isLocalUser ??
          this.isLocalUser,
    );
  }

  // ==========================================================
  // HELPERS
  // ==========================================================

  bool get hasVideo =>
      connected &&
      cameraEnabled &&
      videoConnected;

  bool get hasAudio =>
      connected &&
      audioConnected;

  bool get isAudioOnly =>
      hasAudio &&
      !hasVideo;

  bool get hasLeft =>
      leftAt !=
      null;

  String get displayName {
    final normalizedName = name?.trim();

    if (normalizedName !=
            null &&
        normalizedName.isNotEmpty) {
      return normalizedName;
    }

    final normalizedUsername = username?.trim();

    if (normalizedUsername !=
            null &&
        normalizedUsername.isNotEmpty) {
      return '@$normalizedUsername';
    }

    return 'Usuário';
  }

  // ==========================================================
  // PARSERS
  // ==========================================================

  static String _readString(
    dynamic value,
  ) {
    return value?.toString().trim() ??
        '';
  }

  static String? _readNullableString(
    dynamic value,
  ) {
    final normalized = value?.toString().trim();

    if (normalized ==
            null ||
        normalized.isEmpty) {
      return null;
    }

    return normalized;
  }

  static bool _readBool(
    dynamic value, {
    bool fallback = false,
  }) {
    if (value
        is bool) {
      return value;
    }

    if (value
        is num) {
      return value !=
          0;
    }

    if (value
        is String) {
      switch (value.trim().toLowerCase()) {
        case 'true':
        case '1':
          return true;

        case 'false':
        case '0':
          return false;
      }
    }

    return fallback;
  }

  static DateTime? _readDateTime(
    dynamic value,
  ) {
    if (value ==
        null) {
      return null;
    }

    if (value
        is DateTime) {
      return value;
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }

  // ==========================================================
  // OBJECT
  // ==========================================================

  @override
  String toString() {
    return 'CallParticipantModel('
        'userId: $userId, '
        'connected: $connected, '
        'microphoneEnabled: $microphoneEnabled, '
        'cameraEnabled: $cameraEnabled'
        ')';
  }
}
