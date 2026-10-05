import 'package:flutter/material.dart';
import 'package:versin/app/locator.dart';

import '../../controllers/royalties_controller.dart';
import 'chart_widget.dart';

// ============================================================
// REVENUE CARD
// ============================================================
//
// Tema:
//
// - verde = receita / crescimento;
// - roxo = identidade visual;
// - fundo escuro;
// - glow verde + roxo;
// - gráfico com altura controlada.
//
// ============================================================

class RevenueCard
    extends
        StatelessWidget {
  const RevenueCard({
    super.key,
  });

  // ============================================================
  // CORES
  // ============================================================

  static const Color _green = Color(
    0xFF00E676,
  );

  static const Color _purple = Color(
    0xFF9D6CFF,
  );

  static const Color _deepPurple = Color(
    0xFF6C3BFF,
  );

  @override
  Widget build(
    BuildContext context,
  ) {
    // ============================================================
    // CONTROLLER
    // ============================================================

    final RoyaltiesController controller =
        sl<
          RoyaltiesController
        >();

    // ============================================================
    // LISTENABLE
    // ============================================================

    return ListenableBuilder(
      listenable: controller,

      builder:
          (
            context,
            _,
          ) {
            // ========================================================
            // LOADING
            // ========================================================

            if (controller.isLoading) {
              return Container(
                width: double.infinity,

                constraints: const BoxConstraints(
                  minHeight: 220,
                ),

                decoration: BoxDecoration(
                  color: controller.cardBg,

                  borderRadius: BorderRadius.circular(
                    20,
                  ),

                  border: Border.all(
                    color: _purple.withValues(
                      alpha: 0.16,
                    ),
                  ),
                ),

                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,

                    children: [
                      SizedBox(
                        width: 28,
                        height: 28,

                        child: CircularProgressIndicator(
                          color: _green,
                          strokeWidth: 2,
                        ),
                      ),

                      SizedBox(
                        height: 12,
                      ),

                      Text(
                        'Carregando desempenho...',

                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // ========================================================
            // CONTEÚDO
            // ========================================================

            return LayoutBuilder(
              builder:
                  (
                    context,
                    constraints,
                  ) {
                    // ====================================================
                    // ALTURA DO GRÁFICO
                    // ====================================================

                    final hasBoundedHeight =
                        constraints.hasBoundedHeight &&
                        constraints.maxHeight.isFinite;

                    final availableHeight = hasBoundedHeight
                        ? constraints.maxHeight
                        : 320.0;

                    final chartHeight =
                        (availableHeight -
                                105)
                            .clamp(
                              160.0,
                              280.0,
                            )
                            .toDouble();

                    // ====================================================
                    // CARD
                    // ====================================================

                    return Container(
                      width: double.infinity,

                      decoration: BoxDecoration(
                        // ==================================================
                        // GRADIENTE VERDE + ROXO
                        // ==================================================
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,

                          colors: [
                            _purple.withValues(
                              alpha: 0.12,
                            ),

                            controller.cardBg,

                            _green.withValues(
                              alpha: 0.055,
                            ),
                          ],

                          stops: const [
                            0,
                            0.52,
                            1,
                          ],
                        ),

                        borderRadius: BorderRadius.circular(
                          20,
                        ),

                        // ==================================================
                        // BORDA
                        // ==================================================
                        border: Border.all(
                          color: _purple.withValues(
                            alpha: 0.20,
                          ),
                        ),

                        // ==================================================
                        // SOMBRA
                        // ==================================================
                        boxShadow: [
                          BoxShadow(
                            color: _deepPurple.withValues(
                              alpha: 0.07,
                            ),

                            blurRadius: 28,

                            offset: const Offset(
                              -4,
                              8,
                            ),
                          ),

                          BoxShadow(
                            color: _green.withValues(
                              alpha: 0.04,
                            ),

                            blurRadius: 28,

                            offset: const Offset(
                              4,
                              8,
                            ),
                          ),
                        ],
                      ),

                      padding: const EdgeInsets.all(
                        20,
                      ),

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,

                        children: [
                          // ==================================================
                          // HEADER
                          // ==================================================
                          Row(
                            children: [
                              // ==============================================
                              // ÍCONE
                              // ==============================================
                              Container(
                                width: 40,
                                height: 40,

                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,

                                    colors: [
                                      _purple.withValues(
                                        alpha: 0.22,
                                      ),

                                      _green.withValues(
                                        alpha: 0.10,
                                      ),
                                    ],
                                  ),

                                  borderRadius: BorderRadius.circular(
                                    12,
                                  ),

                                  border: Border.all(
                                    color: _purple.withValues(
                                      alpha: 0.20,
                                    ),
                                  ),

                                  boxShadow: [
                                    BoxShadow(
                                      color: _purple.withValues(
                                        alpha: 0.10,
                                      ),

                                      blurRadius: 12,
                                    ),
                                  ],
                                ),

                                child: const Icon(
                                  Icons.show_chart_rounded,
                                  color: _green,
                                  size: 20,
                                ),
                              ),

                              const SizedBox(
                                width: 12,
                              ),

                              // ==============================================
                              // TÍTULO
                              // ==============================================
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,

                                  children: [
                                    Text(
                                      'TENDÊNCIA DE RECEITA',

                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.8,
                                      ),
                                    ),

                                    SizedBox(
                                      height: 3,
                                    ),

                                    Text(
                                      'Evolução dos seus royalties',

                                      style: TextStyle(
                                        color: Colors.white38,
                                        fontSize: 9,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // ==============================================
                              // INDICADOR DE CRESCIMENTO
                              // ==============================================
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),

                                decoration: BoxDecoration(
                                  color: _green.withValues(
                                    alpha: 0.08,
                                  ),

                                  borderRadius: BorderRadius.circular(
                                    999,
                                  ),

                                  border: Border.all(
                                    color: _green.withValues(
                                      alpha: 0.20,
                                    ),
                                  ),
                                ),

                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,

                                  children: [
                                    Icon(
                                      Icons.trending_up_rounded,
                                      color: _green,
                                      size: 13,
                                    ),

                                    SizedBox(
                                      width: 5,
                                    ),

                                    Text(
                                      'Tendência',

                                      style: TextStyle(
                                        color: _green,
                                        fontSize: 8,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(
                            height: 16,
                          ),

                          // ==================================================
                          // DIVISOR VERDE + ROXO
                          // ==================================================
                          Container(
                            width: double.infinity,
                            height: 1,

                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _purple.withValues(
                                    alpha: 0.35,
                                  ),

                                  _green.withValues(
                                    alpha: 0.28,
                                  ),

                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(
                            height: 14,
                          ),

                          // ==================================================
                          // GRÁFICO
                          // ==================================================
                          Container(
                            width: double.infinity,
                            height: chartHeight,

                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,

                                colors: [
                                  _purple.withValues(
                                    alpha: 0.025,
                                  ),

                                  _green.withValues(
                                    alpha: 0.015,
                                  ),

                                  Colors.transparent,
                                ],
                              ),

                              borderRadius: BorderRadius.circular(
                                14,
                              ),
                            ),

                            child: const RoyaltyChartWidget(),
                          ),
                        ],
                      ),
                    );
                  },
            );
          },
    );
  }
}
