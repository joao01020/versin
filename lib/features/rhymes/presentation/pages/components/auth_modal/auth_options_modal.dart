import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:versin/features/rhymes/presentation/pages/components/auth_modal/auth_modal_email/email_auth_form.dart';

class AuthOptionsModal
    extends
        StatelessWidget {
  const AuthOptionsModal({
    super.key,
  });

  static void show(
    BuildContext context,
  ) {
    showDialog<
      void
    >(
      context: context,
      barrierDismissible: true,
      builder:
          (
            _,
          ) => const AuthOptionsModal(),
    );
  }

  Future<
    void
  >
  _handleSocialLogin(
    BuildContext context,
    String provider,
  ) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      final tempUser = 'user_${timestamp.toString().substring(10)}';

      final tempWallet = '0x${timestamp}versin';

      debugPrint(
        'Criando perfil para: $tempUser '
        'com Carteira: $tempWallet '
        'via $provider',
      );

      if (!context.mounted) {
        return;
      }

      Navigator.pop(
        context,
      );
    } catch (
      e
    ) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            'Erro: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Dialog(
      backgroundColor: const Color(
        0xFF121212,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          20,
        ),
        side: const BorderSide(
          color: Colors.purpleAccent,
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(
          24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'ESCOLHA UMA OPÇÃO',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),

            const SizedBox(
              height: 24,
            ),

            _authButton(
              label: 'Entrar com Google',
              icon: Icons.g_mobiledata_rounded,
              color: Colors.white10,
              onPressed: () {
                _handleSocialLogin(
                  context,
                  'google',
                );
              },
            ),

            const SizedBox(
              height: 12,
            ),

            _authButton(
              label: 'Entrar com GitHub',
              icon: Icons.code_rounded,
              color: Colors.white10,
              onPressed: () {
                _handleSocialLogin(
                  context,
                  'github',
                );
              },
            ),

            const SizedBox(
              height: 12,
            ),

            _authButton(
              label: 'Criar conta com E-mail',
              icon: Icons.email_outlined,
              color: Colors.purpleAccent.withValues(
                alpha: 0.2,
              ),
              onPressed: () {
                Navigator.pop(
                  context,
                );
                EmailAuthForm.show(
                  context,
                );
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
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size(
          double.infinity,
          50,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            12,
          ),
        ),
        side: BorderSide(
          color: Colors.white.withValues(
            alpha: 0.1,
          ),
        ),
      ),
      icon: Icon(
        icon,
        color: Colors.white,
      ),
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
        ),
      ),
    );
  }
}
