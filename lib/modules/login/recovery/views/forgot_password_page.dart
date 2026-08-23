import 'package:flutter/material.dart';

import '../controllers/password_recovery_controller.dart';

// ============================================================
// FORGOT PASSWORD PAGE
// ============================================================

class ForgotPasswordPage
    extends
        StatefulWidget {
  // ==========================================================
  // REDIRECT
  // ==========================================================
  //
  // IMPORTANTE:
  //
  // Essa URL precisa existir também na configuração de
  // Redirect URLs do Supabase Auth.
  //
  // Depois configuraremos o deep link do Versin para receber
  // esse callback.
  //
  // ==========================================================

  final String redirectTo;

  const ForgotPasswordPage({
    super.key,
    this.redirectTo = 'versin://auth/reset-password',
  });

  @override
  State<
    ForgotPasswordPage
  >
  createState() => _ForgotPasswordPageState();
}

// ============================================================
// STATE
// ============================================================

class _ForgotPasswordPageState
    extends
        State<
          ForgotPasswordPage
        > {
  // ==========================================================
  // CONTROLLER
  // ==========================================================

  late final PasswordRecoveryController _controller;

  final TextEditingController _emailController = TextEditingController();

  final FocusNode _emailFocusNode = FocusNode();

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

    _emailController.dispose();

    _emailFocusNode.dispose();

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
          child: Stack(
            children: [
              // =================================================
              // BACK
              // =================================================
              Positioned(
                top: 8,
                left: 12,
                child: IconButton(
                  tooltip: 'Voltar',
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).pop();
                  },
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white70,
                  ),
                ),
              ),

              // =================================================
              // CONTENT
              // =================================================
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 460,
                    ),
                    child: _buildCard(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // CARD
  // ==========================================================

  Widget _buildCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        24,
      ),
      decoration: BoxDecoration(
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
      ),
      child: _controller.emailSent
          ? _buildSuccess()
          : _buildForm(),
    );
  }

  // ==========================================================
  // FORM
  // ==========================================================

  Widget _buildForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ====================================================
        // ICON
        // ====================================================
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
            Icons.lock_reset_rounded,
            color: accentNeon,
            size: 25,
          ),
        ),

        const SizedBox(
          height: 18,
        ),

        // ====================================================
        // TITLE
        // ====================================================
        const Text(
          'Recuperar senha',
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
          'Informe o email associado à sua conta. '
          'Enviaremos as instruções para criar uma nova senha.',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 12,
            height: 1.5,
          ),
        ),

        const SizedBox(
          height: 24,
        ),

        // ====================================================
        // EMAIL
        // ====================================================
        TextField(
          controller: _emailController,
          focusNode: _emailFocusNode,
          enabled: !_controller.isLoading,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [
            AutofillHints.email,
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
          decoration: _inputDecoration(
            label: 'EMAIL',
            hint: 'voce@email.com',
            icon: Icons.alternate_email_rounded,
          ),
        ),

        // ====================================================
        // ERROR
        // ====================================================
        if (_controller.hasError) ...[
          const SizedBox(
            height: 12,
          ),
          _buildError(),
        ],

        const SizedBox(
          height: 20,
        ),

        // ====================================================
        // SEND
        // ====================================================
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
            child: _controller.isSendingEmail
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
                        Icons.mark_email_read_outlined,
                        color: accentNeon,
                        size: 18,
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Text(
                        'ENVIAR INSTRUÇÕES',
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

        const SizedBox(
          height: 10,
        ),

        // ====================================================
        // BACK TO LOGIN
        // ====================================================
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: _controller.isLoading
                ? null
                : () {
                    Navigator.of(
                      context,
                    ).pop();
                  },
            child: const Text(
              'Voltar para entrar',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 11,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // SUCCESS
  // ==========================================================

  Widget _buildSuccess() {
    return Column(
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
            Icons.mark_email_read_rounded,
            color: accentNeon,
            size: 30,
          ),
        ),

        const SizedBox(
          height: 20,
        ),

        const Text(
          'Verifique seu email',
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
          'Se existir uma conta associada a esse email, '
          'você receberá as instruções para redefinir sua senha.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white54,
            fontSize: 12,
            height: 1.5,
          ),
        ),

        const SizedBox(
          height: 8,
        ),

        const Text(
          'O link de recuperação pode expirar. '
          'Se necessário, solicite um novo.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white30,
            fontSize: 10,
            height: 1.4,
          ),
        ),

        const SizedBox(
          height: 24,
        ),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: () {
              Navigator.of(
                context,
              ).pop();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: accentNeon,
              side: BorderSide(
                color: accentNeon.withValues(
                  alpha: 0.30,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  14,
                ),
              ),
            ),
            child: const Text(
              'VOLTAR PARA ENTRAR',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ),
      ],
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
                  'Não foi possível continuar.',
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
  // INPUT DECORATION
  // ==========================================================

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
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
        icon,
        color: accentNeon.withValues(
          alpha: 0.70,
        ),
        size: 19,
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          14,
        ),
        borderSide: BorderSide(
          color: Colors.redAccent.withValues(
            alpha: 0.45,
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
  // SUBMIT
  // ==========================================================

  Future<
    void
  >
  _submit() async {
    FocusScope.of(
      context,
    ).unfocus();

    await _controller.requestReset(
      email: _emailController.text,
      redirectTo: widget.redirectTo,
    );
  }
}
