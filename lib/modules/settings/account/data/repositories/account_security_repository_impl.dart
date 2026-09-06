import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:versin/modules/login/data/datasources/auth_local_datasource.dart';
import 'package:versin/modules/settings/account/data/datasources/account_security_remote_datasource.dart';
import 'package:versin/modules/settings/account/domain/repositories/account_security_repository.dart';

class AccountSecurityRepositoryImpl implements AccountSecurityRepository {
  final AccountSecurityRemoteDatasource _remoteDatasource;
  final AuthLocalDatasource _localDatasource;

  AccountSecurityRepositoryImpl({
    AccountSecurityRemoteDatasource? remoteDatasource,
    AuthLocalDatasource? localDatasource,
  }) : _remoteDatasource =
           remoteDatasource ?? AccountSecurityRemoteDatasourceImpl(),
       _localDatasource = localDatasource ?? AuthLocalDatasourceImpl();

  @override
  String? get currentEmail => _remoteDatasource.currentEmail;

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return _remoteDatasource.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  @override
  Future<void> deleteAppData() async {
    await _remoteDatasource.deleteAppData();

    await _localDatasource.clearLocalProfile();
  }

  @override
  Future<void> deleteAccount() async {
    await _remoteDatasource.deleteAccount();

    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {
      // A Edge Function pode já ter invalidado/removido o usuário.
    }

    await _localDatasource.clearLocalProfile();
  }
}
