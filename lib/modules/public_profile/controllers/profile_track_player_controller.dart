import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../models/profile_track_model.dart';

// ============================================================
// PROFILE TRACK PLAYER CONTROLLER
// ============================================================
//
// Player compartilhável para demos do perfil/Match.
//
// Responsabilidades:
//
// - carregar URL;
// - play;
// - pause;
// - toggle;
// - stop;
// - seek;
// - limitar reprodução de preview;
// - expor posição/duração;
// - controlar loading/erro.
//
// NÃO:
//
// - busca signed URL;
// - verifica RLS;
// - acessa Supabase;
// - registra like.
//
// ============================================================

class ProfileTrackPlayerController extends ChangeNotifier {
  // ============================================================
  // PLAYER
  // ============================================================

  final AudioPlayer _player = AudioPlayer();

  // ============================================================
  // PREVIEW
  // ============================================================
  //
  // O player pode tocar no máximo 60 segundos.
  //
  // ============================================================

  static const Duration previewLimit = Duration(seconds: 60);

  // ============================================================
  // STATE
  // ============================================================

  ProfileTrackModel? _track;

  bool _isLoading = false;

  String? _errorMessage;

  Duration _position = Duration.zero;

  Duration _duration = Duration.zero;

  // ============================================================
  // STREAMS
  // ============================================================

  StreamSubscription<Duration>? _positionSubscription;

  StreamSubscription<Duration?>? _durationSubscription;

  StreamSubscription<PlayerState>? _stateSubscription;

  // ============================================================
  // DISPOSE
  // ============================================================

  bool _disposed = false;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  ProfileTrackPlayerController() {
    _setupStreams();
  }

  // ============================================================
  // GETTERS
  // ============================================================

  ProfileTrackModel? get track => _track;

  String? get trackId => _track?.id;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  bool get hasError => _errorMessage?.isNotEmpty == true;

  bool get isPlaying => _player.playing;

  Duration get position => _position;

  Duration get duration => _effectiveDuration;

  // ============================================================
  // DURAÇÃO EFETIVA
  // ============================================================

  Duration get _effectiveDuration {
    if (_duration == Duration.zero) {
      return previewLimit;
    }

    if (_duration > previewLimit) {
      return previewLimit;
    }

    return _duration;
  }

  // ============================================================
  // PROGRESS
  // ============================================================

  double get progress {
    final total = _effectiveDuration.inMilliseconds;

    if (total <= 0) {
      return 0;
    }

    final current = _position.inMilliseconds;

    return (current / total).clamp(0.0, 1.0);
  }

  // ============================================================
  // FORMAT
  // ============================================================

  String get formattedPosition {
    return _formatDuration(_position);
  }

  String get formattedDuration {
    return _formatDuration(_effectiveDuration);
  }

  // ============================================================
  // LOAD
  // ============================================================

  Future<bool> load({
    required ProfileTrackModel track,
    required String url,
  }) async {
    final normalizedUrl = url.trim();

    if (normalizedUrl.isEmpty || _disposed) {
      return false;
    }

    _setLoading(true);

    _clearError();

    try {
      await _player.stop();

      _track = track;

      _position = Duration.zero;

      final duration = await _player.setUrl(normalizedUrl);

      _duration = duration ?? Duration.zero;

      // ========================================================
      // CLIP
      // ========================================================

      if (_duration > previewLimit) {
        await _player.setClip(start: Duration.zero, end: previewLimit);
      }

      _notify();

      return true;
    } catch (error) {
      _setError('Não foi possível carregar a demo.');

      debugPrint(
        '[TRACK PLAYER] '
        'Erro ao carregar demo: '
        '$error',
      );

      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // LOAD AND PLAY
  // ============================================================

  Future<bool> loadAndPlay({
    required ProfileTrackModel track,
    required String url,
  }) async {
    final loaded = await load(track: track, url: url);

    if (!loaded) {
      return false;
    }

    await play();

    return true;
  }

  // ============================================================
  // PLAY
  // ============================================================

  Future<void> play() async {
    if (_disposed || _track == null) {
      return;
    }

    if (_position >= _effectiveDuration) {
      await seek(Duration.zero);
    }

    try {
      await _player.play();
    } catch (error) {
      _setError('Não foi possível reproduzir a demo.');

      debugPrint(
        '[TRACK PLAYER] '
        'Erro ao reproduzir: '
        '$error',
      );
    }
  }

  // ============================================================
  // PAUSE
  // ============================================================

  Future<void> pause() async {
    if (_disposed) {
      return;
    }

    await _player.pause();
  }

  // ============================================================
  // TOGGLE
  // ============================================================

  Future<void> toggle() async {
    if (isPlaying) {
      await pause();

      return;
    }

    await play();
  }

  // ============================================================
  // SEEK
  // ============================================================

  Future<void> seek(Duration position) async {
    if (_disposed) {
      return;
    }

    var normalized = position;

    if (normalized < Duration.zero) {
      normalized = Duration.zero;
    }

    if (normalized > _effectiveDuration) {
      normalized = _effectiveDuration;
    }

    await _player.seek(normalized);
  }

  // ============================================================
  // SEEK POR PROGRESS
  // ============================================================

  Future<void> seekToProgress(double value) async {
    final normalized = value.clamp(0.0, 1.0);

    final milliseconds = (_effectiveDuration.inMilliseconds * normalized)
        .round();

    await seek(Duration(milliseconds: milliseconds));
  }

  // ============================================================
  // STOP
  // ============================================================

  Future<void> stop() async {
    if (_disposed) {
      return;
    }

    await _player.stop();

    _position = Duration.zero;

    _notify();
  }

  // ============================================================
  // CLEAR
  // ============================================================

  Future<void> clear() async {
    if (_disposed) {
      return;
    }

    await _player.stop();

    _track = null;

    _position = Duration.zero;

    _duration = Duration.zero;

    _clearError();

    _notify();
  }

  // ============================================================
  // STREAMS
  // ============================================================

  void _setupStreams() {
    _positionSubscription = _player.positionStream.listen((position) {
      if (_disposed) {
        return;
      }

      _position = position;

      if (_position >= _effectiveDuration) {
        unawaited(_player.pause());
      }

      _notify();
    });

    _durationSubscription = _player.durationStream.listen((duration) {
      if (_disposed) {
        return;
      }

      _duration = duration ?? Duration.zero;

      _notify();
    });

    _stateSubscription = _player.playerStateStream.listen((_) {
      _notify();
    });
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
  // ERROR
  // ============================================================

  void _setError(String message) {
    if (_disposed) {
      return;
    }

    _errorMessage = message;

    _notify();
  }

  void _clearError() {
    if (_disposed || _errorMessage == null) {
      return;
    }

    _errorMessage = null;

    _notify();
  }

  void clearError() {
    _clearError();
  }

  // ============================================================
  // FORMAT
  // ============================================================

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;

    final seconds = duration.inSeconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
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

    unawaited(_positionSubscription?.cancel());

    unawaited(_durationSubscription?.cancel());

    unawaited(_stateSubscription?.cancel());

    unawaited(_player.dispose());

    super.dispose();
  }
}
