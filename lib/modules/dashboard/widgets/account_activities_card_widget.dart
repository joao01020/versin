import 'package:flutter/material.dart';
import 'package:versin/app/routes/app_routes.dart'; // Importação das rotas
import '../controllers/dashboard_controller.dart';

/// [AccountActivitiesCardWidget] renders profile summary and recent system logs.
class AccountActivitiesCardWidget extends StatelessWidget {
  final DashboardController controller;
  final VoidCallback onStateChanged;

  const AccountActivitiesCardWidget({
    super.key,
    required this.controller,
    required this.onStateChanged,
  });

  // Função para abrir o Modal de Notificações
  void _showNotificationsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Color(0xFF1F1A3A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(width: 40, height: 4, color: Colors.white24),
            const SizedBox(height: 20),
            const Text("NOTIFICAÇÕES",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            const Expanded(
                child: Center(
                    child: Text("Nenhuma notificação nova.",
                        style: TextStyle(color: Colors.white54)))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1F1A3A), Color(0xFF0D0B1F)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF1F1A3A).withOpacity(0.5),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () {
                  controller.toggleProfileCard();
                  onStateChanged();
                },
                child: Icon(
                  controller.isProfileCardExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.white54,
                  size: 22,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: controller.pickProfileImage,
            child: CircleAvatar(
              radius: 36,
              backgroundColor: const Color(0xFFFFCC80),
              backgroundImage: controller.profileImagePath != null
                  ? NetworkImage(controller.profileImagePath!)
                  : null,
              child: controller.profileImagePath == null
                  ? const Icon(Icons.person, color: Color(0xFF2E1A47), size: 40)
                  : null,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            "Astryvo",
            style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5),
          ),
          const SizedBox(height: 4),
          const Text(
            "Beatmaker",
            style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w400),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildCircularActionIcon(
                context,
                Icons.description_outlined,
                route: AppRoutes.contracts,
              ),
              const SizedBox(width: 16),
              _buildCircularActionIcon(
                context,
                Icons.calendar_today_outlined,
                route: AppRoutes.calendar,
              ),
              const SizedBox(width: 16),
              // Botão de notificação agora chama o Modal:
              _buildCircularActionIcon(
                context,
                Icons.notifications_none_outlined,
                hasNotification: true,
                onTap: () => _showNotificationsModal(context),
              ),
            ],
          ),
          if (controller.isProfileCardExpanded) ...[
            const SizedBox(height: 28),
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Atividades Recentes",
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 15,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${DateTime.now().day.toString().padLeft(2, '0')} ${controller.getShortMonthName(controller.focusedDay.month)} ${controller.focusedDay.year}",
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.02)),
              ),
              child: const Column(
                children: [
                  Icon(Icons.history_toggle_off, color: Colors.white24, size: 28),
                  SizedBox(height: 8),
                  Text(
                    "Nenhuma atividade recente por aqui.",
                    style: TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                        fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCircularActionIcon(
    BuildContext context,
    IconData icon, {
    bool hasNotification = false,
    String? route,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          onTap();
        } else if (route != null) {
          Navigator.of(context).pushNamed(route);
        }
      },
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Icon(icon, color: Colors.white70, size: 20),
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