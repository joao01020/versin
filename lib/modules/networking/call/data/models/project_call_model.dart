import '../../types/call_media_type.dart';
import '../../types/call_status.dart';

// ============================================================
// PROJECT CALL MODEL
// ============================================================
//
// Representa uma chamada pertencente a um projeto.
//
// IMPORTANTE:
//
// O mediaType representa como a chamada foi INICIADA.
//
// Ele NÃO significa que todos os participantes precisam
// utilizar o mesmo tipo de mídia.
//
// Exemplo:
//
// mediaType = CallMediaType.video
//
// Participante A → vídeo + áudio
// Participante B → áudio
// Participante C → vídeo + áudio
//
// O estado individual fica em CallParticipantModel.
//
// ============================================================

class ProjectCallModel {
  // ==========================================================
  // IDENTIFICAÇÃO
  // ==========================================================

  final String id;

  final String projectId;

  final String createdBy;

  final String? targetUserId;

  // ==========================================================
  // CHAMADA
  // ==========================================================

  final CallMediaType mediaType;

  final CallStatus status;

  // ==========================================================
  // DATAS
  // ==========================================================

  final DateTime? createdAt;

  final DateTime? startedAt;

  final DateTime? endedAt;

  // ==========================================================
  // CONSTRUCTOR
  // ==========================================================

  const ProjectCallModel({
    required this.id,
    required this.projectId,
    required this.createdBy,
    required this.mediaType,
    required this.status,
    this.targetUserId,
    this.createdAt,
    this.startedAt,
    this.endedAt,
  });

  // ==========================================================
  // FROM MAP
  // ==========================================================

  factory ProjectCallModel.fromMap(
    Map<
      String,
      dynamic
    >
    map,
  ) {
    return ProjectCallModel(
      id: _readString(
        map['id'],
      ),

      projectId: _readString(
        map['project_id'],
      ),

      createdBy: _readString(
        map['created_by'],
      ),

      targetUserId: _readNullableString(
        map['target_user_id'],
      ),

      mediaType: CallMediaType.fromString(
        _readString(
          map['media_type'],
        ),
      ),

      status: CallStatus.fromString(
        _readString(
          map['status'],
        ),
      ),

      createdAt: _readDateTime(
        map['created_at'],
      ),

      startedAt: _readDateTime(
        map['started_at'],
      ),

      endedAt: _readDateTime(
        map['ended_at'],
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

      'created_by': createdBy,

      'target_user_id': targetUserId,

      'media_type': mediaType.value,

      'status': status.value,

      'created_at': createdAt?.toUtc().toIso8601String(),

      'started_at': startedAt?.toUtc().toIso8601String(),

      'ended_at': endedAt?.toUtc().toIso8601String(),
    };
  }

  // ==========================================================
  // COPY WITH
  // ==========================================================

  ProjectCallModel copyWith({
    String? id,
    String? projectId,
    String? createdBy,
    String? targetUserId,
    CallMediaType? mediaType,
    CallStatus? status,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? endedAt,
  }) {
    return ProjectCallModel(
      id:
          id ??
          this.id,

      projectId:
          projectId ??
          this.projectId,

      createdBy:
          createdBy ??
          this.createdBy,

      targetUserId:
          targetUserId ??
          this.targetUserId,

      mediaType:
          mediaType ??
          this.mediaType,

      status:
          status ??
          this.status,

      createdAt:
          createdAt ??
          this.createdAt,

      startedAt:
          startedAt ??
          this.startedAt,

      endedAt:
          endedAt ??
          this.endedAt,
    );
  }

  // ==========================================================
  // STATUS
  // ==========================================================

  bool get isRinging => status.isRinging;

  bool get isActive => status.isActive;

  bool get isRejected => status.isRejected;

  bool get isCancelled => status.isCancelled;

  bool get isMissed => status.isMissed;

  bool get isEnded => status.isEnded;

  bool get isFinished => status.isFinished;

  // ==========================================================
  // MEDIA
  // ==========================================================

  bool get startedAsAudio => mediaType.isAudio;

  bool get startedAsVideo => mediaType.isVideo;

  // ==========================================================
  // PODE ACEITAR?
  // ==========================================================

  bool get canAccept => status.canAccept;

  // ==========================================================
  // PODE RECUSAR?
  // ==========================================================

  bool get canReject => status.canReject;

  // ==========================================================
  // PODE ENCERRAR?
  // ==========================================================

  bool get canEnd => status.canEnd;

  // ==========================================================
  // USERS
  // ==========================================================

  bool wasCreatedBy(
    String userId,
  ) {
    final normalized = userId.trim();

    if (normalized.isEmpty) {
      return false;
    }

    return createdBy ==
        normalized;
  }

  bool targets(
    String userId,
  ) {
    final normalized = userId.trim();

    if (normalized.isEmpty) {
      return false;
    }

    return targetUserId ==
        normalized;
  }

  // ==========================================================
  // É CHAMADA DIRETA?
  // ==========================================================

  bool get isDirectCall =>
      targetUserId !=
          null &&
      targetUserId!.isNotEmpty;

  // ==========================================================
  // É CHAMADA DE GRUPO?
  // ==========================================================

  bool get isGroupCall => !isDirectCall;

  // ==========================================================
  // DURATION
  // ==========================================================

  Duration? get duration {
    final start = startedAt;

    if (start ==
        null) {
      return null;
    }

    final end =
        endedAt ??
        (isActive
            ? DateTime.now()
            : null);

    if (end ==
        null) {
      return null;
    }

    final difference = end.difference(
      start,
    );

    if (difference.isNegative) {
      return Duration.zero;
    }

    return difference;
  }

  // ==========================================================
  // DURATION LABEL
  // ==========================================================

  String get durationLabel {
    final value = duration;

    if (value ==
        null) {
      return '00:00';
    }

    final hours = value.inHours;

    final minutes = value.inMinutes
        .remainder(
          60,
        )
        .toString()
        .padLeft(
          2,
          '0',
        );

    final seconds = value.inSeconds
        .remainder(
          60,
        )
        .toString()
        .padLeft(
          2,
          '0',
        );

    if (hours >
        0) {
      final formattedHours = hours.toString().padLeft(
        2,
        '0',
      );

      return '$formattedHours:$minutes:$seconds';
    }

    return '$minutes:$seconds';
  }

  // ==========================================================
  // VALID
  // ==========================================================

  bool get isValid {
    if (id.isEmpty) {
      return false;
    }

    if (projectId.isEmpty) {
      return false;
    }

    if (createdBy.isEmpty) {
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

  static DateTime? _readDateTime(
    dynamic value,
  ) {
    if (value ==
        null) {
      return null;
    }

    if (value
        is DateTime) {
      return value.toLocal();
    }

    final parsed = DateTime.tryParse(
      value.toString(),
    );

    return parsed?.toLocal();
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
            is ProjectCallModel &&
        other.id ==
            id;
  }

  @override
  int get hashCode => id.hashCode;

  // ==========================================================
  // OBJECT
  // ==========================================================

  @override
  String toString() {
    return 'ProjectCallModel('
        'id: $id, '
        'projectId: $projectId, '
        'createdBy: $createdBy, '
        'targetUserId: $targetUserId, '
        'mediaType: ${mediaType.value}, '
        'status: ${status.value}'
        ')';
  }
}
