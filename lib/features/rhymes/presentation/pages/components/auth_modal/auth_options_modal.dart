import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqflite/sqflite.dart';

// IMPORTAÇÕES DE PERSISTÊNCIA E COMPONENTES
import 'package:versin/core/database/database_helper.dart';
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

  // --- PERSISTÊNCIA LOCAL (A QUE COLOCAMOS NO BANCO) ---
  Future<void> _saveLocalProfile(String userId, String username, String wallet) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('user_profile', {
      'id': userId,
      'name': username,
      'wallet': "wallet@$wallet",
      'synced': 1 
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // --- LÓGICA DE LOGIN SOCIAL COM PERSISTÊNCIA REAL ---
  Future<void> _handleSocialLogin(BuildContext context, String provider) async {
    final supabase = Supabase.instance.client;
    
    try {
      // Inicia o fluxo de login social
      await supabase.auth.signInWithOAuth(
        provider == 'google' ? OAuthProvider.google : OAuthProvider.github,
        redirectTo: 'io.supabase.versin://callback',
      );

      // Após o retorno do OAuth, pegamos o usuário logado
      final user = supabase.auth.currentUser;

      if (user != null) {
        // Buscamos se ele já tem um perfil no banco de dados (Profiles)
        final profile = await supabase
            .from('profiles')
            .select('username, wallet_address')
            .eq('id', user.id)
            .maybeSingle();

        if (profile != null) {
          // Se o perfil existe, salva na persistência local
          await _saveLocalProfile(
            user.id, 
            profile['username'], 
            profile['wallet_address']
          );
        } else {
          // Se NÃO existe, aqui você redirecionaria para uma tela de "Completar Perfil"
          // ou abriria o modal de criação que criamos anteriormente.
          debugPrint("Usuário novo detectado: Necessário definir Username e Wallet.");
        }
      }

      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro na autenticação: $e"), backgroundColor: Colors.redAccent)
        );
      }
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
            const Icon(Icons.security_outlined, color: Colors.purpleAccent, size: 40),
            const SizedBox(height: 16),
            const Text(
              "ACESSO AO VERSIN",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),

            _authButton(
              label: "Entrar com Google",
              icon: Icons.g_mobiledata_rounded,
              color: Colors.white10,
              onPressed: () => _handleSocialLogin(context, 'google'),
            ),
            const SizedBox(height: 12),

            _authButton(
              label: "Entrar com GitHub",
              icon: Icons.code_rounded,
              color: Colors.white10,
              onPressed: () => _handleSocialLogin(context, 'github'),
            ),
            const SizedBox(height: 12),

            _authButton(
              label: "Criar conta com E-mail",
              icon: Icons.email_outlined,
              color: Colors.purpleAccent.withOpacity(0.2),
              onPressed: () {
                Navigator.pop(context); 
                EmailAuthForm.show(context); 
              },
            ),
            const SizedBox(height: 16),
            const Text(
              "Suas rimas e carteira serão sincronizadas localmente.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 10),
            )
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
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: BorderSide(color: Colors.white.withOpacity(0.05)),
      ),
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white, size: 22),
      label: Text(
        label, 
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)
      ),
    );
  }
}