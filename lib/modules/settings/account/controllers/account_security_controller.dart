import 'package:flutter/foundation.dart';

import 'package:versin/modules/settings/account/domain/repositories/account_security_repository.dart';

class AccountSecurityController extends ChangeNotifier {
  final AccountSecurityRepository _repository;

  AccountSecurityController({required AccountSecurityRepository repository})
    : _repository = repository;

  bool _changingPassword = false;
  bool _deletingData = false;
  bool _deletingAccount = false;

  String? get email => _repository.currentEmail;

  bool get changingPassword => _changingPassword;
  bool get deletingData => _deletingData;
  bool get deletingAccount => _deletingAccount;

  bool get busy => _changingPassword || _deletingData || _deletingAccount;

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (busy) {
      return;
    }

    _changingPassword = true;
    notifyListeners();

    try {
      await _repository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    } finally {
      _changingPassword = false;
      notifyListeners();
    }
  }

  Future<void> deleteAppData() async {
    if (busy) {
      return;
    }

    _deletingData = true;
    notifyListeners();

    try {
      await _repository.deleteAppData();
    } finally {
      _deletingData = false;
      notifyListeners();
    }
  }

  Future<void> deleteAccount() async {
    if (busy) {
      return;
    }

    _deletingAccount = true;
    notifyListeners();

    try {
      await _repository.deleteAccount();
    } finally {
      _deletingAccount = false;
      notifyListeners();
    }
  }
}
