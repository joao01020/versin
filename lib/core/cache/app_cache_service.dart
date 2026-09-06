import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cache_policy.dart';

class CacheReadResult {
  final dynamic value;
  final DateTime savedAt;
  final bool isFresh;
  final bool isStale;

  const CacheReadResult({
    required this.value,
    required this.savedAt,
    required this.isFresh,
    required this.isStale,
  });
}

class AppCacheService {
  AppCacheService._();
  static final AppCacheService instance = AppCacheService._();
  static const String _prefix = 'versin_app_cache_v1';

  final Map<String, Map<String, dynamic>> _memory = {};

  String _storageKey(String key) => '$_prefix::$key';

  Future<CacheReadResult?> read(
    String key, {
    required CachePolicy policy,
    bool allowStale = true,
  }) async {
    final normalized = key.trim();
    if (normalized.isEmpty) return null;

    Map<String, dynamic>? payload = _memory[normalized];
    if (payload == null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString(_storageKey(normalized));
        if (raw == null || raw.trim().isEmpty) return null;
        final decoded = jsonDecode(raw);
        if (decoded is! Map) {
          await remove(normalized);
          return null;
        }
        payload = Map<String, dynamic>.from(decoded);
        _memory[normalized] = payload;
      } catch (error) {
        debugPrint('[APP CACHE] read $normalized: $error');
        return null;
      }
    }

    final savedAt = DateTime.tryParse(payload['saved_at']?.toString() ?? '');
    if (savedAt == null) {
      await remove(normalized);
      return null;
    }

    final age = DateTime.now().toUtc().difference(savedAt.toUtc());
    final fresh = age <= policy.freshFor;
    final stale = !fresh && age <= policy.staleFor;
    if (!fresh && (!allowStale || !stale)) {
      await remove(normalized);
      return null;
    }

    return CacheReadResult(
      value: payload['value'],
      savedAt: savedAt,
      isFresh: fresh,
      isStale: stale,
    );
  }

  Future<void> write(String key, dynamic value) async {
    final normalized = key.trim();
    if (normalized.isEmpty) return;
    final payload = <String, dynamic>{
      'version': 1,
      'saved_at': DateTime.now().toUtc().toIso8601String(),
      'value': value,
    };
    _memory[normalized] = payload;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey(normalized), jsonEncode(payload));
    } catch (error) {
      debugPrint('[APP CACHE] write $normalized: $error');
    }
  }

  Future<void> remove(String key) async {
    final normalized = key.trim();
    if (normalized.isEmpty) return;
    _memory.remove(normalized);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey(normalized));
    } catch (error) {
      debugPrint('[APP CACHE] remove $normalized: $error');
    }
  }

  Future<void> clearUser(String userId) async {
    final id = userId.trim();
    if (id.isEmpty) return;
    _memory.removeWhere((key, _) => key.contains(':$id'));
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs
          .getKeys()
          .where((key) => key.startsWith('$_prefix::') && key.contains(':$id'))
          .toList();
      for (final key in keys) {
        await prefs.remove(key);
      }
    } catch (error) {
      debugPrint('[APP CACHE] clearUser: $error');
    }
  }
}
