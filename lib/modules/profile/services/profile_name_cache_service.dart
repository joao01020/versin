import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================================
// PROFILE NAME CACHE ENTRY
// ============================================================
//
// Representa um nome resolvido de perfil armazenado em cache.
//
// O cache guarda:
//
// - userId;
// - displayName;
// - updatedAt.
//
// A fonte final continua sendo:
//
// public.profiles
//
// ============================================================

class ProfileNameCacheEntry {
  final String userId;
  final String displayName;
  final DateTime updatedAt;

  const ProfileNameCacheEntry({
    required this.userId,
    required this.displayName,
    required this.updatedAt,
  });

  // ============================================================
  // VALID
  // ============================================================

  bool isValidFor(
    Duration ttl,
  ) {
    final now = DateTime.now().toUtc();

    final age = now.difference(
      updatedAt.toUtc(),
    );

    return age <=
        ttl;
  }

  // ============================================================
  // TO MAP
  // ============================================================

  Map<
    String,
    dynamic
  >
  toMap() {
    return {
      'user_id': userId,
      'display_name': displayName,
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  // ============================================================
  // FROM MAP
  // ============================================================

  factory ProfileNameCacheEntry.fromMap(
    Map<
      String,
      dynamic
    >
    map,
  ) {
    final userId =
        map['user_id']?.toString().trim() ??
        '';

    final displayName =
        map['display_name']?.toString().trim() ??
        '';

    final updatedAtRaw = map['updated_at']?.toString().trim();

    final updatedAt =
        updatedAtRaw ==
                null ||
            updatedAtRaw.isEmpty
        ? DateTime.fromMillisecondsSinceEpoch(
            0,
            isUtc: true,
          )
        : DateTime.tryParse(
                updatedAtRaw,
              ) ??
              DateTime.fromMillisecondsSinceEpoch(
                0,
                isUtc: true,
              );

    return ProfileNameCacheEntry(
      userId: userId,
      displayName: displayName,
      updatedAt: updatedAt,
    );
  }
}

// ============================================================
// PROFILE NAME CACHE SERVICE
// ============================================================
//
// Cache compartilhável para nomes de perfis.
//
// CAMADAS:
//
// 1. RAM
// -> acesso imediato durante a execução.
//
// 2. SharedPreferences
// -> persiste após fechar o aplicativo.
//
// 3. Supabase
// -> fonte final dos dados.
//
// PRIORIDADE DE NOME:
//
// 1. artist_name
// 2. name
// 3. @username
// 4. Membro
//
// USO:
//
// final cache = ProfileNameCacheService();
//
// await cache.init();
//
// final name = await cache.getName(userId);
//
// ou em lote:
//
// final names = await cache.getNames(userIds);
//
// ============================================================

class ProfileNameCacheService {
  // ============================================================
  // CONSTANTS
  // ============================================================

  static const String _storageKey = 'versin_profile_name_cache_v1';

  static const Duration defaultTtl = Duration(
    hours: 24,
  );

  // ============================================================
  // SUPABASE
  // ============================================================

  final SupabaseClient _supabase;

  // ============================================================
  // RAM CACHE
  // ============================================================

  final Map<
    String,
    ProfileNameCacheEntry
  >
  _cache =
      <
        String,
        ProfileNameCacheEntry
      >{};

  // ============================================================
  // STATE
  // ============================================================

  bool _initialized = false;

  Future<
    void
  >?
  _initializationFuture;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  ProfileNameCacheService({
    SupabaseClient? supabase,
  }) : _supabase =
           supabase ??
           Supabase.instance.client;

  // ============================================================
  // INIT
  // ============================================================

  Future<
    void
  >
  init() {
    if (_initialized) {
      return Future<
        void
      >.value();
    }

    final currentInitialization = _initializationFuture;

    if (currentInitialization !=
        null) {
      return currentInitialization;
    }

    final future = _loadFromStorage();

    _initializationFuture = future;

    return future;
  }

  // ============================================================
  // LOAD STORAGE
  // ============================================================

  Future<
    void
  >
  _loadFromStorage() async {
    try {
      final preferences = await SharedPreferences.getInstance();

      final raw = preferences.getString(
        _storageKey,
      );

      if (raw ==
              null ||
          raw.trim().isEmpty) {
        _initialized = true;

        return;
      }

      final decoded = jsonDecode(
        raw,
      );

      if (decoded
          is! Map) {
        _initialized = true;

        return;
      }

      for (final entry in decoded.entries) {
        final userId = entry.key.toString().trim();

        final value = entry.value;

        if (userId.isEmpty ||
            value
                is! Map) {
          continue;
        }

        final map =
            Map<
              String,
              dynamic
            >.from(
              value,
            );

        final cacheEntry = ProfileNameCacheEntry.fromMap(
          map,
        );

        if (cacheEntry.userId.isEmpty ||
            cacheEntry.displayName.isEmpty) {
          continue;
        }

        _cache[userId] = cacheEntry;
      }

      _initialized = true;

      debugPrint(
        '[PROFILE NAME CACHE] '
        '${_cache.length} nomes carregados do armazenamento.',
      );
    } catch (
      error,
      stackTrace
    ) {
      _initialized = true;

      debugPrint(
        '[PROFILE NAME CACHE] '
        'Erro ao carregar cache local: $error',
      );

      debugPrint(
        '$stackTrace',
      );
    } finally {
      _initializationFuture = null;
    }
  }

  // ============================================================
  // GET CACHED NAME
  // ============================================================
  //
  // Não consulta Supabase.
  //
  // Útil para renderizar imediatamente.
  //
  // ============================================================

  String? getCachedName(
    String userId, {
    Duration ttl = defaultTtl,
    bool allowExpired = true,
  }) {
    final normalizedUserId = userId.trim();

    if (normalizedUserId.isEmpty) {
      return null;
    }

    final entry = _cache[normalizedUserId];

    if (entry ==
        null) {
      return null;
    }

    if (!allowExpired &&
        !entry.isValidFor(
          ttl,
        )) {
      return null;
    }

    final name = entry.displayName.trim();

    if (name.isEmpty) {
      return null;
    }

    return name;
  }

  // ============================================================
  // GET NAME
  // ============================================================

  Future<
    String
  >
  getName(
    String userId, {
    Duration ttl = defaultTtl,
    bool refreshExpiredInBackground = true,
  }) async {
    await init();

    final normalizedUserId = userId.trim();

    if (normalizedUserId.isEmpty) {
      return 'Membro';
    }

    final entry = _cache[normalizedUserId];

    // ==========================================================
    // CACHE VÁLIDO
    // ==========================================================

    if (entry !=
            null &&
        entry.displayName.trim().isNotEmpty &&
        entry.isValidFor(
          ttl,
        )) {
      return entry.displayName;
    }

    // ==========================================================
    // CACHE EXPIRADO
    // ==========================================================
    //
    // Mostra imediatamente o nome antigo e atualiza silenciosamente.
    //
    // ==========================================================

    if (entry !=
            null &&
        entry.displayName.trim().isNotEmpty &&
        refreshExpiredInBackground) {
      _refreshSingleInBackground(
        normalizedUserId,
      );

      return entry.displayName;
    }

    // ==========================================================
    // SEM CACHE
    // ==========================================================

    final resolved = await _fetchSingleName(
      normalizedUserId,
    );

    return resolved;
  }

  // ============================================================
  // GET NAMES
  // ============================================================
  //
  // Resolve vários usuários.
  //
  // Estratégia:
  //
  // 1. retorna cache quando existe;
  // 2. identifica IDs sem cache;
  // 3. consulta Supabase em lote;
  // 4. salva novos nomes;
  // 5. atualiza expirados silenciosamente.
  //
  // ============================================================

  Future<
    Map<
      String,
      String
    >
  >
  getNames(
    Iterable<
      String
    >
    userIds, {
    Duration ttl = defaultTtl,
    bool refreshExpiredInBackground = true,
  }) async {
    await init();

    final normalizedIds = userIds
        .map(
          (
            id,
          ) => id.trim(),
        )
        .where(
          (
            id,
          ) => id.isNotEmpty,
        )
        .toSet();

    if (normalizedIds.isEmpty) {
      return <
        String,
        String
      >{};
    }

    final result =
        <
          String,
          String
        >{};

    final missingIds =
        <
          String
        >{};

    final expiredIds =
        <
          String
        >{};

    for (final userId in normalizedIds) {
      final entry = _cache[userId];

      if (entry ==
              null ||
          entry.displayName.trim().isEmpty) {
        missingIds.add(
          userId,
        );

        continue;
      }

      result[userId] = entry.displayName;

      if (!entry.isValidFor(
        ttl,
      )) {
        expiredIds.add(
          userId,
        );
      }
    }

    // ==========================================================
    // SEM CACHE
    // ==========================================================

    if (missingIds.isNotEmpty) {
      final fetched = await _fetchNamesBatch(
        missingIds,
      );

      result.addAll(
        fetched,
      );
    }

    // ==========================================================
    // CACHE EXPIRADO
    // ==========================================================

    if (refreshExpiredInBackground &&
        expiredIds.isNotEmpty) {
      _refreshBatchInBackground(
        expiredIds,
      );
    }

    // ==========================================================
    // FALLBACK
    // ==========================================================

    for (final userId in normalizedIds) {
      result.putIfAbsent(
        userId,
        () => 'Membro',
      );
    }

    return Map<
      String,
      String
    >.unmodifiable(
      result,
    );
  }

  // ============================================================
  // FORCE REFRESH NAME
  // ============================================================

  Future<
    String
  >
  refreshName(
    String userId,
  ) async {
    await init();

    final normalizedUserId = userId.trim();

    if (normalizedUserId.isEmpty) {
      return 'Membro';
    }

    return _fetchSingleName(
      normalizedUserId,
    );
  }

  // ============================================================
  // FORCE REFRESH NAMES
  // ============================================================

  Future<
    Map<
      String,
      String
    >
  >
  refreshNames(
    Iterable<
      String
    >
    userIds,
  ) async {
    await init();

    final normalizedIds = userIds
        .map(
          (
            id,
          ) => id.trim(),
        )
        .where(
          (
            id,
          ) => id.isNotEmpty,
        )
        .toSet();

    if (normalizedIds.isEmpty) {
      return <
        String,
        String
      >{};
    }

    return _fetchNamesBatch(
      normalizedIds,
    );
  }

  // ============================================================
  // FETCH SINGLE
  // ============================================================

  Future<
    String
  >
  _fetchSingleName(
    String userId,
  ) async {
    try {
      final profile = await _supabase
          .from(
            'profiles',
          )
          .select(
            'id, artist_name, name, username',
          )
          .eq(
            'id',
            userId,
          )
          .maybeSingle();

      final name = _resolveProfileName(
        profile,
      );

      await _put(
        userId: userId,
        displayName: name,
      );

      return name;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[PROFILE NAME CACHE] '
        'Erro ao buscar perfil $userId: $error',
      );

      debugPrint(
        '$stackTrace',
      );

      return _cache[userId]?.displayName ??
          'Membro';
    }
  }

  // ============================================================
  // FETCH BATCH
  // ============================================================

  Future<
    Map<
      String,
      String
    >
  >
  _fetchNamesBatch(
    Set<
      String
    >
    userIds,
  ) async {
    if (userIds.isEmpty) {
      return <
        String,
        String
      >{};
    }

    try {
      final response = await _supabase
          .from(
            'profiles',
          )
          .select(
            'id, artist_name, name, username',
          )
          .inFilter(
            'id',
            userIds.toList(
              growable: false,
            ),
          );

      final result =
          <
            String,
            String
          >{};

      final now = DateTime.now().toUtc();

      for (final rawProfile in response) {
        final profile =
            Map<
              String,
              dynamic
            >.from(
              rawProfile,
            );

        final userId = profile['id']?.toString().trim();

        if (userId ==
                null ||
            userId.isEmpty) {
          continue;
        }

        final name = _resolveProfileName(
          profile,
        );

        result[userId] = name;

        _cache[userId] = ProfileNameCacheEntry(
          userId: userId,
          displayName: name,
          updatedAt: now,
        );
      }

      // ========================================================
      // IDS NÃO RETORNADOS
      // ========================================================

      for (final userId in userIds) {
        if (result.containsKey(
          userId,
        )) {
          continue;
        }

        const fallback = 'Membro';

        result[userId] = fallback;

        _cache[userId] = ProfileNameCacheEntry(
          userId: userId,
          displayName: fallback,
          updatedAt: now,
        );
      }

      await _persist();

      return Map<
        String,
        String
      >.unmodifiable(
        result,
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[PROFILE NAME CACHE] '
        'Erro ao buscar perfis em lote: $error',
      );

      debugPrint(
        '$stackTrace',
      );

      final fallback =
          <
            String,
            String
          >{};

      for (final userId in userIds) {
        fallback[userId] =
            _cache[userId]?.displayName ??
            'Membro';
      }

      return fallback;
    }
  }

  // ============================================================
  // RESOLVE PROFILE NAME
  // ============================================================

  String _resolveProfileName(
    Map<
      String,
      dynamic
    >?
    profile,
  ) {
    if (profile ==
        null) {
      return 'Membro';
    }

    final artistName = profile['artist_name']?.toString().trim();

    if (artistName !=
            null &&
        artistName.isNotEmpty) {
      return artistName;
    }

    final name = profile['name']?.toString().trim();

    if (name !=
            null &&
        name.isNotEmpty) {
      return name;
    }

    final username = profile['username']?.toString().trim().replaceFirst(
      RegExp(
        r'^@+',
      ),
      '',
    );

    if (username !=
            null &&
        username.isNotEmpty) {
      return '@$username';
    }

    return 'Membro';
  }

  // ============================================================
  // PUT
  // ============================================================

  Future<
    void
  >
  _put({
    required String userId,
    required String displayName,
  }) async {
    final normalizedUserId = userId.trim();

    final normalizedDisplayName = displayName.trim().isEmpty
        ? 'Membro'
        : displayName.trim();

    if (normalizedUserId.isEmpty) {
      return;
    }

    _cache[normalizedUserId] = ProfileNameCacheEntry(
      userId: normalizedUserId,
      displayName: normalizedDisplayName,
      updatedAt: DateTime.now().toUtc(),
    );

    await _persist();
  }

  // ============================================================
  // REFRESH SINGLE BACKGROUND
  // ============================================================

  void _refreshSingleInBackground(
    String userId,
  ) {
    Future<
      void
    >(
      () async {
        await _fetchSingleName(
          userId,
        );
      },
    );
  }

  // ============================================================
  // REFRESH BATCH BACKGROUND
  // ============================================================

  void _refreshBatchInBackground(
    Set<
      String
    >
    userIds,
  ) {
    Future<
      void
    >(
      () async {
        await _fetchNamesBatch(
          userIds,
        );
      },
    );
  }

  // ============================================================
  // PERSIST
  // ============================================================

  Future<
    void
  >
  _persist() async {
    try {
      final preferences = await SharedPreferences.getInstance();

      final map =
          <
            String,
            dynamic
          >{};

      for (final entry in _cache.entries) {
        map[entry.key] = entry.value.toMap();
      }

      await preferences.setString(
        _storageKey,
        jsonEncode(
          map,
        ),
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[PROFILE NAME CACHE] '
        'Erro ao persistir cache: $error',
      );

      debugPrint(
        '$stackTrace',
      );
    }
  }

  // ============================================================
  // CACHE NAME
  // ============================================================
  //
  // Salva diretamente um nome que outro módulo já conhece.
  //
  // Não consulta o Supabase novamente.
  //
  // ============================================================

  Future<
    void
  >
  cacheName({
    required String userId,
    required String displayName,
  }) async {
    await init();

    final normalizedUserId = userId.trim();

    final normalizedDisplayName = displayName.trim();

    if (normalizedUserId.isEmpty ||
        normalizedDisplayName.isEmpty) {
      return;
    }

    await _put(
      userId: normalizedUserId,
      displayName: normalizedDisplayName,
    );
  }

  // ============================================================
  // CACHE PROFILE MAP
  // ============================================================
  //
  // Recebe uma linha de public.profiles já carregada por outro
  // módulo e sincroniza o nome no cache.
  //
  // Prioridade:
  //
  // 1. artist_name
  // 2. name
  // 3. @username
  // 4. Membro
  //
  // ============================================================

  Future<
    String
  >
  cacheProfileMap(
    Map<
      String,
      dynamic
    >
    profile, {
    String? fallbackUserId,
  }) async {
    await init();

    final profileUserId = profile['id']?.toString().trim();

    final normalizedFallbackUserId = fallbackUserId?.trim();

    final userId =
        profileUserId !=
                null &&
            profileUserId.isNotEmpty
        ? profileUserId
        : normalizedFallbackUserId ??
              '';

    if (userId.isEmpty) {
      return 'Membro';
    }

    final displayName = _resolveProfileName(
      profile,
    );

    await _put(
      userId: userId,
      displayName: displayName,
    );

    return displayName;
  }

  // ============================================================
  // REMOVE USER
  // ============================================================

  Future<
    void
  >
  remove(
    String userId,
  ) async {
    await init();

    final normalizedUserId = userId.trim();

    if (normalizedUserId.isEmpty) {
      return;
    }

    _cache.remove(
      normalizedUserId,
    );

    await _persist();
  }

  // ============================================================
  // CLEAR
  // ============================================================

  Future<
    void
  >
  clear() async {
    await init();

    _cache.clear();

    try {
      final preferences = await SharedPreferences.getInstance();

      await preferences.remove(
        _storageKey,
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[PROFILE NAME CACHE] '
        'Erro ao limpar cache persistente: $error',
      );

      debugPrint(
        '$stackTrace',
      );
    }
  }

  // ============================================================
  // SIZE
  // ============================================================

  int get size => _cache.length;

  // ============================================================
  // HAS
  // ============================================================

  bool contains(
    String userId,
  ) {
    final normalizedUserId = userId.trim();

    if (normalizedUserId.isEmpty) {
      return false;
    }

    return _cache.containsKey(
      normalizedUserId,
    );
  }
}
