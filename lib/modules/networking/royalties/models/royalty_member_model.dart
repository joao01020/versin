// ============================================================
// ROYALTY MEMBER MODEL
// ============================================================
//
// Representa um participante ATUAL do projeto dentro do módulo
// de royalties.
//
// É usado para montar uma nova proposta.
//
// Não representa diretamente uma linha da tabela
// royalty_shares.
//
// Os dados podem vir de:
//
// - projects;
// - profiles;
// - Match;
// - membership;
// - função/habilidade profissional.
//
// ============================================================

class RoyaltyMemberModel {
  final String userId;

  final String displayName;

  final String? username;

  final String? avatarUrl;

  final String role;

  final bool isFounder;

  const RoyaltyMemberModel({
    required this.userId,
    required this.displayName,
    required this.role,
    this.username,
    this.avatarUrl,
    this.isFounder = false,
  });

  // ============================================================
  // FROM MAP
  // ============================================================
  //
  // Este parser aceita alguns aliases porque consultas com
  // joins do Supabase podem devolver nomes diferentes.
  //
  // ============================================================

  factory RoyaltyMemberModel.fromMap(
    Map<
      String,
      dynamic
    >
    map,
  ) {
    final profile = _mapValue(
      map['profile'],
    );

    final userId = _firstString(
      [
        map['user_id'],
        map['id'],
        profile?['user_id'],
        profile?['id'],
      ],
    );

    final displayName = _firstString(
      [
        map['display_name'],
        map['name'],
        map['full_name'],
        profile?['display_name'],
        profile?['name'],
        profile?['full_name'],
      ],
    );

    final username = _firstNullableString(
      [
        map['username'],
        profile?['username'],
      ],
    );

    final avatarUrl = _firstNullableString(
      [
        map['avatar_url'],
        profile?['avatar_url'],
      ],
    );

    final role = _firstString(
      [
        map['role'],
        map['skill'],
        map['professional_role'],
        map['match_role'],
        profile?['role'],
        profile?['skill'],
        profile?['professional_role'],
      ],
    );

    return RoyaltyMemberModel(
      userId: userId,
      displayName: displayName.isEmpty
          ? username ??
                'Participante'
          : displayName,
      username: username,
      avatarUrl: avatarUrl,
      role: role.isEmpty
          ? 'Membro'
          : role,
      isFounder: _boolValue(
        map['is_founder'],
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
      'user_id': userId,
      'display_name': displayName,
      'username': username,
      'avatar_url': avatarUrl,
      'role': role,
      'is_founder': isFounder,
    };
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  RoyaltyMemberModel copyWith({
    String? userId,
    String? displayName,
    String? username,
    bool clearUsername = false,
    String? avatarUrl,
    bool clearAvatarUrl = false,
    String? role,
    bool? isFounder,
  }) {
    return RoyaltyMemberModel(
      userId:
          userId ??
          this.userId,
      displayName:
          displayName ??
          this.displayName,
      username: clearUsername
          ? null
          : username ??
                this.username,
      avatarUrl: clearAvatarUrl
          ? null
          : avatarUrl ??
                this.avatarUrl,
      role:
          role ??
          this.role,
      isFounder:
          isFounder ??
          this.isFounder,
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String get initial {
    final normalized = displayName.trim();

    if (normalized.isEmpty) {
      return '?';
    }

    return normalized
        .substring(
          0,
          1,
        )
        .toUpperCase();
  }

  String get formattedUsername {
    final normalized =
        username?.trim() ??
        '';

    if (normalized.isEmpty) {
      return '';
    }

    if (normalized.startsWith(
      '@',
    )) {
      return normalized;
    }

    return '@$normalized';
  }

  bool get hasAvatar {
    return avatarUrl?.trim().isNotEmpty ==
        true;
  }

  bool get hasRole {
    return role.trim().isNotEmpty;
  }

  // ============================================================
  // MAP
  // ============================================================

  static Map<
    String,
    dynamic
  >?
  _mapValue(
    dynamic value,
  ) {
    if (value
        is Map<
          String,
          dynamic
        >) {
      return value;
    }

    if (value
        is Map) {
      return Map<
        String,
        dynamic
      >.from(
        value,
      );
    }

    return null;
  }

  // ============================================================
  // FIRST STRING
  // ============================================================

  static String _firstString(
    List<
      dynamic
    >
    values,
  ) {
    for (final value in values) {
      final normalized =
          value?.toString().trim() ??
          '';

      if (normalized.isNotEmpty) {
        return normalized;
      }
    }

    return '';
  }

  // ============================================================
  // FIRST NULLABLE STRING
  // ============================================================

  static String? _firstNullableString(
    List<
      dynamic
    >
    values,
  ) {
    final value = _firstString(
      values,
    );

    if (value.isEmpty) {
      return null;
    }

    return value;
  }

  // ============================================================
  // BOOL
  // ============================================================

  static bool _boolValue(
    dynamic value,
  ) {
    if (value
        is bool) {
      return value;
    }

    if (value
        is num) {
      return value !=
          0;
    }

    switch (value?.toString().trim().toLowerCase()) {
      case 'true':
      case '1':
      case 'yes':
        return true;

      default:
        return false;
    }
  }
}
