import 'package:flutter/material.dart';

import '../controllers/password_recovery_controller.dart';

// ============================================================
// RESET PASSWORD PAGE
// ============================================================
//
// Esta página deve ser aberta SOMENTE depois que o aplicativo
// receber uma sessão válida de recuperação do Supabase.
//
// Ela não processa o deep link.
//
// A responsabilidade dela é:
//
// - receber nova senha;
// - confirmar senha;
// - solicitar atualização;
// - apresentar sucesso/erro.
//
// ============================================================

class ResetPasswordPage
    extends
        StatefulWidget {
  const ResetPasswordPage({
    super.key,
  });

  @override
  State<
    ResetPasswordPage
  >
  createState() => _ResetPasswordPageState();
}

// ============================================================
// STATE
// ============================================================

class _ResetPasswordPageState
    extends
        State<
          ResetPasswordPage
        > {
  // ==========================================================
  // CONTROLLER
  // ==========================================================

  late final PasswordRecoveryController _controller;

  // ==========================================================
  // TEXT CONTROLLERS
  // ==========================================================

  final TextEditingController _passwordController = TextEditingController();

  final TextEditingController _confirmationController = TextEditingController();

  // ==========================================================
  // FOCUS
  // ==========================================================

  final FocusNode _passwordFocusNode = FocusNode();

  final FocusNode _confirmationFocusNode = FocusNode();

  // ==========================================================
  // PASSWORD VISIBILITY
  // ==========================================================

  bool _obscurePassword = true;

  bool _obscureConfirmation = true;

  // ==========================================================
  // COLORS
  // ==========================================================

  static const Color deepBg = Color(
    0xFF0D0B1F,
  );

  static const Color primaryPurple = Color(
    0xFF6A1B9A,
  );

  static const Color accentNeon = Color(
    0xFFE040FB,
  );

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _controller = PasswordRecoveryController();

    _controller.addListener(
      _onControllerChanged,
    );
  }

  // ==========================================================
  // CONTROLLER CHANGED
  // ==========================================================

  void _onControllerChanged() {
    if (!mounted) {
      return;
    }

    setState(
      () {},
    );
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _controller.removeListener(
      _onControllerChanged,
    );

    _controller.dispose();

    _passwordController.dispose();

    _confirmationController.dispose();

    _passwordFocusNode.dispose();

    _confirmationFocusNode.dispose();

    super.dispose();
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(
                0xFF1A0B2E,
              ),
              deepBg,
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 32,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 460,
                ),
                child: _controller.passwordUpdated
                    ? _buildSuccess()
                    : _buildForm(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // FORM
  // ==========================================================

  Widget _buildForm() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        24,
      ),
      decoration: _cardDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==================================================
          // ICON
          // ==================================================
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: primaryPurple.withValues(
                alpha: 0.18,
              ),
              borderRadius: BorderRadius.circular(
                14,
              ),
              border: Border.all(
                color: accentNeon.withValues(
                  alpha: 0.25,
                ),
              ),
            ),
            child: const Icon(
              Icons.password_rounded,
              color: accentNeon,
              size: 25,
            ),
          ),

          const SizedBox(
            height: 18,
          ),

          // ==================================================
          // TITLE
          // ==================================================
          const Text(
            'Criar nova senha',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 7,
          ),

          const Text(
            'Escolha uma nova senha para proteger sua conta Versin.',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 12,
              height: 1.5,
            ),
          ),

          const SizedBox(
            height: 24,
          ),

          // ==================================================
          // PASSWORD
          // ==================================================
          TextField(
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            enabled: !_controller.isLoading,
            obscureText: _obscurePassword,
            autofillHints: const [
              AutofillHints.newPassword,
            ],
            textInputAction: TextInputAction.next,
            onChanged:
                (
                  _,
                ) {
                  _controller.clearError();
                },
            onSubmitted:
                (
                  _,
                ) {
                  _confirmationFocusNode.requestFocus();
                },
            style: const TextStyle(
              color: Colors.white,
            ),
            decoration: _passwordDecoration(
              label: 'NOVA SENHA',
              hint: 'Mínimo de 8 caracteres',
              obscure: _obscurePassword,
              onVisibilityPressed: () {
                setState(
                  () {
                    _obscurePassword = !_obscurePassword;
                  },
                );
              },
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          // ==================================================
          // CONFIRMATION
          // ==================================================
          TextField(
            controller: _confirmationController,
            focusNode: _confirmationFocusNode,
            enabled: !_controller.isLoading,
            obscureText: _obscureConfirmation,
            autofillHints: const [
              AutofillHints.newPassword,
            ],
            textInputAction: TextInputAction.done,
            onChanged:
                (
                  _,
                ) {
                  _controller.clearError();
                },
            onSubmitted:
                (
                  _,
                ) {
                  _submit();
                },
            style: const TextStyle(
              color: Colors.white,
            ),
            decoration: _passwordDecoration(
              label: 'CONFIRMAR SENHA',
              hint: 'Digite novamente',
              obscure: _obscureConfirmation,
              onVisibilityPressed: () {
                setState(
                  () {
                    _obscureConfirmation = !_obscureConfirmation;
                  },
                );
              },
            ),
          ),

          // ==================================================
          // ERROR
          // ==================================================
          if (_controller.hasError) ...[
            const SizedBox(
              height: 12,
            ),
            _buildError(),
          ],

          const SizedBox(
            height: 20,
          ),

          // ==================================================
          // SUBMIT
          // ==================================================
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _controller.isLoading
                  ? null
                  : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryPurple.withValues(
                  alpha: 0.35,
                ),
                foregroundColor: Colors.white,
                disabledBackgroundColor: primaryPurple.withValues(
                  alpha: 0.10,
                ),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    14,
                  ),
                ),
                side: BorderSide(
                  color: accentNeon.withValues(
                    alpha: _controller.isLoading
                        ? 0.12
                        : 0.55,
                  ),
                ),
              ),
              child: _controller.isUpdatingPassword
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: accentNeon,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_reset_rounded,
                          color: accentNeon,
                          size: 18,
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Text(
                          'ATUALIZAR SENHA',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // SUCCESS
  // ==========================================================

  Widget _buildSuccess() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        24,
      ),
      decoration: _cardDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: accentNeon.withValues(
                alpha: 0.10,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: accentNeon.withValues(
                  alpha: 0.30,
                ),
              ),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: accentNeon,
              size: 32,
            ),
          ),

          const SizedBox(
            height: 20,
          ),

          const Text(
            'Senha atualizada',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          const Text(
            'Sua senha foi alterada com sucesso. '
            'Você já pode entrar novamente no Versin.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
              height: 1.5,
            ),
          ),

          const SizedBox(
            height: 24,
          ),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _finish,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryPurple.withValues(
                  alpha: 0.35,
                ),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    14,
                  ),
                ),
                side: BorderSide(
                  color: accentNeon.withValues(
                    alpha: 0.55,
                  ),
                ),
              ),
              child: const Text(
                'IR PARA LOGIN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ERROR
  // ==========================================================

  Widget _buildError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        11,
      ),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(
          alpha: 0.08,
        ),
        borderRadius: BorderRadius.circular(
          10,
        ),
        border: Border.all(
          color: Colors.redAccent.withValues(
            alpha: 0.18,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.redAccent,
            size: 17,
          ),

          const SizedBox(
            width: 8,
          ),

          Expanded(
            child: Text(
              _controller.errorMessage ??
                  'Não foi possível atualizar sua senha.',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // PASSWORD DECORATION
  // ==========================================================

  InputDecoration _passwordDecoration({
    required String label,
    required String hint,
    required bool obscure,
    required VoidCallback onVisibilityPressed,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(
        color: Colors.white38,
        fontSize: 10,
        letterSpacing: 1,
      ),
      hintStyle: const TextStyle(
        color: Colors.white24,
        fontSize: 12,
      ),
      prefixIcon: Icon(
        Icons.lock_outline_rounded,
        color: accentNeon.withValues(
          alpha: 0.70,
        ),
        size: 19,
      ),
      suffixIcon: IconButton(
        onPressed: onVisibilityPressed,
        icon: Icon(
          obscure
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          color: Colors.white30,
          size: 19,
        ),
      ),
      filled: true,
      fillColor: Colors.black.withValues(
        alpha: 0.20,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          14,
        ),
        borderSide: BorderSide(
          color: Colors.white.withValues(
            alpha: 0.07,
          ),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          14,
        ),
        borderSide: BorderSide(
          color: accentNeon.withValues(
            alpha: 0.65,
          ),
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
    );
  }

  // ==========================================================
  // CARD DECORATION
  // ==========================================================

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white.withValues(
        alpha: 0.035,
      ),
      borderRadius: BorderRadius.circular(
        22,
      ),
      border: Border.all(
        color: Colors.white.withValues(
          alpha: 0.06,
        ),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(
            alpha: 0.30,
          ),
          blurRadius: 28,
          offset: const Offset(
            0,
            12,
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // SUBMIT
  // ==========================================================

  Future<
    void
  >
  _submit() async {
    FocusScope.of(
      context,
    ).unfocus();

    await _controller.changePassword(
      password: _passwordController.text,
      confirmation: _confirmationController.text,
    );
  }

  // ==========================================================
  // FINISH
  // ==========================================================

  void _finish() {
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(
      '/login',
      (
        route,
      ) => false,
    );
  }
}
