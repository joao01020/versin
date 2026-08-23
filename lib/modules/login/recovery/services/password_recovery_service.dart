import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================================
// PASSWORD RECOVERY SERVICE
// ============================================================
//
// Responsável exclusivamente pela comunicação com o Supabase
// durante o fluxo de recuperação de senha.
//
// Responsabilidades:
//
// - solicitar email de recuperação;
// - atualizar a senha do usuário autenticado pela sessão
//   de recuperação.
//
// Este service NÃO:
//
// - conhece BuildContext;
// - navega entre páginas;
// - exibe SnackBar;
// - controla estado visual.
//
// ============================================================

class PasswordRecoveryService {
  // ==========================================================
  // SUPABASE
  // ==========================================================

  final SupabaseClient _supabase;

  // ==========================================================
  // CONSTRUCTOR
  // ==========================================================

  PasswordRecoveryService({
    SupabaseClient? supabase,
  }) : _supabase =
           supabase ??
           Supabase.instance.client;

  // ==========================================================
  // REQUEST PASSWORD RESET
  // ==========================================================
  //
  // Solicita ao Supabase o envio do email de recuperação.
  //
  // redirectTo deve ser uma URL permitida nas configurações
  // de autenticação do projeto Supabase.
  //
  // ==========================================================

  Future<
    void
  >
  requestPasswordReset({
    required String email,
    required String redirectTo,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    if (normalizedEmail.isEmpty) {
      throw ArgumentError(
        'Email não pode ficar vazio.',
      );
    }

    if (redirectTo.trim().isEmpty) {
      throw ArgumentError(
        'redirectTo não pode ficar vazio.',
      );
    }

    try {
      debugPrint(
        '[PASSWORD RECOVERY SERVICE] '
        'Solicitando recuperação de senha.',
      );

      await _supabase.auth.resetPasswordForEmail(
        normalizedEmail,
        redirectTo: redirectTo.trim(),
      );

      debugPrint(
        '[PASSWORD RECOVERY SERVICE] '
        'Solicitação de recuperação processada.',
      );
    } on AuthException catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[PASSWORD RECOVERY SERVICE] '
        'AuthException ao solicitar recuperação: '
        '${error.message}',
      );

      debugPrint(
        '[PASSWORD RECOVERY SERVICE] '
        'Stack trace: $stackTrace',
      );

      rethrow;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[PASSWORD RECOVERY SERVICE] '
        'Erro inesperado ao solicitar recuperação: '
        '$error',
      );

      debugPrint(
        '[PASSWORD RECOVERY SERVICE] '
        'Stack trace: $stackTrace',
      );

      rethrow;
    }
  }

  // ==========================================================
  // UPDATE PASSWORD
  // ==========================================================
  //
  // O usuário precisa possuir uma sessão válida de recovery
  // antes de chamar este método.
  //
  // Essa sessão normalmente é criada após o usuário clicar
  // no link recebido por email.
  //
  // ==========================================================

  Future<
    void
  >
  updatePassword({
    required String newPassword,
  }) async {
    if (newPassword.isEmpty) {
      throw ArgumentError(
        'Nova senha não pode ficar vazia.',
      );
    }

    if (newPassword.length <
        8) {
      throw ArgumentError(
        'A senha deve possuir pelo menos 8 caracteres.',
      );
    }

    if (newPassword.length >
        128) {
      throw ArgumentError(
        'A senha não pode ultrapassar 128 caracteres.',
      );
    }

    try {
      debugPrint(
        '[PASSWORD RECOVERY SERVICE] '
        'Atualizando senha.',
      );

      final session = _supabase.auth.currentSession;

      if (session ==
          null) {
        throw const AuthException(
          'Sessão de recuperação inválida ou expirada.',
        );
      }

      await _supabase.auth.updateUser(
        UserAttributes(
          password: newPassword,
        ),
      );

      debugPrint(
        '[PASSWORD RECOVERY SERVICE] '
        'Senha atualizada com sucesso.',
      );
    } on AuthException catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[PASSWORD RECOVERY SERVICE] '
        'AuthException ao atualizar senha: '
        '${error.message}',
      );

      debugPrint(
        '[PASSWORD RECOVERY SERVICE] '
        'Stack trace: $stackTrace',
      );

      rethrow;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[PASSWORD RECOVERY SERVICE] '
        'Erro inesperado ao atualizar senha: '
        '$error',
      );

      debugPrint(
        '[PASSWORD RECOVERY SERVICE] '
        'Stack trace: $stackTrace',
      );

      rethrow;
    }
  }
}
