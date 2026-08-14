import 'package:flutter/material.dart';

import 'package:versin/features/rhymes/presentation/controller/rhymes_controller.dart';

// ============================================================
// AI MONTHLY USAGE CARD WIDGET
// ============================================================
//
// Card responsável por exibir:
//
// - uso mensal da IA;
// - percentual utilizado;
// - status atual;
// - barra de progresso;
// - mensagem contextual;
// - tokens usados;
// - tokens restantes;
// - limite mensal;
// - modo expandido;
// - modo compacto.
//
// No modo compacto:
//
// - mantém o header;
// - mostra o status;
// - mostra a barra de progresso.
//
// ============================================================

class AiMonthlyUsageCardWidget
    extends
        StatefulWidget {
  final RhymesController controller;

  const AiMonthlyUsageCardWidget({
    super.key,
    required this.controller,
  });

  @override
  State<
    AiMonthlyUsageCardWidget
  >
  createState() => _AiMonthlyUsageCardWidgetState();
}

// ============================================================
// STATE
// ============================================================

class _AiMonthlyUsageCardWidgetState
    extends
        State<
          AiMonthlyUsageCardWidget
        > {
  // ============================================================
  // EXPANSÃO
  // ============================================================

  bool _isExpanded = true;

  // ============================================================
  // CONTROLLER
  // ============================================================

  RhymesController get controller => widget.controller;

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final percentage = controller.aiUsagePercentage.clamp(
      0.0,
      100.0,
    );

    final progress = controller.aiUsageProgress.clamp(
      0.0,
      1.0,
    );

    final level = controller.aiUsageLevel;

    final message = controller.aiUsageMessage;

    final usedTokens = controller.aiUsedTokens;

    final remainingTokens = controller.aiRemainingTokens;

    final limitTokens = controller.aiLimitTokens;

    final accentColor = _accentForLevel(
      level,
      percentage,
    );

    final statusText = _statusText(
      level,
      percentage,
    );

    return AnimatedContainer(
      duration: const Duration(
        milliseconds: 220,
      ),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      padding: const EdgeInsets.all(
        16,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(
          0.035,
        ),
        borderRadius: BorderRadius.circular(
          16,
        ),
        border: Border.all(
          color: accentColor.withOpacity(
            percentage >=
                    70
                ? 0.30
                : 0.12,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ====================================================
          // HEADER
          // ====================================================
          _buildHeader(
            accentColor: accentColor,
            percentage: percentage,
          ),

          // ====================================================
          // CONTEÚDO
          // ====================================================
          AnimatedCrossFade(
            duration: const Duration(
              milliseconds: 220,
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: _buildExpandedContent(
              accentColor: accentColor,
              percentage: percentage,
              progress: progress,
              level: level,
              statusText: statusText,
              message: message,
              usedTokens: usedTokens,
              remainingTokens: remainingTokens,
              limitTokens: limitTokens,
            ),
            secondChild: _buildCollapsedContent(
              accentColor: accentColor,
              progress: progress,
              statusText: statusText,
              level: level,
              percentage: percentage,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader({
    required Color accentColor,
    required double percentage,
  }) {
    return Row(
      children: [
        // ======================================================
        // ÍCONE
        // ======================================================
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: accentColor.withOpacity(
              0.10,
            ),
            borderRadius: BorderRadius.circular(
              12,
            ),
            border: Border.all(
              color: accentColor.withOpacity(
                0.22,
              ),
            ),
          ),
          child: Icon(
            Icons.auto_awesome_rounded,
            color: accentColor,
            size: 20,
          ),
        ),

        const SizedBox(
          width: 12,
        ),

        // ======================================================
        // TÍTULO
        // ======================================================
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'IA mensal',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),

              if (_isExpanded) ...[
                const SizedBox(
                  height: 2,
                ),

                const Text(
                  'Uso da sua cota mensal de inteligência artificial',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(
          width: 10,
        ),

        // ======================================================
        // PERCENTUAL
        // ======================================================
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: accentColor.withOpacity(
              0.10,
            ),
            borderRadius: BorderRadius.circular(
              20,
            ),
            border: Border.all(
              color: accentColor.withOpacity(
                0.22,
              ),
            ),
          ),
          child: Text(
            '${_formatPercentage(percentage)}%',
            style: TextStyle(
              color: accentColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ),

        const SizedBox(
          width: 6,
        ),

        // ======================================================
        // EXPANDIR / RECOLHER
        // ======================================================
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(
              20,
            ),
            onTap: _toggleExpanded,
            child: Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              child: AnimatedRotation(
                turns: _isExpanded
                    ? 0
                    : 0.5,
                duration: const Duration(
                  milliseconds: 220,
                ),
                child: const Icon(
                  Icons.keyboard_arrow_up_rounded,
                  color: Colors.white54,
                  size: 21,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EXPANDIDO
  // ============================================================

  Widget _buildExpandedContent({
    required Color accentColor,
    required double percentage,
    required double progress,
    required String level,
    required String statusText,
    required String message,
    required int usedTokens,
    required int remainingTokens,
    required int limitTokens,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(
          height: 16,
        ),

        // ======================================================
        // STATUS
        // ======================================================
        _buildStatus(
          accentColor: accentColor,
          level: level,
          percentage: percentage,
          statusText: statusText,
        ),

        const SizedBox(
          height: 9,
        ),

        // ======================================================
        // BARRA
        // ======================================================
        _buildProgressBar(
          progress: progress,
          accentColor: accentColor,
          height: 10,
        ),

        const SizedBox(
          height: 6,
        ),

        // ======================================================
        // MARCADORES
        // ======================================================
        const Row(
          children: [
            Text(
              '0%',
              style: TextStyle(
                color: Colors.white24,
                fontSize: 9,
              ),
            ),

            Spacer(),

            Text(
              '70%',
              style: TextStyle(
                color: Colors.white24,
                fontSize: 9,
              ),
            ),

            SizedBox(
              width: 24,
            ),

            Text(
              '90%',
              style: TextStyle(
                color: Colors.white24,
                fontSize: 9,
              ),
            ),

            SizedBox(
              width: 18,
            ),

            Text(
              '100%',
              style: TextStyle(
                color: Colors.white24,
                fontSize: 9,
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 12,
        ),

        // ======================================================
        // MENSAGEM
        // ======================================================
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: accentColor.withOpacity(
              0.06,
            ),
            borderRadius: BorderRadius.circular(
              10,
            ),
            border: Border.all(
              color: accentColor.withOpacity(
                0.12,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: accentColor.withOpacity(
                  0.90,
                ),
                size: 15,
              ),

              const SizedBox(
                width: 8,
              ),

              Expanded(
                child: Text(
                  _normalizeMessage(
                    message,
                    percentage,
                  ),
                  style: TextStyle(
                    color: accentColor.withOpacity(
                      0.92,
                    ),
                    fontSize: 11,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(
          height: 14,
        ),

        // ======================================================
        // TOKENS
        // ======================================================
        Row(
          children: [
            Expanded(
              child: _buildMetric(
                label: 'USADOS',
                value: _formatTokens(
                  usedTokens,
                ),
              ),
            ),

            const SizedBox(
              width: 8,
            ),

            Expanded(
              child: _buildMetric(
                label: 'RESTANTES',
                value: _formatTokens(
                  remainingTokens,
                ),
              ),
            ),

            const SizedBox(
              width: 8,
            ),

            Expanded(
              child: _buildMetric(
                label: 'LIMITE',
                value: _formatTokens(
                  limitTokens,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // RECOLHIDO
  // ============================================================
  //
  // Mostra:
  //
  // Uso normal
  // barra
  //
  // Não mostra:
  //
  // - "0% utilizado";
  // - marcadores;
  // - mensagem;
  // - métricas.
  //
  // ============================================================

  Widget _buildCollapsedContent({
    required Color accentColor,
    required double progress,
    required String statusText,
    required String level,
    required double percentage,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(
          height: 12,
        ),

        // ======================================================
        // STATUS
        // ======================================================
        _buildStatus(
          accentColor: accentColor,
          level: level,
          percentage: percentage,
          statusText: statusText,
        ),

        const SizedBox(
          height: 9,
        ),

        // ======================================================
        // BARRA
        // ======================================================
        _buildProgressBar(
          progress: progress,
          accentColor: accentColor,
          height: 7,
        ),
      ],
    );
  }

  // ============================================================
  // STATUS
  // ============================================================

  Widget _buildStatus({
    required Color accentColor,
    required String level,
    required double percentage,
    required String statusText,
  }) {
    return Row(
      children: [
        Icon(
          _iconForLevel(
            level,
            percentage,
          ),
          size: 15,
          color: accentColor,
        ),

        const SizedBox(
          width: 7,
        ),

        Text(
          statusText,
          style: TextStyle(
            color: accentColor,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BARRA DE PROGRESSO
  // ============================================================

  Widget _buildProgressBar({
    required double progress,
    required Color accentColor,
    required double height,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(
        20,
      ),
      child: LinearProgressIndicator(
        value: progress,
        minHeight: height,
        backgroundColor: Colors.white.withOpacity(
          0.07,
        ),
        valueColor:
            AlwaysStoppedAnimation<
              Color
            >(
              accentColor,
            ),
      ),
    );
  }

  // ============================================================
  // EXPANDIR / RECOLHER
  // ============================================================

  void _toggleExpanded() {
    setState(
      () {
        _isExpanded = !_isExpanded;
      },
    );
  }

  // ============================================================
  // MÉTRICA
  // ============================================================

  Widget _buildMetric({
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(
          0.18,
        ),
        borderRadius: BorderRadius.circular(
          10,
        ),
        border: Border.all(
          color: Colors.white.withOpacity(
            0.04,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white30,
              fontSize: 8,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.7,
            ),
          ),

          const SizedBox(
            height: 3,
          ),

          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COR POR NÍVEL
  // ============================================================

  Color _accentForLevel(
    String level,
    double percentage,
  ) {
    final normalizedLevel = level.toLowerCase();

    if (percentage >=
            100 ||
        normalizedLevel ==
            'blocked') {
      return Colors.redAccent;
    }

    if (percentage >=
            90 ||
        normalizedLevel ==
            'critical') {
      return Colors.orangeAccent;
    }

    if (percentage >=
            70 ||
        normalizedLevel ==
            'warning') {
      return Colors.amberAccent;
    }

    return const Color(
      0xFFE100FF,
    );
  }

  // ============================================================
  // ÍCONE POR NÍVEL
  // ============================================================

  IconData _iconForLevel(
    String level,
    double percentage,
  ) {
    final normalizedLevel = level.toLowerCase();

    if (percentage >=
            100 ||
        normalizedLevel ==
            'blocked') {
      return Icons.block_rounded;
    }

    if (percentage >=
            90 ||
        normalizedLevel ==
            'critical') {
      return Icons.warning_amber_rounded;
    }

    if (percentage >=
            70 ||
        normalizedLevel ==
            'warning') {
      return Icons.info_outline_rounded;
    }

    return Icons.check_circle_outline_rounded;
  }

  // ============================================================
  // STATUS
  // ============================================================

  String _statusText(
    String level,
    double percentage,
  ) {
    final normalizedLevel = level.toLowerCase();

    if (percentage >=
            100 ||
        normalizedLevel ==
            'blocked') {
      return 'Limite atingido';
    }

    if (percentage >=
            90 ||
        normalizedLevel ==
            'critical') {
      return 'Limite próximo';
    }

    if (percentage >=
            70 ||
        normalizedLevel ==
            'warning') {
      return 'Uso elevado';
    }

    return 'Uso normal';
  }

  // ============================================================
  // MENSAGEM
  // ============================================================

  String _normalizeMessage(
    String message,
    double percentage,
  ) {
    final normalized = message.trim();

    if (percentage >=
        100) {
      return 'Limite mensal de IA atingido.';
    }

    if (percentage >=
        90) {
      return 'Seu limite mensal está próximo.';
    }

    if (percentage >=
        70) {
      return 'Você já utilizou boa parte da sua IA este mês.';
    }

    if (normalized.isNotEmpty) {
      return normalized;
    }

    return 'Uso normal da IA.';
  }

  // ============================================================
  // FORMATAR PERCENTUAL
  // ============================================================

  static String _formatPercentage(
    double percentage,
  ) {
    if (percentage ==
        percentage.roundToDouble()) {
      return percentage.toInt().toString();
    }

    return percentage.toStringAsFixed(
      1,
    );
  }

  // ============================================================
  // FORMATAR TOKENS
  // ============================================================

  String _formatTokens(
    int value,
  ) {
    if (value >=
        1000000) {
      final millions =
          value /
          1000000;

      if (millions ==
          millions.roundToDouble()) {
        return '${millions.toInt()}M';
      }

      return '${millions.toStringAsFixed(1)}M';
    }

    if (value >=
        1000) {
      final thousands =
          value /
          1000;

      if (thousands ==
          thousands.roundToDouble()) {
        return '${thousands.toInt()}k';
      }

      return '${thousands.toStringAsFixed(1)}k';
    }

    return value.toString();
  }
}
