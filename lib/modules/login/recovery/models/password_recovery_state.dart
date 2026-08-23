// ============================================================
// PASSWORD RECOVERY STEP
// ============================================================
//
// Representa cada etapa possível do fluxo de recuperação.
//
// idle
//   Nenhuma operação em andamento.
//
// sendingEmail
//   Solicitando o envio do email de recuperação.
//
// emailSent
//   Solicitação processada.
//
// updatingPassword
//   Atualizando a senha.
//
// passwordUpdated
//   Senha atualizada com sucesso.
//
// error
//   Ocorreu algum erro.
//
// ============================================================

enum PasswordRecoveryStep {
  idle,
  sendingEmail,
  emailSent,
  updatingPassword,
  passwordUpdated,
  error,
}

// ============================================================
// PASSWORD RECOVERY STATE
// ============================================================

class PasswordRecoveryState {
  // ==========================================================
  // STATE
  // ==========================================================

  final PasswordRecoveryStep step;

  final String? errorMessage;

  // ==========================================================
  // CONSTRUCTOR
  // ==========================================================

  const PasswordRecoveryState({
    this.step = PasswordRecoveryStep.idle,
    this.errorMessage,
  });

  // ==========================================================
  // INITIAL
  // ==========================================================

  static const PasswordRecoveryState initial = PasswordRecoveryState();

  // ==========================================================
  // LOADING
  // ==========================================================

  bool get isLoading {
    return step ==
            PasswordRecoveryStep.sendingEmail ||
        step ==
            PasswordRecoveryStep.updatingPassword;
  }

  // ==========================================================
  // SENDING EMAIL
  // ==========================================================

  bool get isSendingEmail {
    return step ==
        PasswordRecoveryStep.sendingEmail;
  }

  // ==========================================================
  // EMAIL SENT
  // ==========================================================

  bool get emailSent {
    return step ==
        PasswordRecoveryStep.emailSent;
  }

  // ==========================================================
  // UPDATING PASSWORD
  // ==========================================================

  bool get isUpdatingPassword {
    return step ==
        PasswordRecoveryStep.updatingPassword;
  }

  // ==========================================================
  // PASSWORD UPDATED
  // ==========================================================

  bool get passwordUpdated {
    return step ==
        PasswordRecoveryStep.passwordUpdated;
  }

  // ==========================================================
  // ERROR
  // ==========================================================

  bool get hasError {
    return errorMessage !=
            null &&
        errorMessage!.trim().isNotEmpty;
  }

  bool get isError {
    return step ==
        PasswordRecoveryStep.error;
  }

  // ==========================================================
  // COPY WITH
  // ==========================================================

  PasswordRecoveryState copyWith({
    PasswordRecoveryStep? step,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PasswordRecoveryState(
      step:
          step ??
          this.step,
      errorMessage: clearError
          ? null
          : errorMessage ??
                this.errorMessage,
    );
  }

  // ==========================================================
  // HELPERS
  // ==========================================================

  PasswordRecoveryState toIdle() {
    return const PasswordRecoveryState(
      step: PasswordRecoveryStep.idle,
    );
  }

  PasswordRecoveryState clearError() {
    return PasswordRecoveryState(
      step:
          step ==
              PasswordRecoveryStep.error
          ? PasswordRecoveryStep.idle
          : step,
      errorMessage: null,
    );
  }

  // ==========================================================
  // TO STRING
  // ==========================================================

  @override
  String toString() {
    return 'PasswordRecoveryState('
        'step: $step, '
        'isLoading: $isLoading, '
        'hasError: $hasError'
        ')';
  }
}
