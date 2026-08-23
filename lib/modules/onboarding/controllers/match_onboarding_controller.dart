import 'dart:async';

import 'package:flutter/material.dart';

import 'package:versin/modules/match/controllers/match_controllers.dart';

// ============================================================
// MATCH ONBOARDING CONTROLLER
// ============================================================
//
// Controla exclusivamente a interação do onboarding de username.
//
// Responsabilidades:
//
// - TextEditingController;
// - FocusNode;
// - debounce;
// - sincronização com MatchController;
// - validação;
// - disponibilidade;
// - salvamento.
//
// A regra de negócio do username continua no MatchController.
//
// ============================================================

class MatchOnboardingController
    extends
        ChangeNotifier {
  // ============================================================
  // MATCH
  // ============================================================

  final MatchController matchController;

  // ============================================================
  // INPUT
  // ============================================================

  final TextEditingController usernameController = TextEditingController();

  final FocusNode usernameFocusNode = FocusNode();

  // ============================================================
  // DEBOUNCE
  // ============================================================

  Timer? _usernameDebounce;

  static const Duration _debounceDuration = Duration(
    milliseconds: 450,
  );

  // ============================================================
  // STATE
  // ============================================================

  bool _usernameWasSeeded = false;

  bool _disposed = false;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  MatchOnboardingController({
    required this.matchController,
  });

  // ============================================================
  // GETTERS
  // ============================================================

  bool get requiresUsername {
    return matchController.requiresUsername;
  }

  bool get requiresProfessionalProfile {
    return matchController.requiresProfessionalProfile;
  }

  bool get isMatchUnlocked {
    return matchController.isMatchUnlocked;
  }

  bool get isCheckingUsername {
    return matchController.isCheckingUsername;
  }

  bool get isSavingUsername {
    return matchController.isSavingUsername;
  }

  bool get canSubmitUsername {
    return matchController.canSubmitUsername;
  }

  bool? get usernameAvailable {
    return matchController.usernameAvailable;
  }

  String? get usernameValidationMessage {
    return matchController.usernameValidationMessage;
  }

  String get currentUsername {
    return matchController.currentUsername;
  }

  // ============================================================
  // INITIALIZE
  // ============================================================

  void initialize() {
    syncUsername();

    matchController.addListener(
      _handleMatchControllerChanged,
    );
  }

  // ============================================================
  // MATCH CONTROLLER CHANGED
  // ============================================================

  void _handleMatchControllerChanged() {
    if (_disposed) {
      return;
    }

    syncUsername();

    notifyListeners();
  }

  // ============================================================
  // SYNC USERNAME
  // ============================================================
  //
  // Antes esta lógica estava diretamente na MatchPage.
  //
  // Não sobrescrevemos o campo enquanto o usuário estiver
  // digitando.
  //
  // ============================================================

  void syncUsername() {
    final username = matchController.currentUsername.trim();

    if (username.isEmpty) {
      return;
    }

    if (usernameFocusNode.hasFocus) {
      return;
    }

    if (_usernameWasSeeded &&
        usernameController.text.trim() ==
            username) {
      return;
    }

    _usernameWasSeeded = true;

    usernameController.value = TextEditingValue(
      text: username,

      selection: TextSelection.collapsed(
        offset: username.length,
      ),
    );
  }

  // ============================================================
  // REQUEST USERNAME FOCUS
  // ============================================================

  void requestUsernameFocus() {
    if (_disposed) {
      return;
    }

    usernameFocusNode.requestFocus();
  }

  // ============================================================
  // UNFOCUS
  // ============================================================

  void unfocusUsername() {
    if (_disposed) {
      return;
    }

    usernameFocusNode.unfocus();
  }

  // ============================================================
  // USERNAME CHANGED
  // ============================================================

  void onUsernameChanged(
    String value,
  ) {
    _usernameDebounce?.cancel();

    matchController.resetUsernameCheck();

    final validationError = matchController.validateUsername(
      value,
    );

    // ==========================================================
    // LOCAL VALIDATION ERROR
    // ==========================================================
    //
    // Mantemos o mesmo comportamento que existia na MatchPage:
    //
    // checkUsernameAvailability() é chamado imediatamente para
    // que o MatchController publique a mensagem visual.
    //
    // ==========================================================

    if (validationError !=
        null) {
      unawaited(
        matchController.checkUsernameAvailability(
          value,
        ),
      );

      return;
    }

    // ==========================================================
    // DEBOUNCE
    // ==========================================================

    _usernameDebounce = Timer(
      _debounceDuration,
      () {
        if (_disposed) {
          return;
        }

        unawaited(
          matchController.checkUsernameAvailability(
            value,
          ),
        );
      },
    );
  }

  // ============================================================
  // SUBMIT FROM KEYBOARD
  // ============================================================

  Future<
    bool
  >
  submitFromKeyboard() async {
    if (!canSubmitUsername) {
      return false;
    }

    return saveUsername();
  }

  // ============================================================
  // SAVE USERNAME
  // ============================================================

  Future<
    bool
  >
  saveUsername() async {
    if (_disposed ||
        !matchController.canSubmitUsername) {
      return false;
    }

    _usernameDebounce?.cancel();

    final saved = await matchController.saveUsername(
      usernameController.text,
    );

    if (_disposed ||
        !saved) {
      return false;
    }

    usernameFocusNode.unfocus();

    // ==========================================================
    // NEXT ONBOARDING STEP
    // ==========================================================
    //
    // Depois do username, o próximo requisito obrigatório
    // continua sendo o perfil profissional.
    //
    // ==========================================================

    matchController.requestProfessionalProfileAttention();

    notifyListeners();

    return true;
  }

  // ============================================================
  // ENSURE INTERACTION ALLOWED
  // ============================================================
  //
  // Centraliza a parte de onboarding do antigo:
  //
  // _ensureMatchUnlockedForInteraction()
  //
  // ============================================================

  bool ensureMatchUnlockedForInteraction() {
    if (matchController.isMatchUnlocked) {
      return true;
    }

    if (matchController.requiresUsername) {
      requestUsernameFocus();

      return false;
    }

    if (matchController.requiresProfessionalProfile) {
      matchController.requestProfessionalProfileAttention();

      return false;
    }

    return false;
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

    _usernameDebounce?.cancel();

    _usernameDebounce = null;

    matchController.removeListener(
      _handleMatchControllerChanged,
    );

    usernameController.dispose();

    usernameFocusNode.dispose();

    super.dispose();
  }
}
