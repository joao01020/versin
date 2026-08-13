import 'package:versin/modules/profile/models/music_role.dart';

// ============================================================
// CONNECTION TYPE
// ============================================================

enum ConnectionType {
  chat,
  video,
  proximity,
}

// ============================================================
// MATCH USER ENTITY
// ============================================================
//
// Entidade de usuário utilizada pelo módulo Match.
//
// Agora utiliza:
//
// MusicRole
//
// em vez do antigo:
//
// UserRole
//
// Isso permite suportar:
//
// - Artista
// - Beatmaker
// - Produtor
// - Compositor
// - Eng. de Mixagem
// - Eng. de Masterização
// - Eng. de Gravação
// - Instrumentista
// - Sound Designer
// - DJ
//
// ============================================================

class MatchUserEntity {
  // ============================================================
  // IDENTIDADE
  // ============================================================

  final String id;

  final String name;

  // ============================================================
  // PERFIL PROFISSIONAL
  // ============================================================

  /// Função principal do usuário.
  ///
  /// Exemplo:
  ///
  /// MusicRole.beatmaker
  final MusicRole? primaryRole;

  /// Todas as funções exercidas pelo usuário.
  ///
  /// Exemplo:
  ///
  /// [
  ///   MusicRole.beatmaker,
  ///   MusicRole.artist,
  /// ]
  final List<
    MusicRole
  >
  roles;

  /// Profissionais com quem este usuário deseja se conectar.
  ///
  /// Exemplo:
  ///
  /// [
  ///   MusicRole.artist,
  ///   MusicRole.composer,
  /// ]
  final List<
    MusicRole
  >
  lookingForRoles;

  // ============================================================
  // PERFIL
  // ============================================================

  final List<
    String
  >
  tags;

  final String bio;

  final String showcaseMediaUrl;

  final String showcaseDescription;

  // ============================================================
  // LOCALIZAÇÃO / STATUS
  // ============================================================

  final double distanceKm;

  final bool isOnline;

  // ============================================================
  // CONEXÃO
  // ============================================================

  final ConnectionType preferredConnection;

  // ============================================================
  // SESSÃO
  // ============================================================

  final DateTime? sessionStartedAt;

  final String? provisionalHash;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  const MatchUserEntity({
    required this.id,
    required this.name,
    required this.primaryRole,
    required this.roles,
    required this.lookingForRoles,
    required this.tags,
    required this.bio,
    required this.showcaseMediaUrl,
    required this.showcaseDescription,
    required this.distanceKm,
    required this.isOnline,
    this.preferredConnection = ConnectionType.proximity,
    this.sessionStartedAt,
    this.provisionalHash,
  });

  // ============================================================
  // LABEL DA FUNÇÃO PRINCIPAL
  // ============================================================

  String get primaryRoleLabel {
    return primaryRole?.label ??
        'Não informado';
  }

  // ============================================================
  // POSSUI FUNÇÃO PRINCIPAL
  // ============================================================

  bool get hasPrimaryRole {
    return primaryRole !=
        null;
  }

  // ============================================================
  // POSSUI FUNÇÕES
  // ============================================================

  bool get hasRoles {
    return roles.isNotEmpty;
  }

  // ============================================================
  // ESTÁ PROCURANDO PROFISSIONAIS
  // ============================================================

  bool get isLookingForProfessionals {
    return lookingForRoles.isNotEmpty;
  }

  // ============================================================
  // VERIFICAR SE EXERCE UMA FUNÇÃO
  // ============================================================

  bool hasRole(
    MusicRole role,
  ) {
    return roles.contains(
      role,
    );
  }

  // ============================================================
  // VERIFICAR SE PROCURA UMA FUNÇÃO
  // ============================================================

  bool isLookingFor(
    MusicRole role,
  ) {
    return lookingForRoles.contains(
      role,
    );
  }

  // ============================================================
  // COMPATIBILIDADE COM OUTRO USUÁRIO
  // ============================================================

  bool isInterestedIn(
    MatchUserEntity other,
  ) {
    for (final role in other.roles) {
      if (lookingForRoles.contains(
        role,
      )) {
        return true;
      }
    }

    return false;
  }

  // ============================================================
  // MATCH MÚTUO
  // ============================================================

  bool hasMutualInterestWith(
    MatchUserEntity other,
  ) {
    return isInterestedIn(
          other,
        ) &&
        other.isInterestedIn(
          this,
        );
  }

  // ============================================================
  // FUNÇÕES COMPATÍVEIS
  // ============================================================

  List<
    MusicRole
  >
  matchingRolesWith(
    MatchUserEntity other,
  ) {
    return other.roles
        .where(
          (
            role,
          ) => lookingForRoles.contains(
            role,
          ),
        )
        .toList();
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  MatchUserEntity copyWith({
    String? id,
    String? name,
    MusicRole? primaryRole,
    List<
      MusicRole
    >?
    roles,
    List<
      MusicRole
    >?
    lookingForRoles,
    List<
      String
    >?
    tags,
    String? bio,
    String? showcaseMediaUrl,
    String? showcaseDescription,
    double? distanceKm,
    bool? isOnline,
    ConnectionType? preferredConnection,
    DateTime? sessionStartedAt,
    String? provisionalHash,
  }) {
    return MatchUserEntity(
      id:
          id ??
          this.id,

      name:
          name ??
          this.name,

      primaryRole:
          primaryRole ??
          this.primaryRole,

      roles:
          roles ??
          this.roles,

      lookingForRoles:
          lookingForRoles ??
          this.lookingForRoles,

      tags:
          tags ??
          this.tags,

      bio:
          bio ??
          this.bio,

      showcaseMediaUrl:
          showcaseMediaUrl ??
          this.showcaseMediaUrl,

      showcaseDescription:
          showcaseDescription ??
          this.showcaseDescription,

      distanceKm:
          distanceKm ??
          this.distanceKm,

      isOnline:
          isOnline ??
          this.isOnline,

      preferredConnection:
          preferredConnection ??
          this.preferredConnection,

      sessionStartedAt:
          sessionStartedAt ??
          this.sessionStartedAt,

      provisionalHash:
          provisionalHash ??
          this.provisionalHash,
    );
  }

  // ============================================================
  // DEBUG
  // ============================================================

  @override
  String toString() {
    return 'MatchUserEntity('
        'id: $id, '
        'name: $name, '
        'primaryRole: ${primaryRole?.key}, '
        'roles: ${MusicRole.toKeys(roles)}, '
        'lookingForRoles: ${MusicRole.toKeys(lookingForRoles)}, '
        'isOnline: $isOnline'
        ')';
  }
}
