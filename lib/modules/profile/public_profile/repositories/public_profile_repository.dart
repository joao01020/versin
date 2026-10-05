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
// - alterar preferência ONLINE / OFFLINE;
// - atualizar heartbeat de presença real;
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
  // Não deve atualizar last_seen_at.
  //
  // ============================================================

  Future<
    PublicProfileModel
  >
  updateProfile({
    required PublicProfileModel profile,
  });

  // ============================================================
  // ATUALIZAR PREFERÊNCIA ONLINE / OFFLINE
  // ============================================================
  //
  // IMPORTANTE:
  //
  // isOnline NÃO representa sozinho a presença real.
  //
  // Ele representa a preferência do usuário:
  //
  // true:
  //
  // - permite aparecer online;
  // - quando houver heartbeat recente, poderá aparecer como
  //   "ONLINE AGORA".
  //
  // false:
  //
  // - permanece offline/invisível;
  // - mesmo se o aplicativo estiver aberto.
  //
  // No backend, o fluxo esperado é:
  //
  // set_my_online_preference(true)
  //
  //   is_online = true
  //   last_seen_at = now()
  //
  // set_my_online_preference(false)
  //
  //   is_online = false
  //   last_seen_at = null
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
  // HEARTBEAT DE PRESENÇA
  // ============================================================
  //
  // Registra atividade real do usuário autenticado.
  //
  // Backend:
  //
  // public.update_my_presence()
  //
  // Atualiza:
  //
  // public.profiles.last_seen_at
  //
  // NÃO altera:
  //
  // public.profiles.is_online
  //
  // Portanto:
  //
  // is_online
  //   = preferência do usuário
  //
  // last_seen_at
  //   = atividade real do aplicativo
  //
  // Presença real:
  //
  // is_online == true
  // &&
  // last_seen_at recente
  //
  // ============================================================

  Future<
    DateTime
  >
  updateMyPresence();

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
