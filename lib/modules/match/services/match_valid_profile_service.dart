import 'package:supabase_flutter/supabase_flutter.dart';

/// Confirma no servidor se os IDs de perfis ainda possuem conta Auth.
class MatchValidProfileService {
  MatchValidProfileService._();
  static final MatchValidProfileService instance = MatchValidProfileService._();
  final SupabaseClient _client = Supabase.instance.client;

  Future<Set<String>> validIds(Iterable<String> ids) async {
    final uuid = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
      r'[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    final unique = ids.map((id) => id.trim())
        .where((id) => uuid.hasMatch(id)).toSet().toList();
    final result = <String>{};
    for (var start = 0; start < unique.length; start += 200) {
      final end = start + 200 < unique.length ? start + 200 : unique.length;
      final response = await _client.rpc('match_valid_profile_ids',
          params: {'p_ids': unique.sublist(start, end)});
      if (response is! List) {
        throw StateError('Resposta inválida ao validar perfis.');
      }
      result.addAll(response.map((id) => id.toString()));
    }
    return result;
  }

  Future<bool> isValid(String id) async =>
      (await validIds([id])).contains(id.trim());
}
