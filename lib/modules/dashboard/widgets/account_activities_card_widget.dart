import 'package:flutter/material.dart';

import 'package:versin/app/locator.dart';
import 'package:versin/app/routes/app_routes.dart';
import 'package:versin/modules/profile/controllers/professional_profile_controller.dart';

import '../controllers/dashboard_controller.dart';

class AccountActivitiesCardWidget
    extends
        StatefulWidget {
  final DashboardController controller;

  final VoidCallback onStateChanged;

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

class _AccountActivitiesCardWidgetState
    extends
        State<
          AccountActivitiesCardWidget
        > {
  late final ProfessionalProfileController _profileController;

  @override
  void initState() {
    super.initState();

    _profileController =
        sl<
          ProfessionalProfileController
        >();

    _profileController.load();
  }

  // ============================================================
  // NOTIFICAÇÕES
  // ============================================================

  void _showNotificationsModal(
    BuildContext context,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (
            context,
          ) => Container(
            height:
                MediaQuery.of(
                  context,
                ).size.height *
                0.6,
            decoration: const BoxDecoration(
              color: Color(
                0xFF1F1A3A,
              ),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(
                  24,
                ),
              ),
            ),
            padding: const EdgeInsets.all(
              20,
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  color: Colors.white.withValues(
                    alpha: 0.24,
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                const Text(
                  'NOTIFICAÇÕES',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                const Expanded(
                  child: Center(
                    child: Text(
                      'Nenhuma notificação nova.',
                      style: TextStyle(
                        color: Colors.white54,
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
                  // EXPANDIR
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
                  // FUNÇÃO PROFISSIONAL
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
                      _buildCircularActionIcon(
                        context,
                        Icons.description_outlined,
                        route: AppRoutes.contracts,
                      ),
                      const SizedBox(
                        width: 16,
                      ),
                      _buildCircularActionIcon(
                        context,
                        Icons.calendar_today_outlined,
                        route: AppRoutes.calendar,
                      ),
                      const SizedBox(
                        width: 16,
                      ),
                      _buildCircularActionIcon(
                        context,
                        Icons.notifications_none_outlined,
                        hasNotification: true,
                        onTap: () => _showNotificationsModal(
                          context,
                        ),
                      ),
                    ],
                  ),

                  // ==================================================
                  // ATIVIDADES
                  // ==================================================
                  if (widget.controller.isProfileCardExpanded) ...[
                    const SizedBox(
                      height: 28,
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Atividades Recentes',
                            style: TextStyle(
                              color: Colors.white.withValues(
                                alpha: 0.8,
                              ),
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(
                            height: 4,
                          ),
                          Text(
                            '${DateTime.now().day.toString().padLeft(2, '0')} '
                            '${widget.controller.getShortMonthName(widget.controller.focusedDay.month)} '
                            '${widget.controller.focusedDay.year}',
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 24,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(
                          alpha: 0.2,
                        ),
                        borderRadius: BorderRadius.circular(
                          16,
                        ),
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.history_toggle_off,
                            color: Colors.white24,
                            size: 28,
                          ),
                          SizedBox(
                            height: 8,
                          ),
                          Text(
                            'Nenhuma atividade recente por aqui.',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
    );
  }

  // ============================================================
  // BOTÃO
  // ============================================================

  Widget _buildCircularActionIcon(
    BuildContext context,
    IconData icon, {
    bool hasNotification = false,
    String? route,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: () {
        if (onTap !=
            null) {
          onTap();

          return;
        }

        if (route !=
            null) {
          Navigator.of(
            context,
          ).pushNamed(
            route,
          );
        }
      },
      child: Stack(
        alignment: Alignment.topRight,
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
          if (hasNotification)
            Positioned(
              right: 2,
              top: 2,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.orangeAccent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
