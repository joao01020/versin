import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:versin/app/locator.dart';
import 'package:versin/modules/dashboard/controllers/dashboard_controller.dart';

import 'package:versin/modules/networking/call/data/repositories/project_call_repository_impl.dart';
import 'package:versin/modules/networking/call/views/call_view.dart';
import 'package:versin/modules/networking/call/views/widgets/global_call_banner.dart';
import 'package:versin/modules/networking/chat/controllers/global_chat_controller.dart';
import 'package:versin/modules/networking/chat/views/chat_view.dart';
import 'package:versin/modules/networking/core/controllers/networking_controller.dart';
import 'package:versin/modules/networking/invitations/controllers/project_invitation_controller.dart';
import 'package:versin/modules/networking/invitations/models/project_invitation_model.dart';
import 'package:versin/modules/networking/members/views/members_view.dart';
import 'package:versin/modules/networking/page/dialogs/networking_leave_project_dialog.dart';
import 'package:versin/modules/networking/page/models/networking_call_banner_data.dart';
import 'package:versin/modules/networking/page/services/networking_profile_name_resolver.dart';
import 'package:versin/modules/networking/royalties/controllers/royalties_controller.dart';
import 'package:versin/modules/networking/royalties/data/repositories/royalties_repository_impl.dart';
import 'package:versin/modules/networking/royalties/views/royalties_view.dart';
import 'package:versin/modules/networking/tasks/controllers/project_tasks_controller.dart';
import 'package:versin/modules/networking/tasks/data/repositories/project_tasks_repository_impl.dart';
import 'package:versin/modules/networking/tasks/views/tasks_view.dart';
import 'package:versin/modules/networking/views/networking_session_view.dart';
import 'package:versin/modules/networking/views/sub_features/contract_view.dart';

// ============================================================
// NETWORKING SESSION COORDINATOR
// ============================================================
//
// Orquestra a Studio Session.
//
// Owned:
// - NetworkingController
// - GlobalChatController
// - ProfileNameResolver
//
// Shared:
// - ProjectInvitationController (GetIt)
// - DashboardController (GetIt)
//
// ============================================================

class NetworkingSessionCoordinator extends ChangeNotifier {
  final String projectId;

  late final NetworkingController controller;
  late final GlobalChatController globalChatController;
  late final ProjectInvitationController invitationController;
  late final NetworkingProfileNameResolver nameResolver;

  final SupabaseClient _supabase;
  final ProjectCallRepositoryImpl _callRepository;

  bool _initialized = false;
  bool _disposed = false;

  bool isGlobalCallActionProcessing = false;
  String? globalCallAction;

  bool isLeavingProject = false;

  NetworkingSessionCoordinator({
    required String projectId,
    SupabaseClient? supabase,
    ProjectCallRepositoryImpl? callRepository,
  }) : projectId = projectId.trim(),
       _supabase = supabase ?? Supabase.instance.client,
       _callRepository = callRepository ?? ProjectCallRepositoryImpl();

  // ============================================================
  // INIT
  // ============================================================

  void initialize() {
    if (_initialized || _disposed) {
      return;
    }

    _initialized = true;

    controller = NetworkingController(projectId: projectId)..initSession();

    globalChatController = GlobalChatController(projectId: projectId)..init();

    invitationController = sl<ProjectInvitationController>();

    invitationController.init();

    nameResolver = NetworkingProfileNameResolver(supabase: _supabase);
  }

  // ============================================================
  // DERIVED
  // ============================================================

  String get projectHash {
    if (projectId.length >= 8) {
      return projectId.substring(0, 8).toUpperCase();
    }

    return projectId.toUpperCase();
  }

  String? get currentUserId {
    final value = _supabase.auth.currentUser?.id.trim();

    if (value == null || value.isEmpty) {
      return null;
    }

    return value;
  }

  // ============================================================
  // CALL STREAM
  // ============================================================

  Stream<List<Map<String, dynamic>>> get projectCallsStream {
    return _supabase
        .from('project_calls')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }

  Map<String, dynamic>? selectActiveCallRow(List<Map<String, dynamic>> rows) {
    final userId = currentUserId;

    if (userId == null) {
      return null;
    }

    for (final row in rows) {
      final rowProjectId = row['project_id']?.toString().trim();

      if (rowProjectId != projectId) {
        continue;
      }

      final status = row['status']?.toString().trim();

      if (status != 'ringing' && status != 'active') {
        continue;
      }

      final createdBy = row['created_by']?.toString().trim();

      final targetUserId = row['target_user_id']?.toString().trim();

      final directlyInvolved = createdBy == userId || targetUserId == userId;

      final groupCall = targetUserId == null || targetUserId.isEmpty;

      if (!directlyInvolved && !groupCall) {
        continue;
      }

      return row;
    }

    return null;
  }

  NetworkingCallBannerData? callBannerDataFor(Map<String, dynamic> row) {
    final userId = currentUserId;

    if (userId == null) {
      return null;
    }

    final callId = row['id']?.toString().trim() ?? '';

    final createdBy = row['created_by']?.toString().trim() ?? '';

    final targetUserId = row['target_user_id']?.toString().trim();

    final status = row['status']?.toString().trim() ?? '';

    final mediaTypeValue =
        row['media_type']?.toString().trim().toLowerCase() ?? 'audio';

    final mediaType = mediaTypeValue == 'video'
        ? GlobalCallMediaType.video
        : GlobalCallMediaType.audio;

    final incoming =
        status == 'ringing' &&
        createdBy != userId &&
        (targetUserId == userId ||
            targetUserId == null ||
            targetUserId.isEmpty);

    final outgoing = status == 'ringing' && createdBy == userId;

    final active = status == 'active';

    var state = GlobalCallBannerState.hidden;

    if (isGlobalCallActionProcessing && globalCallAction == 'end') {
      state = GlobalCallBannerState.ending;
    } else if (incoming) {
      state = GlobalCallBannerState.incoming;
    } else if (outgoing) {
      state = GlobalCallBannerState.calling;
    } else if (active) {
      state = GlobalCallBannerState.active;
    }

    final startedAt = DateTime.tryParse(row['started_at']?.toString() ?? '');

    final duration = startedAt == null || !active
        ? null
        : DateTime.now().toUtc().difference(startedAt.toUtc());

    final participantUserId = _resolveCallParticipantUserId(
      createdBy: createdBy,
      targetUserId: targetUserId,
      currentUserId: userId,
    );

    return NetworkingCallBannerData(
      callId: callId,
      participantUserId: participantUserId,
      state: state,
      mediaType: mediaType,
      duration: duration,
      canAccept: incoming && callId.isNotEmpty,
      canReject: incoming && callId.isNotEmpty,
      canEnd: (outgoing || active) && callId.isNotEmpty,
    );
  }

  String _resolveCallParticipantUserId({
    required String createdBy,
    required String? targetUserId,
    required String currentUserId,
  }) {
    final normalizedCreatedBy = createdBy.trim();

    final normalizedTargetUserId = targetUserId?.trim();

    if (normalizedCreatedBy == currentUserId) {
      if (normalizedTargetUserId != null && normalizedTargetUserId.isNotEmpty) {
        return normalizedTargetUserId;
      }

      return '';
    }

    return normalizedCreatedBy;
  }

  // ============================================================
  // NAMES
  // ============================================================

  Future<String> resolveChatSenderName(String userId) {
    var fallback = globalChatController.senderName.trim();

    if (fallback.isEmpty || fallback == 'Membro') {
      fallback = 'Membro';
    }

    return nameResolver.resolve(userId: userId, fallback: fallback);
  }

  Future<String> resolveCallParticipantName(String userId) {
    return nameResolver.resolve(userId: userId, fallback: 'Membro da sessão');
  }

  String? cachedName(String userId) {
    return nameResolver.cachedName(userId);
  }

  // ============================================================
  // INVITATIONS
  // ============================================================

  Future<void> acceptProjectInvitation(
    BuildContext context,
    ProjectInvitationModel invitation,
  ) async {
    if (invitationController.isBusy) {
      return;
    }

    final acceptedProjectId = await invitationController.acceptInvitation(
      invitation,
    );

    if (_disposed || !context.mounted) {
      return;
    }

    if (acceptedProjectId == null || acceptedProjectId.trim().isEmpty) {
      showMessage(
        context,
        invitationController.errorMessage ??
            'Não foi possível aceitar o convite.',
        error: true,
      );

      return;
    }

    showMessage(context, 'Você entrou em ${invitation.projectTitle}.');

    final normalizedProjectId = acceptedProjectId.trim();

    if (normalizedProjectId == projectId) {
      controller.initSession();

      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) {
          return NetworkingSessionView(projectId: normalizedProjectId);
        },
      ),
    );
  }

  Future<void> rejectProjectInvitation(
    BuildContext context,
    ProjectInvitationModel invitation,
  ) async {
    if (invitationController.isBusy) {
      return;
    }

    final rejected = await invitationController.rejectInvitation(invitation);

    if (_disposed || !context.mounted) {
      return;
    }

    if (!rejected) {
      showMessage(
        context,
        invitationController.errorMessage ??
            'Não foi possível recusar o convite.',
        error: true,
      );

      return;
    }

    showMessage(context, 'Convite recusado.');
  }

  // ============================================================
  // CHAT
  // ============================================================

  Future<void> openChat(BuildContext context) async {
    if (!context.mounted) {
      return;
    }

    globalChatController.markAsRead();

    globalChatController.setChatVisible(true);

    try {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) {
            return ChatView(projectId: projectId);
          },
        ),
      );
    } finally {
      if (globalChatController.chatVisible) {
        globalChatController.setChatVisible(false);
      }
    }
  }

  // ============================================================
  // LEAVE PROJECT
  // ============================================================

  Future<void> requestLeaveProject(BuildContext context) async {
    if (isLeavingProject || !context.mounted) {
      return;
    }

    final confirmed = await NetworkingLeaveProjectDialog.show(context: context);

    if (!confirmed || _disposed || !context.mounted) {
      return;
    }

    await _leaveProject(context);
  }

  Future<void> _leaveProject(BuildContext context) async {
    if (isLeavingProject) {
      return;
    }

    final userId = currentUserId;

    if (userId == null || projectId.isEmpty) {
      showMessage(
        context,
        'Não foi possível identificar sua participação '
        'neste projeto.',
        error: true,
      );

      return;
    }

    _setLeavingProject(true);

    try {
      await _supabase.rpc(
        'leave_match_project',
        params: <String, dynamic>{'p_project_id': projectId},
      );

      debugPrint(
        '[NETWORKING SESSION] '
        'Usuário $userId saiu do projeto $projectId.',
      );

      await _refreshDashboardActiveProject();

      if (_disposed || !context.mounted) {
        return;
      }

      showMessage(context, 'Você saiu da Studio Session.');

      Navigator.of(context).pop(true);
    } on PostgrestException catch (error, stackTrace) {
      debugPrint(
        '[NETWORKING SESSION] '
        'Erro Supabase ao sair do projeto: '
        '${error.message}',
      );

      debugPrint(
        '[NETWORKING SESSION] '
        'Código: ${error.code}',
      );

      debugPrint('$stackTrace');

      if (context.mounted) {
        showMessage(context, _leaveProjectErrorMessage(error), error: true);
      }
    } catch (error, stackTrace) {
      debugPrint(
        '[NETWORKING SESSION] '
        'Erro ao sair do projeto: $error',
      );

      debugPrint('$stackTrace');

      if (context.mounted) {
        showMessage(
          context,
          'Não foi possível sair do projeto. '
          'Tente novamente.',
          error: true,
        );
      }
    } finally {
      _setLeavingProject(false);
    }
  }

  String _leaveProjectErrorMessage(PostgrestException error) {
    final message = error.message.trim().toLowerCase();

    if (message.contains('projeto não encontrado') ||
        message.contains('projeto nao encontrado')) {
      return 'Este projeto não está mais disponível.';
    }

    if (message.contains('usuário não pertence') ||
        message.contains('usuario nao pertence')) {
      return 'Você já não faz parte deste projeto.';
    }

    if (message.contains('não autenticado') ||
        message.contains('nao autenticado')) {
      return 'Sua sessão expirou. '
          'Entre novamente para continuar.';
    }

    return 'Não foi possível sair do projeto. '
        'Tente novamente.';
  }

  Future<void> _refreshDashboardActiveProject() async {
    try {
      final dashboardController = sl<DashboardController>();

      await dashboardController.refreshActiveProject();
    } catch (error, stackTrace) {
      debugPrint(
        '[NETWORKING SESSION] '
        'Não foi possível atualizar projeto ativo '
        'no Dashboard: $error',
      );

      debugPrint('$stackTrace');
    }
  }

  // ============================================================
  // CALLS
  // ============================================================

  Future<void> openCall(BuildContext context, {String? participantName}) async {
    if (!context.mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) {
          return CallView(
            projectId: projectId,
            participantName: participantName,
          );
        },
      ),
    );
  }

  Future<void> acceptGlobalCall(
    BuildContext context,
    String callId,
    String participantName,
  ) async {
    if (isGlobalCallActionProcessing) {
      return;
    }

    _setGlobalCallProcessing(true, 'accept');

    try {
      await _callRepository.acceptCall(callId: callId);

      if (_disposed || !context.mounted) {
        return;
      }

      await openCall(context, participantName: participantName);
    } catch (error, stackTrace) {
      debugPrint(
        '[NETWORKING SESSION] '
        'Erro ao aceitar chamada: $error',
      );

      debugPrint('$stackTrace');
    } finally {
      _setGlobalCallProcessing(false, null);
    }
  }

  Future<void> rejectGlobalCall(String callId) async {
    if (isGlobalCallActionProcessing) {
      return;
    }

    _setGlobalCallProcessing(true, 'reject');

    try {
      await _callRepository.rejectCall(callId: callId);
    } catch (error, stackTrace) {
      debugPrint(
        '[NETWORKING SESSION] '
        'Erro ao recusar chamada: $error',
      );

      debugPrint('$stackTrace');
    } finally {
      _setGlobalCallProcessing(false, null);
    }
  }

  Future<void> endGlobalCall(String callId) async {
    if (isGlobalCallActionProcessing) {
      return;
    }

    _setGlobalCallProcessing(true, 'end');

    try {
      await _callRepository.endCall(callId: callId);
    } catch (error, stackTrace) {
      debugPrint(
        '[NETWORKING SESSION] '
        'Erro ao encerrar chamada: $error',
      );

      debugPrint('$stackTrace');
    } finally {
      _setGlobalCallProcessing(false, null);
    }
  }

  void _setGlobalCallProcessing(bool value, String? action) {
    if (_disposed) {
      return;
    }

    isGlobalCallActionProcessing = value;
    globalCallAction = action;

    notifyListeners();
  }

  void _setLeavingProject(bool value) {
    if (_disposed) {
      return;
    }

    isLeavingProject = value;

    notifyListeners();
  }

  // ============================================================
  // FEATURE NAVIGATION
  // ============================================================

  Future<void> openRoyalties(BuildContext context) async {
    final userId = currentUserId;

    if (userId == null || projectId.isEmpty) {
      showMessage(
        context,
        'Não foi possível abrir os royalties deste projeto.',
        error: true,
      );

      return;
    }

    final repository = RoyaltiesRepositoryImpl(
      professionalRoleResolver: (userId) async {
        return null;
      },
    );

    final royaltiesController = RoyaltiesController(repository: repository);

    try {
      await royaltiesController.load(
        projectId: projectId,
        currentUserId: userId,
      );

      if (_disposed || !context.mounted) {
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) {
            return RoyaltiesView(
              projectId: projectId,
              controller: royaltiesController,
            );
          },
        ),
      );
    } finally {
      royaltiesController.dispose();
    }
  }

  Future<void> openTasks(BuildContext context) async {
    final userId = currentUserId;

    if (userId == null || projectId.isEmpty) {
      showMessage(
        context,
        'Não foi possível abrir as tarefas deste projeto.',
        error: true,
      );

      return;
    }

    final repository = ProjectTasksRepositoryImpl(
      professionalRoleResolver: (userId) async {
        return null;
      },
    );

    final tasksController = ProjectTasksController(repository: repository);

    try {
      await tasksController.load(projectId: projectId, currentUserId: userId);

      if (_disposed || !context.mounted) {
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) {
            return TasksView(projectId: projectId, controller: tasksController);
          },
        ),
      );
    } finally {
      tasksController.dispose();
    }
  }

  Future<void> openContract(BuildContext context) {
    return _openPage(context, ContractView(projectId: projectId));
  }

  Future<void> openMembers(BuildContext context) {
    return _openPage(context, MembersView(projectId: projectId));
  }

  Future<void> _openPage(BuildContext context, Widget page) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) {
          return page;
        },
      ),
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void showMessage(BuildContext context, String message, {bool error = false}) {
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error
              ? const Color(0xFF3B1218)
              : const Color(0xFF15151D),
          behavior: SnackBarBehavior.floating,
        ),
      );
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

    nameResolver.clear();

    // ProjectInvitationController é global (GetIt).
    // NÃO deve ser destroyed por esta página.
    globalChatController.dispose();
    controller.dispose();

    super.dispose();
  }
}
