import 'package:supabase_flutter/supabase_flutter.dart';

class MatchProjectHistoryService {
  MatchProjectHistoryService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Map<String, dynamic> _map(dynamic value) =>
      Map<String, dynamic>.from(value as Map);

  List<Map<String, dynamic>> _rows(dynamic value) =>
      (value as List).map(_map).toList(growable: false);

  Future<List<Map<String, dynamic>>> listHistory() async =>
      _rows(await _client.rpc('match_project_history_list'));

  Future<Map<String, dynamic>> detail(String projectId) async => _map(
    await _client.rpc(
      'match_project_history_detail',
      params: {'p_project_id': projectId},
    ),
  );

  Future<List<Map<String, dynamic>>> events(
    String projectId, {
    Map<String, dynamic>? before,
    int limit = 40,
  }) async => _rows(
    await _client.rpc(
      'match_project_history_events',
      params: {
        'p_project_id': projectId,
        'p_before_at': before?['at'],
        'p_before_kind': before?['kind'],
        'p_before_id': before?['id'],
        'p_limit': limit,
      },
    ),
  );

  Future<Map<String, dynamic>> soloStatus(String projectId) async => _map(
    await _client.rpc(
      'match_project_solo_status',
      params: {'p_project_id': projectId},
    ),
  );

  Future<void> acknowledgeSolo(String projectId, int eventId) async {
    await _client.rpc(
      'match_project_solo_acknowledge',
      params: {'p_project_id': projectId, 'p_event_id': eventId},
    );
  }
}
