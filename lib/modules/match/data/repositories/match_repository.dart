import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:versin/core/cache/app_cache_service.dart';
import 'package:versin/core/cache/cache_keys.dart';
import 'package:versin/core/cache/cache_policy.dart';
import 'package:versin/core/cache/request_deduplicator.dart';
import 'package:versin/modules/match/controllers/match_controllers.dart';
import 'package:versin/modules/match/services/match_valid_profile_service.dart';
import 'package:versin/modules/match/data/repositories/match_discovery_policy.dart';
import 'package:versin/modules/match/models/match_discovery_mode.dart';
import 'package:versin/modules/match/models/match_user_entity.dart';

import 'package:versin/modules/profile/models/music_role.dart';

// ============================================================
// MATCH REPOSITORY
// ============================================================
//
// Responsabilidades:
//
// - observar usuários realmente online;
// - descobrir candidatos compatíveis;
// - descobrir candidatos compatíveis por proximidade;
// - descobrir candidatos disponíveis agora;
// - calcular distância entre perfis;
// - pesquisar somente usuários online;
// - usar looking_for_roles do usuário atual;
// - comparar com roles dos candidatos;
// - priorizar interesse mútuo;
// - converter profiles em MatchUserEntity;
// - alimentar Discovery e Recomendados.
//
// ============================================================

class MatchRepository {
  // ============================================================
  // SUPABASE
  // ============================================================

  final SupabaseClient _supabase = Supabase.instance.client;

  final AppCacheService _cache = AppCacheService.instance;

  final RequestDeduplicator _deduplicator = RequestDeduplicator.instance;

  // ============================================================
  // CONFIGURAÇÃO
  // ============================================================

  final MatchValidProfileService _validProfiles = MatchValidProfileService.instance;

  Future<List<MatchUserEntity>> _filterValidEntities(
    List<MatchUserEntity> users,
  ) async {
    if (users.isEmpty) return users;
    final valid = await _validProfiles.validIds(users.map((user) => user.id));
    return users.where((user) => valid.contains(user.id)).toList();
  }

  static const int _searchLimit = 20;

  static const Duration _onlinePresenceWindow = Duration(seconds: 90);

  // ============================================================
  // STREAM
  // ============================================================

  StreamSubscription<List<Map<String, dynamic>>>? _profilesSubscription;

  // ============================================================
  // PESQUISAR USUÁRIOS
  // ============================================================
  //
  // A pesquisa manual continua independente de:
  //
  // available_now
  //
  // Ou seja:
  //
  // um usuário realmente online pode ser encontrado pela busca
  // mesmo que não tenha ativado "Disponíveis agora".
  //
  // ============================================================

  Future<List<MatchUserEntity>> searchUsers({
    required String query,
    String? currentUserId,
  }) async {
    final normalizedQuery = _normalizeSearchQuery(query);
    if (normalizedQuery.isEmpty) return const [];

    final resolvedUserId = currentUserId?.trim().isNotEmpty == true
        ? currentUserId!.trim()
        : (_supabase.auth.currentUser?.id.trim() ?? 'anonymous');

    final cacheKey = CacheKeys.matchSearch(
      userId: resolvedUserId,
      query: normalizedQuery,
    );

    final cached = await _cache.read(cacheKey, policy: CachePolicy.matchSearch);

    if (cached != null) {
      final users = await _filterValidEntities(_decodeCachedUsers(cached.value));
      if (cached.isFresh) return users;

      unawaited(
        _refreshSearchUsers(
          normalizedQuery: normalizedQuery,
          currentUserId: currentUserId,
          cacheKey: cacheKey,
        ),
      );
      return users;
    }

    return _refreshSearchUsers(
      normalizedQuery: normalizedQuery,
      currentUserId: currentUserId,
      cacheKey: cacheKey,
    );
  }

  Future<List<MatchUserEntity>> _refreshSearchUsers({
    required String normalizedQuery,
    required String? currentUserId,
    required String cacheKey,
  }) {
    return _deduplicator.run<
      List<MatchUserEntity>
    >('remote:$cacheKey', () async {
      try {
        final queryBuilder = _supabase
            .from('profiles')
            .select(
              'id,username,artist_name,name,primary_role,roles,looking_for_roles,tags,bio,showcase_url,showcase_desc,is_online,last_seen_at',
            )
            .eq('is_online', true)
            .gte('last_seen_at', _onlineCutoffIso())
            .or(
              'username.ilike.%$normalizedQuery%,'
              'artist_name.ilike.%$normalizedQuery%,'
              'name.ilike.%$normalizedQuery%',
            );

        final dynamic response;
        final id = currentUserId?.trim();
        if (id != null && id.isNotEmpty) {
          response = await queryBuilder.neq('id', id).limit(_searchLimit);
        } else {
          response = await queryBuilder.limit(_searchLimit);
        }

        final rows = List<Map<String, dynamic>>.from(response as List);
        final now = DateTime.now().toUtc();

        final validIds = await _validProfiles.validIds(
          rows.map((row) => row['id']?.toString() ?? ''),
        );
        final users = rows
            .where((row) => validIds.contains(row['id']?.toString()))
            .where((row) => _isProfileReallyOnline(row, now: now))
            .map(_mapMapToEntity)
            .where((user) => user.id.isNotEmpty && user.isOnline)
            .toList();

        users.sort((a, b) {
          final scoreA = _calculateSearchScore(user: a, query: normalizedQuery);
          final scoreB = _calculateSearchScore(user: b, query: normalizedQuery);
          final comparison = scoreB.compareTo(scoreA);
          if (comparison != 0) return comparison;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });

        await _cache.write(cacheKey, users.map(_encodeMatchUser).toList());
        return users;
      } catch (_) {
        final stale = await _cache.read(
          cacheKey,
          policy: CachePolicy.matchSearch,
          allowStale: true,
        );
        if (stale != null) {
          return _filterValidEntities(_decodeCachedUsers(stale.value));
        }
        rethrow;
      }
    });
  }

  Map<String, dynamic> _encodeMatchUser(MatchUserEntity user) {
    return <String, dynamic>{
      'id': user.id,
      'username': user.username,
      'name': user.name,
      'primary_role': user.primaryRole?.key,
      'roles': user.roles.map((e) => e.key).toList(),
      'looking_for_roles': user.lookingForRoles.map((e) => e.key).toList(),
      'tags': user.tags,
      'bio': user.bio,
      'showcase_url': user.showcaseMediaUrl,
      'showcase_desc': user.showcaseDescription,
      'distance_km': user.distanceKm,
      'is_online': user.isOnline,
      'preferred_connection': user.preferredConnection.name,
      'session_started_at': user.sessionStartedAt?.toUtc().toIso8601String(),
      'provisional_hash': user.provisionalHash,
    };
  }

  List<MatchUserEntity> _decodeCachedUsers(dynamic raw) {
    if (raw is! List) return <MatchUserEntity>[];
    final result = <MatchUserEntity>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final preferred = ConnectionType.values.firstWhere(
        (value) => value.name == map['preferred_connection']?.toString(),
        orElse: () => ConnectionType.proximity,
      );
      result.add(
        MatchUserEntity(
          id: map['id']?.toString() ?? '',
          username: map['username']?.toString() ?? '',
          name: map['name']?.toString() ?? '',
          primaryRole: MusicRole.fromKey(map['primary_role']?.toString()),
          roles: MusicRole.fromKeys(
            map['roles'] is Iterable ? map['roles'] as Iterable : const [],
          ),
          lookingForRoles: MusicRole.fromKeys(
            map['looking_for_roles'] is Iterable
                ? map['looking_for_roles'] as Iterable
                : const [],
          ),
          tags: map['tags'] is Iterable
              ? (map['tags'] as Iterable).map((e) => e.toString()).toList()
              : const <String>[],
          bio: map['bio']?.toString() ?? '',
          showcaseMediaUrl: map['showcase_url']?.toString() ?? '',
          showcaseDescription: map['showcase_desc']?.toString() ?? '',
          distanceKm:
              double.tryParse(map['distance_km']?.toString() ?? '') ?? 0,
          isOnline: map['is_online'] == true,
          preferredConnection: preferred,
          sessionStartedAt: DateTime.tryParse(
            map['session_started_at']?.toString() ?? '',
          ),
          provisionalHash: map['provisional_hash']?.toString(),
        ),
      );
    }
    return result;
  }

  // ============================================================
  // SCORE DA PESQUISA
  // ============================================================

  int _calculateSearchScore({
    required MatchUserEntity user,
    required String query,
  }) {
    final normalizedUsername = user.username.trim().toLowerCase();

    final normalizedName = user.name.trim().toLowerCase();

    var score = 0;

    if (normalizedUsername == query) {
      score += 100;
    }

    if (normalizedName == query) {
      score += 90;
    }

    if (normalizedUsername.startsWith(query)) {
      score += 50;
    }

    if (normalizedName.startsWith(query)) {
      score += 40;
    }

    if (normalizedUsername.contains(query)) {
      score += 20;
    }

    if (normalizedName.contains(query)) {
      score += 10;
    }

    if (user.isOnline) {
      score += 1;
    }

    return score;
  }

  // ============================================================
  // NORMALIZAR PESQUISA
  // ============================================================

  String _normalizeSearchQuery(String value) {
    return value.trim().toLowerCase().replaceFirst(RegExp(r'^@+'), '');
  }

  // ============================================================
  // INICIAR STREAM DE MATCH
  // ============================================================

  void streamCrossRoleMatches(MatchController controller) {
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
      '[MATCH REPOSITORY] '
      '========================================',
    );

    debugPrint(
      '[MATCH REPOSITORY] '
      'Iniciando busca.',
    );

    debugPrint(
      '[MATCH REPOSITORY] '
      'User ID: $currentUserId',
    );

    debugPrint(
      '[MATCH REPOSITORY] '
      'Minhas funções: '
      '${currentRoles.map((role) => role.key).toList()}',
    );

    debugPrint(
      '[MATCH REPOSITORY] '
      'Procuro: '
      '${lookingForRoles.map((role) => role.key).toList()}',
    );

    debugPrint(
      '[MATCH REPOSITORY] '
      'Modo ativo: '
      '${controller.discoveryMode.name}',
    );

    // ==========================================================
    // NÃO CONFIGUROU QUEM PROCURA
    // ==========================================================
    //
    // Todos os três modos agora dependem da habilidade.
    //
    // compatible
    // nearby
    // global -> Disponíveis agora
    //
    // ==========================================================

    if (lookingForRoles.isEmpty &&
        !(controller.discoveryMode == MatchDiscoveryMode.compatible &&
            currentRoles.isNotEmpty)) {
      debugPrint(
        '[MATCH REPOSITORY] '
        'Nenhuma profissão procurada configurada.',
      );

      controller.clearMatchResults();

      debugPrint(
        '[MATCH REPOSITORY] '
        '========================================',
      );

      return;
    }

    // ==========================================================
    // STREAM DE CANDIDATOS
    // ==========================================================

    final profilesStream = _supabase.from('profiles').stream(primaryKey: ['id']);

    // Somente Agora restringe o stream à presença ativa.
    // Compatíveis e Próximos precisam receber também perfis offline.
    final stream = MatchDiscoveryPolicy.requiresOnlinePresence(
      controller.discoveryMode,
    )
        ? profilesStream.eq('is_online', true)
        : profilesStream;

    _profilesSubscription = stream.listen(
      (data) async {
        final now = DateTime.now().toUtc();

        final activeProfiles = data
            .where(
              (profile) => MatchDiscoveryPolicy.allowsPresence(
                mode: controller.discoveryMode,
                isOnline: _isProfileReallyOnline(profile, now: now),
              ),
            )
            .map((profile) => Map<String, dynamic>.from(profile))
            .toList(growable: false);

        debugPrint(
          '[MATCH REALTIME] '
          '${data.length} perfil(is) recebido(s); '
          '${activeProfiles.length} com presença ativa.',
        );

        for (final profile in activeProfiles) {
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
            'Available now: '
            '${profile['available_now']}',
          );

          debugPrint(
            '[MATCH REALTIME] '
            'Available until: '
            '${profile['available_until']}',
          );

          debugPrint(
            '[MATCH REALTIME] '
            'Location enabled: '
            '${profile['location_enabled']}',
          );

          debugPrint(
            '[MATCH REALTIME] '
            'Latitude: '
            '${profile['latitude']}',
          );

          debugPrint(
            '[MATCH REALTIME] '
            'Longitude: '
            '${profile['longitude']}',
          );

          debugPrint(
            '[MATCH REALTIME] '
            'Location updated at: '
            '${profile['location_updated_at']}',
          );
        }

        try {
          await _processProfiles(controller: controller, data: activeProfiles);
        } catch (error, stackTrace) {
          debugPrint('[MATCH REPOSITORY] Validação de perfis: $error');
          debugPrint('$stackTrace');
          controller.clearMatchResults();
        }
      },
      onError: (error) {
        debugPrint(
          '[MATCH REPOSITORY] '
          'Erro no pipeline do Match: '
          '$error',
        );

        controller.clearMatchResults();
      },
    );
  }

  // ============================================================
  // PROCESSAR PERFIS
  // ============================================================

  Future<void> _processProfiles({
    required MatchController controller,
    required List<Map<String, dynamic>> data,
  }) async {
    // ==========================================================
    // ESTADO ATUAL
    // ==========================================================

    final currentUserId = controller.currentUserId;

    final currentRoles = controller.currentRoles;

    final lookingForRoles = controller.lookingForRoles;

    final discoveryMode = controller.discoveryMode;

    final now = DateTime.now().toUtc();

    // ==========================================================
    // PERFIS JÁ AVALIADOS
    // ==========================================================

    // Validação obrigatória também para Compatíveis e Próximos.
    // Não usamos is_online como prova de existência da conta.
    final validIds = await _validProfiles.validIds(
      data.map((profile) => profile['id']?.toString() ?? ''),
    );
    data = data.where(
      (profile) => validIds.contains(profile['id']?.toString()),
    ).toList(growable: false);

    final excludedUserIds = await _loadExcludedDiscoveryUserIds(currentUserId);

    // ==========================================================
    // SEM DADOS
    // ==========================================================

    if (data.isEmpty) {
      debugPrint(
        '[MATCH REPOSITORY] '
        'Nenhum perfil recebido para o modo atual.',
      );

      controller.clearMatchResults();

      return;
    }

    // ==========================================================
    // PERFIL DO PRÓPRIO USUÁRIO
    // ==========================================================

    Map<String, dynamic>? currentProfile;

    if (currentUserId != null) {
      for (final profile in data) {
        final profileId = profile['id']?.toString().trim();

        if (profileId == currentUserId) {
          currentProfile = profile;

          break;
        }
      }
    }

    // ==========================================================
    // LOCALIZAÇÃO ATUAL
    // ==========================================================

    final currentLocationEnabled = currentProfile?['location_enabled'] == true;

    final currentLatitude = _readNullableDouble(currentProfile?['latitude']);

    final currentLongitude = _readNullableDouble(currentProfile?['longitude']);

    final hasCurrentLocation =
        currentLocationEnabled &&
        currentLatitude != null &&
        currentLongitude != null &&
        _isValidLatitude(currentLatitude) &&
        _isValidLongitude(currentLongitude);

    // ==========================================================
    // LOG DO MODO
    // ==========================================================

    debugPrint(
      '[MATCH REPOSITORY] '
      'Processando modo: '
      '${discoveryMode.name}',
    );

    // ==========================================================
    // NEARBY EXIGE LOCALIZAÇÃO
    // ==========================================================

    if (discoveryMode == MatchDiscoveryMode.nearby) {
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

    final candidates = <Map<String, dynamic>>[];

    for (final rawProfile in data) {
      final profile = Map<String, dynamic>.from(rawProfile);

      // ========================================================
      // ID
      // ========================================================

      final profileId = profile['id']?.toString().trim();

      if (profileId == null || profileId.isEmpty) {
        debugPrint(
          '[MATCH REPOSITORY] '
          'Perfil ignorado: ID inválido.',
        );

        continue;
      }

      // ========================================================
      // NÃO MOSTRAR A SI MESMO
      // ========================================================

      if (currentUserId != null && profileId == currentUserId) {
        debugPrint(
          '[MATCH REPOSITORY] '
          'Perfil ignorado: próprio usuário '
          '($profileId).',
        );

        continue;
      }

      // ========================================================
      // JÁ AVALIADO
      // ========================================================

      if (excludedUserIds.contains(profileId)) {
        debugPrint(
          '[MATCH REPOSITORY] '
          'Perfil $profileId ignorado: '
          'já recebeu like ou X.',
        );

        continue;
      }

      // ========================================================
      // PRESENÇA EXIGIDA SOMENTE EM AGORA
      // ========================================================

      if (!MatchDiscoveryPolicy.allowsPresence(
        mode: discoveryMode,
        isOnline: _isProfileReallyOnline(profile, now: now),
      )) {
        debugPrint(
          '[MATCH REPOSITORY] '
          'Perfil $profileId ignorado: '
          'sem presença recente no modo Agora.',
        );

        continue;
      }

      // ========================================================
      // FUNÇÕES DO CANDIDATO
      // ========================================================

      final candidateRoles = MusicRole.fromKeys(_readList(profile['roles']));

      if (candidateRoles.isEmpty) {
        debugPrint(
          '[MATCH REPOSITORY] '
          'Perfil $profileId ignorado: '
          'sem funções profissionais.',
        );

        continue;
      }

      // ========================================================
      // COMPATIBILIDADE DE HABILIDADE
      // ========================================================
      //
      // Exemplo:
      //
      // usuário procura:
      //
      // Beatmaker
      //
      // candidato precisa possuir:
      //
      // Beatmaker
      //
      // em roles.
      //
      // Isso vale para:
      //
      // - Compatíveis;
      // - Próximos;
      // - Disponíveis agora.
      //
      // ========================================================

      final compatible = MatchDiscoveryPolicy.matchesRoles(
        mode: discoveryMode,
        currentRoles: currentRoles,
        lookingForRoles: lookingForRoles,
        candidateRoles: candidateRoles,
        candidateLookingForRoles: MusicRole.fromKeys(
          _readList(profile['looking_for_roles']),
        ),
      );

      if (!compatible) {
        debugPrint(
          '[MATCH REPOSITORY] '
          'Perfil $profileId ignorado: '
          'não possui habilidade procurada.',
        );

        continue;
      }

      // ========================================================
      // DISPONÍVEIS AGORA
      // ========================================================
      //
      // Internamente ainda usamos:
      //
      // MatchDiscoveryMode.global
      //
      // mas visualmente esse modo é:
      //
      // DISPONÍVEIS AGORA
      //
      // Exige:
      //
      // - online real;
      // - habilidade compatível;
      // - available_now == true;
      // - available_until válido;
      // - available_until > agora.
      //
      // ========================================================

      if (discoveryMode == MatchDiscoveryMode.global) {
        if (!_isProfileAvailableNow(profile, now: now)) {
          debugPrint(
            '[MATCH AVAILABLE NOW] '
            'Perfil $profileId ignorado: '
            'não está disponível agora.',
          );

          continue;
        }

        candidates.add(profile);

        continue;
      }

      // ========================================================
      // COMPATÍVEIS
      // ========================================================

      if (discoveryMode == MatchDiscoveryMode.compatible) {
        candidates.add(profile);

        continue;
      }

      // ========================================================
      // PRÓXIMOS
      // ========================================================

      if (discoveryMode == MatchDiscoveryMode.nearby) {
        final candidateLocationEnabled = profile['location_enabled'] == true;

        final candidateLatitude = _readNullableDouble(profile['latitude']);

        final candidateLongitude = _readNullableDouble(profile['longitude']);

        final hasCandidateLocation =
            candidateLocationEnabled &&
            candidateLatitude != null &&
            candidateLongitude != null &&
            _isValidLatitude(candidateLatitude) &&
            _isValidLongitude(candidateLongitude);

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

        candidates.add(profile);
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
            '[MATCH AVAILABLE NOW] '
            'Nenhum profissional compatível '
            'está disponível agora.',
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
        candidates.sort((a, b) {
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

          return scoreB.compareTo(scoreA);
        });

      // ========================================================
      // PRÓXIMOS
      // ========================================================

      case MatchDiscoveryMode.nearby:
        candidates.sort((a, b) {
          final distanceA = _readDouble(a['distance']);

          final distanceB = _readDouble(b['distance']);

          final distanceComparison = distanceA.compareTo(distanceB);

          if (distanceComparison != 0) {
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

          return scoreB.compareTo(scoreA);
        });

      // ========================================================
      // DISPONÍVEIS AGORA
      // ========================================================
      //
      // Todos que chegaram aqui:
      //
      // - estão realmente online;
      // - possuem habilidade compatível;
      // - ativaram disponibilidade;
      // - ainda estão dentro do tempo.
      //
      // Ordenamos pela compatibilidade profissional.
      //
      // ========================================================

      case MatchDiscoveryMode.global:
        candidates.sort((a, b) {
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

          final scoreComparison = scoreB.compareTo(scoreA);

          if (scoreComparison != 0) {
            return scoreComparison;
          }

          final nameA = _readDisplayName(a).toLowerCase();

          final nameB = _readDisplayName(b).toLowerCase();

          return nameA.compareTo(nameB);
        });
    }

    // ==========================================================
    // CONVERTER
    // ==========================================================

    final users = candidates.map(_mapMapToEntity).toList();

    if (users.isEmpty) {
      controller.clearMatchResults();

      return;
    }

    // ==========================================================
    // DISCOVERY
    // ==========================================================

    controller.setDiscoveryUser(users.first);

    // ==========================================================
    // RECOMENDADOS
    // ==========================================================

    controller.updateRecommendedUsers(users.skip(1).toList());

    // ==========================================================
    // LOG FINAL
    // ==========================================================

    debugPrint(
      '[MATCH REPOSITORY] '
      '${users.length} candidato(s) '
      'no modo ${discoveryMode.name}.',
    );

    for (final user in users) {
      final distanceText = discoveryMode == MatchDiscoveryMode.nearby
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
      '[MATCH REPOSITORY] '
      '========================================',
    );
  }

  // ============================================================
  // CARREGAR PERFIS JÁ AVALIADOS
  // ============================================================

  Future<Set<String>> _loadExcludedDiscoveryUserIds(
    String? currentUserId,
  ) async {
    final normalizedUserId = currentUserId?.trim();

    if (normalizedUserId == null || normalizedUserId.isEmpty) {
      return <String>{};
    }

    final excluded = <String>{};

    // ==========================================================
    // LIKES
    // ==========================================================

    try {
      final likes = await _supabase
          .from('favorites')
          .select('target_user_id')
          .eq('sender_id', normalizedUserId);

      for (final row in likes) {
        final targetId = row['target_user_id']?.toString().trim();

        if (targetId != null && targetId.isNotEmpty) {
          excluded.add(targetId);
        }
      }
    } on PostgrestException catch (error, stackTrace) {
      debugPrint(
        '[MATCH REPOSITORY] '
        'Erro ao carregar likes já enviados: '
        '${error.message}',
      );

      debugPrint('$stackTrace');
    } catch (error, stackTrace) {
      debugPrint(
        '[MATCH REPOSITORY] '
        'Erro inesperado ao carregar likes: '
        '$error',
      );

      debugPrint('$stackTrace');
    }

    // ==========================================================
    // PASSES / X
    // ==========================================================

    try {
      final passes = await _supabase
          .from('match_passes')
          .select('target_user_id')
          .eq('sender_id', normalizedUserId);

      for (final row in passes) {
        final targetId = row['target_user_id']?.toString().trim();

        if (targetId != null && targetId.isNotEmpty) {
          excluded.add(targetId);
        }
      }
    } on PostgrestException catch (error, stackTrace) {
      debugPrint(
        '[MATCH REPOSITORY] '
        'Erro ao carregar passes já enviados: '
        '${error.message}',
      );

      debugPrint('$stackTrace');
    } catch (error, stackTrace) {
      debugPrint(
        '[MATCH REPOSITORY] '
        'Erro inesperado ao carregar passes: '
        '$error',
      );

      debugPrint('$stackTrace');
    }

    debugPrint(
      '[MATCH REPOSITORY] '
      'Perfis excluídos da descoberta: '
      '${excluded.length}.',
    );

    return excluded;
  }

  // ============================================================
  // DISTÂNCIA
  // ============================================================

  double _calculateDistanceKm({
    required double latitudeA,
    required double longitudeA,
    required double latitudeB,
    required double longitudeB,
  }) {
    const earthRadiusKm = 6371.0088;

    final latitudeDelta = _degreesToRadians(latitudeB - latitudeA);

    final longitudeDelta = _degreesToRadians(longitudeB - longitudeA);

    final latitudeARadians = _degreesToRadians(latitudeA);

    final latitudeBRadians = _degreesToRadians(latitudeB);

    final haversine =
        math.pow(math.sin(latitudeDelta / 2), 2) +
        math.cos(latitudeARadians) *
            math.cos(latitudeBRadians) *
            math.pow(math.sin(longitudeDelta / 2), 2);

    final normalizedHaversine = haversine.toDouble().clamp(0.0, 1.0);

    final centralAngle =
        2 *
        math.atan2(
          math.sqrt(normalizedHaversine),
          math.sqrt(1 - normalizedHaversine),
        );

    return earthRadiusKm * centralAngle;
  }

  // ============================================================
  // GRAUS → RADIANOS
  // ============================================================

  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180.0;
  }

  // ============================================================
  // COORDENADAS VÁLIDAS
  // ============================================================

  bool _isValidLatitude(double value) {
    return value >= -90.0 && value <= 90.0;
  }

  bool _isValidLongitude(double value) {
    return value >= -180.0 && value <= 180.0;
  }

  // ============================================================
  // DOUBLE OPCIONAL
  // ============================================================

  double? _readNullableDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value.trim());
    }

    return null;
  }

  // ============================================================
  // SCORE DE COMPATIBILIDADE
  // ============================================================

  int _calculateCompatibilityScore({
    required Map<String, dynamic> profile,
    required Set<MusicRole> currentRoles,
    required Set<MusicRole> lookingForRoles,
  }) {
    final candidateRoles = MusicRole.fromKeys(_readList(profile['roles']));

    final candidateLookingForRoles = MusicRole.fromKeys(
      _readList(profile['looking_for_roles']),
    );

    final candidatePrimaryRole = MusicRole.fromKey(
      profile['primary_role']?.toString(),
    );

    var score = 0;

    // ==========================================================
    // TEM O QUE EU PROCURO
    // ==========================================================

    for (final role in candidateRoles) {
      if (lookingForRoles.contains(role)) {
        score += 10;
      }
    }

    // ==========================================================
    // PRINCIPAL É O QUE EU PROCURO
    // ==========================================================

    if (candidatePrimaryRole != null &&
        lookingForRoles.contains(candidatePrimaryRole)) {
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

    if (_isProfileReallyOnline(profile)) {
      score += 1;
    }

    return score;
  }

  // ============================================================
  // INTERSEÇÃO
  // ============================================================

  bool _hasIntersection({
    required Iterable<MusicRole> first,
    required Iterable<MusicRole> second,
  }) {
    final secondSet = second.toSet();

    for (final role in first) {
      if (secondSet.contains(role)) {
        return true;
      }
    }

    return false;
  }

  // ============================================================
  // PRESENÇA REAL
  // ============================================================
  //
  // ONLINE AGORA exige:
  //
  // - is_online == true;
  // - last_seen_at válido;
  // - heartbeat nos últimos 90 segundos.
  //
  // ============================================================

  String _onlineCutoffIso() {
    return DateTime.now()
        .toUtc()
        .subtract(_onlinePresenceWindow)
        .toIso8601String();
  }

  bool _isProfileReallyOnline(Map<String, dynamic> profile, {DateTime? now}) {
    if (profile['is_online'] != true) {
      return false;
    }

    final lastSeenAt = _readNullableDateTime(profile['last_seen_at']);

    if (lastSeenAt == null) {
      return false;
    }

    final reference = (now ?? DateTime.now()).toUtc();

    final difference = reference.difference(lastSeenAt);

    // Pequena tolerância para relógio do servidor/cliente.

    if (difference.isNegative) {
      return true;
    }

    return difference <= _onlinePresenceWindow;
  }

  // ============================================================
  // DISPONÍVEL AGORA
  // ============================================================
  //
  // Não substitui a presença.
  //
  // O candidato precisa primeiro estar realmente online.
  //
  // Depois verificamos:
  //
  // available_now == true
  //
  // E:
  //
  // available_until > agora
  //
  // ============================================================

  bool _isProfileAvailableNow(Map<String, dynamic> profile, {DateTime? now}) {
    if (profile['available_now'] != true) {
      return false;
    }

    final availableUntil = _readNullableDateTime(profile['available_until']);

    if (availableUntil == null) {
      return false;
    }

    final reference = (now ?? DateTime.now()).toUtc();

    return availableUntil.isAfter(reference);
  }

  // ============================================================
  // DATETIME OPCIONAL
  // ============================================================

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
  // MAPEAR SUPABASE → ENTITY
  // ============================================================

  MatchUserEntity _mapMapToEntity(Map<String, dynamic> map) {
    final username = _readUsername(map);

    final displayName = _readDisplayName(map);

    final primaryRole = MusicRole.fromKey(map['primary_role']?.toString());

    final roles = MusicRole.fromKeys(_readList(map['roles']));

    final lookingForRoles = MusicRole.fromKeys(
      _readList(map['looking_for_roles']),
    );

    final tags = _readList(map['tags'])
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();

    return MatchUserEntity(
      id: map['id']?.toString().trim() ?? '',

      username: username,

      name: displayName,

      primaryRole: primaryRole,

      roles: roles,

      lookingForRoles: lookingForRoles,

      tags: tags,

      bio: map['bio']?.toString().trim() ?? '',

      showcaseMediaUrl: map['showcase_url']?.toString().trim() ?? '',

      showcaseDescription: map['showcase_desc']?.toString().trim() ?? '',

      distanceKm: _readDouble(map['distance']),

      isOnline: _isProfileReallyOnline(map),
    );
  }

  // ============================================================
  // USERNAME
  // ============================================================

  String _readUsername(Map<String, dynamic> map) {
    final username = map['username']?.toString().trim();

    if (username == null || username.isEmpty) {
      return '';
    }

    return username.replaceFirst(RegExp(r'^@+'), '');
  }

  // ============================================================
  // NOME PARA EXIBIÇÃO
  // ============================================================

  String _readDisplayName(Map<String, dynamic> map) {
    final artistName = map['artist_name']?.toString().trim();

    if (artistName != null && artistName.isNotEmpty) {
      return artistName;
    }

    final name = map['name']?.toString().trim();

    if (name != null && name.isNotEmpty) {
      return name;
    }

    final username = _readUsername(map);

    if (username.isNotEmpty) {
      return username;
    }

    return 'Sem Nome';
  }

  // ============================================================
  // LIST
  // ============================================================

  Iterable<dynamic> _readList(dynamic value) {
    if (value == null) {
      return const [];
    }

    if (value is Iterable) {
      return value;
    }

    return const [];
  }

  // ============================================================
  // DOUBLE
  // ============================================================

  double _readDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }

    return 0.0;
  }

  // ============================================================
  // PARAR STREAM
  // ============================================================

  Future<void> stopStreaming() async {
    await _profilesSubscription?.cancel();

    _profilesSubscription = null;
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  Future<void> dispose() async {
    await stopStreaming();
  }
}
