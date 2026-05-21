import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRemoteDatasource {
  Future<void> signInWithOAuth(OAuthProvider provider);
  Future<User?> getCurrentUser();
  Future<Map<String, dynamic>?> getRemoteProfile(String userId);
  Future<User?> signUpCustom({required String username, required String generatedWallet, required String displayName});
  Future<bool> isUsernameTaken(String username);
}

class AuthRemoteDatasourceImpl implements AuthRemoteDatasource {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Future<void> signInWithOAuth(OAuthProvider provider) async {
    await _supabase.auth.signInWithOAuth(
      provider,
      redirectTo: kIsWeb ? null : 'io.supabase.versin://callback',
    );
  }

  @override
  Future<User?> getCurrentUser() async {
    return _supabase.auth.currentUser;
  }

  @override
  Future<Map<String, dynamic>?> getRemoteProfile(String userId) async {
    return await _supabase
        .from('profiles')
        .select('username, wallet_address')
        .eq('id', userId)
        .maybeSingle();
  }

  @override
  Future<User?> signUpCustom({
    required String username,
    required String generatedWallet,
    required String displayName,
  }) async {
    final AuthResponse res = await _supabase.auth.signUp(
      email: "$username@versin.local",
      password: "vrs_${DateTime.now().millisecondsSinceEpoch}",
      data: {
        'username': username,
        'wallet': generatedWallet,
        'display_name': displayName,
      },
    );
    return res.user;
  }

  @override
  Future<bool> isUsernameTaken(String username) async {
    final res = await _supabase
        .from('profiles')
        .select('username')
        .eq('username', username.trim())
        .maybeSingle();
    return res != null;
  }
}