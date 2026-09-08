import 'package:supabase_flutter/supabase_flutter.dart';

class MatchQuickProjectTarget {
  final String userId;
  final String name;
  const MatchQuickProjectTarget(this.userId, this.name);
}

class MatchQuickProjectResolver {
  static Future<MatchQuickProjectTarget?> resolve(String projectId) async {
    final client = Supabase.instance.client;
    final me = client.auth.currentUser?.id;
    if (me == null) return null;
    final project = await client
        .from('projects')
        .select('members,origin,status')
        .eq('id', projectId)
        .maybeSingle();
    if (project == null ||
        project['origin'] != 'match' ||
        project['status'] != 'active')
      return null;
    final members =
        (project['members'] as List?)?.map((e) => e.toString()).toList() ??
        <String>[];
    if (members.length != 2 || !members.contains(me)) return null;
    final other = members.firstWhere((id) => id != me);
    final profile = await client
        .from('profiles')
        .select('artist_name,username')
        .eq('id', other)
        .maybeSingle();
    final artist = profile?['artist_name']?.toString().trim() ?? '';
    final username = profile?['username']?.toString().trim() ?? '';
    return MatchQuickProjectTarget(
      other,
      artist.isNotEmpty
          ? artist
          : username.isNotEmpty
          ? username
          : 'Usuário',
    );
  }
}
