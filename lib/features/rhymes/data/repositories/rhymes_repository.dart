import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:versin/core/models/rhyme_model.dart';

class RhymesRepository {
  final _supabase = Supabase.instance.client;
  final String _baseUrl = "https://versin.onrender.com";

  Future<List<Rhyme>> fetchVocabulary() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final response = await _supabase
        .from('user_vocabulary')
        .select('word')
        .eq('user_id', user.id);

    return (response as List)
        .map((item) => Rhyme(word: item['word'], isPriority: false))
        .toList();
  }

  Future<void> saveWord(String word) async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      await _supabase.from('user_vocabulary').insert({
        'word': word,
        'user_id': user.id,
      });
    }
  }

  Future<void> deleteWord(String word) async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      await _supabase
          .from('user_vocabulary')
          .delete()
          .eq('word', word)
          .eq('user_id', user.id);
    }
  }

  Future<http.Response> postChat({
    required String message,
    required List<String> currentList,
    required String? apiKey,
    required Map<String, dynamic> context,
  }) async {
    return await http.post(
      Uri.parse('$_baseUrl/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': _supabase.auth.currentUser?.id ?? "user_dev_01",
        'message': message,
        'current_list': currentList,
        'private_api_key': apiKey,
        'context': context,
      }),
    ).timeout(const Duration(seconds: 60));
  }
}