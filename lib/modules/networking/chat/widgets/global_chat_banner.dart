import 'dart:async';

import 'package:flutter/material.dart';

// ============================================================
// GLOBAL CHAT BANNER TYPE
// ============================================================

enum GlobalChatBannerType {
  message,
  audio,
}

// ============================================================
// GLOBAL CHAT BANNER
// ============================================================
//
// Banner temporário de novas mensagens.
//
// Comportamento:
//
// - Nova mensagem chega;
// - banner aparece;
// - permanece visível por alguns segundos;
// - desaparece automaticamente;
// - uma nova mensagem reinicia o tempo;
//
// Também continua permitindo:
//
// - ABRIR;
// - fechar manualmente no X.
//
// ============================================================

class GlobalChatBanner
    extends
        StatefulWidget {
  // ==========================================================
  // DATA
  // ==========================================================

  final GlobalChatBannerType type;

  final String senderName;

  final String preview;

  final int unreadCount;

  // ==========================================================
  // CALLBACKS
  // ==========================================================

  final VoidCallback? onOpen;

  final VoidCallback? onDismiss;

  // ==========================================================
  // AUTO DISMISS
  // ==========================================================

  final Duration displayDuration;

  // ==========================================================
  // CONSTRUCTOR
  // ==========================================================

  const GlobalChatBanner({
    super.key,
    required this.type,
    required this.senderName,
    required this.preview,
    this.unreadCount = 1,
    this.onOpen,
    this.onDismiss,
    this.displayDuration = const Duration(
      seconds: 5,
    ),
  });

  @override
  State<
    GlobalChatBanner
  >
  createState() => _GlobalChatBannerState();
}

// ============================================================
// STATE
// ============================================================

class _GlobalChatBannerState
    extends
        State<
          GlobalChatBanner
        > {
  // ==========================================================
  // COLORS
  // ==========================================================

  static const Color _background = Color(
    0xFF121217,
  );

  static const Color _surface = Color(
    0xFF191920,
  );

  static const Color _purple = Color(
    0xFF8B5CF6,
  );

  static const Color _green = Color(
    0xFF34D399,
  );

  // ==========================================================
  // TIMER
  // ==========================================================

  Timer? _dismissTimer;

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _startDismissTimer();
  }

  // ==========================================================
  // NOVA MENSAGEM
  // ==========================================================
  //
  // Caso o mesmo widget seja atualizado com uma nova
  // mensagem, reinicia o tempo de exibição.
  //
  // ==========================================================

  @override
  void didUpdateWidget(
    covariant GlobalChatBanner oldWidget,
  ) {
    super.didUpdateWidget(
      oldWidget,
    );

    final messageChanged =
        oldWidget.senderName !=
            widget.senderName ||
        oldWidget.preview !=
            widget.preview ||
        oldWidget.type !=
            widget.type ||
        oldWidget.unreadCount !=
            widget.unreadCount;

    if (messageChanged) {
      _startDismissTimer();
    }
  }

  // ==========================================================
  // START DISMISS TIMER
  // ==========================================================

  void _startDismissTimer() {
    _dismissTimer?.cancel();

    _dismissTimer = Timer(
      widget.displayDuration,
      _dismissAutomatically,
    );
  }

  // ==========================================================
  // AUTO DISMISS
  // ==========================================================

  void _dismissAutomatically() {
    if (!mounted) {
      return;
    }

    widget.onDismiss?.call();
  }

  // ==========================================================
  // MANUAL DISMISS
  // ==========================================================

  void _dismissManually() {
    _dismissTimer?.cancel();

    widget.onDismiss?.call();
  }

  // ==========================================================
  // OPEN
  // ==========================================================

  void _open() {
    _dismissTimer?.cancel();

    widget.onOpen?.call();
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _dismissTimer?.cancel();

    super.dispose();
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final normalizedSender = widget.senderName.trim().isEmpty
        ? 'Membro'
        : widget.senderName.trim();

    final normalizedPreview = widget.preview.trim().isEmpty
        ? 'Nova mensagem'
        : widget.preview.trim();

    return SafeArea(
      minimum: const EdgeInsets.only(
        top: 8,
        left: 12,
        right: 12,
      ),

      child: Material(
        color: Colors.transparent,

        child: Container(
          width: double.infinity,

          constraints: const BoxConstraints(
            minHeight: 66,
          ),

          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),

          decoration: BoxDecoration(
            color: _background,

            borderRadius: BorderRadius.circular(
              18,
            ),

            border: Border.all(
              color: _accentColor.withValues(
                alpha: 0.30,
              ),
            ),

            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: 0.35,
                ),

                blurRadius: 20,

                offset: const Offset(
                  0,
                  8,
                ),
              ),
            ],
          ),

          child: Row(
            children: [
              // ==============================================
              // ICON
              // ==============================================
              _buildIcon(),

              const SizedBox(
                width: 12,
              ),

              // ==============================================
              // INFORMATION
              // ==============================================
              Expanded(
                child: _buildInformation(
                  sender: normalizedSender,
                  preview: normalizedPreview,
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              // ==============================================
              // ACTIONS
              // ==============================================
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // ICON
  // ==========================================================

  Widget _buildIcon() {
    return Container(
      width: 42,

      height: 42,

      decoration: BoxDecoration(
        color: _accentColor.withValues(
          alpha: 0.12,
        ),

        shape: BoxShape.circle,

        border: Border.all(
          color: _accentColor.withValues(
            alpha: 0.25,
          ),
        ),
      ),

      child: Icon(
        _icon,
        color: _accentColor,
        size: 20,
      ),
    );
  }

  // ==========================================================
  // INFORMATION
  // ==========================================================

  Widget _buildInformation({
    required String sender,
    required String preview,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,

      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        // ================================================
        // TOP ROW
        // ================================================
        Row(
          children: [
            Flexible(
              child: Text(
                sender,

                maxLines: 1,

                overflow: TextOverflow.ellipsis,

                style: const TextStyle(
                  color: Colors.white,

                  fontSize: 12,

                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            if (widget.unreadCount >
                1) ...[
              const SizedBox(
                width: 7,
              ),

              _buildUnreadBadge(),
            ],
          ],
        ),

        const SizedBox(
          height: 4,
        ),

        // ================================================
        // PREVIEW
        // ================================================
        Row(
          children: [
            Container(
              width: 6,

              height: 6,

              decoration: BoxDecoration(
                color: _accentColor,

                shape: BoxShape.circle,
              ),
            ),

            const SizedBox(
              width: 6,
            ),

            Expanded(
              child: Text(
                preview,

                maxLines: 2,

                overflow: TextOverflow.ellipsis,

                style: const TextStyle(
                  color: Colors.white54,

                  fontSize: 10,

                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================================
  // UNREAD BADGE
  // ==========================================================

  Widget _buildUnreadBadge() {
    final label =
        widget.unreadCount >
            99
        ? '99+'
        : widget.unreadCount.toString();

    return Container(
      constraints: const BoxConstraints(
        minWidth: 20,
      ),

      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 2,
      ),

      decoration: BoxDecoration(
        color: _accentColor.withValues(
          alpha: 0.16,
        ),

        borderRadius: BorderRadius.circular(
          20,
        ),

        border: Border.all(
          color: _accentColor.withValues(
            alpha: 0.22,
          ),
        ),
      ),

      child: Text(
        label,

        textAlign: TextAlign.center,

        style: TextStyle(
          color: _accentColor,

          fontSize: 8,

          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // ==========================================================
  // ACTIONS
  // ==========================================================

  Widget _buildActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,

      children: [
        if (widget.onOpen !=
            null)
          _buildOpenButton(),

        if (widget.onOpen !=
                null &&
            widget.onDismiss !=
                null)
          const SizedBox(
            width: 6,
          ),

        if (widget.onDismiss !=
            null)
          _buildDismissButton(),
      ],
    );
  }

  // ==========================================================
  // OPEN
  // ==========================================================

  Widget _buildOpenButton() {
    return TextButton(
      onPressed: _open,

      style: TextButton.styleFrom(
        foregroundColor: _purple,

        backgroundColor: _surface,

        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 7,
        ),

        minimumSize: Size.zero,

        tapTargetSize: MaterialTapTargetSize.shrinkWrap,

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            10,
          ),
        ),
      ),

      child: const Text(
        'ABRIR',

        style: TextStyle(
          fontSize: 9,

          fontWeight: FontWeight.w800,

          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ==========================================================
  // DISMISS
  // ==========================================================

  Widget _buildDismissButton() {
    return Tooltip(
      message: 'Fechar',

      child: InkWell(
        onTap: _dismissManually,

        borderRadius: BorderRadius.circular(
          30,
        ),

        child: Container(
          width: 32,

          height: 32,

          decoration: BoxDecoration(
            color: Colors.white.withValues(
              alpha: 0.04,
            ),

            shape: BoxShape.circle,

            border: Border.all(
              color: Colors.white.withValues(
                alpha: 0.08,
              ),
            ),
          ),

          child: const Icon(
            Icons.close_rounded,

            color: Colors.white54,

            size: 16,
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // ACCENT COLOR
  // ==========================================================

  Color get _accentColor {
    switch (widget.type) {
      case GlobalChatBannerType.message:
        return _purple;

      case GlobalChatBannerType.audio:
        return _green;
    }
  }

  // ==========================================================
  // ICON
  // ==========================================================

  IconData get _icon {
    switch (widget.type) {
      case GlobalChatBannerType.message:
        return Icons.chat_bubble_rounded;

      case GlobalChatBannerType.audio:
        return Icons.mic_rounded;
    }
  }
}
