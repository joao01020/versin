import '../../models/profile_track_model.dart';
import '../../models/public_profile_model.dart';
import '../../repositories/public_profile_repository.dart';
import '../datasources/public_profile_remote_datasource.dart';

// ============================================================
// PUBLIC PROFILE REPOSITORY IMPLEMENTATION
// ============================================================
//
// Responsável por:
//
// - converter Map -> Model;
// - converter Model -> Map;
// - delegar operações ao datasource.
//
// NÃO:
//
// - acessa Supabase diretamente;
// - controla UI;
// - reproduz áudio;
// - possui regra de Match.
//
// ============================================================

class PublicProfileRepositoryImpl implements PublicProfileRepository {
  // ============================================================
  // DATASOURCE
  // ============================================================

  final PublicProfileRemoteDatasource _remoteDatasource;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  PublicProfileRepositoryImpl({PublicProfileRemoteDatasource? remoteDatasource})
    : _remoteDatasource =
          remoteDatasource ?? PublicProfileRemoteDatasourceImpl();

  // ============================================================
  // PERFIL
  // ============================================================

  @override
  Future<PublicProfileModel?> getProfile({required String userId}) async {
    final data = await _remoteDatasource.getProfile(userId: userId);

    if (data == null) {
      return null;
    }

    return PublicProfileModel.fromMap(data);
  }

  // ============================================================
  // ATUALIZAR PERFIL
  // ============================================================

  @override
  Future<PublicProfileModel> updateProfile({
    required PublicProfileModel profile,
  }) async {
    final data = await _remoteDatasource.updateProfile(
      userId: profile.userId,
      data: profile.toUpdateMap(),
    );

    return PublicProfileModel.fromMap(data);
  }

  // ============================================================
  // TRACKS
  // ============================================================

  @override
  Future<List<ProfileTrackModel>> getTracks({
    required String userId,
    bool onlyActive = true,
  }) async {
    final rows = await _remoteDatasource.getTracks(
      userId: userId,
      onlyActive: onlyActive,
    );

    return rows
        .map((row) {
          return ProfileTrackModel.fromMap(row);
        })
        .toList(growable: false);
  }

  // ============================================================
  // PRIMEIRA DEMO
  // ============================================================
  //
  // Usado principalmente pelo Match:
  //
  // OUVIR DEMO
  //    ↓
  // getFirstTrack()
  //    ↓
  // ProfileTrackModel?
  //
  // ============================================================

  @override
  Future<ProfileTrackModel?> getFirstTrack({required String userId}) async {
    final data = await _remoteDatasource.getFirstTrack(
      userId: userId,
      onlyActive: true,
    );

    if (data == null) {
      return null;
    }

    return ProfileTrackModel.fromMap(data);
  }

  // ============================================================
  // CRIAR TRACK
  // ============================================================

  @override
  Future<ProfileTrackModel> createTrack({
    required ProfileTrackModel track,
  }) async {
    final data = await _remoteDatasource.createTrack(data: track.toInsertMap());

    return ProfileTrackModel.fromMap(data);
  }

  // ============================================================
  // ATUALIZAR TRACK
  // ============================================================

  @override
  Future<ProfileTrackModel> updateTrack({
    required ProfileTrackModel track,
  }) async {
    final data = await _remoteDatasource.updateTrack(
      trackId: track.id,
      data: track.toUpdateMap(),
    );

    return ProfileTrackModel.fromMap(data);
  }

  // ============================================================
  // EXCLUIR TRACK
  // ============================================================

  @override
  Future<void> deleteTrack({required String trackId}) {
    return _remoteDatasource.deleteTrack(trackId: trackId);
  }

  // ============================================================
  // STREAM
  // ============================================================

  @override
  Stream<List<ProfileTrackModel>> watchTracks({required String userId}) {
    return _remoteDatasource.watchTracks(userId: userId).map((rows) {
      final tracks = rows.map((row) {
        return ProfileTrackModel.fromMap(row);
      }).toList();

      tracks.sort((a, b) {
        final positionComparison = a.position.compareTo(b.position);

        if (positionComparison != 0) {
          return positionComparison;
        }

        final aCreated = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

        final bCreated = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

        return bCreated.compareTo(aCreated);
      });

      return List<ProfileTrackModel>.unmodifiable(tracks);
    });
  }
}
