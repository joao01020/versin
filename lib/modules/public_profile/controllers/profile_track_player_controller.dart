import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import 'package:versin/modules/public_profile/models/profile_track_model.dart';

// ============================================================
// PROFILE TRACK PLAYER CONTROLLER
// ============================================================
//
// Player reutilizável para demos.
//
// Fluxo:
//
// Cloudflare R2
//      ↓
// presigned HTTPS URL
//      ↓
// ProfileTrackPlayerController
//      ↓
// just_audio
//
// Responsabilidades:
//
// - carregar URL temporária;
// - play;
// - pause;
// - toggle;
// - seek;
// - stop;
// - limitar preview;
// - controlar posição;
// - controlar duração;
// - tratar conclusão;
// - tratar erros;
// - expor estado para UI.
//
// NÃO:
//
// - busca URL no R2;
// - chama Edge Function;
// - acessa Supabase;
// - verifica audience_roles;
// - registra likes.
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

  static const Duration previewLimit = Duration(seconds: 60);

  // ============================================================
  // ESTADO
  // ============================================================

  ProfileTrackModel? _track;

  bool _isLoading = false;

  bool _isCompleted = false;

  String? _errorMessage;

  Duration _position = Duration.zero;

  Duration _duration = Duration.zero;

  // ============================================================
  // STREAMS
  // ============================================================

  StreamSubscription<Duration>? _positionSubscription;

  StreamSubscription<Duration?>? _durationSubscription;

  StreamSubscription<PlayerState>? _stateSubscription;

  StreamSubscription<PlayerException>? _errorSubscription;

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

  bool get isCompleted => _isCompleted;

  String? get errorMessage => _errorMessage;

  bool get hasError => _errorMessage?.trim().isNotEmpty == true;

  bool get isPlaying => _player.playing && !_isCompleted;

  Duration get position => _position;

  Duration get duration => _effectiveDuration;

  bool get hasTrack => _track != null;

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

  String get formattedPosition => _formatDuration(_position);

  String get formattedDuration => _formatDuration(_effectiveDuration);

  // ============================================================
  // LOAD
  // ============================================================

  Future<bool> load({
    required ProfileTrackModel track,
    required String url,
  }) async {
    final normalizedUrl = url.trim();

    if (_disposed || normalizedUrl.isEmpty) {
      return false;
    }

    _setLoading(true);

    _clearError();

    _isCompleted = false;

    try {
      // ========================================================
      // PARAR PLAYER ANTERIOR
      // ========================================================

      await _player.stop();

      if (_disposed) {
        return false;
      }

      // ========================================================
      // ESTADO
      // ========================================================

      _track = track;

      _position = Duration.zero;

      _duration = Duration.zero;

      // ========================================================
      // URL TEMPORÁRIA R2
      // ========================================================

      final duration = await _player.setUrl(normalizedUrl);

      if (_disposed) {
        return false;
      }

      _duration = duration ?? Duration.zero;

      // ========================================================
      // LIMITAR A 60 SEGUNDOS
      // ========================================================

      if (_duration > previewLimit) {
        await _player.setClip(start: Duration.zero, end: previewLimit);
      }

      if (_disposed) {
        return false;
      }

      _notify();

      debugPrint(
        '[TRACK PLAYER] '
        'Demo carregada: '
        '${track.title}',
      );

      return true;
    } on PlayerException catch (error) {
      _setError('Não foi possível carregar a demo.');

      debugPrint(
        '[TRACK PLAYER] '
        'PlayerException: '
        '${error.code} | '
        '${error.message}',
      );

      return false;
    } on PlayerInterruptedException catch (error) {
      _setError('O carregamento da demo foi interrompido.');

      debugPrint(
        '[TRACK PLAYER] '
        'Carregamento interrompido: '
        '${error.message}',
      );

      return false;
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

    return !hasError;
  }

  // ============================================================
  // PLAY
  // ============================================================

  Future<void> play() async {
    if (_disposed || _track == null || _isLoading) {
      return;
    }

    _clearError();

    try {
      // ========================================================
      // REPLAY
      // ========================================================

      if (_isCompleted || _position >= _effectiveDuration) {
        await _player.seek(Duration.zero);

        _position = Duration.zero;

        _isCompleted = false;
      }

      // ========================================================
      // PLAY
      // ========================================================

      unawaited(_player.play());

      _notify();
    } on PlayerException catch (error) {
      _setError('Não foi possível reproduzir a demo.');

      debugPrint(
        '[TRACK PLAYER] '
        'Erro de reprodução: '
        '${error.code} | '
        '${error.message}',
      );
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

    try {
      await _player.pause();

      _notify();
    } catch (error) {
      debugPrint(
        '[TRACK PLAYER] '
        'Erro ao pausar: '
        '$error',
      );
    }
  }

  // ============================================================
  // TOGGLE
  // ============================================================

  Future<void> toggle() async {
    if (_disposed || _isLoading || _track == null) {
      return;
    }

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
    if (_disposed || _track == null) {
      return;
    }

    var normalized = position;

    if (normalized < Duration.zero) {
      normalized = Duration.zero;
    }

    if (normalized > _effectiveDuration) {
      normalized = _effectiveDuration;
    }

    try {
      await _player.seek(normalized);

      _position = normalized;

      _isCompleted = normalized >= _effectiveDuration;

      _notify();
    } catch (error) {
      debugPrint(
        '[TRACK PLAYER] '
        'Erro ao buscar posição: '
        '$error',
      );
    }
  }

  // ============================================================
  // SEEK POR PROGRESSO
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

    try {
      await _player.stop();

      _position = Duration.zero;

      _isCompleted = false;

      _notify();
    } catch (error) {
      debugPrint(
        '[TRACK PLAYER] '
        'Erro ao parar: '
        '$error',
      );
    }
  }

  // ============================================================
  // CLEAR
  // ============================================================

  Future<void> clear() async {
    if (_disposed) {
      return;
    }

    try {
      await _player.stop();
    } catch (_) {
      // Ignora falha no cleanup.
    }

    _track = null;

    _position = Duration.zero;

    _duration = Duration.zero;

    _isCompleted = false;

    _clearError();

    _notify();
  }

  // ============================================================
  // STREAMS
  // ============================================================

  void _setupStreams() {
    // ==========================================================
    // POSITION
    // ==========================================================

    _positionSubscription = _player.positionStream.listen((position) {
      if (_disposed) {
        return;
      }

      final effectiveDuration = _effectiveDuration;

      if (position > effectiveDuration) {
        _position = effectiveDuration;
      } else {
        _position = position;
      }

      // ======================================================
      // GARANTIR LIMITE DE PREVIEW
      // ======================================================

      if (_position >= effectiveDuration) {
        _isCompleted = true;

        unawaited(_player.pause());
      }

      _notify();
    });

    // ==========================================================
    // DURATION
    // ==========================================================

    _durationSubscription = _player.durationStream.listen((duration) {
      if (_disposed) {
        return;
      }

      _duration = duration ?? Duration.zero;

      _notify();
    });

    // ==========================================================
    // PLAYER STATE
    // ==========================================================

    _stateSubscription = _player.playerStateStream.listen((state) {
      if (_disposed) {
        return;
      }

      // ======================================================
      // COMPLETED
      // ======================================================

      if (state.processingState == ProcessingState.completed) {
        _isCompleted = true;

        _position = _effectiveDuration;

        unawaited(_player.pause());
      }

      // ======================================================
      // NOVA REPRODUÇÃO
      // ======================================================

      if (state.processingState == ProcessingState.ready &&
          _position < _effectiveDuration) {
        _isCompleted = false;
      }

      _notify();
    });

    // ==========================================================
    // ERROS ASSÍNCRONOS
    // ==========================================================

    _errorSubscription = _player.errorStream.listen((error) {
      if (_disposed) {
        return;
      }

      _setError('A reprodução da demo foi interrompida.');

      debugPrint(
        '[TRACK PLAYER] '
        'Erro assíncrono: '
        '${error.code} | '
        '${error.message}',
      );
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

  void clearError() {
    _clearError();
  }

  // ============================================================
  // FORMAT DURATION
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

    unawaited(_errorSubscription?.cancel());

    unawaited(_player.dispose());

    super.dispose();
  }
}
