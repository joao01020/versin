import 'package:flutter/material.dart';

import 'package:versin/app/locator.dart';
import 'package:versin/app/routes/app_routes.dart';

import 'package:versin/modules/activities/controllers/recent_activity_controller.dart';
import 'package:versin/modules/activities/views/recent_activities_page.dart';
import 'package:versin/modules/activities/widgets/recent_activities_card_widget.dart';
import 'package:versin/modules/notifications/widgets/notification_button_widget.dart';
import 'package:versin/modules/profile/controllers/professional_profile_controller.dart';

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
                        route: AppRoutes.calendar,
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
}
