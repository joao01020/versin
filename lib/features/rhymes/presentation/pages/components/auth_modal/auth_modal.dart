import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Chamada via package para o modal de opções
import 'package:versin/features/rhymes/presentation/pages/components/auth_modal/auth_options_modal.dart';

class AuthModal extends StatefulWidget {
  const AuthModal({super.key});

  // Função estática para chamar o modal de qualquer lugar
  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Obriga o usuário a escolher uma opção
      builder: (context) => const AuthModal(),
    );
  }

  @override
  State<AuthModal> createState() => _AuthModalState();
}

class _AuthModalState extends State<AuthModal> {
  bool _isLoading = false;

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
            const Icon(Icons.shield_rounded, color: Colors.purpleAccent, size: 48),
            const SizedBox(height: 16),
            const Text(
              "VERSIN GENESIS",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Para registrar suas rimas na rede e garantir sua autoria, crie uma conta ou faça login.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            
            if (_isLoading)
              const CircularProgressIndicator(color: Colors.purpleAccent)
            else ...[
              // Botão de Entrar / Criar Conta
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purpleAccent,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  // Em vez de fechar, apenas chamamos o próximo passo
                  // O AuthOptionsModal agora gerencia a troca
                  AuthOptionsModal.show(context);
                },
                child: const Text(
                  "ENTRAR OU CRIAR CONTA",
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Botão de Permanecer Desconectado
              TextButton(
                style: TextButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Permanecer desconectado",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}