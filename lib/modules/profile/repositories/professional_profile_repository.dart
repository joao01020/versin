import 'package:versin/modules/profile/models/professional_profile_model.dart';

// ============================================================
// PROFESSIONAL PROFILE REPOSITORY
// ============================================================
//
// Contrato responsável pelas operações do perfil profissional.
//
// Esta camada NÃO conhece:
//
// - Supabase;
// - SQLite;
// - API;
// - implementação de persistência.
//
// O Controller depende somente deste contrato.
//
// Fluxo:
//
// View / Dashboard
//        ↓
// ProfessionalProfileController
//        ↓
// ProfessionalProfileRepository
//        ↓
// ProfessionalProfileRepositoryImpl
//        ↓
// ProfessionalProfileRemoteDatasource
//        ↓
// Supabase
//
// ============================================================

abstract class ProfessionalProfileRepository {
  // ==========================================================
  // BUSCAR PERFIL PROFISSIONAL
  // ==========================================================
  //
  // Busca todas as informações profissionais do usuário
  // autenticado em uma única operação.
  //
  // Retorna:
  //
  // ProfessionalProfileModel
  //
  // contendo:
  //
  // roles
  // → todas as funções exercidas pelo usuário.
  //
  // primaryRole
  // → profissão principal exibida no Dashboard.
  //
  // lookingForRoles
  // → profissionais com quem o usuário deseja se conectar.
  //
  // Exemplo:
  //
  // ProfessionalProfileModel(
  //   roles: [
  //     MusicRole.beatmaker,
  //     MusicRole.artist,
  //   ],
  //
  //   primaryRole:
  //     MusicRole.beatmaker,
  //
  //   lookingForRoles: [
  //     MusicRole.artist,
  //     MusicRole.composer,
  //     MusicRole.mixEngineer,
  //   ],
  // )
  //
  // ==========================================================

  Future<
    ProfessionalProfileModel
  >
  getProfessionalProfile();

  // ==========================================================
  // SALVAR PERFIL PROFISSIONAL
  // ==========================================================
  //
  // Salva o perfil profissional completo.
  //
  // O Model contém:
  //
  // roles
  // → o que o usuário faz.
  //
  // primaryRole
  // → profissão principal.
  //
  // lookingForRoles
  // → quem o usuário procura para se conectar.
  //
  // ==========================================================

  Future<
    void
  >
  saveProfessionalProfile(
    ProfessionalProfileModel profile,
  );
}
