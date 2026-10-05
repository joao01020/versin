import 'package:flutter/material.dart';

import '../controllers/recent_activity_controller.dart';
import 'recent_activity_item_widget.dart';

// ============================================================
// RECENT ACTIVITIES CARD WIDGET
// ============================================================
//
// Card exibido no Dashboard.
//
// Mostra:
//
// - título;
// - quantidade de atividades;
// - loading;
// - erro;
// - estado vazio;
// - até 5 atividades recentes;
// - atualização via Realtime.
//
// ============================================================

class RecentActivitiesCardWidget
    extends
        StatefulWidget {
  final RecentActivityController controller;

  final Color accentColor;

  final VoidCallback? onViewAll;

  const RecentActivitiesCardWidget({
    super.key,
    required this.controller,
    this.accentColor = const Color(
      0xFFE100FF,
    ),
    this.onViewAll,
  });

  @override
  State<
    RecentActivitiesCardWidget
  >
  createState() => _RecentActivitiesCardWidgetState();
}

// ============================================================
// STATE
// ============================================================

class _RecentActivitiesCardWidgetState
    extends
        State<
          RecentActivitiesCardWidget
        > {
  // ============================================================
  // CONTROLLER
  // ============================================================

  RecentActivityController get controller => widget.controller;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    controller.addListener(
      _onControllerUpdate,
    );

    if (!controller.isInitialized) {
      WidgetsBinding.instance.addPostFrameCallback(
        (
          _,
        ) async {
          if (!mounted) {
            return;
          }

          await controller.init();
        },
      );
    }
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        18,
      ),
      decoration: BoxDecoration(
        color: const Color(
          0xFF151229,
        ),
        borderRadius: BorderRadius.circular(
          20,
        ),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.05,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==================================================
          // HEADER
          // ==================================================
          _buildHeader(),

          const SizedBox(
            height: 12,
          ),

          Divider(
            height: 1,
            color: Colors.white.withValues(
              alpha: 0.05,
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          // ==================================================
          // CONTEÚDO
          // ==================================================
          _buildContent(),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Row(
      children: [
        // ======================================================
        // ÍCONE
        // ======================================================
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: widget.accentColor.withValues(
              alpha: 0.10,
            ),
            borderRadius: BorderRadius.circular(
              11,
            ),
          ),
          child: Icon(
            Icons.history_rounded,
            color: widget.accentColor,
            size: 18,
          ),
        ),

        const SizedBox(
          width: 11,
        ),

        // ======================================================
        // TÍTULO
        // ======================================================
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Atividades recentes',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),

              SizedBox(
                height: 2,
              ),

              Text(
                'Últimas ações da sua conta',
                style: TextStyle(
                  color: Colors.white30,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),

        // ======================================================
        // VER TODAS
        // ======================================================
        if (widget.onViewAll !=
            null)
          TextButton(
            onPressed: widget.onViewAll,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 6,
              ),
              foregroundColor: widget.accentColor,
            ),
            child: const Text(
              'VER TODAS',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // CONTEÚDO
  // ============================================================

  Widget _buildContent() {
    // ==========================================================
    // LOADING
    // ==========================================================

    if (controller.isLoading &&
        !controller.hasActivities) {
      return const Padding(
        padding: EdgeInsets.symmetric(
          vertical: 30,
        ),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }

    // ==========================================================
    // ERRO
    // ==========================================================

    if (controller.hasError &&
        !controller.hasActivities) {
      return _buildErrorState();
    }

    // ==========================================================
    // VAZIO
    // ==========================================================

    if (!controller.hasActivities) {
      return _buildEmptyState();
    }

    // ==========================================================
    // LISTA
    // ==========================================================

    final activities = controller.activities;

    return Column(
      children: [
        for (
          var index = 0;
          index <
              activities.length;
          index++
        ) ...[
          RecentActivityItemWidget(
            activity: activities[index],
            accentColor: widget.accentColor,
          ),

          if (index <
              activities.length -
                  1)
            Divider(
              height: 1,
              indent: 50,
              color: Colors.white.withValues(
                alpha: 0.04,
              ),
            ),
        ],
      ],
    );
  }

  // ============================================================
  // VAZIO
  // ============================================================

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 26,
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(
                  alpha: 0.025,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history_toggle_off_rounded,
                color: Colors.white24,
                size: 22,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            const Text(
              'Nenhuma atividade ainda',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(
              height: 4,
            ),

            const Text(
              'Suas ações recentes aparecerão aqui.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white24,
                fontSize: 9,
              ),
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
      padding: const EdgeInsets.symmetric(
        vertical: 24,
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent,
              size: 23,
            ),

            const SizedBox(
              height: 9,
            ),

            Text(
              controller.errorMessage ??
                  'Não foi possível carregar as atividades.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 9,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            TextButton.icon(
              onPressed: controller.refresh,
              icon: const Icon(
                Icons.refresh_rounded,
                size: 14,
              ),
              label: const Text(
                'TENTAR NOVAMENTE',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
