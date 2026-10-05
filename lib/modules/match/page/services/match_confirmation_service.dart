import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MatchConfirmationProfile {
  final String id;
  final String name;
  final String username;
  final String? avatarUrl;

  const MatchConfirmationProfile({
    required this.id,
    required this.name,
    required this.username,
    this.avatarUrl,
  });
}

class MatchConfirmation {
  final String projectId;
  final MatchConfirmationProfile self;
  final MatchConfirmationProfile other;

  const MatchConfirmation({
    required this.projectId,
    required this.self,
    required this.other,
  });
}

/// UI-only notification state. Does not create matches or modify projects.
class MatchConfirmationService {
  final SupabaseClient _client;
  MatchConfirmationService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final Set<String> _seen = <String>{};
  String? _userId;
  bool _ready = false;

  String _key(String userId) => 'versin_match_confirmation_v1::$userId';

  Future<void> initialize(String userId) async {
    _ready = false;
    _userId = userId;
    _seen.clear();

    // Existing projects are a baseline, not new match notifications.
    // This prevents old matches from popping up on every page opening.
    final existing = await _client
        .from('projects')
        .select('id')
        .eq('origin', 'match')
        .eq('status', 'active')
        .contains('members', <String>[userId]);

    final prefs = await SharedPreferences.getInstance();
    _seen.addAll(prefs.getStringList(_key(userId)) ?? const <String>[]);
    for (final row in existing) {
      final id = row['id']?.toString().trim();
      if (id != null && id.isNotEmpty) _seen.add(id);
    }
    _ready = true;
  }

  Future<MatchConfirmation?> resolve(String projectId) async {
    final userId = _userId;
    if (!_ready || userId == null || _seen.contains(projectId)) return null;
    final project = await _client
        .from('projects')
        .select('id, members')
        .eq('id', projectId)
        .eq('origin', 'match')
        .eq('status', 'active')
        .maybeSingle();
    if (project == null) return null;

    final members =
        (project['members'] as List?)
            ?.map((value) => value.toString())
            .toList(growable: false) ??
        const <String>[];
    if (!members.contains(userId)) return null;
    final otherId = members.where((id) => id != userId).firstOrNull;
    if (otherId == null) return null;

    final profiles = await _client
        .from('profiles')
        .select('id, username, artist_name, avatar_url')
        .inFilter('id', <String>[userId, otherId]);

    MatchConfirmationProfile profileFor(String id) {
      Map<String, dynamic>? row;
      for (final candidate in profiles) {
        if (candidate['id']?.toString() == id) {
          row = candidate;
          break;
        }
      }
      final username = row?['username']?.toString().trim() ?? '';
      final artistName = row?['artist_name']?.toString().trim() ?? '';
      final name = artistName.isNotEmpty
          ? artistName
          : username.isNotEmpty
          ? username
          : 'Usuário';
      final avatar = row?['avatar_url']?.toString().trim();
      return MatchConfirmationProfile(
        id: id,
        name: name,
        username: username,
        avatarUrl: avatar == null || avatar.isEmpty ? null : avatar,
      );
    }

    return MatchConfirmation(
      projectId: projectId,
      self: profileFor(userId),
      other: profileFor(otherId),
    );
  }

  Future<void> acknowledge(String projectId) async {
    final userId = _userId;
    if (userId == null || !_seen.add(projectId)) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key(userId), _seen.toList(growable: false));
    } catch (error) {
      debugPrint('[MATCH CONFIRMATION] Preferência não salva: $error');
    }
  }

  bool isSeen(String projectId) => _seen.contains(projectId);
}
