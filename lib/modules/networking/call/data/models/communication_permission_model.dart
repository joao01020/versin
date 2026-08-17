// ============================================================
// COMMUNICATION PERMISSION MODEL
// ============================================================
//
// Representa a permissão BILATERAL de vídeo entre dois
// usuários dentro de um projeto.
//
// IMPORTANTE:
//
// A permissão é específica para o PAR:
//
// userA <-> userB
//
// Exemplo:
//
// João <-> Artista
// videoAllowed = true
//
// João <-> Beatmaker
// videoAllowed = false
//
// Isso significa que aceitar vídeo com um usuário NÃO libera
// automaticamente vídeo com todos os outros membros.
//
// Áudio continua independente e não depende desse model.
//
// ============================================================

class CommunicationPermissionModel {
  // ==========================================================
  // IDENTIFICAÇÃO
  // ==========================================================

  final String id;

  final String projectId;

  // ==========================================================
  // PAR DE USUÁRIOS
  // ==========================================================
  //
  // O banco mantém o par em ordem canônica:
  //
  // userAId < userBId
  //
  // Assim:
  //
  // A <-> B
  //
  // e
  //
  // B <-> A
  //
  // representam exatamente a mesma permissão.
  //
  // ==========================================================

  final String userAId;

  final String userBId;

  // ==========================================================
  // PERMISSÃO DE VÍDEO
  // ==========================================================

  final bool videoAllowed;

  // ==========================================================
  // AUDITORIA
  // ==========================================================

  final DateTime? videoAllowedAt;

  final DateTime? videoRevokedAt;

  final String? videoRevokedBy;

  final DateTime? createdAt;

  final DateTime? updatedAt;

  // ==========================================================
  // CONSTRUCTOR
  // ==========================================================

  const CommunicationPermissionModel({
    required this.id,
    required this.projectId,
    required this.userAId,
    required this.userBId,
    this.videoAllowed = false,
    this.videoAllowedAt,
    this.videoRevokedAt,
    this.videoRevokedBy,
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
      userAId: _readString(
        map['user_a_id'],
      ),
      userBId: _readString(
        map['user_b_id'],
      ),
      videoAllowed: _readBool(
        map['video_allowed'],
      ),
      videoAllowedAt: _readDateTime(
        map['video_allowed_at'],
      ),
      videoRevokedAt: _readDateTime(
        map['video_revoked_at'],
      ),
      videoRevokedBy: _readNullableString(
        map['video_revoked_by'],
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
      'user_a_id': userAId,
      'user_b_id': userBId,
      'video_allowed': videoAllowed,
      'video_allowed_at': videoAllowedAt?.toIso8601String(),
      'video_revoked_at': videoRevokedAt?.toIso8601String(),
      'video_revoked_by': videoRevokedBy,
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
    String? userAId,
    String? userBId,
    bool? videoAllowed,
    DateTime? videoAllowedAt,
    DateTime? videoRevokedAt,
    String? videoRevokedBy,
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
      userAId:
          userAId ??
          this.userAId,
      userBId:
          userBId ??
          this.userBId,
      videoAllowed:
          videoAllowed ??
          this.videoAllowed,
      videoAllowedAt:
          videoAllowedAt ??
          this.videoAllowedAt,
      videoRevokedAt:
          videoRevokedAt ??
          this.videoRevokedAt,
      videoRevokedBy:
          videoRevokedBy ??
          this.videoRevokedBy,
      createdAt:
          createdAt ??
          this.createdAt,
      updatedAt:
          updatedAt ??
          this.updatedAt,
    );
  }

  // ==========================================================
  // VIDEO
  // ==========================================================

  bool get canUseVideo => videoAllowed;

  bool get requiresVideoPermission => !videoAllowed;

  bool get wasRevoked =>
      videoRevokedAt !=
      null;

  // ==========================================================
  // RELATIONSHIP
  // ==========================================================

  bool containsUser(
    String userId,
  ) {
    final normalized = userId.trim();

    if (normalized.isEmpty) {
      return false;
    }

    return userAId ==
            normalized ||
        userBId ==
            normalized;
  }

  // ==========================================================
  // OTHER USER
  // ==========================================================
  //
  // Se o usuário atual for A:
  //
  // retorna B.
  //
  // Se for B:
  //
  // retorna A.
  //
  // Caso o usuário não faça parte da relação:
  //
  // retorna null.
  //
  // ==========================================================

  String? otherUserId(
    String currentUserId,
  ) {
    final normalized = currentUserId.trim();

    if (normalized.isEmpty) {
      return null;
    }

    if (userAId ==
        normalized) {
      return userBId;
    }

    if (userBId ==
        normalized) {
      return userAId;
    }

    return null;
  }

  // ==========================================================
  // MATCHES PAIR
  // ==========================================================
  //
  // A ordem não importa.
  //
  // matchesPair(A, B)
  //
  // ==
  //
  // matchesPair(B, A)
  //
  // ==========================================================

  bool matchesPair({
    required String firstUserId,
    required String secondUserId,
  }) {
    final first = firstUserId.trim();

    final second = secondUserId.trim();

    if (first.isEmpty ||
        second.isEmpty ||
        first ==
            second) {
      return false;
    }

    return (userAId ==
                first &&
            userBId ==
                second) ||
        (userAId ==
                second &&
            userBId ==
                first);
  }

  // ==========================================================
  // WAS REVOKED BY
  // ==========================================================

  bool wasRevokedBy(
    String userId,
  ) {
    final revokedBy = videoRevokedBy?.trim();

    final normalized = userId.trim();

    if (revokedBy ==
            null ||
        revokedBy.isEmpty ||
        normalized.isEmpty) {
      return false;
    }

    return revokedBy ==
        normalized;
  }

  // ==========================================================
  // IS VALID
  // ==========================================================

  bool get isValid {
    if (id.isEmpty ||
        projectId.isEmpty ||
        userAId.isEmpty ||
        userBId.isEmpty) {
      return false;
    }

    if (userAId ==
        userBId) {
      return false;
    }

    return true;
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
    return 'CommunicationPermissionModel('
        'projectId: $projectId, '
        'userAId: $userAId, '
        'userBId: $userBId, '
        'videoAllowed: $videoAllowed'
        ')';
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
            is CommunicationPermissionModel &&
        other.id ==
            id &&
        other.projectId ==
            projectId &&
        other.userAId ==
            userAId &&
        other.userBId ==
            userBId &&
        other.videoAllowed ==
            videoAllowed &&
        other.videoAllowedAt ==
            videoAllowedAt &&
        other.videoRevokedAt ==
            videoRevokedAt &&
        other.videoRevokedBy ==
            videoRevokedBy;
  }

  // ==========================================================
  // HASH CODE
  // ==========================================================

  @override
  int get hashCode => Object.hash(
    id,
    projectId,
    userAId,
    userBId,
    videoAllowed,
    videoAllowedAt,
    videoRevokedAt,
    videoRevokedBy,
  );
}
