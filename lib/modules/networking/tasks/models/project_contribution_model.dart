// ============================================================
// PROJECT CONTRIBUTION STATUS
// ============================================================
//
// Estado atual de uma contribuição dentro do projeto.
//
// FLUXO PRINCIPAL:
//
// DRAFT
//   ↓
// WAITING APPROVAL
//   ↓
// READY / BLOCKED
//   ↓
// IN PROGRESS
//   ↓
// DELIVERED
//   ↓
// VALIDATED
//
// ============================================================

enum ProjectContributionStatus {
  draft,
  waitingApproval,
  blocked,
  ready,
  inProgress,
  delivered,
  validated,
}

// ============================================================
// PROJECT CONTRIBUTION MODEL
// ============================================================
//
// Representa o compromisso de UM participante dentro do projeto.
//
// Exemplos:
//
// João
// Produtor
// "Mixagem e masterização"
//
// Ana
// Artista
// "Composição e gravação dos vocais"
//
// Lucas
// Beatmaker
// "Produção do instrumental e stems"
//
// IMPORTANTE:
//
// O membro existir no projeto NÃO significa que existe uma
// contribuição.
//
// Uma contribuição só passa a existir depois que o usuário
// define o que pretende realizar.
//
// ============================================================

class ProjectContributionModel {
  // ============================================================
  // IDENTIDADE
  // ============================================================

  final String id;

  final String projectId;

  final String userId;

  // ============================================================
  // CONTRIBUIÇÃO
  // ============================================================

  final String title;

  final String description;

  // ============================================================
  // ROLE SNAPSHOT
  // ============================================================
  //
  // Função profissional preservada no momento em que a
  // contribuição é formalizada.
  //
  // Exemplo:
  //
  // "Produtor"
  //
  // Mesmo que futuramente o usuário altere seu perfil para
  // "Compositor", o histórico deste projeto continua mostrando
  // a função utilizada nesta colaboração.
  //
  // ============================================================

  final String? roleSnapshot;

  // ============================================================
  // DEPENDENCY
  // ============================================================
  //
  // Permite construir:
  //
  // BEAT
  //   ↓
  // VOCAL
  //   ↓
  // MIX
  //   ↓
  // MASTER
  //
  // null significa que não depende de outra contribuição.
  //
  // ============================================================

  final String? dependencyContributionId;

  // ============================================================
  // STATUS
  // ============================================================

  final ProjectContributionStatus status;

  // ============================================================
  // VERSION
  // ============================================================
  //
  // Alterar uma proposta depois de enviada para aprovação
  // deverá criar uma nova versão lógica.
  //
  // Aprovações sempre apontarão para uma versão específica.
  //
  // ============================================================

  final int version;

  // ============================================================
  // DEADLINE
  // ============================================================

  final DateTime? dueAt;

  // ============================================================
  // CALENDAR
  // ============================================================

  final String? calendarEventId;

  // ============================================================
  // LOCK
  // ============================================================
  //
  // Depois da aprovação coletiva, a contribuição pode ser
  // bloqueada para edição.
  //
  // Alterações posteriores devem gerar nova versão/proposta.
  //
  // ============================================================

  final DateTime? lockedAt;

  // ============================================================
  // TIMESTAMPS
  // ============================================================

  final DateTime createdAt;

  final DateTime updatedAt;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  const ProjectContributionModel({
    required this.id,
    required this.projectId,
    required this.userId,
    required this.title,
    required this.description,
    required this.status,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
    this.roleSnapshot,
    this.dependencyContributionId,
    this.dueAt,
    this.calendarEventId,
    this.lockedAt,
  });

  // ============================================================
  // HELPERS
  // ============================================================

  bool get isDraft {
    return status ==
        ProjectContributionStatus.draft;
  }

  bool get isWaitingApproval {
    return status ==
        ProjectContributionStatus.waitingApproval;
  }

  bool get isBlocked {
    return status ==
        ProjectContributionStatus.blocked;
  }

  bool get isReady {
    return status ==
        ProjectContributionStatus.ready;
  }

  bool get isInProgress {
    return status ==
        ProjectContributionStatus.inProgress;
  }

  bool get isDelivered {
    return status ==
        ProjectContributionStatus.delivered;
  }

  bool get isValidated {
    return status ==
        ProjectContributionStatus.validated;
  }

  bool get isLocked {
    return lockedAt !=
        null;
  }

  bool get hasDependency {
    return dependencyContributionId?.trim().isNotEmpty ==
        true;
  }

  bool get hasDeadline {
    return dueAt !=
        null;
  }

  bool get hasCalendarEvent {
    return calendarEventId?.trim().isNotEmpty ==
        true;
  }

  bool get hasRoleSnapshot {
    return roleSnapshot?.trim().isNotEmpty ==
        true;
  }

  bool get hasTitle {
    return title.trim().isNotEmpty;
  }

  bool get hasDescription {
    return description.trim().isNotEmpty;
  }

  bool get canBeEdited {
    return !isLocked &&
        (isDraft ||
            isWaitingApproval);
  }

  bool get canStart {
    return isReady;
  }

  bool get canUploadDelivery {
    return isInProgress;
  }

  bool get canBeValidated {
    return isDelivered;
  }

  // ============================================================
  // STATUS DATABASE VALUE
  // ============================================================

  String get statusDatabaseValue {
    switch (status) {
      case ProjectContributionStatus.draft:
        return 'draft';

      case ProjectContributionStatus.waitingApproval:
        return 'waiting_approval';

      case ProjectContributionStatus.blocked:
        return 'blocked';

      case ProjectContributionStatus.ready:
        return 'ready';

      case ProjectContributionStatus.inProgress:
        return 'in_progress';

      case ProjectContributionStatus.delivered:
        return 'delivered';

      case ProjectContributionStatus.validated:
        return 'validated';
    }
  }

  // ============================================================
  // STATUS FROM DATABASE
  // ============================================================

  static ProjectContributionStatus statusFromDatabase(
    String? value,
  ) {
    switch (value?.trim().toLowerCase()) {
      case 'waiting_approval':
        return ProjectContributionStatus.waitingApproval;

      case 'blocked':
        return ProjectContributionStatus.blocked;

      case 'ready':
        return ProjectContributionStatus.ready;

      case 'in_progress':
        return ProjectContributionStatus.inProgress;

      case 'delivered':
        return ProjectContributionStatus.delivered;

      case 'validated':
        return ProjectContributionStatus.validated;

      case 'draft':
      default:
        return ProjectContributionStatus.draft;
    }
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  ProjectContributionModel copyWith({
    String? id,
    String? projectId,
    String? userId,
    String? title,
    String? description,
    String? roleSnapshot,
    String? dependencyContributionId,
    ProjectContributionStatus? status,
    int? version,
    DateTime? dueAt,
    String? calendarEventId,
    DateTime? lockedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearRoleSnapshot = false,
    bool clearDependency = false,
    bool clearDueAt = false,
    bool clearCalendarEventId = false,
    bool clearLockedAt = false,
  }) {
    return ProjectContributionModel(
      id:
          id ??
          this.id,
      projectId:
          projectId ??
          this.projectId,
      userId:
          userId ??
          this.userId,
      title:
          title ??
          this.title,
      description:
          description ??
          this.description,
      roleSnapshot: clearRoleSnapshot
          ? null
          : roleSnapshot ??
                this.roleSnapshot,
      dependencyContributionId: clearDependency
          ? null
          : dependencyContributionId ??
                this.dependencyContributionId,
      status:
          status ??
          this.status,
      version:
          version ??
          this.version,
      dueAt: clearDueAt
          ? null
          : dueAt ??
                this.dueAt,
      calendarEventId: clearCalendarEventId
          ? null
          : calendarEventId ??
                this.calendarEventId,
      lockedAt: clearLockedAt
          ? null
          : lockedAt ??
                this.lockedAt,
      createdAt:
          createdAt ??
          this.createdAt,
      updatedAt:
          updatedAt ??
          this.updatedAt,
    );
  }

  // ============================================================
  // EQUALITY
  // ============================================================

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
            is ProjectContributionModel &&
        other.id ==
            id &&
        other.version ==
            version;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      version,
    );
  }

  // ============================================================
  // TO STRING
  // ============================================================

  @override
  String toString() {
    return 'ProjectContributionModel('
        'id: $id, '
        'projectId: $projectId, '
        'userId: $userId, '
        'status: $statusDatabaseValue, '
        'version: $version'
        ')';
  }
}
