import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRepository {
  // ============================================================
  // EMAIL / SENHA
  // ============================================================

  Future<
    bool
  >
  signInWithEmail({
    required String email,
    required String password,
  });

  Future<
    bool
  >
  signUpWithEmail({
    required String email,
    required String password,
  });

  // ============================================================
  // OAUTH
  // ============================================================

  Future<
    void
  >
  signInWithOAuth(
    OAuthProvider provider,
  );

  // ============================================================
  // SESSÃO
  // ============================================================

  Future<
    void
  >
  signOut();

  Future<
    String?
  >
  getCurrentUserId();

  // ============================================================
  // NOME ARTÍSTICO
  // ============================================================

  Future<
    String?
  >
  getArtistName();

  Future<
    bool
  >
  saveArtistName(
    String artistName,
  );

  Future<
    bool
  >
  hasArtistName();

  // ============================================================
  // USERNAME
  // ============================================================

  Future<
    bool
  >
  isUsernameTaken(
    String username,
  );

  // ============================================================
  // PERFIL LOCAL
  // ============================================================

  Future<
    bool
  >
  registerLocalChassi({
    required String username,
    required String displayName,
    required String walletAddress,
  });
}
