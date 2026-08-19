import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
// carrega última quota conhecida
//      ↓
// Dashboard mostra imediatamente
//      ↓
// backend responde
//      ↓
// quota real substitui o cache
//
// ============================================================

class AiQuotaCacheService {
  // ============================================================
  // CHAVES
  // ============================================================

  static const String _quotaKey = 'versin_ai_quota_cache';

  static const String _updatedAtKey = 'versin_ai_quota_cache_updated_at';

  // ============================================================
  // VERSÃO
  // ============================================================
  //
  // Permite invalidar caches antigos futuramente caso a
  // estrutura da quota seja alterada.
  //
  // ============================================================

  static const int _cacheVersion = 1;

  // ============================================================
  // SALVAR QUOTA
  // ============================================================

  Future<void> saveQuota(Map<String, dynamic> quota) async {
    if (quota.isEmpty) {
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();

      final normalized = _normalizeQuota(quota);

      final payload = <String, dynamic>{
        'version': _cacheVersion,

        'saved_at': DateTime.now().toUtc().toIso8601String(),

        'quota': normalized,
      };

      final encoded = jsonEncode(payload);

      await prefs.setString(_quotaKey, encoded);

      await prefs.setString(
        _updatedAtKey,
        DateTime.now().toUtc().toIso8601String(),
      );

      debugPrint(
        '[AI QUOTA CACHE] '
        'Quota salva localmente.',
      );
    } catch (error, stackTrace) {
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

  Future<Map<String, dynamic>?> loadQuota() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final raw = prefs.getString(_quotaKey);

      if (raw == null || raw.trim().isEmpty) {
        debugPrint(
          '[AI QUOTA CACHE] '
          'Nenhum cache encontrado.',
        );

        return null;
      }

      final decoded = jsonDecode(raw);

      if (decoded is! Map) {
        await clear();

        return null;
      }

      final map = Map<String, dynamic>.from(decoded);

      final version = _readInt(map['version']);

      if (version != _cacheVersion) {
        debugPrint(
          '[AI QUOTA CACHE] '
          'Versão de cache incompatível.',
        );

        await clear();

        return null;
      }

      final quota = map['quota'];

      if (quota is! Map) {
        await clear();

        return null;
      }

      final normalized = _normalizeQuota(Map<String, dynamic>.from(quota));

      if (!_isValidQuota(normalized)) {
        debugPrint(
          '[AI QUOTA CACHE] '
          'Cache inválido.',
        );

        await clear();

        return null;
      }

      debugPrint(
        '[AI QUOTA CACHE] '
        'Quota carregada do cache.',
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
    } catch (error, stackTrace) {
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

  Future<bool> hasCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final raw = prefs.getString(_quotaKey);

      return raw != null && raw.trim().isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // ÚLTIMA ATUALIZAÇÃO
  // ============================================================

  Future<DateTime?> getLastUpdatedAt() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final raw = prefs.getString(_updatedAtKey);

      if (raw == null || raw.trim().isEmpty) {
        return null;
      }

      return DateTime.tryParse(raw);
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // LIMPAR CACHE
  // ============================================================

  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove(_quotaKey);

      await prefs.remove(_updatedAtKey);

      debugPrint(
        '[AI QUOTA CACHE] '
        'Cache removido.',
      );
    } catch (error) {
      debugPrint(
        '[AI QUOTA CACHE] '
        'Falha ao remover cache: $error',
      );
    }
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

  Map<String, dynamic> _normalizeQuota(Map<String, dynamic> quota) {
    final usedTokens = _readInt(quota['used_tokens']);

    final limitTokens = _readInt(quota['limit_tokens']);

    var remainingTokens = _readInt(quota['remaining_tokens']);

    // ==========================================================
    // FALLBACK RESTANTE
    // ==========================================================

    if (limitTokens > 0 && !quota.containsKey('remaining_tokens')) {
      remainingTokens = limitTokens - usedTokens;

      if (remainingTokens < 0) {
        remainingTokens = 0;
      }
    }

    var usagePercentage = _readDouble(quota['usage_percentage']);

    // ==========================================================
    // FALLBACK PERCENTUAL
    // ==========================================================

    if (limitTokens > 0 && !quota.containsKey('usage_percentage')) {
      usagePercentage = (usedTokens / limitTokens) * 100;
    }

    usagePercentage = usagePercentage.clamp(0.0, 100.0);

    final level =
        _readString(quota['level']) ?? _calculateLevel(usagePercentage);

    final blocked = _readBool(
      quota['blocked'],
      fallback: level == 'blocked' || remainingTokens <= 0 && limitTokens > 0,
    );

    final canUseAi = _readBool(quota['can_use_ai'], fallback: !blocked);

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
      'renews_at': _readString(quota['renews_at']),

      'renews_in_days': _readInt(quota['renews_in_days']),

      'renews_in_hours': _readInt(quota['renews_in_hours']),

      'renewal_timezone': _readString(quota['renewal_timezone']) ?? 'UTC',

      // ========================================================
      // METADADOS
      // ========================================================
      'period': _readString(quota['period']) ?? 'monthly',

      'provider': _readString(quota['provider']) ?? 'versin',

      'message': _readString(quota['message']),
    };
  }

  // ============================================================
  // VALIDAR QUOTA
  // ============================================================

  bool _isValidQuota(Map<String, dynamic> quota) {
    final used = _readInt(quota['used_tokens']);

    final remaining = _readInt(quota['remaining_tokens']);

    final limit = _readInt(quota['limit_tokens']);

    if (used < 0 || remaining < 0 || limit < 0) {
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

  String _calculateLevel(double percentage) {
    if (percentage >= 100) {
      return 'blocked';
    }

    if (percentage >= 90) {
      return 'critical';
    }

    if (percentage >= 80) {
      return 'warning';
    }

    return 'normal';
  }

  // ============================================================
  // LER INT
  // ============================================================

  int _readInt(dynamic value) {
    if (value is int) {
      return value < 0 ? 0 : value;
    }

    if (value is num) {
      final parsed = value.toInt();

      return parsed < 0 ? 0 : parsed;
    }

    final parsed = int.tryParse(value?.toString() ?? '');

    if (parsed == null) {
      return 0;
    }

    return parsed < 0 ? 0 : parsed;
  }

  // ============================================================
  // LER DOUBLE
  // ============================================================

  double _readDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  // ============================================================
  // LER BOOL
  // ============================================================

  bool _readBool(dynamic value, {required bool fallback}) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final normalized = value?.toString().trim().toLowerCase();

    if (normalized == 'true' || normalized == '1') {
      return true;
    }

    if (normalized == 'false' || normalized == '0') {
      return false;
    }

    return fallback;
  }

  // ============================================================
  // LER STRING
  // ============================================================

  String? _readString(dynamic value) {
    if (value == null) {
      return null;
    }

    final normalized = value.toString().trim();

    if (normalized.isEmpty) {
      return null;
    }

    return normalized;
  }
}
