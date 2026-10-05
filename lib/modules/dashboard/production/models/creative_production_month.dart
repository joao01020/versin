// ============================================================
// CREATIVE PRODUCTION MONTH
// ============================================================
//
// Representa o resumo de produção criativa de um único mês.
//
// Fonte principal:
//
// RPC:
// get_creative_activity_monthly
//
// Exemplo de resposta:
//
// {
//   "month_start": "2026-08-01",
//   "projects_created": 4,
//   "composition_sessions": 11,
//   "tasks_completed": 18,
//   "collaborations_started": 3,
//   "files_added": 7
// }
//
// O model NÃO:
//
// - consulta Supabase;
// - calcula regra de negócio complexa;
// - conhece widgets;
// - decide pesos de produção.
//
// Ele apenas representa os dados mensais já normalizados.
//
// ============================================================

class CreativeProductionMonth {
  // ==========================================================
  // MÊS
  // ==========================================================

  final DateTime month;

  // ==========================================================
  // MÉTRICAS
  // ==========================================================

  final int projectsCreated;

  final int compositionSessions;

  final int tasksCompleted;

  final int collaborationsStarted;

  final int filesAdded;

  // ==========================================================
  // SCORE
  // ==========================================================
  //
  // Calculado posteriormente pelo CreativeProductionService.
  //
  // ==========================================================

  final double score;

  // ==========================================================
  // VARIAÇÃO MENSAL
  // ==========================================================
  //
  // Percentual de diferença comparado ao mês anterior.
  //
  // Exemplo:
  //
  // Julho:
  // 73 pontos
  //
  // Agosto:
  // 87 pontos
  //
  // changeFromPreviousMonth:
  // +19.17
  //
  // ==========================================================

  final double changeFromPreviousMonth;

  // ==========================================================
  // CONSTRUCTOR
  // ==========================================================

  const CreativeProductionMonth({
    required this.month,
    required this.projectsCreated,
    required this.compositionSessions,
    required this.tasksCompleted,
    required this.collaborationsStarted,
    required this.filesAdded,
    required this.score,
    required this.changeFromPreviousMonth,
  });

  // ==========================================================
  // FACTORY — MAP
  // ==========================================================
  //
  // Converte diretamente a resposta da RPC do Supabase.
  //
  // O score começa em zero porque será calculado pelo service.
  //
  // ==========================================================

  factory CreativeProductionMonth.fromMap(
    Map<
      String,
      dynamic
    >
    map,
  ) {
    return CreativeProductionMonth(
      month: _readMonth(
        map['month_start'],
      ),

      projectsCreated: _readInt(
        map['projects_created'],
      ),

      compositionSessions: _readInt(
        map['composition_sessions'],
      ),

      tasksCompleted: _readInt(
        map['tasks_completed'],
      ),

      collaborationsStarted: _readInt(
        map['collaborations_started'],
      ),

      filesAdded: _readInt(
        map['files_added'],
      ),

      score: _readDouble(
        map['score'],
      ),

      changeFromPreviousMonth: _readDouble(
        map['change_from_previous_month'],
      ),
    );
  }

  // ==========================================================
  // EMPTY
  // ==========================================================

  factory CreativeProductionMonth.empty({
    required DateTime month,
  }) {
    return CreativeProductionMonth(
      month: DateTime(
        month.year,
        month.month,
      ),
      projectsCreated: 0,
      compositionSessions: 0,
      tasksCompleted: 0,
      collaborationsStarted: 0,
      filesAdded: 0,
      score: 0,
      changeFromPreviousMonth: 0,
    );
  }

  // ==========================================================
  // COPY WITH
  // ==========================================================

  CreativeProductionMonth copyWith({
    DateTime? month,
    int? projectsCreated,
    int? compositionSessions,
    int? tasksCompleted,
    int? collaborationsStarted,
    int? filesAdded,
    double? score,
    double? changeFromPreviousMonth,
  }) {
    return CreativeProductionMonth(
      month:
          month ??
          this.month,

      projectsCreated:
          projectsCreated ??
          this.projectsCreated,

      compositionSessions:
          compositionSessions ??
          this.compositionSessions,

      tasksCompleted:
          tasksCompleted ??
          this.tasksCompleted,

      collaborationsStarted:
          collaborationsStarted ??
          this.collaborationsStarted,

      filesAdded:
          filesAdded ??
          this.filesAdded,

      score:
          score ??
          this.score,

      changeFromPreviousMonth:
          changeFromPreviousMonth ??
          this.changeFromPreviousMonth,
    );
  }

  // ==========================================================
  // TOTAL DE EVENTOS
  // ==========================================================
  //
  // NÃO representa score.
  //
  // Apenas soma a quantidade bruta de atividades do mês.
  //
  // ==========================================================

  int get totalActivities {
    return projectsCreated +
        compositionSessions +
        tasksCompleted +
        collaborationsStarted +
        filesAdded;
  }

  // ==========================================================
  // TEM ATIVIDADE
  // ==========================================================

  bool get hasActivity {
    return totalActivities >
        0;
  }

  // ==========================================================
  // SEM ATIVIDADE
  // ==========================================================

  bool get isEmpty {
    return !hasActivity;
  }

  // ==========================================================
  // VARIAÇÃO
  // ==========================================================

  bool get hasPositiveChange {
    return changeFromPreviousMonth >
        0;
  }

  bool get hasNegativeChange {
    return changeFromPreviousMonth <
        0;
  }

  bool get hasNeutralChange {
    return changeFromPreviousMonth ==
        0;
  }

  // ==========================================================
  // IDENTIDADE DO MÊS
  // ==========================================================
  //
  // Útil para comparar dois registros sem considerar dia/hora.
  //
  // ==========================================================

  String get monthKey {
    final normalizedMonth = month.month.toString().padLeft(
      2,
      '0',
    );

    return '${month.year}-$normalizedMonth';
  }

  // ==========================================================
  // LABEL CURTA
  // ==========================================================
  //
  // Não usamos intl aqui para manter o model independente de UI.
  //
  // ==========================================================

  String get shortMonthLabel {
    const months =
        <
          String
        >[
          'Jan',
          'Fev',
          'Mar',
          'Abr',
          'Mai',
          'Jun',
          'Jul',
          'Ago',
          'Set',
          'Out',
          'Nov',
          'Dez',
        ];

    final index =
        month.month -
        1;

    if (index <
            0 ||
        index >=
            months.length) {
      return '';
    }

    return months[index];
  }

  // ==========================================================
  // LABEL COMPLETA
  // ==========================================================

  String get fullMonthLabel {
    const months =
        <
          String
        >[
          'Janeiro',
          'Fevereiro',
          'Março',
          'Abril',
          'Maio',
          'Junho',
          'Julho',
          'Agosto',
          'Setembro',
          'Outubro',
          'Novembro',
          'Dezembro',
        ];

    final index =
        month.month -
        1;

    if (index <
            0 ||
        index >=
            months.length) {
      return '';
    }

    return months[index];
  }

  // ==========================================================
  // TO MAP
  // ==========================================================

  Map<
    String,
    dynamic
  >
  toMap() {
    return <
      String,
      dynamic
    >{
      'month_start': DateTime(
        month.year,
        month.month,
      ).toIso8601String(),

      'projects_created': projectsCreated,

      'composition_sessions': compositionSessions,

      'tasks_completed': tasksCompleted,

      'collaborations_started': collaborationsStarted,

      'files_added': filesAdded,

      'score': score,

      'change_from_previous_month': changeFromPreviousMonth,
    };
  }

  // ==========================================================
  // READ MONTH
  // ==========================================================

  static DateTime _readMonth(
    dynamic value,
  ) {
    if (value
        is DateTime) {
      return DateTime(
        value.year,
        value.month,
      );
    }

    final parsed = DateTime.tryParse(
      value?.toString() ??
          '',
    );

    if (parsed ==
        null) {
      return DateTime(
        DateTime.now().year,
        DateTime.now().month,
      );
    }

    return DateTime(
      parsed.year,
      parsed.month,
    );
  }

  // ==========================================================
  // READ INT
  // ==========================================================

  static int _readInt(
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
      value?.toString().trim() ??
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

  // ==========================================================
  // READ DOUBLE
  // ==========================================================

  static double _readDouble(
    dynamic value,
  ) {
    if (value
        is double) {
      return value;
    }

    if (value
        is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString().trim() ??
              '',
        ) ??
        0;
  }

  // ==========================================================
  // EQUALITY
  // ==========================================================

  @override
  bool operator ==(
    Object other,
  ) {
    if (identical(
      this,
      other,
    )) {
      return true;
    }

    return other
            is CreativeProductionMonth &&
        other.month.year ==
            month.year &&
        other.month.month ==
            month.month &&
        other.projectsCreated ==
            projectsCreated &&
        other.compositionSessions ==
            compositionSessions &&
        other.tasksCompleted ==
            tasksCompleted &&
        other.collaborationsStarted ==
            collaborationsStarted &&
        other.filesAdded ==
            filesAdded &&
        other.score ==
            score &&
        other.changeFromPreviousMonth ==
            changeFromPreviousMonth;
  }

  // ==========================================================
  // HASH CODE
  // ==========================================================

  @override
  int get hashCode {
    return Object.hash(
      month.year,
      month.month,
      projectsCreated,
      compositionSessions,
      tasksCompleted,
      collaborationsStarted,
      filesAdded,
      score,
      changeFromPreviousMonth,
    );
  }

  // ==========================================================
  // TO STRING
  // ==========================================================

  @override
  String toString() {
    return 'CreativeProductionMonth('
        'month: $monthKey, '
        'projectsCreated: $projectsCreated, '
        'compositionSessions: $compositionSessions, '
        'tasksCompleted: $tasksCompleted, '
        'collaborationsStarted: $collaborationsStarted, '
        'filesAdded: $filesAdded, '
        'score: $score, '
        'changeFromPreviousMonth: $changeFromPreviousMonth'
        ')';
  }
}
