import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:versin/core/models/rhyme_model.dart';

class RhymesRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const String _baseUrl = 'https://versin.onrender.com';

  // =========================================================
  // BUSCAR VOCABULÁRIO
  // =========================================================

  Future<
    List<
      Rhyme
    >
  >
  fetchVocabulary() async {
    final user = _supabase.auth.currentUser;

    if (user ==
        null) {
      return [];
    }

    try {
      final response = await _supabase
          .from(
            'user_vocabulary',
          )
          .select(
            'word',
          )
          .eq(
            'user_id',
            user.id,
          );

      return response
          .map(
            (
              item,
            ) => Rhyme(
              word:
                  item['word']?.toString() ??
                  '',
              isPriority: false,
            ),
          )
          .where(
            (
              rhyme,
            ) => rhyme.word.trim().isNotEmpty,
          )
          .toList();
    } catch (
      e
    ) {
      return [];
    }
  }

  // =========================================================
  // SALVAR RIMA
  // =========================================================

  Future<
    void
  >
  saveWord(
    String word,
  ) async {
    final user = _supabase.auth.currentUser;

    if (user ==
        null) {
      return;
    }

    final normalized = word.trim().toLowerCase();

    if (normalized.isEmpty) {
      return;
    }

    await _supabase
        .from(
          'user_vocabulary',
        )
        .insert(
          {
            'word': normalized,
            'user_id': user.id,
          },
        );
  }

  // =========================================================
  // REMOVER RIMA
  // =========================================================

  Future<
    void
  >
  deleteWord(
    String word,
  ) async {
    final user = _supabase.auth.currentUser;

    if (user ==
        null) {
      return;
    }

    final normalized = word.trim().toLowerCase();

    if (normalized.isEmpty) {
      return;
    }

    await _supabase
        .from(
          'user_vocabulary',
        )
        .delete()
        .eq(
          'word',
          normalized,
        )
        .eq(
          'user_id',
          user.id,
        );
  }

  // =========================================================
  // CHAT / IA
  // =========================================================

  Future<
    http.Response
  >
  postChat({
    required String message,
    required List<
      String
    >
    currentList,
    required String? apiKey,
    required Map<
      String,
      dynamic
    >
    context,
  }) async {
    final userId =
        _supabase.auth.currentUser?.id ??
        'user_dev_01';

    final response = await http
        .post(
          Uri.parse(
            '$_baseUrl/chat',
          ),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode(
            {
              'user_id': userId,
              'message': message,
              'current_list': currentList,
              'private_api_key': apiKey,
              'context': context,
            },
          ),
        )
        .timeout(
          const Duration(
            seconds: 60,
          ),
        );

    return response;
  }
}
