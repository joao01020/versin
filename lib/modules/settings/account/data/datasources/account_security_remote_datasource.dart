import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:versin/modules/settings/account/domain/repositories/account_security_repository.dart';

abstract class AccountSecurityRemoteDatasource {
  String? get currentEmail;

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<void> deleteAppData();

  Future<void> deleteAccount();
}

class AccountSecurityRemoteDatasourceImpl
    implements AccountSecurityRemoteDatasource {
  final SupabaseClient _supabase;

  AccountSecurityRemoteDatasourceImpl({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  @override
  String? get currentEmail {
    final email = _supabase.auth.currentUser?.email?.trim();

    if (email == null || email.isEmpty) {
      return null;
    }

    return email;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final userBefore = _supabase.auth.currentUser;
    final email = userBefore?.email?.trim().toLowerCase();

    if (userBefore == null || email == null || email.isEmpty) {
      throw const AccountSecurityException(
        'Não foi possível identificar a conta autenticada.',
        code: 'NO_AUTHENTICATED_USER',
      );
    }

    try {
      final reauth = await _supabase.auth.signInWithPassword(
        email: email,
        password: currentPassword,
      );

      if (reauth.user?.id != userBefore.id) {
        throw const AccountSecurityException(
          'Não foi possível confirmar a identidade da conta.',
          code: 'REAUTH_USER_MISMATCH',
        );
      }

      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (error) {
      final normalized = error.message.toLowerCase();

      if (normalized.contains('invalid login credentials') ||
          normalized.contains('invalid credentials') ||
          normalized.contains('password is incorrect')) {
        throw const AccountSecurityException(
          'A senha atual está incorreta.',
          code: 'INVALID_CURRENT_PASSWORD',
        );
      }

      if (normalized.contains('same password') ||
          normalized.contains('different from the old password')) {
        throw const AccountSecurityException(
          'A nova senha deve ser diferente da senha atual.',
          code: 'PASSWORD_NOT_CHANGED',
        );
      }

      if (normalized.contains('weak password') ||
          normalized.contains('password should be at least')) {
        throw const AccountSecurityException(
          'A nova senha não atende aos requisitos de segurança.',
          code: 'WEAK_PASSWORD',
        );
      }

      throw AccountSecurityException(error.message, code: 'AUTH_ERROR');
    }
  }

  @override
  Future<void> deleteAppData() async {
    await _invokeAccountManagement(action: 'delete_data');
  }

  @override
  Future<void> deleteAccount() async {
    await _invokeAccountManagement(action: 'delete_account');
  }

  Future<void> _invokeAccountManagement({required String action}) async {
    final session = _supabase.auth.currentSession;

    if (session == null) {
      throw const AccountSecurityException(
        'Sua sessão expirou. Entre novamente para continuar.',
        code: 'NO_SESSION',
      );
    }

    try {
      final response = await _supabase.functions.invoke(
        'account-management',
        body: {'action': action},
      );

      final status = response.status;
      final data = response.data;

      if (status >= 200 && status < 300) {
        return;
      }

      String? message;
      String? code;

      if (data is Map) {
        message = data['error']?.toString();
        code = data['code']?.toString();
      }

      throw AccountSecurityException(
        message?.trim().isNotEmpty == true
            ? message!.trim()
            : 'Não foi possível concluir a operação.',
        code: code,
      );
    } on FunctionException catch (error) {
      final details = error.details;

      String? message;
      String? code;

      if (details is Map) {
        message = details['error']?.toString();
        code = details['code']?.toString();
      }

      throw AccountSecurityException(
        message?.trim().isNotEmpty == true
            ? message!.trim()
            : error.reasonPhrase ?? 'Falha ao comunicar com o servidor.',
        code: code,
      );
    }
  }
}
