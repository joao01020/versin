import 'package:flutter/foundation.dart';

import 'package:versin/app/locator.dart';

import 'package:versin/modules/networking/invitations/controllers/project_invitation_controller.dart';
import 'package:versin/modules/networking/invitations/models/project_invitation_model.dart';

// ============================================================
// DASHBOARD INVITATION ACTION TYPE
// ============================================================

enum DashboardInvitationActionType { accepted, rejected, failed }

// ============================================================
// DASHBOARD INVITATION ACTION RESULT
// ============================================================
//
// Resultado padronizado das ações de convite.
//
// Isso evita que o DashboardPage precise conhecer:
// - errorMessage;
// - retorno interno do ProjectInvitationController;
// - textos de sucesso/erro.
//
// ============================================================

class DashboardInvitationActionResult {
  final DashboardInvitationActionType type;

  final String message;

  final String? projectId;

  const DashboardInvitationActionResult({
    required this.type,
    required this.message,
    this.projectId,
  });

  // ============================================================
  // HELPERS
  // ============================================================

  bool get succeeded {
    return type != DashboardInvitationActionType.failed;
  }

  bool get wasAccepted {
    return type == DashboardInvitationActionType.accepted;
  }

  bool get wasRejected {
    return type == DashboardInvitationActionType.rejected;
  }

  bool get failed {
    return type == DashboardInvitationActionType.failed;
  }
}

// ============================================================
// DASHBOARD INVITATION CONTROLLER
// ============================================================
//
// Adapta:
//
// ProjectInvitationController
//
// para:
//
// Dashboard.
//
// Responsabilidades:
//
// - inicializar convites;
// - observar mudanças;
// - expor convite atual;
// - aceitar convite;
// - recusar convite;
// - limpar projeto aceito;
// - padronizar mensagens.
//
// NÃO:
//
// - conhece BuildContext;
// - abre NetworkingSessionView;
// - mostra SnackBar;
// - desenha banner.
//
// IMPORTANTE:
//
// ProjectInvitationController continua sendo global via GetIt.
// Este controller NÃO deve dar dispose nele.
//
// ============================================================

class DashboardInvitationController extends ChangeNotifier {
  // ============================================================
  // PROJECT INVITATION CONTROLLER
  // ============================================================

  final ProjectInvitationController projectInvitationController;

  // ============================================================
  // STATE
  // ============================================================

  bool _initialized = false;

  bool _disposed = false;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  DashboardInvitationController({
    ProjectInvitationController? projectInvitationController,
  }) : projectInvitationController =
           projectInvitationController ?? sl<ProjectInvitationController>();

  // ============================================================
  // GETTERS
  // ============================================================

  bool get initialized {
    return _initialized;
  }

  ProjectInvitationModel? get currentInvitation {
    return projectInvitationController.currentInvitation;
  }

  bool get hasInvitation {
    return currentInvitation != null;
  }

  bool get isAccepting {
    return projectInvitationController.isAccepting;
  }

  bool get isRejecting {
    return projectInvitationController.isRejecting;
  }

  bool get isBusy {
    return projectInvitationController.isBusy;
  }

  String? get errorMessage {
    final value = projectInvitationController.errorMessage?.trim();

    if (value == null || value.isEmpty) {
      return null;
    }

    return value;
  }

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> init() async {
    if (_initialized || _disposed) {
      return;
    }

    _initialized = true;

    projectInvitationController.addListener(_handleInvitationChanged);

    try {
      await projectInvitationController.init();

      debugPrint(
        '[DASHBOARD INVITATION] '
        'Controller inicializado.',
      );
    } catch (error, stackTrace) {
      debugPrint(
        '[DASHBOARD INVITATION] '
        'Erro ao inicializar: '
        '$error',
      );

      debugPrint('$stackTrace');

      rethrow;
    }
  }

  // ============================================================
  // CONTROLLER CHANGED
  // ============================================================

  void _handleInvitationChanged() {
    if (_disposed) {
      return;
    }

    notifyListeners();
  }

  // ============================================================
  // ACCEPT
  // ============================================================

  Future<DashboardInvitationActionResult> accept(
    ProjectInvitationModel invitation,
  ) async {
    if (_disposed) {
      return const DashboardInvitationActionResult(
        type: DashboardInvitationActionType.failed,
        message: 'O controller de convites não está disponível.',
      );
    }

    if (isBusy) {
      return const DashboardInvitationActionResult(
        type: DashboardInvitationActionType.failed,
        message: 'Já existe uma ação de convite em andamento.',
      );
    }

    try {
      final projectId = await projectInvitationController.acceptInvitation(
        invitation,
      );

      final normalizedProjectId = projectId?.trim();

      // ========================================================
      // FAILURE
      // ========================================================

      if (normalizedProjectId == null || normalizedProjectId.isEmpty) {
        return DashboardInvitationActionResult(
          type: DashboardInvitationActionType.failed,

          message: errorMessage ?? 'Não foi possível aceitar o convite.',
        );
      }

      // ========================================================
      // SUCCESS
      // ========================================================

      final projectTitle = invitation.projectTitle.trim();

      return DashboardInvitationActionResult(
        type: DashboardInvitationActionType.accepted,

        message: projectTitle.isNotEmpty
            ? 'Você entrou em $projectTitle.'
            : 'Você entrou no projeto.',

        projectId: normalizedProjectId,
      );
    } catch (error, stackTrace) {
      debugPrint(
        '[DASHBOARD INVITATION] '
        'Erro ao aceitar convite: '
        '$error',
      );

      debugPrint('$stackTrace');

      return DashboardInvitationActionResult(
        type: DashboardInvitationActionType.failed,

        message: errorMessage ?? 'Não foi possível aceitar o convite.',
      );
    }
  }

  // ============================================================
  // REJECT
  // ============================================================

  Future<DashboardInvitationActionResult> reject(
    ProjectInvitationModel invitation,
  ) async {
    if (_disposed) {
      return const DashboardInvitationActionResult(
        type: DashboardInvitationActionType.failed,
        message: 'O controller de convites não está disponível.',
      );
    }

    if (isBusy) {
      return const DashboardInvitationActionResult(
        type: DashboardInvitationActionType.failed,
        message: 'Já existe uma ação de convite em andamento.',
      );
    }

    try {
      final rejected = await projectInvitationController.rejectInvitation(
        invitation,
      );

      // ========================================================
      // FAILURE
      // ========================================================

      if (!rejected) {
        return DashboardInvitationActionResult(
          type: DashboardInvitationActionType.failed,

          message: errorMessage ?? 'Não foi possível recusar o convite.',
        );
      }

      // ========================================================
      // SUCCESS
      // ========================================================

      return const DashboardInvitationActionResult(
        type: DashboardInvitationActionType.rejected,

        message: 'Convite recusado.',
      );
    } catch (error, stackTrace) {
      debugPrint(
        '[DASHBOARD INVITATION] '
        'Erro ao recusar convite: '
        '$error',
      );

      debugPrint('$stackTrace');

      return DashboardInvitationActionResult(
        type: DashboardInvitationActionType.failed,

        message: errorMessage ?? 'Não foi possível recusar o convite.',
      );
    }
  }

  // ============================================================
  // CLEAR ACCEPTED PROJECT
  // ============================================================

  void clearAcceptedProject() {
    if (_disposed) {
      return;
    }

    projectInvitationController.clearAcceptedProject();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    if (_disposed) {
      return;
    }

    _disposed = true;

    projectInvitationController.removeListener(_handleInvitationChanged);

    // ==========================================================
    // IMPORTANTE
    // ==========================================================
    //
    // NÃO chamar:
    //
    // projectInvitationController.dispose();
    //
    // porque ele é registrado globalmente no GetIt.
    //
    // ==========================================================

    super.dispose();
  }
}
