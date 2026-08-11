import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:versin/modules/studio/models/mind_map_node.dart';

class MindMap
    extends
        StatelessWidget {
  final List<
    MindMapNode
  >
  nodes;

  final String? selectedNodeId;

  final Color activeColor;

  final ValueChanged<
    String?
  >
  onSelectNode;

  final void Function(
    String nodeId,
    Offset delta,
  )
  onMoveNode;

  final ValueChanged<
    String
  >
  onRemoveNode;

  final ValueChanged<
    String
  >
  onAddNodeToTimeline;

  final VoidCallback onAddNode;

  const MindMap({
    super.key,
    required this.nodes,
    required this.selectedNodeId,
    required this.activeColor,
    required this.onSelectNode,
    required this.onMoveNode,
    required this.onRemoveNode,
    required this.onAddNodeToTimeline,
    required this.onAddNode,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(
          0xFF111111,
        ),
        borderRadius: BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.05,
          ),
        ),
      ),
      child: Column(
        children: [
          // =====================================================
          // HEADER
          // =====================================================
          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              14,
              12,
              10,
            ),
            child: Row(
              children: [
                const Text(
                  'MAPA',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.4,
                  ),
                ),

                const Spacer(),

                IconButton(
                  tooltip: 'Adicionar ideia',
                  onPressed: onAddNode,
                  icon: Icon(
                    Icons.add_rounded,
                    color: activeColor,
                  ),
                ),
              ],
            ),
          ),

          const Divider(
            height: 1,
            color: Colors.white10,
          ),

          // =====================================================
          // ÁREA DO MAPA
          // =====================================================
          Expanded(
            child: LayoutBuilder(
              builder:
                  (
                    context,
                    constraints,
                  ) {
                    if (nodes.isEmpty) {
                      return _EmptyMindMap(
                        activeColor: activeColor,
                        onAddNode: onAddNode,
                      );
                    }

                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        onSelectNode(
                          null,
                        );
                      },
                      child: ClipRect(
                        child: Stack(
                          children: [
                            // =========================================
                            // CONEXÕES
                            // =========================================
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _MindMapConnectionsPainter(
                                  nodes: nodes,
                                  activeColor: activeColor,
                                ),
                              ),
                            ),

                            // =========================================
                            // NÓS
                            // =========================================
                            for (final node in nodes)
                              Positioned(
                                left: _safeX(
                                  node.x,
                                  constraints.maxWidth,
                                ),
                                top: _safeY(
                                  node.y,
                                  constraints.maxHeight,
                                ),
                                child: _MindMapNodeCard(
                                  node: node,
                                  isSelected:
                                      node.id ==
                                      selectedNodeId,
                                  activeColor: activeColor,
                                  onTap: () {
                                    onSelectNode(
                                      node.id,
                                    );
                                  },
                                  onMove:
                                      (
                                        delta,
                                      ) {
                                        onMoveNode(
                                          node.id,
                                          delta,
                                        );
                                      },
                                  onRemove: () {
                                    onRemoveNode(
                                      node.id,
                                    );
                                  },
                                  onAddToTimeline: () {
                                    onAddNodeToTimeline(
                                      node.id,
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LIMITAR POSIÇÃO VISUAL
  // ============================================================

  double _safeX(
    double x,
    double maxWidth,
  ) {
    if (maxWidth <=
        140) {
      return 0;
    }

    return x.clamp(
      0.0,
      maxWidth -
          140,
    );
  }

  double _safeY(
    double y,
    double maxHeight,
  ) {
    if (maxHeight <=
        70) {
      return 0;
    }

    return y.clamp(
      0.0,
      maxHeight -
          70,
    );
  }
}

// ============================================================
// ESTADO VAZIO
// ============================================================

class _EmptyMindMap
    extends
        StatelessWidget {
  final Color activeColor;
  final VoidCallback onAddNode;

  const _EmptyMindMap({
    required this.activeColor,
    required this.onAddNode,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(
          24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_tree_outlined,
              color: activeColor.withValues(
                alpha: 0.55,
              ),
              size: 34,
            ),

            const SizedBox(
              height: 14,
            ),

            const Text(
              'Seu mapa ainda está vazio',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            const Text(
              'Selecione palavras da letra ou adicione uma ideia para começar a enxergar a música.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white38,
                fontSize: 11,
                height: 1.5,
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            TextButton.icon(
              onPressed: onAddNode,
              icon: Icon(
                Icons.add_rounded,
                color: activeColor,
                size: 18,
              ),
              label: Text(
                'ADICIONAR IDEIA',
                style: TextStyle(
                  color: activeColor,
                  fontSize: 11,
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
// CARD DO NÓ
// ============================================================

class _MindMapNodeCard
    extends
        StatelessWidget {
  final MindMapNode node;

  final bool isSelected;

  final Color activeColor;

  final VoidCallback onTap;

  final ValueChanged<
    Offset
  >
  onMove;

  final VoidCallback onRemove;

  final VoidCallback onAddToTimeline;

  const _MindMapNodeCard({
    required this.node,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
    required this.onMove,
    required this.onRemove,
    required this.onAddToTimeline,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final nodeColor = _resolveNodeColor();

    return GestureDetector(
      onTap: onTap,
      onPanUpdate:
          (
            details,
          ) {
            onMove(
              details.delta,
            );
          },
      child: AnimatedContainer(
        duration: const Duration(
          milliseconds: 160,
        ),
        constraints: const BoxConstraints(
          minWidth: 90,
          maxWidth: 150,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? nodeColor.withValues(
                  alpha: 0.16,
                )
              : const Color(
                  0xFF1A1A1A,
                ),
          borderRadius: BorderRadius.circular(
            14,
          ),
          border: Border.all(
            color: isSelected
                ? nodeColor.withValues(
                    alpha: 0.65,
                  )
                : nodeColor.withValues(
                    alpha: 0.20,
                  ),
            width: isSelected
                ? 1.4
                : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: nodeColor.withValues(
                      alpha: 0.16,
                    ),
                    blurRadius: 12,
                  ),
                ]
              : const [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // =================================================
            // TIPO
            // =================================================
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _resolveNodeIcon(),
                  size: 12,
                  color: nodeColor.withValues(
                    alpha: 0.7,
                  ),
                ),

                const SizedBox(
                  width: 4,
                ),

                Flexible(
                  child: Text(
                    _resolveNodeLabel(),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: nodeColor.withValues(
                        alpha: 0.7,
                      ),
                      fontSize: 8,
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 5,
            ),

            // =================================================
            // TEXTO
            // =================================================
            Text(
              node.text,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                height: 1.25,
                fontWeight: FontWeight.w600,
              ),
            ),

            // =================================================
            // AÇÕES QUANDO SELECIONADO
            // =================================================
            if (isSelected) ...[
              const SizedBox(
                height: 8,
              ),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _NodeActionButton(
                    icon: Icons.timeline_rounded,
                    tooltip: 'Levar para Timeline',
                    color: nodeColor,
                    onTap: onAddToTimeline,
                  ),

                  const SizedBox(
                    width: 6,
                  ),

                  _NodeActionButton(
                    icon: Icons.delete_outline_rounded,
                    tooltip: 'Remover',
                    color: Colors.redAccent,
                    onTap: onRemove,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TIPO → COR
  // ============================================================

  Color _resolveNodeColor() {
    switch (node.type) {
      case MindMapNodeType.idea:
        return activeColor;

      case MindMapNodeType.scene:
        return Colors.blueAccent;

      case MindMapNodeType.emotion:
        return Colors.pinkAccent;

      case MindMapNodeType.image:
        return Colors.cyanAccent;

      case MindMapNodeType.rhyme:
        return Colors.greenAccent;

      case MindMapNodeType.concept:
        return Colors.orangeAccent;
    }
  }

  // ============================================================
  // TIPO → ÍCONE
  // ============================================================

  IconData _resolveNodeIcon() {
    switch (node.type) {
      case MindMapNodeType.idea:
        return Icons.lightbulb_outline;

      case MindMapNodeType.scene:
        return Icons.movie_filter_outlined;

      case MindMapNodeType.emotion:
        return Icons.favorite_border;

      case MindMapNodeType.image:
        return Icons.image_outlined;

      case MindMapNodeType.rhyme:
        return Icons.music_note_outlined;

      case MindMapNodeType.concept:
        return Icons.hub_outlined;
    }
  }

  // ============================================================
  // TIPO → TEXTO
  // ============================================================

  String _resolveNodeLabel() {
    switch (node.type) {
      case MindMapNodeType.idea:
        return 'IDEIA';

      case MindMapNodeType.scene:
        return 'CENA';

      case MindMapNodeType.emotion:
        return 'EMOÇÃO';

      case MindMapNodeType.image:
        return 'IMAGEM';

      case MindMapNodeType.rhyme:
        return 'RIMA';

      case MindMapNodeType.concept:
        return 'CONCEITO';
    }
  }
}

// ============================================================
// BOTÃO PEQUENO DO NÓ
// ============================================================

class _NodeActionButton
    extends
        StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  const _NodeActionButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(
          8,
        ),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(
            6,
          ),
          decoration: BoxDecoration(
            color: color.withValues(
              alpha: 0.08,
            ),
            borderRadius: BorderRadius.circular(
              8,
            ),
          ),
          child: Icon(
            icon,
            size: 14,
            color: color.withValues(
              alpha: 0.8,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// DESENHO DAS CONEXÕES
// ============================================================

class _MindMapConnectionsPainter
    extends
        CustomPainter {
  final List<
    MindMapNode
  >
  nodes;
  final Color activeColor;

  const _MindMapConnectionsPainter({
    required this.nodes,
    required this.activeColor,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final nodeMap = {
      for (final node in nodes) node.id: node,
    };

    final drawnConnections =
        <
          String
        >{};

    final paint = Paint()
      ..color = activeColor.withValues(
        alpha: 0.18,
      )
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final node in nodes) {
      for (final connectionId in node.connections) {
        final target = nodeMap[connectionId];

        if (target ==
            null) {
          continue;
        }

        final ids = [
          node.id,
          target.id,
        ]..sort();

        final connectionKey = '${ids[0]}-${ids[1]}';

        if (drawnConnections.contains(
          connectionKey,
        )) {
          continue;
        }

        drawnConnections.add(
          connectionKey,
        );

        final start = Offset(
          node.x +
              70,
          node.y +
              30,
        );

        final end = Offset(
          target.x +
              70,
          target.y +
              30,
        );

        final path = Path();

        path.moveTo(
          start.dx,
          start.dy,
        );

        final distance =
            (end.dx -
                    start.dx)
                .abs();

        final curve = math.max(
          40.0,
          distance *
              0.35,
        );

        path.cubicTo(
          start.dx +
              curve,
          start.dy,
          end.dx -
              curve,
          end.dy,
          end.dx,
          end.dy,
        );

        canvas.drawPath(
          path,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(
    covariant _MindMapConnectionsPainter oldDelegate,
  ) {
    return oldDelegate.nodes !=
            nodes ||
        oldDelegate.activeColor !=
            activeColor;
  }
}
