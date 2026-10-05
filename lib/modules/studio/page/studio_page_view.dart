import 'dart:async';

import 'package:flutter/material.dart';

import 'package:versin/modules/studio/page/studio_page_coordinator.dart';
import 'package:versin/modules/studio/page/widgets/studio_header.dart';
import 'package:versin/modules/studio/page/widgets/studio_workspace.dart';
import 'package:versin/modules/studio/widgets/song_word_timeline.dart';

// ============================================================
// STUDIO PAGE VIEW
// ============================================================
//
// Somente composição visual.
//
// Não:
//
// - acessa GetIt;
// - cria services;
// - registra analytics;
// - abre janelas diretamente;
// - contém dialogs.
//
// ============================================================

class StudioPageView extends StatelessWidget {
  final StudioPageCoordinator coordinator;

  const StudioPageView({super.key, required this.coordinator});

  @override
  Widget build(BuildContext context) {
    final controller = coordinator.controller;

    const activeColor = StudioPageCoordinator.activeColor;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              StudioHeader(
                controller: controller,
                activeColor: activeColor,
                onEditTitle: () {
                  unawaited(coordinator.editTitle(context));
                },
                onEditBpm: () {
                  unawaited(coordinator.editBpm(context));
                },
                onSave: () {
                  coordinator.saveProject(context);
                },
              ),
              const SizedBox(height: 12),
              Expanded(
                child: StudioWorkspace(
                  controller: controller,
                  brainController: coordinator.brainController,
                  activeColor: activeColor,
                  onDetachLyrics: () {
                    unawaited(coordinator.detachLyrics(context));
                  },
                  onDetachMindMap: () {
                    unawaited(coordinator.detachMindMap(context));
                  },
                  onDockAll: () {
                    unawaited(coordinator.dockAllPanels());
                  },
                  onAddMindMapNode: () {
                    unawaited(coordinator.addMindMapNode(context));
                  },
                  onAskChat: (text) {
                    coordinator.askChat(context, text);
                  },
                ),
              ),
              const SizedBox(height: 12),
              SongWordTimeline(
                words: controller.timelineWords,
                activeColor: activeColor,
                isWordUsed: controller.isTimelineWordUsed,
                onRemoveWord: controller.removeTimelineWord,
                onAddWord: () {
                  unawaited(coordinator.addTimelineWord(context));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
