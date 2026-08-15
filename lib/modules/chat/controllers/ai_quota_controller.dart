import 'package:flutter/foundation.dart';

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

class AiQuotaController
    extends
        ChangeNotifier {
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

  // ============================================================
  // HELPERS
  // ============================================================

  bool get hasLimit =>
      _limitTokens >
      0;

  bool get hasUsage =>
      _usedTokens >
          0 ||
      _usagePercentage >
          0;

  bool get isWarning =>
      _usagePercentage >=
          70 &&
      _usagePercentage <
          90;

  bool get isCritical =>
      _usagePercentage >=
          90 &&
      _usagePercentage <
          100;

  bool get isBlocked =>
      _quotaBlocked ||
      _usagePercentage >=
          100;

  // ============================================================
  // ATUALIZAR A PARTIR DE MAP
  // ============================================================

  void updateFromMap(
    Map<
      String,
      dynamic
    >?
    data,
  ) {
    if (data ==
        null) {
      return;
    }

    final quota = _extractQuotaMap(
      data,
    );

    // ==========================================================
    // PERCENTUAL
    // ==========================================================

    final percentage = _readDouble(
      quota,
      const [
        'usage_percentage',
        'usagePercentage',
        'percentage',
        'percent',
      ],
    );

    // ==========================================================
    // PROGRESSO
    // ==========================================================

    final progress = _readDouble(
      quota,
      const [
        'progress',
        'usage_progress',
        'usageProgress',
      ],
    );

    // ==========================================================
    // TOKENS
    // ==========================================================

    final usedTokens = _readInt(
      quota,
      const [
        'used_tokens',
        'usedTokens',
        'tokens_used',
      ],
    );

    final remainingTokens = _readInt(
      quota,
      const [
        'remaining_tokens',
        'remainingTokens',
        'tokens_remaining',
      ],
    );

    final limitTokens = _readInt(
      quota,
      const [
        'limit_tokens',
        'limitTokens',
        'token_limit',
        'monthly_limit',
      ],
    );

    // ==========================================================
    // BLOQUEIO
    // ==========================================================

    final blocked = _readBool(
      quota,
      const [
        'blocked',
        'quota_blocked',
        'quotaBlocked',
      ],
    );

    final canUse = _readBool(
      quota,
      const [
        'can_use_ai',
        'canUseAi',
        'can_use',
        'canUse',
      ],
    );

    // ==========================================================
    // LEVEL
    // ==========================================================

    final level = _readString(
      quota,
      const [
        'level',
        'usage_level',
        'usageLevel',
      ],
    );

    // ==========================================================
    // MESSAGE
    // ==========================================================

    final message = _readString(
      quota,
      const [
        'message',
        'usage_message',
        'usageMessage',
      ],
    );

    // ==========================================================
    // APLICAR
    // ==========================================================

    if (percentage !=
        null) {
      _usagePercentage = percentage.clamp(
        0.0,
        100.0,
      );
    } else if (usedTokens !=
            null &&
        limitTokens !=
            null &&
        limitTokens >
            0) {
      _usagePercentage =
          ((usedTokens /
                      limitTokens) *
                  100)
              .clamp(
                0.0,
                100.0,
              );
    }

    if (progress !=
        null) {
      _usageProgress = progress.clamp(
        0.0,
        1.0,
      );
    } else {
      _usageProgress =
          (_usagePercentage /
                  100)
              .clamp(
                0.0,
                1.0,
              );
    }

    if (usedTokens !=
        null) {
      _usedTokens =
          usedTokens <
              0
          ? 0
          : usedTokens;
    }

    if (remainingTokens !=
        null) {
      _remainingTokens =
          remainingTokens <
              0
          ? 0
          : remainingTokens;
    }

    if (limitTokens !=
        null) {
      _limitTokens =
          limitTokens <
              0
          ? 0
          : limitTokens;
    }

    // ==========================================================
    // CALCULAR RESTANTE
    // ==========================================================

    if (remainingTokens ==
            null &&
        _limitTokens >
            0) {
      _remainingTokens =
          (_limitTokens -
                  _usedTokens)
              .clamp(
                0,
                _limitTokens,
              );
    }

    // ==========================================================
    // BLOQUEIO
    // ==========================================================

    if (blocked !=
        null) {
      _quotaBlocked = blocked;
    } else {
      _quotaBlocked =
          _usagePercentage >=
          100;
    }

    if (canUse !=
        null) {
      _canUse = canUse;
    } else {
      _canUse = !_quotaBlocked;
    }

    // ==========================================================
    // LEVEL
    // ==========================================================

    if (level !=
            null &&
        level.isNotEmpty) {
      _usageLevel = level;
    } else {
      _usageLevel = _calculateLevel();
    }

    // ==========================================================
    // MESSAGE
    // ==========================================================

    if (message !=
            null &&
        message.isNotEmpty) {
      _usageMessage = message;
    } else {
      _usageMessage = _calculateMessage();
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
  }) {
    if (usagePercentage !=
        null) {
      _usagePercentage = usagePercentage.clamp(
        0.0,
        100.0,
      );
    }

    if (usageProgress !=
        null) {
      _usageProgress = usageProgress.clamp(
        0.0,
        1.0,
      );
    } else if (usagePercentage !=
        null) {
      _usageProgress =
          (_usagePercentage /
                  100)
              .clamp(
                0.0,
                1.0,
              );
    }

    if (usageLevel !=
            null &&
        usageLevel.trim().isNotEmpty) {
      _usageLevel = usageLevel.trim();
    }

    if (usageMessage !=
            null &&
        usageMessage.trim().isNotEmpty) {
      _usageMessage = usageMessage.trim();
    }

    if (quotaBlocked !=
        null) {
      _quotaBlocked = quotaBlocked;
    }

    if (canUse !=
        null) {
      _canUse = canUse;
    }

    if (usedTokens !=
        null) {
      _usedTokens =
          usedTokens <
              0
          ? 0
          : usedTokens;
    }

    if (remainingTokens !=
        null) {
      _remainingTokens =
          remainingTokens <
              0
          ? 0
          : remainingTokens;
    }

    if (limitTokens !=
        null) {
      _limitTokens =
          limitTokens <
              0
          ? 0
          : limitTokens;
    }

    notifyListeners();
  }

  // ============================================================
  // BLOQUEAR
  // ============================================================

  void block({
    String message = 'Limite mensal de IA atingido.',
  }) {
    _usagePercentage = 100.0;

    _usageProgress = 1.0;

    _usageLevel = 'blocked';

    _usageMessage = message;

    _quotaBlocked = true;

    _canUse = false;

    if (_limitTokens >
        0) {
      _usedTokens = _limitTokens;

      _remainingTokens = 0;
    }

    notifyListeners();
  }

  // ============================================================
  // RESET
  // ============================================================

  void reset() {
    _usagePercentage = 0.0;

    _usageProgress = 0.0;

    _usageLevel = 'normal';

    _usageMessage = 'Uso normal da IA.';

    _quotaBlocked = false;

    _canUse = true;

    _usedTokens = 0;

    _remainingTokens = 0;

    _limitTokens = 0;

    notifyListeners();
  }

  // ============================================================
  // EXTRAIR QUOTA
  // ============================================================

  Map<
    String,
    dynamic
  >
  _extractQuotaMap(
    Map<
      String,
      dynamic
    >
    data,
  ) {
    final quota = data['quota'];

    if (quota
        is Map) {
      return Map<
        String,
        dynamic
      >.from(
        quota,
      );
    }

    final aiQuota = data['ai_quota'];

    if (aiQuota
        is Map) {
      return Map<
        String,
        dynamic
      >.from(
        aiQuota,
      );
    }

    final usage = data['usage'];

    if (usage
        is Map) {
      return Map<
        String,
        dynamic
      >.from(
        usage,
      );
    }

    return data;
  }

  // ============================================================
  // LEVEL AUTOMÁTICO
  // ============================================================

  String _calculateLevel() {
    if (_quotaBlocked ||
        _usagePercentage >=
            100) {
      return 'blocked';
    }

    if (_usagePercentage >=
        90) {
      return 'critical';
    }

    if (_usagePercentage >=
        70) {
      return 'warning';
    }

    return 'normal';
  }

  // ============================================================
  // MENSAGEM AUTOMÁTICA
  // ============================================================

  String _calculateMessage() {
    if (_quotaBlocked ||
        _usagePercentage >=
            100) {
      return 'Limite mensal de IA atingido.';
    }

    if (_usagePercentage >=
        90) {
      return 'Seu limite mensal está próximo.';
    }

    if (_usagePercentage >=
        70) {
      return 'Você já utilizou boa parte da sua IA este mês.';
    }

    return 'Uso normal da IA.';
  }

  // ============================================================
  // LER DOUBLE
  // ============================================================

  double? _readDouble(
    Map<
      String,
      dynamic
    >
    map,
    List<
      String
    >
    keys,
  ) {
    for (final key in keys) {
      final value = map[key];

      if (value ==
          null) {
        continue;
      }

      if (value
          is num) {
        return value.toDouble();
      }

      final parsed = double.tryParse(
        value.toString(),
      );

      if (parsed !=
          null) {
        return parsed;
      }
    }

    return null;
  }

  // ============================================================
  // LER INT
  // ============================================================

  int? _readInt(
    Map<
      String,
      dynamic
    >
    map,
    List<
      String
    >
    keys,
  ) {
    for (final key in keys) {
      final value = map[key];

      if (value ==
          null) {
        continue;
      }

      if (value
          is int) {
        return value;
      }

      if (value
          is num) {
        return value.toInt();
      }

      final parsed = int.tryParse(
        value.toString(),
      );

      if (parsed !=
          null) {
        return parsed;
      }
    }

    return null;
  }

  // ============================================================
  // LER BOOL
  // ============================================================

  bool? _readBool(
    Map<
      String,
      dynamic
    >
    map,
    List<
      String
    >
    keys,
  ) {
    for (final key in keys) {
      final value = map[key];

      if (value ==
          null) {
        continue;
      }

      if (value
          is bool) {
        return value;
      }

      if (value
          is num) {
        return value !=
            0;
      }

      final normalized = value.toString().trim().toLowerCase();

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
    }

    return null;
  }

  // ============================================================
  // LER STRING
  // ============================================================

  String? _readString(
    Map<
      String,
      dynamic
    >
    map,
    List<
      String
    >
    keys,
  ) {
    for (final key in keys) {
      final value = map[key];

      if (value ==
          null) {
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
