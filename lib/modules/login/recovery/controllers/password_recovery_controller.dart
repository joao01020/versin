import 'package:flutter/foundation.dart';

import '../models/password_recovery_state.dart';
import '../services/password_recovery_service.dart';

// ============================================================
// PASSWORD RECOVERY CONTROLLER
// ============================================================
//
// Responsável pelo estado do fluxo de recuperação.
//
// Este controller:
//
// - valida email;
// - solicita envio do email;
// - valida nova senha;
// - confirma as duas senhas;
// - solicita atualização da senha;
// - expõe estado para a UI.
//
// NÃO:
//
// - conhece BuildContext;
// - navega entre páginas;
// - exibe SnackBar;
// - acessa Supabase diretamente;
// - decide URL de redirect;
// - conhece Web, Linux, Windows ou macOS.
//
// A decisão da URL de recuperação pertence ao:
//
// PasswordRecoveryService
//
// ============================================================

class PasswordRecoveryController
    extends
        ChangeNotifier {
  // ==========================================================
  // SERVICE
  // ==========================================================

  final PasswordRecoveryService service;

  // ==========================================================
  // STATE
  // ==========================================================

  PasswordRecoveryState _state = PasswordRecoveryState.initial;

  // ==========================================================
  // CONSTRUCTOR
  // ==========================================================

  PasswordRecoveryController({
    PasswordRecoveryService? service,
  }) : service =
           service ??
           PasswordRecoveryService();

  // ==========================================================
  // GETTERS
  // ==========================================================

  PasswordRecoveryState get state => _state;

  PasswordRecoveryStep get step => _state.step;

  bool get isLoading => _state.isLoading;

  bool get isSendingEmail => _state.isSendingEmail;

  bool get emailSent => _state.emailSent;

  bool get isUpdatingPassword => _state.isUpdatingPassword;

  bool get passwordUpdated => _state.passwordUpdated;

  bool get hasError => _state.hasError;

  String? get errorMessage => _state.errorMessage;

  // ==========================================================
  // REQUEST PASSWORD RESET
  // ==========================================================
  //
  // A UI informa somente o email.
  //
  // O controller:
  //
  // - normaliza;
  // - valida;
  // - controla loading;
  // - chama o service.
  //
  // O service decide automaticamente:
  //
  // Web:
  //   http(s)://host/reset-password
  //
  // Desktop:
  //   versin://auth/reset-password
  //
  // ==========================================================

  Future<
    bool
  >
  requestReset({
    required String email,
  }) async {
    // ========================================================
    // EVITA REQUISIÇÕES DUPLICADAS
    // ========================================================

    if (_state.isLoading) {
      return false;
    }

    // ========================================================
    // NORMALIZAR EMAIL
    // ========================================================

    final normalizedEmail = email.trim().toLowerCase();

    // ========================================================
    // VALIDAR EMAIL
    // ========================================================

    final emailError = _validateEmail(
      normalizedEmail,
    );

    if (emailError !=
        null) {
      _setError(
        emailError,
      );

      return false;
    }

    // ========================================================
    // LOADING
    // ========================================================

    _setState(
      const PasswordRecoveryState(
        step: PasswordRecoveryStep.sendingEmail,
      ),
    );

    try {
      // ======================================================
      // SERVICE
      // ======================================================
      //
      // O redirect não é mais informado aqui.
      //
      // PasswordRecoveryService resolve automaticamente
      // de acordo com a plataforma.
      //
      // ======================================================

      await service.requestPasswordReset(
        email: normalizedEmail,
      );

      // ======================================================
      // SUCCESS
      // ======================================================

      _setState(
        const PasswordRecoveryState(
          step: PasswordRecoveryStep.emailSent,
        ),
      );

      debugPrint(
        '[PASSWORD RECOVERY CONTROLLER] '
        'Solicitação de recuperação processada.',
      );

      return true;
    } catch (
      error,
      stackTrace
    ) {
      // ======================================================
      // LOG INTERNO
      // ======================================================

      debugPrint(
        '[PASSWORD RECOVERY CONTROLLER] '
        'Erro ao solicitar recuperação: '
        '$error',
      );

      debugPrint(
        '[PASSWORD RECOVERY CONTROLLER] '
        'Stack trace: '
        '$stackTrace',
      );

      // ======================================================
      // MENSAGEM GENÉRICA
      // ======================================================
      //
      // Não informamos se determinado email existe.
      //
      // Isso evita enumeração de contas.
      //
      // ======================================================

      _setError(
        'Não foi possível processar a solicitação agora. '
        'Tente novamente em alguns instantes.',
      );

      return false;
    }
  }

  // ==========================================================
  // CHANGE PASSWORD
  // ==========================================================

  Future<
    bool
  >
  changePassword({
    required String password,
    required String confirmation,
  }) async {
    // ========================================================
    // EVITA REQUISIÇÕES DUPLICADAS
    // ========================================================

    if (_state.isLoading) {
      return false;
    }

    // ========================================================
    // VALIDAR NOVA SENHA
    // ========================================================
    //
    // Não usamos trim() na senha.
    //
    // Espaços podem fazer parte de uma senha válida.
    //
    // ========================================================

    final passwordError = _validatePassword(
      password,
    );

    if (passwordError !=
        null) {
      _setError(
        passwordError,
      );

      return false;
    }

    // ========================================================
    // CONFIRMAÇÃO
    // ========================================================

    if (password !=
        confirmation) {
      _setError(
        'As senhas não coincidem.',
      );

      return false;
    }

    // ========================================================
    // LOADING
    // ========================================================

    _setState(
      const PasswordRecoveryState(
        step: PasswordRecoveryStep.updatingPassword,
      ),
    );

    try {
      // ======================================================
      // SERVICE
      // ======================================================

      await service.updatePassword(
        newPassword: password,
      );

      // ======================================================
      // SUCCESS
      // ======================================================

      _setState(
        const PasswordRecoveryState(
          step: PasswordRecoveryStep.passwordUpdated,
        ),
      );

      debugPrint(
        '[PASSWORD RECOVERY CONTROLLER] '
        'Senha atualizada com sucesso.',
      );

      return true;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[PASSWORD RECOVERY CONTROLLER] '
        'Erro ao atualizar senha: '
        '$error',
      );

      debugPrint(
        '[PASSWORD RECOVERY CONTROLLER] '
        'Stack trace: '
        '$stackTrace',
      );

      _setError(
        'Não foi possível atualizar sua senha. '
        'Solicite um novo link de recuperação e tente novamente.',
      );

      return false;
    }
  }

  // ==========================================================
  // VALIDATE EMAIL
  // ==========================================================

  String? _validateEmail(
    String email,
  ) {
    if (email.isEmpty) {
      return 'Informe seu email.';
    }

    if (email.length >
        254) {
      return 'Informe um email válido.';
    }

    final atIndex = email.indexOf(
      '@',
    );

    if (atIndex <=
        0) {
      return 'Informe um email válido.';
    }

    if (atIndex !=
        email.lastIndexOf(
          '@',
        )) {
      return 'Informe um email válido.';
    }

    if (atIndex >=
        email.length -
            1) {
      return 'Informe um email válido.';
    }

    final localPart = email.substring(
      0,
      atIndex,
    );

    final domain = email.substring(
      atIndex +
          1,
    );

    if (localPart.isEmpty ||
        domain.isEmpty) {
      return 'Informe um email válido.';
    }

    if (!domain.contains(
      '.',
    )) {
      return 'Informe um email válido.';
    }

    if (domain.startsWith(
          '.',
        ) ||
        domain.endsWith(
          '.',
        )) {
      return 'Informe um email válido.';
    }

    if (domain.contains(
      '..',
    )) {
      return 'Informe um email válido.';
    }

    return null;
  }

  // ==========================================================
  // VALIDATE PASSWORD
  // ==========================================================

  String? _validatePassword(
    String password,
  ) {
    if (password.isEmpty) {
      return 'Informe sua nova senha.';
    }

    if (password.length <
        8) {
      return 'A senha deve possuir pelo menos 8 caracteres.';
    }

    if (password.length >
        128) {
      return 'A senha não pode ultrapassar 128 caracteres.';
    }

    return null;
  }

  // ==========================================================
  // CLEAR ERROR
  // ==========================================================

  void clearError() {
    if (!_state.hasError) {
      return;
    }

    _setState(
      _state.clearError(),
    );
  }

  // ==========================================================
  // RESET
  // ==========================================================

  void reset() {
    _setState(
      PasswordRecoveryState.initial,
    );
  }

  // ==========================================================
  // SET ERROR
  // ==========================================================

  void _setError(
    String message,
  ) {
    _setState(
      PasswordRecoveryState(
        step: PasswordRecoveryStep.error,

        errorMessage: message.trim(),
      ),
    );
  }

  // ==========================================================
  // SET STATE
  // ==========================================================

  void _setState(
    PasswordRecoveryState value,
  ) {
    _state = value;

    notifyListeners();
  }
}
