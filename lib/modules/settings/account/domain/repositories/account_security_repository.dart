abstract class AccountSecurityRepository {
  String? get currentEmail;

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<void> deleteAppData();

  Future<void> deleteAccount();
}

class AccountSecurityException implements Exception {
  final String message;
  final String? code;

  const AccountSecurityException(this.message, {this.code});

  @override
  String toString() {
    return message;
  }
}
