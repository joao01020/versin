import 'package:flutter/foundation.dart';

import 'package:versin/modules/public_profile/controllers/public_profile_controller.dart';
import 'package:versin/modules/public_profile/models/profile_track_model.dart';

// ============================================================
// MATCH DEMO RESULT
// ============================================================
//
// Resultado preparado para a UI.
//
// O controller entrega:
//
// - track;
// - URL temporária;
// - informação sobre existência da demo.
//
// A View não precisa conhecer a lógica usada para obter
// a primeira música pública do profissional.
//
// ============================================================

class MatchDemoResult {
  final ProfileTrackModel? track;

  final String? playbackUrl;

  const MatchDemoResult({
    required this.track,
    required this.playbackUrl,
  });

  // ============================================================
  // HAS TRACK
  // ============================================================

  bool get hasTrack {
    return track !=
        null;
  }

  // ============================================================
  // HAS URL
  // ============================================================

  bool get hasUrl {
    final url = playbackUrl?.trim();

    return url !=
            null &&
        url.isNotEmpty;
  }
}

// ============================================================
// MATCH DEMO CONTROLLER
// ============================================================
//
// Responsabilidade:
//
// Match
//   ↓
// usuário toca em "OUVIR DEMO"
//   ↓
// MatchDemoController
//   ↓
// PublicProfileController
//   ↓
// getFirstTrackPlaybackForUser()
//   ↓
// track + signed playback URL
//
// IMPORTANTE:
//
// Utilizamos getFirstTrackPlaybackForUser().
//
// NÃO devemos fazer:
//
// getFirstTrack()
// +
// getPlaybackUrl()
//
// separadamente.
//
// Isso evita gerar mais de uma URL temporária para a mesma
// abertura da demo.
//
// NÃO:
//
// - conhece BuildContext;
// - abre BottomSheet;
// - mostra SnackBar;
// - conhece MatchPage;
// - controla reprodução do áudio.
//
// ============================================================

class MatchDemoController
    extends
        ChangeNotifier {
  // ============================================================
  // PUBLIC PROFILE
  // ============================================================

  final PublicProfileController publicProfileController;

  // ============================================================
  // STATE
  // ============================================================

  bool _isLoading = false;

  String? _loadingUserId;

  String? _errorMessage;

  // ============================================================
  // DISPOSED
  // ============================================================

  bool _disposed = false;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  MatchDemoController({
    required this.publicProfileController,
  });

  // ============================================================
  // GETTERS
  // ============================================================

  bool get isLoading {
    return _isLoading;
  }

  String? get loadingUserId {
    return _loadingUserId;
  }

  String? get errorMessage {
    return _errorMessage;
  }

  bool get hasError {
    final error = _errorMessage?.trim();

    return error !=
            null &&
        error.isNotEmpty;
  }

  // ============================================================
  // IS LOADING USER
  // ============================================================

  bool isLoadingUser(
    String userId,
  ) {
    final normalizedUserId = userId.trim();

    if (normalizedUserId.isEmpty) {
      return false;
    }

    return _isLoading &&
        _loadingUserId ==
            normalizedUserId;
  }

  // ============================================================
  // LOAD
  // ============================================================

  Future<
    MatchDemoResult?
  >
  load({
    required String userId,
  }) async {
    final normalizedUserId = userId.trim();

    // ==========================================================
    // VALIDATION
    // ==========================================================

    if (normalizedUserId.isEmpty) {
      throw ArgumentError(
        'userId não pode ficar vazio.',
      );
    }

    // ==========================================================
    // DUPLICATE REQUEST
    // ==========================================================

    if (_isLoading) {
      debugPrint(
        '[MATCH DEMO CONTROLLER] '
        'Solicitação ignorada: '
        'uma demo já está carregando.',
      );

      return null;
    }

    // ==========================================================
    // LOADING
    // ==========================================================

    _isLoading = true;

    _loadingUserId = normalizedUserId;

    _errorMessage = null;

    _safeNotify();

    try {
      debugPrint(
        '[MATCH DEMO CONTROLLER] '
        'Buscando demo de: '
        '$normalizedUserId',
      );

      // ========================================================
      // TRACK + PLAYBACK URL
      // ========================================================

      final playback = await publicProfileController.getFirstTrackPlaybackForUser(
        userId: normalizedUserId,
      );

      // ========================================================
      // NO TRACK
      // ========================================================

      if (playback ==
          null) {
        debugPrint(
          '[MATCH DEMO CONTROLLER] '
          'Usuário sem demo.',
        );

        return const MatchDemoResult(
          track: null,
          playbackUrl: null,
        );
      }

      // ========================================================
      // TRACK
      // ========================================================

      debugPrint(
        '[MATCH DEMO CONTROLLER] '
        'Track encontrada: '
        '${playback.track.title}',
      );

      // ========================================================
      // URL
      // ========================================================

      if (playback.hasUrl) {
        debugPrint(
          '[MATCH DEMO CONTROLLER] '
          'Playback URL disponível.',
        );
      } else {
        debugPrint(
          '[MATCH DEMO CONTROLLER] '
          'Playback URL indisponível.',
        );
      }

      // ========================================================
      // RESULT
      // ========================================================

      return MatchDemoResult(
        track: playback.track,

        playbackUrl: playback.url,
      );
    } catch (
      error,
      stackTrace
    ) {
      _errorMessage = 'Não foi possível carregar a demo.';

      debugPrint(
        '[MATCH DEMO CONTROLLER] '
        'Erro ao carregar demo: '
        '$error',
      );

      debugPrint(
        '[MATCH DEMO CONTROLLER] '
        'Stack trace: '
        '$stackTrace',
      );

      rethrow;
    } finally {
      _isLoading = false;

      _loadingUserId = null;

      _safeNotify();
    }
  }

  // ============================================================
  // CLEAR ERROR
  // ============================================================

  void clearError() {
    if (_errorMessage ==
        null) {
      return;
    }

    _errorMessage = null;

    _safeNotify();
  }

  // ============================================================
  // SAFE NOTIFY
  // ============================================================

  void _safeNotify() {
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

    super.dispose();
  }
}
