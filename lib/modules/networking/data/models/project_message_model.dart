// ============================================================
// PROJECT MESSAGE TYPE
// ============================================================
//
// Tipos suportados pelo chat da Studio Session.
//
// text
// -> mensagem de texto normal.
//
// audio
// -> mensagem de voz armazenada no Storage.
//
// system
// -> mensagem gerada pelo sistema.
//
// ============================================================

enum ProjectMessageType {
  text,
  audio,
  system,
}

// ============================================================
// PROJECT MESSAGE MODEL
// ============================================================
//
// Representa uma mensagem enviada dentro de uma Studio Session.
//
// A mensagem pertence ao PROJETO, e não a uma conversa
// individual entre dois usuários.
//
// Isso permite:
//
// João + Maria
//      ↓
// projectId = X
//
// Pedro entra depois
//      ↓
// projectId = X
//
// Todos continuam usando o mesmo histórico.
//
// Banco:
//
// public.project_messages
//
// id
// project_id
// sender_id
// content
// message_type
// audio_path
// audio_duration_ms
// created_at
//
// ============================================================

class ProjectMessageModel {
  // ==========================================================
  // CAMPOS
  // ==========================================================

  final String id;

  final String projectId;

  final String senderId;

  final String content;

  final ProjectMessageType type;

  final String? audioPath;

  final int? audioDurationMs;

  final DateTime createdAt;

  // ==========================================================
  // CONSTRUTOR
  // ==========================================================

  const ProjectMessageModel({
    required this.id,
    required this.projectId,
    required this.senderId,
    required this.content,
    required this.type,
    required this.audioPath,
    required this.audioDurationMs,
    required this.createdAt,
  });

  // ==========================================================
  // FACTORY TEXT
  // ==========================================================

  factory ProjectMessageModel.text({
    required String id,
    required String projectId,
    required String senderId,
    required String content,
    required DateTime createdAt,
  }) {
    return ProjectMessageModel(
      id: id.trim(),
      projectId: projectId.trim(),
      senderId: senderId.trim(),
      content: content,
      type: ProjectMessageType.text,
      audioPath: null,
      audioDurationMs: null,
      createdAt: createdAt,
    );
  }

  // ==========================================================
  // FACTORY AUDIO
  // ==========================================================

  factory ProjectMessageModel.audio({
    required String id,
    required String projectId,
    required String senderId,
    required String audioPath,
    required int audioDurationMs,
    required DateTime createdAt,
    String content = '',
  }) {
    return ProjectMessageModel(
      id: id.trim(),
      projectId: projectId.trim(),
      senderId: senderId.trim(),
      content: content,
      type: ProjectMessageType.audio,
      audioPath: _normalizeNullableString(
        audioPath,
      ),
      audioDurationMs:
          audioDurationMs <
              0
          ? 0
          : audioDurationMs,
      createdAt: createdAt,
    );
  }

  // ==========================================================
  // FACTORY SYSTEM
  // ==========================================================

  factory ProjectMessageModel.system({
    required String id,
    required String projectId,
    required String content,
    required DateTime createdAt,
    String senderId = '',
  }) {
    return ProjectMessageModel(
      id: id.trim(),
      projectId: projectId.trim(),
      senderId: senderId.trim(),
      content: content,
      type: ProjectMessageType.system,
      audioPath: null,
      audioDurationMs: null,
      createdAt: createdAt,
    );
  }

  // ==========================================================
  // É MINHA MENSAGEM?
  // ==========================================================

  bool isMine(
    String currentUserId,
  ) {
    final normalizedCurrentUserId = currentUserId.trim();

    if (normalizedCurrentUserId.isEmpty) {
      return false;
    }

    return senderId ==
        normalizedCurrentUserId;
  }

  // ==========================================================
  // PERTENCE AO PROJETO?
  // ==========================================================

  bool belongsToProject(
    String currentProjectId,
  ) {
    final normalizedProjectId = currentProjectId.trim();

    if (normalizedProjectId.isEmpty) {
      return false;
    }

    return projectId ==
        normalizedProjectId;
  }

  // ==========================================================
  // TIPO
  // ==========================================================

  bool get isText =>
      type ==
      ProjectMessageType.text;

  bool get isAudio =>
      type ==
      ProjectMessageType.audio;

  bool get isSystem =>
      type ==
      ProjectMessageType.system;

  // ==========================================================
  // POSSUI REMETENTE?
  // ==========================================================

  bool get hasSender => senderId.isNotEmpty;

  // ==========================================================
  // POSSUI CONTEÚDO?
  // ==========================================================

  bool get hasContent => content.trim().isNotEmpty;

  // ==========================================================
  // POSSUI ÁUDIO?
  // ==========================================================

  bool get hasAudio {
    if (!isAudio) {
      return false;
    }

    final path = audioPath?.trim();

    return path !=
            null &&
        path.isNotEmpty;
  }

  // ==========================================================
  // DURAÇÃO DO ÁUDIO
  // ==========================================================

  Duration get audioDuration {
    final milliseconds = audioDurationMs;

    if (milliseconds ==
            null ||
        milliseconds <=
            0) {
      return Duration.zero;
    }

    return Duration(
      milliseconds: milliseconds,
    );
  }

  // ==========================================================
  // É VÁLIDA?
  // ==========================================================

  bool get isValid {
    if (id.isEmpty ||
        projectId.isEmpty) {
      return false;
    }

    switch (type) {
      case ProjectMessageType.text:
        return senderId.isNotEmpty &&
            hasContent;

      case ProjectMessageType.audio:
        return senderId.isNotEmpty &&
            hasAudio;

      case ProjectMessageType.system:
        return hasContent;
    }
  }

  // ==========================================================
  // FROM MAP
  // ==========================================================

  factory ProjectMessageModel.fromMap(
    Map<
      String,
      dynamic
    >
    map,
  ) {
    return ProjectMessageModel(
      id: _readString(
        map['id'],
      ),

      projectId: _readString(
        map['project_id'],
      ),

      senderId: _readString(
        map['sender_id'],
      ),

      content: _readContent(
        map['content'],
      ),

      type: _readMessageType(
        map['message_type'],
      ),

      audioPath: _readNullableString(
        map['audio_path'],
      ),

      audioDurationMs: _readNullableInt(
        map['audio_duration_ms'],
      ),

      createdAt: _readDateTime(
        map['created_at'],
      ),
    );
  }

  // ==========================================================
  // TO MAP
  // ==========================================================
  //
  // Representação completa do objeto.
  //
  // ==========================================================

  Map<
    String,
    dynamic
  >
  toMap() {
    return {
      'id': id,

      'project_id': projectId,

      'sender_id': senderId,

      'content': hasContent
          ? content
          : null,

      'message_type': _messageTypeToDatabase(
        type,
      ),

      'audio_path': audioPath,

      'audio_duration_ms': audioDurationMs,

      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }

  // ==========================================================
  // TO INSERT MAP
  // ==========================================================
  //
  // Útil para INSERT no Supabase.
  //
  // Não envia:
  //
  // - id;
  // - created_at.
  //
  // Esses valores normalmente são gerados pelo banco.
  //
  // ==========================================================

  Map<
    String,
    dynamic
  >
  toInsertMap() {
    return {
      'project_id': projectId,

      'sender_id': senderId,

      'content': hasContent
          ? content.trim()
          : null,

      'message_type': _messageTypeToDatabase(
        type,
      ),

      'audio_path': audioPath,

      'audio_duration_ms': audioDurationMs,
    };
  }

  // ==========================================================
  // COPY WITH
  // ==========================================================

  ProjectMessageModel copyWith({
    String? id,
    String? projectId,
    String? senderId,
    String? content,
    ProjectMessageType? type,
    String? audioPath,
    int? audioDurationMs,
    DateTime? createdAt,
    bool clearAudioPath = false,
    bool clearAudioDuration = false,
  }) {
    return ProjectMessageModel(
      id:
          id ??
          this.id,

      projectId:
          projectId ??
          this.projectId,

      senderId:
          senderId ??
          this.senderId,

      content:
          content ??
          this.content,

      type:
          type ??
          this.type,

      audioPath: clearAudioPath
          ? null
          : audioPath ??
                this.audioPath,

      audioDurationMs: clearAudioDuration
          ? null
          : audioDurationMs ??
                this.audioDurationMs,

      createdAt:
          createdAt ??
          this.createdAt,
    );
  }

  // ==========================================================
  // DATABASE TYPE
  // ==========================================================

  static String _messageTypeToDatabase(
    ProjectMessageType type,
  ) {
    switch (type) {
      case ProjectMessageType.text:
        return 'text';

      case ProjectMessageType.audio:
        return 'audio';

      case ProjectMessageType.system:
        return 'system';
    }
  }

  // ==========================================================
  // READ MESSAGE TYPE
  // ==========================================================

  static ProjectMessageType _readMessageType(
    dynamic value,
  ) {
    final normalized = value?.toString().trim().toLowerCase();

    switch (normalized) {
      case 'audio':
        return ProjectMessageType.audio;

      case 'system':
        return ProjectMessageType.system;

      case 'text':
      default:
        return ProjectMessageType.text;
    }
  }

  // ==========================================================
  // READ STRING
  // ==========================================================

  static String _readString(
    dynamic value,
  ) {
    return value?.toString().trim() ??
        '';
  }

  // ==========================================================
  // READ NULLABLE STRING
  // ==========================================================

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

  // ==========================================================
  // NORMALIZE NULLABLE STRING
  // ==========================================================

  static String? _normalizeNullableString(
    String? value,
  ) {
    final normalized = value?.trim();

    if (normalized ==
            null ||
        normalized.isEmpty) {
      return null;
    }

    return normalized;
  }

  // ==========================================================
  // READ CONTENT
  // ==========================================================

  static String _readContent(
    dynamic value,
  ) {
    return value?.toString() ??
        '';
  }

  // ==========================================================
  // READ NULLABLE INT
  // ==========================================================

  static int? _readNullableInt(
    dynamic value,
  ) {
    if (value ==
        null) {
      return null;
    }

    if (value
        is int) {
      return value <
              0
          ? 0
          : value;
    }

    if (value
        is num) {
      final parsed = value.toInt();

      return parsed <
              0
          ? 0
          : parsed;
    }

    final parsed = int.tryParse(
      value.toString(),
    );

    if (parsed ==
        null) {
      return null;
    }

    return parsed <
            0
        ? 0
        : parsed;
  }

  // ==========================================================
  // READ DATE
  // ==========================================================

  static DateTime _readDateTime(
    dynamic value,
  ) {
    if (value
        is DateTime) {
      return value.toLocal();
    }

    if (value
        is String) {
      final normalized = value.trim();

      if (normalized.isNotEmpty) {
        final parsed = DateTime.tryParse(
          normalized,
        );

        if (parsed !=
            null) {
          return parsed.toLocal();
        }
      }
    }

    return DateTime.now();
  }

  // ==========================================================
  // EQUALITY
  // ==========================================================

  @override
  bool operator ==(
    Object other,
  ) {
    if (identical(
      this,
      other,
    )) {
      return true;
    }

    return other
            is ProjectMessageModel &&
        other.id ==
            id;
  }

  // ==========================================================
  // HASH CODE
  // ==========================================================

  @override
  int get hashCode => id.hashCode;

  // ==========================================================
  // STRING
  // ==========================================================

  @override
  String toString() {
    return 'ProjectMessageModel('
        'id: $id, '
        'projectId: $projectId, '
        'senderId: $senderId, '
        'type: ${_messageTypeToDatabase(type)}, '
        'audioPath: $audioPath, '
        'audioDurationMs: $audioDurationMs, '
        'createdAt: $createdAt'
        ')';
  }
}
