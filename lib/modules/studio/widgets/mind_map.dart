import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:versin/modules/studio/models/mind_map_node.dart';

// ============================================================
// PORTAS DE CONEXÃO
// ============================================================

enum _MindMapPort { top, right, bottom, left }

// ============================================================
// MAPA MENTAL
// ============================================================

class MindMap extends StatefulWidget {
  final List<MindMapNode> nodes;

  final String? selectedNodeId;

  final Color activeColor;

  final ValueChanged<String?> onSelectNode;

  final void Function(String nodeId, Offset delta) onMoveNode;

  final ValueChanged<String> onRemoveNode;

  final ValueChanged<String> onAddNodeToTimeline;

  final VoidCallback onAddNode;

  // ============================================================
  // CONECTAR NÓS
  // ============================================================

  final void Function(String firstNodeId, String secondNodeId)? onConnectNodes;

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
    this.onConnectNodes,
  });

  @override
  State<MindMap> createState() => _MindMapState();
}

class _MindMapState extends State<MindMap> {
  // ============================================================
  // TAMANHO BASE DOS NÓS
  // ============================================================

  static const double _nodeWidth = 140;

  static const double _nodeHeight = 76;

  static const double _handleSize = 12;

  static const double _connectionSnapDistance = 24;

  // ============================================================
  // HOVER
  // ============================================================

  String? _hoveredNodeId;

  // ============================================================
  // CONEXÃO EM ANDAMENTO
  // ============================================================

  String? _connectingFromNodeId;

  _MindMapPort? _connectingFromPort;

  Offset? _connectionStart;

  Offset? _connectionCurrent;

  String? _hoveredTargetNodeId;

  _MindMapPort? _hoveredTargetPort;

  // ============================================================
  // ÁREA DO MAPA
  // ============================================================

  final GlobalKey _canvasKey = GlobalKey();

  // ============================================================
  // CONVERTER GLOBAL → LOCAL
  // ============================================================

  Offset _globalToCanvas(Offset globalPosition) {
    final renderObject = _canvasKey.currentContext?.findRenderObject();

    if (renderObject is! RenderBox) {
      return globalPosition;
    }

    return renderObject.globalToLocal(globalPosition);
  }

  // ============================================================
  // SAFE POSITION
  // ============================================================

  double _safeX(double x, double maxWidth) {
    if (maxWidth <= _nodeWidth) {
      return 0;
    }

    return x.clamp(0.0, maxWidth - _nodeWidth);
  }

  double _safeY(double y, double maxHeight) {
    if (maxHeight <= _nodeHeight) {
      return 0;
    }

    return y.clamp(0.0, maxHeight - _nodeHeight);
  }

  // ============================================================
  // POSIÇÃO DA PORTA
  // ============================================================

  Offset _portPosition(MindMapNode node, _MindMapPort port, Size canvasSize) {
    final x = _safeX(node.x, canvasSize.width);

    final y = _safeY(node.y, canvasSize.height);

    switch (port) {
      case _MindMapPort.top:
        return Offset(x + _nodeWidth / 2, y);

      case _MindMapPort.right:
        return Offset(x + _nodeWidth, y + _nodeHeight / 2);

      case _MindMapPort.bottom:
        return Offset(x + _nodeWidth / 2, y + _nodeHeight);

      case _MindMapPort.left:
        return Offset(x, y + _nodeHeight / 2);
    }
  }

  // ============================================================
  // INICIAR CONEXÃO
  // ============================================================

  void _startConnection({
    required MindMapNode node,
    required _MindMapPort port,
    required DragStartDetails details,
    required Size canvasSize,
  }) {
    final start = _portPosition(node, port, canvasSize);

    setState(() {
      _connectingFromNodeId = node.id;

      _connectingFromPort = port;

      _connectionStart = start;

      _connectionCurrent = _globalToCanvas(details.globalPosition);

      _hoveredTargetNodeId = null;

      _hoveredTargetPort = null;
    });
  }

  // ============================================================
  // ATUALIZAR CONEXÃO
  // ============================================================

  void _updateConnection({
    required DragUpdateDetails details,
    required Size canvasSize,
  }) {
    final current = _globalToCanvas(details.globalPosition);

    final target = _findNearestTarget(current, canvasSize);

    setState(() {
      _connectionCurrent = current;

      _hoveredTargetNodeId = target?.node.id;

      _hoveredTargetPort = target?.port;
    });
  }

  // ============================================================
  // FINALIZAR CONEXÃO
  // ============================================================

  void _finishConnection() {
    final fromId = _connectingFromNodeId;

    final targetId = _hoveredTargetNodeId;

    if (fromId != null && targetId != null && fromId != targetId) {
      widget.onConnectNodes?.call(fromId, targetId);
    }

    _cancelConnection();
  }

  // ============================================================
  // CANCELAR CONEXÃO
  // ============================================================

  void _cancelConnection() {
    if (!mounted) {
      return;
    }

    setState(() {
      _connectingFromNodeId = null;

      _connectingFromPort = null;

      _connectionStart = null;

      _connectionCurrent = null;

      _hoveredTargetNodeId = null;

      _hoveredTargetPort = null;
    });
  }

  // ============================================================
  // PROCURAR PORTA DE DESTINO
  // ============================================================

  _PortTarget? _findNearestTarget(Offset pointer, Size canvasSize) {
    _PortTarget? nearest;

    double nearestDistance = double.infinity;

    for (final node in widget.nodes) {
      if (node.id == _connectingFromNodeId) {
        continue;
      }

      for (final port in _MindMapPort.values) {
        final position = _portPosition(node, port, canvasSize);

        final distance = (pointer - position).distance;

        if (distance <= _connectionSnapDistance && distance < nearestDistance) {
          nearestDistance = distance;

          nearest = _PortTarget(node: node, port: port, position: position);
        }
      }
    }

    return nearest;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          // =====================================================
          // HEADER
          // =====================================================
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
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

                if (_connectingFromNodeId != null) ...[
                  Text(
                    'Conectando...',
                    style: TextStyle(
                      color: widget.activeColor.withValues(alpha: 0.7),
                      fontSize: 10,
                    ),
                  ),

                  const SizedBox(width: 6),

                  IconButton(
                    tooltip: 'Cancelar conexão',
                    onPressed: _cancelConnection,
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white38,
                      size: 18,
                    ),
                  ),
                ],

                IconButton(
                  tooltip: 'Adicionar ideia',
                  onPressed: widget.onAddNode,
                  icon: Icon(Icons.add_rounded, color: widget.activeColor),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Colors.white10),

          // =====================================================
          // ÁREA DO MAPA
          // =====================================================
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (widget.nodes.isEmpty) {
                  return _EmptyMindMap(
                    activeColor: widget.activeColor,
                    onAddNode: widget.onAddNode,
                  );
                }

                final canvasSize = Size(
                  constraints.maxWidth,
                  constraints.maxHeight,
                );

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (_connectingFromNodeId != null) {
                      _cancelConnection();

                      return;
                    }

                    widget.onSelectNode(null);
                  },
                  child: ClipRect(
                    child: Stack(
                      key: _canvasKey,
                      clipBehavior: Clip.none,
                      children: [
                        // =========================================
                        // CONEXÕES SALVAS + PREVIEW
                        // =========================================
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: _MindMapConnectionsPainter(
                                nodes: widget.nodes,
                                activeColor: widget.activeColor,
                                nodeWidth: _nodeWidth,
                                nodeHeight: _nodeHeight,
                                previewStart: _connectionStart,
                                previewCurrent: _previewEnd(canvasSize),
                              ),
                            ),
                          ),
                        ),

                        // =========================================
                        // NÓS
                        // =========================================
                        for (final node in widget.nodes)
                          Positioned(
                            left: _safeX(node.x, constraints.maxWidth),
                            top: _safeY(node.y, constraints.maxHeight),
                            child: _MindMapNodeWithHandles(
                              node: node,
                              width: _nodeWidth,
                              height: _nodeHeight,
                              isSelected: node.id == widget.selectedNodeId,
                              isHovered: node.id == _hoveredNodeId,
                              isConnectionSource:
                                  node.id == _connectingFromNodeId,
                              hoveredTargetPort: node.id == _hoveredTargetNodeId
                                  ? _hoveredTargetPort
                                  : null,
                              activeColor: widget.activeColor,
                              showHandles: _shouldShowHandles(node.id),
                              onHoverChanged: (hovering) {
                                if (_connectingFromNodeId != null) {
                                  return;
                                }

                                setState(() {
                                  _hoveredNodeId = hovering ? node.id : null;
                                });
                              },
                              onTap: () {
                                widget.onSelectNode(node.id);
                              },
                              onMove: (delta) {
                                if (_connectingFromNodeId != null) {
                                  return;
                                }

                                widget.onMoveNode(node.id, delta);
                              },
                              onRemove: () {
                                widget.onRemoveNode(node.id);
                              },
                              onAddToTimeline: () {
                                widget.onAddNodeToTimeline(node.id);
                              },
                              onConnectionStart: (port, details) {
                                _startConnection(
                                  node: node,
                                  port: port,
                                  details: details,
                                  canvasSize: canvasSize,
                                );
                              },
                              onConnectionUpdate: (details) {
                                _updateConnection(
                                  details: details,
                                  canvasSize: canvasSize,
                                );
                              },
                              onConnectionEnd: _finishConnection,
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
  // PREVIEW COM SNAP
  // ============================================================

  Offset? _previewEnd(Size canvasSize) {
    if (_hoveredTargetNodeId != null && _hoveredTargetPort != null) {
      final target = widget.nodes
          .where((node) => node.id == _hoveredTargetNodeId)
          .cast<MindMapNode>()
          .firstOrNull;

      if (target != null) {
        return _portPosition(target, _hoveredTargetPort!, canvasSize);
      }
    }

    return _connectionCurrent;
  }

  // ============================================================
  // MOSTRAR HANDLES
  // ============================================================

  bool _shouldShowHandles(String nodeId) {
    if (_connectingFromNodeId != null) {
      return nodeId == _connectingFromNodeId || nodeId == _hoveredTargetNodeId;
    }

    return nodeId == _hoveredNodeId || nodeId == widget.selectedNodeId;
  }
}

// ============================================================
// TARGET DE PORTA
// ============================================================

class _PortTarget {
  final MindMapNode node;

  final _MindMapPort port;

  final Offset position;

  const _PortTarget({
    required this.node,
    required this.port,
    required this.position,
  });
}

// ============================================================
// EXTENSÃO SEGURA
// ============================================================

extension _IterableFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;

    if (!iterator.moveNext()) {
      return null;
    }

    return iterator.current;
  }
}

// ============================================================
// NÓ + HANDLES
// ============================================================

class _MindMapNodeWithHandles extends StatelessWidget {
  final MindMapNode node;

  final double width;

  final double height;

  final bool isSelected;

  final bool isHovered;

  final bool isConnectionSource;

  final _MindMapPort? hoveredTargetPort;

  final Color activeColor;

  final bool showHandles;

  final ValueChanged<bool> onHoverChanged;

  final VoidCallback onTap;

  final ValueChanged<Offset> onMove;

  final VoidCallback onRemove;

  final VoidCallback onAddToTimeline;

  final void Function(_MindMapPort port, DragStartDetails details)
  onConnectionStart;

  final ValueChanged<DragUpdateDetails> onConnectionUpdate;

  final VoidCallback onConnectionEnd;

  const _MindMapNodeWithHandles({
    required this.node,
    required this.width,
    required this.height,
    required this.isSelected,
    required this.isHovered,
    required this.isConnectionSource,
    required this.hoveredTargetPort,
    required this.activeColor,
    required this.showHandles,
    required this.onHoverChanged,
    required this.onTap,
    required this.onMove,
    required this.onRemove,
    required this.onAddToTimeline,
    required this.onConnectionStart,
    required this.onConnectionUpdate,
    required this.onConnectionEnd,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        onHoverChanged(true);
      },
      onExit: (_) {
        onHoverChanged(false);
      },
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: _MindMapNodeCard(
                node: node,
                isSelected: isSelected,
                activeColor: activeColor,
                onTap: onTap,
                onMove: onMove,
                onRemove: onRemove,
                onAddToTimeline: onAddToTimeline,
              ),
            ),

            // ==================================================
            // HANDLES
            // ==================================================
            if (showHandles) ...[
              _ConnectionHandle(
                port: _MindMapPort.top,
                activeColor: activeColor,
                highlighted:
                    hoveredTargetPort == _MindMapPort.top ||
                    (isConnectionSource ? true : false),
                onPanStart: (details) {
                  onConnectionStart(_MindMapPort.top, details);
                },
                onPanUpdate: onConnectionUpdate,
                onPanEnd: (_) {
                  onConnectionEnd();
                },
              ),

              _ConnectionHandle(
                port: _MindMapPort.right,
                activeColor: activeColor,
                highlighted:
                    hoveredTargetPort == _MindMapPort.right ||
                    isConnectionSource,
                onPanStart: (details) {
                  onConnectionStart(_MindMapPort.right, details);
                },
                onPanUpdate: onConnectionUpdate,
                onPanEnd: (_) {
                  onConnectionEnd();
                },
              ),

              _ConnectionHandle(
                port: _MindMapPort.bottom,
                activeColor: activeColor,
                highlighted:
                    hoveredTargetPort == _MindMapPort.bottom ||
                    isConnectionSource,
                onPanStart: (details) {
                  onConnectionStart(_MindMapPort.bottom, details);
                },
                onPanUpdate: onConnectionUpdate,
                onPanEnd: (_) {
                  onConnectionEnd();
                },
              ),

              _ConnectionHandle(
                port: _MindMapPort.left,
                activeColor: activeColor,
                highlighted:
                    hoveredTargetPort == _MindMapPort.left ||
                    isConnectionSource,
                onPanStart: (details) {
                  onConnectionStart(_MindMapPort.left, details);
                },
                onPanUpdate: onConnectionUpdate,
                onPanEnd: (_) {
                  onConnectionEnd();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================
// HANDLE DE CONEXÃO
// ============================================================

class _ConnectionHandle extends StatelessWidget {
  static const double size = 12;

  final _MindMapPort port;

  final Color activeColor;

  final bool highlighted;

  final GestureDragStartCallback onPanStart;

  final GestureDragUpdateCallback onPanUpdate;

  final GestureDragEndCallback onPanEnd;

  const _ConnectionHandle({
    required this.port,
    required this.activeColor,
    required this.highlighted,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _left,
      top: _top,
      right: _right,
      bottom: _bottom,
      child: MouseRegion(
        cursor: SystemMouseCursors.precise,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: onPanStart,
          onPanUpdate: onPanUpdate,
          onPanEnd: onPanEnd,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: highlighted ? activeColor : const Color(0xFF111111),
              shape: BoxShape.circle,
              border: Border.all(
                color: activeColor,
                width: highlighted ? 2 : 1.4,
              ),
              boxShadow: highlighted
                  ? [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.35),
                        blurRadius: 8,
                      ),
                    ]
                  : const [],
            ),
          ),
        ),
      ),
    );
  }

  double? get _left {
    switch (port) {
      case _MindMapPort.top:
      case _MindMapPort.bottom:
        return 70 - size / 2;

      case _MindMapPort.left:
        return -size / 2;

      case _MindMapPort.right:
        return null;
    }
  }

  double? get _right {
    switch (port) {
      case _MindMapPort.right:
        return -size / 2;

      default:
        return null;
    }
  }

  double? get _top {
    switch (port) {
      case _MindMapPort.top:
        return -size / 2;

      case _MindMapPort.left:
      case _MindMapPort.right:
        return 38 - size / 2;

      case _MindMapPort.bottom:
        return null;
    }
  }

  double? get _bottom {
    switch (port) {
      case _MindMapPort.bottom:
        return -size / 2;

      default:
        return null;
    }
  }
}

// ============================================================
// ESTADO VAZIO
// ============================================================

class _EmptyMindMap extends StatelessWidget {
  final Color activeColor;

  final VoidCallback onAddNode;

  const _EmptyMindMap({required this.activeColor, required this.onAddNode});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_tree_outlined,
              color: activeColor.withValues(alpha: 0.55),
              size: 34,
            ),

            const SizedBox(height: 14),

            const Text(
              'Seu mapa ainda está vazio',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Selecione palavras da letra ou adicione uma ideia para começar a enxergar a música.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white38,
                fontSize: 11,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 16),

            TextButton.icon(
              onPressed: onAddNode,
              icon: Icon(Icons.add_rounded, color: activeColor, size: 18),
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

class _MindMapNodeCard extends StatelessWidget {
  final MindMapNode node;

  final bool isSelected;

  final Color activeColor;

  final VoidCallback onTap;

  final ValueChanged<Offset> onMove;

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
  Widget build(BuildContext context) {
    final nodeColor = _resolveNodeColor();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onPanUpdate: (details) {
        onMove(details.delta);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected
              ? nodeColor.withValues(alpha: 0.16)
              : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? nodeColor.withValues(alpha: 0.65)
                : nodeColor.withValues(alpha: 0.20),
            width: isSelected ? 1.4 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: nodeColor.withValues(alpha: 0.16),
                    blurRadius: 12,
                  ),
                ]
              : const [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _resolveNodeIcon(),
                  size: 12,
                  color: nodeColor.withValues(alpha: 0.7),
                ),

                const SizedBox(width: 4),

                Flexible(
                  child: Text(
                    _resolveNodeLabel(),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: nodeColor.withValues(alpha: 0.7),
                      fontSize: 8,
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 5),

            Flexible(
              child: Text(
                node.text,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            if (isSelected) ...[
              const SizedBox(height: 5),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _NodeActionButton(
                    icon: Icons.timeline_rounded,
                    tooltip: 'Levar para Timeline',
                    color: nodeColor,
                    onTap: onAddToTimeline,
                  ),

                  const SizedBox(width: 4),

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

class _NodeActionButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 13, color: color.withValues(alpha: 0.8)),
        ),
      ),
    );
  }
}

// ============================================================
// PAINTER DAS CONEXÕES
// ============================================================

class _MindMapConnectionsPainter extends CustomPainter {
  final List<MindMapNode> nodes;

  final Color activeColor;

  final double nodeWidth;

  final double nodeHeight;

  final Offset? previewStart;

  final Offset? previewCurrent;

  const _MindMapConnectionsPainter({
    required this.nodes,
    required this.activeColor,
    required this.nodeWidth,
    required this.nodeHeight,
    this.previewStart,
    this.previewCurrent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final nodeMap = {for (final node in nodes) node.id: node};

    final drawnConnections = <String>{};

    final paint = Paint()
      ..color = activeColor.withValues(alpha: 0.24)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final node in nodes) {
      for (final connectionId in node.connections) {
        final target = nodeMap[connectionId];

        if (target == null) {
          continue;
        }

        final ids = [node.id, target.id]..sort();

        final connectionKey = '${ids[0]}-${ids[1]}';

        if (drawnConnections.contains(connectionKey)) {
          continue;
        }

        drawnConnections.add(connectionKey);

        final start = _bestAnchor(from: node, to: target);

        final end = _bestAnchor(from: target, to: node);

        _drawCurve(canvas: canvas, start: start, end: end, paint: paint);
      }
    }

    // ==========================================================
    // PREVIEW
    // ==========================================================

    if (previewStart != null && previewCurrent != null) {
      final previewPaint = Paint()
        ..color = activeColor.withValues(alpha: 0.75)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      _drawCurve(
        canvas: canvas,
        start: previewStart!,
        end: previewCurrent!,
        paint: previewPaint,
      );

      canvas.drawCircle(previewCurrent!, 4, Paint()..color = activeColor);
    }
  }

  // ============================================================
  // MELHOR ARESTA ENTRE NÓS
  // ============================================================

  Offset _bestAnchor({required MindMapNode from, required MindMapNode to}) {
    final fromCenter = Offset(from.x + nodeWidth / 2, from.y + nodeHeight / 2);

    final toCenter = Offset(to.x + nodeWidth / 2, to.y + nodeHeight / 2);

    final dx = toCenter.dx - fromCenter.dx;

    final dy = toCenter.dy - fromCenter.dy;

    if (dx.abs() >= dy.abs()) {
      if (dx >= 0) {
        return Offset(from.x + nodeWidth, from.y + nodeHeight / 2);
      }

      return Offset(from.x, from.y + nodeHeight / 2);
    }

    if (dy >= 0) {
      return Offset(from.x + nodeWidth / 2, from.y + nodeHeight);
    }

    return Offset(from.x + nodeWidth / 2, from.y);
  }

  // ============================================================
  // CURVA
  // ============================================================

  void _drawCurve({
    required Canvas canvas,
    required Offset start,
    required Offset end,
    required Paint paint,
  }) {
    final path = Path();

    path.moveTo(start.dx, start.dy);

    final dx = end.dx - start.dx;

    final dy = end.dy - start.dy;

    if (dx.abs() >= dy.abs()) {
      final curve = math.max(40.0, dx.abs() * 0.35);

      path.cubicTo(
        start.dx + (dx >= 0 ? curve : -curve),
        start.dy,
        end.dx - (dx >= 0 ? curve : -curve),
        end.dy,
        end.dx,
        end.dy,
      );
    } else {
      final curve = math.max(40.0, dy.abs() * 0.35);

      path.cubicTo(
        start.dx,
        start.dy + (dy >= 0 ? curve : -curve),
        end.dx,
        end.dy - (dy >= 0 ? curve : -curve),
        end.dx,
        end.dy,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MindMapConnectionsPainter oldDelegate) {
    return oldDelegate.nodes != nodes ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.previewStart != previewStart ||
        oldDelegate.previewCurrent != previewCurrent;
  }
}
