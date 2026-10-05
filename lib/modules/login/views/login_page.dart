import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:versin/modules/login/controllers/login_controller.dart';
import 'package:versin/modules/login/recovery/views/forgot_password_page.dart';
import 'package:versin/modules/login/views/create_account_page.dart';
import 'package:versin/modules/login/views/artist_name_page.dart';
import 'package:versin/modules/login/widgets/custom_social_button.dart';
import 'package:versin/modules/login/widgets/login_header_logo.dart';

class LoginPage
    extends
        StatefulWidget {
  const LoginPage({
    super.key,
  });

  @override
  State<
    LoginPage
  >
  createState() => _LoginPageState();
}

class _LoginPageState
    extends
        State<
          LoginPage
        > {
  final LoginController _controller = LoginController();

  bool _obscurePassword = true;

  static const Color deepBg = Color(
    0xFF0D0B1F,
  );

  static const Color primaryPurple = Color(
    0xFF6A1B9A,
  );

  static const Color accentNeon = Color(
    0xFFE040FB,
  );

  @override
  void initState() {
    super.initState();

    _controller.initListeners();
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

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
          child: LayoutBuilder(
            builder:
                (
                  context,
                  constraints,
                ) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: 460,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const LoginHeaderLogo(
                                primaryPurple: primaryPurple,
                                accentNeon: accentNeon,
                              ),

                              if (kDebugMode) ...[
                                const SizedBox(
                                  height: 10,
                                ),
                                TextButton(
                                  onPressed: () {
                                    _controller.bypassToDashboard(
                                      context,
                                    );
                                  },
                                  child: Text(
                                    'DEV MODE: Bypass p/ Dashboard',
                                    style: TextStyle(
                                      color: accentNeon.withValues(
                                        alpha: 0.6,
                                      ),
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],

                              const SizedBox(
                                height: 8,
                              ),

                              _buildAuthCard(),

                              const SizedBox(
                                height: 10,
                              ),

                              _buildDivider(),

                              const SizedBox(
                                height: 8,
                              ),

                              CustomSocialButton(
                                label: 'Entrar com o Google',
                                isGoogle: true,
                                onTap: () async {
                                  await _controller.loginWithGoogle();
                                },
                              ),

                              const SizedBox(
                                height: 8,
                              ),

                              CustomSocialButton(
                                label: 'Conectar via GitHub',
                                isGoogle: false,
                                onTap: () async {
                                  await _controller.loginWithGitHub();
                                },
                              ),

                              const SizedBox(
                                height: 10,
                              ),

                              const Text(
                                'Ao entrar, você concorda com os protocolos do ecossistema Versin.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white12,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
          ),
        ),
      ),
    );
  }

  Widget _buildAuthCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        18,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Entrar no Versin',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 5,
          ),

          const Text(
            'Use seu email para acessar sua identidade, obras e armazenamento.',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 11,
              height: 1.4,
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          _buildEmailField(),

          const SizedBox(
            height: 10,
          ),

          _buildPasswordField(),

          const SizedBox(
            height: 6,
          ),

          _buildForgotPasswordButton(),

          const SizedBox(
            height: 6,
          ),

          _buildError(),

          const SizedBox(
            height: 8,
          ),

          _buildLoginButton(),

          const SizedBox(
            height: 8,
          ),

          _buildCreateAccountButton(),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return TextField(
      controller: _controller.emailController,
      keyboardType: TextInputType.emailAddress,
      autofillHints: const [
        AutofillHints.email,
      ],
      textInputAction: TextInputAction.next,
      style: const TextStyle(
        color: Colors.white,
      ),
      decoration: _inputDecoration(
        label: 'EMAIL',
        hint: 'voce@email.com',
        icon: Icons.alternate_email_rounded,
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _controller.passwordController,
      obscureText: _obscurePassword,
      autofillHints: const [
        AutofillHints.password,
      ],
      textInputAction: TextInputAction.done,
      onSubmitted:
          (
            _,
          ) {
            _login();
          },
      style: const TextStyle(
        color: Colors.white,
      ),
      decoration:
          _inputDecoration(
            label: 'SENHA',
            hint: 'Sua senha',
            icon: Icons.lock_outline_rounded,
          ).copyWith(
            suffixIcon: IconButton(
              onPressed: () {
                setState(
                  () {
                    _obscurePassword = !_obscurePassword;
                  },
                );
              },
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: Colors.white30,
                size: 19,
              ),
            ),
          ),
    );
  }

  // ============================================================
  // ESQUECI MINHA SENHA
  // ============================================================

  Widget _buildForgotPasswordButton() {
    return ValueListenableBuilder<
      bool
    >(
      valueListenable: _controller.isLoading,
      builder:
          (
            context,
            loading,
            _,
          ) {
            return Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: loading
                    ? null
                    : _openForgotPassword,
                style: TextButton.styleFrom(
                  foregroundColor: accentNeon,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: Icon(
                  Icons.lock_reset_rounded,
                  color: loading
                      ? Colors.white24
                      : accentNeon.withValues(
                          alpha: 0.78,
                        ),
                  size: 16,
                ),
                label: Text(
                  'Esqueci minha senha',
                  style: TextStyle(
                    color: loading
                        ? Colors.white24
                        : accentNeon.withValues(
                            alpha: 0.78,
                          ),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            );
          },
    );
  }

  Widget _buildError() {
    return ValueListenableBuilder<
      String?
    >(
      valueListenable: _controller.errorMessage,
      builder:
          (
            context,
            message,
            _,
          ) {
            if (message ==
                    null ||
                message.isEmpty) {
              return const SizedBox.shrink();
            }

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
                      message,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
    );
  }

  Widget _buildLoginButton() {
    return ValueListenableBuilder<
      bool
    >(
      valueListenable: _controller.isLoading,
      builder:
          (
            context,
            loading,
            _,
          ) {
            return SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: loading
                    ? null
                    : _login,
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
                      alpha: loading
                          ? 0.12
                          : 0.55,
                    ),
                  ),
                ),
                child: loading
                    ? const SizedBox(
                        width: 20,
                        height: 8,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: accentNeon,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.login_rounded,
                            color: accentNeon,
                            size: 18,
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Text(
                            'ENTRAR',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
              ),
            );
          },
    );
  }

  Widget _buildCreateAccountButton() {
    return ValueListenableBuilder<
      bool
    >(
      valueListenable: _controller.isLoading,
      builder:
          (
            context,
            loading,
            _,
          ) {
            return SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: loading
                    ? null
                    : _openCreateAccount,
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
                  'CRIAR CONTA',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            );
          },
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: Colors.white.withValues(
              alpha: 0.06,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 14,
          ),
          child: Text(
            'OU',
            style: TextStyle(
              color: Colors.white24,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: Colors.white.withValues(
              alpha: 0.06,
            ),
          ),
        ),
      ],
    );
  }

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
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
    );
  }

  Future<
    void
  >
  _login() async {
    FocusScope.of(
      context,
    ).unfocus();

    final success = await _controller.loginWithEmail();

    if (!mounted ||
        !success) {
      return;
    }

    final hasArtistName = await _controller.hasArtistName();

    if (!mounted) {
      return;
    }

    if (!hasArtistName) {
      Navigator.of(
        context,
      ).pushReplacement(
        MaterialPageRoute(
          builder:
              (
                context,
              ) => const ArtistNamePage(),
        ),
      );

      return;
    }

    Navigator.pushReplacementNamed(
      context,
      '/dashboard',
    );
  }

  // ============================================================
  // ABRIR RECUPERAÇÃO DE SENHA
  // ============================================================

  Future<
    void
  >
  _openForgotPassword() async {
    FocusScope.of(
      context,
    ).unfocus();

    _controller.clearError();

    await Navigator.of(
      context,
    ).push(
      MaterialPageRoute(
        builder:
            (
              context,
            ) => const ForgotPasswordPage(),
      ),
    );

    if (!mounted) {
      return;
    }

    _controller.clearError();
  }

  Future<
    void
  >
  _openCreateAccount() async {
    FocusScope.of(
      context,
    ).unfocus();

    await Navigator.of(
      context,
    ).push(
      MaterialPageRoute(
        builder:
            (
              context,
            ) => const CreateAccountPage(),
      ),
    );

    if (!mounted) {
      return;
    }

    _controller.clearError();
  }
}
