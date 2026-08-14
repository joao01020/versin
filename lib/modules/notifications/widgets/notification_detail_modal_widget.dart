import 'package:flutter/material.dart';

import 'package:versin/modules/notifications/controllers/notification_controller.dart';
import 'package:versin/modules/notifications/models/system_notification_model.dart';

// ============================================================
// NOTIFICATION DETAIL MODAL WIDGET
// ============================================================
//
// Modal responsável por exibir os detalhes de uma notificação.
//
// Para notificações do tipo update:
//
// - mostra status;
// - mostra barra de progresso;
// - mostra porcentagem;
// - mostra mensagem de progresso;
// - atualiza automaticamente via NotificationController.
//
// O modal recebe apenas o notificationId.
//
// Isso é importante porque:
//
// NotificationController
//        ↓
// Realtime
//        ↓
// atualiza o objeto da lista
//        ↓
// findById(notificationId)
//        ↓
// modal recebe sempre a versão mais recente
//
// ============================================================

class NotificationDetailModalWidget
    extends
        StatefulWidget {
  // ============================================================
  // DEPENDÊNCIAS
  // ============================================================

  final NotificationController controller;

  final String notificationId;

  final Color? accentColor;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  const NotificationDetailModalWidget({
    super.key,
    required this.controller,
    required this.notificationId,
    this.accentColor,
  });

  @override
  State<
    NotificationDetailModalWidget
  >
  createState() => _NotificationDetailModalWidgetState();
}

// ============================================================
// STATE
// ============================================================

class _NotificationDetailModalWidgetState
    extends
        State<
          NotificationDetailModalWidget
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

    WidgetsBinding.instance.addPostFrameCallback(
      (
        _,
      ) async {
        if (!mounted) {
          return;
        }

        final existing = controller.findById(
          widget.notificationId,
        );

        if (existing ==
            null) {
          await controller.loadNotificationById(
            widget.notificationId,
          );
        }
      },
    );
  }

  // ============================================================
  // CONTROLLER UPDATE
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
    final notification = controller.findById(
      widget.notificationId,
    );

    if (notification ==
        null) {
      return _buildLoadingOrMissing();
    }

    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight:
              MediaQuery.of(
                context,
              ).size.height *
              0.82,
        ),
        decoration: const BoxDecoration(
          color: Color(
            0xFF121022,
          ),
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(
              28,
            ),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            22,
            14,
            22,
            30,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================================================
              // HANDLE
              // ==================================================
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(
                      20,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 18,
              ),

              // ==================================================
              // HEADER
              // ==================================================
              _buildHeader(
                context,
                notification,
              ),

              const SizedBox(
                height: 20,
              ),

              // ==================================================
              // MENSAGEM
              // ==================================================
              _buildMessageCard(
                notification,
              ),

              // ==================================================
              // PROGRESSO
              // ==================================================
              if (notification.isUpdate) ...[
                const SizedBox(
                  height: 18,
                ),

                _buildProgressSection(
                  notification,
                ),
              ],

              const SizedBox(
                height: 18,
              ),

              // ==================================================
              // INFORMAÇÕES
              // ==================================================
              _buildInformationSection(
                notification,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(
    BuildContext context,
    SystemNotificationModel notification,
  ) {
    final typeColor = _colorForType(
      notification.type,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ======================================================
        // ÍCONE
        // ======================================================
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: typeColor.withValues(
              alpha: 0.10,
            ),
            borderRadius: BorderRadius.circular(
              14,
            ),
            border: Border.all(
              color: typeColor.withValues(
                alpha: 0.22,
              ),
            ),
          ),
          child: Icon(
            _iconForType(
              notification.type,
            ),
            color: typeColor,
            size: 22,
          ),
        ),

        const SizedBox(
          width: 14,
        ),

        // ======================================================
        // TÍTULO
        // ======================================================
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notification.typeLabel.toUpperCase(),
                style: TextStyle(
                  color: typeColor,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.9,
                ),
              ),

              const SizedBox(
                height: 5,
              ),

              Text(
                notification.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(
          width: 8,
        ),

        // ======================================================
        // FECHAR
        // ======================================================
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
            size: 20,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // MENSAGEM
  // ============================================================

  Widget _buildMessageCard(
    SystemNotificationModel notification,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        16,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.03,
        ),
        borderRadius: BorderRadius.circular(
          16,
        ),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.06,
          ),
        ),
      ),
      child: Text(
        notification.message,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
          height: 1.6,
        ),
      ),
    );
  }

  // ============================================================
  // PROGRESSO
  // ============================================================

  Widget _buildProgressSection(
    SystemNotificationModel notification,
  ) {
    final statusColor = _colorForStatus(
      notification.status,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        18,
      ),
      decoration: BoxDecoration(
        color: statusColor.withValues(
          alpha: 0.045,
        ),
        borderRadius: BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: statusColor.withValues(
            alpha: 0.16,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ====================================================
          // STATUS
          // ====================================================
          Row(
            children: [
              _buildStatusIcon(
                notification,
                statusColor,
              ),

              const SizedBox(
                width: 8,
              ),

              Expanded(
                child: Text(
                  notification.statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              Text(
                '${notification.normalizedProgress}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 16,
          ),

          // ====================================================
          // BARRA
          // ====================================================
          ClipRRect(
            borderRadius: BorderRadius.circular(
              20,
            ),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: notification.progressValue,
              backgroundColor: Colors.white.withValues(
                alpha: 0.07,
              ),
              valueColor:
                  AlwaysStoppedAnimation<
                    Color
                  >(
                    statusColor,
                  ),
            ),
          ),

          // ====================================================
          // MENSAGEM DE PROGRESSO
          // ====================================================
          if (notification.progressMessage !=
                  null &&
              notification.progressMessage!.trim().isNotEmpty) ...[
            const SizedBox(
              height: 14,
            ),

            Text(
              notification.progressMessage!,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
                height: 1.45,
              ),
            ),
          ],

          // ====================================================
          // ESTADO FINAL
          // ====================================================
          if (notification.isCompleted) ...[
            const SizedBox(
              height: 14,
            ),

            _buildCompletedMessage(),
          ],

          if (notification.isFailed) ...[
            const SizedBox(
              height: 14,
            ),

            _buildFailedMessage(),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // STATUS ICON
  // ============================================================

  Widget _buildStatusIcon(
    SystemNotificationModel notification,
    Color color,
  ) {
    if (notification.isDownloading ||
        notification.isInstalling) {
      return SizedBox(
        width: 17,
        height: 17,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: color,
        ),
      );
    }

    if (notification.isCompleted) {
      return Icon(
        Icons.check_circle_rounded,
        color: color,
        size: 18,
      );
    }

    if (notification.isFailed) {
      return Icon(
        Icons.error_rounded,
        color: color,
        size: 18,
      );
    }

    return Icon(
      Icons.schedule_rounded,
      color: color,
      size: 18,
    );
  }

  // ============================================================
  // CONCLUÍDA
  // ============================================================

  Widget _buildCompletedMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.greenAccent.withValues(
          alpha: 0.06,
        ),
        borderRadius: BorderRadius.circular(
          10,
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.check_rounded,
            color: Colors.greenAccent,
            size: 15,
          ),

          SizedBox(
            width: 7,
          ),

          Expanded(
            child: Text(
              'Atualização concluída com sucesso.',
              style: TextStyle(
                color: Colors.greenAccent,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FALHA
  // ============================================================

  Widget _buildFailedMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(
          alpha: 0.06,
        ),
        borderRadius: BorderRadius.circular(
          10,
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: Colors.redAccent,
            size: 15,
          ),

          SizedBox(
            width: 7,
          ),

          Expanded(
            child: Text(
              'Não foi possível concluir a atualização.',
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INFORMAÇÕES
  // ============================================================

  Widget _buildInformationSection(
    SystemNotificationModel notification,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        15,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(
          alpha: 0.12,
        ),
        borderRadius: BorderRadius.circular(
          14,
        ),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            icon: notification.isGlobal
                ? Icons.public_rounded
                : Icons.person_outline_rounded,
            label: 'Destino',
            value: notification.isGlobal
                ? 'Todos os usuários'
                : 'Notificação pessoal',
          ),

          const SizedBox(
            height: 10,
          ),

          _buildInfoRow(
            icon: Icons.access_time_rounded,
            label: 'Enviado',
            value: _formatDateTime(
              notification.createdAt,
            ),
          ),

          if (notification.expiresAt !=
              null) ...[
            const SizedBox(
              height: 10,
            ),

            _buildInfoRow(
              icon: Icons.timer_outlined,
              label: 'Expira',
              value: _formatDateTime(
                notification.expiresAt!,
              ),
            ),
          ],

          if (notification.isUpdate) ...[
            const SizedBox(
              height: 10,
            ),

            _buildInfoRow(
              icon: Icons.sync_rounded,
              label: 'Status',
              value: notification.statusLabel,
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // INFO ROW
  // ============================================================

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.white24,
          size: 14,
        ),

        const SizedBox(
          width: 8,
        ),

        Text(
          label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 10,
          ),
        ),

        const Spacer(),

        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // LOADING / REMOVIDA
  // ============================================================

  Widget _buildLoadingOrMissing() {
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(
          minHeight: 240,
        ),
        decoration: const BoxDecoration(
          color: Color(
            0xFF121022,
          ),
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(
              28,
            ),
          ),
        ),
        child: Center(
          child: controller.isLoading
              ? CircularProgressIndicator(
                  strokeWidth: 2,
                  color: accentColor,
                )
              : const Padding(
                  padding: EdgeInsets.all(
                    30,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.notifications_off_outlined,
                        color: Colors.white24,
                        size: 28,
                      ),

                      SizedBox(
                        height: 10,
                      ),

                      Text(
                        'Notificação não encontrada.',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
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
  // FORMATAR DATA
  // ============================================================

  String _formatDateTime(
    DateTime date,
  ) {
    final localDate = date.toLocal();

    final day = localDate.day.toString().padLeft(
      2,
      '0',
    );

    final month = localDate.month.toString().padLeft(
      2,
      '0',
    );

    final year = localDate.year.toString();

    final hour = localDate.hour.toString().padLeft(
      2,
      '0',
    );

    final minute = localDate.minute.toString().padLeft(
      2,
      '0',
    );

    return '$day/$month/$year $hour:$minute';
  }
}
