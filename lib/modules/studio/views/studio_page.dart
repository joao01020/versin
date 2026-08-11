import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'package:versin/modules/brain/controller/brain_controller.dart';
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
  late final BrainController brainController;
  late final StudioController controller;

  final Color activeColor = const Color(0xFFE100FF);

  // ============================================================
  // POSIÇÃO DOS PAINÉIS FLUTUANTES
  // ============================================================

  Offset _lyricsFloatingPosition = const Offset(80, 90);

  Offset _mindMapFloatingPosition = const Offset(360, 130);

  @override
  void initState() {
    super.initState();

    // ==========================================================
    // MESMO CÉREBRO GLOBAL USADO PELO CHAT / BIBLIOTECA
    // ==========================================================

    brainController = GetIt.I<BrainController>();

    // ==========================================================
    // CONTROLLER DO STUDIO — INSTÂNCIA DA SESSÃO
    // ==========================================================
    //
    // Não criamos mais StudioController aqui.
    //
    // O GetIt mantém uma única instância durante toda a sessão
    // do aplicativo, preservando:
    //
    // - título
    // - letra
    // - BPM
    // - Timeline
    // - mapa mental
    // - posições dos nós
    // - conexões
    //
    // ==========================================================

    controller = GetIt.I<StudioController>();

    // ==========================================================
    // CARREGAR BANCO DE RIMAS DEPOIS DO PRIMEIRO FRAME
    // ==========================================================
    //
    // carregarDadosUsuario() executa notifyListeners().
    // Como o Studio fica dentro do PageView, chamar isso
    // diretamente no initState pode disparar rebuild durante
    // a montagem da árvore e causar:
    //
    // setState() or markNeedsBuild() called during build.
    //
    // ==========================================================

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }

      await brainController.carregarDadosUsuario();
    });
  }

  @override
  void dispose() {
    // ==========================================================
    // NÃO DESTRUIR O STUDIOCONTROLLER
    // ==========================================================
    //
    // StudioController pertence ao GetIt e deve continuar vivo
    // enquanto o aplicativo estiver aberto.
    //
    // Se chamarmos controller.dispose() aqui, perderíamos o
    // estado da sessão ao sair do Studio.
    //
    // ==========================================================

    super.dispose();
  }

  // ============================================================
  // ADICIONAR PALAVRA À TIMELINE
  // ============================================================

  Future<void> _showAddTimelineWordDialog() async {
    final librarySnapshot = List<String>.from(controller.rhymeLibrary);

    final timelineSnapshot = Set<String>.from(
      controller.timelineWords.map((word) => word.trim().toLowerCase()),
    );

    final result = await showDialog<String>(
      context: context,
      builder: (_) {
        return _TimelineLibraryDialog(
          libraryWords: librarySnapshot,
          timelineWords: timelineSnapshot,
          activeColor: activeColor,
        );
      },
    );

    if (!mounted || result == null || result.trim().isEmpty) {
      return;
    }

    controller.addTimelineWord(result.trim());
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
            child: LayoutBuilder(
              builder: (context, pageConstraints) {
                final pageSize = Size(
                  pageConstraints.maxWidth,
                  pageConstraints.maxHeight,
                );

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // =================================================
                    // CONTEÚDO PRINCIPAL
                    // =================================================
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          children: [
                            // =========================================
                            // HEADER
                            // =========================================
                            _buildHeader(),

                            const SizedBox(height: 12),

                            // =========================================
                            // LETRA + MAPA
                            // =========================================
                            Expanded(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  return _buildDockedWorkspace(constraints);
                                },
                              ),
                            ),

                            const SizedBox(height: 12),

                            // =========================================
                            // TIMELINE
                            // =========================================
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

                    // =================================================
                    // LETRA DESTACADA
                    // =================================================
                    if (controller.isLyricsDetached)
                      _buildFloatingLyricsPanel(pageSize),

                    // =================================================
                    // MAPA DESTACADO
                    // =================================================
                    if (controller.isMindMapDetached)
                      _buildFloatingMindMapPanel(pageSize),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // WORKSPACE ENCAIXADO
  // ============================================================

  Widget _buildDockedWorkspace(BoxConstraints constraints) {
    final compact = constraints.maxWidth < 850;

    final lyricsDetached = controller.isLyricsDetached;

    final mapDetached = controller.isMindMapDetached;

    // ==========================================================
    // AMBOS DESTACADOS
    // ==========================================================

    if (lyricsDetached && mapDetached) {
      return _DetachedWorkspacePlaceholder(
        activeColor: activeColor,
        onDockAll: controller.dockAllPanels,
      );
    }

    // ==========================================================
    // APENAS LETRA ENCAIXADA
    // ==========================================================

    if (!lyricsDetached && mapDetached) {
      return _DockableHoverPanel(
        activeColor: activeColor,
        tooltip: 'Desencaixar Letra',
        onDetach: controller.detachLyrics,
        child: _buildLyricsEditor(),
      );
    }

    // ==========================================================
    // APENAS MAPA ENCAIXADO
    // ==========================================================

    if (lyricsDetached && !mapDetached) {
      return _DockableHoverPanel(
        activeColor: activeColor,
        tooltip: 'Desencaixar Mapa',
        onDetach: controller.detachMindMap,
        child: _buildMindMap(),
      );
    }

    // ==========================================================
    // AMBOS ENCAIXADOS
    // ==========================================================

    if (compact) {
      return Column(
        children: [
          Expanded(
            child: _DockableHoverPanel(
              activeColor: activeColor,
              tooltip: 'Desencaixar Letra',
              onDetach: controller.detachLyrics,
              child: _buildLyricsEditor(),
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: _DockableHoverPanel(
              activeColor: activeColor,
              tooltip: 'Desencaixar Mapa',
              onDetach: controller.detachMindMap,
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
          child: _DockableHoverPanel(
            activeColor: activeColor,
            tooltip: 'Desencaixar Letra',
            onDetach: controller.detachLyrics,
            child: _buildLyricsEditor(),
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          flex: 2,
          child: _DockableHoverPanel(
            activeColor: activeColor,
            tooltip: 'Desencaixar Mapa',
            onDetach: controller.detachMindMap,
            child: _buildMindMap(),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EDITOR DE LETRA
  // ============================================================

  Widget _buildLyricsEditor() {
    return LyricEditor(
      controller: controller.lyricController,
      activeColor: activeColor,
      onSelectionChanged: controller.updateSelectedText,
      onAddToMap: (text) {
        controller.addMindMapNode(text: text, position: const Offset(40, 40));
      },
      onAddToTimeline: controller.addTimelineWord,
      onAskChat: _askChat,
    );
  }

  // ============================================================
  // MAPA
  // ============================================================

  Widget _buildMindMap() {
    return MindMap(
      nodes: controller.mindMapNodes,
      selectedNodeId: controller.selectedNodeId,
      activeColor: activeColor,
      onSelectNode: controller.selectMindMapNode,
      onMoveNode: controller.moveMindMapNode,
      onRemoveNode: controller.removeMindMapNode,
      onAddNodeToTimeline: controller.addNodeToTimeline,
      onAddNode: _showAddMindMapNodeDialog,
      onConnectNodes: controller.connectMindMapNodes,
    );
  }

  // ============================================================
  // PAINEL FLUTUANTE — LETRA
  // ============================================================

  Widget _buildFloatingLyricsPanel(Size pageSize) {
    final width = math.min(680.0, math.max(360.0, pageSize.width * 0.58));

    final height = math.min(560.0, math.max(320.0, pageSize.height * 0.68));

    return Positioned(
      left: _lyricsFloatingPosition.dx,
      top: _lyricsFloatingPosition.dy,
      width: width,
      height: height,
      child: _FloatingStudioPanel(
        title: 'LETRA',
        activeColor: activeColor,
        onDock: controller.dockLyrics,
        onDrag: (delta) {
          setState(() {
            _lyricsFloatingPosition = _clampFloatingPosition(
              _lyricsFloatingPosition + delta,
              pageSize,
              Size(width, height),
            );
          });
        },
        child: _buildLyricsEditor(),
      ),
    );
  }

  // ============================================================
  // PAINEL FLUTUANTE — MAPA
  // ============================================================

  Widget _buildFloatingMindMapPanel(Size pageSize) {
    final width = math.min(620.0, math.max(340.0, pageSize.width * 0.50));

    final height = math.min(540.0, math.max(320.0, pageSize.height * 0.64));

    return Positioned(
      left: _mindMapFloatingPosition.dx,
      top: _mindMapFloatingPosition.dy,
      width: width,
      height: height,
      child: _FloatingStudioPanel(
        title: 'MAPA',
        activeColor: activeColor,
        onDock: controller.dockMindMap,
        onDrag: (delta) {
          setState(() {
            _mindMapFloatingPosition = _clampFloatingPosition(
              _mindMapFloatingPosition + delta,
              pageSize,
              Size(width, height),
            );
          });
        },
        child: _buildMindMap(),
      ),
    );
  }

  // ============================================================
  // LIMITAR POSIÇÃO DO PAINEL
  // ============================================================

  Offset _clampFloatingPosition(
    Offset position,
    Size pageSize,
    Size panelSize,
  ) {
    final maxX = math.max(0.0, pageSize.width - panelSize.width);

    final maxY = math.max(0.0, pageSize.height - panelSize.height);

    return Offset(position.dx.clamp(0.0, maxX), position.dy.clamp(0.0, maxY));
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

// ============================================================
// PAINEL ENCAIXADO COM HOVER
// ============================================================

class _DockableHoverPanel extends StatefulWidget {
  final Color activeColor;

  final String tooltip;

  final VoidCallback onDetach;

  final Widget child;

  const _DockableHoverPanel({
    required this.activeColor,
    required this.tooltip,
    required this.onDetach,
    required this.child,
  });

  @override
  State<_DockableHoverPanel> createState() => _DockableHoverPanelState();
}

class _DockableHoverPanelState extends State<_DockableHoverPanel> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _hovered = true;
        });
      },
      onExit: (_) {
        setState(() {
          _hovered = false;
        });
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: widget.child),

          // ====================================================
          // BOTÃO DE DESENCAIXAR
          // ====================================================
          Positioned(
            top: 7,
            right: 42,
            child: IgnorePointer(
              ignoring: !_hovered,
              child: AnimatedOpacity(
                opacity: _hovered ? 1 : 0,
                duration: const Duration(milliseconds: 130),
                child: Tooltip(
                  message: widget.tooltip,
                  child: Material(
                    color: const Color(0xFF171717),
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: widget.onDetach,
                      child: Padding(
                        padding: const EdgeInsets.all(7),
                        child: Icon(
                          Icons.open_in_new_rounded,
                          size: 15,
                          color: widget.activeColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PAINEL FLUTUANTE
// ============================================================

class _FloatingStudioPanel extends StatelessWidget {
  final String title;

  final Color activeColor;

  final VoidCallback onDock;

  final ValueChanged<Offset> onDrag;

  final Widget child;

  const _FloatingStudioPanel({
    required this.title,
    required this.activeColor,
    required this.onDock,
    required this.onDrag,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 24,
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: activeColor.withValues(alpha: 0.32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              // =================================================
              // BARRA DE ARRASTE
              // =================================================
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanUpdate: (details) {
                  onDrag(details.delta);
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.move,
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.only(left: 12, right: 4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF171717),
                      border: Border(bottom: BorderSide(color: Colors.white10)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.drag_indicator_rounded,
                          size: 16,
                          color: Colors.white24,
                        ),

                        const SizedBox(width: 7),

                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),

                        const Spacer(),

                        IconButton(
                          tooltip: 'Encaixar novamente',
                          onPressed: onDock,
                          icon: Icon(
                            Icons.call_merge_rounded,
                            size: 17,
                            color: activeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // =================================================
              // CONTEÚDO
              // =================================================
              Expanded(
                child: Padding(padding: const EdgeInsets.all(8), child: child),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// PLACEHOLDER QUANDO OS DOIS PAINÉIS ESTÃO DESTACADOS
// ============================================================

class _DetachedWorkspacePlaceholder extends StatelessWidget {
  final Color activeColor;

  final VoidCallback onDockAll;

  const _DetachedWorkspacePlaceholder({
    required this.activeColor,
    required this.onDockAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.dashboard_customize_outlined,
              size: 28,
              color: activeColor.withValues(alpha: 0.5),
            ),

            const SizedBox(height: 10),

            const Text(
              'LETRA e MAPA estão destacados',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 10),

            TextButton.icon(
              onPressed: onDockAll,
              icon: Icon(
                Icons.call_merge_rounded,
                size: 16,
                color: activeColor,
              ),
              label: Text(
                'ENCAIXAR PAINÉIS',
                style: TextStyle(
                  color: activeColor,
                  fontSize: 10,
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

// ============================================================
// DIÁLOGO DA BIBLIOTECA DA TIMELINE
// ============================================================

class _TimelineLibraryDialog extends StatefulWidget {
  final List<String> libraryWords;
  final Set<String> timelineWords;
  final Color activeColor;

  const _TimelineLibraryDialog({
    required this.libraryWords,
    required this.timelineWords,
    required this.activeColor,
  });

  @override
  State<_TimelineLibraryDialog> createState() => _TimelineLibraryDialogState();
}

class _TimelineLibraryDialogState extends State<_TimelineLibraryDialog> {
  late final TextEditingController _searchController;

  String _search = '';

  @override
  void initState() {
    super.initState();

    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();

    super.dispose();
  }

  // ============================================================
  // PALAVRAS FILTRADAS
  // ============================================================

  List<String> get _filteredWords {
    final query = _search.trim().toLowerCase();

    final seen = <String>{};

    return widget.libraryWords.where((word) {
      final normalized = word.trim().toLowerCase();

      if (normalized.isEmpty) {
        return false;
      }

      if (!seen.add(normalized)) {
        return false;
      }

      if (widget.timelineWords.contains(normalized)) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      return normalized.contains(query);
    }).toList();
  }

  // ============================================================
  // FECHAR COM RESULTADO
  // ============================================================

  void _finish(String word) {
    final normalized = word.trim();

    if (normalized.isEmpty) {
      return;
    }

    Navigator.of(context).pop(normalized);
  }

  // ============================================================
  // LIMPAR BUSCA
  // ============================================================

  void _clearSearch() {
    _searchController.clear();

    setState(() {
      _search = '';
    });
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final libraryWords = _filteredWords;

    final hasSearch = _search.trim().isNotEmpty;

    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      title: const Text(
        'Adicionar à Timeline',
        style: TextStyle(color: Colors.white),
      ),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================================================
            // BUSCA
            // ==================================================
            TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              onChanged: (value) {
                setState(() {
                  _search = value;
                });
              },
              onSubmitted: _finish,
              decoration: InputDecoration(
                hintText: 'Buscar na biblioteca ou criar uma palavra...',
                hintStyle: const TextStyle(color: Colors.white30),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Colors.white30,
                ),
                suffixIcon: !hasSearch
                    ? null
                    : IconButton(
                        onPressed: _clearSearch,
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white30,
                        ),
                      ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.04),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: widget.activeColor),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // ==================================================
            // CABEÇALHO DA BIBLIOTECA
            // ==================================================
            Row(
              children: [
                const Text(
                  'BIBLIOTECA',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),

                const SizedBox(width: 8),

                Text(
                  '${libraryWords.length}',
                  style: const TextStyle(color: Colors.white24, fontSize: 10),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ==================================================
            // LISTA
            // ==================================================
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: libraryWords.isEmpty
                  ? _buildEmptyState()
                  : SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: libraryWords.map((word) {
                          return InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              _finish(word);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: widget.activeColor.withValues(
                                  alpha: 0.08,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: widget.activeColor.withValues(
                                    alpha: 0.20,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.add_rounded,
                                    color: widget.activeColor,
                                    size: 15,
                                  ),

                                  const SizedBox(width: 5),

                                  Text(
                                    word,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
            ),

            // ==================================================
            // CRIAR NOVA PALAVRA
            // ==================================================
            if (hasSearch) ...[
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _finish(_search);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: widget.activeColor,
                    side: BorderSide(
                      color: widget.activeColor.withValues(alpha: 0.35),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 17),
                  label: Text(
                    'CRIAR "${_search.trim()}"',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('CANCELAR'),
        ),
      ],
    );
  }

  // ============================================================
  // ESTADO VAZIO
  // ============================================================

  Widget _buildEmptyState() {
    final hasSearch = _search.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.library_books_outlined,
            color: Colors.white24,
            size: 28,
          ),

          const SizedBox(height: 10),

          Text(
            hasSearch
                ? 'Nenhuma palavra encontrada.'
                : 'Nenhuma palavra disponível na biblioteca.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white30, fontSize: 11),
          ),

          if (hasSearch) ...[
            const SizedBox(height: 6),

            Text(
              'Você pode criar "${_search.trim()}" usando o botão abaixo.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white24, fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }
}
