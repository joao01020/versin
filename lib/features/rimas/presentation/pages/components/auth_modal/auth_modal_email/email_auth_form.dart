import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmailAuthForm extends StatefulWidget {
  const EmailAuthForm({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const EmailAuthForm(),
    );
  }

  @override
  State<EmailAuthForm> createState() => _EmailAuthFormState();
}

class _EmailAuthFormState extends State<EmailAuthForm> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleMagicLink() async {
    final email = _emailController.text.trim();
    
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, insira um e-mail válido.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Tenta enviar o Magic Link
      // DICA: No Linux, às vezes o redirectTo causa problemas se não estiver configurado no painel.
      // Se o erro 401 persistir, tente comentar a linha 'emailRedirectTo' para testar.
      await Supabase.instance.client.auth.signInWithOtp(
        email: email,
        emailRedirectTo: 'io.supabase.versin://login-callback/', 
      );

      if (mounted) {
        Navigator.pop(context); // Fecha o formulário
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Link de acesso enviado! Verifique seu e-mail."),
            backgroundColor: Colors.greenAccent,
          ),
        );
      }
    } on AuthException catch (e) {
      // Captura erros específicos do Supabase (como o 401)
      debugPrint("ERRO DE AUTENTICAÇÃO: ${e.message} (Código: ${e.statusCode})");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro na API (401): Verifique se as chaves no main.dart estão corretas."),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      debugPrint("ERRO GENÉRICO: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro inesperado: $e"), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
              "ENTRAR COM E-MAIL",
              style: TextStyle(
                color: Colors.white, 
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "seu@email.com",
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.email_outlined, color: Colors.purpleAccent),
              ),
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const CircularProgressIndicator(color: Colors.purpleAccent)
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purpleAccent,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _handleMagicLink,
                    child: const Text(
                      "ENVIAR LINK DE ACESSO", 
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}