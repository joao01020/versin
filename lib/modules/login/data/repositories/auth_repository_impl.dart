import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:versin/modules/login/domain/repositories/auth_repository.dart';
import 'package:versin/modules/login/data/datasources/auth_local_datasource.dart';
import 'package:versin/modules/login/data/datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl
    implements
        AuthRepository {
  final AuthRemoteDatasource _remoteDatasource;
  final AuthLocalDatasource _localDatasource;

  AuthRepositoryImpl({
    AuthRemoteDatasource? remoteDatasource,
    AuthLocalDatasource? localDatasource,
  }) : _remoteDatasource =
           remoteDatasource ??
           AuthRemoteDatasourceImpl(),
       _localDatasource =
           localDatasource ??
           AuthLocalDatasourceImpl();

  // ============================================================
  // LOGIN POR EMAIL
  // ============================================================

  @override
  Future<
    bool
  >
  signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _remoteDatasource.signInWithEmail(
      email: email,
      password: password,
    );

    final user = response.user;

    if (user ==
        null) {
      return false;
    }

    await _syncRemoteProfile(
      user.id,
    );

    return true;
  }

  // ============================================================
  // CADASTRO POR EMAIL
  // ============================================================

  @override
  Future<
    bool
  >
  signUpWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _remoteDatasource.signUpWithEmail(
      email: email,
      password: password,
    );

    return response.user !=
        null;
  }

  // ============================================================
  // OAUTH
  // ============================================================

  @override
  Future<
    void
  >
  signInWithOAuth(
    OAuthProvider provider,
  ) async {
    await _remoteDatasource.signInWithOAuth(
      provider,
    );
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  @override
  Future<
    void
  >
  signOut() async {
    await _remoteDatasource.signOut();

    await _localDatasource.clearLocalProfile();
  }

  // ============================================================
  // USUÁRIO ATUAL
  // ============================================================

  @override
  Future<
    String?
  >
  getCurrentUserId() async {
    final user = await _remoteDatasource.getCurrentUser();

    return user?.id;
  }

  // ============================================================
  // NOME ARTÍSTICO
  // ============================================================

  @override
  Future<
    String?
  >
  getArtistName() async {
    final user = await _remoteDatasource.getCurrentUser();

    if (user ==
        null) {
      return null;
    }

    // ==========================================================
    // TENTAR SQLITE PRIMEIRO
    // ==========================================================

    final localArtistName = await _localDatasource.getArtistName(
      user.id,
    );

    if (localArtistName !=
            null &&
        localArtistName.isNotEmpty) {
      return localArtistName;
    }

    // ==========================================================
    // BUSCAR SUPABASE
    // ==========================================================

    final remoteArtistName = await _remoteDatasource.getArtistName(
      user.id,
    );

    if (remoteArtistName ==
            null ||
        remoteArtistName.isEmpty) {
      return null;
    }

    // ==========================================================
    // SINCRONIZAR LOCAL
    // ==========================================================

    await _localDatasource.saveArtistName(
      userId: user.id,
      artistName: remoteArtistName,
    );

    return remoteArtistName;
  }

  // ============================================================
  // SALVAR NOME ARTÍSTICO
  // ============================================================

  @override
  Future<
    bool
  >
  saveArtistName(
    String artistName,
  ) async {
    final normalizedArtistName = artistName.trim().replaceAll(
      RegExp(
        r'\s+',
      ),
      ' ',
    );

    if (normalizedArtistName.isEmpty) {
      return false;
    }

    final user = await _remoteDatasource.getCurrentUser();

    if (user ==
        null) {
      return false;
    }

    // ==========================================================
    // SUPABASE
    // ==========================================================

    await _remoteDatasource.saveArtistName(
      userId: user.id,
      artistName: normalizedArtistName,
    );

    // ==========================================================
    // SQLITE
    // ==========================================================

    await _localDatasource.saveArtistName(
      userId: user.id,
      artistName: normalizedArtistName,
    );

    return true;
  }

  // ============================================================
  // VERIFICAR SE POSSUI NOME ARTÍSTICO
  // ============================================================

  @override
  Future<
    bool
  >
  hasArtistName() async {
    final artistName = await getArtistName();

    return artistName !=
            null &&
        artistName.trim().isNotEmpty;
  }

  // ============================================================
  // USERNAME
  // ============================================================

  @override
  Future<
    bool
  >
  isUsernameTaken(
    String username,
  ) async {
    try {
      return await _remoteDatasource.isUsernameTaken(
        username,
      );
    } catch (
      _
    ) {
      return true;
    }
  }

  // ============================================================
  // PERFIL LOCAL
  // ============================================================

  @override
  Future<
    bool
  >
  registerLocalChassi({
    required String username,
    required String displayName,
    required String walletAddress,
  }) async {
    final user = await _remoteDatasource.getCurrentUser();

    if (user ==
        null) {
      return false;
    }

    final artistName = displayName.trim().isEmpty
        ? null
        : displayName.trim();

    await _localDatasource.saveLocalProfile(
      userId: user.id,
      username: username.trim(),
      wallet: walletAddress.trim(),
      artistName: artistName,
    );

    return true;
  }

  // ============================================================
  // SINCRONIZAR PERFIL REMOTO → SQLITE
  // ============================================================

  Future<
    void
  >
  _syncRemoteProfile(
    String userId,
  ) async {
    final profile = await _remoteDatasource.getRemoteProfile(
      userId,
    );

    if (profile ==
        null) {
      return;
    }

    final username = profile['username']?.toString().trim();

    final wallet = profile['wallet_address']?.toString().trim();

    final artistName = profile['artist_name']?.toString().trim();

    // ==========================================================
    // PERFIL COMPLETO
    // ==========================================================

    if (username !=
            null &&
        username.isNotEmpty) {
      await _localDatasource.saveLocalProfile(
        userId: userId,
        username: username,
        wallet:
            wallet ??
            '',
        artistName:
            artistName?.isEmpty ==
                true
            ? null
            : artistName,
      );

      return;
    }

    // ==========================================================
    // USUÁRIO AINDA NÃO TEM USERNAME
    // ==========================================================
    //
    // Mesmo sem username, ainda podemos sincronizar o
    // artist_name caso ele já exista.
    //
    // ==========================================================

    if (artistName !=
            null &&
        artistName.isNotEmpty) {
      await _localDatasource.saveArtistName(
        userId: userId,
        artistName: artistName,
      );
    }
  }
}
