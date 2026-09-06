import 'dart:async';

import 'package:flutter/material.dart';

import 'package:versin/modules/storage/data/models/stored_work_model.dart';
import 'package:versin/modules/storage/page/storage_page_coordinator.dart';
import 'package:versin/modules/storage/page/widgets/storage_header.dart';
import 'package:versin/modules/storage/widgets/storage_empty_state.dart';
import 'package:versin/modules/storage/widgets/storage_item_card.dart';
import 'package:versin/modules/storage/widgets/storage_summary_card.dart';

class StoragePageView extends StatelessWidget {
  final StoragePageCoordinator coordinator;

  const StoragePageView({super.key, required this.coordinator});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StoragePageCoordinator.backgroundColor,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              StoragePageCoordinator.surfaceColor,
              StoragePageCoordinator.backgroundColor,
              Colors.black,
            ],
          ),
        ),
        child: coordinator.isInitializingStorage
            ? const Center(
                child: CircularProgressIndicator(
                  color: StoragePageCoordinator.accentColor,
                ),
              )
            : coordinator.initializationError != null
            ? _InitializationError(coordinator: coordinator)
            : _StorageContent(coordinator: coordinator),
      ),
    );
  }
}

class _InitializationError extends StatelessWidget {
  final StoragePageCoordinator coordinator;

  const _InitializationError({required this.coordinator});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: StoragePageCoordinator.surfaceColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.redAccent.withValues(alpha: 0.22),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  color: Colors.redAccent,
                  size: 34,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Não foi possível carregar o armazenamento',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  coordinator.initializationError ?? 'Tente novamente.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {
                    unawaited(coordinator.initialize());
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: StoragePageCoordinator.accentColor,
                    foregroundColor: Colors.black,
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 17),
                  label: const Text(
                    'TENTAR NOVAMENTE',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StorageContent extends StatelessWidget {
  final StoragePageCoordinator coordinator;

  const _StorageContent({required this.coordinator});

  @override
  Widget build(BuildContext context) {
    final controller = coordinator.controller;

    if (controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: StoragePageCoordinator.accentColor,
        ),
      );
    }

    return Column(
      children: [
        StorageHeader(
          accentColor: StoragePageCoordinator.accentColor,
          onRegister: () {
            unawaited(coordinator.showRegisterWorkOptions(context));
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              _SummaryCard(
                title: 'Letras',
                value: controller.lyricsCount,
                icon: Icons.description_outlined,
              ),
              const SizedBox(width: 10),
              _SummaryCard(
                title: 'Beats',
                value: controller.beatsCount,
                icon: Icons.graphic_eq_rounded,
              ),
              const SizedBox(width: 10),
              _SummaryCard(
                title: 'Íntegras',
                value: controller.verifiedCount,
                icon: Icons.verified_outlined,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            height: 44,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.035),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: TabBar(
              controller: coordinator.tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: StoragePageCoordinator.accentColor,
              unselectedLabelColor: Colors.white38,
              indicator: BoxDecoration(
                color: StoragePageCoordinator.accentColor.withValues(
                  alpha: 0.12,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              tabs: const [
                Tab(text: 'BEATS'),
                Tab(text: 'LETRAS'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: TabBarView(
            controller: coordinator.tabController,
            children: [
              _WorksList(coordinator: coordinator, type: StoredWorkType.beat),
              _WorksList(coordinator: coordinator, type: StoredWorkType.lyrics),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final int value;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: StorageSummaryCard(
        title: title,
        value: value.toString(),
        icon: icon,
        accentColor: StoragePageCoordinator.accentColor,
      ),
    );
  }
}

class _WorksList extends StatelessWidget {
  final StoragePageCoordinator coordinator;
  final StoredWorkType type;

  const _WorksList({required this.coordinator, required this.type});

  @override
  Widget build(BuildContext context) {
    final works = coordinator.worksFor(type);

    if (works.isEmpty) {
      final isBeat = type == StoredWorkType.beat;

      return StorageEmptyState(
        title: isBeat ? 'Nenhum beat registrado' : 'Nenhuma letra registrada',
        message: isBeat
            ? 'Adicione um arquivo de áudio para gerar seu hash de integridade.'
            : 'Cole ou escreva uma letra para criar seu registro de integridade.',
        icon: isBeat ? Icons.graphic_eq_rounded : Icons.description_outlined,
        buttonLabel: isBeat ? 'REGISTRAR BEAT' : 'REGISTRAR LETRA',
        accentColor: StoragePageCoordinator.accentColor,
        onPressed: isBeat
            ? () {
                unawaited(coordinator.openRegisterBeat(context));
              }
            : () {
                unawaited(coordinator.openRegisterLyrics(context));
              },
      );
    }

    return RefreshIndicator(
      color: StoragePageCoordinator.accentColor,
      onRefresh: coordinator.refresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        itemCount: works.length,
        separatorBuilder: (_, __) {
          return const SizedBox(height: 12);
        },
        itemBuilder: (_, index) {
          final work = works[index];

          return StorageItemCard(
            work: work,
            accentColor: StoragePageCoordinator.accentColor,
            onTap: () {
              unawaited(coordinator.openDetails(context, work));
            },
            onMorePressed: () {
              unawaited(coordinator.showWorkActions(context, work));
            },
          );
        },
      ),
    );
  }
}
