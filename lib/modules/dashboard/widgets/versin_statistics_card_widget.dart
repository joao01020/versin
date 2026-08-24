import 'package:flutter/material.dart';

import '../controllers/dashboard_controller.dart';
import '../production/controllers/creative_production_controller.dart';
import '../production/models/creative_production_month.dart';
import '../services/dashboard_ui_preferences_service.dart';

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

  // ============================================================
  // EXPANSION STATE
  // ============================================================
  //
  // Começamos recolhido enquanto a preferência ainda está sendo
  // carregada. Isso evita o efeito:
  //
  // aberto
  //   ↓
  // fecha sozinho
  //
  // Quando a preferência chega, aplicamos o estado salvo sem
  // animação. As animações só são habilitadas depois disso.
  //
  // ============================================================

  bool _isExpanded = false;

  bool _hasLoadedExpansionPreference = false;

  bool _animateExpansion = false;

  // ============================================================
  // UI PREFERENCES
  // ============================================================

  late final DashboardUiPreferencesService _uiPreferencesService;

  // ============================================================
  // PRODUÇÃO CRIATIVA
  // ============================================================

  late final CreativeProductionController _productionController;

  int? _selectedMonthIndex;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _uiPreferencesService = DashboardUiPreferencesService();

    _productionController = CreativeProductionController();

    _productionController.addListener(
      _onProductionChanged,
    );

    _loadExpansionPreference();

    WidgetsBinding.instance.addPostFrameCallback(
      (
        _,
      ) {
        if (!mounted) {
          return;
        }

        _productionController.load(
          months: 12,
        );
      },
    );
  }

  // ============================================================
  // PRODUÇÃO ALTERADA
  // ============================================================

  void _onProductionChanged() {
    if (!mounted) {
      return;
    }

    setState(
      () {
        _selectedMonthIndex = _resolveSelectedMonthIndex();
      },
    );
  }

  // ============================================================
  // LOAD EXPANSION PREFERENCE
  // ============================================================

  Future<
    void
  >
  _loadExpansionPreference() async {
    final isExpanded = await _uiPreferencesService.loadStatisticsCardExpanded();

    if (!mounted) {
      return;
    }

    setState(
      () {
        _isExpanded = isExpanded;

        _hasLoadedExpansionPreference = true;

        // A restauração inicial nunca deve parecer uma ação
        // executada pelo usuário.
        _animateExpansion = false;
      },
    );

    // ==========================================================
    // ENABLE USER ANIMATIONS
    // ==========================================================
    //
    // Habilitamos as animações somente depois que o primeiro
    // frame com a preferência restaurada já foi desenhado.
    //
    // ==========================================================

    WidgetsBinding.instance.addPostFrameCallback(
      (
        _,
      ) {
        if (!mounted) {
          return;
        }

        _animateExpansion = true;
      },
    );
  }

  // ============================================================
  // CONTROLLER VISUAL
  // ============================================================

  DashboardController get controller => widget.controller;

  // ============================================================
  // DADOS DE PRODUÇÃO
  // ============================================================

  List<
    CreativeProductionMonth
  >
  get _months {
    return _productionController.months;
  }

  int get _currentMonthIndex {
    final now = DateTime.now();

    for (
      var index = 0;
      index <
          _months.length;
      index++
    ) {
      final month = _months[index];

      if (month.month.year ==
              now.year &&
          month.month.month ==
              now.month) {
        return index;
      }
    }

    return _months.isEmpty
        ? -1
        : _months.length -
              1;
  }

  int _resolveSelectedMonthIndex() {
    if (_months.isEmpty) {
      return -1;
    }

    final selected = _selectedMonthIndex;

    if (selected !=
            null &&
        selected >=
            0 &&
        selected <
            _months.length) {
      return selected;
    }

    final currentIndex = _currentMonthIndex;

    if (currentIndex >=
        0) {
      return currentIndex;
    }

    return _months.length -
        1;
  }

  CreativeProductionMonth? get _selectedMonth {
    final index = _resolveSelectedMonthIndex();

    if (index <
            0 ||
        index >=
            _months.length) {
      return null;
    }

    return _months[index];
  }

  CreativeProductionMonth? get _selectedPreviousMonth {
    final index = _resolveSelectedMonthIndex();

    if (index <=
            0 ||
        index >=
            _months.length) {
      return null;
    }

    return _months[index -
        1];
  }

  // ============================================================
  // EXPANDIR / RECOLHER
  // ============================================================

  Future<
    void
  >
  _toggleExpanded() async {
    if (!_hasLoadedExpansionPreference) {
      return;
    }

    final nextIsExpanded = !_isExpanded;

    setState(
      () {
        _animateExpansion = true;

        _isExpanded = nextIsExpanded;
      },
    );

    final saved = await _uiPreferencesService.saveStatisticsCardExpanded(
      nextIsExpanded,
    );

    if (!saved) {
      debugPrint(
        '[DASHBOARD UI] '
        'Não foi possível salvar o estado do card de estatísticas.',
      );
    }
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
            duration: _animateExpansion
                ? const Duration(
                    milliseconds: 320,
                  )
                : Duration.zero,

            curve: Curves.easeOutCubic,

            alignment: Alignment.topCenter,

            child:
                _hasLoadedExpansionPreference &&
                    _isExpanded
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
        // CRESCIMENTO REAL
        // ======================================================
        _buildGrowthBadge(),

        const SizedBox(
          width: 8,
        ),

        // ======================================================
        // EXPANDIR / RECOLHER
        // ======================================================
        Tooltip(
          message: !_hasLoadedExpansionPreference
              ? 'Carregando preferência'
              : _isExpanded
              ? 'Recolher gráfico'
              : 'Expandir gráfico',

          child: Material(
            color: Colors.transparent,

            child: InkWell(
              onTap: _hasLoadedExpansionPreference
                  ? _toggleExpanded
                  : null,

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

                  duration: _animateExpansion
                      ? const Duration(
                          milliseconds: 250,
                        )
                      : Duration.zero,

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
  // BADGE DE CRESCIMENTO
  // ============================================================

  Widget _buildGrowthBadge() {
    if (_productionController.isLoading &&
        !_productionController.hasData) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: controller.accentNeon.withValues(
            alpha: 0.05,
          ),
          borderRadius: BorderRadius.circular(
            999,
          ),
          border: Border.all(
            color: controller.accentNeon.withValues(
              alpha: 0.10,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: controller.primaryPurple.withValues(
                alpha: 0.10,
              ),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 11,
              height: 11,
              child: CircularProgressIndicator(
                strokeWidth: 1.4,
                valueColor:
                    AlwaysStoppedAnimation<
                      Color
                    >(
                      controller.accentNeon,
                    ),
              ),
            ),
            const SizedBox(
              width: 6,
            ),
            Text(
              'SYNC',
              style: TextStyle(
                color: controller.accentNeon.withValues(
                  alpha: 0.78,
                ),
                fontSize: 8,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      );
    }

    final month = _productionController.currentMonth;

    if (month ==
        null) {
      return const SizedBox.shrink();
    }

    final change = month.changeFromPreviousMonth;

    final isPositive =
        change >
        0;

    final isNegative =
        change <
        0;

    final badgeColor = isNegative
        ? const Color(
            0xFFFF5C7A,
          )
        : isPositive
        ? controller.accentNeon
        : Colors.white54;

    final icon = isNegative
        ? Icons.trending_down_rounded
        : isPositive
        ? Icons.trending_up_rounded
        : Icons.trending_flat_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withValues(
          alpha: 0.08,
        ),
        borderRadius: BorderRadius.circular(
          999,
        ),
        border: Border.all(
          color: badgeColor.withValues(
            alpha: 0.15,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: badgeColor,
            size: 13,
          ),
          const SizedBox(
            width: 4,
          ),
          Text(
            _formatChange(
              change,
            ),
            style: TextStyle(
              color: badgeColor,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CONTEÚDO EXPANDIDO
  // ============================================================

  Widget _buildExpandedContent() {
    if (_productionController.isLoading &&
        !_productionController.hasData) {
      return _buildLoadingState();
    }

    if (_productionController.hasError &&
        !_productionController.hasData) {
      return _buildErrorState();
    }

    if (!_productionController.hasData) {
      return _buildEmptyState();
    }

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
              Expanded(
                child: Stack(
                  children: [
                    _buildBackgroundLines(),
                    _buildBars(),
                  ],
                ),
              ),

              const SizedBox(
                height: 12,
              ),

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

              _buildMonthLabels(),
            ],
          ),
        ),

        const SizedBox(
          height: 20,
        ),

        _buildSelectedMonthSummary(),
      ],
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoadingState() {
    const ghostHeights =
        <
          double
        >[
          18,
          28,
          22,
          40,
          32,
          54,
          37,
          47,
          25,
          43,
          31,
          51,
        ];

    return Padding(
      padding: const EdgeInsets.only(
        top: 26,
        bottom: 18,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(
          18,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              controller.primaryPurple.withValues(
                alpha: 0.11,
              ),
              Colors.white.withValues(
                alpha: 0.025,
              ),
              controller.accentNeon.withValues(
                alpha: 0.035,
              ),
            ],
          ),
          borderRadius: BorderRadius.circular(
            18,
          ),
          border: Border.all(
            color: controller.accentNeon.withValues(
              alpha: 0.10,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: controller.primaryPurple.withValues(
                alpha: 0.10,
              ),
              blurRadius: 20,
              offset: const Offset(
                0,
                8,
              ),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================================================
            // HEADER
            // ==================================================
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        controller.primaryPurple.withValues(
                          alpha: 0.24,
                        ),
                        controller.accentNeon.withValues(
                          alpha: 0.10,
                        ),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(
                      11,
                    ),
                    border: Border.all(
                      color: controller.accentNeon.withValues(
                        alpha: 0.14,
                      ),
                    ),
                  ),
                  child: Icon(
                    Icons.auto_graph_rounded,
                    color: controller.accentNeon,
                    size: 19,
                  ),
                ),

                const SizedBox(
                  width: 11,
                ),

                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Analisando sua produção',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(
                        height: 3,
                      ),
                      Text(
                        'Sincronizando atividade criativa...',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),

                TweenAnimationBuilder<
                  double
                >(
                  tween:
                      Tween<
                        double
                      >(
                        begin: 0.30,
                        end: 1.0,
                      ),
                  duration: const Duration(
                    milliseconds: 850,
                  ),
                  curve: Curves.easeInOut,
                  builder:
                      (
                        context,
                        value,
                        child,
                      ) {
                        return Opacity(
                          opacity: value,
                          child: child,
                        );
                      },
                  child: Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: controller.accentNeon.withValues(
                        alpha: 0.07,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: controller.accentNeon.withValues(
                          alpha: 0.12,
                        ),
                      ),
                    ),
                    child: SizedBox(
                      width: 13,
                      height: 13,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.6,
                        valueColor:
                            AlwaysStoppedAnimation<
                              Color
                            >(
                              controller.accentNeon,
                            ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 24,
            ),

            // ==================================================
            // GRÁFICO FANTASMA
            // ==================================================
            SizedBox(
              height: 82,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(
                        3,
                        (
                          index,
                        ) {
                          return Container(
                            width: double.infinity,
                            height: 1,
                            color: Colors.white.withValues(
                              alpha: 0.025,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(
                        ghostHeights.length,
                        (
                          index,
                        ) {
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 3,
                              ),
                              child:
                                  TweenAnimationBuilder<
                                    double
                                  >(
                                    tween:
                                        Tween<
                                          double
                                        >(
                                          begin: 3,
                                          end: ghostHeights[index],
                                        ),
                                    duration: Duration(
                                      milliseconds:
                                          420 +
                                          (index *
                                              55),
                                    ),
                                    curve: Curves.easeOutCubic,
                                    builder:
                                        (
                                          context,
                                          height,
                                          _,
                                        ) {
                                          final isLast =
                                              index ==
                                              ghostHeights.length -
                                                  1;

                                          return Align(
                                            alignment: Alignment.bottomCenter,
                                            child: Container(
                                              height: height,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [
                                                    isLast
                                                        ? controller.accentNeon.withValues(
                                                            alpha: 0.52,
                                                          )
                                                        : controller.primaryPurple.withValues(
                                                            alpha: 0.36,
                                                          ),
                                                    controller.primaryPurple.withValues(
                                                      alpha: 0.10,
                                                    ),
                                                  ],
                                                ),
                                                borderRadius: BorderRadius.circular(
                                                  6,
                                                ),
                                                border: Border.all(
                                                  color: isLast
                                                      ? controller.accentNeon.withValues(
                                                          alpha: 0.13,
                                                        )
                                                      : Colors.white.withValues(
                                                          alpha: 0.025,
                                                        ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                  ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 14,
            ),

            // ==================================================
            // LINHA NEON
            // ==================================================
            TweenAnimationBuilder<
              double
            >(
              tween:
                  Tween<
                    double
                  >(
                    begin: 0.10,
                    end: 1.0,
                  ),
              duration: const Duration(
                milliseconds: 900,
              ),
              curve: Curves.easeOutCubic,
              builder:
                  (
                    context,
                    value,
                    _,
                  ) {
                    return FractionallySizedBox(
                      widthFactor: value,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            999,
                          ),
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              controller.primaryPurple.withValues(
                                alpha: 0.45,
                              ),
                              controller.accentNeon.withValues(
                                alpha: 0.90,
                              ),
                              controller.primaryPurple.withValues(
                                alpha: 0.40,
                              ),
                              Colors.transparent,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: controller.accentNeon.withValues(
                                alpha: 0.20,
                              ),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
            ),

            const SizedBox(
              height: 13,
            ),

            // ==================================================
            // FOOTER
            // ==================================================
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
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
                  'VERSIN • CREATIVE ENGINE',
                  style: TextStyle(
                    color: controller.accentNeon.withValues(
                      alpha: 0.64,
                    ),
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),

                const Spacer(),

                const Text(
                  '12 meses',
                  style: TextStyle(
                    color: Colors.white24,
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
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
    return Padding(
      padding: const EdgeInsets.only(
        top: 24,
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: Colors.white38,
            size: 24,
          ),
          const SizedBox(
            height: 10,
          ),
          Text(
            _productionController.errorMessage ??
                'Não foi possível carregar a produção.',
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
            onPressed: () {
              _productionController.reload(
                months: 12,
              );
            },
            icon: const Icon(
              Icons.refresh_rounded,
              size: 16,
            ),
            label: const Text(
              'Tentar novamente',
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SEM DADOS
  // ============================================================

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(
        vertical: 34,
      ),
      child: Column(
        children: [
          Icon(
            Icons.insights_rounded,
            color: Colors.white30,
            size: 28,
          ),
          SizedBox(
            height: 10,
          ),
          Text(
            'Sua produção começará a aparecer aqui.',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 11,
            ),
          ),
        ],
      ),
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
  // BARRAS REAIS
  // ============================================================

  Widget _buildBars() {
    return Positioned.fill(
      child: LayoutBuilder(
        builder:
            (
              context,
              constraints,
            ) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(
                  _months.length,
                  (
                    index,
                  ) {
                    final month = _months[index];

                    final score = month.score.clamp(
                      0.0,
                      100.0,
                    );

                    final maxHeight = constraints.maxHeight;

                    final barHeight =
                        score <=
                            0
                        ? 4.0
                        : (maxHeight *
                                  (score /
                                      100))
                              .clamp(
                                6.0,
                                maxHeight,
                              );

                    final isCurrentMonth =
                        index ==
                        _currentMonthIndex;

                    final isSelected =
                        index ==
                        _resolveSelectedMonthIndex();

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                        ),
                        child: _buildModernBarTooltip(
                          month: month,
                          index: index,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(
                                7,
                              ),
                              onTap: () {
                                setState(
                                  () {
                                    _selectedMonthIndex = index;
                                  },
                                );
                              },
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
                                                alpha: isSelected
                                                    ? 0.90
                                                    : 0.72,
                                              ),
                                              controller.primaryPurple.withValues(
                                                alpha: isSelected
                                                    ? 0.32
                                                    : 0.20,
                                              ),
                                            ],
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      7,
                                    ),
                                    border: Border.all(
                                      color:
                                          isCurrentMonth ||
                                              isSelected
                                          ? controller.accentNeon.withValues(
                                              alpha: isCurrentMonth
                                                  ? 0.28
                                                  : 0.16,
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
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
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
          final month = _months[index];

          final isCurrentMonth =
              index ==
              _currentMonthIndex;

          final isSelected =
              index ==
              _resolveSelectedMonthIndex();

          return Expanded(
            child: InkWell(
              onTap: () {
                setState(
                  () {
                    _selectedMonthIndex = index;
                  },
                );
              },
              borderRadius: BorderRadius.circular(
                6,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 3,
                ),
                child: Text(
                  month.shortMonthLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isCurrentMonth
                        ? controller.accentNeon
                        : isSelected
                        ? Colors.white70
                        : Colors.white30,
                    fontSize: 9,
                    fontWeight:
                        isCurrentMonth ||
                            isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // RESUMO DO MÊS SELECIONADO
  // ============================================================

  Widget _buildSelectedMonthSummary() {
    final month = _selectedMonth;

    if (month ==
        null) {
      return const SizedBox.shrink();
    }

    final selectedIndex = _resolveSelectedMonthIndex();

    final previous = _selectedPreviousMonth;

    final change = month.changeFromPreviousMonth;

    final changeColor =
        change <
            0
        ? const Color(
            0xFFFF5C7A,
          )
        : change >
              0
        ? controller.accentNeon
        : Colors.white54;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        16,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.025,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  month.fullMonthLabel.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              Text(
                '${month.score.round()} pts',
                style: TextStyle(
                  color: controller.accentNeon,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 14,
          ),

          _buildMetricRow(
            icon: Icons.library_music_rounded,
            label: '${month.projectsCreated} projetos criados',
          ),

          _buildMetricRow(
            icon: Icons.edit_note_rounded,
            label: '${month.compositionSessions} sessões de composição',
          ),

          _buildMetricRow(
            icon: Icons.task_alt_rounded,
            label: '${month.tasksCompleted} tarefas concluídas',
          ),

          _buildMetricRow(
            icon: Icons.handshake_rounded,
            label: '${month.collaborationsStarted} colaborações',
          ),

          _buildMetricRow(
            icon: Icons.folder_copy_rounded,
            label: '${month.filesAdded} arquivos adicionados',
            showBottomSpacing: false,
          ),

          const SizedBox(
            height: 14,
          ),

          Divider(
            height: 1,
            color: Colors.white.withValues(
              alpha: 0.06,
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          Text(
            'Produção: ${month.score.round()} pontos',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 5,
          ),

          Text(
            selectedIndex <=
                        0 ||
                    previous ==
                        null
                ? 'Primeiro mês do período'
                : '${_changeArrow(change)} '
                      '${_formatChange(change)} '
                      'comparado a '
                      '${previous.fullMonthLabel.toLowerCase()}',
            style: TextStyle(
              color:
                  selectedIndex <=
                      0
                  ? Colors.white38
                  : changeColor,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LINHA DE MÉTRICA
  // ============================================================

  Widget _buildMetricRow({
    required IconData icon,
    required String label,
    bool showBottomSpacing = true,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: showBottomSpacing
            ? 8
            : 0,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: controller.accentNeon,
            size: 15,
          ),
          const SizedBox(
            width: 9,
          ),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TOOLTIP MODERNO DO GRÁFICO
  // ============================================================
  //
  // Substitui o tooltip padrão claro do Flutter por uma versão
  // alinhada ao visual do Versin:
  //
  // - fundo escuro;
  // - borda neon;
  // - glow suave;
  // - título do mês;
  // - score;
  // - métricas organizadas;
  // - comparação com o mês anterior.
  //
  // ============================================================

  Widget _buildModernBarTooltip({
    required CreativeProductionMonth month,
    required int index,
    required Widget child,
  }) {
    final previous =
        index >
            0
        ? _months[index -
              1]
        : null;

    final change = month.changeFromPreviousMonth;

    final isPositive =
        change >
        0;

    final isNegative =
        change <
        0;

    final changeColor = isNegative
        ? const Color(
            0xFFFF5C7A,
          )
        : isPositive
        ? controller.accentNeon
        : Colors.white54;

    final comparisonText =
        previous ==
            null
        ? 'Primeiro mês do período'
        : '${_changeArrow(change)} '
              '${_formatChange(change)} '
              'vs ${previous.fullMonthLabel.toLowerCase()}';

    return Tooltip(
      preferBelow: false,
      verticalOffset: 18,
      waitDuration: const Duration(
        milliseconds: 180,
      ),
      showDuration: const Duration(
        seconds: 6,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      margin: const EdgeInsets.all(
        12,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(
              0xFF171222,
            ),
            const Color(
              0xFF0D0A14,
            ),
            controller.primaryPurple.withValues(
              alpha: 0.20,
            ),
          ],
        ),
        borderRadius: BorderRadius.circular(
          14,
        ),
        border: Border.all(
          color: controller.accentNeon.withValues(
            alpha: 0.28,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: controller.primaryPurple.withValues(
              alpha: 0.30,
            ),
            blurRadius: 24,
            spreadRadius: 1,
            offset: const Offset(
              0,
              8,
            ),
          ),
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.42,
            ),
            blurRadius: 16,
            offset: const Offset(
              0,
              4,
            ),
          ),
        ],
      ),
      richMessage: TextSpan(
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 11,
          height: 1.55,
        ),
        children: [
          TextSpan(
            text:
                '${month.fullMonthLabel.toUpperCase()} '
                '${month.month.year}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const TextSpan(
            text: '\n',
          ),
          TextSpan(
            text: '${month.score.round()} PONTOS DE PRODUÇÃO',
            style: TextStyle(
              color: controller.accentNeon,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const TextSpan(
            text: '\n\n',
          ),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Icon(
              Icons.library_music_rounded,
              size: 13,
              color: controller.accentNeon,
            ),
          ),
          TextSpan(
            text: '  ${month.projectsCreated}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const TextSpan(
            text: '  Projetos criados\n',
          ),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Icon(
              Icons.edit_note_rounded,
              size: 13,
              color: controller.accentNeon,
            ),
          ),
          TextSpan(
            text: '  ${month.compositionSessions}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const TextSpan(
            text: '  Sessões de composição\n',
          ),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Icon(
              Icons.task_alt_rounded,
              size: 13,
              color: controller.accentNeon,
            ),
          ),
          TextSpan(
            text: '  ${month.tasksCompleted}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const TextSpan(
            text: '  Tarefas concluídas\n',
          ),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Icon(
              Icons.handshake_rounded,
              size: 13,
              color: controller.accentNeon,
            ),
          ),
          TextSpan(
            text: '  ${month.collaborationsStarted}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const TextSpan(
            text: '  Colaborações\n',
          ),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Icon(
              Icons.folder_copy_rounded,
              size: 13,
              color: controller.accentNeon,
            ),
          ),
          TextSpan(
            text: '  ${month.filesAdded}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const TextSpan(
            text: '  Arquivos adicionados',
          ),
          const TextSpan(
            text: '\n\n',
          ),
          TextSpan(
            text: comparisonText,
            style: TextStyle(
              color:
                  previous ==
                      null
                  ? Colors.white38
                  : changeColor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      child: child,
    );
  }

  // ============================================================
  // FORMATAÇÃO
  // ============================================================

  String _formatChange(
    double value,
  ) {
    final normalized =
        value.abs() <
            0.05
        ? 0.0
        : value;

    final absolute = normalized
        .abs()
        .toStringAsFixed(
          1,
        )
        .replaceAll(
          '.',
          ',',
        );

    if (normalized >
        0) {
      return '+$absolute%';
    }

    if (normalized <
        0) {
      return '-$absolute%';
    }

    return '0,0%';
  }

  String _changeArrow(
    double value,
  ) {
    if (value >
        0) {
      return '↑';
    }

    if (value <
        0) {
      return '↓';
    }

    return '→';
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _productionController.removeListener(
      _onProductionChanged,
    );

    _productionController.dispose();

    super.dispose();
  }
}
