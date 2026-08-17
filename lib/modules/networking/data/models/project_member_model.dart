// ============================================================
// PROJECT MEMBER MODEL
// ============================================================
//
// Representa um participante de uma Studio Session.
//
// Os dados principais vêm de:
//
// public.profiles
//
// Campos usados:
//
// id
// username
// name
// artist_name
// primary_role
// roles
// avatar_url
// is_online
//
// ============================================================

class ProjectMemberModel {
  // ==========================================================
  // CAMPOS
  // ==========================================================

  final String id;

  final String username;

  final String name;

  final String artistName;

  final String primaryRole;

  final List<
    String
  >
  roles;

  final String? avatarUrl;

  final bool isOnline;

  // ==========================================================
  // CONSTRUTOR
  // ==========================================================

  const ProjectMemberModel({
    required this.id,
    required this.username,
    required this.name,
    required this.artistName,
    required this.primaryRole,
    required this.roles,
    required this.avatarUrl,
    required this.isOnline,
  });

  // ==========================================================
  // NOME PARA EXIBIÇÃO
  // ==========================================================

  String get displayName {
    final normalizedArtistName = artistName.trim();

    if (normalizedArtistName.isNotEmpty) {
      return normalizedArtistName;
    }

    final normalizedName = name.trim();

    if (normalizedName.isNotEmpty) {
      return normalizedName;
    }

    final normalizedUsername = username.trim();

    if (normalizedUsername.isNotEmpty) {
      return normalizedUsername;
    }

    return 'Usuário';
  }

  // ==========================================================
  // USERNAME COM @
  // ==========================================================

  String get usernameLabel {
    final normalized = username.trim().replaceFirst(
      RegExp(
        r'^@+',
      ),
      '',
    );

    if (normalized.isEmpty) {
      return '';
    }

    return '@$normalized';
  }

  // ==========================================================
  // FUNÇÃO PRINCIPAL
  // ==========================================================

  String get roleLabel {
    final normalizedPrimaryRole = primaryRole.trim();

    if (normalizedPrimaryRole.isNotEmpty) {
      return normalizedPrimaryRole;
    }

    if (roles.isNotEmpty) {
      return roles.first;
    }

    return 'Membro';
  }

  // ==========================================================
  // FROM MAP
  // ==========================================================

  factory ProjectMemberModel.fromMap(
    Map<
      String,
      dynamic
    >
    map,
  ) {
    return ProjectMemberModel(
      id:
          map['id']?.toString().trim() ??
          '',

      username:
          map['username']?.toString().trim() ??
          '',

      name:
          map['name']?.toString().trim() ??
          '',

      artistName:
          map['artist_name']?.toString().trim() ??
          '',

      primaryRole:
          map['primary_role']?.toString().trim() ??
          '',

      roles: _readStringList(
        map['roles'],
      ),

      avatarUrl: _readNullableString(
        map['avatar_url'],
      ),

      isOnline:
          map['is_online'] ==
          true,
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

      'username': username,

      'name': name,

      'artist_name': artistName,

      'primary_role': primaryRole,

      'roles': roles,

      'avatar_url': avatarUrl,

      'is_online': isOnline,
    };
  }

  // ==========================================================
  // COPY WITH
  // ==========================================================

  ProjectMemberModel copyWith({
    String? id,
    String? username,
    String? name,
    String? artistName,
    String? primaryRole,
    List<
      String
    >?
    roles,
    String? avatarUrl,
    bool? isOnline,
  }) {
    return ProjectMemberModel(
      id:
          id ??
          this.id,

      username:
          username ??
          this.username,

      name:
          name ??
          this.name,

      artistName:
          artistName ??
          this.artistName,

      primaryRole:
          primaryRole ??
          this.primaryRole,

      roles:
          roles ??
          this.roles,

      avatarUrl:
          avatarUrl ??
          this.avatarUrl,

      isOnline:
          isOnline ??
          this.isOnline,
    );
  }

  // ==========================================================
  // READ STRING LIST
  // ==========================================================

  static List<
    String
  >
  _readStringList(
    dynamic value,
  ) {
    if (value
        is! Iterable) {
      return const <
        String
      >[];
    }

    return value
        .map(
          (
            item,
          ) => item.toString().trim(),
        )
        .where(
          (
            item,
          ) => item.isNotEmpty,
        )
        .toList(
          growable: false,
        );
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
            is ProjectMemberModel &&
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
    return 'ProjectMemberModel('
        'id: $id, '
        'username: $username, '
        'displayName: $displayName, '
        'role: $roleLabel'
        ')';
  }
}
