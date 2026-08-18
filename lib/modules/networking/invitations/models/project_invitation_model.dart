// ============================================================
// PROJECT INVITATION STATUS
// ============================================================

enum ProjectInvitationStatus {
  pending,
  accepted,
  rejected,
}

// ============================================================
// PROJECT INVITATION MODEL
// ============================================================
//
// Representa um convite para entrar em uma Studio Session.
//
// Fonte:
//
// public.project_invitations
//
// Campos principais:
//
// - id;
// - projectId;
// - invitedBy;
// - invitedUserId;
// - status;
// - createdAt;
// - respondedAt.
//
// Campos enriquecidos:
//
// - inviterName;
// - projectTitle.
//
// Esses dois últimos não precisam existir diretamente na tabela.
// O ProjectInvitationService pode resolvê-los consultando:
//
// public.profiles
// public.projects
//
// ============================================================

class ProjectInvitationModel {
  final String id;

  final String projectId;

  final String invitedBy;

  final String invitedUserId;

  final ProjectInvitationStatus status;

  final DateTime createdAt;

  final DateTime? respondedAt;

  final String inviterName;

  final String projectTitle;

  const ProjectInvitationModel({
    required this.id,
    required this.projectId,
    required this.invitedBy,
    required this.invitedUserId,
    required this.status,
    required this.createdAt,
    this.respondedAt,
    this.inviterName = 'Membro',
    this.projectTitle = 'Studio Session',
  });

  // ============================================================
  // HELPERS
  // ============================================================

  bool get isPending {
    return status ==
        ProjectInvitationStatus.pending;
  }

  bool get isAccepted {
    return status ==
        ProjectInvitationStatus.accepted;
  }

  bool get isRejected {
    return status ==
        ProjectInvitationStatus.rejected;
  }

  bool get hasInviterName {
    return inviterName.trim().isNotEmpty &&
        inviterName.trim() !=
            'Membro';
  }

  bool get hasProjectTitle {
    return projectTitle.trim().isNotEmpty;
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  ProjectInvitationModel copyWith({
    String? id,
    String? projectId,
    String? invitedBy,
    String? invitedUserId,
    ProjectInvitationStatus? status,
    DateTime? createdAt,
    DateTime? respondedAt,
    bool clearRespondedAt = false,
    String? inviterName,
    String? projectTitle,
  }) {
    return ProjectInvitationModel(
      id:
          id ??
          this.id,
      projectId:
          projectId ??
          this.projectId,
      invitedBy:
          invitedBy ??
          this.invitedBy,
      invitedUserId:
          invitedUserId ??
          this.invitedUserId,
      status:
          status ??
          this.status,
      createdAt:
          createdAt ??
          this.createdAt,
      respondedAt: clearRespondedAt
          ? null
          : respondedAt ??
                this.respondedAt,
      inviterName:
          inviterName ??
          this.inviterName,
      projectTitle:
          projectTitle ??
          this.projectTitle,
    );
  }

  // ============================================================
  // FROM MAP
  // ============================================================

  factory ProjectInvitationModel.fromMap(
    Map<
      String,
      dynamic
    >
    map,
  ) {
    return ProjectInvitationModel(
      id: _readString(
        map['id'],
      ),

      projectId: _readString(
        map['project_id'],
      ),

      invitedBy: _readString(
        map['invited_by'],
      ),

      invitedUserId: _readString(
        map['invited_user_id'],
      ),

      status: _statusFromValue(
        map['status'],
      ),

      createdAt:
          _readDateTime(
            map['created_at'],
          ) ??
          DateTime.now().toUtc(),

      respondedAt: _readDateTime(
        map['responded_at'],
      ),

      inviterName:
          _readString(
            map['inviter_name'],
          ).isEmpty
          ? 'Membro'
          : _readString(
              map['inviter_name'],
            ),

      projectTitle:
          _readString(
            map['project_title'],
          ).isEmpty
          ? 'Studio Session'
          : _readString(
              map['project_title'],
            ),
    );
  }

  // ============================================================
  // TO MAP
  // ============================================================

  Map<
    String,
    dynamic
  >
  toMap() {
    return {
      'id': id,
      'project_id': projectId,
      'invited_by': invitedBy,
      'invited_user_id': invitedUserId,
      'status': status.name,
      'created_at': createdAt.toUtc().toIso8601String(),
      'responded_at': respondedAt?.toUtc().toIso8601String(),
    };
  }

  // ============================================================
  // STATUS
  // ============================================================

  static ProjectInvitationStatus _statusFromValue(
    dynamic value,
  ) {
    switch (value?.toString().trim().toLowerCase()) {
      case 'accepted':
        return ProjectInvitationStatus.accepted;

      case 'rejected':
        return ProjectInvitationStatus.rejected;

      case 'pending':
      default:
        return ProjectInvitationStatus.pending;
    }
  }

  // ============================================================
  // STRING
  // ============================================================

  static String _readString(
    dynamic value,
  ) {
    return value?.toString().trim() ??
        '';
  }

  // ============================================================
  // DATETIME
  // ============================================================

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

    final normalized = value.toString().trim();

    if (normalized.isEmpty) {
      return null;
    }

    return DateTime.tryParse(
      normalized,
    );
  }

  // ============================================================
  // TO STRING
  // ============================================================

  @override
  String toString() {
    return 'ProjectInvitationModel('
        'id: $id, '
        'projectId: $projectId, '
        'invitedBy: $invitedBy, '
        'invitedUserId: $invitedUserId, '
        'status: ${status.name}, '
        'inviterName: $inviterName, '
        'projectTitle: $projectTitle'
        ')';
  }
}
