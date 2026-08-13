import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:versin/modules/match/controllers/match_controllers.dart';
import 'package:versin/modules/match/models/match_user_entity.dart';

import 'package:versin/modules/profile/models/music_role.dart';

// ============================================================
// MATCH REPOSITORY
// ============================================================
//
// Responsabilidades:
//
// - observar usuários online;
// - descobrir candidatos compatíveis;
// - pesquisar usuários;
// - usar looking_for_roles do usuário atual;
// - comparar com roles dos candidatos;
// - priorizar interesse mútuo;
// - converter profiles em MatchUserEntity;
// - carregar username separadamente;
// - alimentar Discovery e Recomendados.
//
// Fluxo:
//
// Supabase
//    ↓
// MatchRepository
//    ↓
// MatchUserEntity
//    ↓
// MatchController / MatchPage
//
// ============================================================

class MatchRepository {
  // ============================================================
  // SUPABASE
  // ============================================================

  final SupabaseClient _supabase = Supabase.instance.client;

  // ============================================================
  // CONFIGURAÇÃO
  // ============================================================

  static const int _searchLimit = 20;

  // ============================================================
  // STREAM
  // ============================================================

  StreamSubscription<
    List<
      Map<
        String,
        dynamic
      >
    >
  >?
  _profilesSubscription;

  // ============================================================
  // PESQUISAR USUÁRIOS
  // ============================================================
  //
  // Pesquisa por:
  //
  // - username
  // - artist_name
  // - name
  //
  // Exemplos:
  //
  // astryvo
  // @astryvo
  // Astryvo
  //
  // O próprio usuário é removido dos resultados.
  //
  // ============================================================

  Future<
    List<
      MatchUserEntity
    >
  >
  searchUsers({
    required String query,
    String? currentUserId,
  }) async {
    // ==========================================================
    // NORMALIZAR QUERY
    // ==========================================================

    final normalizedQuery = _normalizeSearchQuery(
      query,
    );

    if (normalizedQuery.isEmpty) {
      return const [];
    }

    // ==========================================================
    // NORMALIZAR ID ATUAL
    // ==========================================================

    final normalizedCurrentUserId = currentUserId?.trim();

    // ==========================================================
    // LOG
    // ==========================================================

    debugPrint(
      '[MATCH REPOSITORY] ========================================',
    );

    debugPrint(
      '[MATCH REPOSITORY] Pesquisando usuários.',
    );

    debugPrint(
      '[MATCH REPOSITORY] Query: $normalizedQuery',
    );

    // ==========================================================
    // BUSCAR
    // ==========================================================

    try {
      // ========================================================
      // QUERY BASE
      // ========================================================
      //
      // IMPORTANTE:
      //
      // filtros precisam vir antes de:
      //
      // - limit
      // - order
      // - range
      //
      // ========================================================

      final queryBuilder = _supabase
          .from(
            'profiles',
          )
          .select(
            '''
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
                ''',
          )
          .or(
            'username.ilike.%$normalizedQuery%,'
            'artist_name.ilike.%$normalizedQuery%,'
            'name.ilike.%$normalizedQuery%',
          );

      // ========================================================
      // EXECUTAR QUERY
      // ========================================================
      //
      // Criamos dois fluxos para evitar problema de tipagem:
      //
      // com usuário atual:
      //
      // or
      // ↓
      // neq
      // ↓
      // limit
      //
      // sem usuário atual:
      //
      // or
      // ↓
      // limit
      //
      // ========================================================

      final dynamic response;

      if (normalizedCurrentUserId !=
              null &&
          normalizedCurrentUserId.isNotEmpty) {
        response = await queryBuilder
            .neq(
              'id',
              normalizedCurrentUserId,
            )
            .limit(
              _searchLimit,
            );
      } else {
        response = await queryBuilder.limit(
          _searchLimit,
        );
      }

      // ========================================================
      // CONVERTER RESPONSE
      // ========================================================

      final rows =
          List<
            Map<
              String,
              dynamic
            >
          >.from(
            response
                as List,
          );

      // ========================================================
      // CONVERTER PARA ENTITY
      // ========================================================

      final users = rows
          .map(
            _mapMapToEntity,
          )
          .where(
            (
              user,
            ) => user.id.isNotEmpty,
          )
          .toList();

      // ========================================================
      // ORDENAR RESULTADOS
      // ========================================================

      users.sort(
        (
          a,
          b,
        ) {
          final scoreA = _calculateSearchScore(
            user: a,
            query: normalizedQuery,
          );

          final scoreB = _calculateSearchScore(
            user: b,
            query: normalizedQuery,
          );

          final scoreComparison = scoreB.compareTo(
            scoreA,
          );

          if (scoreComparison !=
              0) {
            return scoreComparison;
          }

          return a.name.toLowerCase().compareTo(
            b.name.toLowerCase(),
          );
        },
      );

      // ========================================================
      // LOG
      // ========================================================

      debugPrint(
        '[MATCH REPOSITORY] '
        '${users.length} usuário(s) encontrado(s).',
      );

      for (final user in users) {
        debugPrint(
          '[MATCH REPOSITORY] '
          '${user.name} | ${user.usernameLabel}',
        );
      }

      debugPrint(
        '[MATCH REPOSITORY] ========================================',
      );

      return users;
    } on PostgrestException catch (
      error
    ) {
      // ========================================================
      // ERRO SUPABASE
      // ========================================================

      debugPrint(
        '[MATCH REPOSITORY] ========================================',
      );

      debugPrint(
        '[MATCH REPOSITORY] '
        'Erro Supabase na pesquisa.',
      );

      debugPrint(
        '[MATCH REPOSITORY] '
        'Mensagem: ${error.message}',
      );

      debugPrint(
        '[MATCH REPOSITORY] '
        'Código: ${error.code}',
      );

      debugPrint(
        '[MATCH REPOSITORY] '
        'Detalhes: ${error.details}',
      );

      debugPrint(
        '[MATCH REPOSITORY] ========================================',
      );

      rethrow;
    } catch (
      error
    ) {
      // ========================================================
      // ERRO INESPERADO
      // ========================================================

      debugPrint(
        '[MATCH REPOSITORY] '
        'Erro inesperado na pesquisa: $error',
      );

      rethrow;
    }
  }

  // ============================================================
  // SCORE DA PESQUISA
  // ============================================================
  //
  // Prioridade:
  //
  // username exato
  //        ↓
  // nome exato
  //        ↓
  // username começa com
  //        ↓
  // nome começa com
  //        ↓
  // contém
  //
  // ============================================================

  int _calculateSearchScore({
    required MatchUserEntity user,
    required String query,
  }) {
    final normalizedUsername = user.username.trim().toLowerCase();

    final normalizedName = user.name.trim().toLowerCase();

    var score = 0;

    // ==========================================================
    // USERNAME EXATO
    // ==========================================================

    if (normalizedUsername ==
        query) {
      score += 100;
    }

    // ==========================================================
    // NOME EXATO
    // ==========================================================

    if (normalizedName ==
        query) {
      score += 90;
    }

    // ==========================================================
    // USERNAME COMEÇA COM
    // ==========================================================

    if (normalizedUsername.startsWith(
      query,
    )) {
      score += 50;
    }

    // ==========================================================
    // NOME COMEÇA COM
    // ==========================================================

    if (normalizedName.startsWith(
      query,
    )) {
      score += 40;
    }

    // ==========================================================
    // USERNAME CONTÉM
    // ==========================================================

    if (normalizedUsername.contains(
      query,
    )) {
      score += 20;
    }

    // ==========================================================
    // NOME CONTÉM
    // ==========================================================

    if (normalizedName.contains(
      query,
    )) {
      score += 10;
    }

    // ==========================================================
    // ONLINE
    // ==========================================================

    if (user.isOnline) {
      score += 1;
    }

    return score;
  }

  // ============================================================
  // NORMALIZAR PESQUISA
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

  // ============================================================
  // INICIAR STREAM DE MATCH
  // ============================================================

  void streamCrossRoleMatches(
    MatchController controller,
  ) {
    // ==========================================================
    // CANCELAR STREAM ANTIGO
    // ==========================================================

    _profilesSubscription?.cancel();

    // ==========================================================
    // PERFIL ATUAL
    // ==========================================================

    final currentUserId = controller.currentUserId;

    final currentRoles = controller.currentRoles;

    final lookingForRoles = controller.lookingForRoles;

    // ==========================================================
    // LOG
    // ==========================================================

    debugPrint(
      '[MATCH REPOSITORY] ========================================',
    );

    debugPrint(
      '[MATCH REPOSITORY] Iniciando busca.',
    );

    debugPrint(
      '[MATCH REPOSITORY] User ID: $currentUserId',
    );

    debugPrint(
      '[MATCH REPOSITORY] Minhas funções: '
      '${currentRoles.map((role) => role.key).toList()}',
    );

    debugPrint(
      '[MATCH REPOSITORY] Procuro: '
      '${lookingForRoles.map((role) => role.key).toList()}',
    );

    // ==========================================================
    // NÃO CONFIGUROU QUEM PROCURA
    // ==========================================================

    if (lookingForRoles.isEmpty) {
      debugPrint(
        '[MATCH REPOSITORY] '
        'Nenhuma profissão procurada configurada.',
      );

      controller.clearMatchResults();

      debugPrint(
        '[MATCH REPOSITORY] ========================================',
      );

      return;
    }

    // ==========================================================
    // STREAM DE USUÁRIOS ONLINE
    // ==========================================================

    _profilesSubscription = _supabase
        .from(
          'profiles',
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
        .listen(
          (
            data,
          ) {
            _processProfiles(
              controller: controller,
              data: data,
            );
          },
          onError:
              (
                error,
              ) {
                debugPrint(
                  '[MATCH REPOSITORY] '
                  'Erro no pipeline do Match: $error',
                );

                controller.clearMatchResults();
              },
        );
  }

  // ============================================================
  // PROCESSAR PERFIS
  // ============================================================

  void _processProfiles({
    required MatchController controller,
    required List<
      Map<
        String,
        dynamic
      >
    >
    data,
  }) {
    // ==========================================================
    // PERFIL ATUAL
    // ==========================================================

    final currentUserId = controller.currentUserId;

    final currentRoles = controller.currentRoles;

    final lookingForRoles = controller.lookingForRoles;

    // ==========================================================
    // SEM DADOS
    // ==========================================================

    if (data.isEmpty) {
      controller.clearMatchResults();

      return;
    }

    // ==========================================================
    // FILTRAR CANDIDATOS
    // ==========================================================

    final candidates = data.where(
      (
        profile,
      ) {
        // ======================================================
        // ID
        // ======================================================

        final profileId = profile['id']?.toString().trim();

        if (profileId ==
                null ||
            profileId.isEmpty) {
          return false;
        }

        // ======================================================
        // NÃO MOSTRAR A SI MESMO
        // ======================================================

        if (currentUserId !=
                null &&
            profileId ==
                currentUserId) {
          return false;
        }

        // ======================================================
        // FUNÇÕES DO CANDIDATO
        // ======================================================

        final candidateRoles = MusicRole.fromKeys(
          _readList(
            profile['roles'],
          ),
        );

        // ======================================================
        // PERFIL SEM FUNÇÕES
        // ======================================================

        if (candidateRoles.isEmpty) {
          return false;
        }

        // ======================================================
        // COMPATIBILIDADE
        // ======================================================

        return _hasIntersection(
          first: lookingForRoles,
          second: candidateRoles,
        );
      },
    ).toList();

    // ==========================================================
    // SEM CANDIDATOS
    // ==========================================================

    if (candidates.isEmpty) {
      debugPrint(
        '[MATCH REPOSITORY] '
        'Nenhum candidato compatível.',
      );

      controller.clearMatchResults();

      return;
    }

    // ==========================================================
    // ORDENAR POR SCORE
    // ==========================================================

    candidates.sort(
      (
        a,
        b,
      ) {
        final scoreA = _calculateCompatibilityScore(
          profile: a,
          currentRoles: currentRoles,
          lookingForRoles: lookingForRoles,
        );

        final scoreB = _calculateCompatibilityScore(
          profile: b,
          currentRoles: currentRoles,
          lookingForRoles: lookingForRoles,
        );

        return scoreB.compareTo(
          scoreA,
        );
      },
    );

    // ==========================================================
    // CONVERTER
    // ==========================================================

    final users = candidates
        .map(
          _mapMapToEntity,
        )
        .toList();

    if (users.isEmpty) {
      controller.clearMatchResults();

      return;
    }

    // ==========================================================
    // DISCOVERY
    // ==========================================================

    controller.setDiscoveryUser(
      users.first,
    );

    // ==========================================================
    // RECOMENDADOS
    // ==========================================================

    controller.updateRecommendedUsers(
      users
          .skip(
            1,
          )
          .toList(),
    );

    // ==========================================================
    // LOG
    // ==========================================================

    debugPrint(
      '[MATCH REPOSITORY] '
      '${users.length} candidato(s) compatível(is).',
    );

    for (final user in users) {
      debugPrint(
        '[MATCH REPOSITORY] '
        '${user.name} | '
        '${user.usernameLabel} | '
        '${user.primaryRole?.key ?? "sem função"} | '
        'roles: ${MusicRole.toKeys(user.roles)} | '
        'procura: ${MusicRole.toKeys(user.lookingForRoles)}',
      );
    }

    debugPrint(
      '[MATCH REPOSITORY] ========================================',
    );
  }

  // ============================================================
  // SCORE DE COMPATIBILIDADE
  // ============================================================

  int _calculateCompatibilityScore({
    required Map<
      String,
      dynamic
    >
    profile,
    required Set<
      MusicRole
    >
    currentRoles,
    required Set<
      MusicRole
    >
    lookingForRoles,
  }) {
    // ==========================================================
    // FUNÇÕES DO CANDIDATO
    // ==========================================================

    final candidateRoles = MusicRole.fromKeys(
      _readList(
        profile['roles'],
      ),
    );

    // ==========================================================
    // QUEM ELE PROCURA
    // ==========================================================

    final candidateLookingForRoles = MusicRole.fromKeys(
      _readList(
        profile['looking_for_roles'],
      ),
    );

    // ==========================================================
    // PRINCIPAL
    // ==========================================================

    final candidatePrimaryRole = MusicRole.fromKey(
      profile['primary_role']?.toString(),
    );

    var score = 0;

    // ==========================================================
    // TEM O QUE EU PROCURO
    // ==========================================================

    for (final role in candidateRoles) {
      if (lookingForRoles.contains(
        role,
      )) {
        score += 10;
      }
    }

    // ==========================================================
    // PRINCIPAL É O QUE EU PROCURO
    // ==========================================================

    if (candidatePrimaryRole !=
            null &&
        lookingForRoles.contains(
          candidatePrimaryRole,
        )) {
      score += 5;
    }

    // ==========================================================
    // INTERESSE MÚTUO
    // ==========================================================

    final mutualInterest = _hasIntersection(
      first: currentRoles,
      second: candidateLookingForRoles,
    );

    if (mutualInterest) {
      score += 20;
    }

    // ==========================================================
    // ONLINE
    // ==========================================================

    if (profile['is_online'] ==
        true) {
      score += 1;
    }

    return score;
  }

  // ============================================================
  // INTERSEÇÃO
  // ============================================================

  bool _hasIntersection({
    required Iterable<
      MusicRole
    >
    first,
    required Iterable<
      MusicRole
    >
    second,
  }) {
    final secondSet = second.toSet();

    for (final role in first) {
      if (secondSet.contains(
        role,
      )) {
        return true;
      }
    }

    return false;
  }

  // ============================================================
  // MAPEAR SUPABASE → ENTITY
  // ============================================================

  MatchUserEntity _mapMapToEntity(
    Map<
      String,
      dynamic
    >
    map,
  ) {
    // ==========================================================
    // USERNAME
    // ==========================================================

    final username = _readUsername(
      map,
    );

    // ==========================================================
    // NOME
    // ==========================================================

    final displayName = _readDisplayName(
      map,
    );

    // ==========================================================
    // FUNÇÃO PRINCIPAL
    // ==========================================================

    final primaryRole = MusicRole.fromKey(
      map['primary_role']?.toString(),
    );

    // ==========================================================
    // ROLES
    // ==========================================================

    final roles = MusicRole.fromKeys(
      _readList(
        map['roles'],
      ),
    );

    // ==========================================================
    // LOOKING FOR
    // ==========================================================

    final lookingForRoles = MusicRole.fromKeys(
      _readList(
        map['looking_for_roles'],
      ),
    );

    // ==========================================================
    // TAGS
    // ==========================================================

    final tags =
        _readList(
              map['tags'],
            )
            .map(
              (
                item,
              ) => item.toString().trim(),
            )
            .where(
              (
                item,
              ) => item.isNotEmpty,
            )
            .toList();

    // ==========================================================
    // ENTITY
    // ==========================================================

    return MatchUserEntity(
      id:
          map['id']?.toString().trim() ??
          '',

      username: username,

      name: displayName,

      primaryRole: primaryRole,

      roles: roles,

      lookingForRoles: lookingForRoles,

      tags: tags,

      bio:
          map['bio']?.toString().trim() ??
          '',

      showcaseMediaUrl:
          map['showcase_url']?.toString().trim() ??
          '',

      showcaseDescription:
          map['showcase_desc']?.toString().trim() ??
          '',

      distanceKm: _readDouble(
        map['distance'],
      ),

      isOnline:
          map['is_online'] ==
          true,
    );
  }

  // ============================================================
  // USERNAME
  // ============================================================

  String _readUsername(
    Map<
      String,
      dynamic
    >
    map,
  ) {
    final username = map['username']?.toString().trim();

    if (username ==
            null ||
        username.isEmpty) {
      return '';
    }

    return username.replaceFirst(
      RegExp(
        r'^@+',
      ),
      '',
    );
  }

  // ============================================================
  // NOME PARA EXIBIÇÃO
  // ============================================================

  String _readDisplayName(
    Map<
      String,
      dynamic
    >
    map,
  ) {
    // ==========================================================
    // ARTIST NAME
    // ==========================================================

    final artistName = map['artist_name']?.toString().trim();

    if (artistName !=
            null &&
        artistName.isNotEmpty) {
      return artistName;
    }

    // ==========================================================
    // NAME
    // ==========================================================

    final name = map['name']?.toString().trim();

    if (name !=
            null &&
        name.isNotEmpty) {
      return name;
    }

    // ==========================================================
    // USERNAME
    // ==========================================================

    final username = _readUsername(
      map,
    );

    if (username.isNotEmpty) {
      return username;
    }

    return 'Sem Nome';
  }

  // ============================================================
  // LIST
  // ============================================================

  Iterable<
    dynamic
  >
  _readList(
    dynamic value,
  ) {
    if (value ==
        null) {
      return const [];
    }

    if (value
        is Iterable) {
      return value;
    }

    return const [];
  }

  // ============================================================
  // DOUBLE
  // ============================================================

  double _readDouble(
    dynamic value,
  ) {
    if (value
        is num) {
      return value.toDouble();
    }

    if (value
        is String) {
      return double.tryParse(
            value,
          ) ??
          0.0;
    }

    return 0.0;
  }

  // ============================================================
  // PARAR STREAM
  // ============================================================

  Future<
    void
  >
  stopStreaming() async {
    await _profilesSubscription?.cancel();

    _profilesSubscription = null;
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  Future<
    void
  >
  dispose() async {
    await stopStreaming();
  }
}
