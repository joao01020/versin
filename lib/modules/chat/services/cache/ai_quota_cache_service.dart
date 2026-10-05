import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================================
// AI QUOTA CACHE SERVICE
// ============================================================
//
// Responsável por manter localmente a última quota conhecida
// da IA Versin.
//
// IMPORTANTE:
//
// O cache NÃO é a fonte da verdade.
//
// A fonte da verdade continua sendo:
//
// backend
//   ↓
// Redis
//
// O cache existe apenas para melhorar a experiência visual:
//
// aplicativo abre
//      ↓
// identifica o usuário autenticado
//      ↓
// carrega somente o cache desse usuário
//      ↓
// Dashboard mostra imediatamente
//      ↓
// backend responde
//      ↓
// quota real substitui o cache
//
// SEGURANÇA / ISOLAMENTO:
//
// Cada conta possui suas próprias chaves.
//
// Exemplo:
//
// versin_ai_quota_cache_v2_<USER_ID>
// versin_ai_quota_cache_updated_at_v2_<USER_ID>
//
// O cache legado global NÃO é migrado porque não é possível
// determinar com segurança a qual usuário ele pertencia.
//
// ============================================================

class AiQuotaCacheService {
  // ============================================================
  // CHAVES
  // ============================================================

  static const String _quotaKeyPrefix = 'versin_ai_quota_cache_v2';

  static const String _updatedAtKeyPrefix = 'versin_ai_quota_cache_updated_at_v2';

  // ============================================================
  // CHAVES LEGADAS
  // ============================================================
  //
  // Essas chaves eram compartilhadas entre todas as contas.
  //
  // Nunca devem ser lidas novamente.
  //
  // ============================================================

  static const String _legacyQuotaKey = 'versin_ai_quota_cache';

  static const String _legacyUpdatedAtKey = 'versin_ai_quota_cache_updated_at';

  // ============================================================
  // VERSÃO
  // ============================================================
  //
  // Versão 2:
  //
  // - cache isolado por userId;
  // - payload também registra user_id;
  // - cache global antigo não é reutilizado.
  //
  // ============================================================

  static const int _cacheVersion = 2;

  // ============================================================
  // SALVAR QUOTA
  // ============================================================

  Future<
    void
  >
  saveQuota(
    Map<
      String,
      dynamic
    >
    quota, {
    String? userId,
  }) async {
    if (quota.isEmpty) {
      return;
    }

    final resolvedUserId = _resolveUserId(
      userId,
    );

    if (resolvedUserId ==
        null) {
      debugPrint(
        '[AI QUOTA CACHE] '
        'Quota não salva: nenhum usuário autenticado.',
      );

      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();

      await _removeLegacyCache(
        prefs,
      );

      final normalized = _normalizeQuota(
        quota,
      );

      final now = DateTime.now().toUtc().toIso8601String();

      final payload =
          <
            String,
            dynamic
          >{
            'version': _cacheVersion,

            'user_id': resolvedUserId,

            'saved_at': now,

            'quota': normalized,
          };

      final encoded = jsonEncode(
        payload,
      );

      final quotaKey = _buildQuotaKey(
        resolvedUserId,
      );

      final updatedAtKey = _buildUpdatedAtKey(
        resolvedUserId,
      );

      await prefs.setString(
        quotaKey,
        encoded,
      );

      await prefs.setString(
        updatedAtKey,
        now,
      );

      debugPrint(
        '[AI QUOTA CACHE] '
        'Quota salva localmente para o usuário atual.',
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[AI QUOTA CACHE] '
        'Falha ao salvar quota: $error',
      );

      debugPrint(
        '[AI QUOTA CACHE] '
        'Stack trace: $stackTrace',
      );
    }
  }

  // ============================================================
  // CARREGAR QUOTA
  // ============================================================

  Future<
    Map<
      String,
      dynamic
    >?
  >
  loadQuota({
    String? userId,
  }) async {
    final resolvedUserId = _resolveUserId(
      userId,
    );

    if (resolvedUserId ==
        null) {
      debugPrint(
        '[AI QUOTA CACHE] '
        'Cache não carregado: nenhum usuário autenticado.',
      );

      return null;
    }

    try {
      final prefs = await SharedPreferences.getInstance();

      await _removeLegacyCache(
        prefs,
      );

      final quotaKey = _buildQuotaKey(
        resolvedUserId,
      );

      final raw = prefs.getString(
        quotaKey,
      );

      if (raw ==
              null ||
          raw.trim().isEmpty) {
        debugPrint(
          '[AI QUOTA CACHE] '
          'Nenhum cache encontrado para o usuário atual.',
        );

        return null;
      }

      final decoded = jsonDecode(
        raw,
      );

      if (decoded
          is! Map) {
        await clear(
          userId: resolvedUserId,
        );

        return null;
      }

      final map =
          Map<
            String,
            dynamic
          >.from(
            decoded,
          );

      final version = _readInt(
        map['version'],
      );

      if (version !=
          _cacheVersion) {
        debugPrint(
          '[AI QUOTA CACHE] '
          'Versão de cache incompatível.',
        );

        await clear(
          userId: resolvedUserId,
        );

        return null;
      }

      // ========================================================
      // VALIDAR DONO DO CACHE
      // ========================================================

      final cachedUserId = _readString(
        map['user_id'],
      );

      if (cachedUserId ==
              null ||
          cachedUserId !=
              resolvedUserId) {
        debugPrint(
          '[AI QUOTA CACHE] '
          'Cache pertence a outro usuário. Removendo.',
        );

        await clear(
          userId: resolvedUserId,
        );

        return null;
      }

      final quota = map['quota'];

      if (quota
          is! Map) {
        await clear(
          userId: resolvedUserId,
        );

        return null;
      }

      final normalized = _normalizeQuota(
        Map<
          String,
          dynamic
        >.from(
          quota,
        ),
      );

      if (!_isValidQuota(
        normalized,
      )) {
        debugPrint(
          '[AI QUOTA CACHE] '
          'Cache inválido.',
        );

        await clear(
          userId: resolvedUserId,
        );

        return null;
      }

      debugPrint(
        '[AI QUOTA CACHE] '
        'Quota carregada do cache do usuário atual.',
      );

      debugPrint(
        '[AI QUOTA CACHE] '
        'Usados: '
        '${normalized['used_tokens']}',
      );

      debugPrint(
        '[AI QUOTA CACHE] '
        'Restantes: '
        '${normalized['remaining_tokens']}',
      );

      debugPrint(
        '[AI QUOTA CACHE] '
        'Limite: '
        '${normalized['limit_tokens']}',
      );

      return normalized;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[AI QUOTA CACHE] '
        'Falha ao carregar quota: $error',
      );

      debugPrint(
        '[AI QUOTA CACHE] '
        'Stack trace: $stackTrace',
      );

      return null;
    }
  }

  // ============================================================
  // POSSUI CACHE
  // ============================================================

  Future<
    bool
  >
  hasCache({
    String? userId,
  }) async {
    final resolvedUserId = _resolveUserId(
      userId,
    );

    if (resolvedUserId ==
        null) {
      return false;
    }

    try {
      final prefs = await SharedPreferences.getInstance();

      await _removeLegacyCache(
        prefs,
      );

      final raw = prefs.getString(
        _buildQuotaKey(
          resolvedUserId,
        ),
      );

      return raw !=
              null &&
          raw.trim().isNotEmpty;
    } catch (
      _
    ) {
      return false;
    }
  }

  // ============================================================
  // ÚLTIMA ATUALIZAÇÃO
  // ============================================================

  Future<
    DateTime?
  >
  getLastUpdatedAt({
    String? userId,
  }) async {
    final resolvedUserId = _resolveUserId(
      userId,
    );

    if (resolvedUserId ==
        null) {
      return null;
    }

    try {
      final prefs = await SharedPreferences.getInstance();

      await _removeLegacyCache(
        prefs,
      );

      final raw = prefs.getString(
        _buildUpdatedAtKey(
          resolvedUserId,
        ),
      );

      if (raw ==
              null ||
          raw.trim().isEmpty) {
        return null;
      }

      return DateTime.tryParse(
        raw,
      );
    } catch (
      _
    ) {
      return null;
    }
  }

  // ============================================================
  // LIMPAR CACHE
  // ============================================================
  //
  // Remove apenas o cache do usuário informado / autenticado.
  //
  // Isso evita apagar o cache de outras contas que já utilizaram
  // o mesmo dispositivo.
  //
  // ============================================================

  Future<
    void
  >
  clear({
    String? userId,
  }) async {
    final resolvedUserId = _resolveUserId(
      userId,
    );

    try {
      final prefs = await SharedPreferences.getInstance();

      await _removeLegacyCache(
        prefs,
      );

      if (resolvedUserId ==
          null) {
        debugPrint(
          '[AI QUOTA CACHE] '
          'Nenhum usuário autenticado para limpar cache individual.',
        );

        return;
      }

      await prefs.remove(
        _buildQuotaKey(
          resolvedUserId,
        ),
      );

      await prefs.remove(
        _buildUpdatedAtKey(
          resolvedUserId,
        ),
      );

      debugPrint(
        '[AI QUOTA CACHE] '
        'Cache do usuário atual removido.',
      );
    } catch (
      error
    ) {
      debugPrint(
        '[AI QUOTA CACHE] '
        'Falha ao remover cache: $error',
      );
    }
  }

  // ============================================================
  // LIMPAR CACHE LEGADO
  // ============================================================
  //
  // Pode ser chamado explicitamente em migrações.
  //
  // O serviço também executa essa limpeza automaticamente.
  //
  // ============================================================

  Future<
    void
  >
  clearLegacyCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await _removeLegacyCache(
        prefs,
      );
    } catch (
      error
    ) {
      debugPrint(
        '[AI QUOTA CACHE] '
        'Falha ao limpar cache legado: $error',
      );
    }
  }

  // ============================================================
  // RESOLVER USER ID
  // ============================================================

  String? _resolveUserId(
    String? userId,
  ) {
    final explicit = userId?.trim();

    if (explicit !=
            null &&
        explicit.isNotEmpty) {
      return explicit;
    }

    final currentUserId = Supabase.instance.client.auth.currentUser?.id.trim();

    if (currentUserId ==
            null ||
        currentUserId.isEmpty) {
      return null;
    }

    return currentUserId;
  }

  // ============================================================
  // BUILD QUOTA KEY
  // ============================================================

  String _buildQuotaKey(
    String userId,
  ) {
    return '${_quotaKeyPrefix}_${_normalizeUserIdForKey(userId)}';
  }

  // ============================================================
  // BUILD UPDATED AT KEY
  // ============================================================

  String _buildUpdatedAtKey(
    String userId,
  ) {
    return '${_updatedAtKeyPrefix}_${_normalizeUserIdForKey(userId)}';
  }

  // ============================================================
  // NORMALIZAR USER ID PARA CHAVE
  // ============================================================

  String _normalizeUserIdForKey(
    String userId,
  ) {
    final normalized = userId.trim().replaceAll(
      RegExp(
        r'[^a-zA-Z0-9_-]',
      ),
      '_',
    );

    if (normalized.isEmpty) {
      throw ArgumentError(
        'userId inválido para cache.',
      );
    }

    return normalized;
  }

  // ============================================================
  // REMOVER CACHE LEGADO
  // ============================================================

  Future<
    void
  >
  _removeLegacyCache(
    SharedPreferences prefs,
  ) async {
    final hadLegacyQuota = prefs.containsKey(
      _legacyQuotaKey,
    );

    final hadLegacyUpdatedAt = prefs.containsKey(
      _legacyUpdatedAtKey,
    );

    if (!hadLegacyQuota &&
        !hadLegacyUpdatedAt) {
      return;
    }

    await prefs.remove(
      _legacyQuotaKey,
    );

    await prefs.remove(
      _legacyUpdatedAtKey,
    );

    debugPrint(
      '[AI QUOTA CACHE] '
      'Cache global legado removido.',
    );
  }

  // ============================================================
  // NORMALIZAR QUOTA
  // ============================================================
  //
  // Mantemos somente os campos necessários para reconstruir o
  // estado visual.
  //
  // Isso evita persistir informações inesperadas devolvidas
  // pelo backend.
  //
  // ============================================================

  Map<
    String,
    dynamic
  >
  _normalizeQuota(
    Map<
      String,
      dynamic
    >
    quota,
  ) {
    final usedTokens = _readInt(
      quota['used_tokens'],
    );

    final limitTokens = _readInt(
      quota['limit_tokens'],
    );

    var remainingTokens = _readInt(
      quota['remaining_tokens'],
    );

    // ==========================================================
    // FALLBACK RESTANTE
    // ==========================================================

    if (limitTokens >
            0 &&
        !quota.containsKey(
          'remaining_tokens',
        )) {
      remainingTokens =
          limitTokens -
          usedTokens;

      if (remainingTokens <
          0) {
        remainingTokens = 0;
      }
    }

    var usagePercentage = _readDouble(
      quota['usage_percentage'],
    );

    // ==========================================================
    // FALLBACK PERCENTUAL
    // ==========================================================

    if (limitTokens >
            0 &&
        !quota.containsKey(
          'usage_percentage',
        )) {
      usagePercentage =
          (usedTokens /
              limitTokens) *
          100;
    }

    usagePercentage = usagePercentage.clamp(
      0.0,
      100.0,
    );

    final level =
        _readString(
          quota['level'],
        ) ??
        _calculateLevel(
          usagePercentage,
        );

    final blocked = _readBool(
      quota['blocked'],
      fallback:
          level ==
              'blocked' ||
          remainingTokens <=
                  0 &&
              limitTokens >
                  0,
    );

    final canUseAi = _readBool(
      quota['can_use_ai'],
      fallback: !blocked,
    );

    return {
      // ========================================================
      // TOKENS
      // ========================================================
      'used_tokens': usedTokens,

      'remaining_tokens': remainingTokens,

      'limit_tokens': limitTokens,

      // ========================================================
      // USO
      // ========================================================
      'usage_percentage': usagePercentage,

      'level': level,

      'blocked': blocked,

      'can_use_ai': canUseAi,

      // ========================================================
      // RENOVAÇÃO
      // ========================================================
      'renews_at': _readString(
        quota['renews_at'],
      ),

      'renews_in_days': _readInt(
        quota['renews_in_days'],
      ),

      'renews_in_hours': _readInt(
        quota['renews_in_hours'],
      ),

      'renewal_timezone':
          _readString(
            quota['renewal_timezone'],
          ) ??
          'UTC',

      // ========================================================
      // METADADOS
      // ========================================================
      'period':
          _readString(
            quota['period'],
          ) ??
          'monthly',

      'provider':
          _readString(
            quota['provider'],
          ) ??
          'versin',

      'message': _readString(
        quota['message'],
      ),
    };
  }

  // ============================================================
  // VALIDAR QUOTA
  // ============================================================

  bool _isValidQuota(
    Map<
      String,
      dynamic
    >
    quota,
  ) {
    final used = _readInt(
      quota['used_tokens'],
    );

    final remaining = _readInt(
      quota['remaining_tokens'],
    );

    final limit = _readInt(
      quota['limit_tokens'],
    );

    if (used <
            0 ||
        remaining <
            0 ||
        limit <
            0) {
      return false;
    }

    // ==========================================================
    // PRIMEIRO USO
    // ==========================================================
    //
    // 0 / 0 / 0 pode existir temporariamente, então não tratamos
    // isso como erro estrutural.
    //
    // ==========================================================

    return true;
  }

  // ============================================================
  // CALCULAR LEVEL
  // ============================================================

  String _calculateLevel(
    double percentage,
  ) {
    if (percentage >=
        100) {
      return 'blocked';
    }

    if (percentage >=
        90) {
      return 'critical';
    }

    if (percentage >=
        80) {
      return 'warning';
    }

    return 'normal';
  }

  // ============================================================
  // LER INT
  // ============================================================

  int _readInt(
    dynamic value,
  ) {
    if (value
        is int) {
      return value <
              0
          ? 0
          : value;
    }

    if (value
        is num) {
      final parsed = value.toInt();

      return parsed <
              0
          ? 0
          : parsed;
    }

    final parsed = int.tryParse(
      value?.toString() ??
          '',
    );

    if (parsed ==
        null) {
      return 0;
    }

    return parsed <
            0
        ? 0
        : parsed;
  }

  // ============================================================
  // LER DOUBLE
  // ============================================================

  double _readDouble(
    dynamic value,
  ) {
    if (value
        is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ??
              '',
        ) ??
        0.0;
  }

  // ============================================================
  // LER BOOL
  // ============================================================

  bool _readBool(
    dynamic value, {
    required bool fallback,
  }) {
    if (value
        is bool) {
      return value;
    }

    if (value
        is num) {
      return value !=
          0;
    }

    final normalized = value?.toString().trim().toLowerCase();

    if (normalized ==
            'true' ||
        normalized ==
            '1') {
      return true;
    }

    if (normalized ==
            'false' ||
        normalized ==
            '0') {
      return false;
    }

    return fallback;
  }

  // ============================================================
  // LER STRING
  // ============================================================

  String? _readString(
    dynamic value,
  ) {
    if (value ==
        null) {
      return null;
    }

    final normalized = value.toString().trim();

    if (normalized.isEmpty) {
      return null;
    }

    return normalized;
  }
}
