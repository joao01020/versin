class TransferRecipientModel {
  // ==========================================================
  // CAMPOS
  // ==========================================================

  final String userId;

  final String username;

  final String displayName;

  final String? avatarUrl;

  // ==========================================================
  // CONSTRUTOR
  // ==========================================================

  const TransferRecipientModel({
    required this.userId,
    required this.username,
    required this.displayName,
    this.avatarUrl,
  });

  // ==========================================================
  // USERNAME FORMATADO
  // ==========================================================

  String get formattedUsername {
    final normalized = username.trim().replaceFirst(
      RegExp(
        r'^@',
      ),
      '',
    );

    if (normalized.isEmpty) {
      return '';
    }

    return '@$normalized';
  }

  // ==========================================================
  // NOME PARA EXIBIÇÃO
  // ==========================================================

  String get displayLabel {
    final name = displayName.trim();

    if (name.isNotEmpty) {
      return name;
    }

    final normalizedUsername = username.trim().replaceFirst(
      RegExp(
        r'^@',
      ),
      '',
    );

    if (normalizedUsername.isNotEmpty) {
      return normalizedUsername;
    }

    return userId;
  }

  // ==========================================================
  // AVATAR
  // ==========================================================

  bool get hasAvatar {
    final value = avatarUrl?.trim();

    return value !=
            null &&
        value.isNotEmpty;
  }

  // ==========================================================
  // INICIAIS
  // ==========================================================

  String get initials {
    final name = displayLabel.trim();

    if (name.isEmpty) {
      return '?';
    }

    final parts = name
        .split(
          RegExp(
            r'\s+',
          ),
        )
        .where(
          (
            part,
          ) => part.isNotEmpty,
        )
        .toList();

    if (parts.isEmpty) {
      return '?';
    }

    if (parts.length ==
        1) {
      final value = parts.first;

      if (value.length ==
          1) {
        return value.toUpperCase();
      }

      return value
          .substring(
            0,
            2,
          )
          .toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  // ==========================================================
  // ID CURTO
  // ==========================================================

  String get shortUserId {
    final value = userId.trim();

    if (value.length <=
        14) {
      return value;
    }

    return '${value.substring(0, 8)}...'
        '${value.substring(value.length - 4)}';
  }

  // ==========================================================
  // VALIDAÇÃO
  // ==========================================================

  bool get isValid {
    return userId.trim().isNotEmpty &&
        username.trim().isNotEmpty;
  }

  // ==========================================================
  // FROM MAP
  // ==========================================================
  //
  // Compatível com uma tabela profiles semelhante a:
  //
  // id
  // username
  // display_name
  // avatar_url
  //
  // ==========================================================

  factory TransferRecipientModel.fromMap(
    Map<
      String,
      dynamic
    >
    map,
  ) {
    final userId =
        map['id']?.toString().trim() ??
        map['user_id']?.toString().trim() ??
        '';

    final username =
        map['username']?.toString().trim() ??
        '';

    final displayName =
        map['display_name']?.toString().trim() ??
        map['name']?.toString().trim() ??
        username;

    final rawAvatar = map['avatar_url']?.toString().trim();

    return TransferRecipientModel(
      userId: userId,
      username: username,
      displayName: displayName,
      avatarUrl:
          rawAvatar ==
                  null ||
              rawAvatar.isEmpty
          ? null
          : rawAvatar,
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
      'id': userId,
      'username': username,
      'display_name': displayName,
      'avatar_url': avatarUrl,
    };
  }

  // ==========================================================
  // COPY WITH
  // ==========================================================

  TransferRecipientModel copyWith({
    String? userId,
    String? username,
    String? displayName,
    String? avatarUrl,
    bool clearAvatarUrl = false,
  }) {
    return TransferRecipientModel(
      userId:
          userId ??
          this.userId,
      username:
          username ??
          this.username,
      displayName:
          displayName ??
          this.displayName,
      avatarUrl: clearAvatarUrl
          ? null
          : avatarUrl ??
                this.avatarUrl,
    );
  }

  // ==========================================================
  // COMPARAÇÃO POR USUÁRIO
  // ==========================================================

  bool isSameUser(
    String otherUserId,
  ) {
    return userId.trim() ==
        otherUserId.trim();
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
            is TransferRecipientModel &&
        other.userId ==
            userId;
  }

  @override
  int get hashCode => userId.hashCode;

  // ==========================================================
  // DEBUG
  // ==========================================================

  @override
  String toString() {
    return 'TransferRecipientModel('
        'userId: $userId, '
        'username: $username, '
        'displayName: $displayName'
        ')';
  }
}
