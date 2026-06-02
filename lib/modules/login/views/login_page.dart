import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:versin/modules/login/controllers/login_controller.dart';
import 'package:versin/modules/login/widgets/login_header_logo.dart';
import 'package:versin/modules/login/widgets/custom_social_button.dart';
import 'package:versin/modules/login/widgets/cyberpunk_input_field.dart';
import 'package:versin/modules/login/widgets/identity_confirmation_box.dart';

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
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const LoginHeaderLogo(
                    primaryPurple: primaryPurple,
                    accentNeon: accentNeon,
                  ),

                  // MODO DEV: Botão de bypass que só aparece em Debug Mode
                  if (kDebugMode) ...[
                    const SizedBox(
                      height: 10,
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushReplacementNamed(
                        context,
                        '/dashboard',
                      ),
                      child: Text(
                        "DEV MODE: Bypass p/ Dashboard",
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
                    height: 40,
                  ),

                  // BOTÃO GOOGLE
                  CustomSocialButton(
                    label: "Entrar com o Google",
                    isGoogle: true,
                    onTap: () async => await _controller.loginWithGoogle(),
                  ),
                  const SizedBox(
                    height: 12,
                  ),

                  // BOTÃO GITHUB
                  CustomSocialButton(
                    label: "Conectar via GitHub",
                    isGoogle: false,
                    onTap: () async => await _controller.loginWithGitHub(),
                  ),
                  const SizedBox(
                    height: 32,
                  ),

                  // DIVISOR EXPANSÍVEL REATIVO
                  ValueListenableBuilder<
                    bool
                  >(
                    valueListenable: _controller.isLocalFieldsExpanded,
                    builder:
                        (
                          context,
                          expanded,
                          _,
                        ) {
                          return GestureDetector(
                            onTap: _controller.toggleLocalFields,
                            behavior: HitTestBehavior.opaque,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: Colors.white.withValues(
                                      alpha: 0.05,
                                    ),
                                    thickness: 1,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        "OU CRIE IDENTIDADE LOCAL",
                                        style: TextStyle(
                                          color: expanded
                                              ? accentNeon
                                              : accentNeon.withValues(
                                                  alpha: 0.5,
                                                ),
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 4,
                                      ),
                                      Icon(
                                        expanded
                                            ? Icons.keyboard_arrow_up
                                            : Icons.keyboard_arrow_down,
                                        color: accentNeon.withValues(
                                          alpha: 0.5,
                                        ),
                                        size: 12,
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: Colors.white.withValues(
                                      alpha: 0.05,
                                    ),
                                    thickness: 1,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                  ),

                  // PAINEL FORMULÁRIO
                  ValueListenableBuilder<
                    bool
                  >(
                    valueListenable: _controller.isLocalFieldsExpanded,
                    builder:
                        (
                          context,
                          expanded,
                          _,
                        ) {
                          return AnimatedCrossFade(
                            duration: const Duration(
                              milliseconds: 300,
                            ),
                            firstChild: const SizedBox(
                              width: double.infinity,
                              height: 16,
                            ),
                            secondChild: Padding(
                              padding: const EdgeInsets.only(
                                top: 32,
                              ),
                              child: Form(
                                key: _controller.formKey,
                                child: Column(
                                  children: [
                                    CyberpunkInputField(
                                      controller: _controller.nameController,
                                      hint: "Seu nome ou pseudônimo",
                                      label: "NOME",
                                      icon: Icons.person_outline_rounded,
                                      accentNeon: accentNeon,
                                      validator:
                                          (
                                            v,
                                          ) => v!.isEmpty
                                          ? "Insira seu nome"
                                          : null,
                                    ),
                                    const SizedBox(
                                      height: 16,
                                    ),

                                    ValueListenableBuilder<
                                      bool
                                    >(
                                      valueListenable: _controller.isUsernameAvailable,
                                      builder:
                                          (
                                            context,
                                            available,
                                            _,
                                          ) {
                                            return CyberpunkInputField(
                                              controller: _controller.userController,
                                              hint: "ex: astryvo",
                                              label: "USERNAME",
                                              icon: Icons.alternate_email_rounded,
                                              accentNeon: accentNeon,
                                              suffixIcon: available
                                                  ? const Icon(
                                                      Icons.verified,
                                                      color: Color(
                                                        0xFFFFD700,
                                                      ),
                                                      size: 18,
                                                    )
                                                  : null,
                                              validator:
                                                  (
                                                    v,
                                                  ) => v!.isEmpty
                                                  ? "Defina um username único"
                                                  : null,
                                            );
                                          },
                                    ),
                                    const SizedBox(
                                      height: 16,
                                    ),

                                    ValueListenableBuilder<
                                      bool
                                    >(
                                      valueListenable: _controller.isUsernameAvailable,
                                      builder:
                                          (
                                            context,
                                            _,
                                            _,
                                          ) {
                                            return CyberpunkInputField(
                                              controller: _controller.walletController,
                                              hint: "",
                                              label: "ENDEREÇO DA WALLET",
                                              icon: Icons.account_balance_wallet_outlined,
                                              isReadOnly: true,
                                              accentNeon: accentNeon,
                                              customTextColor: accentNeon,
                                              validator:
                                                  (
                                                    v,
                                                  ) => v!.isEmpty
                                                  ? "Aguardando username..."
                                                  : null,
                                            );
                                          },
                                    ),

                                    ValueListenableBuilder<
                                      bool
                                    >(
                                      valueListenable: _controller.isUsernameAvailable,
                                      builder:
                                          (
                                            context,
                                            available,
                                            _,
                                          ) {
                                            if (!available) return const SizedBox.shrink();
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                top: 24,
                                              ),
                                              child:
                                                  ValueListenableBuilder<
                                                    bool
                                                  >(
                                                    valueListenable: _controller.isNameRepresented,
                                                    builder:
                                                        (
                                                          context,
                                                          represented,
                                                          _,
                                                        ) {
                                                          return IdentityConfirmationBox(
                                                            isNameRepresented: represented,
                                                            walletAddress: _controller.walletController.text,
                                                            primaryPurple: primaryPurple,
                                                            accentNeon: accentNeon,
                                                            onChanged:
                                                                (
                                                                  bool? value,
                                                                ) => _controller.setIdentityRepresentation(
                                                                  value ??
                                                                      false,
                                                                ),
                                                          );
                                                        },
                                                  ),
                                            );
                                          },
                                    ),
                                    const SizedBox(
                                      height: 24,
                                    ),

                                    // BOTÃO SUBMIT
                                    ValueListenableBuilder<
                                      bool
                                    >(
                                      valueListenable: _controller.isLoading,
                                      builder:
                                          (
                                            context,
                                            loading,
                                            _,
                                          ) {
                                            return ValueListenableBuilder<
                                              bool
                                            >(
                                              valueListenable: _controller.isNameRepresented,
                                              builder:
                                                  (
                                                    context,
                                                    represented,
                                                    _,
                                                  ) {
                                                    final bool isButtonActive =
                                                        represented &&
                                                        !loading;

                                                    return SizedBox(
                                                      width: double.infinity,
                                                      height: 52,
                                                      child: ElevatedButton(
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: isButtonActive
                                                              ? primaryPurple.withValues(
                                                                  alpha: 0.3,
                                                                )
                                                              : primaryPurple.withValues(
                                                                  alpha: 0.05,
                                                                ),
                                                          foregroundColor: isButtonActive
                                                              ? Colors.white
                                                              : Colors.white30,
                                                          elevation: 0,
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(
                                                              16,
                                                            ),
                                                          ),
                                                          side: BorderSide(
                                                            color: isButtonActive
                                                                ? accentNeon.withValues(
                                                                    alpha: 0.6,
                                                                  )
                                                                : Colors.white.withValues(
                                                                    alpha: 0.05,
                                                                  ),
                                                            width: 1.5,
                                                          ),
                                                        ),
                                                        onPressed: isButtonActive
                                                            ? () async {
                                                                final success = await _controller.registerCustomProfile();
                                                                if (success &&
                                                                    context.mounted) {
                                                                  Navigator.pushReplacementNamed(
                                                                    context,
                                                                    '/dashboard',
                                                                  );
                                                                }
                                                              }
                                                            : null,
                                                        child: loading
                                                            ? const SizedBox(
                                                                width: 20,
                                                                height: 20,
                                                                child: CircularProgressIndicator(
                                                                  color: accentNeon,
                                                                  strokeWidth: 2,
                                                                ),
                                                              )
                                                            : Row(
                                                                mainAxisAlignment: MainAxisAlignment.center,
                                                                children: [
                                                                  Icon(
                                                                    Icons.fingerprint,
                                                                    size: 18,
                                                                    color: isButtonActive
                                                                        ? accentNeon
                                                                        : Colors.white30,
                                                                  ),
                                                                  const SizedBox(
                                                                    width: 12,
                                                                  ),
                                                                  const Text(
                                                                    "INICIALIZAR CHASSI",
                                                                    style: TextStyle(
                                                                      fontWeight: FontWeight.bold,
                                                                      letterSpacing: 1.0,
                                                                      fontSize: 13,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                      ),
                                                    );
                                                  },
                                            );
                                          },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            crossFadeState: expanded
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                          );
                        },
                  ),

                  const SizedBox(
                    height: 24,
                  ),
                  const Text(
                    "Ao inicializar, você concorda com os protocolos criptográficos do ecossistema.",
                    style: TextStyle(
                      color: Colors.white12,
                      fontSize: 9,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
