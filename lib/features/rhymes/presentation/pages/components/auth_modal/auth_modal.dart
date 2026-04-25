import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class AuthModal extends StatefulWidget {
  const AuthModal({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AuthModal(),
    );
  }

  @override
  State<AuthModal> createState() => _AuthModalState();
}

class _AuthModalState extends State<AuthModal> {
  bool _isLoading = false;
  bool _isExpanded = false; // Controla a transição para o formulário de email/wallet

  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isWalletAvailable = true;
  Timer? _debounce;

  // Validação em tempo real na tabela public.profiles
  Future<void> _checkWalletAvailability(String value) async {
    if (value.isEmpty) return;
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final res = await Supabase.instance.client
            .from('profiles')
            .select('username')
            .eq('username', value)
            .maybeSingle();
        setState(() => _isWalletAvailable = res == null);
      } catch (e) {
        debugPrint("Erro na checagem: $e");
      }
    });
  }

  // Login Social (GitHub / Google)
  Future<void> _handleSocialLogin(OAuthProvider provider) async {
    try {
      await Supabase.instance.client.auth.signInWithOAuth(provider);
    } catch (e) {
      debugPrint("Erro Social: $e");
    }
  }

  Future<void> _handleEmailGenesis() async {
    if (_usernameController.text.isEmpty || !_isWalletAvailable) return;

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        data: {'username': _usernameController.text.trim()},
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro: ${e.toString()}"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0A0A0A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.purpleAccent.withOpacity(0.3), width: 1),
      ),
      child: SingleChildScrollView(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.fastOutSlowIn,
          padding: const EdgeInsets.all(28.0),
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.token_outlined, color: Colors.purpleAccent, size: 54),
              const SizedBox(height: 16),
              const Text(
                "VERSIN GENESIS",
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2),
              ),
              const SizedBox(height: 8),
              const Text(
                "Sua identidade on-chain começa aqui.",
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 32),

              if (!_isExpanded) ...[
                // BOTÃO PRINCIPAL: EXPANDIR PARA EMAIL/WALLET
                _buildActionButton(
                  label: "CRIAR CONTA COM EMAIL",
                  icon: Icons.email_rounded,
                  color: Colors.purpleAccent,
                  textColor: Colors.black,
                  onPressed: () => setState(() => _isExpanded = true),
                ),
                const SizedBox(height: 16),
                
                // DIVISOR
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text("OU ENTRAR COM", style: TextStyle(color: Colors.grey, fontSize: 10)),
                    ),
                    Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
                  ],
                ),
                const SizedBox(height: 16),

                // LOGINS SOCIAIS
                Row(
                  children: [
                    Expanded(
                      child: _buildSocialButton(
                        label: "GITHUB",
                        icon: Icons.code_rounded,
                        onPressed: () => _handleSocialLogin(OAuthProvider.github),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSocialButton(
                        label: "GOOGLE",
                        icon: Icons.g_mobiledata_rounded,
                        onPressed: () => _handleSocialLogin(OAuthProvider.google),
                      ),
                    ),
                  ],
                ),
              ],

              if (_isExpanded) ...[
                _buildTextField(
                  controller: _emailController,
                  label: "E-mail Profissional",
                  icon: Icons.alternate_email_rounded,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _usernameController,
                  label: "Identidade Única",
                  icon: Icons.badge_outlined,
                  prefixText: "wallet@", // AQUI ESTÁ O QUE VOCÊ PEDIU
                  onChanged: _checkWalletAvailability,
                  helperText: _usernameController.text.isEmpty 
                    ? "Sua assinatura digital" 
                    : (_isWalletAvailable ? "Disponível ✅" : "Indisponível ❌"),
                  helperColor: _isWalletAvailable ? Colors.greenAccent : Colors.redAccent,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _passwordController,
                  label: "Senha de Acesso",
                  icon: Icons.lock_person_outlined,
                  isPassword: true,
                ),
                const SizedBox(height: 24),
                
                if (_isLoading)
                  const CircularProgressIndicator(color: Colors.purpleAccent)
                else
                  _buildActionButton(
                    label: "FINALIZAR REGISTRO",
                    color: Colors.purpleAccent,
                    textColor: Colors.black,
                    onPressed: _handleEmailGenesis,
                  ),
                
                TextButton(
                  onPressed: () => setState(() => _isExpanded = false),
                  child: const Text("Voltar para opções", style: TextStyle(color: Colors.grey, fontSize: 12)),
                ),
              ],

              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Permanecer como convidado", style: TextStyle(color: Colors.grey, fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGETS DE SUPORTE ---

  Widget _buildActionButton({required String label, required Color color, required Color textColor, required VoidCallback onPressed, IconData? icon}) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
      onPressed: onPressed,
      icon: icon != null ? Icon(icon, color: textColor, size: 20) : const SizedBox.shrink(),
      label: Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }

  Widget _buildSocialButton({required String label, required IconData icon, required VoidCallback onPressed}) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        side: BorderSide(color: Colors.white.withOpacity(0.1)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white, size: 20),
      label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, bool isPassword = false, String? prefixText, String? helperText, Color? helperColor, Function(String)? onChanged}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefixText,
        prefixStyle: const TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold, fontSize: 15),
        prefixIcon: Icon(icon, color: Colors.grey, size: 18),
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
        helperText: helperText,
        helperStyle: TextStyle(color: helperColor ?? Colors.grey, fontSize: 11),
        filled: true,
        fillColor: Colors.white.withOpacity(0.03),
        enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.transparent), borderRadius: BorderRadius.circular(14)),
        focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.purpleAccent, width: 1), borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}