import 'package:flutter/material.dart';

import 'package:versin/modules/notifications/controllers/notification_controller.dart';
import 'package:versin/modules/notifications/models/system_notification_model.dart';
import 'package:versin/modules/notifications/widgets/notification_detail_modal_widget.dart';

// ============================================================
// NOTIFICATION PANEL WIDGET
// ============================================================

class NotificationPanelWidget
    extends
        StatefulWidget {
  final NotificationController controller;

  final Color? accentColor;

  const NotificationPanelWidget({
    super.key,
    required this.controller,
    this.accentColor,
  });

  @override
  State<
    NotificationPanelWidget
  >
  createState() => _NotificationPanelWidgetState();
}

// ============================================================
// STATE
// ============================================================

class _NotificationPanelWidgetState
    extends
        State<
          NotificationPanelWidget
        > {
  // ============================================================
  // CONTROLLER
  // ============================================================

  NotificationController get controller => widget.controller;

  // ============================================================
  // ACCENT
  // ============================================================

  Color get accentColor =>
      widget.accentColor ??
      const Color(
        0xFFE100FF,
      );

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    controller.addListener(
      _onControllerUpdate,
    );

    if (!controller.isInitialized) {
      WidgetsBinding.instance.addPostFrameCallback(
        (
          _,
        ) {
          if (!mounted) {
            return;
          }

          controller.init();
        },
      );
    }
  }

  // ============================================================
  // LISTENER
  // ============================================================

  void _onControllerUpdate() {
    if (!mounted) {
      return;
    }

    setState(
      () {},
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    controller.removeListener(
      _onControllerUpdate,
    );

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final mediaQuery = MediaQuery.of(
      context,
    );

    final maxHeight =
        mediaQuery.size.height *
        0.78;

    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: maxHeight,
        ),
        decoration: const BoxDecoration(
          color: Color(
            0xFF121022,
          ),
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(
              26,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ==================================================
            // HANDLE
            // ==================================================
            const SizedBox(
              height: 10,
            ),

            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(
                  20,
                ),
              ),
            ),

            // ==================================================
            // HEADER
            // ==================================================
            _buildHeader(),

            // ==================================================
            // DIVISOR
            // ==================================================
            Divider(
              height: 1,
              color: Colors.white.withValues(
                alpha: 0.06,
              ),
            ),

            // ==================================================
            // CONTEÚDO
            // ==================================================
            Flexible(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    final unreadCount = controller.unreadCount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        16,
        12,
        14,
      ),
      child: Row(
        children: [
          // ====================================================
          // ÍCONE
          // ====================================================
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accentColor.withValues(
                alpha: 0.10,
              ),
              borderRadius: BorderRadius.circular(
                12,
              ),
              border: Border.all(
                color: accentColor.withValues(
                  alpha: 0.22,
                ),
              ),
            ),
            child: Icon(
              Icons.notifications_rounded,
              color: accentColor,
              size: 19,
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          // ====================================================
          // TÍTULO
          // ====================================================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Notificações',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    if (unreadCount >
                        0) ...[
                      const SizedBox(
                        width: 8,
                      ),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(
                            alpha: 0.10,
                          ),
                          borderRadius: BorderRadius.circular(
                            20,
                          ),
                        ),
                        child: Text(
                          '$unreadCount',
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(
                  height: 2,
                ),

                Text(
                  unreadCount >
                          0
                      ? '$unreadCount não lida(s)'
                      : 'Você está em dia',
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          // ====================================================
          // MARCAR TODAS
          // ====================================================
          if (unreadCount >
              0)
            TextButton(
              onPressed: controller.markAllAsRead,
              style: TextButton.styleFrom(
                foregroundColor: accentColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
              ),
              child: const Text(
                'LER TODAS',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          // ====================================================
          // FECHAR
          // ====================================================
          IconButton(
            tooltip: 'Fechar',
            onPressed: () {
              Navigator.of(
                context,
              ).pop();
            },
            icon: const Icon(
              Icons.close_rounded,
              color: Colors.white38,
              size: 19,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CONTEÚDO
  // ============================================================

  Widget _buildContent() {
    // ==========================================================
    // LOADING
    // ==========================================================

    if (controller.isLoading &&
        !controller.hasNotifications) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(
            40,
          ),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(
              0xFFE100FF,
            ),
          ),
        ),
      );
    }

    // ==========================================================
    // ERRO
    // ==========================================================

    if (controller.hasError &&
        !controller.hasNotifications) {
      return _buildErrorState();
    }

    // ==========================================================
    // VAZIO
    // ==========================================================

    if (!controller.hasNotifications) {
      return _buildEmptyState();
    }

    // ==========================================================
    // LISTA
    // ==========================================================

    return RefreshIndicator(
      color: accentColor,
      backgroundColor: const Color(
        0xFF17132D,
      ),
      onRefresh: controller.refresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          16,
          14,
          16,
          24,
        ),
        itemCount: controller.notifications.length,
        separatorBuilder:
            (
              context,
              index,
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
              final notification = controller.notifications[index];

              return _buildNotificationCard(
                notification,
              );
            },
      ),
    );
  }

  // ============================================================
  // CARD
  // ============================================================

  Widget _buildNotificationCard(
    SystemNotificationModel notification,
  ) {
    final typeColor = _colorForType(
      notification.type,
    );

    final typeIcon = _iconForType(
      notification.type,
    );

    return InkWell(
      // ========================================================
      // CLIQUE
      // ========================================================
      onTap: () async {
        await _openNotification(
          notification,
        );
      },

      borderRadius: BorderRadius.circular(
        16,
      ),

      child: AnimatedContainer(
        duration: const Duration(
          milliseconds: 160,
        ),
        width: double.infinity,
        padding: const EdgeInsets.all(
          14,
        ),
        decoration: BoxDecoration(
          color: notification.isUnread
              ? typeColor.withValues(
                  alpha: 0.055,
                )
              : Colors.white.withValues(
                  alpha: 0.025,
                ),
          borderRadius: BorderRadius.circular(
            16,
          ),
          border: Border.all(
            color: notification.isUnread
                ? typeColor.withValues(
                    alpha: 0.20,
                  )
                : Colors.white.withValues(
                    alpha: 0.05,
                  ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================================================
            // ÍCONE
            // ==================================================
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: typeColor.withValues(
                  alpha: 0.10,
                ),
                borderRadius: BorderRadius.circular(
                  11,
                ),
              ),
              child: Icon(
                typeIcon,
                color: typeColor,
                size: 18,
              ),
            ),

            const SizedBox(
              width: 12,
            ),

            // ==================================================
            // CONTEÚDO
            // ==================================================
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ============================================
                  // TIPO + DATA
                  // ============================================
                  Row(
                    children: [
                      Text(
                        notification.typeLabel.toUpperCase(),
                        style: TextStyle(
                          color: typeColor,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.7,
                        ),
                      ),

                      const Spacer(),

                      Text(
                        _formatDate(
                          notification.createdAt,
                        ),
                        style: const TextStyle(
                          color: Colors.white24,
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 5,
                  ),

                  // ============================================
                  // TÍTULO
                  // ============================================
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            color: notification.isUnread
                                ? Colors.white
                                : Colors.white70,
                            fontSize: 12,
                            fontWeight: notification.isUnread
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                      ),

                      if (notification.isUnread) ...[
                        const SizedBox(
                          width: 8,
                        ),

                        Container(
                          width: 7,
                          height: 7,
                          margin: const EdgeInsets.only(
                            top: 4,
                          ),
                          decoration: BoxDecoration(
                            color: typeColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: typeColor.withValues(
                                  alpha: 0.40,
                                ),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(
                    height: 5,
                  ),

                  // ============================================
                  // MENSAGEM
                  // ============================================
                  Text(
                    notification.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      height: 1.45,
                    ),
                  ),

                  // ============================================
                  // PROGRESSO DA ATUALIZAÇÃO
                  // ============================================
                  if (notification.isUpdate) ...[
                    const SizedBox(
                      height: 10,
                    ),

                    _buildUpdatePreview(
                      notification,
                      typeColor,
                    ),
                  ],

                  // ============================================
                  // RODAPÉ
                  // ============================================
                  const SizedBox(
                    height: 8,
                  ),

                  Row(
                    children: [
                      Icon(
                        notification.isGlobal
                            ? Icons.public_rounded
                            : Icons.person_outline_rounded,
                        color: Colors.white24,
                        size: 11,
                      ),

                      const SizedBox(
                        width: 4,
                      ),

                      Text(
                        notification.isGlobal
                            ? 'Sistema'
                            : 'Mensagem pessoal',
                        style: const TextStyle(
                          color: Colors.white24,
                          fontSize: 8,
                        ),
                      ),

                      const Spacer(),

                      const Text(
                        'VER DETALHES',
                        style: TextStyle(
                          color: Colors.white30,
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(
                        width: 3,
                      ),

                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white24,
                        size: 8,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PREVIEW DA ATUALIZAÇÃO
  // ============================================================

  Widget _buildUpdatePreview(
    SystemNotificationModel notification,
    Color typeColor,
  ) {
    final progress = notification.normalizedProgress;

    final progressValue = notification.progressValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              _iconForStatus(
                notification.status,
              ),
              color: _colorForStatus(
                notification.status,
              ),
              size: 11,
            ),

            const SizedBox(
              width: 5,
            ),

            Expanded(
              child: Text(
                notification.statusLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _colorForStatus(
                    notification.status,
                  ),
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            Text(
              '$progress%',
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 6,
        ),

        ClipRRect(
          borderRadius: BorderRadius.circular(
            20,
          ),
          child: LinearProgressIndicator(
            value: progressValue,
            minHeight: 3,
            backgroundColor: Colors.white.withValues(
              alpha: 0.06,
            ),
            valueColor:
                AlwaysStoppedAnimation<
                  Color
                >(
                  typeColor,
                ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ABRIR NOTIFICAÇÃO
  // ============================================================

  Future<
    void
  >
  _openNotification(
    SystemNotificationModel notification,
  ) async {
    final notificationId = notification.id;

    // ==========================================================
    // MARCAR COMO LIDA
    // ==========================================================

    if (notification.isUnread) {
      await controller.markAsRead(
        notificationId,
      );
    }

    if (!mounted) {
      return;
    }

    // ==========================================================
    // GUARDAR NAVEGADOR
    // ==========================================================

    final navigator = Navigator.of(
      context,
    );

    // ==========================================================
    // FECHAR PAINEL ATUAL
    // ==========================================================

    navigator.pop();

    // ==========================================================
    // AGUARDAR O BOTTOM SHEET SER REMOVIDO
    // ==========================================================

    await Future<
      void
    >.delayed(
      const Duration(
        milliseconds: 180,
      ),
    );

    if (!navigator.mounted) {
      return;
    }

    // ==========================================================
    // ABRIR DETALHES
    // ==========================================================

    await showModalBottomSheet<
      void
    >(
      context: navigator.context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(
        alpha: 0.70,
      ),
      builder:
          (
            modalContext,
          ) {
            return NotificationDetailModalWidget(
              controller: controller,
              notificationId: notificationId,
              accentColor: accentColor,
            );
          },
    );
  }

  // ============================================================
  // ESTADO VAZIO
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 52,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white.withValues(
                  alpha: 0.035,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: Colors.white24,
                size: 25,
              ),
            ),

            const SizedBox(
              height: 14,
            ),

            const Text(
              'Nenhuma notificação',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(
              height: 5,
            ),

            const Text(
              'Atualizações do sistema e avisos importantes aparecerão aqui.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white30,
                fontSize: 10,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ERRO
  // ============================================================

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 42,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent,
              size: 28,
            ),

            const SizedBox(
              height: 10,
            ),

            Text(
              controller.errorMessage ??
                  'Não foi possível carregar as notificações.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            TextButton.icon(
              onPressed: controller.refresh,
              icon: const Icon(
                Icons.refresh_rounded,
                size: 16,
              ),
              label: const Text(
                'TENTAR NOVAMENTE',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // COR POR TIPO
  // ============================================================

  Color _colorForType(
    SystemNotificationType type,
  ) {
    switch (type) {
      case SystemNotificationType.info:
        return Colors.lightBlueAccent;

      case SystemNotificationType.success:
        return Colors.greenAccent;

      case SystemNotificationType.warning:
        return Colors.amberAccent;

      case SystemNotificationType.error:
        return Colors.redAccent;

      case SystemNotificationType.update:
        return accentColor;

      case SystemNotificationType.maintenance:
        return Colors.orangeAccent;

      case SystemNotificationType.news:
        return Colors.cyanAccent;
    }
  }

  // ============================================================
  // COR POR STATUS
  // ============================================================

  Color _colorForStatus(
    SystemNotificationStatus status,
  ) {
    switch (status) {
      case SystemNotificationStatus.pending:
        return Colors.white54;

      case SystemNotificationStatus.downloading:
        return Colors.lightBlueAccent;

      case SystemNotificationStatus.installing:
        return accentColor;

      case SystemNotificationStatus.completed:
        return Colors.greenAccent;

      case SystemNotificationStatus.failed:
        return Colors.redAccent;
    }
  }

  // ============================================================
  // ÍCONE POR TIPO
  // ============================================================

  IconData _iconForType(
    SystemNotificationType type,
  ) {
    switch (type) {
      case SystemNotificationType.info:
        return Icons.info_outline_rounded;

      case SystemNotificationType.success:
        return Icons.check_circle_outline_rounded;

      case SystemNotificationType.warning:
        return Icons.warning_amber_rounded;

      case SystemNotificationType.error:
        return Icons.error_outline_rounded;

      case SystemNotificationType.update:
        return Icons.system_update_alt_rounded;

      case SystemNotificationType.maintenance:
        return Icons.construction_rounded;

      case SystemNotificationType.news:
        return Icons.newspaper_rounded;
    }
  }

  // ============================================================
  // ÍCONE POR STATUS
  // ============================================================

  IconData _iconForStatus(
    SystemNotificationStatus status,
  ) {
    switch (status) {
      case SystemNotificationStatus.pending:
        return Icons.schedule_rounded;

      case SystemNotificationStatus.downloading:
        return Icons.download_rounded;

      case SystemNotificationStatus.installing:
        return Icons.settings_rounded;

      case SystemNotificationStatus.completed:
        return Icons.check_circle_rounded;

      case SystemNotificationStatus.failed:
        return Icons.error_rounded;
    }
  }

  // ============================================================
  // DATA
  // ============================================================

  String _formatDate(
    DateTime date,
  ) {
    final now = DateTime.now();

    final localDate = date.toLocal();

    final difference = now.difference(
      localDate,
    );

    if (difference.inSeconds <
        60) {
      return 'agora';
    }

    if (difference.inMinutes <
        60) {
      return '${difference.inMinutes}min';
    }

    if (difference.inHours <
        24) {
      return '${difference.inHours}h';
    }

    if (difference.inDays ==
        1) {
      return 'ontem';
    }

    if (difference.inDays <
        7) {
      return '${difference.inDays}d';
    }

    final day = localDate.day.toString().padLeft(
      2,
      '0',
    );

    final month = localDate.month.toString().padLeft(
      2,
      '0',
    );

    return '$day/$month';
  }
}
