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
// - pesquisar usuários ONLINE;
// - observar usuários ONLINE via Realtime.
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
//     ↓
// perfil pode aparecer no Match
//
// is_online = false
//     ↓
// perfil não aparece no Match
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

  Stream<
    List<
      Map<
        String,
        dynamic
      >
    >
  >
  watchOnlineProfiles();

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

  Future<
    List<
      Map<
        String,
        dynamic
      >
    >
  >
  searchProfiles({
    required String query,
    String? currentUserId,
    int limit = 20,
  });
}

// ============================================================
// MATCH REMOTE DATASOURCE IMPLEMENTATION
// ============================================================

class MatchRemoteDatasourceImpl
    implements
        MatchRemoteDatasource {
  // ============================================================
  // SUPABASE
  // ============================================================

  final SupabaseClient _supabase;

  // ============================================================
  // TABELA
  // ============================================================

  static const String _profilesTable = 'profiles';

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  MatchRemoteDatasourceImpl({
    SupabaseClient? supabase,
  }) : _supabase =
           supabase ??
           Supabase.instance.client;

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
    is_online
  ''';

  // ============================================================
  // STREAM DE USUÁRIOS ONLINE
  // ============================================================

  @override
  Stream<
    List<
      Map<
        String,
        dynamic
      >
    >
  >
  watchOnlineProfiles() {
    debugPrint(
      '[MATCH REMOTE] '
      'Iniciando stream de usuários online.',
    );

    return _supabase
        .from(
          _profilesTable,
        )
        .stream(
          primaryKey: [
            'id',
          ],
        )
        .eq(
          'is_online',
          true,
        )
        .map(
          (
            rows,
          ) {
            // ==================================================
            // PROTEÇÃO EXTRA
            // ==================================================
            //
            // O Supabase já aplica:
            //
            // is_online = true
            //
            // mas mantemos a validação local para garantir que
            // nenhum registro offline seja propagado caso o
            // estado do realtime mude inesperadamente.
            //
            // ==================================================

            final onlineRows = rows.where(
              (
                row,
              ) {
                return row['is_online'] ==
                    true;
              },
            );

            return onlineRows
                .map(
                  (
                    row,
                  ) {
                    return Map<
                      String,
                      dynamic
                    >.from(
                      row,
                    );
                  },
                )
                .toList(
                  growable: false,
                );
          },
        );
  }

  // ============================================================
  // PESQUISAR PERFIS
  // ============================================================

  @override
  Future<
    List<
      Map<
        String,
        dynamic
      >
    >
  >
  searchProfiles({
    required String query,
    String? currentUserId,
    int limit = 20,
  }) async {
    // ==========================================================
    // NORMALIZAR QUERY
    // ==========================================================

    final normalizedQuery = _normalizeSearchQuery(
      query,
    );

    if (normalizedQuery.isEmpty) {
      return const <
        Map<
          String,
          dynamic
        >
      >[];
    }

    // ==========================================================
    // NORMALIZAR USER ID
    // ==========================================================

    final normalizedCurrentUserId = currentUserId?.trim();

    // ==========================================================
    // NORMALIZAR LIMITE
    // ==========================================================

    final safeLimit = limit.clamp(
      1,
      100,
    );

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

      var request = _supabase
          .from(
            _profilesTable,
          )
          .select(
            _profileColumns,
          )
          .eq(
            'is_online',
            true,
          )
          .or(
            'username.ilike.%$normalizedQuery%,'
            'artist_name.ilike.%$normalizedQuery%,'
            'name.ilike.%$normalizedQuery%',
          );

      // ========================================================
      // REMOVER O PRÓPRIO USUÁRIO
      // ========================================================

      if (normalizedCurrentUserId !=
              null &&
          normalizedCurrentUserId.isNotEmpty) {
        request = request.neq(
          'id',
          normalizedCurrentUserId,
        );
      }

      // ========================================================
      // EXECUTAR
      // ========================================================

      final response = await request.limit(
        safeLimit,
      );

      // ========================================================
      // NORMALIZAR RESPOSTA
      // ========================================================

      final rows =
          List<
            Map<
              String,
              dynamic
            >
          >.from(
            response,
          );

      // ========================================================
      // PROTEÇÃO EXTRA LOCAL
      // ========================================================

      final onlineRows = rows
          .where(
            (
              row,
            ) {
              return row['is_online'] ==
                  true;
            },
          )
          .map(
            (
              row,
            ) {
              return Map<
                String,
                dynamic
              >.from(
                row,
              );
            },
          )
          .toList(
            growable: false,
          );

      debugPrint(
        '[MATCH REMOTE] '
        '${onlineRows.length} perfil(is) online encontrado(s).',
      );

      return onlineRows;
    } on PostgrestException catch (
      error
    ) {
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
    } catch (
      error
    ) {
      debugPrint(
        '[MATCH REMOTE] '
        'Erro inesperado ao pesquisar perfis: '
        '$error',
      );

      rethrow;
    }
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

  String _normalizeSearchQuery(
    String value,
  ) {
    return value.trim().toLowerCase().replaceFirst(
      RegExp(
        r'^@+',
      ),
      '',
    );
  }
}
