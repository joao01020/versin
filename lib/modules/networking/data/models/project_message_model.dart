// ============================================================
// PROJECT MESSAGE MODEL
// ============================================================
//
// Representa uma mensagem enviada dentro de uma Studio Session.
//
// Banco:
//
// public.project_messages
//
// id
// project_id
// sender_id
// content
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

  final DateTime createdAt;

  // ==========================================================
  // CONSTRUTOR
  // ==========================================================

  const ProjectMessageModel({
    required this.id,
    required this.projectId,
    required this.senderId,
    required this.content,
    required this.createdAt,
  });

  // ==========================================================
  // É MINHA MENSAGEM?
  // ==========================================================

  bool isMine(
    String currentUserId,
  ) {
    return senderId ==
        currentUserId.trim();
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
      id:
          map['id']?.toString().trim() ??
          '',

      projectId:
          map['project_id']?.toString().trim() ??
          '',

      senderId:
          map['sender_id']?.toString().trim() ??
          '',

      content:
          map['content']?.toString() ??
          '',

      createdAt: _readDateTime(
        map['created_at'],
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

      'sender_id': senderId,

      'content': content,

      'created_at': createdAt.toUtc().toIso8601String(),
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
    DateTime? createdAt,
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

      createdAt:
          createdAt ??
          this.createdAt,
    );
  }

  // ==========================================================
  // DATE
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
      final parsed = DateTime.tryParse(
        value,
      );

      if (parsed !=
          null) {
        return parsed.toLocal();
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
        'senderId: $senderId'
        ')';
  }
}
