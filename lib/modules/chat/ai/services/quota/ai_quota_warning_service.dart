import '../../models/ai_quota_warning_state.dart';

// ============================================================
// AI QUOTA WARNING SERVICE
// ============================================================
//
// Responsável pela lógica de apresentação dos avisos de quota.
//
// NÃO:
//
// - chama backend;
// - desconta tokens;
// - controla Redis;
// - conhece Widgets;
// - conhece BuildContext.
//
// Ele apenas recebe AiQuotaWarningState e decide:
//
// normal
//      ↓
// nenhum aviso
//
// warning / critical
//      ↓
// aviso de créditos baixos
//
// blocked
//      ↓
// card de créditos esgotados
//
// ============================================================

class AiQuotaWarningService {
  // ============================================================
  // DEVE MOSTRAR AVISO
  // ============================================================

  bool shouldShowWarning(
    AiQuotaWarningState state,
  ) {
    return state.shouldShowWarning;
  }

  // ============================================================
  // DEVE MOSTRAR AVISO DE QUOTA BAIXA
  // ============================================================

  bool shouldShowLowQuotaWarning(
    AiQuotaWarningState state,
  ) {
    if (state.isBlocked) {
      return false;
    }

    return state.isWarning ||
        state.isCritical;
  }

  // ============================================================
  // DEVE MOSTRAR CARD DE ESGOTADO
  // ============================================================

  bool shouldShowExhaustedCard(
    AiQuotaWarningState state,
  ) {
    return state.isBlocked;
  }

  // ============================================================
  // TÍTULO
  // ============================================================

  String buildTitle(
    AiQuotaWarningState state,
  ) {
    if (state.isBlocked) {
      return 'Seus créditos Versin acabaram';
    }

    if (state.isCritical) {
      return 'Seus créditos estão quase no fim';
    }

    if (state.isWarning) {
      return 'Seus créditos estão diminuindo';
    }

    return '';
  }

  // ============================================================
  // MENSAGEM PRINCIPAL
  // ============================================================

  String buildMessage(
    AiQuotaWarningState state,
  ) {
    if (state.isBlocked) {
      return 'Biblioteca e recursos locais continuam.\n\n'
          'Para continuar com análises por IA, '
          'conecte uma API própria.';
    }

    if (state.isCritical) {
      return 'Você está perto do limite mensal '
          'de créditos da IA Versin.\n\n'
          'Se quiser continuar depois que eles acabarem, '
          'você pode conectar uma API própria.';
    }

    if (state.isWarning) {
      return 'Você já utilizou boa parte dos seus '
          'créditos de IA deste ciclo.';
    }

    return '';
  }

  // ============================================================
  // TEXTO DO BOTÃO
  // ============================================================

  String? buildActionLabel(
    AiQuotaWarningState state,
  ) {
    if (state.isBlocked) {
      return 'Começar configuração';
    }

    if (state.isCritical) {
      return 'Ver como continuar';
    }

    return null;
  }

  // ============================================================
  // TEXTO DA RENOVAÇÃO
  // ============================================================

  String buildRenewalText(
    AiQuotaWarningState state,
  ) {
    final renewsAt = state.renewsAt;

    // ==========================================================
    // SEM DATA
    // ==========================================================

    if (renewsAt ==
        null) {
      if (state.renewsInDays >
          0) {
        return _buildDaysOnlyText(
          state.renewsInDays,
        );
      }

      return '';
    }

    // ==========================================================
    // CONVERTER PARA HORÁRIO LOCAL
    // ==========================================================

    final localDate = renewsAt.toLocal();

    final formattedDate = _formatDate(
      localDate,
    );

    // ==========================================================
    // HOJE / HORAS
    // ==========================================================

    if (state.renewsInDays <=
            1 &&
        state.renewsInHours >
            0 &&
        state.renewsInHours <
            24) {
      final hours = state.renewsInHours;

      final unit =
          hours ==
              1
          ? 'hora'
          : 'horas';

      return 'Renova em $hours $unit • $formattedDate';
    }

    // ==========================================================
    // DIAS
    // ==========================================================

    if (state.renewsInDays >
        0) {
      final days = state.renewsInDays;

      final unit =
          days ==
              1
          ? 'dia'
          : 'dias';

      return 'Renova em $days $unit • $formattedDate';
    }

    // ==========================================================
    // FALLBACK
    // ==========================================================

    return 'Renova em $formattedDate';
  }

  // ============================================================
  // TEXTO SOMENTE COM DIAS
  // ============================================================

  String _buildDaysOnlyText(
    int days,
  ) {
    if (days <=
        0) {
      return '';
    }

    final unit =
        days ==
            1
        ? 'dia'
        : 'dias';

    return 'Renova em $days $unit';
  }

  // ============================================================
  // FORMATAR DATA
  // ============================================================
  //
  // Não utilizamos intl aqui para evitar adicionar dependência
  // apenas para DD/MM/YYYY.
  //
  // ============================================================

  String _formatDate(
    DateTime date,
  ) {
    final day = date.day.toString().padLeft(
      2,
      '0',
    );

    final month = date.month.toString().padLeft(
      2,
      '0',
    );

    final year = date.year.toString();

    return '$day/$month/$year';
  }

  // ============================================================
  // PORCENTAGEM RESTANTE
  // ============================================================

  int getRemainingPercentage(
    AiQuotaWarningState state,
  ) {
    return state.remainingPercentage.round().clamp(
      0,
      100,
    );
  }

  // ============================================================
  // TEXTO DE CRÉDITOS RESTANTES
  // ============================================================

  String buildRemainingText(
    AiQuotaWarningState state,
  ) {
    if (state.isBlocked) {
      return '0% restante';
    }

    final percentage = getRemainingPercentage(
      state,
    );

    return '$percentage% restante';
  }

  // ============================================================
  // CARD COMPLETO?
  // ============================================================
  //
  // Usado futuramente pelo Widget para saber se deve mostrar:
  //
  // título
  // mensagem
  // renovação
  // botão
  //
  // ============================================================

  bool shouldUseFullCard(
    AiQuotaWarningState state,
  ) {
    return state.isCritical ||
        state.isBlocked;
  }

  // ============================================================
  // AVISO DISCRETO?
  // ============================================================

  bool shouldUseCompactWarning(
    AiQuotaWarningState state,
  ) {
    return state.isWarning;
  }

  // ============================================================
  // IDENTIFICADOR DO AVISO
  // ============================================================
  //
  // Isso será útil para impedir que o ChatController adicione o
  // mesmo aviso repetidamente.
  //
  // Exemplos:
  //
  // ai_quota_warning_2026-09-01
  // ai_quota_critical_2026-09-01
  // ai_quota_blocked_2026-09-01
  //
  // ============================================================

  String buildWarningId(
    AiQuotaWarningState state,
  ) {
    final level = state.level.name;

    final renewal = state.renewsAt;

    if (renewal ==
        null) {
      return 'ai_quota_$level';
    }

    final utc = renewal.toUtc();

    final year = utc.year.toString().padLeft(
      4,
      '0',
    );

    final month = utc.month.toString().padLeft(
      2,
      '0',
    );

    final day = utc.day.toString().padLeft(
      2,
      '0',
    );

    return 'ai_quota_${level}_${year}_${month}_${day}';
  }
}
