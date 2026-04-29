import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Import via package para o formulário de email
import 'package:versin/features/rhymes/presentation/pages/components/auth_modal/auth_modal_email/email_auth_form.dart';

class AuthOptionsModal extends StatelessWidget {
  const AuthOptionsModal({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const AuthOptionsModal(),
    );
  }

  // Lógica para criar perfil automático após login social
  Future<void> _handleSocialLogin(BuildContext context, String provider) async {
    try {
      // Simulação de criação de dados após sucesso:
      final String tempUser =
          "user_${DateTime.now().millisecondsSinceEpoch.toString().substring(10)}";
      final String tempWallet =
          "0x${DateTime.now().millisecondsSinceEpoch}versin";

      print("Criando perfil para: $tempUser com Carteira: $tempWallet");

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF121212),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Colors.purpleAccent, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "ESCOLHA UMA OPÇÃO",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 24),

            // Botão Google
            _authButton(
              label: "Entrar com Google",
              icon: Icons.g_mobiledata_rounded,
              color: Colors.white10,
              onPressed: () => _handleSocialLogin(context, 'google'),
            ),
            const SizedBox(height: 12),

            // Botão GitHub
            _authButton(
              label: "Entrar com GitHub",
              icon: Icons.code_rounded,
              color: Colors.white10,
              onPressed: () => _handleSocialLogin(context, 'github'),
            ),
            const SizedBox(height: 12),

            // Botão Criar Conta Email (CORRIGIDO)
            _authButton(
              label: "Criar conta com E-mail",
              icon: Icons.email_outlined,
              color: Colors.purpleAccent.withOpacity(0.2),
              onPressed: () {
                Navigator.pop(context); // Fecha este modal de opções
                EmailAuthForm.show(context); // Abre o formulário de e-mail
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _authButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white)),
    );
  }
}
