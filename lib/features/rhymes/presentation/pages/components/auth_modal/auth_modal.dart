import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:flutter/foundation.dart'
    show
        kIsWeb;
import 'package:sqflite/sqflite.dart';

// Importação da persistência core do Versin
import 'package:versin/core/database/database_helper.dart';

class AuthModal
    extends
        StatefulWidget {
  const AuthModal({
    super.key,
  });

  static void show(
    BuildContext context,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (
            context,
          ) => const AuthModal(),
    );
  }

  @override
  State<
    AuthModal
  >
  createState() => _AuthModalState();
}

class _AuthModalState
    extends
        State<
          AuthModal
        > {
  bool _isLoading = false;
  bool _isExpanded = false;
  bool _registrationSuccess = false;

  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isWalletAvailable = true;
  Timer? _debounce;

  // --- PERSISTÊNCIA LOCAL (SQLITE) ---
  Future<
    void
  >
  _saveLocalProfile(
    String userId,
    String username,
  ) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.insert(
        'user_profile',
        {
          'id': userId,
          'name': username,
          'wallet': "wallet@$username",
          'synced': 1, // Indica que já está sincronizado com a nuvem Genesis
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (
      e
    ) {
      debugPrint(
        "Erro ao salvar perfil local: $e",
      );
    }
  }

  // --- VERIFICAÇÃO DE DISPONIBILIDADE NO SUPABASE ---
  Future<
    void
  >
  _checkWalletAvailability(
    String value,
  ) async {
    if (value.isEmpty) return;
    if (_debounce?.isActive ??
        false)
      _debounce!.cancel();

    _debounce = Timer(
      const Duration(
        milliseconds: 500,
      ),
      () async {
        try {
          final res = await Supabase.instance.client
              .from(
                'profiles',
              )
              .select(
                'username',
              )
              .eq(
                'username',
                value.trim(),
              )
              .maybeSingle();

          if (mounted) {
            setState(
              () => _isWalletAvailable =
                  res ==
                  null,
            );
          }
        } catch (
          e
        ) {
          debugPrint(
            "Erro na checagem: $e",
          );
        }
      },
    );
  }

  Future<
    void
  >
  _handleSocialLogin(
    OAuthProvider provider,
  ) async {
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        provider,
        redirectTo: kIsWeb
            ? null
            : 'io.supabase.versin://callback',
      );
    } catch (
      e
    ) {
      debugPrint(
        "Erro Social: $e",
      );
    }
  }

  // --- REGISTRO COM PERSISTÊNCIA E SINCRONIA ---
  Future<
    void
  >
  _handleEmailGenesis() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty ||
        !_isWalletAvailable)
      return;

    setState(
      () => _isLoading = true,
    );
    try {
      final String generatedWallet = "0x${DateTime.now().millisecondsSinceEpoch}vrs";

      final AuthResponse res = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        data: {
          'username': username,
          'wallet': generatedWallet,
        },
      );

      if (res.user !=
          null) {
        // Grava na persistência local SQLite imediatamente
        await _saveLocalProfile(
          res.user!.id,
          username,
        );

        setState(
          () {
            _isLoading = false;
            _registrationSuccess = true;
          },
        );

        // Delay para feedback visual de sucesso
        await Future.delayed(
          const Duration(
            seconds: 2,
          ),
        );
        if (mounted)
          Navigator.pop(
            context,
          );
      }
    } catch (
      e
    ) {
      setState(
        () => _isLoading = false,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text(
              "Erro: ${e.toString()}",
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Dialog(
      backgroundColor: const Color(
        0xFF0A0A0A,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          24,
        ),
        side: BorderSide(
          color: Colors.purpleAccent.withValues(
            alpha: 0.3,
          ),
          width: 1,
        ),
      ),
      child: AnimatedSize(
        duration: const Duration(
          milliseconds: 300,
        ),
        child: Container(
          padding: const EdgeInsets.all(
            28.0,
          ),
          width: 420,
          child: _registrationSuccess
              ? _buildSuccessView()
              : _buildMainView(),
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.lock_outline_rounded,
          color: Colors.greenAccent,
          size: 64,
        ),
        const SizedBox(
          height: 24,
        ),
        const Text(
          "ACESSO GARANTIDO",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(
          height: 12,
        ),
        const Text(
          "Sua identidade foi criptografada e salva localmente.\nVerifique seu e-mail para ativar.",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey,
            fontSize: 13,
          ),
        ),
        const SizedBox(
          height: 24,
        ),
        const LinearProgressIndicator(
          color: Colors.greenAccent,
          backgroundColor: Colors.white10,
        ),
      ],
    );
  }

  Widget _buildMainView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.token_outlined,
          color: Colors.purpleAccent,
          size: 54,
        ),
        const SizedBox(
          height: 16,
        ),
        const Text(
          "VERSIN GENESIS",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(
          height: 32,
        ),

        if (!_isExpanded) ...[
          _buildActionButton(
            label: "CRIAR CONTA COM EMAIL",
            icon: Icons.email_rounded,
            color: Colors.purpleAccent,
            textColor: Colors.black,
            onPressed: () => setState(
              () => _isExpanded = true,
            ),
          ),
          const SizedBox(
            height: 24,
          ),
          Row(
            children: [
              Expanded(
                child: Divider(
                  color: Colors.white.withValues(
                    alpha: 0.1,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 16,
                ),
                child: Text(
                  "ENTRAR COM",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                  ),
                ),
              ),
              Expanded(
                child: Divider(
                  color: Colors.white.withValues(
                    alpha: 0.1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 24,
          ),
          Row(
            children: [
              Expanded(
                child: _buildSocialButton(
                  label: "GITHUB",
                  icon: Icons.code_rounded,
                  onPressed: () => _handleSocialLogin(
                    OAuthProvider.github,
                  ),
                ),
              ),
              const SizedBox(
                width: 12,
              ),
              Expanded(
                child: _buildSocialButton(
                  label: "GOOGLE",
                  icon: Icons.g_mobiledata_rounded,
                  onPressed: () => _handleSocialLogin(
                    OAuthProvider.google,
                  ),
                ),
              ),
            ],
          ),
        ],

        if (_isExpanded) ...[
          _buildTextField(
            controller: _emailController,
            label: "E-mail",
            icon: Icons.alternate_email_rounded,
          ),
          const SizedBox(
            height: 16,
          ),
          _buildTextField(
            controller: _usernameController,
            label: "Identidade",
            icon: Icons.badge_outlined,
            prefixText: "wallet@",
            onChanged: _checkWalletAvailability,
            helperText: _usernameController.text.isEmpty
                ? null
                : (_isWalletAvailable
                      ? "Disponível ✅"
                      : "Indisponível ❌"),
            helperColor: _isWalletAvailable
                ? Colors.greenAccent
                : Colors.redAccent,
          ),
          const SizedBox(
            height: 16,
          ),
          _buildTextField(
            controller: _passwordController,
            label: "Senha",
            icon: Icons.lock_person_outlined,
            isPassword: true,
          ),
          const SizedBox(
            height: 24,
          ),

          if (_isLoading)
            const CircularProgressIndicator(
              color: Colors.purpleAccent,
            )
          else
            _buildActionButton(
              label: "FINALIZAR REGISTRO",
              color: Colors.purpleAccent,
              textColor: Colors.black,
              onPressed: _handleEmailGenesis,
            ),

          TextButton(
            onPressed: () => setState(
              () => _isExpanded = false,
            ),
            child: const Text(
              "Voltar",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
        ],
        const SizedBox(
          height: 8,
        ),
        TextButton(
          onPressed: () => Navigator.pop(
            context,
          ),
          child: const Text(
            "Sair",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onPressed,
    IconData? icon,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size(
          double.infinity,
          54,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            14,
          ),
        ),
      ),
      onPressed: onPressed,
      icon:
          icon !=
              null
          ? Icon(
              icon,
              color: textColor,
              size: 20,
            )
          : const SizedBox.shrink(),
      label: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(
          double.infinity,
          50,
        ),
        side: BorderSide(
          color: Colors.white.withValues(
            alpha: 0.1,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            14,
          ),
        ),
      ),
      onPressed: onPressed,
      icon: Icon(
        icon,
        color: Colors.white,
        size: 20,
      ),
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    String? prefixText,
    String? helperText,
    Color? helperColor,
    Function(
      String,
    )?
    onChanged,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      onChanged: onChanged,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefixText,
        prefixIcon: Icon(
          icon,
          color: Colors.grey,
          size: 18,
        ),
        helperText: helperText,
        helperStyle: TextStyle(
          color:
              helperColor ??
              Colors.grey,
          fontSize: 11,
        ),
        filled: true,
        fillColor: Colors.white.withValues(
          alpha: 0.03,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(
            color: Colors.transparent,
          ),
          borderRadius: BorderRadius.circular(
            14,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(
            color: Colors.purpleAccent,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(
            14,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _debounce?.cancel();
    super.dispose();
  }
}
