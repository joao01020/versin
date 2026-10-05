import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:versin/core/models/rhyme_model.dart';
import 'package:versin/core/cache/app_cache_service.dart';
import 'package:versin/core/cache/cache_keys.dart';
import 'package:versin/core/cache/cache_policy.dart';
import 'package:versin/core/cache/request_deduplicator.dart';

class RhymesRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AppCacheService _cache = AppCacheService.instance;
  final RequestDeduplicator _deduplicator = RequestDeduplicator.instance;

  static const String _baseUrl = 'https://versin.onrender.com';

  // =========================================================
  // BUSCAR VOCABULÁRIO
  // =========================================================

  Future<List<Rhyme>> fetchVocabulary({bool forceRefresh = false}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final key = CacheKeys.vocabulary(user.id);
    if (!forceRefresh) {
      final cached = await _cache.read(key, policy: CachePolicy.vocabulary);
      if (cached != null) {
        final result = _decodeVocabulary(cached.value);
        if (cached.isFresh) return result;
        unawaited(_refreshVocabulary(user.id));
        return result;
      }
    }
    return _refreshVocabulary(user.id);
  }

  Future<List<Rhyme>> _refreshVocabulary(String userId) {
    final key = CacheKeys.vocabulary(userId);
    return _deduplicator.run<List<Rhyme>>('remote:$key', () async {
      try {
        final response = await _supabase
            .from('user_vocabulary')
            .select('word')
            .eq('user_id', userId);
        final result = response
            .map(
              (item) => Rhyme(
                word: item['word']?.toString() ?? '',
                isPriority: false,
              ),
            )
            .where((item) => item.word.trim().isNotEmpty)
            .toList();
        await _cache.write(
          key,
          result
              .map(
                (item) => {'word': item.word, 'is_priority': item.isPriority},
              )
              .toList(),
        );
        return result;
      } catch (_) {
        final stale = await _cache.read(
          key,
          policy: CachePolicy.vocabulary,
          allowStale: true,
        );
        return stale == null ? <Rhyme>[] : _decodeVocabulary(stale.value);
      }
    });
  }

  List<Rhyme> _decodeVocabulary(dynamic raw) {
    if (raw is! List) return <Rhyme>[];
    final result = <Rhyme>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final word = item['word']?.toString().trim() ?? '';
      if (word.isEmpty) continue;
      result.add(Rhyme(word: word, isPriority: item['is_priority'] == true));
    }
    return result;
  }

  // =========================================================
  // SALVAR RIMA
  // =========================================================

  Future<void> saveWord(String word) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      return;
    }

    final normalized = word.trim().toLowerCase();

    if (normalized.isEmpty) {
      return;
    }

    await _supabase.from('user_vocabulary').insert({
      'word': normalized,
      'user_id': user.id,
    });

    await _cache.remove(CacheKeys.vocabulary(user.id));
  }

  // =========================================================
  // REMOVER RIMA
  // =========================================================

  Future<void> deleteWord(String word) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      return;
    }

    final normalized = word.trim().toLowerCase();

    if (normalized.isEmpty) {
      return;
    }

    await _supabase
        .from('user_vocabulary')
        .delete()
        .eq('word', normalized)
        .eq('user_id', user.id);

    await _cache.remove(CacheKeys.vocabulary(user.id));
  }

  // =========================================================
  // CHAT / IA
  // =========================================================

  Future<http.Response> postChat({
    required String message,
    required List<String> currentList,
    required String? apiKey,
    required Map<String, dynamic> context,
  }) async {
    final userId = _supabase.auth.currentUser?.id ?? 'user_dev_01';

    final response = await http
        .post(
          Uri.parse('$_baseUrl/chat'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_id': userId,
            'message': message,
            'current_list': currentList,
            'private_api_key': apiKey,
            'context': context,
          }),
        )
        .timeout(const Duration(seconds: 60));

    return response;
  }
}
