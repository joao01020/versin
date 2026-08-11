import 'package:flutter/material.dart';

import 'package:versin/modules/studio/controllers/studio_controller.dart';
import 'package:versin/modules/studio/models/mind_map_node.dart';
import 'package:versin/modules/studio/widgets/lyric_editor.dart';
import 'package:versin/modules/studio/widgets/mind_map.dart';
import 'package:versin/modules/studio/widgets/song_word_timeline.dart';

class StudioPage extends StatefulWidget {
  const StudioPage({super.key});

  @override
  State<StudioPage> createState() => _StudioPageState();
}

class _StudioPageState extends State<StudioPage> {
  late final StudioController controller;

  final Color activeColor = const Color(0xFFE100FF);

  @override
  void initState() {
    super.initState();

    controller = StudioController();
  }

  @override
  void dispose() {
    controller.dispose();

    super.dispose();
  }

  // ============================================================
  // ADICIONAR PALAVRA À TIMELINE
  // ============================================================

  Future<void> _showAddTimelineWordDialog() async {
    final textController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Adicionar à Timeline',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: textController,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Digite uma palavra ou ideia...',
              hintStyle: TextStyle(color: Colors.white30),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.purpleAccent),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('CANCELAR'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, textController.text.trim());
              },
              child: Text('ADICIONAR', style: TextStyle(color: activeColor)),
            ),
          ],
        );
      },
    );

    textController.dispose();

    if (result == null || result.isEmpty) {
      return;
    }

    controller.addTimelineWord(result);
  }

  // ============================================================
  // ADICIONAR NÓ AO MAPA
  // ============================================================

  Future<void> _showAddMindMapNodeDialog() async {
    final textController = TextEditingController();

    MindMapNodeType selectedType = MindMapNodeType.idea;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1A1A),
              title: const Text(
                'Adicionar ao Mapa',
                style: TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: textController,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Ex: madrugada, saudade, reflexo...',
                      hintStyle: TextStyle(color: Colors.white30),
                    ),
                  ),

                  const SizedBox(height: 18),

                  DropdownButtonFormField<MindMapNodeType>(
                    initialValue: selectedType,
                    dropdownColor: const Color(0xFF1A1A1A),
                    decoration: const InputDecoration(
                      labelText: 'Tipo',
                      labelStyle: TextStyle(color: Colors.white54),
                    ),
                    style: const TextStyle(color: Colors.white),
                    items: MindMapNodeType.values.map((type) {
                      return DropdownMenuItem<MindMapNodeType>(
                        value: type,
                        child: Text(_nodeTypeLabel(type)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }

                      setDialogState(() {
                        selectedType = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('CANCELAR'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, {
                      'text': textController.text.trim(),
                      'type': selectedType,
                    });
                  },
                  child: Text(
                    'ADICIONAR',
                    style: TextStyle(color: activeColor),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    textController.dispose();

    if (result == null) {
      return;
    }

    final text = result['text']?.toString().trim();

    final type = result['type'] as MindMapNodeType?;

    if (text == null || text.isEmpty || type == null) {
      return;
    }

    final index = controller.mindMapNodes.length;

    final position = Offset(40 + (index % 3) * 130, 50 + (index ~/ 3) * 90);

    controller.addMindMapNode(text: text, type: type, position: position);
  }

  // ============================================================
  // SALVAR
  // ============================================================

  void _saveProject() {
    final data = controller.exportProject();

    debugPrint('================ STUDIO SAVE ================');

    debugPrint(data.toString());

    debugPrint('=============================================');

    controller.markAsSaved();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Projeto preparado para salvar.')),
    );
  }

  // ============================================================
  // CHAT
  // ============================================================

  void _askChat(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Trecho preparado para consultar no Chat: "$text"'),
      ),
    );

    // ==========================================================
    // FUTURO:
    //
    // Aqui vamos abrir o Chat já com o trecho selecionado.
    //
    // Exemplo:
    //
    // Navigator.pushNamed(
    //   context,
    //   AppRoutes.chat,
    //   arguments: {
    //     'selected_text': text,
    //   },
    // );
    // ==========================================================
  }

  // ============================================================
  // EDITAR TÍTULO
  // ============================================================

  Future<void> _editTitle() async {
    final textController = TextEditingController(text: controller.title);

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Nome da Música',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: textController,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('CANCELAR'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, textController.text.trim());
              },
              child: Text('SALVAR', style: TextStyle(color: activeColor)),
            ),
          ],
        );
      },
    );

    textController.dispose();

    if (result == null || result.isEmpty) {
      return;
    }

    controller.updateTitle(result);
  }

  // ============================================================
  // BPM
  // ============================================================

  Future<void> _editBpm() async {
    final textController = TextEditingController(
      text: controller.bpm.toString(),
    );

    final result = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text('BPM', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: textController,
            autofocus: true,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(hintText: '120'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('CANCELAR'),
            ),
            TextButton(
              onPressed: () {
                final value = int.tryParse(textController.text);

                Navigator.pop(context, value);
              },
              child: Text('SALVAR', style: TextStyle(color: activeColor)),
            ),
          ],
        );
      },
    );

    textController.dispose();

    if (result == null || result <= 0) {
      return;
    }

    controller.updateBpm(result);
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFF0D0D0D),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  // =============================================
                  // HEADER
                  // =============================================
                  _buildHeader(),

                  const SizedBox(height: 12),

                  // =============================================
                  // LETRA + MAPA
                  // =============================================
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 850;

                        if (compact) {
                          return Column(
                            children: [
                              Expanded(
                                child: LyricEditor(
                                  controller: controller.lyricController,
                                  activeColor: activeColor,
                                  onSelectionChanged:
                                      controller.updateSelectedText,
                                  onAddToMap: (text) {
                                    controller.addMindMapNode(
                                      text: text,
                                      position: const Offset(40, 40),
                                    );
                                  },
                                  onAddToTimeline: controller.addTimelineWord,
                                  onAskChat: _askChat,
                                ),
                              ),

                              const SizedBox(height: 12),

                              Expanded(
                                child: MindMap(
                                  nodes: controller.mindMapNodes,
                                  selectedNodeId: controller.selectedNodeId,
                                  activeColor: activeColor,
                                  onSelectNode: controller.selectMindMapNode,
                                  onMoveNode: controller.moveMindMapNode,
                                  onRemoveNode: controller.removeMindMapNode,
                                  onAddNodeToTimeline:
                                      controller.addNodeToTimeline,
                                  onAddNode: _showAddMindMapNodeDialog,
                                ),
                              ),
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: LyricEditor(
                                controller: controller.lyricController,
                                activeColor: activeColor,
                                onSelectionChanged:
                                    controller.updateSelectedText,
                                onAddToMap: (text) {
                                  controller.addMindMapNode(
                                    text: text,
                                    position: const Offset(40, 40),
                                  );
                                },
                                onAddToTimeline: controller.addTimelineWord,
                                onAskChat: _askChat,
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              flex: 2,
                              child: MindMap(
                                nodes: controller.mindMapNodes,
                                selectedNodeId: controller.selectedNodeId,
                                activeColor: activeColor,
                                onSelectNode: controller.selectMindMapNode,
                                onMoveNode: controller.moveMindMapNode,
                                onRemoveNode: controller.removeMindMapNode,
                                onAddNodeToTimeline:
                                    controller.addNodeToTimeline,
                                onAddNode: _showAddMindMapNodeDialog,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  // =============================================
                  // TIMELINE
                  // =============================================
                  SongWordTimeline(
                    words: controller.timelineWords,
                    activeColor: activeColor,
                    isWordUsed: controller.isTimelineWordUsed,
                    onRemoveWord: controller.removeTimelineWord,
                    onAddWord: _showAddTimelineWordDialog,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          // =====================================================
          // TÍTULO
          // =====================================================
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: _editTitle,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        controller.title,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 0.7,
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    const Icon(
                      Icons.edit_outlined,
                      color: Colors.white30,
                      size: 14,
                    ),

                    if (controller.hasUnsavedChanges) ...[
                      const SizedBox(width: 8),

                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: activeColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // =====================================================
          // BPM
          // =====================================================
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: _editBpm,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: activeColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.speed_rounded, color: activeColor, size: 16),

                  const SizedBox(width: 6),

                  Text(
                    '${controller.bpm} BPM',
                    style: TextStyle(
                      color: activeColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 10),

          // =====================================================
          // SALVAR
          // =====================================================
          ElevatedButton.icon(
            onPressed: _saveProject,
            style: ElevatedButton.styleFrom(
              backgroundColor: activeColor,
              foregroundColor: Colors.black,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.save_outlined, size: 17),
            label: const Text(
              'SALVAR',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LABEL DO TIPO
  // ============================================================

  static String _nodeTypeLabel(MindMapNodeType type) {
    switch (type) {
      case MindMapNodeType.idea:
        return 'Ideia';

      case MindMapNodeType.scene:
        return 'Cena';

      case MindMapNodeType.emotion:
        return 'Emoção';

      case MindMapNodeType.image:
        return 'Imagem';

      case MindMapNodeType.rhyme:
        return 'Rima';

      case MindMapNodeType.concept:
        return 'Conceito';
    }
  }
}
