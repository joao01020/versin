// ============================================================
// COMMUNICATION PERMISSION MODEL
// ============================================================
//
// Representa as permissões de comunicação de um membro
// dentro de um projeto.
//
// Áudio e vídeo são independentes.
//
// Exemplo:
//
// audioAllowed = true
// videoAllowed = false
//
// O usuário pode participar por áudio,
// mas ainda não possui autorização para vídeo.
//
// ============================================================

class CommunicationPermissionModel {
  // ==========================================================
  // IDENTIFICAÇÃO
  // ==========================================================

  final String id;

  final String projectId;

  final String userId;

  // ==========================================================
  // PERMISSÕES
  // ==========================================================

  final bool audioAllowed;

  final bool videoAllowed;

  // ==========================================================
  // AUDITORIA
  // ==========================================================

  final String? videoApprovedBy;

  final DateTime? videoApprovedAt;

  final DateTime? createdAt;

  final DateTime? updatedAt;

  // ==========================================================
  // CONSTRUCTOR
  // ==========================================================

  const CommunicationPermissionModel({
    required this.id,
    required this.projectId,
    required this.userId,
    this.audioAllowed = true,
    this.videoAllowed = false,
    this.videoApprovedBy,
    this.videoApprovedAt,
    this.createdAt,
    this.updatedAt,
  });

  // ==========================================================
  // FROM MAP
  // ==========================================================

  factory CommunicationPermissionModel.fromMap(
    Map<
      String,
      dynamic
    >
    map,
  ) {
    return CommunicationPermissionModel(
      id: _readString(
        map['id'],
      ),
      projectId: _readString(
        map['project_id'],
      ),
      userId: _readString(
        map['user_id'],
      ),
      audioAllowed: _readBool(
        map['audio_allowed'],
        fallback: true,
      ),
      videoAllowed: _readBool(
        map['video_allowed'],
      ),
      videoApprovedBy: _readNullableString(
        map['video_approved_by'],
      ),
      videoApprovedAt: _readDateTime(
        map['video_approved_at'],
      ),
      createdAt: _readDateTime(
        map['created_at'],
      ),
      updatedAt: _readDateTime(
        map['updated_at'],
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
      'id': id,
      'project_id': projectId,
      'user_id': userId,
      'audio_allowed': audioAllowed,
      'video_allowed': videoAllowed,
      'video_approved_by': videoApprovedBy,
      'video_approved_at': videoApprovedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // ==========================================================
  // COPY WITH
  // ==========================================================

  CommunicationPermissionModel copyWith({
    String? id,
    String? projectId,
    String? userId,
    bool? audioAllowed,
    bool? videoAllowed,
    String? videoApprovedBy,
    DateTime? videoApprovedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CommunicationPermissionModel(
      id:
          id ??
          this.id,
      projectId:
          projectId ??
          this.projectId,
      userId:
          userId ??
          this.userId,
      audioAllowed:
          audioAllowed ??
          this.audioAllowed,
      videoAllowed:
          videoAllowed ??
          this.videoAllowed,
      videoApprovedBy:
          videoApprovedBy ??
          this.videoApprovedBy,
      videoApprovedAt:
          videoApprovedAt ??
          this.videoApprovedAt,
      createdAt:
          createdAt ??
          this.createdAt,
      updatedAt:
          updatedAt ??
          this.updatedAt,
    );
  }

  // ==========================================================
  // HELPERS
  // ==========================================================

  bool get canJoinAudio => audioAllowed;

  bool get canJoinVideo =>
      audioAllowed &&
      videoAllowed;

  bool get requiresVideoPermission => !videoAllowed;

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
    return 'CommunicationPermissionModel('
        'projectId: $projectId, '
        'userId: $userId, '
        'audioAllowed: $audioAllowed, '
        'videoAllowed: $videoAllowed'
        ')';
  }
}
