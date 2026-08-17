import 'package:flutter/material.dart';

// ============================================================
// GLOBAL CALL BANNER STATE
// ============================================================
//
// Estado visual do banner global.
//
// O banner NÃO controla WebRTC nem Supabase.
//
// Ele somente recebe o estado atual da chamada e o representa
// visualmente.
//
// ============================================================

enum GlobalCallBannerState {
  hidden,
  calling,
  incoming,
  active,
  ending,
}

// ============================================================
// GLOBAL CALL MEDIA TYPE
// ============================================================

enum GlobalCallMediaType {
  audio,
  video,
}

// ============================================================
// GLOBAL CALL BANNER
// ============================================================
//
// Banner persistente de chamada.
//
// Pode ser colocado no Shell principal do aplicativo para
// continuar aparecendo mesmo quando o usuário sair da página
// de ligação.
//
// Exemplos:
//
// calling
// -> Chamando João... · 00:12
//
// incoming
// -> Ligação de João · 00:12
//
// active
// -> Chamada em andamento
//
// ending
// -> Encerrando chamada...
//
// ============================================================

class GlobalCallBanner
    extends
        StatelessWidget {
  // ==========================================================
  // CORES
  // ==========================================================

  static const Color _background = Color(
    0xFF121217,
  );

  static const Color _green = Color(
    0xFF34D399,
  );

  static const Color _red = Color(
    0xFFEF4444,
  );

  static const Color _purple = Color(
    0xFF8B5CF6,
  );

  static const Color _orange = Color(
    0xFFF59E0B,
  );

  // ==========================================================
  // ESTADO
  // ==========================================================

  final GlobalCallBannerState state;

  // ==========================================================
  // TIPO DE MÍDIA
  // ==========================================================

  final GlobalCallMediaType mediaType;

  // ==========================================================
  // PARTICIPANTE
  // ==========================================================

  final String? participantName;

  // ==========================================================
  // TEMPO
  // ==========================================================

  // Tempo enquanto a chamada está tocando.
  final Duration? ringingDuration;

  // Tempo da chamada depois que foi atendida.
  final Duration? duration;

  // ==========================================================
  // CALLBACKS
  // ==========================================================

  final VoidCallback? onOpen;

  final VoidCallback? onAccept;

  final VoidCallback? onReject;

  final VoidCallback? onEnd;

  // ==========================================================
  // CONSTRUCTOR
  // ==========================================================

  const GlobalCallBanner({
    super.key,
    required this.state,
    this.mediaType = GlobalCallMediaType.audio,
    this.participantName,
    this.ringingDuration,
    this.duration,
    this.onOpen,
    this.onAccept,
    this.onReject,
    this.onEnd,
  });

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    // ========================================================
    // HIDDEN
    // ========================================================

    if (state ==
        GlobalCallBannerState.hidden) {
      return const SizedBox.shrink();
    }

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
            minHeight: 62,
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
              color: _stateColor.withValues(
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
              // ==================================================
              // ÍCONE
              // ==================================================
              _buildIcon(),

              const SizedBox(
                width: 12,
              ),

              // ==================================================
              // INFORMAÇÕES
              // ==================================================
              Expanded(
                child: _buildInformation(),
              ),

              const SizedBox(
                width: 10,
              ),

              // ==================================================
              // AÇÕES
              // ==================================================
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
      width: 40,

      height: 40,

      decoration: BoxDecoration(
        color: _stateColor.withValues(
          alpha: 0.12,
        ),

        shape: BoxShape.circle,

        border: Border.all(
          color: _stateColor.withValues(
            alpha: 0.25,
          ),
        ),
      ),

      child: Icon(
        _stateIcon,

        color: _stateColor,

        size: 20,
      ),
    );
  }

  // ==========================================================
  // INFORMATION
  // ==========================================================

  Widget _buildInformation() {
    return Column(
      mainAxisSize: MainAxisSize.min,

      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        // ======================================================
        // TITLE
        // ======================================================
        Text(
          _title,

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

        // ======================================================
        // SUBTITLE
        // ======================================================
        Row(
          children: [
            // ==================================================
            // STATUS DOT
            // ==================================================
            Container(
              width: 6,

              height: 6,

              decoration: BoxDecoration(
                color: _stateColor,

                shape: BoxShape.circle,
              ),
            ),

            const SizedBox(
              width: 6,
            ),

            Flexible(
              child: Text(
                _subtitle,

                maxLines: 1,

                overflow: TextOverflow.ellipsis,

                style: const TextStyle(
                  color: Colors.white38,

                  fontSize: 9,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================================
  // ACTIONS
  // ==========================================================

  Widget _buildActions() {
    switch (state) {
      // ========================================================
      // INCOMING
      // ========================================================

      case GlobalCallBannerState.incoming:
        return Row(
          mainAxisSize: MainAxisSize.min,

          children: [
            _buildCircleAction(
              icon: Icons.call_end_rounded,

              color: _red,

              tooltip: 'Recusar',

              onPressed: onReject,
            ),

            const SizedBox(
              width: 8,
            ),

            _buildCircleAction(
              icon:
                  mediaType ==
                      GlobalCallMediaType.video
                  ? Icons.videocam_rounded
                  : Icons.call_rounded,

              color: _green,

              tooltip:
                  mediaType ==
                      GlobalCallMediaType.video
                  ? 'Atender vídeo'
                  : 'Atender',

              onPressed: onAccept,
            ),
          ],
        );

      // ========================================================
      // CALLING
      // ========================================================

      case GlobalCallBannerState.calling:
        return Row(
          mainAxisSize: MainAxisSize.min,

          children: [
            if (onOpen !=
                null) ...[
              _buildOpenButton(),

              const SizedBox(
                width: 8,
              ),
            ],

            _buildCircleAction(
              icon: Icons.call_end_rounded,

              color: _red,

              tooltip: 'Cancelar chamada',

              onPressed: onEnd,
            ),
          ],
        );

      // ========================================================
      // ACTIVE
      // ========================================================

      case GlobalCallBannerState.active:
        return Row(
          mainAxisSize: MainAxisSize.min,

          children: [
            if (onOpen !=
                null) ...[
              _buildOpenButton(),

              const SizedBox(
                width: 8,
              ),
            ],

            _buildCircleAction(
              icon: Icons.call_end_rounded,

              color: _red,

              tooltip: 'Encerrar chamada',

              onPressed: onEnd,
            ),
          ],
        );

      // ========================================================
      // ENDING
      // ========================================================

      case GlobalCallBannerState.ending:
        return const SizedBox(
          width: 18,

          height: 18,

          child: CircularProgressIndicator(
            strokeWidth: 2,

            color: _orange,
          ),
        );

      // ========================================================
      // HIDDEN
      // ========================================================

      case GlobalCallBannerState.hidden:
        return const SizedBox.shrink();
    }
  }

  // ==========================================================
  // OPEN BUTTON
  // ==========================================================

  Widget _buildOpenButton() {
    return TextButton(
      onPressed: onOpen,

      style: TextButton.styleFrom(
        foregroundColor: _purple,

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
  // CIRCLE ACTION
  // ==========================================================

  Widget _buildCircleAction({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    return Tooltip(
      message: tooltip,

      child: InkWell(
        onTap: onPressed,

        borderRadius: BorderRadius.circular(
          30,
        ),

        child: Container(
          width: 34,

          height: 34,

          decoration: BoxDecoration(
            color: color.withValues(
              alpha:
                  onPressed ==
                      null
                  ? 0.05
                  : 0.12,
            ),

            shape: BoxShape.circle,

            border: Border.all(
              color: color.withValues(
                alpha:
                    onPressed ==
                        null
                    ? 0.10
                    : 0.25,
              ),
            ),
          ),

          child: Icon(
            icon,

            color:
                onPressed ==
                    null
                ? color.withValues(
                    alpha: 0.30,
                  )
                : color,

            size: 17,
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // TITLE
  // ==========================================================

  String get _title {
    final normalizedName = participantName?.trim();

    final name =
        normalizedName ==
                null ||
            normalizedName.isEmpty
        ? 'Membro da sessão'
        : normalizedName;

    final isVideo =
        mediaType ==
        GlobalCallMediaType.video;

    switch (state) {
      case GlobalCallBannerState.calling:
        return isVideo
            ? 'Chamando $name por vídeo...'
            : 'Chamando $name...';

      case GlobalCallBannerState.incoming:
        return isVideo
            ? 'Chamada de vídeo de $name'
            : 'Ligação de $name';

      case GlobalCallBannerState.active:
        return isVideo
            ? 'Vídeo com $name'
            : name;

      case GlobalCallBannerState.ending:
        return isVideo
            ? 'Encerrando chamada de vídeo'
            : 'Encerrando chamada';

      case GlobalCallBannerState.hidden:
        return '';
    }
  }

  // ==========================================================
  // SUBTITLE
  // ==========================================================

  String get _subtitle {
    final isVideo =
        mediaType ==
        GlobalCallMediaType.video;

    switch (state) {
      case GlobalCallBannerState.calling:
        final value = ringingDuration;

        final baseText = isVideo
            ? 'Aguardando atendimento por vídeo'
            : 'Aguardando atendimento';

        if (value ==
            null) {
          return baseText;
        }

        return '$baseText · ${_formatDuration(value)}';

      case GlobalCallBannerState.incoming:
        final value = ringingDuration;

        final baseText = isVideo
            ? 'Chamada de vídeo recebida'
            : 'Chamada recebida';

        if (value ==
            null) {
          return baseText;
        }

        return '$baseText · ${_formatDuration(value)}';

      case GlobalCallBannerState.active:
        final value = duration;

        final baseText = isVideo
            ? 'Vídeo em andamento'
            : 'Chamada em andamento';

        if (value ==
            null) {
          return baseText;
        }

        return '$baseText · ${_formatDuration(value)}';

      case GlobalCallBannerState.ending:
        return 'Finalizando conexão';

      case GlobalCallBannerState.hidden:
        return '';
    }
  }

  // ==========================================================
  // STATE COLOR
  // ==========================================================

  Color get _stateColor {
    switch (state) {
      case GlobalCallBannerState.calling:
        return _purple;

      case GlobalCallBannerState.incoming:
        return _green;

      case GlobalCallBannerState.active:
        return _green;

      case GlobalCallBannerState.ending:
        return _orange;

      case GlobalCallBannerState.hidden:
        return Colors.transparent;
    }
  }

  // ==========================================================
  // STATE ICON
  // ==========================================================

  IconData get _stateIcon {
    if (state ==
        GlobalCallBannerState.ending) {
      return Icons.call_end_rounded;
    }

    if (mediaType ==
        GlobalCallMediaType.video) {
      switch (state) {
        case GlobalCallBannerState.calling:
          return Icons.videocam_rounded;

        case GlobalCallBannerState.incoming:
          return Icons.video_call_rounded;

        case GlobalCallBannerState.active:
          return Icons.videocam_rounded;

        case GlobalCallBannerState.ending:
          return Icons.call_end_rounded;

        case GlobalCallBannerState.hidden:
          return Icons.videocam_rounded;
      }
    }

    switch (state) {
      case GlobalCallBannerState.calling:
        return Icons.phone_in_talk_rounded;

      case GlobalCallBannerState.incoming:
        return Icons.ring_volume_rounded;

      case GlobalCallBannerState.active:
        return Icons.call_rounded;

      case GlobalCallBannerState.ending:
        return Icons.call_end_rounded;

      case GlobalCallBannerState.hidden:
        return Icons.call_rounded;
    }
  }

  // ==========================================================
  // FORMAT DURATION
  // ==========================================================

  String _formatDuration(
    Duration value,
  ) {
    final totalSeconds = value.inSeconds;

    final hours =
        totalSeconds ~/
        3600;

    final minutes =
        (totalSeconds %
            3600) ~/
        60;

    final seconds =
        totalSeconds %
        60;

    if (hours >
        0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
}
