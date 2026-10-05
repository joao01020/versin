// ============================================================
// PROJECT TASK MEMBER MODEL
// ============================================================
//
// Representa um participante do projeto dentro do módulo
// de produção / tarefas.
//
// IMPORTANTE:
//
// Este model NÃO representa a contribuição.
//
// Uma pessoa pode estar no projeto e ainda não ter definido
// o que fará.
//
// Exemplo:
//
// João
// Produtor
// contribuição: null
//
// Isso permite que um projeto recém-criado comece realmente
// zerado.
//
// ============================================================

class ProjectTaskMemberModel {
  // ============================================================
  // IDENTIDADE
  // ============================================================

  final String userId;

  // ============================================================
  // APRESENTAÇÃO
  // ============================================================

  final String displayName;

  final String? username;

  final String? avatarUrl;

  // ============================================================
  // PERFIL PROFISSIONAL
  // ============================================================
  //
  // Deve refletir a função/habilidade usada no Match.
  //
  // Exemplos:
  //
  // Artista
  // Produtor
  // Beatmaker
  // Compositor
  //
  // ============================================================

  final String professionalRole;

  // ============================================================
  // PROJETO
  // ============================================================

  final bool isFounder;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  const ProjectTaskMemberModel({
    required this.userId,
    required this.displayName,
    required this.professionalRole,
    this.username,
    this.avatarUrl,
    this.isFounder = false,
  });

  // ============================================================
  // COPY WITH
  // ============================================================

  ProjectTaskMemberModel copyWith({
    String? userId,
    String? displayName,
    String? username,
    String? avatarUrl,
    String? professionalRole,
    bool? isFounder,
  }) {
    return ProjectTaskMemberModel(
      userId:
          userId ??
          this.userId,
      displayName:
          displayName ??
          this.displayName,
      username:
          username ??
          this.username,
      avatarUrl:
          avatarUrl ??
          this.avatarUrl,
      professionalRole:
          professionalRole ??
          this.professionalRole,
      isFounder:
          isFounder ??
          this.isFounder,
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  bool get hasDisplayName {
    return displayName.trim().isNotEmpty;
  }

  bool get hasUsername {
    return username?.trim().isNotEmpty ==
        true;
  }

  bool get hasAvatar {
    return avatarUrl?.trim().isNotEmpty ==
        true;
  }

  bool get hasProfessionalRole {
    return professionalRole.trim().isNotEmpty;
  }

  String get resolvedDisplayName {
    final normalizedName = displayName.trim();

    if (normalizedName.isNotEmpty) {
      return normalizedName;
    }

    final normalizedUsername =
        username?.trim() ??
        '';

    if (normalizedUsername.isNotEmpty) {
      return normalizedUsername.startsWith(
            '@',
          )
          ? normalizedUsername
          : '@$normalizedUsername';
    }

    return 'Usuário';
  }

  String get resolvedProfessionalRole {
    final normalized = professionalRole.trim();

    if (normalized.isNotEmpty) {
      return normalized;
    }

    return 'Profissional';
  }

  String get initials {
    final name = resolvedDisplayName
        .replaceFirst(
          '@',
          '',
        )
        .trim();

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
      return parts.first
          .substring(
            0,
            1,
          )
          .toUpperCase();
    }

    final first = parts.first
        .substring(
          0,
          1,
        )
        .toUpperCase();

    final last = parts.last
        .substring(
          0,
          1,
        )
        .toUpperCase();

    return '$first$last';
  }

  // ============================================================
  // EQUALITY
  // ============================================================

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
            is ProjectTaskMemberModel &&
        other.userId ==
            userId;
  }

  @override
  int get hashCode => userId.hashCode;

  // ============================================================
  // TO STRING
  // ============================================================

  @override
  String toString() {
    return 'ProjectTaskMemberModel('
        'userId: $userId, '
        'displayName: $displayName, '
        'professionalRole: $professionalRole, '
        'isFounder: $isFounder'
        ')';
  }
}
