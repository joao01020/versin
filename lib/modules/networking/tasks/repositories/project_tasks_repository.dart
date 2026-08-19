import '../models/contribution_approval_model.dart';
import '../models/contribution_delivery_model.dart';
import '../models/project_contribution_model.dart';
import '../models/project_record_event_model.dart';
import '../models/project_task_member_model.dart';

// ============================================================
// PROJECT TASKS REPOSITORY
// ============================================================
//
// Contrato principal do módulo de produção / tarefas.
//
// O Controller conhece apenas este contrato.
//
// A implementação poderá usar:
//
// - Supabase Database;
// - Supabase Storage;
// - Realtime;
// - cache;
//
// sem alterar o Controller.
//
// RESPONSABILIDADES:
//
// - carregar membros;
// - carregar contribuições;
// - criar/editar contribuições;
// - registrar aprovações;
// - carregar entregas;
// - registrar entregas;
// - validar entregas;
// - carregar Versin Record;
// - observar alterações em realtime.
//
// ============================================================

abstract class ProjectTasksRepository {
  // ============================================================
  // PROJECT MEMBERS
  // ============================================================
  //
  // Retorna os participantes reais do projeto.
  //
  // Deve resolver:
  //
  // - userId;
  // - nome;
  // - username;
  // - avatar;
  // - função profissional usada no Match;
  // - fundador ou membro.
  //
  // IMPORTANTE:
  //
  // Retornar um membro NÃO significa criar automaticamente uma
  // contribuição para ele.
  //
  // ============================================================

  Future<
    List<
      ProjectTaskMemberModel
    >
  >
  getProjectMembers({
    required String projectId,
  });

  // ============================================================
  // WATCH PROJECT MEMBERS
  // ============================================================
  //
  // Realtime dos participantes.
  //
  // Pode ser usado quando:
  //
  // - alguém entra no projeto;
  // - alguém sai;
  // - founders muda;
  // - membros são atualizados.
  //
  // ============================================================

  Stream<
    List<
      ProjectTaskMemberModel
    >
  >
  watchProjectMembers({
    required String projectId,
  });

  // ============================================================
  // EXISTS PROJECT
  // ============================================================

  Future<
    bool
  >
  projectExists({
    required String projectId,
  });

  // ============================================================
  // IS MEMBER
  // ============================================================

  Future<
    bool
  >
  isProjectMember({
    required String projectId,
    required String userId,
  });

  // ============================================================
  // IS FOUNDER
  // ============================================================

  Future<
    bool
  >
  isProjectFounder({
    required String projectId,
    required String userId,
  });

  // ============================================================
  // CONTRIBUTIONS
  // ============================================================

  Future<
    List<
      ProjectContributionModel
    >
  >
  getContributions({
    required String projectId,
  });

  // ============================================================
  // GET USER CONTRIBUTION
  // ============================================================

  Future<
    ProjectContributionModel?
  >
  getUserContribution({
    required String projectId,
    required String userId,
  });

  // ============================================================
  // CREATE CONTRIBUTION
  // ============================================================
  //
  // Um membro define sua própria responsabilidade.
  //
  // Exemplo:
  //
  // title:
  // Mix + Master
  //
  // description:
  // Mixagem, tratamento vocal e masterização.
  //
  // ============================================================

  Future<
    ProjectContributionModel
  >
  createContribution({
    required String projectId,
    required String userId,
    required String title,
    required String description,
    required String roleSnapshot,
    String? dependencyContributionId,
    DateTime? dueAt,
  });

  // ============================================================
  // UPDATE CONTRIBUTION
  // ============================================================
  //
  // Deve ser permitido somente enquanto a contribuição ainda
  // estiver editável.
  //
  // Caso já tenha sido aprovada/travada, a regra de negócio deve
  // criar uma nova versão em vez de sobrescrever silenciosamente.
  //
  // ============================================================

  Future<
    ProjectContributionModel
  >
  updateContribution({
    required ProjectContributionModel contribution,
  });

  // ============================================================
  // SUBMIT CONTRIBUTION FOR APPROVAL
  // ============================================================
  //
  // draft
  //   ↓
  // waiting_approval
  //
  // ============================================================

  Future<
    ProjectContributionModel
  >
  submitContributionForApproval({
    required String contributionId,
  });

  // ============================================================
  // START CONTRIBUTION
  // ============================================================
  //
  // ready
  //   ↓
  // in_progress
  //
  // ============================================================

  Future<
    ProjectContributionModel
  >
  startContribution({
    required String contributionId,
  });

  // ============================================================
  // WATCH CONTRIBUTIONS
  // ============================================================

  Stream<
    List<
      ProjectContributionModel
    >
  >
  watchContributions({
    required String projectId,
  });

  // ============================================================
  // CONTRIBUTION APPROVALS
  // ============================================================

  Future<
    List<
      ContributionApprovalModel
    >
  >
  getContributionApprovals({
    required String projectId,
  });

  // ============================================================
  // APPROVALS BY CONTRIBUTION
  // ============================================================

  Future<
    List<
      ContributionApprovalModel
    >
  >
  getApprovalsForContribution({
    required String contributionId,
    required int contributionVersion,
  });

  // ============================================================
  // HAS USER APPROVED
  // ============================================================

  Future<
    bool
  >
  hasUserApprovedContribution({
    required String contributionId,
    required String userId,
    required int contributionVersion,
  });

  // ============================================================
  // APPROVE CONTRIBUTION
  // ============================================================
  //
  // Cada usuário só pode aprovar uma vez por:
  //
  // contribution_id
  // +
  // user_id
  // +
  // contribution_version
  //
  // ============================================================

  Future<
    ContributionApprovalModel
  >
  approveContribution({
    required String contributionId,
    required String userId,
    required int contributionVersion,
  });

  // ============================================================
  // WATCH APPROVALS
  // ============================================================

  Stream<
    List<
      ContributionApprovalModel
    >
  >
  watchContributionApprovals({
    required String projectId,
  });

  // ============================================================
  // DELIVERIES
  // ============================================================

  Future<
    List<
      ContributionDeliveryModel
    >
  >
  getDeliveries({
    required String projectId,
  });

  // ============================================================
  // DELIVERIES BY CONTRIBUTION
  // ============================================================

  Future<
    List<
      ContributionDeliveryModel
    >
  >
  getDeliveriesForContribution({
    required String contributionId,
  });

  // ============================================================
  // LATEST DELIVERY
  // ============================================================

  Future<
    ContributionDeliveryModel?
  >
  getLatestDelivery({
    required String contributionId,
  });

  // ============================================================
  // CREATE DELIVERY
  // ============================================================
  //
  // O arquivo já deve ter sido enviado pelo
  // ContributionUploadService.
  //
  // Aqui registramos os metadados no banco.
  //
  // ============================================================

  Future<
    ContributionDeliveryModel
  >
  createDelivery({
    required String contributionId,
    required String uploadedBy,
    required String fileName,
    required String storagePath,
    required int version,
    required int fileSize,
    required String sha256,
    String? mimeType,
  });

  // ============================================================
  // MARK CONTRIBUTION DELIVERED
  // ============================================================
  //
  // in_progress
  //   ↓
  // delivered
  //
  // ============================================================

  Future<
    ProjectContributionModel
  >
  markContributionDelivered({
    required String contributionId,
  });

  // ============================================================
  // VALIDATE DELIVERY
  // ============================================================
  //
  // Depois que a regra coletiva definir que a entrega foi
  // aprovada:
  //
  // delivery
  // submitted / validating
  //   ↓
  // validated
  //
  // contribution
  // delivered
  //   ↓
  // validated
  //
  // ============================================================

  Future<
    ContributionDeliveryModel
  >
  validateDelivery({
    required String deliveryId,
  });

  // ============================================================
  // REJECT DELIVERY
  // ============================================================
  //
  // Não apaga o arquivo.
  //
  // Apenas marca a versão como rejeitada para que o responsável
  // envie uma nova.
  //
  // ============================================================

  Future<
    ContributionDeliveryModel
  >
  rejectDelivery({
    required String deliveryId,
  });

  // ============================================================
  // WATCH DELIVERIES
  // ============================================================

  Stream<
    List<
      ContributionDeliveryModel
    >
  >
  watchDeliveries({
    required String projectId,
  });

  // ============================================================
  // PROJECT RECORD
  // ============================================================

  Future<
    List<
      ProjectRecordEventModel
    >
  >
  getProjectRecordEvents({
    required String projectId,
  });

  // ============================================================
  // LATEST RECORD EVENT
  // ============================================================

  Future<
    ProjectRecordEventModel?
  >
  getLatestProjectRecordEvent({
    required String projectId,
  });

  // ============================================================
  // CREATE RECORD EVENT
  // ============================================================
  //
  // Cria um evento no Versin Record.
  //
  // Exemplo:
  //
  // contribution.created
  // contribution.approved
  // delivery.submitted
  // delivery.validated
  //
  // IMPORTANTE:
  //
  // payloadHash / previousEventHash / eventHash devem vir do
  // ContributionIntegrityService.
  //
  // ============================================================

  Future<
    ProjectRecordEventModel
  >
  createProjectRecordEvent({
    required String projectId,
    required ProjectRecordEventType eventType,
    required Map<
      String,
      dynamic
    >
    payload,
    required DateTime createdAt,
    String? actorUserId,
    String? entityType,
    String? entityId,
    String? payloadHash,
    String? previousEventHash,
    String? eventHash,
  });

  // ============================================================
  // WATCH PROJECT RECORD
  // ============================================================

  Stream<
    List<
      ProjectRecordEventModel
    >
  >
  watchProjectRecordEvents({
    required String projectId,
  });

  // ============================================================
  // DEADLINE / CALENDAR
  // ============================================================
  //
  // Liga uma contribuição a um evento do calendário interno.
  //
  // A criação real do compromisso será feita pelo módulo de
  // calendário.
  //
  // ============================================================

  Future<
    ProjectContributionModel
  >
  attachCalendarEvent({
    required String contributionId,
    required String calendarEventId,
  });

  // ============================================================
  // REMOVE CALENDAR EVENT REFERENCE
  // ============================================================

  Future<
    ProjectContributionModel
  >
  detachCalendarEvent({
    required String contributionId,
  });
}
