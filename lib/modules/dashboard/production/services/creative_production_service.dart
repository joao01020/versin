import '../models/creative_production_month.dart';

// ============================================================
// CREATIVE PRODUCTION SERVICE
// ============================================================
//
// Responsável pelas regras de negócio da produção criativa.
//
// Ele recebe dados mensais brutos vindos do:
//
// CreativeActivityService
//
// e calcula:
//
// - score de produção;
// - variação percentual em relação ao mês anterior;
// - normalização dos meses;
// - dados prontos para o Dashboard.
//
// Este service NÃO:
//
// - consulta Supabase;
// - registra eventos;
// - conhece widgets;
// - controla loading;
// - possui BuildContext.
//
// ============================================================

class CreativeProductionService {
  // ==========================================================
  // PESOS
  // ==========================================================
  //
  // Estes pesos definem a importância relativa de cada tipo de
  // atividade no score mensal.
  //
  // IMPORTANTE:
  //
  // O score bruto NÃO precisa ficar limitado a 100.
  //
  // Depois ele é normalizado para uma escala de 0 até 100.
  //
  // ==========================================================

  static const double projectCreatedWeight = 10.0;

  static const double compositionSessionWeight = 3.0;

  static const double taskCompletedWeight = 2.0;

  static const double collaborationStartedWeight = 8.0;

  static const double fileAddedWeight = 2.0;

  // ==========================================================
  // SCORE MÁXIMO DE REFERÊNCIA
  // ==========================================================
  //
  // Define qual score bruto representa 100 pontos.
  //
  // Exemplo:
  //
  // score bruto = 120
  // referência = 150
  //
  // score normalizado:
  //
  // 80
  //
  // Se passar da referência, limitamos em 100.
  //
  // Isso evita que o gráfico cresça indefinidamente.
  //
  // ==========================================================

  static const double referenceMonthlyScore = 150.0;

  // ==========================================================
  // PROCESSAR MESES
  // ==========================================================
  //
  // Entrada:
  //
  // dados brutos vindos da RPC.
  //
  // Saída:
  //
  // mesma lista com:
  //
  // - score;
  // - changeFromPreviousMonth.
  //
  // ==========================================================

  List<
    CreativeProductionMonth
  >
  processMonths(
    List<
      CreativeProductionMonth
    >
    months,
  ) {
    if (months.isEmpty) {
      return const <
        CreativeProductionMonth
      >[];
    }

    // ========================================================
    // ORDENAR
    // ========================================================
    //
    // A comparação mensal exige:
    //
    // mês anterior
    // ↓
    // mês atual
    //
    // ========================================================

    final sorted =
        List<
            CreativeProductionMonth
          >.from(
            months,
          )
          ..sort(
            (
              a,
              b,
            ) {
              return a.month.compareTo(
                b.month,
              );
            },
          );

    final result =
        <
          CreativeProductionMonth
        >[];

    CreativeProductionMonth? previousMonth;

    for (final month in sorted) {
      // ======================================================
      // SCORE
      // ======================================================

      final score = calculateScore(
        month,
      );

      // ======================================================
      // VARIAÇÃO
      // ======================================================

      final change =
          previousMonth ==
              null
          ? 0.0
          : calculateChangePercentage(
              previousScore: previousMonth.score,
              currentScore: score,
            );

      final processed = month.copyWith(
        score: score,
        changeFromPreviousMonth: change,
      );

      result.add(
        processed,
      );

      previousMonth = processed;
    }

    return List<
      CreativeProductionMonth
    >.unmodifiable(
      result,
    );
  }

  // ==========================================================
  // CALCULAR SCORE
  // ==========================================================
  //
  // Score bruto:
  //
  // projetos      × 10
  // sessões       × 3
  // tarefas       × 2
  // colaborações  × 8
  // arquivos      × 2
  //
  // Depois normalizamos para:
  //
  // 0 → 100
  //
  // ==========================================================

  double calculateScore(
    CreativeProductionMonth month,
  ) {
    final rawScore = calculateRawScore(
      month,
    );

    return normalizeScore(
      rawScore,
    );
  }

  // ==========================================================
  // SCORE BRUTO
  // ==========================================================

  double calculateRawScore(
    CreativeProductionMonth month,
  ) {
    final projectsScore =
        month.projectsCreated *
        projectCreatedWeight;

    final sessionsScore =
        month.compositionSessions *
        compositionSessionWeight;

    final tasksScore =
        month.tasksCompleted *
        taskCompletedWeight;

    final collaborationsScore =
        month.collaborationsStarted *
        collaborationStartedWeight;

    final filesScore =
        month.filesAdded *
        fileAddedWeight;

    return projectsScore +
        sessionsScore +
        tasksScore +
        collaborationsScore +
        filesScore;
  }

  // ==========================================================
  // NORMALIZAR SCORE
  // ==========================================================
  //
  // Fórmula:
  //
  // score / referência × 100
  //
  // limitado entre:
  //
  // 0 e 100
  //
  // ==========================================================

  double normalizeScore(
    double rawScore,
  ) {
    if (rawScore <=
        0) {
      return 0;
    }

    if (referenceMonthlyScore <=
        0) {
      return 0;
    }

    final normalized =
        (rawScore /
            referenceMonthlyScore) *
        100;

    return normalized.clamp(
      0.0,
      100.0,
    );
  }

  // ==========================================================
  // VARIAÇÃO PERCENTUAL
  // ==========================================================
  //
  // Exemplo:
  //
  // Julho:
  // 73
  //
  // Agosto:
  // 87
  //
  // ((87 - 73) / 73) × 100
  //
  // +19.18%
  //
  // ==========================================================

  double calculateChangePercentage({
    required double previousScore,
    required double currentScore,
  }) {
    // ========================================================
    // MÊS ANTERIOR ZERO
    // ========================================================
    //
    // Evita divisão por zero.
    //
    // Se ambos forem zero:
    //
    // 0%
    //
    // Se anterior for zero e atual tiver produção:
    //
    // consideramos 100%.
    //
    // ========================================================

    if (previousScore <=
        0) {
      if (currentScore <=
          0) {
        return 0;
      }

      return 100;
    }

    final difference =
        currentScore -
        previousScore;

    final change =
        (difference /
            previousScore) *
        100;

    // ========================================================
    // LIMITE DEFENSIVO
    // ========================================================
    //
    // Evita números absurdamente grandes na UI.
    //
    // ========================================================

    return change.clamp(
      -999.0,
      999.0,
    );
  }

  // ==========================================================
  // SCORE DO MÊS ATUAL
  // ==========================================================

  CreativeProductionMonth? currentMonth(
    List<
      CreativeProductionMonth
    >
    months,
  ) {
    if (months.isEmpty) {
      return null;
    }

    final now = DateTime.now();

    for (final month in months) {
      if (month.month.year ==
              now.year &&
          month.month.month ==
              now.month) {
        return month;
      }
    }

    return null;
  }

  // ==========================================================
  // MÊS ANTERIOR
  // ==========================================================

  CreativeProductionMonth? previousMonth(
    List<
      CreativeProductionMonth
    >
    months,
  ) {
    if (months.isEmpty) {
      return null;
    }

    final now = DateTime.now();

    final previousDate = DateTime(
      now.year,
      now.month -
          1,
    );

    for (final month in months) {
      if (month.month.year ==
              previousDate.year &&
          month.month.month ==
              previousDate.month) {
        return month;
      }
    }

    return null;
  }

  // ==========================================================
  // MELHOR MÊS
  // ==========================================================

  CreativeProductionMonth? bestMonth(
    List<
      CreativeProductionMonth
    >
    months,
  ) {
    if (months.isEmpty) {
      return null;
    }

    CreativeProductionMonth best = months.first;

    for (final month in months.skip(
      1,
    )) {
      if (month.score >
          best.score) {
        best = month;
      }
    }

    return best;
  }

  // ==========================================================
  // MÉDIA DE PRODUÇÃO
  // ==========================================================

  double averageScore(
    List<
      CreativeProductionMonth
    >
    months,
  ) {
    if (months.isEmpty) {
      return 0;
    }

    double total = 0;

    for (final month in months) {
      total += month.score;
    }

    return total /
        months.length;
  }

  // ==========================================================
  // TOTAL DE PROJETOS
  // ==========================================================

  int totalProjectsCreated(
    List<
      CreativeProductionMonth
    >
    months,
  ) {
    return months.fold<
      int
    >(
      0,
      (
        total,
        month,
      ) {
        return total +
            month.projectsCreated;
      },
    );
  }

  // ==========================================================
  // TOTAL DE SESSÕES
  // ==========================================================

  int totalCompositionSessions(
    List<
      CreativeProductionMonth
    >
    months,
  ) {
    return months.fold<
      int
    >(
      0,
      (
        total,
        month,
      ) {
        return total +
            month.compositionSessions;
      },
    );
  }

  // ==========================================================
  // TOTAL DE TAREFAS
  // ==========================================================

  int totalTasksCompleted(
    List<
      CreativeProductionMonth
    >
    months,
  ) {
    return months.fold<
      int
    >(
      0,
      (
        total,
        month,
      ) {
        return total +
            month.tasksCompleted;
      },
    );
  }

  // ==========================================================
  // TOTAL DE COLABORAÇÕES
  // ==========================================================

  int totalCollaborationsStarted(
    List<
      CreativeProductionMonth
    >
    months,
  ) {
    return months.fold<
      int
    >(
      0,
      (
        total,
        month,
      ) {
        return total +
            month.collaborationsStarted;
      },
    );
  }

  // ==========================================================
  // TOTAL DE ARQUIVOS
  // ==========================================================

  int totalFilesAdded(
    List<
      CreativeProductionMonth
    >
    months,
  ) {
    return months.fold<
      int
    >(
      0,
      (
        total,
        month,
      ) {
        return total +
            month.filesAdded;
      },
    );
  }

  // ==========================================================
  // TOTAL DE ATIVIDADES
  // ==========================================================

  int totalActivities(
    List<
      CreativeProductionMonth
    >
    months,
  ) {
    return months.fold<
      int
    >(
      0,
      (
        total,
        month,
      ) {
        return total +
            month.totalActivities;
      },
    );
  }

  // ==========================================================
  // FORMATAR VARIAÇÃO
  // ==========================================================
  //
  // Exemplos:
  //
  // +18,4%
  // -7,2%
  // 0,0%
  //
  // ==========================================================

  String formatChangePercentage(
    double value,
  ) {
    final normalized =
        value.abs() <
            0.05
        ? 0.0
        : value;

    final formatted = normalized
        .abs()
        .toStringAsFixed(
          1,
        )
        .replaceAll(
          '.',
          ',',
        );

    if (normalized >
        0) {
      return '+$formatted%';
    }

    if (normalized <
        0) {
      return '-$formatted%';
    }

    return '$formatted%';
  }

  // ==========================================================
  // FORMATAR SCORE
  // ==========================================================
  //
  // 87.4
  //
  // vira:
  //
  // 87
  //
  // ==========================================================

  String formatScore(
    double score,
  ) {
    return score.round().toString();
  }

  // ==========================================================
  // TEXTO DE COMPARAÇÃO
  // ==========================================================
  //
  // Exemplo:
  //
  // ↑ 18,4% comparado a julho
  //
  // ↓ 7,2% comparado a julho
  //
  // → 0,0% comparado a julho
  //
  // ==========================================================

  String buildComparisonText({
    required CreativeProductionMonth current,
    CreativeProductionMonth? previous,
  }) {
    if (previous ==
        null) {
      return 'Primeiro mês registrado';
    }

    final change = current.changeFromPreviousMonth;

    final symbol =
        change >
            0
        ? '↑'
        : change <
              0
        ? '↓'
        : '→';

    final formatted = formatChangePercentage(
      change,
    );

    final monthName = previous.fullMonthLabel.toLowerCase();

    return '$symbol $formatted comparado a $monthName';
  }
}
