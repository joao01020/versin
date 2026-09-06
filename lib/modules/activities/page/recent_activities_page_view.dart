import 'dart:async';

import 'package:flutter/material.dart';

import 'package:versin/modules/activities/page/dialogs/recent_activity_delete_dialog.dart';
import 'package:versin/modules/activities/page/recent_activities_page_coordinator.dart';
import 'package:versin/modules/activities/page/widgets/recent_activity_card.dart';

class RecentActivitiesPageView extends StatelessWidget {
  static const Color _backgroundColor = Color(0xFF0D0B1F);

  static const Color _cardColor = Color(0xFF17132D);

  static const Color _accentColor = Color(0xFFE100FF);

  final RecentActivitiesPageCoordinator coordinator;

  const RecentActivitiesPageView({super.key, required this.coordinator});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Atividades',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              coordinator.currentMonthLabel,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: coordinator.isLoading
                ? null
                : () {
                    unawaited(coordinator.loadMonthlyActivities());
                  },
            icon: Icon(
              Icons.refresh_rounded,
              color: coordinator.isLoading ? Colors.white12 : Colors.white54,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (coordinator.isLoading && coordinator.monthlyActivities.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: _accentColor),
      );
    }

    if (coordinator.errorMessage != null &&
        coordinator.monthlyActivities.isEmpty) {
      return _ErrorState(
        message: coordinator.errorMessage!,
        onRetry: () {
          unawaited(coordinator.loadMonthlyActivities());
        },
      );
    }

    if (coordinator.monthlyActivities.isEmpty) {
      return const _EmptyState();
    }

    return RefreshIndicator(
      color: _accentColor,
      backgroundColor: _cardColor,
      onRefresh: coordinator.loadMonthlyActivities,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
        itemCount: coordinator.monthlyActivities.length,
        itemBuilder: (context, index) {
          final activity = coordinator.monthlyActivities[index];

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: RecentActivityCard(
              activity: activity,
              onDelete: () async {
                final confirmed = await RecentActivityDeleteDialog.show(
                  context: context,
                  activity: activity,
                );

                if (!confirmed || !context.mounted) {
                  return;
                }

                final success = await coordinator.deleteActivity(activity.id);

                if (!context.mounted) {
                  return;
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Atividade excluída.'
                          : 'Não foi possível excluir a atividade.',
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
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.035),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history_toggle_off_rounded,
                color: Colors.white24,
                size: 27,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Nenhuma atividade neste mês',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Suas principais ações aparecerão aqui conforme você utilizar o Versin.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white24,
                fontSize: 10,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent,
              size: 28,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white38, fontSize: 10),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 15),
              label: const Text(
                'TENTAR NOVAMENTE',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
