import 'package:flutter/material.dart';

import '../controllers/dashboard_controller.dart';

// ============================================================
// VERSIN STATISTICS CARD WIDGET
// ============================================================
//
// Card responsável por apresentar as estatísticas do Versin.
//
// RECURSOS:
//
// - gráfico mensal;
// - verde + roxo;
// - destaque do mês atual;
// - indicador de crescimento;
// - expandir;
// - recolher;
// - animação de abertura e fechamento.
//
// ============================================================

class VersinStatisticsCardWidget
    extends
        StatefulWidget {
  final DashboardController controller;

  const VersinStatisticsCardWidget({
    super.key,
    required this.controller,
  });

  @override
  State<
    VersinStatisticsCardWidget
  >
  createState() => _VersinStatisticsCardWidgetState();
}

// ============================================================
// STATE
// ============================================================

class _VersinStatisticsCardWidgetState
    extends
        State<
          VersinStatisticsCardWidget
        >
    with
        SingleTickerProviderStateMixin {
  // ============================================================
  // ESTADO
  // ============================================================

  bool _isExpanded = true;

  // ============================================================
  // MESES
  // ============================================================

  static const List<
    String
  >
  _months = [
    'Jan',
    'Fev',
    'Mar',
    'Abr',
    'Mai',
    'Jun',
    'Jul',
    'Ago',
    'Set',
    'Out',
    'Nov',
    'Dez',
  ];

  // ============================================================
  // CONTROLLER
  // ============================================================

  DashboardController get controller => widget.controller;

  // ============================================================
  // MÊS ATUAL
  // ============================================================

  int get _currentMonthIndex {
    return DateTime.now().month -
        1;
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
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return AnimatedContainer(
      duration: const Duration(
        milliseconds: 300,
      ),

      curve: Curves.easeOutCubic,

      width: double.infinity,

      padding: const EdgeInsets.all(
        24,
      ),

      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,

          end: Alignment.bottomRight,

          colors: [
            controller.primaryPurple.withValues(
              alpha: 0.10,
            ),

            Colors.white.withValues(
              alpha: 0.035,
            ),

            controller.accentNeon.withValues(
              alpha: 0.025,
            ),
          ],
        ),

        borderRadius: BorderRadius.circular(
          24,
        ),

        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.08,
          ),
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.15,
            ),

            blurRadius: 24,

            offset: const Offset(
              0,
              10,
            ),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          // ====================================================
          // HEADER
          // ====================================================
          _buildHeader(),

          // ====================================================
          // CONTEÚDO EXPANSÍVEL
          // ====================================================
          AnimatedSize(
            duration: const Duration(
              milliseconds: 320,
            ),

            curve: Curves.easeOutCubic,

            alignment: Alignment.topCenter,

            child: _isExpanded
                ? _buildExpandedContent()
                : const SizedBox(
                    width: double.infinity,

                    height: 0,
                  ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,

      children: [
        // ======================================================
        // ÍCONE
        // ======================================================
        Container(
          width: 42,

          height: 42,

          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,

              end: Alignment.bottomRight,

              colors: [
                controller.primaryPurple.withValues(
                  alpha: 0.20,
                ),

                controller.accentNeon.withValues(
                  alpha: 0.10,
                ),
              ],
            ),

            borderRadius: BorderRadius.circular(
              13,
            ),

            border: Border.all(
              color: controller.primaryPurple.withValues(
                alpha: 0.20,
              ),
            ),
          ),

          child: Icon(
            Icons.bar_chart_rounded,

            color: controller.accentNeon,

            size: 21,
          ),
        ),

        const SizedBox(
          width: 12,
        ),

        // ======================================================
        // TÍTULO
        // ======================================================
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                'Estatísticas Versin',

                style: TextStyle(
                  color: Colors.white,

                  fontSize: 16,

                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(
                height: 4,
              ),

              Text(
                'Evolução dos últimos 12 meses',

                style: TextStyle(
                  color: Colors.white38,

                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),

        // ======================================================
        // CRESCIMENTO
        // ======================================================
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,

            vertical: 6,
          ),

          decoration: BoxDecoration(
            color: controller.accentNeon.withValues(
              alpha: 0.08,
            ),

            borderRadius: BorderRadius.circular(
              999,
            ),

            border: Border.all(
              color: controller.accentNeon.withValues(
                alpha: 0.15,
              ),
            ),
          ),

          child: Row(
            mainAxisSize: MainAxisSize.min,

            children: [
              Icon(
                Icons.trending_up_rounded,

                color: controller.accentNeon,

                size: 13,
              ),

              const SizedBox(
                width: 4,
              ),

              Text(
                '+18.4%',

                style: TextStyle(
                  color: controller.accentNeon,

                  fontSize: 9,

                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(
          width: 8,
        ),

        // ======================================================
        // EXPANDIR / RECOLHER
        // ======================================================
        Tooltip(
          message: _isExpanded
              ? 'Recolher gráfico'
              : 'Expandir gráfico',

          child: Material(
            color: Colors.transparent,

            child: InkWell(
              onTap: _toggleExpanded,

              borderRadius: BorderRadius.circular(
                10,
              ),

              child: Container(
                width: 36,

                height: 36,

                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: 0.04,
                  ),

                  borderRadius: BorderRadius.circular(
                    10,
                  ),

                  border: Border.all(
                    color: Colors.white.withValues(
                      alpha: 0.07,
                    ),
                  ),
                ),

                child: AnimatedRotation(
                  turns: _isExpanded
                      ? 0
                      : 0.5,

                  duration: const Duration(
                    milliseconds: 250,
                  ),

                  curve: Curves.easeOutCubic,

                  child: const Icon(
                    Icons.keyboard_arrow_up_rounded,

                    color: Colors.white54,

                    size: 21,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CONTEÚDO EXPANDIDO
  // ============================================================

  Widget _buildExpandedContent() {
    return Column(
      children: [
        const SizedBox(
          height: 28,
        ),

        // ======================================================
        // GRÁFICO
        // ======================================================
        SizedBox(
          height: 190,

          child: Column(
            children: [
              // ==================================================
              // ÁREA DAS BARRAS
              // ==================================================
              Expanded(
                child: Stack(
                  children: [
                    // ==============================================
                    // LINHAS DE REFERÊNCIA
                    // ==============================================
                    _buildBackgroundLines(),

                    // ==============================================
                    // BARRAS
                    // ==============================================
                    _buildBars(),
                  ],
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              // ==================================================
              // LINHA BASE
              // ==================================================
              Container(
                width: double.infinity,

                height: 1,

                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      controller.primaryPurple.withValues(
                        alpha: 0.15,
                      ),

                      Colors.white.withValues(
                        alpha: 0.06,
                      ),

                      controller.accentNeon.withValues(
                        alpha: 0.12,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(
                height: 9,
              ),

              // ==================================================
              // MESES
              // ==================================================
              _buildMonthLabels(),
            ],
          ),
        ),

        const SizedBox(
          height: 4,
        ),
      ],
    );
  }

  // ============================================================
  // LINHAS DO FUNDO
  // ============================================================

  Widget _buildBackgroundLines() {
    return Positioned.fill(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,

        children: List.generate(
          4,
          (
            index,
          ) {
            return Container(
              width: double.infinity,

              height: 1,

              color: Colors.white.withValues(
                alpha: 0.035,
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // BARRAS
  // ============================================================

  Widget _buildBars() {
    return Positioned.fill(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,

        children: List.generate(
          12,
          (
            index,
          ) {
            // ==================================================
            // DADOS TEMPORÁRIOS
            // ==================================================
            //
            // Depois podemos substituir isso por dados reais:
            //
            // controller.monthlyStatistics[index]
            //
            // ==================================================

            final barHeight =
                (20 +
                        (index *
                            12)) %
                    100 +
                40.0;

            final isCurrentMonth =
                index ==
                _currentMonthIndex;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                ),

                child: Align(
                  alignment: Alignment.bottomCenter,

                  child: AnimatedContainer(
                    duration: Duration(
                      milliseconds:
                          300 +
                          (index *
                              25),
                    ),

                    curve: Curves.easeOutCubic,

                    height: barHeight,

                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,

                        end: Alignment.bottomCenter,

                        colors: isCurrentMonth
                            ? [
                                controller.accentNeon,
                                controller.primaryPurple,
                              ]
                            : [
                                controller.primaryPurple.withValues(
                                  alpha: 0.72,
                                ),

                                controller.primaryPurple.withValues(
                                  alpha: 0.20,
                                ),
                              ],
                      ),

                      borderRadius: BorderRadius.circular(
                        7,
                      ),

                      border: Border.all(
                        color: isCurrentMonth
                            ? controller.accentNeon.withValues(
                                alpha: 0.22,
                              )
                            : Colors.white.withValues(
                                alpha: 0.03,
                              ),
                      ),

                      boxShadow: isCurrentMonth
                          ? [
                              BoxShadow(
                                color: controller.accentNeon.withValues(
                                  alpha: 0.28,
                                ),

                                blurRadius: 14,

                                offset: const Offset(
                                  0,
                                  4,
                                ),
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // LABELS DOS MESES
  // ============================================================

  Widget _buildMonthLabels() {
    return Row(
      children: List.generate(
        _months.length,
        (
          index,
        ) {
          final isCurrentMonth =
              index ==
              _currentMonthIndex;

          return Expanded(
            child: Text(
              _months[index],

              textAlign: TextAlign.center,

              style: TextStyle(
                color: isCurrentMonth
                    ? controller.accentNeon
                    : Colors.white30,

                fontSize: 9,

                fontWeight: isCurrentMonth
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }
}
