import 'package:flutter/material.dart';

import 'package:versin/modules/brain/controller/brain_controller.dart';
import 'package:versin/modules/studio/controllers/studio_controller.dart';
import 'package:versin/modules/studio/page/widgets/studio_detached_workspace_placeholder.dart';
import 'package:versin/modules/studio/page/widgets/studio_dockable_panel.dart';
import 'package:versin/modules/studio/widgets/lyric_editor.dart';
import 'package:versin/modules/studio/widgets/mind_map.dart';

// ============================================================
// STUDIO WORKSPACE
// ============================================================
//
// Composição visual da área Letra + Mapa.
//
// Não controla janelas nem dialogs.
// Apenas encaminha as intenções recebidas.
//
// ============================================================

class StudioWorkspace extends StatelessWidget {
  final StudioController controller;
  final BrainController brainController;
  final Color activeColor;

  final VoidCallback onDetachLyrics;
  final VoidCallback onDetachMindMap;
  final VoidCallback onDockAll;
  final VoidCallback onAddMindMapNode;
  final ValueChanged<String> onAskChat;

  const StudioWorkspace({
    super.key,
    required this.controller,
    required this.brainController,
    required this.activeColor,
    required this.onDetachLyrics,
    required this.onDetachMindMap,
    required this.onDockAll,
    required this.onAddMindMapNode,
    required this.onAskChat,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 850;

        final lyricsDetached = controller.isLyricsDetached;

        final mapDetached = controller.isMindMapDetached;

        if (lyricsDetached && mapDetached) {
          return StudioDetachedWorkspacePlaceholder(
            activeColor: activeColor,
            onDockAll: onDockAll,
          );
        }

        if (!lyricsDetached && mapDetached) {
          return StudioDockablePanel(
            activeColor: activeColor,
            tooltip: 'Desencaixar Letra',
            onDetach: onDetachLyrics,
            child: _buildLyricsEditor(),
          );
        }

        if (lyricsDetached && !mapDetached) {
          return StudioDockablePanel(
            activeColor: activeColor,
            tooltip: 'Desencaixar Mapa',
            onDetach: onDetachMindMap,
            child: _buildMindMap(),
          );
        }

        if (compact) {
          return Column(
            children: [
              Expanded(
                child: StudioDockablePanel(
                  activeColor: activeColor,
                  tooltip: 'Desencaixar Letra',
                  onDetach: onDetachLyrics,
                  child: _buildLyricsEditor(),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: StudioDockablePanel(
                  activeColor: activeColor,
                  tooltip: 'Desencaixar Mapa',
                  onDetach: onDetachMindMap,
                  child: _buildMindMap(),
                ),
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              flex: 3,
              child: StudioDockablePanel(
                activeColor: activeColor,
                tooltip: 'Desencaixar Letra',
                onDetach: onDetachLyrics,
                child: _buildLyricsEditor(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: StudioDockablePanel(
                activeColor: activeColor,
                tooltip: 'Desencaixar Mapa',
                onDetach: onDetachMindMap,
                child: _buildMindMap(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLyricsEditor() {
    return LyricEditor(
      controller: controller.lyricController,
      suggestionController: brainController.suggestionController,
      rhymeLibrary: controller.timelineController.rhymeLibrary,
      activeColor: activeColor,
      onSelectionChanged: controller.updateSelectedText,
      onAddToMap: (text) {
        controller.addMindMapNode(text: text, position: const Offset(40, 40));
      },
      onAddToTimeline: controller.addTimelineWord,
      onAskChat: onAskChat,
    );
  }

  Widget _buildMindMap() {
    return MindMap(
      nodes: controller.mindMapNodes,
      selectedNodeId: controller.selectedNodeId,
      activeColor: activeColor,
      onSelectNode: controller.selectMindMapNode,
      onMoveNode: controller.moveMindMapNode,
      onRemoveNode: controller.removeMindMapNode,
      onAddNodeToTimeline: controller.addNodeToTimeline,
      onAddNode: onAddMindMapNode,
      onConnectNodes: controller.connectMindMapNodes,
    );
  }
}
