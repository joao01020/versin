import 'package:flutter/foundation.dart';

import 'package:versin/modules/match/controllers/match_controllers.dart';
import 'package:versin/modules/match/models/match_discovery_mode.dart';
import 'package:versin/modules/match/services/match_session_service.dart';

// ============================================================
// MATCH DISCOVERY CONTROLLER
// ============================================================
//
// Controla exclusivamente a troca do modo de descoberta.
//
// Responsabilidades:
//
// - expor modo atual;
// - controlar loading da troca;
// - impedir chamadas duplicadas;
// - utilizar MatchSessionService;
// - expor erro;
//
// NÃO:
//
// - abre dialogs;
// - pede localização;
// - ativa Disponíveis agora;
// - mostra SnackBar;
// - conhece BuildContext;
// - controla UI.
//
// Os guards específicos:
//
// - Próximos -> consentimento;
// - Agora -> disponibilidade;
//
// continuam sendo executados pelo nível superior antes de
// chamar changeMode().
//
// ============================================================

class MatchDiscoveryController
    extends
        ChangeNotifier {
  // ============================================================
  // DEPENDENCIES
  // ============================================================

  final MatchController matchController;

  final MatchSessionService sessionService;

  // ============================================================
  // STATE
  // ============================================================

  bool _isChangingMode = false;

  String? _errorMessage;

  bool _disposed = false;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  MatchDiscoveryController({
    required this.matchController,
    required this.sessionService,
  });

  // ============================================================
  // GETTERS
  // ============================================================

  MatchDiscoveryMode get activeMode {
    return matchController.discoveryMode;
  }

  bool get isChangingMode {
    return _isChangingMode;
  }

  bool get isRestarting {
    return sessionService.isRestarting;
  }

  bool get isBusy {
    return _isChangingMode ||
        sessionService.isRestarting;
  }

  String? get errorMessage {
    return _errorMessage;
  }

  bool get hasError {
    final value = _errorMessage?.trim();

    return value !=
            null &&
        value.isNotEmpty;
  }

  // ============================================================
  // IS SELECTED
  // ============================================================

  bool isSelected(
    MatchDiscoveryMode mode,
  ) {
    return activeMode ==
        mode;
  }

  // ============================================================
  // CHANGE MODE
  // ============================================================

  Future<
    bool
  >
  changeMode(
    MatchDiscoveryMode mode,
  ) async {
    if (_disposed ||
        isBusy) {
      return false;
    }

    // ==========================================================
    // JÁ ESTÁ ATIVO
    // ==========================================================

    if (activeMode ==
        mode) {
      return true;
    }

    // ==========================================================
    // LOADING
    // ==========================================================

    _isChangingMode = true;

    _errorMessage = null;

    _safeNotify();

    try {
      debugPrint(
        '[MATCH DISCOVERY] '
        'Alterando modo: '
        '${activeMode.name} -> ${mode.name}',
      );

      await sessionService.changeDiscoveryMode(
        mode,
      );

      if (_disposed) {
        return false;
      }

      debugPrint(
        '[MATCH DISCOVERY] '
        'Modo alterado para: '
        '${mode.name}',
      );

      return true;
    } catch (
      error,
      stackTrace
    ) {
      _errorMessage =
          'Não foi possível alterar '
          'o modo de descoberta.';

      debugPrint(
        '[MATCH DISCOVERY] '
        'Erro ao alterar modo: '
        '$error',
      );

      debugPrint(
        '[MATCH DISCOVERY] '
        'Stack trace: '
        '$stackTrace',
      );

      return false;
    } finally {
      if (!_disposed) {
        _isChangingMode = false;

        _safeNotify();
      }
    }
  }

  // ============================================================
  // COMPATIBLE
  // ============================================================

  Future<
    bool
  >
  useCompatible() {
    return changeMode(
      MatchDiscoveryMode.compatible,
    );
  }

  // ============================================================
  // NEARBY
  // ============================================================
  //
  // O consentimento de localização deve ser validado ANTES.
  //
  // ============================================================

  Future<
    bool
  >
  useNearby() {
    return changeMode(
      MatchDiscoveryMode.nearby,
    );
  }

  // ============================================================
  // AVAILABLE NOW
  // ============================================================
  //
  // A disponibilidade deve ser validada/ativada ANTES.
  //
  // ============================================================

  Future<
    bool
  >
  useAvailableNow() {
    return changeMode(
      MatchDiscoveryMode.global,
    );
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
