import 'package:flutter/material.dart';

import 'package:versin/modules/login/controllers/login_controller.dart';
import 'package:versin/modules/login/views/artist_name_page.dart';

class CreateAccountPage
    extends
        StatefulWidget {
  const CreateAccountPage({
    super.key,
  });

  @override
  State<
    CreateAccountPage
  >
  createState() => _CreateAccountPageState();
}

class _CreateAccountPageState
    extends
        State<
          CreateAccountPage
        > {
  final LoginController _controller = LoginController();

  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

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
    _controller.passwordController.addListener(
      _onPasswordChanged,
    );
  }

  @override
  void dispose() {
    _controller.passwordController.removeListener(
      _onPasswordChanged,
    );

    _confirmPasswordController.dispose();
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
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),

              padding: const EdgeInsets.symmetric(
                horizontal: 24,

                vertical: 24,
              ),

              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 460,
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    // =================================================
                    // VOLTAR
                    // =================================================
                    IconButton(
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

                    const SizedBox(
                      height: 20,
                    ),

                    // =================================================
                    // HEADER
                    // =================================================
                    _buildHeader(),

                    const SizedBox(
                      height: 28,
                    ),

                    // =================================================
                    // FORM
                    // =================================================
                    _buildCreateAccountCard(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Container(
          width: 52,

          height: 52,

          decoration: BoxDecoration(
            color: accentNeon.withValues(
              alpha: 0.08,
            ),

            borderRadius: BorderRadius.circular(
              16,
            ),

            border: Border.all(
              color: accentNeon.withValues(
                alpha: 0.20,
              ),
            ),
          ),

          child: const Icon(
            Icons.person_add_alt_1_rounded,

            color: accentNeon,

            size: 24,
          ),
        ),

        const SizedBox(
          height: 18,
        ),

        const Text(
          'Criar conta',

          style: TextStyle(
            color: Colors.white,

            fontSize: 26,

            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(
          height: 6,
        ),

        const Text(
          'Crie sua identidade no Versin usando seu email.',

          style: TextStyle(
            color: Colors.white38,

            fontSize: 12,

            height: 1.5,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CARD
  // ============================================================

  Widget _buildCreateAccountCard() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(
        22,
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
        children: [
          // =====================================================
          // EMAIL
          // =====================================================
          TextField(
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
          ),

          const SizedBox(
            height: 14,
          ),

          // =====================================================
          // SENHA
          // =====================================================
          TextField(
            controller: _controller.passwordController,

            obscureText: _obscurePassword,

            textInputAction: TextInputAction.next,

            autofillHints: const [
              AutofillHints.newPassword,
            ],

            style: const TextStyle(
              color: Colors.white,
            ),

            decoration:
                _inputDecoration(
                  label: 'SENHA',

                  hint: 'Mínimo de 6 caracteres',

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
          ),

          const SizedBox(
            height: 10,
          ),

          _buildPasswordStrength(),

          const SizedBox(
            height: 14,
          ),

          // =====================================================
          // CONFIRMAR SENHA
          // =====================================================
          TextField(
            controller: _confirmPasswordController,

            obscureText: _obscureConfirmPassword,

            textInputAction: TextInputAction.done,

            onSubmitted:
                (
                  _,
                ) {
                  _createAccount();
                },

            style: const TextStyle(
              color: Colors.white,
            ),

            decoration:
                _inputDecoration(
                  label: 'CONFIRMAR SENHA',

                  hint: 'Digite novamente sua senha',

                  icon: Icons.lock_reset_rounded,
                ).copyWith(
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(
                        () {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        },
                      );
                    },

                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,

                      color: Colors.white30,

                      size: 19,
                    ),
                  ),
                ),
          ),

          const SizedBox(
            height: 10,
          ),

          // =====================================================
          // ERRO
          // =====================================================
          _buildError(),

          const SizedBox(
            height: 20,
          ),

          // =====================================================
          // BOTÃO
          // =====================================================
          _buildCreateButton(),

          const SizedBox(
            height: 16,
          ),

          // =====================================================
          // LOGIN
          // =====================================================
          Row(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              const Text(
                'Já possui uma conta?',

                style: TextStyle(
                  color: Colors.white38,

                  fontSize: 11,
                ),
              ),

              TextButton(
                onPressed: () {
                  Navigator.of(
                    context,
                  ).pop();
                },

                child: const Text(
                  'ENTRAR',

                  style: TextStyle(
                    color: accentNeon,

                    fontSize: 11,

                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _onPasswordChanged() {
    if (!mounted) {
      return;
    }

    setState(
      () {},
    );
  }

  double get _passwordStrength {
    final password = _controller.passwordController.text;

    if (password.isEmpty) {
      return 0;
    }

    var score = 0;

    if (password.length >=
        8) {
      score++;
    }

    if (RegExp(
      r'[A-Z]',
    ).hasMatch(
      password,
    )) {
      score++;
    }

    if (RegExp(
      r'[a-z]',
    ).hasMatch(
      password,
    )) {
      score++;
    }

    if (RegExp(
      r'[0-9]',
    ).hasMatch(
      password,
    )) {
      score++;
    }

    if (RegExp(
      r'[^A-Za-z0-9]',
    ).hasMatch(
      password,
    )) {
      score++;
    }

    return score /
        5;
  }

  String get _passwordStrengthLabel {
    final strength = _passwordStrength;

    if (strength ==
        0) {
      return 'Digite uma senha';
    }

    if (strength <=
        0.4) {
      return 'Senha fraca';
    }

    if (strength <=
        0.7) {
      return 'Senha média';
    }

    return 'Senha segura';
  }

  Color get _passwordStrengthColor {
    final strength = _passwordStrength;

    if (strength ==
        0) {
      return Colors.white24;
    }

    if (strength <=
        0.4) {
      return Colors.redAccent;
    }

    if (strength <=
        0.7) {
      return Colors.orangeAccent;
    }

    return Colors.greenAccent;
  }

  Widget _buildPasswordStrength() {
    final strength = _passwordStrength;

    final color = _passwordStrengthColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'SEGURANÇA DA SENHA',
              style: TextStyle(
                color: Colors.white30,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            Text(
              _passwordStrengthLabel,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 7,
        ),

        ClipRRect(
          borderRadius: BorderRadius.circular(
            20,
          ),
          child: LinearProgressIndicator(
            value: strength,
            minHeight: 6,
            backgroundColor: Colors.white.withValues(
              alpha: 0.06,
            ),
            valueColor:
                AlwaysStoppedAnimation<
                  Color
                >(
                  color,
                ),
          ),
        ),

        const SizedBox(
          height: 8,
        ),

        Wrap(
          spacing: 10,
          runSpacing: 5,
          children: [
            _buildPasswordRule(
              '8+ caracteres',
              _controller.passwordController.text.length >=
                  8,
            ),
            _buildPasswordRule(
              'Maiúscula',
              RegExp(
                r'[A-Z]',
              ).hasMatch(
                _controller.passwordController.text,
              ),
            ),
            _buildPasswordRule(
              'Número',
              RegExp(
                r'[0-9]',
              ).hasMatch(
                _controller.passwordController.text,
              ),
            ),
            _buildPasswordRule(
              'Símbolo',
              RegExp(
                r'[^A-Za-z0-9]',
              ).hasMatch(
                _controller.passwordController.text,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPasswordRule(
    String label,
    bool valid,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          valid
              ? Icons.check_circle_rounded
              : Icons.circle_outlined,
          size: 12,
          color: valid
              ? Colors.greenAccent
              : Colors.white24,
        ),
        const SizedBox(
          width: 4,
        ),
        Text(
          label,
          style: TextStyle(
            color: valid
                ? Colors.white60
                : Colors.white24,
            fontSize: 9,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BOTÃO CRIAR
  // ============================================================

  Widget _buildCreateButton() {
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
                    : _createAccount,

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
                            Icons.person_add_alt_1_rounded,

                            color: accentNeon,

                            size: 18,
                          ),

                          SizedBox(
                            width: 10,
                          ),

                          Text(
                            'CRIAR CONTA',

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

  // ============================================================
  // ERRO
  // ============================================================

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

  // ============================================================
  // INPUT
  // ============================================================

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

  // ============================================================
  // CRIAR CONTA
  // ============================================================

  Future<
    void
  >
  _createAccount() async {
    FocusScope.of(
      context,
    ).unfocus();

    final password = _controller.passwordController.text;

    final confirmPassword = _confirmPasswordController.text;

    // ==========================================================
    // CONFIRMAR SENHAS
    // ==========================================================

    if (password !=
        confirmPassword) {
      _controller.errorMessage.value = 'As senhas não são iguais.';

      return;
    }

    // ==========================================================
    // CADASTRO
    // ==========================================================

    final success = await _controller.createAccountWithEmail();

    if (!mounted ||
        !success) {
      return;
    }

    // ==========================================================
    // VERIFICAR SE JÁ EXISTE SESSÃO
    // ==========================================================
    //
    // Se a confirmação de email estiver desativada no Supabase,
    // o cadastro já cria uma sessão e podemos seguir direto para
    // a página de nome artístico.
    //
    // Se a confirmação estiver ativada, o usuário precisa
    // confirmar o email e entrar antes de definir o nome.
    //
    // ==========================================================

    final userId = await _controller.getCurrentUserId();

    if (!mounted) {
      return;
    }

    if (userId !=
            null &&
        userId.isNotEmpty) {
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

    // ==========================================================
    // AGUARDANDO CONFIRMAÇÃO DO EMAIL
    // ==========================================================

    await showDialog<
      void
    >(
      context: context,
      barrierDismissible: false,
      builder:
          (
            dialogContext,
          ) {
            return AlertDialog(
              backgroundColor: const Color(
                0xFF17132D,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  20,
                ),
              ),
              icon: const Icon(
                Icons.mark_email_read_outlined,
                color: accentNeon,
                size: 34,
              ),
              title: const Text(
                'Conta criada',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Text(
                'Enviamos uma confirmação para '
                '${_controller.emailController.text.trim()}.\n\n'
                'Confirme seu email e depois entre no Versin. '
                'Após o primeiro login, você poderá definir seu nome artístico.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  height: 1.5,
                ),
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(
                      dialogContext,
                    ).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentNeon,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text(
                    'VOLTAR AO LOGIN',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
    );

    if (!mounted) {
      return;
    }

    Navigator.of(
      context,
    ).pop();
  }
}
