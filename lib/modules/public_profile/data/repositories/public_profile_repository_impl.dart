import 'package:flutter/foundation.dart';
import 'package:versin/modules/profile/services/profile_name_cache_service.dart';

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
// - delegar operações de banco ao Datasource;
// - atualizar visibilidade ONLINE / OFFLINE.
//
// Arquitetura:
//
// UI / Controller
//      ↓
// Repository
//      ↓
// Datasource
//      ↓
// Supabase Postgres
//
// Arquivos de áudio:
//
// NÃO passam por este Repository.
//
// Eles usam:
//
// ProfileTrackService
//      ↓
// Supabase Edge Functions
//      ↓
// Cloudflare R2
//
// ============================================================

class PublicProfileRepositoryImpl
    implements
        PublicProfileRepository {
  // ============================================================
  // DATASOURCE
  // ============================================================

  final PublicProfileRemoteDatasource _remoteDatasource;

  final ProfileNameCacheService _profileNameCacheService;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  PublicProfileRepositoryImpl({
    PublicProfileRemoteDatasource? remoteDatasource,
    ProfileNameCacheService? profileNameCacheService,
  }) : _remoteDatasource =
           remoteDatasource ??
           PublicProfileRemoteDatasourceImpl(),
       _profileNameCacheService =
           profileNameCacheService ??
           ProfileNameCacheService();

  // ============================================================
  // PERFIL
  // ============================================================

  @override
  Future<
    PublicProfileModel?
  >
  getProfile({
    required String userId,
  }) async {
    final normalizedUserId = userId.trim();

    if (normalizedUserId.isEmpty) {
      return null;
    }

    final data = await _remoteDatasource.getProfile(
      userId: normalizedUserId,
    );

    if (data ==
        null) {
      return null;
    }

    final profile = PublicProfileModel.fromMap(
      data,
    );

    await _syncProfileNameCache(
      data: data,
      fallbackUserId: normalizedUserId,
    );

    return profile;
  }

  // ============================================================
  // ATUALIZAR PERFIL
  // ============================================================

  @override
  Future<
    PublicProfileModel
  >
  updateProfile({
    required PublicProfileModel profile,
  }) async {
    final userId = profile.userId.trim();

    if (userId.isEmpty) {
      throw ArgumentError(
        'O perfil não possui userId válido.',
      );
    }

    final data = await _remoteDatasource.updateProfile(
      userId: userId,

      data: profile.toUpdateMap(),
    );

    final updatedProfile = PublicProfileModel.fromMap(
      data,
    );

    await _syncProfileNameCache(
      data: data,
      fallbackUserId: userId,
    );

    return updatedProfile;
  }

  // ============================================================
  // ONLINE / OFFLINE
  // ============================================================
  //
  // Atualiza somente:
  //
  // public.profiles.is_online
  //
  // Isso evita reenviar:
  //
  // - nome;
  // - username;
  // - bio;
  // - avatar.
  //
  // ============================================================

  @override
  Future<
    PublicProfileModel
  >
  updateOnlineStatus({
    required String userId,
    required bool isOnline,
  }) async {
    final normalizedUserId = userId.trim();

    if (normalizedUserId.isEmpty) {
      throw ArgumentError(
        'userId não pode ser vazio.',
      );
    }

    final data = await _remoteDatasource.updateOnlineStatus(
      userId: normalizedUserId,

      isOnline: isOnline,
    );

    return PublicProfileModel.fromMap(
      data,
    );
  }

  // ============================================================
  // TRACKS
  // ============================================================

  @override
  Future<
    List<
      ProfileTrackModel
    >
  >
  getTracks({
    required String userId,
    bool onlyActive = true,
  }) async {
    final normalizedUserId = userId.trim();

    if (normalizedUserId.isEmpty) {
      return const <
        ProfileTrackModel
      >[];
    }

    final rows = await _remoteDatasource.getTracks(
      userId: normalizedUserId,

      onlyActive: onlyActive,
    );

    final tracks = rows.map(
      (
        row,
      ) {
        return ProfileTrackModel.fromMap(
          row,
        );
      },
    ).toList();

    _sortTracks(
      tracks,
    );

    return List<
      ProfileTrackModel
    >.unmodifiable(
      tracks,
    );
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
  // Essa função retorna apenas METADADOS.
  //
  // A playbackUrl é gerada depois pelo:
  //
  // ProfileTrackService
  //    ↓
  // create-track-playback-url
  //    ↓
  // Cloudflare R2
  //
  // ============================================================

  @override
  Future<
    ProfileTrackModel?
  >
  getFirstTrack({
    required String userId,
  }) async {
    final normalizedUserId = userId.trim();

    if (normalizedUserId.isEmpty) {
      return null;
    }

    final data = await _remoteDatasource.getFirstTrack(
      userId: normalizedUserId,

      onlyActive: true,
    );

    if (data ==
        null) {
      return null;
    }

    return ProfileTrackModel.fromMap(
      data,
    );
  }

  // ============================================================
  // CRIAR TRACK
  // ============================================================
  //
  // O arquivo já deve ter sido enviado para o R2.
  //
  // storagePath contém:
  //
  // profiles/<user-id>/tracks/<uuid>.mp3
  //
  // ============================================================

  @override
  Future<
    ProfileTrackModel
  >
  createTrack({
    required ProfileTrackModel track,
  }) async {
    _validateTrackForCreate(
      track,
    );

    final data = await _remoteDatasource.createTrack(
      data: track.toInsertMap(),
    );

    return ProfileTrackModel.fromMap(
      data,
    );
  }

  // ============================================================
  // ATUALIZAR TRACK
  // ============================================================

  @override
  Future<
    ProfileTrackModel
  >
  updateTrack({
    required ProfileTrackModel track,
  }) async {
    final trackId = track.id.trim();

    if (trackId.isEmpty) {
      throw ArgumentError(
        'A track não possui id válido.',
      );
    }

    final data = await _remoteDatasource.updateTrack(
      trackId: trackId,

      data: track.toUpdateMap(),
    );

    return ProfileTrackModel.fromMap(
      data,
    );
  }

  // ============================================================
  // EXCLUIR TRACK - LEGADO
  // ============================================================
  //
  // O fluxo normal NÃO deve usar este método.
  //
  // Para excluir uma demo use o ProfileTrackService, que chama
  // delete-profile-track e remove:
  //
  // - arquivo do R2;
  // - linha do Postgres.
  //
  // ============================================================

  @override
  Future<
    void
  >
  deleteTrack({
    required String trackId,
  }) {
    final normalizedTrackId = trackId.trim();

    if (normalizedTrackId.isEmpty) {
      return Future<
        void
      >.value();
    }

    return _remoteDatasource.deleteTrack(
      trackId: normalizedTrackId,
    );
  }

  // ============================================================
  // REALTIME
  // ============================================================

  @override
  Stream<
    List<
      ProfileTrackModel
    >
  >
  watchTracks({
    required String userId,
  }) {
    final normalizedUserId = userId.trim();

    if (normalizedUserId.isEmpty) {
      return Stream<
        List<
          ProfileTrackModel
        >
      >.value(
        const <
          ProfileTrackModel
        >[],
      );
    }

    return _remoteDatasource
        .watchTracks(
          userId: normalizedUserId,
        )
        .map(
          (
            rows,
          ) {
            final tracks = rows.map(
              (
                row,
              ) {
                return ProfileTrackModel.fromMap(
                  row,
                );
              },
            ).toList();

            _sortTracks(
              tracks,
            );

            return List<
              ProfileTrackModel
            >.unmodifiable(
              tracks,
            );
          },
        );
  }

  // ============================================================
  // SYNC PROFILE NAME CACHE
  // ============================================================
  //
  // Sempre que o Repository recebe uma versão atualizada de
  // public.profiles, sincroniza o nome no cache persistente.
  //
  // Isso evita:
  //
  // - nome antigo por até 24 horas;
  // - nova consulta apenas para descobrir o nome;
  // - efeito visual de nome trocar depois que a tela abre.
  //
  // ============================================================

  Future<
    void
  >
  _syncProfileNameCache({
    required Map<
      String,
      dynamic
    >
    data,
    required String fallbackUserId,
  }) async {
    try {
      await _profileNameCacheService.cacheProfileMap(
        data,
        fallbackUserId: fallbackUserId,
      );
    } catch (
      error,
      stackTrace
    ) {
      // Cache nunca deve impedir o fluxo principal do perfil.
      debugPrint(
        '[PUBLIC PROFILE REPOSITORY] '
        'Erro ao sincronizar cache de nome: $error',
      );

      debugPrint(
        '$stackTrace',
      );
    }
  }

  // ============================================================
  // VALIDAR TRACK PARA CREATE
  // ============================================================

  void _validateTrackForCreate(
    ProfileTrackModel track,
  ) {
    if (!track.hasUserId) {
      throw ArgumentError(
        'A track não possui userId válido.',
      );
    }

    if (!track.hasTitle) {
      throw ArgumentError(
        'A track precisa possuir título.',
      );
    }

    if (!track.hasStoragePath) {
      throw ArgumentError(
        'A track não possui storagePath do R2.',
      );
    }

    if (!track.hasAudience) {
      throw ArgumentError(
        'A track precisa possuir pelo menos um grupo de audiência.',
      );
    }
  }

  // ============================================================
  // SORT
  // ============================================================

  void _sortTracks(
    List<
      ProfileTrackModel
    >
    tracks,
  ) {
    tracks.sort(
      (
        a,
        b,
      ) {
        // ======================================================
        // POSITION
        // ======================================================

        final positionComparison = a.position.compareTo(
          b.position,
        );

        if (positionComparison !=
            0) {
          return positionComparison;
        }

        // ======================================================
        // CREATED AT
        // ======================================================

        final aCreated =
            a.createdAt ??
            DateTime.fromMillisecondsSinceEpoch(
              0,
            );

        final bCreated =
            b.createdAt ??
            DateTime.fromMillisecondsSinceEpoch(
              0,
            );

        return bCreated.compareTo(
          aCreated,
        );
      },
    );
  }
}
