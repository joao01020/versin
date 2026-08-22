import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================================
// MATCH REMOTE DATASOURCE
// ============================================================
//
// Camada responsável EXCLUSIVAMENTE pela comunicação remota
// do módulo Match.
//
// Responsabilidades:
//
// - consultar profiles no Supabase;
// - pesquisar usuários realmente ONLINE;
// - observar usuários realmente ONLINE via Realtime.
//
// Esta camada NÃO:
//
// - calcula compatibilidade;
// - calcula score;
// - cria MatchUserEntity;
// - conhece MatchController;
// - atualiza Discovery;
// - atualiza recomendações;
// - possui regra de negócio.
//
// Regra de visibilidade:
//
// is_online = true
// +
// last_seen_at recente
//     ↓
// perfil pode aparecer no Match
//
// Qualquer outro caso
//     ↓
// perfil não aparece como ONLINE AGORA
//
// Fluxo:
//
// Supabase
//    ↓
// MatchRemoteDatasource
//    ↓
// MatchRepository
//    ↓
// MatchController
//    ↓
// MatchPage
//
// ============================================================

abstract class MatchRemoteDatasource {
  // ==========================================================
  // USUÁRIOS ONLINE
  // ==========================================================
  //
  // Retorna o stream bruto da tabela:
  //
  // public.profiles
  //
  // filtrando:
  //
  // is_online = true
  //
  // ==========================================================

  Stream<List<Map<String, dynamic>>> watchOnlineProfiles();

  // ==========================================================
  // PESQUISAR PERFIS
  // ==========================================================
  //
  // Pesquisa somente perfis ONLINE por:
  //
  // - username;
  // - artist_name;
  // - name.
  //
  // Também pode remover o próprio usuário da busca.
  //
  // ==========================================================

  Future<List<Map<String, dynamic>>> searchProfiles({
    required String query,
    String? currentUserId,
    int limit = 20,
  });
}

// ============================================================
// MATCH REMOTE DATASOURCE IMPLEMENTATION
// ============================================================

class MatchRemoteDatasourceImpl implements MatchRemoteDatasource {
  // ============================================================
  // SUPABASE
  // ============================================================

  final SupabaseClient _supabase;

  // ============================================================
  // TABELA
  // ============================================================

  static const String _profilesTable = 'profiles';

  static const Duration _onlinePresenceWindow = Duration(seconds: 90);

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  MatchRemoteDatasourceImpl({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  // ============================================================
  // COLUNAS DE PROFILE UTILIZADAS PELO MATCH
  // ============================================================

  static const String _profileColumns = '''
    id,
    username,
    artist_name,
    name,
    primary_role,
    roles,
    looking_for_roles,
    tags,
    bio,
    showcase_url,
    showcase_desc,
    is_online,
    last_seen_at
  ''';

  // ============================================================
  // STREAM DE USUÁRIOS ONLINE
  // ============================================================

  @override
  Stream<List<Map<String, dynamic>>> watchOnlineProfiles() {
    debugPrint(
      '[MATCH REMOTE] '
      'Iniciando stream de usuários com presença ativa.',
    );

    return _supabase
        .from(_profilesTable)
        .stream(primaryKey: ['id'])
        .eq('is_online', true)
        .map((rows) {
          final now = DateTime.now().toUtc();

          final onlineRows = rows
              .where((row) {
                return _isRowReallyOnline(row, now: now);
              })
              .map((row) {
                return Map<String, dynamic>.from(row);
              })
              .toList(growable: false);

          debugPrint(
            '[MATCH REMOTE] '
            '${onlineRows.length} perfil(is) realmente online no stream.',
          );

          return onlineRows;
        });
  }

  // ============================================================
  // PESQUISAR PERFIS
  // ============================================================

  @override
  Future<List<Map<String, dynamic>>> searchProfiles({
    required String query,
    String? currentUserId,
    int limit = 20,
  }) async {
    // ==========================================================
    // NORMALIZAR QUERY
    // ==========================================================

    final normalizedQuery = _normalizeSearchQuery(query);

    if (normalizedQuery.isEmpty) {
      return const <Map<String, dynamic>>[];
    }

    // ==========================================================
    // NORMALIZAR USER ID
    // ==========================================================

    final normalizedCurrentUserId = currentUserId?.trim();

    // ==========================================================
    // NORMALIZAR LIMITE
    // ==========================================================

    final safeLimit = limit.clamp(1, 100);

    // ==========================================================
    // LOG
    // ==========================================================

    debugPrint(
      '[MATCH REMOTE] '
      'Pesquisando perfis online: '
      '$normalizedQuery',
    );

    try {
      // ========================================================
      // QUERY BASE
      // ========================================================
      //
      // IMPORTANTE:
      //
      // O filtro ONLINE fica aqui.
      //
      // Um perfil OFFLINE não é retornado pelo Supabase.
      //
      // ========================================================

      final cutoff = DateTime.now()
          .toUtc()
          .subtract(_onlinePresenceWindow)
          .toIso8601String();

      var request = _supabase
          .from(_profilesTable)
          .select(_profileColumns)
          .eq('is_online', true)
          .gte('last_seen_at', cutoff)
          .or(
            'username.ilike.%$normalizedQuery%,'
            'artist_name.ilike.%$normalizedQuery%,'
            'name.ilike.%$normalizedQuery%',
          );

      // ========================================================
      // REMOVER O PRÓPRIO USUÁRIO
      // ========================================================

      if (normalizedCurrentUserId != null &&
          normalizedCurrentUserId.isNotEmpty) {
        request = request.neq('id', normalizedCurrentUserId);
      }

      // ========================================================
      // EXECUTAR
      // ========================================================

      final response = await request.limit(safeLimit);

      // ========================================================
      // NORMALIZAR RESPOSTA
      // ========================================================

      final rows = List<Map<String, dynamic>>.from(response);

      // ========================================================
      // PROTEÇÃO EXTRA LOCAL
      // ========================================================

      final now = DateTime.now().toUtc();

      final onlineRows = rows
          .where((row) {
            return _isRowReallyOnline(row, now: now);
          })
          .map((row) {
            return Map<String, dynamic>.from(row);
          })
          .toList(growable: false);

      debugPrint(
        '[MATCH REMOTE] '
        '${onlineRows.length} perfil(is) online encontrado(s).',
      );

      return onlineRows;
    } on PostgrestException catch (error) {
      debugPrint(
        '[MATCH REMOTE] '
        'Erro Supabase ao pesquisar perfis.',
      );

      debugPrint(
        '[MATCH REMOTE] '
        'Mensagem: ${error.message}',
      );

      debugPrint(
        '[MATCH REMOTE] '
        'Código: ${error.code}',
      );

      debugPrint(
        '[MATCH REMOTE] '
        'Detalhes: ${error.details}',
      );

      rethrow;
    } catch (error) {
      debugPrint(
        '[MATCH REMOTE] '
        'Erro inesperado ao pesquisar perfis: '
        '$error',
      );

      rethrow;
    }
  }

  // ============================================================
  // PRESENÇA REAL
  // ============================================================
  //
  // Um perfil só é considerado realmente online quando:
  //
  // - is_online == true;
  // - last_seen_at existe;
  // - last_seen_at ocorreu nos últimos 90 segundos.
  //
  // ============================================================

  bool _isRowReallyOnline(Map<String, dynamic> row, {required DateTime now}) {
    if (row['is_online'] != true) {
      return false;
    }

    final lastSeenAt = _readNullableDateTime(row['last_seen_at']);

    if (lastSeenAt == null) {
      return false;
    }

    final difference = now.toUtc().difference(lastSeenAt.toUtc());

    if (difference.isNegative) {
      return true;
    }

    return difference <= _onlinePresenceWindow;
  }

  DateTime? _readNullableDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value.toUtc();
    }

    final normalized = value.toString().trim();

    if (normalized.isEmpty) {
      return null;
    }

    return DateTime.tryParse(normalized)?.toUtc();
  }

  // ============================================================
  // NORMALIZAR PESQUISA
  // ============================================================
  //
  // Permite:
  //
  // astryvo
  // @astryvo
  // @@@astryvo
  //
  // Todos resultam em:
  //
  // astryvo
  //
  // ============================================================

  String _normalizeSearchQuery(String value) {
    return value.trim().toLowerCase().replaceFirst(RegExp(r'^@+'), '');
  }
}
