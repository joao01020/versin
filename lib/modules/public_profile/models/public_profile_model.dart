// ============================================================
// PUBLIC PROFILE MODEL
// ============================================================
//
// Representa os dados públicos do perfil profissional.
//
// Banco:
//
// public.profiles
//
// Responsabilidades:
//
// - armazenar dados do perfil público;
// - converter Map -> Model;
// - converter Model -> Map;
// - controlar is_online;
// - fornecer helpers de apresentação;
// - permitir cópias imutáveis.
//
// NÃO:
//
// - acessa Supabase;
// - acessa Cloudflare R2;
// - faz upload;
// - controla UI;
// - executa navegação;
// - possui regras de Match;
// - armazena músicas.
//
// As músicas ficam em:
//
// public.profile_tracks
//
// ============================================================

class PublicProfileModel {
  // ============================================================
  // IDENTIDADE
  // ============================================================

  final String userId;

  final String username;

  final String displayName;

  final String? avatarUrl;

  // ============================================================
  // PERFIL
  // ============================================================

  final String bio;

  // ============================================================
  // STATUS / VISIBILIDADE
  // ============================================================
  //
  // true:
  //
  // - perfil visível;
  // - pode aparecer no Match;
  // - pode aparecer em buscas públicas.
  //
  // false:
  //
  // - perfil fica offline;
  // - deve ser ignorado pelo Discovery;
  // - continua acessível pelo próprio dono.
  //
  // A filtragem real de outros usuários é responsabilidade
  // do repository/datasource do Match.
  //
  // ============================================================

  final bool isOnline;

  // ============================================================
  // DATAS
  // ============================================================

  final DateTime? createdAt;

  final DateTime? updatedAt;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  const PublicProfileModel({
    required this.userId,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    this.bio = '',
    this.isOnline = false,
    this.createdAt,
    this.updatedAt,
  });

  // ============================================================
  // EMPTY
  // ============================================================

  factory PublicProfileModel.empty({
    required String userId,
  }) {
    return PublicProfileModel(
      userId: userId.trim(),
      username: '',
      displayName: '',
      bio: '',
      isOnline: false,
    );
  }

  // ============================================================
  // GETTERS
  // ============================================================

  bool get hasUserId => userId.trim().isNotEmpty;

  bool get hasAvatar =>
      avatarUrl?.trim().isNotEmpty ==
      true;

  bool get hasBio => bio.trim().isNotEmpty;

  bool get hasUsername => username.trim().isNotEmpty;

  bool get hasDisplayName => displayName.trim().isNotEmpty;

  bool get isEmpty =>
      !hasUsername &&
      !hasDisplayName &&
      !hasBio &&
      !hasAvatar;

  bool get isComplete =>
      hasUserId &&
      hasUsername &&
      hasDisplayName;

  // ============================================================
  // VISIBILIDADE
  // ============================================================

  bool get isOffline => !isOnline;

  String get onlineStatusLabel => isOnline
      ? 'ONLINE'
      : 'OFFLINE';

  // ============================================================
  // USERNAME
  // ============================================================

  String get usernameLabel {
    final normalizedUsername = username.trim();

    if (normalizedUsername.isEmpty) {
      return '';
    }

    if (normalizedUsername.startsWith(
      '@',
    )) {
      return normalizedUsername;
    }

    return '@$normalizedUsername';
  }

  // ============================================================
  // DISPLAY NAME
  // ============================================================

  String get resolvedDisplayName {
    final normalizedDisplayName = displayName.trim();

    if (normalizedDisplayName.isNotEmpty) {
      return normalizedDisplayName;
    }

    final normalizedUsername = username.trim();

    if (normalizedUsername.isNotEmpty) {
      return normalizedUsername;
    }

    return 'Usuário';
  }

  // ============================================================
  // INITIALS
  // ============================================================

  String get initials {
    final normalizedName = resolvedDisplayName.trim();

    if (normalizedName.isEmpty) {
      return '?';
    }

    final parts = normalizedName
        .split(
          RegExp(
            r'\s+',
          ),
        )
        .where(
          (
            part,
          ) {
            return part.isNotEmpty;
          },
        )
        .toList();

    if (parts.isEmpty) {
      return '?';
    }

    if (parts.length ==
        1) {
      return parts.first
          .substring(
            0,
            1,
          )
          .toUpperCase();
    }

    final first = parts.first.substring(
      0,
      1,
    );

    final last = parts.last.substring(
      0,
      1,
    );

    return '$first$last'.toUpperCase();
  }

  // ============================================================
  // BIO RESUMIDA
  // ============================================================

  String get shortBio {
    final normalizedBio = bio.trim();

    if (normalizedBio.length <=
        160) {
      return normalizedBio;
    }

    return '${normalizedBio.substring(0, 157)}...';
  }

  // ============================================================
  // FROM MAP
  // ============================================================
  //
  // Compatível com:
  //
  // public.profiles
  //
  // Prioridade para nome público:
  //
  // 1. artist_name
  // 2. name
  // 3. username
  //
  // ============================================================

  factory PublicProfileModel.fromMap(
    Map<
      String,
      dynamic
    >
    map,
  ) {
    final artistName = _readString(
      map['artist_name'],
    );

    final name = _readString(
      map['name'],
    );

    final username = _readString(
      map['username'],
    );

    final resolvedName = artistName.isNotEmpty
        ? artistName
        : name.isNotEmpty
        ? name
        : username;

    return PublicProfileModel(
      userId: _readString(
        map['id'],
      ),

      username: username,

      displayName: resolvedName,

      avatarUrl: _readNullableString(
        map['avatar_url'],
      ),

      bio: _readString(
        map['bio'],
      ),

      isOnline: _readBool(
        map['is_online'],
      ),

      createdAt: _readDateTime(
        map['created_at'],
      ),

      updatedAt: _readDateTime(
        map['updated_at'],
      ),
    );
  }

  // ============================================================
  // TO MAP
  // ============================================================
  //
  // Representação completa.
  //
  // ============================================================

  Map<
    String,
    dynamic
  >
  toMap() {
    return {
      'id': userId.trim(),

      'username': username.trim(),

      'artist_name': displayName.trim(),

      'avatar_url': _normalizeNullableString(
        avatarUrl,
      ),

      'bio': bio.trim(),

      'is_online': isOnline,

      if (createdAt !=
          null)
        'created_at': createdAt!.toUtc().toIso8601String(),

      if (updatedAt !=
          null)
        'updated_at': updatedAt!.toUtc().toIso8601String(),
    };
  }

  // ============================================================
  // TO UPDATE MAP
  // ============================================================
  //
  // Utilizado tanto para:
  //
  // - editar perfil;
  // - mudar ONLINE / OFFLINE.
  //
  // Agora is_online também é persistido.
  //
  // NÃO envia:
  //
  // - id;
  // - created_at.
  //
  // ============================================================

  Map<
    String,
    dynamic
  >
  toUpdateMap() {
    return {
      'username': username.trim(),

      'artist_name': displayName.trim(),

      'avatar_url': _normalizeNullableString(
        avatarUrl,
      ),

      'bio': bio.trim(),

      // ========================================================
      // VISIBILIDADE
      // ========================================================
      'is_online': isOnline,

      // ========================================================
      // UPDATED AT
      // ========================================================
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  // ============================================================
  // MAP SOMENTE DO STATUS
  // ============================================================
  //
  // Útil se posteriormente quisermos atualizar apenas:
  //
  // is_online
  //
  // sem enviar nome, bio ou avatar.
  //
  // ============================================================

  Map<
    String,
    dynamic
  >
  toOnlineStatusMap() {
    return {
      'is_online': isOnline,

      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  PublicProfileModel copyWith({
    String? userId,
    String? username,
    String? displayName,
    String? avatarUrl,
    bool clearAvatar = false,
    String? bio,
    bool? isOnline,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PublicProfileModel(
      userId:
          userId ??
          this.userId,

      username:
          username ??
          this.username,

      displayName:
          displayName ??
          this.displayName,

      avatarUrl: clearAvatar
          ? null
          : avatarUrl ??
                this.avatarUrl,

      bio:
          bio ??
          this.bio,

      isOnline:
          isOnline ??
          this.isOnline,

      createdAt:
          createdAt ??
          this.createdAt,

      updatedAt:
          updatedAt ??
          this.updatedAt,
    );
  }

  // ============================================================
  // COPY ONLINE
  // ============================================================

  PublicProfileModel copyWithOnline(
    bool value,
  ) {
    return copyWith(
      isOnline: value,

      updatedAt: DateTime.now(),
    );
  }

  // ============================================================
  // READ STRING
  // ============================================================

  static String _readString(
    dynamic value,
  ) {
    if (value ==
        null) {
      return '';
    }

    return value.toString().trim();
  }

  // ============================================================
  // READ NULLABLE STRING
  // ============================================================

  static String? _readNullableString(
    dynamic value,
  ) {
    final normalized = _readString(
      value,
    );

    if (normalized.isEmpty) {
      return null;
    }

    return normalized;
  }

  // ============================================================
  // NORMALIZE NULLABLE STRING
  // ============================================================

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

  // ============================================================
  // READ BOOL
  // ============================================================

  static bool _readBool(
    dynamic value,
  ) {
    if (value ==
        null) {
      return false;
    }

    if (value
        is bool) {
      return value;
    }

    if (value
        is num) {
      return value !=
          0;
    }

    final normalized = value.toString().trim().toLowerCase();

    return normalized ==
            'true' ||
        normalized ==
            '1';
  }

  // ============================================================
  // READ DATETIME
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
  // DEBUG
  // ============================================================

  @override
  String toString() {
    return 'PublicProfileModel('
        'userId: $userId, '
        'username: $username, '
        'displayName: $displayName, '
        'hasAvatar: $hasAvatar, '
        'hasBio: $hasBio, '
        'isOnline: $isOnline'
        ')';
  }
}
