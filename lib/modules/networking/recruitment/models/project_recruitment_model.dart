// ============================================================
// PROJECT RECRUITMENT MODEL
// ============================================================
//
// Representa uma busca aberta por novos membros dentro de uma
// Studio Session.
//
// Exemplo:
//
// Studio Session
//      ↓
// procura:
// beatmaker
//
// project_recruitments
//
// ============================================================

enum ProjectRecruitmentStatus { open, closed, completed }

// ============================================================
// PROJECT RECRUITMENT MODEL
// ============================================================

class ProjectRecruitmentModel {
  final String id;

  final String projectId;

  final String createdBy;

  final String role;

  final String description;

  final ProjectRecruitmentStatus status;

  final DateTime createdAt;

  final DateTime? expiresAt;

  const ProjectRecruitmentModel({
    required this.id,
    required this.projectId,
    required this.createdBy,
    required this.role,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
  });

  // ==========================================================
  // STATUS
  // ==========================================================

  bool get isOpen => status == ProjectRecruitmentStatus.open;

  bool get isClosed => status == ProjectRecruitmentStatus.closed;

  bool get isCompleted => status == ProjectRecruitmentStatus.completed;

  bool get isExpired {
    final expiration = expiresAt;

    if (expiration == null) {
      return false;
    }

    return expiration.isBefore(DateTime.now());
  }

  // ==========================================================
  // ROLE LABEL
  // ==========================================================

  String get roleLabel {
    switch (role.trim().toLowerCase()) {
      case 'artist':
        return 'Artista';

      case 'producer':
        return 'Produtor';

      case 'beatmaker':
        return 'Beatmaker';

      case 'songwriter':
        return 'Compositor';

      case 'singer':
        return 'Vocalista';

      case 'rapper':
        return 'Rapper';

      case 'engineer':
        return 'Engenheiro';

      default:
        final value = role.trim();

        return value.isEmpty ? 'Membro' : value;
    }
  }

  // ==========================================================
  // FROM MAP
  // ==========================================================

  factory ProjectRecruitmentModel.fromMap(Map<String, dynamic> map) {
    return ProjectRecruitmentModel(
      id: map['id']?.toString().trim() ?? '',

      projectId: map['project_id']?.toString().trim() ?? '',

      createdBy: map['created_by']?.toString().trim() ?? '',

      role: map['role']?.toString().trim() ?? '',

      description: map['description']?.toString().trim() ?? '',

      status: statusFromString(map['status']?.toString()),

      createdAt: _readDate(map['created_at']),

      expiresAt: _readNullableDate(map['expires_at']),
    );
  }

  // ==========================================================
  // STATUS FROM STRING
  // ==========================================================

  static ProjectRecruitmentStatus statusFromString(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'closed':
        return ProjectRecruitmentStatus.closed;

      case 'completed':
        return ProjectRecruitmentStatus.completed;

      case 'open':
      default:
        return ProjectRecruitmentStatus.open;
    }
  }

  // ==========================================================
  // STATUS TO STRING
  // ==========================================================

  static String statusToString(ProjectRecruitmentStatus value) {
    switch (value) {
      case ProjectRecruitmentStatus.open:
        return 'open';

      case ProjectRecruitmentStatus.closed:
        return 'closed';

      case ProjectRecruitmentStatus.completed:
        return 'completed';
    }
  }

  // ==========================================================
  // DATE
  // ==========================================================

  static DateTime _readDate(dynamic value) {
    if (value is DateTime) {
      return value.toLocal();
    }

    if (value is String) {
      final parsed = DateTime.tryParse(value);

      if (parsed != null) {
        return parsed.toLocal();
      }
    }

    return DateTime.now();
  }

  static DateTime? _readNullableDate(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value.toLocal();
    }

    if (value is String) {
      return DateTime.tryParse(value)?.toLocal();
    }

    return null;
  }
}

// ============================================================
// CANDIDATE STATUS
// ============================================================

enum ProjectRecruitmentCandidateStatus {
  discovered,
  invited,
  interested,
  approved,
  rejected,
}

// ============================================================
// PROJECT RECRUITMENT CANDIDATE MODEL
// ============================================================

class ProjectRecruitmentCandidateModel {
  final String userId;

  final String username;

  final String name;

  final String artistName;

  final String primaryRole;

  final List<String> roles;

  final String? avatarUrl;

  final bool isOnline;

  final ProjectRecruitmentCandidateStatus status;

  final String? candidateRecordId;

  const ProjectRecruitmentCandidateModel({
    required this.userId,
    required this.username,
    required this.name,
    required this.artistName,
    required this.primaryRole,
    required this.roles,
    required this.avatarUrl,
    required this.isOnline,
    required this.status,
    required this.candidateRecordId,
  });

  // ==========================================================
  // DISPLAY NAME
  // ==========================================================

  String get displayName {
    final artist = artistName.trim();

    if (artist.isNotEmpty) {
      return artist;
    }

    final fullName = name.trim();

    if (fullName.isNotEmpty) {
      return fullName;
    }

    final user = username.trim();

    if (user.isNotEmpty) {
      return user;
    }

    return 'Usuário';
  }

  // ==========================================================
  // USERNAME
  // ==========================================================

  String get usernameLabel {
    final normalized = username.trim().replaceFirst(RegExp(r'^@+'), '');

    if (normalized.isEmpty) {
      return '';
    }

    return '@$normalized';
  }

  // ==========================================================
  // STATUS
  // ==========================================================

  bool get isInvited => status == ProjectRecruitmentCandidateStatus.invited;

  bool get isInterested =>
      status == ProjectRecruitmentCandidateStatus.interested;

  bool get isApproved => status == ProjectRecruitmentCandidateStatus.approved;

  // ==========================================================
  // FROM PROFILE
  // ==========================================================

  factory ProjectRecruitmentCandidateModel.fromProfileMap(
    Map<String, dynamic> map, {
    ProjectRecruitmentCandidateStatus status =
        ProjectRecruitmentCandidateStatus.discovered,
    String? candidateRecordId,
  }) {
    return ProjectRecruitmentCandidateModel(
      userId: map['id']?.toString().trim() ?? '',

      username: map['username']?.toString().trim() ?? '',

      name: map['name']?.toString().trim() ?? '',

      artistName: map['artist_name']?.toString().trim() ?? '',

      primaryRole: map['primary_role']?.toString().trim() ?? '',

      roles: _readList(map['roles']),

      avatarUrl: _readNullableString(map['avatar_url']),

      isOnline: map['is_online'] == true,

      status: status,

      candidateRecordId: candidateRecordId,
    );
  }

  // ==========================================================
  // STATUS FROM STRING
  // ==========================================================

  static ProjectRecruitmentCandidateStatus statusFromString(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'invited':
        return ProjectRecruitmentCandidateStatus.invited;

      case 'interested':
        return ProjectRecruitmentCandidateStatus.interested;

      case 'approved':
        return ProjectRecruitmentCandidateStatus.approved;

      case 'rejected':
        return ProjectRecruitmentCandidateStatus.rejected;

      case 'discovered':
      default:
        return ProjectRecruitmentCandidateStatus.discovered;
    }
  }

  // ==========================================================
  // LIST
  // ==========================================================

  static List<String> _readList(dynamic value) {
    if (value is! Iterable) {
      return const <String>[];
    }

    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  static String? _readNullableString(dynamic value) {
    final normalized = value?.toString().trim();

    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    return normalized;
  }
}
