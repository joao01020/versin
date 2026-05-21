import 'package:supabase_flutter/supabase_flutter.dart'; // <--- ADICIONE ESTE IMPORT

abstract class AuthRepository {
  Future<void> signInWithOAuth(OAuthProvider provider);
  Future<bool> isUsernameTaken(String username);
  Future<bool> registerLocalChassi({
    required String username,
    required String displayName,
    required String walletAddress,
  });
}