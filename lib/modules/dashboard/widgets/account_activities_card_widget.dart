import 'package:flutter/material.dart';

import 'package:versin/app/locator.dart';
import 'package:versin/app/routes/app_routes.dart';

import 'package:versin/modules/activities/controllers/recent_activity_controller.dart';
import 'package:versin/modules/activities/views/recent_activities_page.dart';
import 'package:versin/modules/activities/widgets/recent_activities_card_widget.dart';
import 'package:versin/modules/calendar/views/calendar_page.dart';
import 'package:versin/modules/notifications/widgets/notification_button_widget.dart';
import 'package:versin/modules/profile/controllers/professional_profile_controller.dart';
import 'package:versin/modules/match/views/match_projects_view.dart';

import 'package:versin/modules/networking/invitations/controllers/project_invitation_controller.dart';
import 'package:versin/modules/networking/invitations/models/project_invitation_model.dart';
import 'package:versin/modules/networking/views/networking_session_view.dart';

import '../controllers/dashboard_controller.dart';

// ============================================================
// ACCOUNT ACTIVITIES CARD WIDGET
// ============================================================
//
// Card principal do perfil exibido no Dashboard.
//
// Responsabilidades:
//
// - exibir avatar;
// - exibir nome artístico;
// - exibir função profissional principal;
// - acessar contratos;
// - acessar calendário;
// - acessar notificações;
// - exibir as 3 atividades mais recentes;
// - permitir acessar o histórico mensal;
// - permitir expandir/recolher o card.
//
// ============================================================

class AccountActivitiesCardWidget
    extends
        StatefulWidget {
  // ============================================================
  // DEPENDÊNCIAS
  // ============================================================

  final DashboardController controller;

  final VoidCallback onStateChanged;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  const AccountActivitiesCardWidget({
    super.key,
    required this.controller,
    required this.onStateChanged,
  });

  @override
  State<
    AccountActivitiesCardWidget
  >
  createState() => _AccountActivitiesCardWidgetState();
}

// ============================================================
// STATE
// ============================================================

class _AccountActivitiesCardWidgetState
    extends
        State<
          AccountActivitiesCardWidget
        > {
  // ============================================================
  // PROFILE CONTROLLER
  // ============================================================

  late final ProfessionalProfileController _profileController;

  // ============================================================
  // ACTIVITY CONTROLLER
  // ============================================================

  late final RecentActivityController _activityController;

  late final ProjectInvitationController _projectInvitationController;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _profileController =
        sl<
          ProfessionalProfileController
        >();

    _activityController =
        sl<
          RecentActivityController
        >();

    _projectInvitationController =
        sl<
          ProjectInvitationController
        >();

    _projectInvitationController.init();

    _profileController.load();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return AnimatedBuilder(
      animation: Listenable.merge(
        [
          widget.controller,
          _profileController,
          _activityController,
          _projectInvitationController,
        ],
      ),
      builder:
          (
            context,
            _,
          ) {
            return Container(
              padding: const EdgeInsets.all(
                20,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(
                      0xFF1F1A3A,
                    ),
                    Color(
                      0xFF0D0B1F,
                    ),
                  ],
                ),
                borderRadius: BorderRadius.circular(
                  24,
                ),
                border: Border.all(
                  color: Colors.white.withValues(
                    alpha: 0.05,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ==================================================
                  // EXPANDIR / RECOLHER
                  // ==================================================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () {
                          widget.controller.toggleProfileCard();

                          widget.onStateChanged();
                        },
                        child: Icon(
                          widget.controller.isProfileCardExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: Colors.white54,
                          size: 22,
                        ),
                      ),
                    ],
                  ),

                  // ==================================================
                  // AVATAR
                  // ==================================================
                  GestureDetector(
                    onTap: widget.controller.pickProfileImage,
                    child: CircleAvatar(
                      radius: 36,
                      backgroundColor: const Color(
                        0xFFFFCC80,
                      ),
                      backgroundImage:
                          widget.controller.profileImagePath !=
                              null
                          ? NetworkImage(
                              widget.controller.profileImagePath!,
                            )
                          : null,
                      child:
                          widget.controller.profileImagePath ==
                              null
                          ? const Icon(
                              Icons.person,
                              color: Color(
                                0xFF2E1A47,
                              ),
                              size: 40,
                            )
                          : null,
                    ),
                  ),

                  const SizedBox(
                    height: 14,
                  ),

                  // ==================================================
                  // NOME ARTÍSTICO
                  // ==================================================
                  Text(
                    widget.controller.artistName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  // ==================================================
                  // FUNÇÃO PROFISSIONAL PRINCIPAL
                  // ==================================================
                  if (_profileController.isLoading)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: Colors.white38,
                      ),
                    )
                  else
                    Text(
                      _profileController.primaryRoleLabel,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                  const SizedBox(
                    height: 20,
                  ),

                  // ==================================================
                  // AÇÕES
                  // ==================================================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ==================================================
                      // CONTRATOS
                      // ==================================================
                      _buildCircularActionIcon(
                        context,
                        Icons.description_outlined,
                        route: AppRoutes.contracts,
                      ),

                      const SizedBox(
                        width: 16,
                      ),

                      // ==================================================
                      // CALENDÁRIO
                      // ==================================================
                      _buildCircularActionIcon(
                        context,
                        Icons.calendar_today_outlined,
                        onTap: () {
                          _openCalendarPage(
                            context,
                          );
                        },
                      ),

                      const SizedBox(
                        width: 16,
                      ),

                      // ==================================================
                      // CONVITES DE PROJETO
                      // ==================================================
                      _buildProjectInvitationButton(
                        context,
                      ),

                      const SizedBox(
                        width: 16,
                      ),

                      // ==================================================
                      // PROJETOS ATIVOS
                      // ==================================================
                      _buildCircularActionIcon(
                        context,
                        Icons.workspaces_outline,
                        onTap: () {
                          _openActiveProjectsPage(
                            context,
                          );
                        },
                      ),

                      const SizedBox(
                        width: 16,
                      ),

                      // ==================================================
                      // NOTIFICAÇÕES
                      // ==================================================
                      const NotificationButtonWidget(
                        size: 44,
                      ),
                    ],
                  ),

                  // ==================================================
                  // ATIVIDADES RECENTES
                  // ==================================================
                  if (widget.controller.isProfileCardExpanded) ...[
                    const SizedBox(
                      height: 28,
                    ),

                    RecentActivitiesCardWidget(
                      controller: _activityController,
                      accentColor: widget.controller.accentNeon,
                    ),

                    // ==================================================
                    // VER MAIS
                    // ==================================================
                    if (_activityController.hasActivities) ...[
                      const SizedBox(
                        height: 12,
                      ),

                      _buildViewMoreButton(
                        context,
                      ),
                    ],
                  ],
                ],
              ),
            );
          },
    );
  }

  // ============================================================
  // VER MAIS
  // ============================================================

  Widget _buildViewMoreButton(
    BuildContext context,
  ) {
    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(
            12,
          ),
          onTap: () {
            _openActivitiesPage(
              context,
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 7,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'VER MAIS',
                  style: TextStyle(
                    color: widget.controller.accentNeon,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                  ),
                ),

                const SizedBox(
                  width: 5,
                ),

                Icon(
                  Icons.arrow_forward_rounded,
                  color: widget.controller.accentNeon,
                  size: 13,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BOTÃO DE CONVITES DE PROJETO
  // ============================================================

  Widget _buildProjectInvitationButton(
    BuildContext context,
  ) {
    final count = _projectInvitationController.pendingCount;

    return Tooltip(
      message:
          count >
              0
          ? 'Convites de projetos • $count'
          : 'Convites de projetos',

      child: GestureDetector(
        onTap: () {
          _openProjectInvitations(
            context,
          );
        },

        child: Stack(
          clipBehavior: Clip.none,

          children: [
            Container(
              width: 44,
              height: 44,

              decoration: BoxDecoration(
                color: Colors.white.withValues(
                  alpha: 0.05,
                ),

                shape: BoxShape.circle,

                border: Border.all(
                  color:
                      count >
                          0
                      ? const Color(
                          0xFF8B5CF6,
                        ).withValues(
                          alpha: 0.45,
                        )
                      : Colors.white.withValues(
                          alpha: 0.08,
                        ),
                ),
              ),

              child: Icon(
                Icons.group_add_outlined,
                color:
                    count >
                        0
                    ? const Color(
                        0xFFA78BFA,
                      )
                    : Colors.white70,
                size: 20,
              ),
            ),

            if (count >
                0)
              Positioned(
                top: -4,
                right: -4,

                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),

                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                  ),

                  alignment: Alignment.center,

                  decoration: const BoxDecoration(
                    color: Color(
                      0xFF8B5CF6,
                    ),
                    shape: BoxShape.circle,
                  ),

                  child: Text(
                    count >
                            99
                        ? '99+'
                        : '$count',

                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ABRIR CONVITES
  // ============================================================

  Future<
    void
  >
  _openProjectInvitations(
    BuildContext context,
  ) async {
    if (!_projectInvitationController.initialized) {
      await _projectInvitationController.init();
    }

    if (!mounted) {
      return;
    }

    await showModalBottomSheet<
      void
    >(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,

      builder:
          (
            sheetContext,
          ) {
            return FractionallySizedBox(
              heightFactor: 0.72,

              child: Container(
                decoration: const BoxDecoration(
                  color: Color(
                    0xFF0D0B14,
                  ),

                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(
                      24,
                    ),
                  ),
                ),

                child: SafeArea(
                  top: false,

                  child: Column(
                    children: [
                      const SizedBox(
                        height: 10,
                      ),

                      Container(
                        width: 42,
                        height: 4,

                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(
                            10,
                          ),
                        ),
                      ),

                      const Padding(
                        padding: EdgeInsets.fromLTRB(
                          20,
                          18,
                          20,
                          14,
                        ),

                        child: Row(
                          children: [
                            Icon(
                              Icons.group_add_outlined,
                              color: Color(
                                0xFFA78BFA,
                              ),
                              size: 20,
                            ),

                            SizedBox(
                              width: 10,
                            ),

                            Text(
                              'Convites de projetos',

                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Expanded(
                        child: ListenableBuilder(
                          listenable: _projectInvitationController,

                          builder:
                              (
                                context,
                                _,
                              ) {
                                if (_projectInvitationController.isLoading &&
                                    !_projectInvitationController.hasPendingInvitations) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }

                                final invitations = _projectInvitationController.pendingInvitations;

                                if (invitations.isEmpty) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(
                                        24,
                                      ),

                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,

                                        children: [
                                          Icon(
                                            Icons.mark_email_read_outlined,
                                            color: Colors.white24,
                                            size: 36,
                                          ),

                                          SizedBox(
                                            height: 12,
                                          ),

                                          Text(
                                            'Nenhum convite pendente',

                                            style: TextStyle(
                                              color: Colors.white54,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),

                                          SizedBox(
                                            height: 5,
                                          ),

                                          Text(
                                            'Novos convites para Studio Sessions aparecerão aqui.',

                                            textAlign: TextAlign.center,

                                            style: TextStyle(
                                              color: Colors.white30,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }

                                return ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    0,
                                    16,
                                    24,
                                  ),

                                  itemCount: invitations.length,

                                  separatorBuilder:
                                      (
                                        _,
                                        __,
                                      ) {
                                        return const SizedBox(
                                          height: 10,
                                        );
                                      },

                                  itemBuilder:
                                      (
                                        context,
                                        index,
                                      ) {
                                        return _buildProjectInvitationCard(
                                          sheetContext,
                                          invitations[index],
                                        );
                                      },
                                );
                              },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
    );
  }

  // ============================================================
  // CARD DO CONVITE
  // ============================================================

  Widget _buildProjectInvitationCard(
    BuildContext sheetContext,
    ProjectInvitationModel invitation,
  ) {
    final busy = _projectInvitationController.isBusy;

    return Container(
      padding: const EdgeInsets.all(
        14,
      ),

      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.035,
        ),

        borderRadius: BorderRadius.circular(
          18,
        ),

        border: Border.all(
          color:
              const Color(
                0xFF8B5CF6,
              ).withValues(
                alpha: 0.18,
              ),
        ),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,

                alignment: Alignment.center,

                decoration: BoxDecoration(
                  color:
                      const Color(
                        0xFF8B5CF6,
                      ).withValues(
                        alpha: 0.12,
                      ),

                  borderRadius: BorderRadius.circular(
                    13,
                  ),
                ),

                child: const Icon(
                  Icons.groups_2_outlined,
                  color: Color(
                    0xFFA78BFA,
                  ),
                  size: 20,
                ),
              ),

              const SizedBox(
                width: 11,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      invitation.projectTitle,

                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,

                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(
                      height: 3,
                    ),

                    Text(
                      '${invitation.inviterName} convidou você para participar.',

                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,

                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 13,
          ),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: busy
                      ? null
                      : () async {
                          final rejected = await _projectInvitationController.rejectInvitation(
                            invitation,
                          );

                          if (!mounted ||
                              !rejected) {
                            return;
                          }

                          _showInvitationMessage(
                            'Convite recusado.',
                          );
                        },

                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,

                    side: BorderSide(
                      color: Colors.redAccent.withValues(
                        alpha: 0.30,
                      ),
                    ),

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        12,
                      ),
                    ),
                  ),

                  child: const Text(
                    'Recusar',

                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              Expanded(
                child: FilledButton(
                  onPressed: busy
                      ? null
                      : () async {
                          final projectId = await _projectInvitationController.acceptInvitation(
                            invitation,
                          );

                          if (!mounted ||
                              projectId ==
                                  null ||
                              projectId.trim().isEmpty) {
                            return;
                          }

                          if (sheetContext.mounted) {
                            Navigator.of(
                              sheetContext,
                            ).pop();
                          }

                          _showInvitationMessage(
                            'Você entrou em ${invitation.projectTitle}.',
                          );

                          await Navigator.of(
                            this.context,
                          ).push(
                            MaterialPageRoute<
                              void
                            >(
                              builder:
                                  (
                                    _,
                                  ) {
                                    return NetworkingSessionView(
                                      projectId: projectId.trim(),
                                    );
                                  },
                            ),
                          );
                        },

                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(
                      0xFF8B5CF6,
                    ),
                    foregroundColor: Colors.white,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        12,
                      ),
                    ),
                  ),

                  child: busy
                      ? const SizedBox(
                          width: 14,
                          height: 14,

                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Aceitar',

                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MENSAGEM DE CONVITE
  // ============================================================

  void _showInvitationMessage(
    String message,
  ) {
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

          backgroundColor: const Color(
            0xFF15151D,
          ),

          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // ABRIR PROJETOS ATIVOS
  // ============================================================

  Future<
    void
  >
  _openActiveProjectsPage(
    BuildContext context,
  ) async {
    await Navigator.of(
      context,
    ).push(
      MaterialPageRoute<
        void
      >(
        builder:
            (
              _,
            ) {
              return const MatchProjectsView();
            },
      ),
    );
  }

  // ============================================================
  // ABRIR CALENDÁRIO
  // ============================================================

  Future<
    void
  >
  _openCalendarPage(
    BuildContext context,
  ) async {
    await Navigator.of(
      context,
    ).push(
      MaterialPageRoute<
        void
      >(
        builder:
            (
              context,
            ) {
              return const CalendarPage();
            },
      ),
    );

    if (!mounted) {
      return;
    }

    setState(
      () {},
    );
  }

  // ============================================================
  // ABRIR HISTÓRICO DE ATIVIDADES
  // ============================================================

  Future<
    void
  >
  _openActivitiesPage(
    BuildContext context,
  ) async {
    await Navigator.of(
      context,
    ).push(
      MaterialPageRoute<
        void
      >(
        builder:
            (
              context,
            ) {
              return const RecentActivitiesPage();
            },
      ),
    );
  }

  // ============================================================
  // BOTÃO CIRCULAR
  // ============================================================

  Widget _buildCircularActionIcon(
    BuildContext context,
    IconData icon, {
    String? route,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: () {
        // ======================================================
        // CALLBACK PERSONALIZADO
        // ======================================================

        if (onTap !=
            null) {
          onTap();

          return;
        }

        // ======================================================
        // ROTA
        // ======================================================

        if (route !=
            null) {
          Navigator.of(
            context,
          ).pushNamed(
            route,
          );
        }
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(
            alpha: 0.05,
          ),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(
              alpha: 0.08,
            ),
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white70,
          size: 20,
        ),
      ),
    );
  }

  @override
  void dispose() {
    // O ProjectInvitationController é global (GetIt LazySingleton).
    // Não deve ser disposed por este widget, senão o Realtime
    // deixaria de funcionar ao sair/recriar o Dashboard.

    super.dispose();
  }
}
