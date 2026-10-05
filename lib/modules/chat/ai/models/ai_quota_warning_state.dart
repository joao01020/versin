// ============================================================
// AI QUOTA WARNING LEVEL
// ============================================================
//
// Representa o nível atual de consumo dos créditos Versin.
//
// Backend:
//
// normal
// warning
// critical
// blocked
//
// ============================================================

enum AiQuotaWarningLevel {
  normal,
  warning,
  critical,
  blocked,
}

// ============================================================
// AI QUOTA WARNING STATE
// ============================================================
//
// Estado utilizado pelo frontend para decidir:
//
// - se deve mostrar algum aviso;
// - qual aviso mostrar;
// - quanto ainda resta;
// - quando os créditos renovam;
// - se a IA Versin ainda pode ser utilizada.
//
// IMPORTANTE:
//
// Este model NÃO controla a quota.
//
// A fonte da verdade continua sendo o backend.
//
// ============================================================

class AiQuotaWarningState {
  // ============================================================
  // NÍVEL
  // ============================================================

  final AiQuotaWarningLevel level;

  // ============================================================
  // TOKENS
  // ============================================================

  final int usedTokens;

  final int remainingTokens;

  final int limitTokens;

  // ============================================================
  // PORCENTAGEM
  // ============================================================
  //
  // Representa quanto da quota já foi utilizado.
  //
  // Exemplo:
  //
  // 80.0 = 80% utilizado.
  //
  // ============================================================

  final double usagePercentage;

  // ============================================================
  // ACESSO À IA VERSIN
  // ============================================================

  final bool canUseAi;

  final bool blocked;

  // ============================================================
  // CICLO
  // ============================================================

  final String period;

  final String provider;

  final String renewalTimezone;

  // ============================================================
  // RENOVAÇÃO
  // ============================================================

  final DateTime? renewsAt;

  final int renewsInDays;

  final int renewsInHours;

  // ============================================================
  // MENSAGEM DO BACKEND
  // ============================================================

  final String? message;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  const AiQuotaWarningState({
    required this.level,
    required this.usedTokens,
    required this.remainingTokens,
    required this.limitTokens,
    required this.usagePercentage,
    required this.canUseAi,
    required this.blocked,
    required this.period,
    required this.provider,
    required this.renewalTimezone,
    required this.renewsAt,
    required this.renewsInDays,
    required this.renewsInHours,
    this.message,
  });

  // ============================================================
  // ESTADO INICIAL
  // ============================================================

  factory AiQuotaWarningState.initial() {
    return const AiQuotaWarningState(
      level: AiQuotaWarningLevel.normal,
      usedTokens: 0,
      remainingTokens: 0,
      limitTokens: 0,
      usagePercentage: 0,
      canUseAi: true,
      blocked: false,
      period: 'monthly',
      provider: 'groq',
      renewalTimezone: 'UTC',
      renewsAt: null,
      renewsInDays: 0,
      renewsInHours: 0,
    );
  }

  // ============================================================
  // FROM MAP
  // ============================================================
  //
  // Converte a quota retornada pelo backend.
  //
  // ============================================================

  factory AiQuotaWarningState.fromMap(
    Map<
      String,
      dynamic
    >
    map,
  ) {
    final level = _parseLevel(
      map['level'],
    );

    final renewsAt = _parseDateTime(
      map['renews_at'],
    );

    return AiQuotaWarningState(
      level: level,

      usedTokens: _parseInt(
        map['used_tokens'],
      ),

      remainingTokens: _parseInt(
        map['remaining_tokens'],
      ),

      limitTokens: _parseInt(
        map['limit_tokens'],
      ),

      usagePercentage: _parseDouble(
        map['usage_percentage'],
      ),

      canUseAi: _parseBool(
        map['can_use_ai'],
        fallback:
            level !=
            AiQuotaWarningLevel.blocked,
      ),

      blocked: _parseBool(
        map['blocked'],
        fallback:
            level ==
            AiQuotaWarningLevel.blocked,
      ),

      period:
          map['period']?.toString().trim().isNotEmpty ==
              true
          ? map['period'].toString().trim()
          : 'monthly',

      provider:
          map['provider']?.toString().trim().isNotEmpty ==
              true
          ? map['provider'].toString().trim()
          : 'groq',

      renewalTimezone:
          map['renewal_timezone']?.toString().trim().isNotEmpty ==
              true
          ? map['renewal_timezone'].toString().trim()
          : 'UTC',

      renewsAt: renewsAt,

      renewsInDays: _parseInt(
        map['renews_in_days'],
      ),

      renewsInHours: _parseInt(
        map['renews_in_hours'],
      ),

      message:
          map['message']?.toString().trim().isNotEmpty ==
              true
          ? map['message'].toString().trim()
          : null,
    );
  }

  // ============================================================
  // NORMAL
  // ============================================================

  bool get isNormal {
    return level ==
        AiQuotaWarningLevel.normal;
  }

  // ============================================================
  // WARNING
  // ============================================================

  bool get isWarning {
    return level ==
        AiQuotaWarningLevel.warning;
  }

  // ============================================================
  // CRITICAL
  // ============================================================

  bool get isCritical {
    return level ==
        AiQuotaWarningLevel.critical;
  }

  // ============================================================
  // BLOCKED
  // ============================================================

  bool get isBlocked {
    return blocked ||
        level ==
            AiQuotaWarningLevel.blocked;
  }

  // ============================================================
  // DEVE MOSTRAR ALGUM AVISO
  // ============================================================

  bool get shouldShowWarning {
    return !isNormal;
  }

  // ============================================================
  // DEVE MOSTRAR AVISO DE QUOTA BAIXA
  // ============================================================

  bool get shouldShowLowQuotaWarning {
    return isWarning ||
        isCritical;
  }

  // ============================================================
  // DEVE MOSTRAR CARD DE ESGOTADO
  // ============================================================

  bool get shouldShowExhaustedCard {
    return isBlocked;
  }

  // ============================================================
  // POSSUI DATA DE RENOVAÇÃO
  // ============================================================

  bool get hasRenewalDate {
    return renewsAt !=
        null;
  }

  // ============================================================
  // PORCENTAGEM RESTANTE
  // ============================================================

  double get remainingPercentage {
    final remaining =
        100 -
        usagePercentage;

    if (remaining <
        0) {
      return 0;
    }

    if (remaining >
        100) {
      return 100;
    }

    return remaining;
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  AiQuotaWarningState copyWith({
    AiQuotaWarningLevel? level,
    int? usedTokens,
    int? remainingTokens,
    int? limitTokens,
    double? usagePercentage,
    bool? canUseAi,
    bool? blocked,
    String? period,
    String? provider,
    String? renewalTimezone,
    DateTime? renewsAt,
    int? renewsInDays,
    int? renewsInHours,
    String? message,
  }) {
    return AiQuotaWarningState(
      level:
          level ??
          this.level,
      usedTokens:
          usedTokens ??
          this.usedTokens,
      remainingTokens:
          remainingTokens ??
          this.remainingTokens,
      limitTokens:
          limitTokens ??
          this.limitTokens,
      usagePercentage:
          usagePercentage ??
          this.usagePercentage,
      canUseAi:
          canUseAi ??
          this.canUseAi,
      blocked:
          blocked ??
          this.blocked,
      period:
          period ??
          this.period,
      provider:
          provider ??
          this.provider,
      renewalTimezone:
          renewalTimezone ??
          this.renewalTimezone,
      renewsAt:
          renewsAt ??
          this.renewsAt,
      renewsInDays:
          renewsInDays ??
          this.renewsInDays,
      renewsInHours:
          renewsInHours ??
          this.renewsInHours,
      message:
          message ??
          this.message,
    );
  }

  // ============================================================
  // PARSE LEVEL
  // ============================================================

  static AiQuotaWarningLevel _parseLevel(
    dynamic value,
  ) {
    final normalized = value?.toString().trim().toLowerCase();

    switch (normalized) {
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
  // PARSE INT
  // ============================================================

  static int _parseInt(
    dynamic value,
  ) {
    if (value
        is int) {
      return value;
    }

    if (value
        is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ??
              '',
        ) ??
        0;
  }

  // ============================================================
  // PARSE DOUBLE
  // ============================================================

  static double _parseDouble(
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
        0;
  }

  // ============================================================
  // PARSE BOOL
  // ============================================================

  static bool _parseBool(
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
  // PARSE DATETIME
  // ============================================================

  static DateTime? _parseDateTime(
    dynamic value,
  ) {
    final normalized = value?.toString().trim();

    if (normalized ==
            null ||
        normalized.isEmpty) {
      return null;
    }

    return DateTime.tryParse(
      normalized,
    );
  }

  // ============================================================
  // TO STRING
  // ============================================================

  @override
  String toString() {
    return 'AiQuotaWarningState('
        'level: ${level.name}, '
        'usedTokens: $usedTokens, '
        'remainingTokens: $remainingTokens, '
        'limitTokens: $limitTokens, '
        'usagePercentage: $usagePercentage, '
        'blocked: $blocked, '
        'canUseAi: $canUseAi, '
        'renewsAt: $renewsAt'
        ')';
  }
}
