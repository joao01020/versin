import 'package:versin/modules/profile/data/datasources/professional_profile_remote_datasource.dart';
import 'package:versin/modules/profile/models/professional_profile_model.dart';
import 'package:versin/modules/profile/repositories/professional_profile_repository.dart';

// ============================================================
// PROFESSIONAL PROFILE REPOSITORY IMPLEMENTATION
// ============================================================
//
// Implementação concreta do:
//
// ProfessionalProfileRepository
//
// Responsabilidades:
//
// - receber operações vindas do Controller;
// - validar regras básicas do perfil profissional;
// - normalizar os dados;
// - encaminhar os dados para o Datasource;
// - manter o Controller independente do Supabase.
//
// Esta camada NÃO acessa diretamente:
//
// - Supabase;
// - SQLite;
// - interface.
//
// Fluxo:
//
// ProfessionalProfileSettingsPage
//              ↓
// ProfessionalProfileController
//              ↓
// ProfessionalProfileRepository
//              ↓
// ProfessionalProfileRepositoryImpl
//              ↓
// ProfessionalProfileRemoteDatasource
//              ↓
// Supabase
//
// ============================================================

class ProfessionalProfileRepositoryImpl
    implements
        ProfessionalProfileRepository {
  // ============================================================
  // DEPENDÊNCIAS
  // ============================================================

  final ProfessionalProfileRemoteDatasource _remoteDatasource;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  ProfessionalProfileRepositoryImpl({
    ProfessionalProfileRemoteDatasource? remoteDatasource,
  }) : _remoteDatasource =
           remoteDatasource ??
           ProfessionalProfileRemoteDatasourceImpl();

  // ============================================================
  // BUSCAR PERFIL PROFISSIONAL
  // ============================================================
  //
  // Busca em uma única operação:
  //
  // - roles;
  // - primary_role;
  // - looking_for_roles.
  //
  // O Datasource devolve um ProfessionalProfileModel pronto.
  //
  // ============================================================

  @override
  Future<
    ProfessionalProfileModel
  >
  getProfessionalProfile() async {
    return await _remoteDatasource.getProfessionalProfile();
  }

  // ============================================================
  // SALVAR PERFIL PROFISSIONAL
  // ============================================================

  @override
  Future<
    void
  >
  saveProfessionalProfile(
    ProfessionalProfileModel profile,
  ) async {
    // ==========================================================
    // NORMALIZAR FUNÇÕES DO USUÁRIO
    // ==========================================================

    final normalizedRoles = profile.roles.toSet().toList();

    // ==========================================================
    // NORMALIZAR PROFISSIONAIS PROCURADOS
    // ==========================================================

    final normalizedLookingForRoles = profile.lookingForRoles.toSet().toList();

    // ==========================================================
    // FUNÇÃO PRINCIPAL
    // ==========================================================

    final primaryRole = profile.primaryRole;

    // ==========================================================
    // VALIDAR FUNÇÕES
    // ==========================================================

    if (normalizedRoles.isEmpty) {
      throw ArgumentError(
        'É necessário informar pelo menos uma função profissional.',
      );
    }

    // ==========================================================
    // VALIDAR FUNÇÃO PRINCIPAL
    // ==========================================================

    if (primaryRole ==
        null) {
      throw ArgumentError(
        'É necessário informar uma função profissional principal.',
      );
    }

    if (!normalizedRoles.contains(
      primaryRole,
    )) {
      throw ArgumentError(
        'A função principal precisa estar entre as funções selecionadas.',
      );
    }

    // ==========================================================
    // CRIAR PERFIL NORMALIZADO
    // ==========================================================
    //
    // Criamos uma nova instância para garantir que arrays
    // duplicados não sejam enviados para o banco.
    //
    // Exemplo:
    //
    // roles:
    //
    // [
    //   beatmaker,
    //   beatmaker,
    //   artist
    // ]
    //
    // passa a ser:
    //
    // [
    //   beatmaker,
    //   artist
    // ]
    //
    // O mesmo acontece com lookingForRoles.
    //
    // ==========================================================

    final normalizedProfile = ProfessionalProfileModel(
      roles: normalizedRoles,
      primaryRole: primaryRole,
      lookingForRoles: normalizedLookingForRoles,
    );

    // ==========================================================
    // SALVAR NO DATASOURCE
    // ==========================================================

    await _remoteDatasource.saveProfessionalProfile(
      normalizedProfile,
    );
  }
}
