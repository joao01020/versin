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
// Banner persistente de novas mensagens.
//
// Exemplos:
//
// TEXTO:
//
// ┌─────────────────────────────────────────────┐
// │ 💬 Maria                                   │
// │ Terminei a base da música                  │
// │                              ABRIR      ×   │
// └─────────────────────────────────────────────┘
//
// ÁUDIO:
//
// ┌─────────────────────────────────────────────┐
// │ 🎙 Maria                                   │
// │ Enviou uma mensagem de áudio               │
// │                              ABRIR      ×   │
// └─────────────────────────────────────────────┘
//
// O widget NÃO conhece Supabase e NÃO controla Realtime.
// Ele somente representa o estado fornecido pelo
// GlobalChatController.
//
// ============================================================

class GlobalChatBanner
    extends
        StatelessWidget {
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
  });

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final normalizedSender = senderName.trim().isEmpty
        ? 'Membro'
        : senderName.trim();

    final normalizedPreview = preview.trim().isEmpty
        ? 'Nova mensagem'
        : preview.trim();

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

            if (unreadCount >
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
        unreadCount >
            99
        ? '99+'
        : unreadCount.toString();

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
        if (onOpen !=
            null)
          _buildOpenButton(),

        if (onOpen !=
                null &&
            onDismiss !=
                null)
          const SizedBox(
            width: 6,
          ),

        if (onDismiss !=
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
      onPressed: onOpen,

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
        onTap: onDismiss,

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
  // TYPE
  // ==========================================================

  Color get _accentColor {
    switch (type) {
      case GlobalChatBannerType.message:
        return _purple;

      case GlobalChatBannerType.audio:
        return _green;
    }
  }

  IconData get _icon {
    switch (type) {
      case GlobalChatBannerType.message:
        return Icons.chat_bubble_rounded;

      case GlobalChatBannerType.audio:
        return Icons.mic_rounded;
    }
  }
}
