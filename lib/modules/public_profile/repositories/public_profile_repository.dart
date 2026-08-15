import '../models/profile_track_model.dart';
import '../models/public_profile_model.dart';

// ============================================================
// PUBLIC PROFILE REPOSITORY
// ============================================================
//
// Contrato principal do módulo Public Profile.
//
// O Controller conhece apenas este contrato.
//
// Implementações podem usar:
//
// - Supabase;
// - API;
// - banco local;
// - cache;
//
// sem alterar o Controller.
//
// Responsabilidades:
//
// - carregar perfil;
// - atualizar perfil;
// - alterar visibilidade ONLINE / OFFLINE;
// - carregar demos;
// - criar demos;
// - atualizar demos;
// - remover demos;
// - acompanhar demos em realtime.
//
// ============================================================

abstract class PublicProfileRepository {
  // ============================================================
  // PERFIL
  // ============================================================

  Future<
    PublicProfileModel?
  >
  getProfile({
    required String userId,
  });

  // ============================================================
  // ATUALIZAR PERFIL
  // ============================================================
  //
  // Usado para:
  //
  // - nome;
  // - username;
  // - avatar;
  // - bio;
  // - demais campos editáveis do perfil.
  //
  // ============================================================

  Future<
    PublicProfileModel
  >
  updateProfile({
    required PublicProfileModel profile,
  });

  // ============================================================
  // ATUALIZAR VISIBILIDADE
  // ============================================================
  //
  // Atualiza somente:
  //
  // public.profiles.is_online
  //
  // true:
  //
  // - perfil ONLINE;
  // - pode aparecer no Match;
  // - pode aparecer em Discovery;
  // - pode aparecer em buscas públicas.
  //
  // false:
  //
  // - perfil OFFLINE;
  // - deve ser ocultado para outros usuários;
  // - o próprio dono continua podendo acessar o perfil.
  //
  // ============================================================

  Future<
    PublicProfileModel
  >
  updateOnlineStatus({
    required String userId,
    required bool isOnline,
  });

  // ============================================================
  // TRACKS
  // ============================================================

  Future<
    List<
      ProfileTrackModel
    >
  >
  getTracks({
    required String userId,
    bool onlyActive = true,
  });

  // ============================================================
  // PRIMEIRA DEMO
  // ============================================================
  //
  // Usado principalmente pelo Match:
  //
  // OUVIR DEMO
  //
  // Retorna null quando o usuário não possui demo ativa.
  //
  // ============================================================

  Future<
    ProfileTrackModel?
  >
  getFirstTrack({
    required String userId,
  });

  // ============================================================
  // CRIAR TRACK
  // ============================================================

  Future<
    ProfileTrackModel
  >
  createTrack({
    required ProfileTrackModel track,
  });

  // ============================================================
  // ATUALIZAR TRACK
  // ============================================================

  Future<
    ProfileTrackModel
  >
  updateTrack({
    required ProfileTrackModel track,
  });

  // ============================================================
  // EXCLUIR TRACK
  // ============================================================

  Future<
    void
  >
  deleteTrack({
    required String trackId,
  });

  // ============================================================
  // REALTIME
  // ============================================================

  Stream<
    List<
      ProfileTrackModel
    >
  >
  watchTracks({
    required String userId,
  });
}
