import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/services/royalty_integrity_service.dart';
import '../models/royalty_agreement_model.dart';
import '../models/royalty_approval_model.dart';
import '../models/royalty_event_model.dart';
import '../models/royalty_member_model.dart';
import '../models/royalty_share_model.dart';
import '../repositories/royalties_repository.dart';

// ============================================================
// ROYALTIES CONTROLLER
// ============================================================
//
// Controller principal do módulo de royalties.
//
// RESPONSABILIDADES:
//
// - carregar membros;
// - carregar acordos;
// - carregar shares;
// - carregar aprovações;
// - carregar eventos;
// - controlar estado;
// - controlar Realtime;
// - propor nova divisão;
// - aprovar acordo;
// - detectar quando a última aprovação fechou o acordo;
// - expor progresso;
// - verificar integridade;
//
// NÃO:
//
// - acessa Supabase diretamente;
// - faz INSERT / UPDATE / DELETE;
// - conhece RLS;
// - calcula o hash oficial do acordo;
// - confirma acordo manualmente.
//
// REGRA PRINCIPAL:
//
// usuário aprova
//      ↓
// RPC
//      ↓
// último participante?
//      ├─ não → continua proposed
//      └─ sim → banco calcula SHA-256
//                ↓
//              confirmed
//                ↓
//              evento final
//
// ============================================================

class RoyaltiesController
    extends
        ChangeNotifier {
  // ============================================================
  // DEPENDENCIES
  // ============================================================

  final RoyaltiesRepository repository;

  final RoyaltyIntegrityService integrityService;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  RoyaltiesController({
    required this.repository,
    RoyaltyIntegrityService? integrityService,
  }) : integrityService =
           integrityService ??
           const RoyaltyIntegrityService();

  // ============================================================
  // PROJECT
  // ============================================================

  String? _projectId;

  String? get projectId => _projectId;

  bool get hasProject {
    return _projectId?.trim().isNotEmpty ==
        true;
  }

  // ============================================================
  // CURRENT USER
  // ============================================================

  String? _currentUserId;

  String? get currentUserId => _currentUserId;

  bool get hasCurrentUser {
    return _currentUserId?.trim().isNotEmpty ==
        true;
  }

  // ============================================================
  // MEMBERS
  // ============================================================

  List<
    RoyaltyMemberModel
  >
  _members =
      const <
        RoyaltyMemberModel
      >[];

  List<
    RoyaltyMemberModel
  >
  get members {
    return List.unmodifiable(
      _members,
    );
  }

  int get memberCount => _members.length;

  bool get hasMembers => _members.isNotEmpty;

  // ============================================================
  // AGREEMENTS
  // ============================================================

  List<
    RoyaltyAgreementModel
  >
  _agreements =
      const <
        RoyaltyAgreementModel
      >[];

  List<
    RoyaltyAgreementModel
  >
  get agreements {
    return List.unmodifiable(
      _agreements,
    );
  }

  bool get hasAgreements => _agreements.isNotEmpty;

  // ============================================================
  // CURRENT AGREEMENT
  // ============================================================

  RoyaltyAgreementModel? _currentAgreement;

  RoyaltyAgreementModel? get currentAgreement => _currentAgreement;

  bool get hasCurrentAgreement {
    return _currentAgreement !=
        null;
  }

  // ============================================================
  // SHARES
  // ============================================================

  List<
    RoyaltyShareModel
  >
  _shares =
      const <
        RoyaltyShareModel
      >[];

  List<
    RoyaltyShareModel
  >
  get shares {
    return List.unmodifiable(
      _shares,
    );
  }

  bool get hasShares => _shares.isNotEmpty;

  // ============================================================
  // APPROVALS
  // ============================================================

  List<
    RoyaltyApprovalModel
  >
  _approvals =
      const <
        RoyaltyApprovalModel
      >[];

  List<
    RoyaltyApprovalModel
  >
  get approvals {
    return List.unmodifiable(
      _approvals,
    );
  }

  int get approvedCount => _approvals.length;

  // ============================================================
  // EVENTS
  // ============================================================

  List<
    RoyaltyEventModel
  >
  _events =
      const <
        RoyaltyEventModel
      >[];

  List<
    RoyaltyEventModel
  >
  get events {
    return List.unmodifiable(
      _events,
    );
  }

  int get eventCount => _events.length;

  bool get hasEvents => _events.isNotEmpty;

  // ============================================================
  // LOADING
  // ============================================================

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  // ============================================================
  // ACTION LOADING
  // ============================================================

  bool _isSubmittingProposal = false;

  bool get isSubmittingProposal => _isSubmittingProposal;

  bool _isApproving = false;

  bool get isApproving => _isApproving;

  bool get isPerformingAction {
    return _isSubmittingProposal ||
        _isApproving;
  }

  // ============================================================
  // INITIALIZED
  // ============================================================

  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  // ============================================================
  // ERROR
  // ============================================================

  String? _errorMessage;

  String? get errorMessage => _errorMessage;

  bool get hasError {
    return _errorMessage?.trim().isNotEmpty ==
        true;
  }

  // ============================================================
  // LAST APPROVAL RESULT
  // ============================================================
  //
  // Útil para a UI saber se:
  //
  // - ainda faltam pessoas;
  // - esta aprovação foi a última;
  // - o acordo foi finalizado pelo banco.
  //
  // ============================================================

  RoyaltyApprovalResult? _lastApprovalResult;

  RoyaltyApprovalResult? get lastApprovalResult => _lastApprovalResult;

  // ============================================================
  // REALTIME SUBSCRIPTIONS
  // ============================================================

  StreamSubscription<
    List<
      RoyaltyAgreementModel
    >
  >?
  _agreementsSubscription;

  StreamSubscription<
    List<
      RoyaltyShareModel
    >
  >?
  _sharesSubscription;

  StreamSubscription<
    List<
      RoyaltyApprovalModel
    >
  >?
  _approvalsSubscription;

  StreamSubscription<
    List<
      RoyaltyEventModel
    >
  >?
  _eventsSubscription;

  // ============================================================
  // CURRENT MEMBER
  // ============================================================

  RoyaltyMemberModel? get currentMember {
    final userId = _currentUserId?.trim();

    if (userId ==
            null ||
        userId.isEmpty) {
      return null;
    }

    return findMember(
      userId,
    );
  }

  // ============================================================
  // CURRENT USER MEMBER
  // ============================================================

  bool get currentUserIsMember {
    return currentMember !=
        null;
  }

  // ============================================================
  // CURRENT USER FOUNDER
  // ============================================================

  bool get currentUserIsFounder {
    return currentMember?.isFounder ??
        false;
  }

  // ============================================================
  // TOTAL
  // ============================================================

  double get totalPercentage {
    return _shares.fold<
      double
    >(
      0,
      (
        total,
        share,
      ) {
        return total +
            share.percentage;
      },
    );
  }

  // ============================================================
  // VALID TOTAL
  // ============================================================

  bool get hasCorrectTotal {
    return (totalPercentage -
                100)
            .abs() <
        0.0001;
  }

  // ============================================================
  // APPROVAL PROGRESS
  // ============================================================

  double get approvalProgress {
    if (_members.isEmpty) {
      return 0;
    }

    return (approvedCount /
            _members.length)
        .clamp(
          0.0,
          1.0,
        );
  }

  // ============================================================
  // ALL APPROVED
  // ============================================================

  bool get allApproved {
    final agreement = _currentAgreement;

    if (agreement ==
            null ||
        _members.isEmpty) {
      return false;
    }

    return _members.every(
      (
        member,
      ) {
        return hasMemberApproved(
          member.userId,
        );
      },
    );
  }

  // ============================================================
  // CURRENT USER APPROVED
  // ============================================================

  bool get currentUserApproved {
    final userId = _currentUserId?.trim();

    if (userId ==
            null ||
        userId.isEmpty) {
      return false;
    }

    return hasMemberApproved(
      userId,
    );
  }

  // ============================================================
  // STATUS
  // ============================================================

  bool get isLocked {
    return _currentAgreement?.isConfirmed ??
        false;
  }

  bool get isConfirmed {
    return _currentAgreement?.isConfirmed ??
        false;
  }

  bool get isProposed {
    return _currentAgreement?.isProposed ??
        false;
  }

  bool get isDraft {
    return _currentAgreement?.isDraft ??
        false;
  }

  // ============================================================
  // CURRENT VERSION
  // ============================================================

  int get currentVersion {
    return _currentAgreement?.version ??
        0;
  }

  // ============================================================
  // NEXT VERSION
  // ============================================================

  int get nextVersion {
    if (_agreements.isEmpty) {
      return 1;
    }

    var highest = 0;

    for (final agreement in _agreements) {
      if (agreement.version >
          highest) {
        highest = agreement.version;
      }
    }

    return highest +
        1;
  }

  // ============================================================
  // INTEGRITY HASH
  // ============================================================

  String? get integrityHash {
    return _currentAgreement?.integrityHash;
  }

  bool get hasIntegrityHash {
    return integrityHash?.trim().isNotEmpty ==
        true;
  }

  String get shortIntegrityHash {
    return integrityService.shortHash(
      integrityHash,
    );
  }

  // ============================================================
  // CAN APPROVE
  // ============================================================
  //
  // A única ação de consenso do usuário é:
  //
  // "Confirmar minha parte"
  //
  // Não existe mais:
  //
  // "Confirmar acordo"
  //
  // ============================================================

  bool get canApprove {
    final agreement = _currentAgreement;

    if (agreement ==
            null ||
        !agreement.isProposed ||
        !currentUserIsMember ||
        currentUserApproved ||
        !hasCorrectTotal ||
        _isApproving) {
      return false;
    }

    return true;
  }

  // ============================================================
  // CAN CREATE PROPOSAL
  // ============================================================

  bool get canCreateProposal {
    return currentUserIsMember &&
        _members.isNotEmpty &&
        !_isSubmittingProposal;
  }

  // ============================================================
  // APPROVAL WAITING COUNT
  // ============================================================

  int get pendingApprovalCount {
    final pending =
        memberCount -
        approvedCount;

    return pending <
            0
        ? 0
        : pending;
  }

  // ============================================================
  // LAST APPROVAL CLOSED AGREEMENT
  // ============================================================

  bool get lastApprovalCompletedAgreement {
    return _lastApprovalResult?.completed ??
        false;
  }

  // ============================================================
  // LOAD
  // ============================================================

  Future<
    void
  >
  load({
    required String projectId,
    required String currentUserId,
  }) async {
    final normalizedProjectId = projectId.trim();

    final normalizedUserId = currentUserId.trim();

    // ==========================================================
    // VALIDATE
    // ==========================================================

    if (normalizedProjectId.isEmpty) {
      _setError(
        'ID do projeto inválido.',
      );

      return;
    }

    if (normalizedUserId.isEmpty) {
      _setError(
        'Usuário não identificado.',
      );

      return;
    }

    // ==========================================================
    // STATE
    // ==========================================================

    _projectId = normalizedProjectId;

    _currentUserId = normalizedUserId;

    _isLoading = true;

    _isInitialized = false;

    _errorMessage = null;

    _lastApprovalResult = null;

    _clearData();

    notifyListeners();

    try {
      // ========================================================
      // PROJECT
      // ========================================================

      final exists = await repository.projectExists(
        projectId: normalizedProjectId,
      );

      if (!exists) {
        throw StateError(
          'Projeto não encontrado.',
        );
      }

      // ========================================================
      // MEMBERSHIP
      // ========================================================

      final isMember = await repository.isProjectMember(
        projectId: normalizedProjectId,
        userId: normalizedUserId,
      );

      if (!isMember) {
        throw StateError(
          'Você não faz parte deste projeto.',
        );
      }

      // ========================================================
      // LOAD DATA
      // ========================================================

      await _loadData(
        normalizedProjectId,
      );

      // ========================================================
      // REALTIME
      // ========================================================

      await _startRealtime();

      _isInitialized = true;

      debugPrint(
        '[ROYALTIES] '
        'Módulo inicializado.',
      );

      debugPrint(
        '[ROYALTIES] '
        'Projeto: '
        '$normalizedProjectId',
      );

      debugPrint(
        '[ROYALTIES] '
        'Membros: '
        '${_members.length}',
      );

      debugPrint(
        '[ROYALTIES] '
        'Acordos: '
        '${_agreements.length}',
      );

      debugPrint(
        '[ROYALTIES] '
        'Shares: '
        '${_shares.length}',
      );

      debugPrint(
        '[ROYALTIES] '
        'Aprovações: '
        '${_approvals.length}',
      );

      debugPrint(
        '[ROYALTIES] '
        'Eventos: '
        '${_events.length}',
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[ROYALTIES] '
        'Erro ao carregar: '
        '$error',
      );

      debugPrint(
        '$stackTrace',
      );

      _clearData();

      _errorMessage = _resolveError(
        error,
      );
    } finally {
      _isLoading = false;

      notifyListeners();
    }
  }

  // ============================================================
  // LOAD DATA
  // ============================================================

  Future<
    void
  >
  _loadData(
    String projectId,
  ) async {
    // ==========================================================
    // MEMBERS
    // ==========================================================

    final members = await repository.getProjectMembers(
      projectId: projectId,
    );

    // ==========================================================
    // AGREEMENTS
    // ==========================================================

    final agreements = await repository.getAgreements(
      projectId: projectId,
    );

    // ==========================================================
    // EVENTS
    // ==========================================================

    final events = await repository.getEvents(
      projectId: projectId,
    );

    _members = _normalizeMembers(
      members,
    );

    _agreements = _normalizeAgreements(
      agreements,
    );

    _events = _normalizeEvents(
      events,
    );

    // ==========================================================
    // CURRENT AGREEMENT
    // ==========================================================

    _currentAgreement = _resolveCurrentAgreement(
      _agreements,
    );

    // ==========================================================
    // CURRENT AGREEMENT DATA
    // ==========================================================

    await _loadCurrentAgreementData();
  }

  // ============================================================
  // LOAD CURRENT AGREEMENT DATA
  // ============================================================

  Future<
    void
  >
  _loadCurrentAgreementData() async {
    final agreement = _currentAgreement;

    if (agreement ==
        null) {
      _shares =
          const <
            RoyaltyShareModel
          >[];

      _approvals =
          const <
            RoyaltyApprovalModel
          >[];

      return;
    }

    final shares = await repository.getShares(
      agreementId: agreement.id,
    );

    final approvals = await repository.getApprovals(
      agreementId: agreement.id,
    );

    _shares = _normalizeShares(
      shares,
    );

    _approvals = _normalizeApprovals(
      approvals,
    );
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<
    void
  >
  refresh() async {
    final projectId = _projectId?.trim();

    if (projectId ==
            null ||
        projectId.isEmpty) {
      return;
    }

    try {
      _errorMessage = null;

      await _loadData(
        projectId,
      );

      await _restartAgreementRealtime();

      notifyListeners();
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[ROYALTIES] '
        'Erro no refresh: '
        '$error',
      );

      debugPrint(
        '$stackTrace',
      );

      _errorMessage = _resolveError(
        error,
      );

      notifyListeners();
    }
  }

  // ============================================================
  // PROPOSE DISTRIBUTION
  // ============================================================

  Future<
    String
  >
  proposeDistribution({
    required Map<
      String,
      double
    >
    percentagesByUserId,
  }) async {
    final projectId = _requireProjectId();

    if (!canCreateProposal) {
      throw StateError(
        'Não é possível criar uma proposta agora.',
      );
    }

    // ==========================================================
    // EVERY MEMBER REQUIRED
    // ==========================================================

    if (percentagesByUserId.length !=
        _members.length) {
      throw StateError(
        'Todos os participantes precisam estar na divisão.',
      );
    }

    final proposals =
        <
          RoyaltyShareProposal
        >[];

    for (final member in _members) {
      final percentage = percentagesByUserId[member.userId];

      if (percentage ==
          null) {
        throw StateError(
          '${member.displayName} não possui porcentagem definida.',
        );
      }

      if (percentage <
              0 ||
          percentage >
              100) {
        throw StateError(
          'Porcentagem inválida para ${member.displayName}.',
        );
      }

      proposals.add(
        RoyaltyShareProposal(
          userId: member.userId,
          percentage: percentage,
          roleSnapshot: member.role,
          displayNameSnapshot: member.displayName,
        ),
      );
    }

    // ==========================================================
    // TOTAL
    // ==========================================================

    final total =
        proposals.fold<
          double
        >(
          0,
          (
            value,
            proposal,
          ) {
            return value +
                proposal.percentage;
          },
        );

    if ((total -
                100)
            .abs() >
        0.0001) {
      throw StateError(
        'A divisão precisa totalizar exatamente 100%.',
      );
    }

    // ==========================================================
    // ACTION
    // ==========================================================

    _isSubmittingProposal = true;

    _errorMessage = null;

    _lastApprovalResult = null;

    notifyListeners();

    try {
      final agreementId = await repository.proposeDistribution(
        projectId: projectId,
        shares: proposals,
      );

      await refresh();

      return agreementId;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[ROYALTIES] '
        'Erro ao propor divisão: '
        '$error',
      );

      debugPrint(
        '$stackTrace',
      );

      _errorMessage = _resolveError(
        error,
      );

      rethrow;
    } finally {
      _isSubmittingProposal = false;

      notifyListeners();
    }
  }

  // ============================================================
  // CREATE NEW VERSION
  // ============================================================
  //
  // Não incrementamos versão no cliente.
  //
  // Quem calcula:
  //
  // max(version) + 1
  //
  // é o PostgreSQL.
  //
  // ============================================================

  Future<
    String
  >
  createNewVersion({
    required Map<
      String,
      double
    >
    percentagesByUserId,
  }) {
    return proposeDistribution(
      percentagesByUserId: percentagesByUserId,
    );
  }

  // ============================================================
  // APPROVE CURRENT AGREEMENT
  // ============================================================
  //
  // NOVO FLUXO:
  //
  // controller
  //      ↓
  // repository
  //      ↓
  // approve_royalty_agreement()
  //
  // Se não for o último:
  //
  // completed = false
  //
  // Se for o último:
  //
  // completed = true
  // status = confirmed
  // integrity_hash = ...
  //
  // ============================================================

  Future<
    RoyaltyApprovalResult
  >
  approveCurrentAgreement() async {
    final agreement = _requireCurrentAgreement();

    if (!canApprove) {
      if (currentUserApproved) {
        throw StateError(
          'Você já confirmou esta divisão.',
        );
      }

      if (agreement.isConfirmed) {
        throw StateError(
          'Este acordo já foi confirmado.',
        );
      }

      throw StateError(
        'Esta divisão não pode ser confirmada agora.',
      );
    }

    _isApproving = true;

    _errorMessage = null;

    _lastApprovalResult = null;

    notifyListeners();

    try {
      final result = await repository.approveAgreement(
        agreementId: agreement.id,
      );

      _lastApprovalResult = result;

      // ========================================================
      // DEBUG
      // ========================================================

      if (result.completed) {
        debugPrint(
          '[ROYALTIES] '
          'Última aprovação registrada. '
          'Acordo confirmado automaticamente.',
        );

        debugPrint(
          '[ROYALTIES] '
          'Hash oficial: '
          '${result.integrityHash}',
        );
      } else {
        debugPrint(
          '[ROYALTIES] '
          'Aprovação registrada. '
          'Faltam ${result.requiredCount - result.approvedCount} '
          'participante(s).',
        );
      }

      // ========================================================
      // REFRESH
      // ========================================================
      //
      // Mesmo com Realtime ativo, fazemos refresh após a ação
      // atual para não depender da latência do evento.
      //
      // ========================================================

      await refresh();

      return result;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[ROYALTIES] '
        'Erro ao aprovar acordo: '
        '$error',
      );

      debugPrint(
        '$stackTrace',
      );

      _errorMessage = _resolveError(
        error,
      );

      rethrow;
    } finally {
      _isApproving = false;

      notifyListeners();
    }
  }

  // ============================================================
  // HAS MEMBER APPROVED
  // ============================================================

  bool hasMemberApproved(
    String userId,
  ) {
    final normalizedUserId = userId.trim();

    if (normalizedUserId.isEmpty) {
      return false;
    }

    return _approvals.any(
      (
        approval,
      ) {
        return approval.userId ==
            normalizedUserId;
      },
    );
  }

  // ============================================================
  // SHARE FOR USER
  // ============================================================

  RoyaltyShareModel? shareForUser(
    String userId,
  ) {
    final normalizedUserId = userId.trim();

    if (normalizedUserId.isEmpty) {
      return null;
    }

    for (final share in _shares) {
      if (share.userId ==
          normalizedUserId) {
        return share;
      }
    }

    return null;
  }

  // ============================================================
  // PERCENTAGE FOR USER
  // ============================================================

  double percentageForUser(
    String userId,
  ) {
    return shareForUser(
          userId,
        )?.percentage ??
        0;
  }

  // ============================================================
  // FIND MEMBER
  // ============================================================

  RoyaltyMemberModel? findMember(
    String userId,
  ) {
    final normalized = userId.trim();

    if (normalized.isEmpty) {
      return null;
    }

    for (final member in _members) {
      if (member.userId ==
          normalized) {
        return member;
      }
    }

    return null;
  }

  // ============================================================
  // MEMBER FOR EVENT
  // ============================================================

  RoyaltyMemberModel? memberForEvent(
    RoyaltyEventModel event,
  ) {
    final actorId = event.actorUserId?.trim();

    if (actorId ==
            null ||
        actorId.isEmpty) {
      return null;
    }

    return findMember(
      actorId,
    );
  }

  // ============================================================
  // VERIFY STORED AGREEMENT INTEGRITY
  // ============================================================
  //
  // ATENÇÃO:
  //
  // O hash oficial agora é calculado no PostgreSQL.
  //
  // Este helper continua disponível, mas só deve ser usado como
  // confirmação local depois que o RoyaltyIntegrityService usar
  // exatamente o MESMO formato canônico da RPC.
  //
  // Por enquanto, um acordo confirmado com hash armazenado é
  // considerado possuir um registro de integridade.
  //
  // ============================================================

  bool verifyCurrentAgreementIntegrity() {
    final agreement = _currentAgreement;

    if (agreement ==
            null ||
        !agreement.isConfirmed ||
        !agreement.hasIntegrityHash) {
      return false;
    }

    return true;
  }

  // ============================================================
  // START REALTIME
  // ============================================================

  Future<
    void
  >
  _startRealtime() async {
    await _cancelRealtime();

    final projectId = _projectId?.trim();

    if (projectId ==
            null ||
        projectId.isEmpty) {
      return;
    }

    // ==========================================================
    // AGREEMENTS
    // ==========================================================

    _agreementsSubscription = repository
        .watchAgreements(
          projectId: projectId,
        )
        .listen(
          (
            agreements,
          ) async {
            final oldAgreementId = _currentAgreement?.id;

            final oldStatus = _currentAgreement?.status;

            _agreements = _normalizeAgreements(
              agreements,
            );

            _currentAgreement = _resolveCurrentAgreement(
              _agreements,
            );

            final newAgreementId = _currentAgreement?.id;

            final newStatus = _currentAgreement?.status;

            // ======================================================
            // AGREEMENT CHANGED
            // ======================================================

            if (oldAgreementId !=
                newAgreementId) {
              await _loadCurrentAgreementData();

              await _restartAgreementRealtime();
            }

            // ======================================================
            // STATUS CHANGED
            // ======================================================

            if (oldStatus !=
                newStatus) {
              debugPrint(
                '[ROYALTIES] '
                'Status do acordo atualizado em realtime: '
                '$newStatus',
              );
            }

            notifyListeners();
          },
          onError: _handleRealtimeError,
        );

    // ==========================================================
    // EVENTS
    // ==========================================================

    _eventsSubscription = repository
        .watchEvents(
          projectId: projectId,
        )
        .listen(
          (
            events,
          ) {
            _events = _normalizeEvents(
              events,
            );

            notifyListeners();
          },
          onError: _handleRealtimeError,
        );

    // ==========================================================
    // CURRENT AGREEMENT REALTIME
    // ==========================================================

    await _startAgreementRealtime();
  }

  // ============================================================
  // START AGREEMENT REALTIME
  // ============================================================

  Future<
    void
  >
  _startAgreementRealtime() async {
    final agreement = _currentAgreement;

    if (agreement ==
        null) {
      return;
    }

    // ==========================================================
    // SHARES
    // ==========================================================

    _sharesSubscription = repository
        .watchShares(
          agreementId: agreement.id,
        )
        .listen(
          (
            shares,
          ) {
            _shares = _normalizeShares(
              shares,
            );

            notifyListeners();
          },
          onError: _handleRealtimeError,
        );

    // ==========================================================
    // APPROVALS
    // ==========================================================

    _approvalsSubscription = repository
        .watchApprovals(
          agreementId: agreement.id,
        )
        .listen(
          (
            approvals,
          ) {
            _approvals = _normalizeApprovals(
              approvals,
            );

            notifyListeners();
          },
          onError: _handleRealtimeError,
        );
  }

  // ============================================================
  // RESTART AGREEMENT REALTIME
  // ============================================================

  Future<
    void
  >
  _restartAgreementRealtime() async {
    await _sharesSubscription?.cancel();

    await _approvalsSubscription?.cancel();

    _sharesSubscription = null;

    _approvalsSubscription = null;

    await _startAgreementRealtime();
  }

  // ============================================================
  // REALTIME ERROR
  // ============================================================

  void _handleRealtimeError(
    Object error,
    StackTrace stackTrace,
  ) {
    debugPrint(
      '[ROYALTIES] '
      'Erro Realtime: '
      '$error',
    );

    debugPrint(
      '$stackTrace',
    );
  }

  // ============================================================
  // RESOLVE CURRENT AGREEMENT
  // ============================================================

  RoyaltyAgreementModel? _resolveCurrentAgreement(
    List<
      RoyaltyAgreementModel
    >
    agreements,
  ) {
    if (agreements.isEmpty) {
      return null;
    }

    // ==========================================================
    // PROPOSED FIRST
    // ==========================================================
    //
    // Se existe proposta pendente, ela é a versão em discussão.
    //
    // ==========================================================

    for (final agreement in agreements) {
      if (agreement.isProposed) {
        return agreement;
      }
    }

    // ==========================================================
    // CONFIRMED
    // ==========================================================

    for (final agreement in agreements) {
      if (agreement.isConfirmed) {
        return agreement;
      }
    }

    // ==========================================================
    // DRAFT
    // ==========================================================

    for (final agreement in agreements) {
      if (agreement.isDraft) {
        return agreement;
      }
    }

    return agreements.first;
  }

  // ============================================================
  // NORMALIZE MEMBERS
  // ============================================================

  List<
    RoyaltyMemberModel
  >
  _normalizeMembers(
    List<
      RoyaltyMemberModel
    >
    members,
  ) {
    final unique =
        <
          String,
          RoyaltyMemberModel
        >{};

    for (final member in members) {
      final userId = member.userId.trim();

      if (userId.isEmpty) {
        continue;
      }

      unique[userId] = member;
    }

    final result = unique.values.toList();

    result.sort(
      (
        a,
        b,
      ) {
        if (a.isFounder !=
            b.isFounder) {
          return a.isFounder
              ? -1
              : 1;
        }

        return a.displayName.toLowerCase().compareTo(
          b.displayName.toLowerCase(),
        );
      },
    );

    return result;
  }

  // ============================================================
  // NORMALIZE AGREEMENTS
  // ============================================================

  List<
    RoyaltyAgreementModel
  >
  _normalizeAgreements(
    List<
      RoyaltyAgreementModel
    >
    agreements,
  ) {
    final unique =
        <
          String,
          RoyaltyAgreementModel
        >{};

    for (final agreement in agreements) {
      final id = agreement.id.trim();

      if (id.isEmpty) {
        continue;
      }

      unique[id] = agreement;
    }

    final result = unique.values.toList();

    result.sort(
      (
        a,
        b,
      ) {
        final versionComparison = b.version.compareTo(
          a.version,
        );

        if (versionComparison !=
            0) {
          return versionComparison;
        }

        return b.createdAt.compareTo(
          a.createdAt,
        );
      },
    );

    return result;
  }

  // ============================================================
  // NORMALIZE SHARES
  // ============================================================

  List<
    RoyaltyShareModel
  >
  _normalizeShares(
    List<
      RoyaltyShareModel
    >
    shares,
  ) {
    final unique =
        <
          String,
          RoyaltyShareModel
        >{};

    for (final share in shares) {
      final userId = share.userId.trim();

      if (userId.isEmpty) {
        continue;
      }

      unique[userId] = share;
    }

    final result = unique.values.toList();

    result.sort(
      (
        a,
        b,
      ) {
        final aIndex = _memberIndex(
          a.userId,
        );

        final bIndex = _memberIndex(
          b.userId,
        );

        if (aIndex !=
            bIndex) {
          return aIndex.compareTo(
            bIndex,
          );
        }

        return a.userId.compareTo(
          b.userId,
        );
      },
    );

    return result;
  }

  // ============================================================
  // NORMALIZE APPROVALS
  // ============================================================

  List<
    RoyaltyApprovalModel
  >
  _normalizeApprovals(
    List<
      RoyaltyApprovalModel
    >
    approvals,
  ) {
    final unique =
        <
          String,
          RoyaltyApprovalModel
        >{};

    for (final approval in approvals) {
      final userId = approval.userId.trim();

      if (userId.isEmpty) {
        continue;
      }

      unique[userId] = approval;
    }

    final result = unique.values.toList();

    result.sort(
      (
        a,
        b,
      ) {
        return a.approvedAt.compareTo(
          b.approvedAt,
        );
      },
    );

    return result;
  }

  // ============================================================
  // NORMALIZE EVENTS
  // ============================================================

  List<
    RoyaltyEventModel
  >
  _normalizeEvents(
    List<
      RoyaltyEventModel
    >
    events,
  ) {
    final unique =
        <
          String,
          RoyaltyEventModel
        >{};

    for (final event in events) {
      final id = event.id.trim();

      if (id.isEmpty) {
        continue;
      }

      unique[id] = event;
    }

    final result = unique.values.toList();

    result.sort(
      (
        a,
        b,
      ) {
        return b.createdAt.compareTo(
          a.createdAt,
        );
      },
    );

    return result;
  }

  // ============================================================
  // MEMBER INDEX
  // ============================================================

  int _memberIndex(
    String userId,
  ) {
    final index = _members.indexWhere(
      (
        member,
      ) {
        return member.userId ==
            userId;
      },
    );

    if (index <
        0) {
      return 999999;
    }

    return index;
  }

  // ============================================================
  // CLEAR DATA
  // ============================================================

  void _clearData() {
    _members =
        const <
          RoyaltyMemberModel
        >[];

    _agreements =
        const <
          RoyaltyAgreementModel
        >[];

    _currentAgreement = null;

    _shares =
        const <
          RoyaltyShareModel
        >[];

    _approvals =
        const <
          RoyaltyApprovalModel
        >[];

    _events =
        const <
          RoyaltyEventModel
        >[];
  }

  // ============================================================
  // CANCEL REALTIME
  // ============================================================

  Future<
    void
  >
  _cancelRealtime() async {
    await _agreementsSubscription?.cancel();

    await _sharesSubscription?.cancel();

    await _approvalsSubscription?.cancel();

    await _eventsSubscription?.cancel();

    _agreementsSubscription = null;

    _sharesSubscription = null;

    _approvalsSubscription = null;

    _eventsSubscription = null;
  }

  // ============================================================
  // REQUIRE PROJECT ID
  // ============================================================

  String _requireProjectId() {
    final projectId = _projectId?.trim();

    if (projectId ==
            null ||
        projectId.isEmpty) {
      throw StateError(
        'Projeto não inicializado.',
      );
    }

    return projectId;
  }

  // ============================================================
  // REQUIRE CURRENT AGREEMENT
  // ============================================================

  RoyaltyAgreementModel _requireCurrentAgreement() {
    final agreement = _currentAgreement;

    if (agreement ==
        null) {
      throw StateError(
        'Nenhum acordo disponível.',
      );
    }

    return agreement;
  }

  // ============================================================
  // CLEAR LAST APPROVAL RESULT
  // ============================================================

  void clearLastApprovalResult() {
    if (_lastApprovalResult ==
        null) {
      return;
    }

    _lastApprovalResult = null;

    notifyListeners();
  }

  // ============================================================
  // CLEAR ERROR
  // ============================================================

  void clearError() {
    if (_errorMessage ==
        null) {
      return;
    }

    _errorMessage = null;

    notifyListeners();
  }

  // ============================================================
  // SET ERROR
  // ============================================================

  void _setError(
    String message,
  ) {
    _errorMessage = message;

    _isLoading = false;

    notifyListeners();
  }

  // ============================================================
  // RESOLVE ERROR
  // ============================================================

  String _resolveError(
    Object error,
  ) {
    if (error
        is StateError) {
      return error.message.toString();
    }

    if (error
        is ArgumentError) {
      return error.message?.toString() ??
          'Dados inválidos.';
    }

    final message = error.toString();

    if (message.startsWith(
      'Exception: ',
    )) {
      return message.substring(
        11,
      );
    }

    return message;
  }

  // ============================================================
  // RESET
  // ============================================================

  Future<
    void
  >
  reset() async {
    await _cancelRealtime();

    _projectId = null;

    _currentUserId = null;

    _clearData();

    _isLoading = false;

    _isSubmittingProposal = false;

    _isApproving = false;

    _isInitialized = false;

    _errorMessage = null;

    _lastApprovalResult = null;

    notifyListeners();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    unawaited(
      _cancelRealtime(),
    );

    super.dispose();
  }
}
