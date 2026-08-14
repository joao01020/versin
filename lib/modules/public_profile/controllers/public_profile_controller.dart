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
// Estado principal do perfil público.
//
// Responsabilidades:
//
// - carregar perfil;
// - carregar músicas;
// - buscar primeira demo;
// - editar perfil;
// - adicionar música;
// - remover música;
// - controlar audiência das demos;
// - acompanhar músicas em realtime;
// - gerar URL para reprodução;
// - controlar loading;
// - controlar saving;
// - controlar upload;
// - controlar erros.
//
// ============================================================

class PublicProfileController extends ChangeNotifier {
  // ============================================================
  // DEPENDÊNCIAS
  // ============================================================

  final PublicProfileRepository _repository;

  final ProfileTrackService _trackService;

  // ============================================================
  // ESTADO
  // ============================================================

  PublicProfileModel? _profile;

  List<ProfileTrackModel> _tracks = const <ProfileTrackModel>[];

  bool _isLoading = false;

  bool _isSaving = false;

  bool _isUploadingTrack = false;

  String? _errorMessage;

  String? _loadedUserId;

  // ============================================================
  // STREAM
  // ============================================================

  StreamSubscription<List<ProfileTrackModel>>? _tracksSubscription;

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

  List<ProfileTrackModel> get tracks => _tracks;

  bool get isLoading => _isLoading;

  bool get isSaving => _isSaving;

  bool get isUploadingTrack => _isUploadingTrack;

  String? get errorMessage => _errorMessage;

  bool get hasError => _errorMessage?.trim().isNotEmpty == true;

  bool get hasProfile => _profile != null;

  bool get hasTracks => _tracks.isNotEmpty;

  String? get loadedUserId => _loadedUserId;

  // ============================================================
  // CURRENT USER
  // ============================================================

  String? get currentUserId {
    return Supabase.instance.client.auth.currentUser?.id;
  }

  // ============================================================
  // É O DONO DO PERFIL?
  // ============================================================

  bool get isOwner {
    final authenticatedUserId = currentUserId;

    final profileUserId = _profile?.userId;

    if (authenticatedUserId == null || profileUserId == null) {
      return false;
    }

    return authenticatedUserId == profileUserId;
  }

  // ============================================================
  // CARREGAR PERFIL
  // ============================================================

  Future<void> load({required String userId}) async {
    final normalizedUserId = userId.trim();

    if (_disposed || normalizedUserId.isEmpty) {
      return;
    }

    _loadedUserId = normalizedUserId;

    _setLoading(true);

    _clearError();

    try {
      // ========================================================
      // PERFIL
      // ========================================================

      _profile = await _repository.getProfile(userId: normalizedUserId);

      if (_disposed) {
        return;
      }

      // ========================================================
      // MÚSICAS
      // ========================================================

      _tracks = await _repository.getTracks(userId: normalizedUserId);

      if (_disposed) {
        return;
      }

      // ========================================================
      // REALTIME
      // ========================================================

      _startTracksStream(normalizedUserId);

      _notify();
    } catch (error) {
      _setError('Não foi possível carregar o perfil.');

      debugPrint(
        '[PUBLIC PROFILE] '
        'Erro ao carregar perfil: '
        '$error',
      );
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> refresh() async {
    final userId = _loadedUserId;

    if (userId == null || userId.isEmpty) {
      return;
    }

    await load(userId: userId);
  }

  // ============================================================
  // BUSCAR PRIMEIRA DEMO DE UM USUÁRIO
  // ============================================================
  //
  // Importante:
  //
  // Este método NÃO altera:
  //
  // - _profile;
  // - _tracks;
  // - _loadedUserId;
  //
  // Portanto pode ser usado pelo Match para ouvir a demo
  // de outro usuário sem trocar o perfil atualmente carregado.
  //
  // ============================================================

  Future<ProfileTrackModel?> getFirstTrackForUser({
    required String userId,
  }) async {
    final normalizedUserId = userId.trim();

    if (_disposed || normalizedUserId.isEmpty) {
      return null;
    }

    try {
      final track = await _repository.getFirstTrack(userId: normalizedUserId);

      if (track == null) {
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
        '${track.title} | '
        'userId: '
        '$normalizedUserId',
      );

      return track;
    } catch (error) {
      debugPrint(
        '[PUBLIC PROFILE] '
        'Erro ao buscar primeira demo: '
        '$error',
      );

      return null;
    }
  }

  // ============================================================
  // BUSCAR TRACKS DE OUTRO USUÁRIO
  // ============================================================
  //
  // Também não altera o estado atual.
  //
  // Útil caso futuramente o modal permita navegar entre várias
  // demos.
  //
  // ============================================================

  Future<List<ProfileTrackModel>> getTracksForUser({
    required String userId,
  }) async {
    final normalizedUserId = userId.trim();

    if (_disposed || normalizedUserId.isEmpty) {
      return const <ProfileTrackModel>[];
    }

    try {
      return await _repository.getTracks(userId: normalizedUserId);
    } catch (error) {
      debugPrint(
        '[PUBLIC PROFILE] '
        'Erro ao buscar demos do usuário: '
        '$error',
      );

      return const <ProfileTrackModel>[];
    }
  }

  // ============================================================
  // ATUALIZAR PERFIL
  // ============================================================

  Future<bool> updateProfile({
    required String displayName,
    required String username,
    required String bio,
    String? avatarUrl,
  }) async {
    final currentProfile = _profile;

    if (_disposed || currentProfile == null) {
      return false;
    }

    _setSaving(true);

    _clearError();

    try {
      final updatedProfile = currentProfile.copyWith(
        displayName: displayName.trim(),
        username: username.trim(),
        bio: bio.trim(),
        avatarUrl: avatarUrl?.trim(),
      );

      _profile = await _repository.updateProfile(profile: updatedProfile);

      _notify();

      return true;
    } catch (error) {
      _setError('Não foi possível atualizar o perfil.');

      debugPrint(
        '[PUBLIC PROFILE] '
        'Erro ao atualizar perfil: '
        '$error',
      );

      return false;
    } finally {
      _setSaving(false);
    }
  }

  // ============================================================
  // ADICIONAR MÚSICA
  // ============================================================

  Future<ProfileTrackModel?> addTrack({
    required String title,
    required String fileName,
    required Uint8List bytes,
    required List<String> audienceRoles,
    String? mimeType,
    int? durationSeconds,
  }) async {
    final profile = _profile;

    if (_disposed || profile == null || !isOwner) {
      return null;
    }

    // ==========================================================
    // TÍTULO
    // ==========================================================

    final normalizedTitle = title.trim();

    if (normalizedTitle.isEmpty) {
      _setError('Informe o título da música.');

      return null;
    }

    // ==========================================================
    // ARQUIVO
    // ==========================================================

    if (bytes.isEmpty) {
      _setError('O arquivo selecionado está vazio.');

      return null;
    }

    // ==========================================================
    // AUDIÊNCIA
    // ==========================================================

    final normalizedAudienceRoles = _normalizeAudienceRoles(audienceRoles);

    if (normalizedAudienceRoles.isEmpty) {
      _setError('Escolha pelo menos um grupo que poderá ouvir a demo.');

      return null;
    }

    // ==========================================================
    // UPLOAD
    // ==========================================================

    _setUploadingTrack(true);

    _clearError();

    String? uploadedStoragePath;

    try {
      // ========================================================
      // STORAGE
      // ========================================================

      uploadedStoragePath = await _trackService.uploadTrack(
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
        storagePath: uploadedStoragePath,
        audienceRoles: normalizedAudienceRoles,
        durationSeconds: durationSeconds,
        mimeType: mimeType?.trim(),
        fileSizeBytes: bytes.length,
        position: _nextTrackPosition,
        isActive: true,
      );

      // ========================================================
      // BANCO
      // ========================================================

      final created = await _repository.createTrack(track: track);

      // ========================================================
      // ESTADO LOCAL
      // ========================================================

      if (!_disposed &&
          !_tracks.any((current) {
            return current.id == created.id;
          })) {
        final updatedTracks = <ProfileTrackModel>[..._tracks, created];

        updatedTracks.sort((a, b) {
          return a.position.compareTo(b.position);
        });

        _tracks = List<ProfileTrackModel>.unmodifiable(updatedTracks);

        _notify();
      }

      debugPrint(
        '[PUBLIC PROFILE] '
        'Demo adicionada: '
        '${created.title} | '
        'audience: '
        '${created.audienceRoles}',
      );

      return created;
    } catch (error) {
      // ========================================================
      // ROLLBACK DO STORAGE
      // ========================================================

      if (uploadedStoragePath != null && uploadedStoragePath.isNotEmpty) {
        try {
          await _trackService.deleteTrackFile(storagePath: uploadedStoragePath);
        } catch (rollbackError) {
          debugPrint(
            '[PUBLIC PROFILE] '
            'Erro no rollback do arquivo: '
            '$rollbackError',
          );
        }
      }

      _setError('Não foi possível adicionar a música.');

      debugPrint(
        '[PUBLIC PROFILE] '
        'Erro ao adicionar música: '
        '$error',
      );

      return null;
    } finally {
      _setUploadingTrack(false);
    }
  }

  // ============================================================
  // PRÓXIMA POSIÇÃO
  // ============================================================

  int get _nextTrackPosition {
    if (_tracks.isEmpty) {
      return 0;
    }

    var highestPosition = 0;

    for (final track in _tracks) {
      if (track.position > highestPosition) {
        highestPosition = track.position;
      }
    }

    return highestPosition + 1;
  }

  // ============================================================
  // REMOVER MÚSICA
  // ============================================================

  Future<bool> deleteTrack(ProfileTrackModel track) async {
    if (_disposed || !isOwner) {
      return false;
    }

    _clearError();

    try {
      // ========================================================
      // BANCO
      // ========================================================

      await _repository.deleteTrack(trackId: track.id);

      // ========================================================
      // STORAGE
      // ========================================================

      if (track.storagePath.trim().isNotEmpty) {
        await _trackService.deleteTrackFile(storagePath: track.storagePath);
      }

      // ========================================================
      // ESTADO LOCAL
      // ========================================================

      if (!_disposed) {
        _tracks = List<ProfileTrackModel>.unmodifiable(
          _tracks.where((current) {
            return current.id != track.id;
          }),
        );

        _notify();
      }

      return true;
    } catch (error) {
      _setError('Não foi possível remover a música.');

      debugPrint(
        '[PUBLIC PROFILE] '
        'Erro ao remover música: '
        '$error',
      );

      return false;
    }
  }

  // ============================================================
  // URL PARA REPRODUÇÃO
  // ============================================================

  Future<String> getTrackPlaybackUrl(ProfileTrackModel track) async {
    if (track.hasAudioUrl) {
      return track.audioUrl!;
    }

    if (track.storagePath.trim().isEmpty) {
      return '';
    }

    try {
      return await _trackService.createSignedUrl(
        storagePath: track.storagePath,
      );
    } catch (error) {
      debugPrint(
        '[PUBLIC PROFILE] '
        'Erro ao criar URL da música: '
        '$error',
      );

      return '';
    }
  }

  // ============================================================
  // PRIMEIRA DEMO + URL
  // ============================================================
  //
  // Helper útil para o Match.
  //
  // Não abre modal e não toca áudio.
  //
  // Apenas resolve:
  //
  // usuário
  //   ↓
  // primeira demo
  //   ↓
  // signed URL
  //
  // ============================================================

  Future<TrackPlaybackData?> getFirstTrackPlaybackForUser({
    required String userId,
  }) async {
    final track = await getFirstTrackForUser(userId: userId);

    if (track == null) {
      return null;
    }

    final url = await getTrackPlaybackUrl(track);

    if (url.isEmpty) {
      return TrackPlaybackData(track: track, url: '');
    }

    return TrackPlaybackData(track: track, url: url);
  }

  // ============================================================
  // ROLE PODE OUVIR?
  // ============================================================
  //
  // Validação útil para interface.
  //
  // Segurança real:
  //
  // - RLS;
  // - Storage Policy.
  //
  // ============================================================

  bool canRoleListenToTrack({
    required ProfileTrackModel track,
    required String role,
  }) {
    return track.allowsRole(role);
  }

  // ============================================================
  // USER ROLES PODEM OUVIR?
  // ============================================================

  bool canAnyRoleListenToTrack({
    required ProfileTrackModel track,
    required Iterable<String> roles,
  }) {
    return track.allowsAnyRole(roles);
  }

  // ============================================================
  // STREAM DAS MÚSICAS
  // ============================================================

  void _startTracksStream(String userId) {
    unawaited(_tracksSubscription?.cancel());

    _tracksSubscription = _repository
        .watchTracks(userId: userId)
        .listen(
          (tracks) {
            if (_disposed) {
              return;
            }

            _tracks = List<ProfileTrackModel>.unmodifiable(tracks);

            _notify();
          },
          onError: (error) {
            debugPrint(
              '[PUBLIC PROFILE] '
              'Erro no stream das músicas: '
              '$error',
            );
          },
        );
  }

  // ============================================================
  // NORMALIZAR AUDIÊNCIA
  // ============================================================

  List<String> _normalizeAudienceRoles(Iterable<String> roles) {
    final normalized = roles
        .map((role) {
          return role.trim().toLowerCase().replaceAll(' ', '_');
        })
        .where((role) {
          return role.isNotEmpty;
        })
        .toSet()
        .toList();

    normalized.sort();

    return List<String>.unmodifiable(normalized);
  }

  // ============================================================
  // LOADING
  // ============================================================

  void _setLoading(bool value) {
    if (_disposed || _isLoading == value) {
      return;
    }

    _isLoading = value;

    _notify();
  }

  // ============================================================
  // SAVING
  // ============================================================

  void _setSaving(bool value) {
    if (_disposed || _isSaving == value) {
      return;
    }

    _isSaving = value;

    _notify();
  }

  // ============================================================
  // UPLOAD
  // ============================================================

  void _setUploadingTrack(bool value) {
    if (_disposed || _isUploadingTrack == value) {
      return;
    }

    _isUploadingTrack = value;

    _notify();
  }

  // ============================================================
  // ERRO
  // ============================================================

  void _setError(String message) {
    if (_disposed) {
      return;
    }

    _errorMessage = message.trim();

    _notify();
  }

  void _clearError() {
    if (_disposed || _errorMessage == null) {
      return;
    }

    _errorMessage = null;

    _notify();
  }

  // ============================================================
  // LIMPAR ERRO PUBLICAMENTE
  // ============================================================

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

    unawaited(_tracksSubscription?.cancel());

    _tracksSubscription = null;

    super.dispose();
  }
}

// ============================================================
// TRACK PLAYBACK DATA
// ============================================================
//
// Resultado pronto para o Match:
//
// track + signed URL.
//
// Não contém player.
//
// ============================================================

class TrackPlaybackData {
  final ProfileTrackModel track;

  final String url;

  const TrackPlaybackData({required this.track, required this.url});

  bool get hasUrl => url.trim().isNotEmpty;
}
