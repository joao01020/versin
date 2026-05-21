import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:versin/modules/login/domain/repositories/auth_repository.dart';
import 'package:versin/modules/login/data/datasources/auth_remote_datasource.dart';
import 'package:versin/modules/login/data/datasources/auth_local_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource _remoteDatasource;
  final AuthLocalDatasource _localDatasource;

  AuthRepositoryImpl({
    AuthRemoteDatasource? remoteDatasource,
    AuthLocalDatasource? localDatasource,
  })  : _remoteDatasource = remoteDatasource ?? AuthRemoteDatasourceImpl(),
        _localDatasource = localDatasource ?? AuthLocalDatasourceImpl();

  @override
  Future<void> signInWithOAuth(OAuthProvider provider) async {
    await _remoteDatasource.signInWithOAuth(provider);

    // CORREÇÃO: Adicionado o 'await' para resolver a Future e obter o User real
    final user = await _remoteDatasource.getCurrentUser();
    
    if (user != null) {
      // Agora o compilador reconhece que 'user' tem a propriedade '.id'
      final profile = await _remoteDatasource.getRemoteProfile(user.id);

      if (profile != null) {
        await _localDatasource.saveLocalProfile(
          userId: user.id,
          username: profile['username'],
          wallet: profile['wallet_address'],
        );
      }
    }
  }

  @override
  Future<bool> registerLocalChassi({
    required String username,
    required String displayName,
    required String walletAddress,
  }) async {
    final String generatedWallet = "0x${DateTime.now().millisecondsSinceEpoch}vrs";

    // Aqui você já estava usando o await corretamente!
    final user = await _remoteDatasource.signUpCustom(
      username: username,
      generatedWallet: generatedWallet,
      displayName: displayName,
    );

    if (user != null) {
      await _localDatasource.saveLocalProfile(
        userId: user.id,
        username: username,
        wallet: walletAddress,
      );
      return true;
    }
    return false;
  }

  @override
  Future<bool> isUsernameTaken(String username) async {
    try {
      return await _remoteDatasource.isUsernameTaken(username);
    } catch (_) {
      return true; // Fallback seguro mantido do seu código original
    }
  }
}