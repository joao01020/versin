import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/ai_quota_warning_state.dart';
import '../services/cache/ai_quota_cache_service.dart';

// ============================================================
// AI QUOTA CONTROLLER
// ============================================================
//
// Responsável exclusivamente pelo estado da cota mensal
// da IA Versin.
//
// Este controller controla:
//
// - percentual utilizado;
// - progresso;
// - nível;
// - mensagem;
// - bloqueio;
// - permissão de uso;
// - tokens utilizados;
// - tokens restantes;
// - limite mensal.
//
// IMPORTANTE:
//
// API privada não deve consumir a quota Versin.
//
// ============================================================

class AiQuotaController extends ChangeNotifier {
  // ============================================================
  // CACHE LOCAL
  // ============================================================
  //
  // O cache serve apenas para preencher a interface rapidamente
  // enquanto o backend ainda não respondeu.
  //
  // A fonte da verdade continua sendo o backend / Redis.
  //
  // ============================================================

  final AiQuotaCacheService _cacheService;

  bool _isLoadingInitialQuota = true;

  bool _hasLoadedInitialQuota = false;

  bool _hasCachedQuota = false;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  AiQuotaController({AiQuotaCacheService? cacheService})
    : _cacheService = cacheService ?? AiQuotaCacheService() {
    unawaited(loadCachedQuota());
  }

  // ============================================================
  // ESTADO
  // ============================================================

  double _usagePercentage = 0.0;

  double _usageProgress = 0.0;

  String _usageLevel = 'normal';

  String _usageMessage = 'Uso normal da IA.';

  bool _quotaBlocked = false;

  bool _canUse = true;

  int _usedTokens = 0;

  int _remainingTokens = 0;

  int _limitTokens = 0;

  // ============================================================
  // ESTADO COMPLETO DE AVISO / RENOVAÇÃO
  // ============================================================
  //
  // Mantém os metadados devolvidos pelo backend:
  //
  // - normal / warning / critical / blocked;
  // - data de renovação;
  // - dias/horas restantes;
  // - provider;
  // - período;
  // - permissão de uso.
  //
  // ============================================================

  AiQuotaWarningState _warningState = AiQuotaWarningState.initial();

  // ============================================================
  // GETTERS
  // ============================================================

  double get usagePercentage => _usagePercentage;

  double get usageProgress => _usageProgress;

  String get usageLevel => _usageLevel;

  String get usageMessage => _usageMessage;

  bool get quotaBlocked => _quotaBlocked;

  bool get canUse => _canUse;

  int get usedTokens => _usedTokens;

  int get remainingTokens => _remainingTokens;

  int get limitTokens => _limitTokens;

  AiQuotaWarningState get warningState => _warningState;

  DateTime? get renewsAt => _warningState.renewsAt;

  int get renewsInDays => _warningState.renewsInDays;

  int get renewsInHours => _warningState.renewsInHours;

  String get quotaPeriod => _warningState.period;

  String get quotaProvider => _warningState.provider;

  String get renewalTimezone => _warningState.renewalTimezone;

  // ============================================================
  // ESTADO DE CARREGAMENTO INICIAL
  // ============================================================
  //
  // hasLoadedInitialQuota:
  //
  // true quando a tentativa de leitura do cache já terminou.
  //
  // hasCachedQuota:
  //
  // true somente quando havia uma quota local válida.
  //
  // Esses getters permitem que o Dashboard diferencie:
  //
  // "ainda carregando"
  //
  // de:
  //
  // "quota realmente zerada".
  //
  // ============================================================

  bool get isLoadingInitialQuota => _isLoadingInitialQuota;

  bool get hasLoadedInitialQuota => _hasLoadedInitialQuota;

  bool get hasCachedQuota => _hasCachedQuota;

  // ============================================================
  // HELPERS
  // ============================================================

  bool get hasLimit => _limitTokens > 0;

  bool get hasUsage => _usedTokens > 0 || _usagePercentage > 0;

  bool get isWarning => _usagePercentage >= 80 && _usagePercentage < 90;

  bool get isCritical => _usagePercentage >= 90 && _usagePercentage < 100;

  bool get isBlocked => _quotaBlocked || _usagePercentage >= 100;

  // ============================================================
  // CARREGAR QUOTA DO CACHE
  // ============================================================
  //
  // Executado automaticamente ao criar o controller.
  //
  // Fluxo:
  //
  // app abre
  //    ↓
  // lê último valor conhecido
  //    ↓
  // atualiza interface
  //    ↓
  // backend posteriormente substitui pelo valor real
  //
  // ============================================================

  Future<void> loadCachedQuota() async {
    if (!_isLoadingInitialQuota && _hasLoadedInitialQuota) {
      return;
    }

    _isLoadingInitialQuota = true;

    try {
      final cachedQuota = await _cacheService.loadQuota();

      if (cachedQuota != null) {
        _hasCachedQuota = true;

        updateFromMap(cachedQuota, persistCache: false);

        debugPrint(
          '[AI QUOTA] '
          'Estado inicial restaurado do cache.',
        );
      } else {
        _hasCachedQuota = false;

        debugPrint(
          '[AI QUOTA] '
          'Nenhuma quota em cache.',
        );
      }
    } catch (error, stackTrace) {
      _hasCachedQuota = false;

      debugPrint(
        '[AI QUOTA] '
        'Erro ao carregar cache: $error',
      );

      debugPrint(
        '[AI QUOTA] '
        'Stack trace: $stackTrace',
      );
    } finally {
      _isLoadingInitialQuota = false;

      _hasLoadedInitialQuota = true;

      notifyListeners();
    }
  }

  // ============================================================
  // ATUALIZAR A PARTIR DE MAP
  // ============================================================

  void updateFromMap(Map<String, dynamic>? data, {bool persistCache = true}) {
    if (data == null) {
      return;
    }

    final quota = _extractQuotaMap(data);

    // ==========================================================
    // ESTADO TIPADO DE AVISO / RENOVAÇÃO
    // ==========================================================
    //
    // O backend é a fonte da verdade para:
    //
    // level
    // blocked
    // can_use_ai
    // renews_at
    // renews_in_days
    // renews_in_hours
    // provider
    // period
    //
    // ==========================================================

    _warningState = AiQuotaWarningState.fromMap(quota);

    // ==========================================================
    // PERCENTUAL
    // ==========================================================

    final percentage = _readDouble(quota, const [
      'usage_percentage',
      'usagePercentage',
      'percentage',
      'percent',
    ]);

    // ==========================================================
    // PROGRESSO
    // ==========================================================

    final progress = _readDouble(quota, const [
      'progress',
      'usage_progress',
      'usageProgress',
    ]);

    // ==========================================================
    // TOKENS
    // ==========================================================

    final usedTokens = _readInt(quota, const [
      'used_tokens',
      'usedTokens',
      'tokens_used',
    ]);

    final remainingTokens = _readInt(quota, const [
      'remaining_tokens',
      'remainingTokens',
      'tokens_remaining',
    ]);

    final limitTokens = _readInt(quota, const [
      'limit_tokens',
      'limitTokens',
      'token_limit',
      'monthly_limit',
    ]);

    // ==========================================================
    // BLOQUEIO
    // ==========================================================

    final blocked = _readBool(quota, const [
      'blocked',
      'quota_blocked',
      'quotaBlocked',
    ]);

    final canUse = _readBool(quota, const [
      'can_use_ai',
      'canUseAi',
      'can_use',
      'canUse',
    ]);

    // ==========================================================
    // LEVEL
    // ==========================================================

    final level = _readString(quota, const [
      'level',
      'usage_level',
      'usageLevel',
    ]);

    // ==========================================================
    // MESSAGE
    // ==========================================================

    final message = _readString(quota, const [
      'message',
      'usage_message',
      'usageMessage',
    ]);

    // ==========================================================
    // APLICAR
    // ==========================================================

    if (percentage != null) {
      _usagePercentage = percentage.clamp(0.0, 100.0);
    } else if (usedTokens != null && limitTokens != null && limitTokens > 0) {
      _usagePercentage = ((usedTokens / limitTokens) * 100).clamp(0.0, 100.0);
    }

    if (progress != null) {
      _usageProgress = progress.clamp(0.0, 1.0);
    } else {
      _usageProgress = (_usagePercentage / 100).clamp(0.0, 1.0);
    }

    if (usedTokens != null) {
      _usedTokens = usedTokens < 0 ? 0 : usedTokens;
    }

    if (remainingTokens != null) {
      _remainingTokens = remainingTokens < 0 ? 0 : remainingTokens;
    }

    if (limitTokens != null) {
      _limitTokens = limitTokens < 0 ? 0 : limitTokens;
    }

    // ==========================================================
    // CALCULAR RESTANTE
    // ==========================================================

    if (remainingTokens == null && _limitTokens > 0) {
      _remainingTokens = (_limitTokens - _usedTokens).clamp(0, _limitTokens);
    }

    // ==========================================================
    // BLOQUEIO
    // ==========================================================

    if (blocked != null) {
      _quotaBlocked = blocked;
    } else {
      _quotaBlocked = _usagePercentage >= 100;
    }

    if (canUse != null) {
      _canUse = canUse;
    } else {
      _canUse = !_quotaBlocked;
    }

    // ==========================================================
    // LEVEL
    // ==========================================================

    if (level != null && level.isNotEmpty) {
      _usageLevel = level;
    } else {
      _usageLevel = _calculateLevel();
    }

    // ==========================================================
    // MESSAGE
    // ==========================================================

    if (message != null && message.isNotEmpty) {
      _usageMessage = message;
    } else {
      _usageMessage = _calculateMessage();
    }

    // ==========================================================
    // SINCRONIZAR ESTADO TIPADO COM CAMPOS LEGADOS
    // ==========================================================
    //
    // Isso mantém compatibilidade com qualquer parte antiga do
    // app que ainda leia os getters tradicionais deste controller.
    //
    // ==========================================================

    _warningState = _warningState.copyWith(
      level: _levelFromString(_usageLevel),
      usedTokens: _usedTokens,
      remainingTokens: _remainingTokens,
      limitTokens: _limitTokens,
      usagePercentage: _usagePercentage,
      canUseAi: _canUse,
      blocked: _quotaBlocked,
      message: _usageMessage,
    );

    // ==========================================================
    // BACKEND RESPONDEU
    // ==========================================================
    //
    // A partir daqui já temos um estado real recebido pela
    // aplicação. Isso também encerra o estado inicial de loading.
    //
    // ==========================================================

    _isLoadingInitialQuota = false;

    _hasLoadedInitialQuota = true;

    if (persistCache) {
      _hasCachedQuota = true;

      unawaited(_persistCurrentQuota());
    }

    notifyListeners();
  }

  // ============================================================
  // ATUALIZAR MANUALMENTE
  // ============================================================

  void update({
    double? usagePercentage,
    double? usageProgress,
    String? usageLevel,
    String? usageMessage,
    bool? quotaBlocked,
    bool? canUse,
    int? usedTokens,
    int? remainingTokens,
    int? limitTokens,
    AiQuotaWarningState? warningState,
  }) {
    if (usagePercentage != null) {
      _usagePercentage = usagePercentage.clamp(0.0, 100.0);
    }

    if (usageProgress != null) {
      _usageProgress = usageProgress.clamp(0.0, 1.0);
    } else if (usagePercentage != null) {
      _usageProgress = (_usagePercentage / 100).clamp(0.0, 1.0);
    }

    if (usageLevel != null && usageLevel.trim().isNotEmpty) {
      _usageLevel = usageLevel.trim();
    }

    if (usageMessage != null && usageMessage.trim().isNotEmpty) {
      _usageMessage = usageMessage.trim();
    }

    if (quotaBlocked != null) {
      _quotaBlocked = quotaBlocked;
    }

    if (canUse != null) {
      _canUse = canUse;
    }

    if (usedTokens != null) {
      _usedTokens = usedTokens < 0 ? 0 : usedTokens;
    }

    if (remainingTokens != null) {
      _remainingTokens = remainingTokens < 0 ? 0 : remainingTokens;
    }

    if (limitTokens != null) {
      _limitTokens = limitTokens < 0 ? 0 : limitTokens;
    }

    if (warningState != null) {
      _warningState = warningState;
    } else {
      _warningState = _warningState.copyWith(
        level: _levelFromString(_usageLevel),
        usedTokens: _usedTokens,
        remainingTokens: _remainingTokens,
        limitTokens: _limitTokens,
        usagePercentage: _usagePercentage,
        canUseAi: _canUse,
        blocked: _quotaBlocked,
        message: _usageMessage,
      );
    }

    notifyListeners();
  }

  // ============================================================
  // BLOQUEAR
  // ============================================================

  void block({String message = 'Limite mensal de IA atingido.'}) {
    _usagePercentage = 100.0;

    _usageProgress = 1.0;

    _usageLevel = 'blocked';

    _usageMessage = message;

    _quotaBlocked = true;

    _canUse = false;

    if (_limitTokens > 0) {
      _usedTokens = _limitTokens;

      _remainingTokens = 0;
    }

    _warningState = _warningState.copyWith(
      level: AiQuotaWarningLevel.blocked,
      usedTokens: _usedTokens,
      remainingTokens: 0,
      limitTokens: _limitTokens,
      usagePercentage: 100.0,
      canUseAi: false,
      blocked: true,
      message: message,
    );

    _isLoadingInitialQuota = false;

    _hasLoadedInitialQuota = true;

    _hasCachedQuota = true;

    unawaited(_persistCurrentQuota());

    notifyListeners();
  }

  // ============================================================
  // RESET
  // ============================================================

  void reset({bool clearCache = false}) {
    _usagePercentage = 0.0;

    _usageProgress = 0.0;

    _usageLevel = 'normal';

    _usageMessage = 'Uso normal da IA.';

    _quotaBlocked = false;

    _canUse = true;

    _usedTokens = 0;

    _remainingTokens = 0;

    _limitTokens = 0;

    _warningState = AiQuotaWarningState.initial();

    _isLoadingInitialQuota = false;

    _hasLoadedInitialQuota = true;

    _hasCachedQuota = false;

    if (clearCache) {
      unawaited(_cacheService.clear());
    }

    notifyListeners();
  }

  // ============================================================
  // PERSISTIR ESTADO ATUAL
  // ============================================================

  Future<void> _persistCurrentQuota() async {
    final quota = <String, dynamic>{
      'used_tokens': _usedTokens,

      'remaining_tokens': _remainingTokens,

      'limit_tokens': _limitTokens,

      'usage_percentage': _usagePercentage,

      'progress': _usageProgress,

      'level': _usageLevel,

      'message': _usageMessage,

      'blocked': _quotaBlocked,

      'can_use_ai': _canUse,

      'renews_at': _warningState.renewsAt?.toUtc().toIso8601String(),

      'renews_in_days': _warningState.renewsInDays,

      'renews_in_hours': _warningState.renewsInHours,

      'renewal_timezone': _warningState.renewalTimezone,

      'period': _warningState.period,

      'provider': _warningState.provider,
    };

    await _cacheService.saveQuota(quota);
  }

  // ============================================================
  // LIMPAR CACHE EXPLICITAMENTE
  // ============================================================
  //
  // Útil principalmente no logout ou troca de conta.
  //
  // ============================================================

  Future<void> clearCache() async {
    await _cacheService.clear();

    _hasCachedQuota = false;

    notifyListeners();
  }

  // ============================================================
  // EXTRAIR QUOTA
  // ============================================================

  Map<String, dynamic> _extractQuotaMap(Map<String, dynamic> data) {
    final quota = data['quota'];

    if (quota is Map) {
      return Map<String, dynamic>.from(quota);
    }

    final aiQuota = data['ai_quota'];

    if (aiQuota is Map) {
      return Map<String, dynamic>.from(aiQuota);
    }

    final usage = data['usage'];

    if (usage is Map) {
      return Map<String, dynamic>.from(usage);
    }

    return data;
  }

  // ============================================================
  // LEVEL AUTOMÁTICO
  // ============================================================

  String _calculateLevel() {
    if (_quotaBlocked || _usagePercentage >= 100) {
      return 'blocked';
    }

    if (_usagePercentage >= 90) {
      return 'critical';
    }

    if (_usagePercentage >= 80) {
      return 'warning';
    }

    return 'normal';
  }

  // ============================================================
  // MENSAGEM AUTOMÁTICA
  // ============================================================

  String _calculateMessage() {
    if (_quotaBlocked || _usagePercentage >= 100) {
      return 'Seus créditos Versin acabaram neste ciclo mensal.';
    }

    if (_usagePercentage >= 90) {
      return 'Seus créditos Versin estão quase no fim.';
    }

    if (_usagePercentage >= 80) {
      return 'Você já utilizou 80% ou mais dos seus créditos Versin.';
    }

    return 'Uso normal da IA.';
  }

  // ============================================================
  // CONVERTER LEVEL
  // ============================================================

  AiQuotaWarningLevel _levelFromString(String value) {
    switch (value.trim().toLowerCase()) {
      case 'warning':
        return AiQuotaWarningLevel.warning;

      case 'critical':
        return AiQuotaWarningLevel.critical;

      case 'blocked':
        return AiQuotaWarningLevel.blocked;

      case 'normal':
      default:
        return AiQuotaWarningLevel.normal;
    }
  }

  // ============================================================
  // LER DOUBLE
  // ============================================================

  double? _readDouble(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];

      if (value == null) {
        continue;
      }

      if (value is num) {
        return value.toDouble();
      }

      final parsed = double.tryParse(value.toString());

      if (parsed != null) {
        return parsed;
      }
    }

    return null;
  }

  // ============================================================
  // LER INT
  // ============================================================

  int? _readInt(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];

      if (value == null) {
        continue;
      }

      if (value is int) {
        return value;
      }

      if (value is num) {
        return value.toInt();
      }

      final parsed = int.tryParse(value.toString());

      if (parsed != null) {
        return parsed;
      }
    }

    return null;
  }

  // ============================================================
  // LER BOOL
  // ============================================================

  bool? _readBool(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];

      if (value == null) {
        continue;
      }

      if (value is bool) {
        return value;
      }

      if (value is num) {
        return value != 0;
      }

      final normalized = value.toString().trim().toLowerCase();

      if (normalized == 'true' || normalized == '1') {
        return true;
      }

      if (normalized == 'false' || normalized == '0') {
        return false;
      }
    }

    return null;
  }

  // ============================================================
  // LER STRING
  // ============================================================

  String? _readString(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];

      if (value == null) {
        continue;
      }

      final normalized = value.toString().trim();

      if (normalized.isNotEmpty) {
        return normalized;
      }
    }

    return null;
  }
}
