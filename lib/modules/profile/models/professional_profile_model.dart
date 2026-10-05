import 'package:versin/modules/profile/models/music_role.dart';

// ============================================================
// PROFESSIONAL PROFILE MODEL
// ============================================================
//
// Representa o perfil profissional musical do usuário.
//
// Responsabilidades:
//
// - armazenar as funções que o usuário exerce;
// - armazenar a função profissional principal;
// - armazenar os profissionais que ele procura;
// - converter dados vindos do Supabase;
// - fornecer dados prontos para Controller e Match.
//
// Este Model NÃO acessa:
//
// - Supabase;
// - SQLite;
// - Repository;
// - Controller;
// - interface.
//
// Estrutura correspondente no Supabase:
//
// primary_role
// roles
// looking_for_roles
//
// Exemplo:
//
// primary_role:
// beatmaker
//
// roles:
// {beatmaker,artist}
//
// looking_for_roles:
// {artist,composer,mix_engineer}
//
// ============================================================

class ProfessionalProfileModel {
  // ============================================================
  // CAMPOS
  // ============================================================

  /// Todas as funções profissionais exercidas pelo usuário.
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

  /// Função profissional principal.
  ///
  /// É essa função que será exibida no Dashboard.
  ///
  /// Pode ser null caso o usuário ainda não tenha configurado
  /// seu perfil profissional.
  final MusicRole? primaryRole;

  /// Profissionais com quem o usuário deseja se conectar.
  ///
  /// Exemplo:
  ///
  /// [
  ///   MusicRole.artist,
  ///   MusicRole.composer,
  ///   MusicRole.mixEngineer,
  /// ]
  final List<
    MusicRole
  >
  lookingForRoles;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  const ProfessionalProfileModel({
    this.roles = const [],
    this.primaryRole,
    this.lookingForRoles = const [],
  });

  // ============================================================
  // PERFIL VAZIO
  // ============================================================

  factory ProfessionalProfileModel.empty() {
    return const ProfessionalProfileModel();
  }

  // ============================================================
  // CRIAR A PARTIR DO SUPABASE
  // ============================================================
  //
  // Espera dados no formato:
  //
  // {
  //   'primary_role': 'beatmaker',
  //
  //   'roles': [
  //     'beatmaker',
  //     'artist',
  //   ],
  //
  //   'looking_for_roles': [
  //     'artist',
  //     'composer',
  //   ],
  // }
  //
  // ============================================================

  factory ProfessionalProfileModel.fromMap(
    Map<
      String,
      dynamic
    >
    map,
  ) {
    // ==========================================================
    // ROLES
    // ==========================================================

    final roles = MusicRole.fromKeys(
      _readList(
        map['roles'],
      ),
    );

    // ==========================================================
    // FUNÇÃO PRINCIPAL
    // ==========================================================

    final primaryRole = MusicRole.fromKey(
      map['primary_role']?.toString(),
    );

    // ==========================================================
    // QUEM O USUÁRIO PROCURA
    // ==========================================================

    final lookingForRoles = MusicRole.fromKeys(
      _readList(
        map['looking_for_roles'],
      ),
    );

    return ProfessionalProfileModel(
      roles: roles,
      primaryRole: primaryRole,
      lookingForRoles: lookingForRoles,
    );
  }

  // ============================================================
  // CONVERTER PARA MAP
  // ============================================================
  //
  // Gera estrutura compatível com o Supabase.
  //
  // Exemplo:
  //
  // {
  //   'primary_role': 'beatmaker',
  //   'roles': ['beatmaker', 'artist'],
  //   'looking_for_roles': ['artist', 'composer'],
  // }
  //
  // ============================================================

  Map<
    String,
    dynamic
  >
  toMap() {
    return {
      'primary_role': primaryRole?.key,

      'roles': MusicRole.toKeys(
        roles,
      ),

      'looking_for_roles': MusicRole.toKeys(
        lookingForRoles,
      ),
    };
  }

  // ============================================================
  // COPY WITH
  // ============================================================
  //
  // Permite criar uma nova versão do perfil sem modificar
  // diretamente a instância atual.
  //
  // Exemplo:
  //
  // final updated = profile.copyWith(
  //   primaryRole: MusicRole.artist,
  // );
  //
  // ============================================================

  ProfessionalProfileModel copyWith({
    List<
      MusicRole
    >?
    roles,
    MusicRole? primaryRole,
    List<
      MusicRole
    >?
    lookingForRoles,
  }) {
    return ProfessionalProfileModel(
      roles:
          roles ??
          this.roles,

      primaryRole:
          primaryRole ??
          this.primaryRole,

      lookingForRoles:
          lookingForRoles ??
          this.lookingForRoles,
    );
  }

  // ============================================================
  // POSSUI FUNÇÕES
  // ============================================================

  bool get hasRoles {
    return roles.isNotEmpty;
  }

  // ============================================================
  // POSSUI FUNÇÃO PRINCIPAL
  // ============================================================

  bool get hasPrimaryRole {
    return primaryRole !=
        null;
  }

  // ============================================================
  // ESTÁ PROCURANDO PROFISSIONAIS
  // ============================================================

  bool get isLookingForProfessionals {
    return lookingForRoles.isNotEmpty;
  }

  // ============================================================
  // PERFIL PROFISSIONAL CONFIGURADO
  // ============================================================
  //
  // Consideramos configurado quando:
  //
  // - possui pelo menos uma função;
  // - possui uma função principal;
  // - a função principal pertence às funções selecionadas.
  //
  // ============================================================

  bool get isConfigured {
    final currentPrimaryRole = primaryRole;

    if (currentPrimaryRole ==
        null) {
      return false;
    }

    return roles.contains(
      currentPrimaryRole,
    );
  }

  // ============================================================
  // LABEL DA FUNÇÃO PRINCIPAL
  // ============================================================
  //
  // Usado pelo Dashboard.
  //
  // Exemplo:
  //
  // beatmaker
  //      ↓
  // Beatmaker
  //
  // ============================================================

  String get primaryRoleLabel {
    return primaryRole?.label ??
        'Não informado';
  }

  // ============================================================
  // LABELS DAS FUNÇÕES
  // ============================================================

  List<
    String
  >
  get roleLabels {
    return MusicRole.toLabels(
      roles,
    );
  }

  // ============================================================
  // LABELS DOS PROFISSIONAIS PROCURADOS
  // ============================================================

  List<
    String
  >
  get lookingForRoleLabels {
    return MusicRole.toLabels(
      lookingForRoles,
    );
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
  // COMPATIBILIDADE BÁSICA
  // ============================================================
  //
  // Verifica se este usuário procura pelo menos uma função
  // exercida pelo outro usuário.
  //
  // Exemplo:
  //
  // Astryvo procura:
  //
  // artist
  //
  // Outro usuário exerce:
  //
  // artist
  //
  // Resultado:
  //
  // true
  //
  // ============================================================

  bool isInterestedIn(
    ProfessionalProfileModel other,
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
  //
  // A procura alguma função de B
  //
  // E
  //
  // B procura alguma função de A.
  //
  // Exemplo:
  //
  // Beatmaker
  // procura Artist
  //
  // Artist
  // procura Beatmaker
  //
  // Resultado:
  //
  // true
  //
  // ============================================================

  bool hasMutualInterestWith(
    ProfessionalProfileModel other,
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
  //
  // Retorna quais funções do outro usuário são procuradas
  // por este perfil.
  //
  // ============================================================

  List<
    MusicRole
  >
  matchingRolesWith(
    ProfessionalProfileModel other,
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
  // NORMALIZAR LISTA
  // ============================================================
  //
  // O Supabase normalmente retorna arrays PostgreSQL como List.
  //
  // Este método deixa o Model mais resistente caso o valor
  // esteja ausente ou venha em outro Iterable.
  //
  // ============================================================

  static Iterable<
    dynamic
  >
  _readList(
    dynamic value,
  ) {
    if (value ==
        null) {
      return const [];
    }

    if (value
        is Iterable) {
      return value;
    }

    return const [];
  }

  // ============================================================
  // DEBUG
  // ============================================================

  @override
  String toString() {
    return 'ProfessionalProfileModel('
        'roles: ${MusicRole.toKeys(roles)}, '
        'primaryRole: ${primaryRole?.key}, '
        'lookingForRoles: ${MusicRole.toKeys(lookingForRoles)}'
        ')';
  }
}
