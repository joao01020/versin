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
// ============================================================

abstract class PublicProfileRepository {
  // ============================================================
  // PERFIL
  // ============================================================

  Future<PublicProfileModel?> getProfile({required String userId});

  // ============================================================
  // ATUALIZAR PERFIL
  // ============================================================

  Future<PublicProfileModel> updateProfile({
    required PublicProfileModel profile,
  });

  // ============================================================
  // TRACKS
  // ============================================================

  Future<List<ProfileTrackModel>> getTracks({
    required String userId,
    bool onlyActive = true,
  });

  // ============================================================
  // PRIMEIRA DEMO
  // ============================================================
  //
  // Usado pelo Match para o botão:
  //
  // OUVIR DEMO
  //
  // Retorna null quando o usuário não possui demo ativa.
  //
  // ============================================================

  Future<ProfileTrackModel?> getFirstTrack({required String userId});

  // ============================================================
  // CRIAR TRACK
  // ============================================================

  Future<ProfileTrackModel> createTrack({required ProfileTrackModel track});

  // ============================================================
  // ATUALIZAR TRACK
  // ============================================================

  Future<ProfileTrackModel> updateTrack({required ProfileTrackModel track});

  // ============================================================
  // EXCLUIR TRACK
  // ============================================================

  Future<void> deleteTrack({required String trackId});

  // ============================================================
  // REALTIME
  // ============================================================

  Stream<List<ProfileTrackModel>> watchTracks({required String userId});
}
