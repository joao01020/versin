import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:versin/app/locator.dart';
import 'package:versin/modules/dashboard/controllers/dashboard_controller.dart';

import '../call/data/repositories/project_call_repository_impl.dart';
import '../call/views/call_view.dart';
import '../call/views/widgets/global_call_banner.dart';
import '../controllers/global_chat_controller.dart';
import '../widgets/global_chat_banner.dart';

import '../controllers/networking_controller.dart';

// ============================================================
// PROJECT INVITATIONS
// ============================================================

import '../invitations/controllers/project_invitation_controller.dart';
import '../invitations/models/project_invitation_model.dart';
import '../invitations/widgets/project_invitation_banner.dart';

import 'sub_features/chat_view.dart';
import 'sub_features/contract_view.dart';
import 'sub_features/members_view.dart';
import 'sub_features/royalties_view.dart';
import 'sub_features/tasks_view.dart';

// ============================================================
// NETWORKING SESSION VIEW
// ============================================================
//
// Tela principal da Studio Session.
//
// Agora também exibe:
//
// - GlobalCallBanner;
// - GlobalChatBanner.
//
// dentro da própria sessão.
//
// Isso é necessário porque NetworkingSessionView é aberta por
// Navigator.push().
//
// Portanto:
//
// DashboardPage
//    ↓
// NetworkingSessionView
//
// O banner que existe no Dashboard fica atrás desta rota.
//
// Nesta versão:
//
// - chamada enviada aparece aqui;
// - chamada recebida aparece aqui;
// - chamada ativa aparece aqui;
// - áudio e vídeo são diferenciados;
// - nome real do outro membro é carregado;
// - tocar no banner abre CallView;
// - aceitar / recusar / encerrar pode ser feito pelo banner.
//
// ============================================================

class NetworkingSessionView
    extends
        StatefulWidget {
  final String projectId;

  const NetworkingSessionView({
    super.key,
    required this.projectId,
  });

  @override
  State<
    NetworkingSessionView
  >
  createState() => _NetworkingSessionViewState();
}

// ============================================================
// STATE
// ============================================================

class _NetworkingSessionViewState
    extends
        State<
          NetworkingSessionView
        > {
  // ==========================================================
  // CONTROLLER
  // ==========================================================

  late final NetworkingController _controller;

  late final GlobalChatController _globalChatController;

  // ==========================================================
  // PROJECT INVITATIONS
  // ==========================================================

  late final ProjectInvitationController _projectInvitationController;

  // ==========================================================
  // SUPABASE
  // ==========================================================

  final SupabaseClient _supabase = Supabase.instance.client;

  // ==========================================================
  // CALL REPOSITORY
  // ==========================================================

  final ProjectCallRepositoryImpl _callRepository = ProjectCallRepositoryImpl();

  // ==========================================================
  // GLOBAL CALL STATE
  // ==========================================================

  bool _isGlobalCallActionProcessing = false;

  String? _globalCallAction;

  // ==========================================================
  // LEAVE PROJECT
  // ==========================================================

  bool _isLeavingProject = false;

  // ==========================================================
  // PARTICIPANT NAME CACHE
  // ==========================================================

  final Map<
    String,
    String
  >
  _callParticipantNameCache =
      <
        String,
        String
      >{};

  // ==========================================================
  // CHAT SENDER NAME CACHE
  // ==========================================================

  final Map<
    String,
    String
  >
  _chatSenderNameCache =
      <
        String,
        String
      >{};

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _controller = NetworkingController(
      projectId: widget.projectId,
    )..initSession();

    _globalChatController = GlobalChatController(
      projectId: widget.projectId,
    )..init();

    _projectInvitationController =
        sl<
          ProjectInvitationController
        >();

    _projectInvitationController.init();
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: const Color(
        0xFF0F0F0F,
      ),

      appBar: AppBar(
        title: const Text(
          'Studio Session',
          style: TextStyle(
            fontSize: 16,
          ),
        ),

        backgroundColor: Colors.transparent,

        elevation: 0,
      ),

      body: Stack(
        children: [
          // ====================================================
          // CONTEÚDO DA SESSÃO
          // ====================================================
          Positioned.fill(
            child: ListenableBuilder(
              listenable: _controller,

              builder:
                  (
                    context,
                    _,
                  ) {
                    if (_controller.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final projectHash =
                        widget.projectId.length >=
                            8
                        ? widget.projectId
                              .substring(
                                0,
                                8,
                              )
                              .toUpperCase()
                        : widget.projectId.toUpperCase();

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                      ),

                      child: Column(
                        children: [
                          _buildHeader(
                            projectHash,
                          ),

                          const SizedBox(
                            height: 25,
                          ),

                          Wrap(
                            spacing: 15,

                            runSpacing: 20,

                            alignment: WrapAlignment.center,

                            children: [
                              _buildSmallAction(
                                Icons.chat_bubble_rounded,

                                'Chat',

                                Colors.blue,

                                _openChatPage,
                              ),

                              _buildSmallAction(
                                Icons.call_rounded,

                                'Ligar',

                                Colors.green,

                                () => _openCallPage(),
                              ),

                              _buildSmallAction(
                                Icons.edit_document,

                                'Doc',

                                Colors.amber,

                                () => _openPage(
                                  ContractView(
                                    projectId: widget.projectId,
                                  ),
                                ),
                              ),

                              _buildSmallAction(
                                Icons.percent_rounded,

                                'Royalties',

                                Colors.pink,

                                () => _openPage(
                                  RoyaltiesView(
                                    projectId: widget.projectId,
                                  ),
                                ),
                              ),

                              _buildSmallAction(
                                Icons.person_add_alt_1_rounded,

                                'Membros',

                                Colors.orange,

                                () => _openPage(
                                  MembersView(
                                    projectId: widget.projectId,
                                  ),
                                ),
                              ),

                              _buildSmallAction(
                                Icons.task_alt_rounded,

                                'Tarefas',

                                Colors.teal,

                                () => _openPage(
                                  TasksView(
                                    projectId: widget.projectId,
                                  ),
                                ),
                              ),

                              _buildSmallAction(
                                Icons.logout_rounded,

                                'Sair',

                                Colors.red,

                                _requestLeaveProject,
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
            ),
          ),

          // ====================================================
          // GLOBAL CALL BANNER
          // ====================================================
          //
          // Fica acima da Studio Session.
          //
          // Assim o usuário continua vendo a chamada mesmo
          // depois de sair da página "Ligar".
          //
          // ====================================================
          Positioned(
            top: 0,

            left: 0,

            right: 0,

            child: Column(
              mainAxisSize: MainAxisSize.min,

              children: [
                _buildGlobalProjectInvitationBanner(),
                _buildGlobalCallBanner(),
                _buildGlobalChatBanner(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // GLOBAL PROJECT INVITATION BANNER
  // ==========================================================

  Widget _buildGlobalProjectInvitationBanner() {
    return ListenableBuilder(
      listenable: _projectInvitationController,

      builder:
          (
            context,
            _,
          ) {
            final invitation = _projectInvitationController.currentInvitation;

            if (invitation ==
                null) {
              return const SizedBox.shrink();
            }

            return ProjectInvitationBanner(
              invitation: invitation,

              isAccepting: _projectInvitationController.isAccepting,

              isRejecting: _projectInvitationController.isRejecting,

              onAccept: () async {
                await _acceptProjectInvitation(
                  invitation,
                );
              },

              onReject: () async {
                await _rejectProjectInvitation(
                  invitation,
                );
              },
            );
          },
    );
  }

  // ==========================================================
  // ACCEPT PROJECT INVITATION
  // ==========================================================

  Future<
    void
  >
  _acceptProjectInvitation(
    ProjectInvitationModel invitation,
  ) async {
    if (!mounted ||
        _projectInvitationController.isBusy) {
      return;
    }

    final projectId = await _projectInvitationController.acceptInvitation(
      invitation,
    );

    if (!mounted) {
      return;
    }

    if (projectId ==
            null ||
        projectId.trim().isEmpty) {
      _showProjectInvitationMessage(
        _projectInvitationController.errorMessage ??
            'Não foi possível aceitar o convite.',
        error: true,
      );

      return;
    }

    _showProjectInvitationMessage(
      'Você entrou em ${invitation.projectTitle}.',
    );

    final normalizedProjectId = projectId.trim();

    // ========================================================
    // MESMA SESSÃO
    // ========================================================
    //
    // Se por algum motivo o convite aceito for para a sessão
    // atualmente aberta, basta atualizar o controller atual.
    //
    // ========================================================

    if (normalizedProjectId ==
        widget.projectId.trim()) {
      _controller.initSession();

      return;
    }

    // ========================================================
    // OUTRA STUDIO SESSION
    // ========================================================

    await Navigator.of(
      context,
    ).push(
      MaterialPageRoute(
        builder:
            (
              _,
            ) {
              return NetworkingSessionView(
                projectId: normalizedProjectId,
              );
            },
      ),
    );
  }

  // ==========================================================
  // REJECT PROJECT INVITATION
  // ==========================================================

  Future<
    void
  >
  _rejectProjectInvitation(
    ProjectInvitationModel invitation,
  ) async {
    if (!mounted ||
        _projectInvitationController.isBusy) {
      return;
    }

    final rejected = await _projectInvitationController.rejectInvitation(
      invitation,
    );

    if (!mounted) {
      return;
    }

    if (!rejected) {
      _showProjectInvitationMessage(
        _projectInvitationController.errorMessage ??
            'Não foi possível recusar o convite.',
        error: true,
      );

      return;
    }

    _showProjectInvitationMessage(
      'Convite recusado.',
    );
  }

  // ==========================================================
  // PROJECT INVITATION MESSAGE
  // ==========================================================

  void _showProjectInvitationMessage(
    String message, {
    bool error = false,
  }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
        context,
      )
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
          ),

          backgroundColor: error
              ? const Color(
                  0xFF3B1218,
                )
              : const Color(
                  0xFF15151D,
                ),

          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ==========================================================
  // GLOBAL CHAT BANNER
  // ==========================================================

  Widget _buildGlobalChatBanner() {
    return ListenableBuilder(
      listenable: _globalChatController,

      builder:
          (
            context,
            _,
          ) {
            if (!_globalChatController.hasNotification) {
              return const SizedBox.shrink();
            }

            final latestMessage = _globalChatController.latestMessage;

            if (latestMessage ==
                null) {
              return const SizedBox.shrink();
            }

            final senderId = latestMessage.senderId.trim();

            return FutureBuilder<
              String
            >(
              future: _resolveChatSenderName(
                senderId,
              ),

              builder:
                  (
                    context,
                    snapshot,
                  ) {
                    final resolvedName =
                        snapshot.data ??
                        _chatSenderNameCache[senderId] ??
                        _globalChatController.senderName;

                    return GlobalChatBanner(
                      type: _globalChatController.latestIsAudio
                          ? GlobalChatBannerType.audio
                          : GlobalChatBannerType.message,

                      senderName: resolvedName,

                      preview: _globalChatController.preview,

                      unreadCount: _globalChatController.unreadCount,

                      onOpen: _openChatPage,

                      onDismiss: _globalChatController.dismissBanner,
                    );
                  },
            );
          },
    );
  }

  // ==========================================================
  // RESOLVE CHAT SENDER NAME
  // ==========================================================

  Future<
    String
  >
  _resolveChatSenderName(
    String userId,
  ) async {
    final normalizedUserId = userId.trim();

    if (normalizedUserId.isEmpty) {
      return _globalChatController.senderName;
    }

    final cached = _chatSenderNameCache[normalizedUserId];

    if (cached !=
            null &&
        cached.isNotEmpty) {
      return cached;
    }

    try {
      final profile = await _supabase
          .from(
            'profiles',
          )
          .select(
            'id, artist_name, name, username',
          )
          .eq(
            'id',
            normalizedUserId,
          )
          .maybeSingle();

      if (profile ==
          null) {
        return _globalChatController.senderName;
      }

      final artistName = profile['artist_name']?.toString().trim();

      if (artistName !=
              null &&
          artistName.isNotEmpty) {
        _chatSenderNameCache[normalizedUserId] = artistName;

        return artistName;
      }

      final name = profile['name']?.toString().trim();

      if (name !=
              null &&
          name.isNotEmpty) {
        _chatSenderNameCache[normalizedUserId] = name;

        return name;
      }

      final username = profile['username']?.toString().trim().replaceFirst(
        RegExp(
          r'^@+',
        ),
        '',
      );

      if (username !=
              null &&
          username.isNotEmpty) {
        final usernameLabel = '@$username';

        _chatSenderNameCache[normalizedUserId] = usernameLabel;

        return usernameLabel;
      }
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[NETWORKING SESSION] '
        'Erro ao buscar nome do remetente do chat: '
        '$error',
      );

      debugPrint(
        '$stackTrace',
      );
    }

    final controllerName = _globalChatController.senderName.trim();

    if (controllerName.isNotEmpty &&
        controllerName !=
            'Membro') {
      return controllerName;
    }

    return 'Membro';
  }

  // ==========================================================
  // OPEN CHAT
  // ==========================================================

  Future<
    void
  >
  _openChatPage() async {
    if (!mounted) {
      return;
    }

    _globalChatController.markAsRead();

    _globalChatController.setChatVisible(
      true,
    );

    try {
      await Navigator.of(
        context,
      ).push(
        MaterialPageRoute(
          builder:
              (
                _,
              ) => ChatView(
                projectId: widget.projectId,
              ),
        ),
      );
    } finally {
      if (!_globalChatController.chatVisible) {
        return;
      }

      _globalChatController.setChatVisible(
        false,
      );
    }
  }

  // ==========================================================
  // REQUEST LEAVE PROJECT
  // ==========================================================
  //
  // Exibe uma confirmação explícita antes de remover o usuário
  // da Studio Session.
  //
  // O botão permanece bloqueado até o usuário marcar o checkbox.
  //
  // ==========================================================

  Future<
    void
  >
  _requestLeaveProject() async {
    if (_isLeavingProject ||
        !mounted) {
      return;
    }

    final shouldLeave =
        await showDialog<
          bool
        >(
          context: context,
          barrierDismissible: false,
          builder:
              (
                dialogContext,
              ) {
                var confirmed = false;

                return StatefulBuilder(
                  builder:
                      (
                        context,
                        setDialogState,
                      ) {
                        return AlertDialog(
                          backgroundColor: const Color(
                            0xFF17171E,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              20,
                            ),
                          ),
                          title: const Row(
                            children: [
                              Icon(
                                Icons.logout_rounded,
                                color: Colors.redAccent,
                                size: 22,
                              ),
                              SizedBox(
                                width: 10,
                              ),
                              Expanded(
                                child: Text(
                                  'Sair desta Studio Session?',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Ao continuar, você deixará de fazer parte '
                                'deste projeto e ele não aparecerá mais entre '
                                'os seus projetos ativos.',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12,
                                  height: 1.45,
                                ),
                              ),
                              const SizedBox(
                                height: 14,
                              ),
                              Container(
                                padding: const EdgeInsets.all(
                                  12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withValues(
                                    alpha: 0.06,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    14,
                                  ),
                                  border: Border.all(
                                    color: Colors.redAccent.withValues(
                                      alpha: 0.14,
                                    ),
                                  ),
                                ),
                                child: const Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.info_outline_rounded,
                                      color: Colors.redAccent,
                                      size: 17,
                                    ),
                                    SizedBox(
                                      width: 9,
                                    ),
                                    Expanded(
                                      child: Text(
                                        'Você perderá o acesso à sessão, '
                                        'ao chat, às tarefas e aos recursos '
                                        'compartilhados deste projeto.',
                                        style: TextStyle(
                                          color: Colors.white54,
                                          fontSize: 10,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(
                                height: 14,
                              ),
                              CheckboxListTile(
                                value: confirmed,
                                onChanged:
                                    (
                                      value,
                                    ) {
                                      setDialogState(
                                        () {
                                          confirmed =
                                              value ??
                                              false;
                                        },
                                      );
                                    },
                                contentPadding: EdgeInsets.zero,
                                controlAffinity: ListTileControlAffinity.leading,
                                activeColor: Colors.redAccent,
                                title: const Text(
                                  'Estou ciente e quero sair deste projeto.',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(
                                  dialogContext,
                                ).pop(
                                  false,
                                );
                              },
                              child: const Text(
                                'Cancelar',
                              ),
                            ),
                            FilledButton.icon(
                              onPressed: confirmed
                                  ? () {
                                      Navigator.of(
                                        dialogContext,
                                      ).pop(
                                        true,
                                      );
                                    }
                                  : null,
                              icon: const Icon(
                                Icons.logout_rounded,
                                size: 16,
                              ),
                              label: const Text(
                                'Sair do projeto',
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.white12,
                                disabledForegroundColor: Colors.white24,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                );
              },
        );

    if (shouldLeave !=
            true ||
        !mounted) {
      return;
    }

    await _leaveProject();
  }

  // ==========================================================
  // LEAVE PROJECT
  // ==========================================================

  Future<
    void
  >
  _leaveProject() async {
    if (_isLeavingProject) {
      return;
    }

    final userId = _supabase.auth.currentUser?.id.trim();

    final projectId = widget.projectId.trim();

    if (userId ==
            null ||
        userId.isEmpty ||
        projectId.isEmpty) {
      _showProjectInvitationMessage(
        'Não foi possível identificar sua participação '
        'neste projeto.',
        error: true,
      );

      return;
    }

    setState(
      () {
        _isLeavingProject = true;
      },
    );

    try {
      // ========================================================
      // SAIR DO PROJETO VIA RPC
      // ========================================================
      //
      // A remoção de members / founders é feita no Supabase
      // pela função:
      //
      // public.leave_match_project(uuid)
      //
      // Isso evita conflito com as políticas RLS da tabela
      // projects e centraliza a regra de negócio no banco.
      //
      // ========================================================

      await _supabase.rpc(
        'leave_match_project',
        params: {
          'p_project_id': projectId,
        },
      );

      debugPrint(
        '[NETWORKING SESSION] '
        'Usuário $userId saiu do projeto $projectId.',
      );

      // ========================================================
      // ATUALIZAR DASHBOARD
      // ========================================================

      await _refreshDashboardActiveProject();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
          context,
        )
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Você saiu da Studio Session.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );

      // ========================================================
      // FECHAR SESSÃO
      // ========================================================

      Navigator.of(
        context,
      ).pop(
        true,
      );
    } on PostgrestException catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[NETWORKING SESSION] '
        'Erro Supabase ao sair do projeto: '
        '${error.message}',
      );

      debugPrint(
        '[NETWORKING SESSION] '
        'Código: ${error.code}',
      );

      debugPrint(
        '$stackTrace',
      );

      if (mounted) {
        _showProjectInvitationMessage(
          _leaveProjectErrorMessage(
            error,
          ),
          error: true,
        );
      }
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[NETWORKING SESSION] '
        'Erro ao sair do projeto: $error',
      );

      debugPrint(
        '$stackTrace',
      );

      if (mounted) {
        _showProjectInvitationMessage(
          'Não foi possível sair do projeto. '
          'Tente novamente.',
          error: true,
        );
      }
    } finally {
      if (mounted) {
        setState(
          () {
            _isLeavingProject = false;
          },
        );
      }
    }
  }

  // ==========================================================
  // LEAVE PROJECT ERROR MESSAGE
  // ==========================================================

  String _leaveProjectErrorMessage(
    PostgrestException error,
  ) {
    final message = error.message.trim().toLowerCase();

    if (message.contains(
          'projeto não encontrado',
        ) ||
        message.contains(
          'projeto nao encontrado',
        )) {
      return 'Este projeto não está mais disponível.';
    }

    if (message.contains(
          'usuário não pertence',
        ) ||
        message.contains(
          'usuario nao pertence',
        )) {
      return 'Você já não faz parte deste projeto.';
    }

    if (message.contains(
          'não autenticado',
        ) ||
        message.contains(
          'nao autenticado',
        )) {
      return 'Sua sessão expirou. '
          'Entre novamente para continuar.';
    }

    return 'Não foi possível sair do projeto. '
        'Tente novamente.';
  }

  // ==========================================================
  // REFRESH DASHBOARD ACTIVE PROJECT
  // ==========================================================

  Future<
    void
  >
  _refreshDashboardActiveProject() async {
    try {
      final dashboardController =
          sl<
            DashboardController
          >();

      await dashboardController.refreshActiveProject();
    } catch (
      error,
      stackTrace
    ) {
      // A saída do projeto não deve falhar somente porque o
      // Dashboard não conseguiu atualizar o card imediatamente.
      debugPrint(
        '[NETWORKING SESSION] '
        'Não foi possível atualizar projeto ativo '
        'no Dashboard: $error',
      );

      debugPrint(
        '$stackTrace',
      );
    }
  }

  // ==========================================================
  // HEADER
  // ==========================================================

  Widget _buildHeader(
    String projectHash,
  ) {
    return Container(
      padding: const EdgeInsets.all(
        16,
      ),

      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.shade900,
            Colors.black,
          ],
        ),

        borderRadius: BorderRadius.circular(
          20,
        ),
      ),

      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.white24,

            child: Icon(
              Icons.music_note,
              color: Colors.white,
            ),
          ),

          const SizedBox(
            width: 15,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                const Text(
                  'Conectados via match',

                  style: TextStyle(
                    color: Colors.white,

                    fontWeight: FontWeight.bold,
                  ),
                ),

                Text(
                  'Hash: #$projectHash',

                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // GLOBAL CALL BANNER
  // ==========================================================

  Widget _buildGlobalCallBanner() {
    final currentUserId = _supabase.auth.currentUser?.id.trim();

    if (currentUserId ==
            null ||
        currentUserId.isEmpty) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<
      List<
        Map<
          String,
          dynamic
        >
      >
    >(
      stream: _supabase
          .from(
            'project_calls',
          )
          .stream(
            primaryKey: [
              'id',
            ],
          )
          .order(
            'created_at',
            ascending: false,
          ),

      builder:
          (
            context,
            snapshot,
          ) {
            final rows =
                snapshot.data ??
                const <
                  Map<
                    String,
                    dynamic
                  >
                >[];

            Map<
              String,
              dynamic
            >?
            activeRow;

            for (final row in rows) {
              // ==================================================
              // MESMO PROJETO
              // ==================================================

              final rowProjectId = row['project_id']?.toString().trim();

              if (rowProjectId !=
                  widget.projectId.trim()) {
                continue;
              }

              // ==================================================
              // STATUS
              // ==================================================

              final status = row['status']?.toString().trim();

              if (status !=
                      'ringing' &&
                  status !=
                      'active') {
                continue;
              }

              // ==================================================
              // PARTICIPANTES
              // ==================================================

              final createdBy = row['created_by']?.toString().trim();

              final targetUserId = row['target_user_id']?.toString().trim();

              final directlyInvolved =
                  createdBy ==
                      currentUserId ||
                  targetUserId ==
                      currentUserId;

              final groupCall =
                  targetUserId ==
                      null ||
                  targetUserId.isEmpty;

              if (!directlyInvolved &&
                  !groupCall) {
                continue;
              }

              activeRow = row;

              break;
            }

            if (activeRow ==
                null) {
              return const SizedBox.shrink();
            }

            return _buildGlobalCallBannerFromRow(
              activeRow,
              currentUserId,
            );
          },
    );
  }

  // ==========================================================
  // GLOBAL CALL FROM ROW
  // ==========================================================

  Widget _buildGlobalCallBannerFromRow(
    Map<
      String,
      dynamic
    >
    row,
    String currentUserId,
  ) {
    final callId =
        row['id']?.toString().trim() ??
        '';

    final createdBy =
        row['created_by']?.toString().trim() ??
        '';

    final targetUserId = row['target_user_id']?.toString().trim();

    final status =
        row['status']?.toString().trim() ??
        '';

    // ========================================================
    // MEDIA TYPE
    // ========================================================

    final mediaTypeValue =
        row['media_type']?.toString().trim().toLowerCase() ??
        'audio';

    final bannerMediaType =
        mediaTypeValue ==
            'video'
        ? GlobalCallMediaType.video
        : GlobalCallMediaType.audio;

    // ========================================================
    // CALL DIRECTION
    // ========================================================

    final incoming =
        status ==
            'ringing' &&
        createdBy !=
            currentUserId &&
        (targetUserId ==
                currentUserId ||
            targetUserId ==
                null ||
            targetUserId.isEmpty);

    final outgoing =
        status ==
            'ringing' &&
        createdBy ==
            currentUserId;

    final active =
        status ==
        'active';

    // ========================================================
    // BANNER STATE
    // ========================================================

    GlobalCallBannerState state = GlobalCallBannerState.hidden;

    if (_isGlobalCallActionProcessing &&
        _globalCallAction ==
            'end') {
      state = GlobalCallBannerState.ending;
    } else if (incoming) {
      state = GlobalCallBannerState.incoming;
    } else if (outgoing) {
      state = GlobalCallBannerState.calling;
    } else if (active) {
      state = GlobalCallBannerState.active;
    }

    // ========================================================
    // DURATION
    // ========================================================

    final startedAt = DateTime.tryParse(
      row['started_at']?.toString() ??
          '',
    );

    final duration =
        startedAt ==
                null ||
            !active
        ? null
        : DateTime.now().toUtc().difference(
            startedAt.toUtc(),
          );

    // ========================================================
    // REMOTE PARTICIPANT
    // ========================================================

    final participantUserId = _resolveCallParticipantUserId(
      createdBy: createdBy,

      targetUserId: targetUserId,

      currentUserId: currentUserId,
    );

    // ========================================================
    // NAME
    // ========================================================

    return FutureBuilder<
      String
    >(
      future: _resolveCallParticipantName(
        participantUserId,
      ),

      builder:
          (
            context,
            snapshot,
          ) {
            final participantName =
                snapshot.data ??
                _callParticipantNameCache[participantUserId] ??
                'Membro da sessão';

            return GlobalCallBanner(
              state: state,

              mediaType: bannerMediaType,

              participantName: participantName,

              duration: duration,

              // ================================================
              // OPEN FULL CALL
              // ================================================
              onOpen: () {
                _openCallPage(
                  participantName: participantName,
                );
              },

              // ================================================
              // ACCEPT
              // ================================================
              onAccept:
                  incoming &&
                      callId.isNotEmpty
                  ? () {
                      _acceptGlobalCall(
                        callId,
                        participantName,
                      );
                    }
                  : null,

              // ================================================
              // REJECT
              // ================================================
              onReject:
                  incoming &&
                      callId.isNotEmpty
                  ? () {
                      _rejectGlobalCall(
                        callId,
                      );
                    }
                  : null,

              // ================================================
              // END
              // ================================================
              onEnd:
                  (outgoing ||
                          active) &&
                      callId.isNotEmpty
                  ? () {
                      _endGlobalCall(
                        callId,
                      );
                    }
                  : null,
            );
          },
    );
  }

  // ==========================================================
  // RESOLVE OTHER PARTICIPANT ID
  // ==========================================================

  String _resolveCallParticipantUserId({
    required String createdBy,
    required String? targetUserId,
    required String currentUserId,
  }) {
    final normalizedCreatedBy = createdBy.trim();

    final normalizedTargetUserId = targetUserId?.trim();

    if (normalizedCreatedBy ==
        currentUserId) {
      if (normalizedTargetUserId !=
              null &&
          normalizedTargetUserId.isNotEmpty) {
        return normalizedTargetUserId;
      }

      return '';
    }

    return normalizedCreatedBy;
  }

  // ==========================================================
  // RESOLVE PARTICIPANT NAME
  // ==========================================================

  Future<
    String
  >
  _resolveCallParticipantName(
    String userId,
  ) async {
    final normalizedUserId = userId.trim();

    if (normalizedUserId.isEmpty) {
      return 'Membro da sessão';
    }

    final cached = _callParticipantNameCache[normalizedUserId];

    if (cached !=
            null &&
        cached.isNotEmpty) {
      return cached;
    }

    try {
      final profile = await _supabase
          .from(
            'profiles',
          )
          .select(
            'id, artist_name, name, username',
          )
          .eq(
            'id',
            normalizedUserId,
          )
          .maybeSingle();

      if (profile ==
          null) {
        return 'Membro da sessão';
      }

      // ======================================================
      // ARTIST NAME
      // ======================================================

      final artistName = profile['artist_name']?.toString().trim();

      if (artistName !=
              null &&
          artistName.isNotEmpty) {
        _callParticipantNameCache[normalizedUserId] = artistName;

        return artistName;
      }

      // ======================================================
      // NAME
      // ======================================================

      final name = profile['name']?.toString().trim();

      if (name !=
              null &&
          name.isNotEmpty) {
        _callParticipantNameCache[normalizedUserId] = name;

        return name;
      }

      // ======================================================
      // USERNAME
      // ======================================================

      final username = profile['username']?.toString().trim().replaceFirst(
        RegExp(
          r'^@+',
        ),
        '',
      );

      if (username !=
              null &&
          username.isNotEmpty) {
        final usernameLabel = '@$username';

        _callParticipantNameCache[normalizedUserId] = usernameLabel;

        return usernameLabel;
      }
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[NETWORKING SESSION] '
        'Erro ao buscar nome do participante: '
        '$error',
      );

      debugPrint(
        '$stackTrace',
      );
    }

    return 'Membro da sessão';
  }

  // ==========================================================
  // OPEN CALL
  // ==========================================================

  Future<
    void
  >
  _openCallPage({
    String? participantName,
  }) async {
    if (!mounted) {
      return;
    }

    await Navigator.of(
      context,
    ).push(
      MaterialPageRoute(
        builder:
            (
              _,
            ) => CallView(
              projectId: widget.projectId,

              participantName: participantName,
            ),
      ),
    );
  }

  // ==========================================================
  // ACCEPT GLOBAL CALL
  // ==========================================================

  Future<
    void
  >
  _acceptGlobalCall(
    String callId,
    String participantName,
  ) async {
    if (_isGlobalCallActionProcessing) {
      return;
    }

    _setGlobalCallProcessing(
      true,
      'accept',
    );

    try {
      await _callRepository.acceptCall(
        callId: callId,
      );

      if (!mounted) {
        return;
      }

      await _openCallPage(
        participantName: participantName,
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[NETWORKING SESSION] '
        'Erro ao aceitar chamada: '
        '$error',
      );

      debugPrint(
        '$stackTrace',
      );
    } finally {
      _setGlobalCallProcessing(
        false,
        null,
      );
    }
  }

  // ==========================================================
  // REJECT GLOBAL CALL
  // ==========================================================

  Future<
    void
  >
  _rejectGlobalCall(
    String callId,
  ) async {
    if (_isGlobalCallActionProcessing) {
      return;
    }

    _setGlobalCallProcessing(
      true,
      'reject',
    );

    try {
      await _callRepository.rejectCall(
        callId: callId,
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[NETWORKING SESSION] '
        'Erro ao recusar chamada: '
        '$error',
      );

      debugPrint(
        '$stackTrace',
      );
    } finally {
      _setGlobalCallProcessing(
        false,
        null,
      );
    }
  }

  // ==========================================================
  // END GLOBAL CALL
  // ==========================================================

  Future<
    void
  >
  _endGlobalCall(
    String callId,
  ) async {
    if (_isGlobalCallActionProcessing) {
      return;
    }

    _setGlobalCallProcessing(
      true,
      'end',
    );

    try {
      await _callRepository.endCall(
        callId: callId,
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[NETWORKING SESSION] '
        'Erro ao encerrar chamada: '
        '$error',
      );

      debugPrint(
        '$stackTrace',
      );
    } finally {
      _setGlobalCallProcessing(
        false,
        null,
      );
    }
  }

  // ==========================================================
  // PROCESSING
  // ==========================================================

  void _setGlobalCallProcessing(
    bool value,
    String? action,
  ) {
    if (!mounted) {
      return;
    }

    setState(
      () {
        _isGlobalCallActionProcessing = value;

        _globalCallAction = action;
      },
    );
  }

  // ==========================================================
  // OPEN PAGE
  // ==========================================================

  void _openPage(
    Widget page,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (
              _,
            ) => page,
      ),
    );
  }

  // ==========================================================
  // SMALL ACTION
  // ==========================================================

  Widget _buildSmallAction(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,

      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(
              12,
            ),

            decoration: BoxDecoration(
              color: color.withValues(
                alpha: 0.1,
              ),

              shape: BoxShape.circle,

              border: Border.all(
                color: color.withValues(
                  alpha: 0.3,
                ),
              ),
            ),

            child: Icon(
              icon,
              size: 22,
              color: color,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          Text(
            label,

            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    // ProjectInvitationController é global (GetIt LazySingleton).
    // Não deve ser disposed por esta tela.

    _globalChatController.dispose();

    _controller.dispose();

    super.dispose();
  }
}
