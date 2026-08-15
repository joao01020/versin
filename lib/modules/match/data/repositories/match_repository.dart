import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'dart:math' as math;

import 'package:versin/modules/match/controllers/match_controllers.dart';
import 'package:versin/modules/match/models/match_discovery_mode.dart';
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
// - descobrir candidatos compatíveis por proximidade;
// - suportar descoberta global;
// - calcular distância entre perfis;
// - pesquisar somente usuários online;
// - usar looking_for_roles do usuário atual;
// - comparar com roles dos candidatos;
// - priorizar interesse mútuo;
// - converter profiles em MatchUserEntity;
// - carregar username separadamente;
// - alimentar Discovery e Recomendados.
//
// Regra de visibilidade:
//
// is_online = true
//     ↓
// perfil pode aparecer na busca, Discovery e Recomendados.
//
// is_online = false
//     ↓
// perfil deve ser ignorado pelo Match.
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
  // Apenas perfis com is_online = true são retornados.
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
          .where(
            (
              row,
            ) {
              return row['is_online'] ==
                  true;
            },
          )
          .map(
            _mapMapToEntity,
          )
          .where(
            (
              user,
            ) {
              return user.id.isNotEmpty &&
                  user.isOnline;
            },
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

    debugPrint(
      '[MATCH REPOSITORY] '
      'Modo ativo: ${controller.discoveryMode.name}',
    );

    // ==========================================================
    // NÃO CONFIGUROU QUEM PROCURA
    // ==========================================================

    if (lookingForRoles.isEmpty &&
        controller.discoveryMode !=
            MatchDiscoveryMode.global) {
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
            debugPrint(
              '[MATCH REALTIME] '
              '${data.length} perfil(is) recebido(s).',
            );

            for (final profile in data) {
              debugPrint(
                '[MATCH REALTIME] '
                '----------------------------------------',
              );

              debugPrint(
                '[MATCH REALTIME] '
                'ID: ${profile['id']}',
              );

              debugPrint(
                '[MATCH REALTIME] '
                'Username: ${profile['username']}',
              );

              debugPrint(
                '[MATCH REALTIME] '
                'Online: ${profile['is_online']}',
              );

              debugPrint(
                '[MATCH REALTIME] '
                'Location enabled: '
                '${profile['location_enabled']}',
              );

              debugPrint(
                '[MATCH REALTIME] '
                'Latitude: ${profile['latitude']}',
              );

              debugPrint(
                '[MATCH REALTIME] '
                'Longitude: ${profile['longitude']}',
              );

              debugPrint(
                '[MATCH REALTIME] '
                'Location updated at: '
                '${profile['location_updated_at']}',
              );
            }

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
    // ESTADO ATUAL
    // ==========================================================

    final currentUserId = controller.currentUserId;

    final currentRoles = controller.currentRoles;

    final lookingForRoles = controller.lookingForRoles;

    final discoveryMode = controller.discoveryMode;

    // ==========================================================
    // SEM DADOS
    // ==========================================================

    if (data.isEmpty) {
      debugPrint(
        '[MATCH REPOSITORY] '
        'Nenhum perfil online recebido.',
      );

      controller.clearMatchResults();

      return;
    }

    // ==========================================================
    // PERFIL DO PRÓPRIO USUÁRIO
    // ==========================================================
    //
    // O Realtime também pode devolver o próprio perfil.
    //
    // No modo nearby usamos esse registro somente para obter:
    //
    // - location_enabled;
    // - latitude;
    // - longitude.
    //
    // Ele nunca entra na lista de candidatos.
    //
    // ==========================================================

    Map<
      String,
      dynamic
    >?
    currentProfile;

    if (currentUserId !=
        null) {
      for (final profile in data) {
        final profileId = profile['id']?.toString().trim();

        if (profileId ==
            currentUserId) {
          currentProfile = profile;

          break;
        }
      }
    }

    // ==========================================================
    // LOCALIZAÇÃO ATUAL
    // ==========================================================

    final currentLocationEnabled =
        currentProfile?['location_enabled'] ==
        true;

    final currentLatitude = _readNullableDouble(
      currentProfile?['latitude'],
    );

    final currentLongitude = _readNullableDouble(
      currentProfile?['longitude'],
    );

    final hasCurrentLocation =
        currentLocationEnabled &&
        currentLatitude !=
            null &&
        currentLongitude !=
            null &&
        _isValidLatitude(
          currentLatitude,
        ) &&
        _isValidLongitude(
          currentLongitude,
        );

    // ==========================================================
    // LOG DO MODO
    // ==========================================================

    debugPrint(
      '[MATCH REPOSITORY] '
      'Processando modo: ${discoveryMode.name}',
    );

    if (discoveryMode ==
        MatchDiscoveryMode.nearby) {
      debugPrint(
        '[MATCH NEARBY] '
        'Localização do usuário disponível: '
        '$hasCurrentLocation',
      );

      if (hasCurrentLocation) {
        debugPrint(
          '[MATCH NEARBY] '
          'Origem: '
          '${currentLatitude.toStringAsFixed(6)}, '
          '${currentLongitude.toStringAsFixed(6)}',
        );
      } else {
        debugPrint(
          '[MATCH NEARBY] '
          'Modo nearby sem localização válida do usuário.',
        );

        controller.clearMatchResults();

        return;
      }
    }

    // ==========================================================
    // CANDIDATOS
    // ==========================================================
    //
    // Cada item permanece Map para podermos acrescentar:
    //
    // distance
    //
    // sem alterar o payload original vindo do Supabase.
    //
    // ==========================================================

    final candidates =
        <
          Map<
            String,
            dynamic
          >
        >[];

    for (final rawProfile in data) {
      final profile =
          Map<
            String,
            dynamic
          >.from(
            rawProfile,
          );

      // ========================================================
      // ID
      // ========================================================

      final profileId = profile['id']?.toString().trim();

      if (profileId ==
              null ||
          profileId.isEmpty) {
        debugPrint(
          '[MATCH REPOSITORY] '
          'Perfil ignorado: ID inválido.',
        );

        continue;
      }

      // ========================================================
      // NÃO MOSTRAR A SI MESMO
      // ========================================================

      if (currentUserId !=
              null &&
          profileId ==
              currentUserId) {
        debugPrint(
          '[MATCH REPOSITORY] '
          'Perfil ignorado: próprio usuário '
          '($profileId).',
        );

        continue;
      }

      // ========================================================
      // SOMENTE ONLINE
      // ========================================================

      if (profile['is_online'] !=
          true) {
        debugPrint(
          '[MATCH REPOSITORY] '
          'Perfil $profileId ignorado: offline.',
        );

        continue;
      }

      // ========================================================
      // GLOBAL
      // ========================================================
      //
      // Global não exige compatibilidade profissional.
      //
      // ========================================================

      if (discoveryMode ==
          MatchDiscoveryMode.global) {
        candidates.add(
          profile,
        );

        continue;
      }

      // ========================================================
      // FUNÇÕES DO CANDIDATO
      // ========================================================

      final candidateRoles = MusicRole.fromKeys(
        _readList(
          profile['roles'],
        ),
      );

      if (candidateRoles.isEmpty) {
        debugPrint(
          '[MATCH REPOSITORY] '
          'Perfil $profileId ignorado: '
          'sem funções profissionais.',
        );

        continue;
      }

      // ========================================================
      // COMPATIBILIDADE
      // ========================================================

      final compatible = _hasIntersection(
        first: lookingForRoles,
        second: candidateRoles,
      );

      if (!compatible) {
        debugPrint(
          '[MATCH REPOSITORY] '
          'Perfil $profileId ignorado: '
          'não compatível.',
        );

        continue;
      }

      // ========================================================
      // COMPATÍVEIS
      // ========================================================

      if (discoveryMode ==
          MatchDiscoveryMode.compatible) {
        candidates.add(
          profile,
        );

        continue;
      }

      // ========================================================
      // NEARBY
      // ========================================================
      //
      // Nearby mantém a compatibilidade profissional.
      //
      // Além disso exige:
      //
      // - location_enabled = true;
      // - latitude válida;
      // - longitude válida.
      //
      // ========================================================

      if (discoveryMode ==
          MatchDiscoveryMode.nearby) {
        final candidateLocationEnabled =
            profile['location_enabled'] ==
            true;

        final candidateLatitude = _readNullableDouble(
          profile['latitude'],
        );

        final candidateLongitude = _readNullableDouble(
          profile['longitude'],
        );

        final hasCandidateLocation =
            candidateLocationEnabled &&
            candidateLatitude !=
                null &&
            candidateLongitude !=
                null &&
            _isValidLatitude(
              candidateLatitude,
            ) &&
            _isValidLongitude(
              candidateLongitude,
            );

        if (!hasCandidateLocation) {
          debugPrint(
            '[MATCH NEARBY] '
            'Perfil $profileId ignorado: '
            'localização indisponível.',
          );

          continue;
        }

        final distanceKm = _calculateDistanceKm(
          latitudeA: currentLatitude!,
          longitudeA: currentLongitude!,
          latitudeB: candidateLatitude,
          longitudeB: candidateLongitude,
        );

        profile['distance'] = distanceKm;

        debugPrint(
          '[MATCH NEARBY] '
          'Perfil $profileId: '
          '${distanceKm.toStringAsFixed(2)} km.',
        );

        candidates.add(
          profile,
        );
      }
    }

    // ==========================================================
    // SEM CANDIDATOS
    // ==========================================================

    if (candidates.isEmpty) {
      switch (discoveryMode) {
        case MatchDiscoveryMode.compatible:
          debugPrint(
            '[MATCH REPOSITORY] '
            'Nenhum candidato compatível.',
          );

        case MatchDiscoveryMode.nearby:
          debugPrint(
            '[MATCH NEARBY] '
            'Nenhum candidato compatível com '
            'localização disponível.',
          );

        case MatchDiscoveryMode.global:
          debugPrint(
            '[MATCH REPOSITORY] '
            'Nenhum outro usuário online.',
          );
      }

      controller.clearMatchResults();

      return;
    }

    // ==========================================================
    // ORDENAR
    // ==========================================================

    switch (discoveryMode) {
      // ========================================================
      // COMPATÍVEIS
      // ========================================================

      case MatchDiscoveryMode.compatible:
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

      // ========================================================
      // NEARBY
      // ========================================================
      //
      // Primeiro:
      //
      // menor distância.
      //
      // Empate:
      //
      // maior compatibilidade.
      //
      // ========================================================

      case MatchDiscoveryMode.nearby:
        candidates.sort(
          (
            a,
            b,
          ) {
            final distanceA = _readDouble(
              a['distance'],
            );

            final distanceB = _readDouble(
              b['distance'],
            );

            final distanceComparison = distanceA.compareTo(
              distanceB,
            );

            if (distanceComparison !=
                0) {
              return distanceComparison;
            }

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

      // ========================================================
      // GLOBAL
      // ========================================================
      //
      // Global não filtra por profissão.
      //
      // Porém, quando houver compatibilidade, ela pode ser usada
      // somente como critério de ordenação.
      //
      // ========================================================

      case MatchDiscoveryMode.global:
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

            final scoreComparison = scoreB.compareTo(
              scoreA,
            );

            if (scoreComparison !=
                0) {
              return scoreComparison;
            }

            final nameA = _readDisplayName(
              a,
            ).toLowerCase();

            final nameB = _readDisplayName(
              b,
            ).toLowerCase();

            return nameA.compareTo(
              nameB,
            );
          },
        );
    }

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
    // LOG FINAL
    // ==========================================================

    debugPrint(
      '[MATCH REPOSITORY] '
      '${users.length} candidato(s) '
      'no modo ${discoveryMode.name}.',
    );

    for (final user in users) {
      final distanceText =
          discoveryMode ==
              MatchDiscoveryMode.nearby
          ? ' | distância: '
                '${user.distanceKm.toStringAsFixed(2)} km'
          : '';

      debugPrint(
        '[MATCH REPOSITORY] '
        '${user.name} | '
        '${user.usernameLabel} | '
        '${user.primaryRole?.key ?? "sem função"} | '
        'roles: ${MusicRole.toKeys(user.roles)} | '
        'procura: ${MusicRole.toKeys(user.lookingForRoles)}'
        '$distanceText',
      );
    }

    debugPrint(
      '[MATCH REPOSITORY] ========================================',
    );
  }

  // ============================================================
  // DISTÂNCIA
  // ============================================================
  //
  // Fórmula de Haversine.
  //
  // Retorna a distância aproximada em quilômetros entre duas
  // coordenadas geográficas.
  //
  // ============================================================

  double _calculateDistanceKm({
    required double latitudeA,
    required double longitudeA,
    required double latitudeB,
    required double longitudeB,
  }) {
    const earthRadiusKm = 6371.0088;

    final latitudeDelta = _degreesToRadians(
      latitudeB -
          latitudeA,
    );

    final longitudeDelta = _degreesToRadians(
      longitudeB -
          longitudeA,
    );

    final latitudeARadians = _degreesToRadians(
      latitudeA,
    );

    final latitudeBRadians = _degreesToRadians(
      latitudeB,
    );

    final haversine =
        math.pow(
          math.sin(
            latitudeDelta /
                2,
          ),
          2,
        ) +
        math.cos(
              latitudeARadians,
            ) *
            math.cos(
              latitudeBRadians,
            ) *
            math.pow(
              math.sin(
                longitudeDelta /
                    2,
              ),
              2,
            );

    final normalizedHaversine = haversine.toDouble().clamp(
      0.0,
      1.0,
    );

    final centralAngle =
        2 *
        math.atan2(
          math.sqrt(
            normalizedHaversine,
          ),
          math.sqrt(
            1 -
                normalizedHaversine,
          ),
        );

    return earthRadiusKm *
        centralAngle;
  }

  // ============================================================
  // GRAUS → RADIANOS
  // ============================================================

  double _degreesToRadians(
    double degrees,
  ) {
    return degrees *
        math.pi /
        180.0;
  }

  // ============================================================
  // COORDENADAS VÁLIDAS
  // ============================================================

  bool _isValidLatitude(
    double value,
  ) {
    return value >=
            -90.0 &&
        value <=
            90.0;
  }

  bool _isValidLongitude(
    double value,
  ) {
    return value >=
            -180.0 &&
        value <=
            180.0;
  }

  // ============================================================
  // DOUBLE OPCIONAL
  // ============================================================

  double? _readNullableDouble(
    dynamic value,
  ) {
    if (value
        is num) {
      return value.toDouble();
    }

    if (value
        is String) {
      return double.tryParse(
        value.trim(),
      );
    }

    return null;
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
