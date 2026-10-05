import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NetworkingProfileNameResolver {
  final SupabaseClient _supabase;

  final Map<String, String> _cache = <String, String>{};

  NetworkingProfileNameResolver({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  String? cachedName(String userId) {
    final normalized = userId.trim();

    if (normalized.isEmpty) {
      return null;
    }

    return _cache[normalized];
  }

  Future<String> resolve({
    required String userId,
    required String fallback,
  }) async {
    final normalizedUserId = userId.trim();

    if (normalizedUserId.isEmpty) {
      return fallback;
    }

    final cached = _cache[normalizedUserId];

    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    try {
      final profile = await _supabase
          .from('profiles')
          .select('id, artist_name, name, username')
          .eq('id', normalizedUserId)
          .maybeSingle();

      if (profile == null) {
        return fallback;
      }

      final artistName = profile['artist_name']?.toString().trim();

      if (artistName != null && artistName.isNotEmpty) {
        _cache[normalizedUserId] = artistName;
        return artistName;
      }

      final name = profile['name']?.toString().trim();

      if (name != null && name.isNotEmpty) {
        _cache[normalizedUserId] = name;
        return name;
      }

      final username = profile['username']?.toString().trim().replaceFirst(
        RegExp(r'^@+'),
        '',
      );

      if (username != null && username.isNotEmpty) {
        final label = '@$username';
        _cache[normalizedUserId] = label;
        return label;
      }
    } catch (error, stackTrace) {
      debugPrint(
        '[NETWORKING NAME RESOLVER] '
        'Erro ao buscar nome público: $error',
      );
      debugPrint('$stackTrace');
    }

    return fallback;
  }

  void clear() {
    _cache.clear();
  }
}
