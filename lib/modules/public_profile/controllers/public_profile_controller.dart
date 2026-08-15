import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:versin/modules/public_profile/models/profile_track_model.dart';
import 'package:versin/modules/public_profile/models/public_profile_model.dart';
import 'package:versin/modules/public_profile/repositories/public_profile_repository.dart';
import 'package:versin/modules/public_profile/services/profile_track_service.dart';

// ============================================================
// PUBLIC PROFILE CONTROLLER
// ============================================================
//
// Responsável por:
//
// - carregar perfil público;
// - carregar demos;
// - atualizar perfil;
// - alterar visibilidade ONLINE / OFFLINE;
// - publicar demo;
// - excluir demo;
// - buscar demo de outro usuário;
// - obter URL temporária de reprodução;
// - impedir requests duplicados de playback;
// - manter estado da tela.
//
// Arquitetura:
//
// Supabase
// ├── Auth
// └── Postgres
//
// Cloudflare R2
// └── arquivos de áudio
//
// Edge Functions
// ├── create-track-upload-url
// ├── create-track-playback-url
// └── delete-profile-track
//
// ============================================================

class PublicProfileController
    extends
        ChangeNotifier {
  // ============================================================
  // DEPENDÊNCIAS
  // ============================================================

  final PublicProfileRepository _repository;

  final ProfileTrackService _trackService;

  // ============================================================
  // PERFIL
  // ============================================================

  PublicProfileModel? _profile;

  List<
    ProfileTrackModel
  >
  _tracks =
      const <
        ProfileTrackModel
      >[];

  String? _loadedUserId;

  // ============================================================
  // ESTADOS
  // ============================================================

  bool _isLoading = false;

  bool _isSaving = false;

  bool _isUploadingTrack = false;

  bool _isUpdatingOnlineStatus = false;

  String? _errorMessage;

  // ============================================================
  // REALTIME
  // ============================================================

  StreamSubscription<
    List<
      ProfileTrackModel
    >
  >?
  _tracksSubscription;

  // ============================================================
  // PLAYBACK REQUESTS
  // ============================================================
  //
  // Evita:
  //
  // chamada A
  //     ↓
  // create-track-playback-url
  //
  // chamada B da mesma track antes de A terminar
  //     ↓
  // cria outra chamada desnecessária
  //
  // Agora ambas compartilham o mesmo Future.
  //
  // ============================================================

  final Map<
    String,
    Future<
      String
    >
  >
  _playbackRequests =
      <
        String,
        Future<
          String
        >
      >{};

  // ============================================================
  // DISPOSE
  // ============================================================

  bool _disposed = false;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  PublicProfileController({
    required PublicProfileRepository repository,
    required ProfileTrackService trackService,
  }) : _repository = repository,
       _trackService = trackService;

  // ============================================================
  // GETTERS
  // ============================================================

  PublicProfileModel? get profile => _profile;

  List<
    ProfileTrackModel
  >
  get tracks => _tracks;

  bool get isLoading => _isLoading;

  bool get isSaving => _isSaving;

  bool get isUploadingTrack => _isUploadingTrack;

  bool get isUpdatingOnlineStatus => _isUpdatingOnlineStatus;

  String? get errorMessage => _errorMessage;

  bool get hasError =>
      _errorMessage?.trim().isNotEmpty ==
      true;

  bool get hasProfile =>
      _profile !=
      null;

  bool get hasTracks => _tracks.isNotEmpty;

  String? get loadedUserId => _loadedUserId;

  // ============================================================
  // USUÁRIO AUTENTICADO
  // ============================================================

  String? get currentUserId {
    final id = Supabase.instance.client.auth.currentUser?.id.trim();

    if (id ==
            null ||
        id.isEmpty) {
      return null;
    }

    return id;
  }

  // ============================================================
  // OWNER
  // ============================================================

  bool get isOwner {
    final authenticatedUserId = currentUserId;

    final profileUserId = _profile?.userId.trim();

    if (authenticatedUserId ==
            null ||
        profileUserId ==
            null ||
        profileUserId.isEmpty) {
      return false;
    }

    return authenticatedUserId ==
        profileUserId;
  }

  // ============================================================
  // LOAD
  // ============================================================

  Future<
    void
  >
  load({
    required String userId,
  }) async {
    final normalizedUserId = userId.trim();

    if (_disposed ||
        normalizedUserId.isEmpty) {
      return;
    }

    _loadedUserId = normalizedUserId;

    _setLoading(
      true,
    );

    _clearError();

    try {
      // ========================================================
      // PERFIL
      // ========================================================

      _profile = await _repository.getProfile(
        userId: normalizedUserId,
      );

      if (_disposed) {
        return;
      }

      // ========================================================
      // TRACKS
      // ========================================================

      _tracks = await _repository.getTracks(
        userId: normalizedUserId,
      );

      if (_disposed) {
        return;
      }

      // ========================================================
      // REALTIME
      // ========================================================

      _startTracksStream(
        normalizedUserId,
      );

      _notify();
    } catch (
      error
    ) {
      _setError(
        'Não foi possível carregar o perfil.',
      );

      debugPrint(
        '[PUBLIC PROFILE] '
        'Erro ao carregar perfil: '
        '$error',
      );
    } finally {
      _setLoading(
        false,
      );
    }
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<
    void
  >
  refresh() async {
    final userId = _loadedUserId;

    if (userId ==
            null ||
        userId.isEmpty) {
      return;
    }

    await load(
      userId: userId,
    );
  }

  // ============================================================
  // PRIMEIRA DEMO
  // ============================================================
  //
  // Não altera o perfil atualmente carregado.
  //
  // ============================================================

  Future<
    ProfileTrackModel?
  >
  getFirstTrackForUser({
    required String userId,
  }) async {
    final normalizedUserId = userId.trim();

    if (_disposed ||
        normalizedUserId.isEmpty) {
      return null;
    }

    try {
      final track = await _repository.getFirstTrack(
        userId: normalizedUserId,
      );

      if (track ==
          null) {
        debugPrint(
          '[PUBLIC PROFILE] '
          'Usuário sem demo: '
          '$normalizedUserId',
        );

        return null;
      }

      debugPrint(
        '[PUBLIC PROFILE] '
        'Demo encontrada: '
        '${track.title}',
      );

      return track;
    } catch (
      error
    ) {
      debugPrint(
        '[PUBLIC PROFILE] '
        'Erro ao buscar primeira demo: '
        '$error',
      );

      return null;
    }
  }

  // ============================================================
  // TRACKS DE OUTRO USUÁRIO
  // ============================================================

  Future<
    List<
      ProfileTrackModel
    >
  >
  getTracksForUser({
    required String userId,
  }) async {
    final normalizedUserId = userId.trim();

    if (_disposed ||
        normalizedUserId.isEmpty) {
      return const <
        ProfileTrackModel
      >[];
    }

    try {
      return await _repository.getTracks(
        userId: normalizedUserId,
      );
    } catch (
      error
    ) {
      debugPrint(
        '[PUBLIC PROFILE] '
        'Erro ao buscar demos do usuário: '
        '$error',
      );

      return const <
        ProfileTrackModel
      >[];
    }
  }

  // ============================================================
  // UPDATE PROFILE
  // ============================================================

  Future<
    bool
  >
  updateProfile({
    required String displayName,
    required String username,
    required String bio,
    String? avatarUrl,
  }) async {
    final currentProfile = _profile;

    if (_disposed ||
        currentProfile ==
            null) {
      return false;
    }

    _setSaving(
      true,
    );

    _clearError();

    try {
      final updatedProfile = currentProfile.copyWith(
        displayName: displayName.trim(),

        username: username.trim(),

        bio: bio.trim(),

        avatarUrl: avatarUrl?.trim(),
      );

      _profile = await _repository.updateProfile(
        profile: updatedProfile,
      );

      _notify();

      return true;
    } catch (
      error
    ) {
      _setError(
        'Não foi possível atualizar o perfil.',
      );

      debugPrint(
        '[PUBLIC PROFILE] '
        'Erro ao atualizar perfil: '
        '$error',
      );

      return false;
    } finally {
      _setSaving(
        false,
      );
    }
  }

  // ============================================================
  // ONLINE / OFFLINE
  // ============================================================
  //
  // Altera a visibilidade pública do perfil.
  //
  // true:
  //
  // - perfil ONLINE;
  // - elegível para aparecer no Match / Discovery.
  //
  // false:
  //
  // - perfil OFFLINE;
  // - deve ser ocultado das consultas públicas;
  // - o próprio dono continua conseguindo abrir o perfil.
  //
  // IMPORTANTE:
  //
  // O Controller apenas persiste is_online.
  // O filtro que realmente remove usuários OFFLINE do Match
  // deve existir também no datasource/repository do Match.
  //
  // ============================================================

  Future<
    bool
  >
  setOnlineStatus(
    bool value,
  ) async {
    final currentProfile = _profile;

    if (_disposed ||
        currentProfile ==
            null ||
        !isOwner ||
        _isUpdatingOnlineStatus) {
      return false;
    }

    // ==========================================================
    // NADA PARA ALTERAR
    // ==========================================================

    if (currentProfile.isOnline ==
        value) {
      return true;
    }

    // ==========================================================
    // LOADING
    // ==========================================================

    _setUpdatingOnlineStatus(
      true,
    );

    _clearError();

    try {
      // ========================================================
      // SUPABASE
      // ========================================================

      final updatedProfile = await _repository.updateOnlineStatus(
        userId: currentProfile.userId,

        isOnline: value,
      );

      if (_disposed) {
        return false;
      }

      // ========================================================
      // ESTADO LOCAL
      // ========================================================

      _profile = updatedProfile;

      _notify();

      debugPrint(
        '[PUBLIC PROFILE] '
        'Perfil ${updatedProfile.isOnline ? 'ONLINE' : 'OFFLINE'}.',
      );

      return true;
    } catch (
      error
    ) {
      _setError(
        value
            ? 'Não foi possível deixar o perfil online.'
            : 'Não foi possível deixar o perfil offline.',
      );

      debugPrint(
        '[PUBLIC PROFILE] '
        'Erro ao alterar visibilidade: '
        '$error',
      );

      return false;
    } finally {
      _setUpdatingOnlineStatus(
        false,
      );
    }
  }

  // ============================================================
  // TOGGLE ONLINE / OFFLINE
  // ============================================================

  Future<
    bool
  >
  toggleOnline() async {
    final currentProfile = _profile;

    if (_disposed ||
        currentProfile ==
            null ||
        !isOwner ||
        _isUpdatingOnlineStatus) {
      return false;
    }

    return setOnlineStatus(
      !currentProfile.isOnline,
    );
  }

  // ============================================================
  // ADD TRACK
  // ============================================================
  //
  // Flutter
  //      ↓
  // create-track-upload-url
  //      ↓
  // Cloudflare R2
  //      ↓
  // objectKey
  //      ↓
  // public.profile_tracks
  //
  // ============================================================

  Future<
    ProfileTrackModel?
  >
  addTrack({
    required String title,
    required String fileName,
    required Uint8List bytes,
    required List<
      String
    >
    audienceRoles,
    String? mimeType,
    int? durationSeconds,
  }) async {
    final profile = _profile;

    if (_disposed ||
        profile ==
            null ||
        !isOwner) {
      return null;
    }

    // ==========================================================
    // TITLE
    // ==========================================================

    final normalizedTitle = title.trim();

    if (normalizedTitle.isEmpty) {
      _setError(
        'Informe o título da música.',
      );

      return null;
    }

    // ==========================================================
    // FILE
    // ==========================================================

    if (bytes.isEmpty) {
      _setError(
        'O arquivo selecionado está vazio.',
      );

      return null;
    }

    // ==========================================================
    // AUDIENCE
    // ==========================================================

    final normalizedAudienceRoles = _normalizeAudienceRoles(
      audienceRoles,
    );

    if (normalizedAudienceRoles.isEmpty) {
      _setError(
        'Escolha pelo menos um grupo que poderá ouvir a demo.',
      );

      return null;
    }

    // ==========================================================
    // UPLOAD
    // ==========================================================

    _setUploadingTrack(
      true,
    );

    _clearError();

    String? uploadedObjectKey;

    try {
      // ========================================================
      // R2
      // ========================================================

      uploadedObjectKey = await _trackService.uploadTrack(
        userId: profile.userId,

        fileName: fileName,

        bytes: bytes,

        contentType: mimeType,
      );

      // ========================================================
      // MODEL
      // ========================================================

      final track = ProfileTrackModel(
        id: '',

        userId: profile.userId,

        title: normalizedTitle,

        storagePath: uploadedObjectKey,

        audienceRoles: normalizedAudienceRoles,

        durationSeconds: durationSeconds,

        mimeType: mimeType?.trim(),

        fileSizeBytes: bytes.length,

        position: _nextTrackPosition,

        isActive: true,
      );

      // ========================================================
      // POSTGRES
      // ========================================================

      final created = await _repository.createTrack(
        track: track,
      );

      // ========================================================
      // LOCAL
      // ========================================================

      if (!_disposed &&
          !_tracks.any(
            (
              current,
            ) =>
                current.id ==
                created.id,
          )) {
        final updated =
            <
              ProfileTrackModel
            >[
              ..._tracks,
              created,
            ];

        updated.sort(
          (
            a,
            b,
          ) {
            return a.position.compareTo(
              b.position,
            );
          },
        );

        _tracks =
            List<
              ProfileTrackModel
            >.unmodifiable(
              updated,
            );

        _notify();
      }

      debugPrint(
        '[PUBLIC PROFILE] '
        'Demo publicada: '
        '${created.title}',
      );

      return created;
    } catch (
      error
    ) {
      // ========================================================
      // POSSÍVEL OBJETO ÓRFÃO
      // ========================================================

      if (uploadedObjectKey !=
              null &&
          uploadedObjectKey.isNotEmpty) {
        debugPrint(
          '[PUBLIC PROFILE] '
          'Upload R2 concluído, '
          'mas criação no banco falhou.',
        );
      }

      _setError(
        'Não foi possível publicar a música.',
      );

      debugPrint(
        '[PUBLIC PROFILE] '
        'Erro ao adicionar música: '
        '$error',
      );

      return null;
    } finally {
      _setUploadingTrack(
        false,
      );
    }
  }

  // ============================================================
  // NEXT POSITION
  // ============================================================

  int get _nextTrackPosition {
    if (_tracks.isEmpty) {
      return 0;
    }

    var highestPosition = -1;

    for (final track in _tracks) {
      if (track.position >
          highestPosition) {
        highestPosition = track.position;
      }
    }

    return highestPosition +
        1;
  }

  // ============================================================
  // DELETE TRACK
  // ============================================================
  //
  // delete-profile-track remove:
  //
  // - R2;
  // - Postgres.
  //
  // ============================================================

  Future<
    bool
  >
  deleteTrack(
    ProfileTrackModel track,
  ) async {
    if (_disposed ||
        !isOwner) {
      return false;
    }

    final trackId = track.id.trim();

    if (trackId.isEmpty) {
      _setError(
        'A música não possui um identificador válido.',
      );

      return false;
    }

    _clearError();

    try {
      await _trackService.deleteTrackFile(
        storagePath: track.storagePath,

        trackId: trackId,
      );

      // ========================================================
      // REMOVER REQUEST PENDENTE
      // ========================================================

      _playbackRequests.remove(
        trackId,
      );

      // ========================================================
      // LOCAL
      // ========================================================

      if (!_disposed) {
        _tracks =
            List<
              ProfileTrackModel
            >.unmodifiable(
              _tracks.where(
                (
                  current,
                ) {
                  return current.id !=
                      trackId;
                },
              ),
            );

        _notify();
      }

      debugPrint(
        '[PUBLIC PROFILE] '
        'Demo removida: '
        '$trackId',
      );

      return true;
    } catch (
      error
    ) {
      _setError(
        'Não foi possível remover a música.',
      );

      debugPrint(
        '[PUBLIC PROFILE] '
        'Erro ao remover música: '
        '$error',
      );

      return false;
    }
  }

  // ============================================================
  // PLAYBACK URL
  // ============================================================
  //
  // Esta função é o ÚNICO caminho do controller para solicitar
  // uma presigned GET URL.
  //
  // Se já existir uma chamada em andamento para a mesma track,
  // reutilizamos o Future.
  //
  // ============================================================

  Future<
    String
  >
  getTrackPlaybackUrl(
    ProfileTrackModel track,
  ) {
    final trackId = track.id.trim();

    if (_disposed ||
        trackId.isEmpty) {
      return Future<
        String
      >.value(
        '',
      );
    }

    // ==========================================================
    // REQUEST JÁ EM ANDAMENTO
    // ==========================================================

    final existingRequest = _playbackRequests[trackId];

    if (existingRequest !=
        null) {
      debugPrint(
        '[PUBLIC PROFILE] '
        'Reutilizando solicitação '
        'de playback em andamento.',
      );

      return existingRequest;
    }

    // ==========================================================
    // NOVA REQUEST
    // ==========================================================

    final request = _requestTrackPlaybackUrl(
      trackId,
    );

    _playbackRequests[trackId] = request;

    return request;
  }

  // ============================================================
  // REQUEST PLAYBACK
  // ============================================================

  Future<
    String
  >
  _requestTrackPlaybackUrl(
    String trackId,
  ) async {
    try {
      final url = await _trackService.createPlaybackUrl(
        trackId: trackId,
      );

      if (url.trim().isEmpty) {
        debugPrint(
          '[PUBLIC PROFILE] '
          'URL de reprodução vazia.',
        );

        return '';
      }

      debugPrint(
        '[PUBLIC PROFILE] '
        'Playback URL obtida com sucesso.',
      );

      // IMPORTANTE:
      //
      // Não logar a URL assinada completa.

      return url;
    } catch (
      error
    ) {
      debugPrint(
        '[PUBLIC PROFILE] '
        'Erro ao obter URL de reprodução: '
        '$error',
      );

      return '';
    } finally {
      _playbackRequests.remove(
        trackId,
      );
    }
  }

  // ============================================================
  // PRIMEIRA DEMO + PLAYBACK
  // ============================================================
  //
  // Match chama apenas este método.
  //
  // Fluxo:
  //
  // getFirstTrack()
  //      ↓
  // getTrackPlaybackUrl()
  //      ↓
  // TrackPlaybackData
  //
  // ============================================================

  Future<
    TrackPlaybackData?
  >
  getFirstTrackPlaybackForUser({
    required String userId,
  }) async {
    final normalizedUserId = userId.trim();

    if (_disposed ||
        normalizedUserId.isEmpty) {
      return null;
    }

    // ==========================================================
    // TRACK
    // ==========================================================

    final track = await getFirstTrackForUser(
      userId: normalizedUserId,
    );

    if (track ==
        null) {
      return null;
    }

    // ==========================================================
    // PLAYBACK
    // ==========================================================

    final url = await getTrackPlaybackUrl(
      track,
    );

    return TrackPlaybackData(
      track: track,

      url: url,
    );
  }

  // ============================================================
  // ROLE LOCAL
  // ============================================================
  //
  // Apenas UI.
  //
  // A validação real deve permanecer no backend.
  //
  // ============================================================

  bool canRoleListenToTrack({
    required ProfileTrackModel track,
    required String role,
  }) {
    return track.allowsRole(
      role,
    );
  }

  // ============================================================
  // MULTIPLE ROLES
  // ============================================================

  bool canAnyRoleListenToTrack({
    required ProfileTrackModel track,
    required Iterable<
      String
    >
    roles,
  }) {
    return track.allowsAnyRole(
      roles,
    );
  }

  // ============================================================
  // REALTIME
  // ============================================================

  void _startTracksStream(
    String userId,
  ) {
    unawaited(
      _tracksSubscription?.cancel(),
    );

    _tracksSubscription = _repository
        .watchTracks(
          userId: userId,
        )
        .listen(
          (
            tracks,
          ) {
            if (_disposed) {
              return;
            }

            _tracks =
                List<
                  ProfileTrackModel
                >.unmodifiable(
                  tracks,
                );

            _notify();
          },
          onError:
              (
                error,
              ) {
                debugPrint(
                  '[PUBLIC PROFILE] '
                  'Erro no realtime das demos: '
                  '$error',
                );
              },
        );
  }

  // ============================================================
  // NORMALIZE AUDIENCE
  // ============================================================

  List<
    String
  >
  _normalizeAudienceRoles(
    Iterable<
      String
    >
    roles,
  ) {
    final normalized = roles
        .map(
          (
            role,
          ) {
            return role.trim().toLowerCase().replaceAll(
              RegExp(
                r'\s+',
              ),
              '_',
            );
          },
        )
        .where(
          (
            role,
          ) {
            return role.isNotEmpty;
          },
        )
        .toSet()
        .toList();

    normalized.sort();

    return List<
      String
    >.unmodifiable(
      normalized,
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  void _setLoading(
    bool value,
  ) {
    if (_disposed ||
        _isLoading ==
            value) {
      return;
    }

    _isLoading = value;

    _notify();
  }

  // ============================================================
  // SAVING
  // ============================================================

  void _setSaving(
    bool value,
  ) {
    if (_disposed ||
        _isSaving ==
            value) {
      return;
    }

    _isSaving = value;

    _notify();
  }

  // ============================================================
  // ONLINE STATUS LOADING
  // ============================================================

  void _setUpdatingOnlineStatus(
    bool value,
  ) {
    if (_disposed ||
        _isUpdatingOnlineStatus ==
            value) {
      return;
    }

    _isUpdatingOnlineStatus = value;

    _notify();
  }

  // ============================================================
  // UPLOAD
  // ============================================================

  void _setUploadingTrack(
    bool value,
  ) {
    if (_disposed ||
        _isUploadingTrack ==
            value) {
      return;
    }

    _isUploadingTrack = value;

    _notify();
  }

  // ============================================================
  // ERROR
  // ============================================================

  void _setError(
    String message,
  ) {
    if (_disposed) {
      return;
    }

    _errorMessage = message.trim();

    _notify();
  }

  void _clearError() {
    if (_disposed ||
        _errorMessage ==
            null) {
      return;
    }

    _errorMessage = null;

    _notify();
  }

  void clearError() {
    _clearError();
  }

  // ============================================================
  // NOTIFY
  // ============================================================

  void _notify() {
    if (_disposed) {
      return;
    }

    notifyListeners();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    if (_disposed) {
      return;
    }

    _disposed = true;

    unawaited(
      _tracksSubscription?.cancel(),
    );

    _tracksSubscription = null;

    _playbackRequests.clear();

    super.dispose();
  }
}

// ============================================================
// TRACK PLAYBACK DATA
// ============================================================
//
// Resultado entregue ao Match.
//
// track:
// metadata da demo.
//
// url:
// presigned GET URL temporária.
//
// ============================================================

class TrackPlaybackData {
  final ProfileTrackModel track;

  final String url;

  const TrackPlaybackData({
    required this.track,
    required this.url,
  });

  bool get hasUrl => url.trim().isNotEmpty;
}
