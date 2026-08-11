import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserService {
  final _supabase = Supabase.instance.client;

  String? get _currentUserId => _supabase.auth.currentUser?.id;

  Future<
    void
  >
  updateWallet(
    String username,
  ) async {
    final userId = _currentUserId;

    if (userId ==
        null) {
      return;
    }

    await _supabase
        .from(
          'profiles',
        )
        .update(
          {
            'username': username,
            'wallet_address': 'wallet@$username',
          },
        )
        .eq(
          'id',
          userId,
        );
  }

  Future<
    void
  >
  updateIAMemory(
    String newMemory,
  ) async {
    final userId = _currentUserId;

    if (userId ==
        null) {
      return;
    }

    await _supabase
        .from(
          'profiles',
        )
        .update(
          {
            'ia_memory': newMemory,
          },
        )
        .eq(
          'id',
          userId,
        );
  }

  Future<
    void
  >
  saveToFavorites({
    required String query,
    required String response,
  }) async {
    final userId = _currentUserId;

    if (userId ==
        null) {
      return;
    }

    try {
      await _supabase
          .from(
            'favorites',
          )
          .insert(
            {
              'user_id': userId,
              'query': query,
              'response': response,
            },
          );

      debugPrint(
        '⭐ Salvo nos favoritos!',
      );
    } catch (
      e
    ) {
      debugPrint(
        'Erro ao favoritar: $e',
      );
    }
  }

  Future<
    void
  >
  updateSettings(
    Map<
      String,
      dynamic
    >
    newSettings,
  ) async {
    final userId = _currentUserId;

    if (userId ==
        null) {
      return;
    }

    await _supabase
        .from(
          'profiles',
        )
        .update(
          {
            'settings': newSettings,
          },
        )
        .eq(
          'id',
          userId,
        );
  }

  Future<
    Map<
      String,
      dynamic
    >?
  >
  getProfileData() async {
    final userId = _currentUserId;

    if (userId ==
        null) {
      return null;
    }

    return await _supabase
        .from(
          'profiles',
        )
        .select()
        .eq(
          'id',
          userId,
        )
        .single();
  }
}
