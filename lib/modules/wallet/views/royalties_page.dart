import 'package:flutter/material.dart';
import 'package:versin/app/locator.dart';
import 'package:versin/modules/wallet/widgets/royalties/revenue_card.dart';

import '../controllers/royalties_controller.dart';

class RoyaltiesPage
    extends
        StatelessWidget {
  const RoyaltiesPage({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final controller =
        sl<
          RoyaltiesController
        >();

    return Scaffold(
      backgroundColor: controller.deepBg,

      body: Container(
        width: double.infinity,

        height: double.infinity,

        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,

            end: Alignment.bottomRight,

            colors: [
              Color(
                0xFF17122D,
              ),
              Color(
                0xFF0D0B1F,
              ),
              Color(
                0xFF090812,
              ),
            ],

            stops: [
              0,
              0.58,
              1,
            ],
          ),
        ),

        child: SafeArea(
          child: ListenableBuilder(
            listenable: controller,

            builder:
                (
                  context,
                  _,
                ) {
                  return Column(
                    children: [
                      // ==================================================
                      // HEADER
                      // ==================================================
                      _buildHeader(
                        context,
                        controller,
                      ),

                      // ==================================================
                      // CONTEÚDO
                      // ==================================================
                      Expanded(
                        child: controller.isLoading
                            ? _buildLoading(
                                controller,
                              )
                            : _buildContent(
                                context,
                                controller,
                              ),
                      ),
                    ],
                  );
                },
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
    RoyaltiesController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        24,
        20,
        24,
        10,
      ),

      child: Row(
        children: [
          // ======================================================
          // VOLTAR
          // ======================================================
          _buildHeaderButton(
            icon: Icons.arrow_back_rounded,

            tooltip: 'Voltar',

            onTap: () {
              Navigator.of(
                context,
              ).maybePop();
            },
          ),

          const SizedBox(
            width: 14,
          ),

          // ======================================================
          // TÍTULO
          // ======================================================
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  'ROYALTIES',

                  style: TextStyle(
                    color: Colors.white,

                    fontSize: 20,

                    fontWeight: FontWeight.w800,

                    letterSpacing: 1.3,
                  ),
                ),

                SizedBox(
                  height: 3,
                ),

                Text(
                  'Receitas, streams e desempenho financeiro',

                  style: TextStyle(
                    color: Colors.white38,

                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // ======================================================
          // STATUS
          // ======================================================
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,

              vertical: 7,
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
                  alpha: 0.18,
                ),
              ),
            ),

            child: Row(
              mainAxisSize: MainAxisSize.min,

              children: [
                Container(
                  width: 7,

                  height: 7,

                  decoration: BoxDecoration(
                    color: controller.accentNeon,

                    shape: BoxShape.circle,

                    boxShadow: [
                      BoxShadow(
                        color: controller.accentNeon.withValues(
                          alpha: 0.45,
                        ),

                        blurRadius: 7,
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  width: 7,
                ),

                Text(
                  'Atualizado',

                  style: TextStyle(
                    color: controller.accentNeon,

                    fontSize: 10,

                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOTÃO DO HEADER
  // ============================================================

  Widget _buildHeaderButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,

      child: Material(
        color: Colors.transparent,

        child: InkWell(
          onTap: onTap,

          borderRadius: BorderRadius.circular(
            12,
          ),

          child: Container(
            width: 42,

            height: 42,

            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.05,
              ),

              borderRadius: BorderRadius.circular(
                12,
              ),

              border: Border.all(
                color: Colors.white.withValues(
                  alpha: 0.08,
                ),
              ),
            ),

            child: Icon(
              icon,

              color: Colors.white70,

              size: 21,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoading(
    RoyaltiesController controller,
  ) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,

        children: [
          CircularProgressIndicator(
            color: controller.accentNeon,

            strokeWidth: 2,
          ),

          const SizedBox(
            height: 14,
          ),

          const Text(
            'Carregando royalties...',

            style: TextStyle(
              color: Colors.white38,

              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CONTEÚDO
  // ============================================================

  Widget _buildContent(
    BuildContext context,
    RoyaltiesController controller,
  ) {
    return LayoutBuilder(
      builder:
          (
            context,
            constraints,
          ) {
            final width = constraints.maxWidth;

            final horizontalPadding =
                width <
                    700
                ? 16.0
                : 24.0;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),

              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                14,
                horizontalPadding,
                28,
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  // ==================================================
                  // DESTAQUE PRINCIPAL
                  // ==================================================
                  _buildMainRevenueCard(
                    controller,
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  // ==================================================
                  // MÉTRICAS
                  // ==================================================
                  _buildMetricsGrid(
                    constraints: constraints,

                    controller: controller,
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  // ==================================================
                  // REVENUE
                  // ==================================================
                  _buildSectionHeader(
                    title: 'DESEMPENHO',

                    subtitle: 'Visão detalhada das suas receitas',
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  Container(
                    width: double.infinity,

                    decoration: BoxDecoration(
                      color: controller.cardBg.withValues(
                        alpha: 0.70,
                      ),

                      borderRadius: BorderRadius.circular(
                        20,
                      ),

                      border: Border.all(
                        color: Colors.white.withValues(
                          alpha: 0.06,
                        ),
                      ),

                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: 0.18,
                          ),

                          blurRadius: 20,

                          offset: const Offset(
                            0,
                            8,
                          ),
                        ),
                      ],
                    ),

                    child: const Padding(
                      padding: EdgeInsets.all(
                        4,
                      ),

                      child: RevenueCard(),
                    ),
                  ),
                ],
              ),
            );
          },
    );
  }

  // ============================================================
  // RECEITA PRINCIPAL
  // ============================================================

  Widget _buildMainRevenueCard(
    RoyaltiesController controller,
  ) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(
        24,
      ),

      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,

          end: Alignment.bottomRight,

          colors: [
            controller.accentNeon.withValues(
              alpha: 0.15,
            ),

            const Color(
              0xFF17132D,
            ),

            const Color(
              0xFF121020,
            ),
          ],
        ),

        borderRadius: BorderRadius.circular(
          22,
        ),

        border: Border.all(
          color: controller.accentNeon.withValues(
            alpha: 0.17,
          ),
        ),

        boxShadow: [
          BoxShadow(
            color: controller.accentNeon.withValues(
              alpha: 0.06,
            ),

            blurRadius: 28,

            offset: const Offset(
              0,
              10,
            ),
          ),
        ],
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,

        children: [
          // ======================================================
          // ÍCONE
          // ======================================================
          Container(
            width: 52,

            height: 52,

            decoration: BoxDecoration(
              color: controller.accentNeon.withValues(
                alpha: 0.10,
              ),

              borderRadius: BorderRadius.circular(
                15,
              ),

              border: Border.all(
                color: controller.accentNeon.withValues(
                  alpha: 0.18,
                ),
              ),
            ),

            child: Icon(
              Icons.account_balance_wallet_outlined,

              color: controller.accentNeon,

              size: 25,
            ),
          ),

          const SizedBox(
            width: 18,
          ),

          // ======================================================
          // VALOR
          // ======================================================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                const Text(
                  'RECEITA TOTAL',

                  style: TextStyle(
                    color: Colors.white38,

                    fontSize: 10,

                    fontWeight: FontWeight.w700,

                    letterSpacing: 1.2,
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),

                Text(
                  'R\$ ${controller.totalRevenue.toStringAsFixed(2)}',

                  style: const TextStyle(
                    color: Colors.white,

                    fontSize: 32,

                    fontWeight: FontWeight.w800,

                    letterSpacing: -0.7,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                const Text(
                  'Receita acumulada de royalties',

                  style: TextStyle(
                    color: Colors.white30,

                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // GRID DE MÉTRICAS
  // ============================================================

  Widget _buildMetricsGrid({
    required BoxConstraints constraints,
    required RoyaltiesController controller,
  }) {
    final width = constraints.maxWidth;

    if (width <
        650) {
      return Column(
        children: [
          _buildMetricCard(
            title: 'RECEITA MENSAL',

            value: 'R\$ ${controller.monthlyRevenue.toStringAsFixed(2)}',

            icon: Icons.calendar_month_outlined,

            controller: controller,
          ),

          const SizedBox(
            height: 12,
          ),

          _buildMetricCard(
            title: 'TOTAL DE STREAMS',

            value: '${controller.totalStreams}',

            icon: Icons.graphic_eq_rounded,

            controller: controller,
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            title: 'RECEITA MENSAL',

            value: 'R\$ ${controller.monthlyRevenue.toStringAsFixed(2)}',

            icon: Icons.calendar_month_outlined,

            controller: controller,
          ),
        ),

        const SizedBox(
          width: 14,
        ),

        Expanded(
          child: _buildMetricCard(
            title: 'TOTAL DE STREAMS',

            value: '${controller.totalStreams}',

            icon: Icons.graphic_eq_rounded,

            controller: controller,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CARD DE MÉTRICA
  // ============================================================

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required RoyaltiesController controller,
  }) {
    return Container(
      padding: const EdgeInsets.all(
        18,
      ),

      decoration: BoxDecoration(
        color: controller.cardBg.withValues(
          alpha: 0.70,
        ),

        borderRadius: BorderRadius.circular(
          18,
        ),

        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.06,
          ),
        ),
      ),

      child: Row(
        children: [
          Container(
            width: 42,

            height: 42,

            decoration: BoxDecoration(
              color: controller.accentNeon.withValues(
                alpha: 0.08,
              ),

              borderRadius: BorderRadius.circular(
                12,
              ),
            ),

            child: Icon(
              icon,

              color: controller.accentNeon.withValues(
                alpha: 0.85,
              ),

              size: 20,
            ),
          ),

          const SizedBox(
            width: 14,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  title,

                  style: const TextStyle(
                    color: Colors.white38,

                    fontSize: 9,

                    fontWeight: FontWeight.w700,

                    letterSpacing: 0.8,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  value,

                  maxLines: 1,

                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    color: Colors.white,

                    fontSize: 21,

                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER DA SEÇÃO
  // ============================================================

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,

      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                title,

                style: const TextStyle(
                  color: Colors.white,

                  fontSize: 12,

                  fontWeight: FontWeight.w700,

                  letterSpacing: 1.1,
                ),
              ),

              const SizedBox(
                height: 3,
              ),

              Text(
                subtitle,

                style: const TextStyle(
                  color: Colors.white30,

                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
