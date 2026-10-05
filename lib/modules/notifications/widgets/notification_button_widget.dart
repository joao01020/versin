import 'package:flutter/material.dart';

import 'package:versin/app/locator.dart';
import 'package:versin/modules/notifications/controllers/notification_controller.dart';

import 'notification_panel_widget.dart';

// ============================================================
// NOTIFICATION BUTTON WIDGET
// ============================================================
//
// Botão de notificações do Dashboard.
//
// Responsabilidades:
//
// - exibir sino;
// - exibir badge de não lidas;
// - reagir ao NotificationController;
// - abrir o painel de notificações;
// - inicializar o controller quando necessário.
//
// ============================================================

class NotificationButtonWidget
    extends
        StatefulWidget {
  // ============================================================
  // CONFIGURAÇÕES
  // ============================================================

  final double size;

  final Color? iconColor;

  final Color? accentColor;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  const NotificationButtonWidget({
    super.key,
    this.size = 42,
    this.iconColor,
    this.accentColor,
  });

  @override
  State<
    NotificationButtonWidget
  >
  createState() => _NotificationButtonWidgetState();
}

// ============================================================
// STATE
// ============================================================

class _NotificationButtonWidgetState
    extends
        State<
          NotificationButtonWidget
        > {
  // ============================================================
  // CONTROLLER
  // ============================================================

  late final NotificationController _controller;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _controller =
        sl<
          NotificationController
        >();

    _controller.addListener(
      _onControllerUpdate,
    );

    WidgetsBinding.instance.addPostFrameCallback(
      (
        _,
      ) {
        if (!mounted) {
          return;
        }

        _initializeNotifications();
      },
    );
  }

  // ============================================================
  // INICIALIZAR
  // ============================================================

  Future<
    void
  >
  _initializeNotifications() async {
    if (_controller.isInitialized) {
      return;
    }

    await _controller.init();
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
  // ABRIR PAINEL
  // ============================================================

  Future<
    void
  >
  _openNotifications() async {
    await showModalBottomSheet<
      void
    >(
      context: context,

      isScrollControlled: true,

      backgroundColor: Colors.transparent,

      barrierColor: Colors.black.withValues(
        alpha: 0.65,
      ),

      builder:
          (
            context,
          ) {
            return NotificationPanelWidget(
              controller: _controller,

              accentColor: widget.accentColor,
            );
          },
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _controller.removeListener(
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
    final unreadCount = _controller.unreadCount;

    final hasUnread =
        unreadCount >
        0;

    final accentColor =
        widget.accentColor ??
        const Color(
          0xFFE100FF,
        );

    final iconColor =
        widget.iconColor ??
        Colors.white70;

    return Tooltip(
      message: hasUnread
          ? '$unreadCount notificação(ões) não lida(s)'
          : 'Notificações',

      child: InkWell(
        onTap: _openNotifications,

        borderRadius: BorderRadius.circular(
          14,
        ),

        child: Container(
          width: widget.size,

          height: widget.size,

          decoration: BoxDecoration(
            color: Colors.white.withValues(
              alpha: 0.035,
            ),

            borderRadius: BorderRadius.circular(
              14,
            ),

            border: Border.all(
              color: hasUnread
                  ? accentColor.withValues(
                      alpha: 0.28,
                    )
                  : Colors.white.withValues(
                      alpha: 0.07,
                    ),
            ),
          ),

          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // ==================================================
              // SINO
              // ==================================================
              Center(
                child:
                    _controller.isLoading &&
                        !_controller.isInitialized
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: accentColor,
                        ),
                      )
                    : Icon(
                        hasUnread
                            ? Icons.notifications_rounded
                            : Icons.notifications_none_rounded,
                        color: hasUnread
                            ? accentColor
                            : iconColor,
                        size: 21,
                      ),
              ),

              // ==================================================
              // BADGE
              // ==================================================
              if (hasUnread)
                Positioned(
                  right: -4,
                  top: -4,
                  child: _buildBadge(
                    unreadCount: unreadCount,
                    accentColor: accentColor,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BADGE
  // ============================================================

  Widget _buildBadge({
    required int unreadCount,
    required Color accentColor,
  }) {
    final label =
        unreadCount >
            99
        ? '99+'
        : unreadCount.toString();

    return Container(
      constraints: const BoxConstraints(
        minWidth: 18,
        minHeight: 18,
      ),

      padding: const EdgeInsets.symmetric(
        horizontal: 5,
      ),

      decoration: BoxDecoration(
        color: accentColor,

        borderRadius: BorderRadius.circular(
          20,
        ),

        border: Border.all(
          color: const Color(
            0xFF0D0B1F,
          ),
          width: 2,
        ),

        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(
              alpha: 0.30,
            ),
            blurRadius: 8,
          ),
        ],
      ),

      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
