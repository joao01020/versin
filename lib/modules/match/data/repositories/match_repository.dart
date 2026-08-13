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
// - usar looking_for_roles do usuário atual;
// - comparar com roles dos candidatos;
// - priorizar interesse mútuo;
// - converter profiles em MatchUserEntity;
// - alimentar Discovery e Recomendados.
//
// Agora NÃO usamos mais:
//
// UserRole.artist
// UserRole.beatmaker
//
// Tudo usa MusicRole.
//
// ============================================================

class MatchRepository {
  // ============================================================
  // SUPABASE
  // ============================================================

  final SupabaseClient _supabase = Supabase.instance.client;

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

      controller.updateRecommendedUsers(
        const [],
      );

      debugPrint(
        '[MATCH REPOSITORY] ========================================',
      );

      return;
    }

    // ==========================================================
    // STREAM DE USUÁRIOS ONLINE
    // ==========================================================
    //
    // Por enquanto mantemos somente:
    //
    // is_online = true
    //
    // e processamos a compatibilidade localmente.
    //
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

                controller.updateRecommendedUsers(
                  const [],
                );
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
      controller.updateRecommendedUsers(
        const [],
      );

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
        //
        // O candidato precisa exercer pelo menos uma profissão
        // que o usuário atual esteja procurando.
        //
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

      controller.updateRecommendedUsers(
        const [],
      );

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
    // CONVERTER PARA ENTIDADES
    // ==========================================================

    final users = candidates
        .map(
          _mapMapToEntity,
        )
        .toList();

    if (users.isEmpty) {
      controller.updateRecommendedUsers(
        const [],
      );

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
        '${user.primaryRole?.key ?? "sem função"} | '
        'roles: ${MusicRole.toKeys(user.roles)} | '
        'procura: ${MusicRole.toKeys(user.lookingForRoles)}',
      );
    }
  }

  // ============================================================
  // SCORE
  // ============================================================
  //
  // Regras:
  //
  // +10
  // para cada função do candidato que o usuário procura.
  //
  // +20
  // se o candidato também procura alguma função do usuário.
  //
  // +5
  // se a função principal do candidato é diretamente procurada.
  //
  // +1
  // se está online.
  //
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
    final candidateRoles = MusicRole.fromKeys(
      _readList(
        profile['roles'],
      ),
    );

    final candidateLookingForRoles = MusicRole.fromKeys(
      _readList(
        profile['looking_for_roles'],
      ),
    );

    final candidatePrimaryRole = MusicRole.fromKey(
      profile['primary_role']?.toString(),
    );

    var score = 0;

    // ==========================================================
    // FUNÇÕES QUE EU PROCuro
    // ==========================================================

    for (final role in candidateRoles) {
      if (lookingForRoles.contains(
        role,
      )) {
        score += 10;
      }
    }

    // ==========================================================
    // PRINCIPAL DO CANDIDATO
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
  // VERIFICAR INTERSEÇÃO
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
  // MAPEAR SUPABASE → MATCH USER ENTITY
  // ============================================================

  MatchUserEntity _mapMapToEntity(
    Map<
      String,
      dynamic
    >
    map,
  ) {
    // ==========================================================
    // FUNÇÃO PRINCIPAL
    // ==========================================================

    final primaryRole = MusicRole.fromKey(
      map['primary_role']?.toString(),
    );

    // ==========================================================
    // TODAS AS FUNÇÕES
    // ==========================================================

    final roles = MusicRole.fromKeys(
      _readList(
        map['roles'],
      ),
    );

    // ==========================================================
    // QUEM O CANDIDATO PROCURA
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
              ) => item.toString(),
            )
            .where(
              (
                item,
              ) => item.trim().isNotEmpty,
            )
            .toList();

    // ==========================================================
    // ENTITY
    // ==========================================================

    return MatchUserEntity(
      id:
          map['id']?.toString().trim() ??
          '',

      name: _readDisplayName(
        map,
      ),

      primaryRole: primaryRole,

      roles: roles,

      lookingForRoles: lookingForRoles,

      tags: tags,

      bio:
          map['bio']?.toString() ??
          '',

      showcaseMediaUrl:
          map['showcase_url']?.toString() ??
          '',

      showcaseDescription:
          map['showcase_desc']?.toString() ??
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
  // NOME
  // ============================================================

  String _readDisplayName(
    Map<
      String,
      dynamic
    >
    map,
  ) {
    // ==========================================================
    // NOME ARTÍSTICO
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

    final username = map['username']?.toString().trim();

    if (username !=
            null &&
        username.isNotEmpty) {
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
