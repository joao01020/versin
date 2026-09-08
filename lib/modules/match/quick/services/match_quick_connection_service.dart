import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Estado compartilhado da conexão rápida. Não controla projetos nem chamadas.
class MatchQuickConnectionService extends ChangeNotifier {
  MatchQuickConnectionService._();
  static final MatchQuickConnectionService instance =
      MatchQuickConnectionService._();

  final SupabaseClient _client = Supabase.instance.client;
  Map<String, dynamic> _data = const <String, dynamic>{};
  String? _userId;
  String? error;
  bool busy = false;
  Future<void>? _pendingRefresh;
  int _watchers = 0;
  Timer? _poller;

  Map<String, dynamic> get data => _data;
  String get state => _data['state']?.toString() ?? 'inactive';
  bool get isInSession => state == 'in_session';
  bool get isPaused => state == 'paused';
  bool get isAvailable => state == 'available';
  String? get projectId => _data['project_id']?.toString();
  String? get sessionId => _data['session_id']?.toString();
  String? get peerId => _data['peer_id']?.toString();
  int get remainingSeconds =>
      (_data['remaining_seconds'] as num?)?.toInt() ?? 0;
  List<Map<String, dynamic>> get incoming => _rows('incoming');
  List<Map<String, dynamic>> get outgoing => _rows('outgoing');

  List<Map<String, dynamic>> _rows(String key) {
    final value = _data[key];
    if (value is! List) return const [];
    return value.whereType<Map>().map((row) =>
        Map<String, dynamic>.from(row)).toList(growable: false);
  }

  void _checkUser() {
    final id = _client.auth.currentUser?.id;
    if (_userId == id) return;
    _userId = id;
    _data = const <String, dynamic>{};
    error = null;
    notifyListeners();
  }

  void watch() {
    _watchers++;
    _checkUser();
    if (_watchers == 1) {
      unawaited(refresh());
      _poller = Timer.periodic(const Duration(seconds: 5), (_) {
        unawaited(refresh());
      });
    }
  }

  void unwatch() {
    if (_watchers > 0) _watchers--;
    if (_watchers == 0) {
      _poller?.cancel();
      _poller = null;
    }
  }

  Future<void> refresh() {
    _checkUser();
    if (_userId == null) return Future<void>.value();
    return _pendingRefresh ??= _read().whenComplete(() {
      _pendingRefresh = null;
    });
  }

  Future<void> _read() async {
    final id = _userId;
    try {
      final result = await _client.rpc('match_quick_status');
      if (_client.auth.currentUser?.id != id) return;
      _data = Map<String, dynamic>.from(result as Map);
      error = null;
      notifyListeners();
    } catch (e) {
      if (_client.auth.currentUser?.id == id) {
        error = e is PostgrestException ? e.message : 'Não foi possível atualizar a conexão.';
        notifyListeners();
      }
    }
  }

  Future<Map<String, dynamic>> _action(
    String rpc, [Map<String, dynamic>? params]
  ) async {
    _checkUser();
    final id = _userId;
    if (id == null) throw StateError('Usuário não autenticado.');
    if (busy) throw StateError('Aguarde a operação anterior.');
    busy = true;
    error = null;
    notifyListeners();
    try {
      final result = await _client.rpc(rpc, params: params);
      if (_client.auth.currentUser?.id != id) {
        throw StateError('A conta mudou durante a operação.');
      }
      await _pendingRefresh;
      await refresh();
      if (result is Map) return Map<String, dynamic>.from(result);
      return <String, dynamic>{'result': result};
    } catch (e) {
      error = e is PostgrestException ? e.message : e.toString();
      notifyListeners();
      rethrow;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> invite(String projectId, String targetId) async {
    await _action('match_quick_invite', {
      'p_project_id': projectId,
      'p_target_id': targetId,
    });
  }

  Future<Map<String, dynamic>> respond(String invitationId, bool accept) =>
      _action('match_quick_respond', {
        'p_invitation_id': invitationId,
        'p_accept': accept,
      });

  Future<void> cancel(String invitationId) async {
    await _action('match_quick_cancel_invite', {
      'p_invitation_id': invitationId,
    });
  }

  /// Prévia autorizada, sem modificar o projeto.
  Future<Map<String, dynamic>> previewCollaboration(String projectId) async {
    _checkUser();
    if (_userId == null) throw StateError('Usuário não autenticado.');
    final result = await _client.rpc(
      'match_collaboration_preview',
      params: {'p_project_id': projectId},
    );
    return Map<String, dynamic>.from(result as Map);
  }

  /// Uma única transação decide entre fechar a dupla e sair de um grupo.
  Future<Map<String, dynamic>> finishCollaboration(
    String projectId, {
    int? expectedMembers,
    bool? expectedHasWork,
  }) => _action('match_collaboration_finish', {
    'p_project_id': projectId,
    'p_expected_members': expectedMembers,
    'p_expected_has_work': expectedHasWork,
  });

  Future<void> end() async {
    final id = sessionId;
    if (id == null) throw StateError('Nenhuma conexão rápida ativa.');
    await _action('match_quick_end', {'p_session_id': id});
  }

  Future<void> resume() async {
    await _action('match_quick_resume');
  }

  Future<void> clear() async {
    await _action('clear_my_available_now');
  }
}
