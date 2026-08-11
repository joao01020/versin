import 'dart:convert';
import 'dart:math' as math;

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';

// ============================================================
// JANELA EXTERNA DO MAPA MENTAL
// ============================================================
//
// IMPORTANTE:
//
// Esta janela roda em outro Flutter Engine.
// Portanto ela NÃO acessa diretamente:
//
// GetIt.I<StudioController>()
//
// O estado principal continua pertencendo ao StudioController
// da janela principal.
//
// A comunicação acontece pelo WindowMethodChannel:
//
// Janela principal
//      ↕
// mind_map_window.dart
//
// ============================================================

class MindMapWindow extends StatefulWidget {
  final String arguments;

  const MindMapWindow({super.key, required this.arguments});

  @override
  State<MindMapWindow> createState() => _MindMapWindowState();
}

class _MindMapWindowState extends State<MindMapWindow> {
  // ============================================================
  // CANAL
  // ============================================================

  static const WindowMethodChannel _channel = WindowMethodChannel(
    'versin_studio_mind_map',
    mode: ChannelMode.bidirectional,
  );

  // ============================================================
  // CONSTANTES VISUAIS
  // ============================================================

  static const Color _activeColor = Color(0xFFE100FF);

  static const double _nodeWidth = 140;

  static const double _nodeHeight = 76;

  static const double _connectionSnapDistance = 26;

  // ============================================================
  // PROJETO
  // ============================================================

  String _projectId = '';

  // ============================================================
  // NÓS LOCAIS
  // ============================================================
  //
  // São apenas uma representação visual temporária.
  //
  // O StudioController da janela principal continua sendo
  // a fonte oficial dos dados.
  //
  // ============================================================

  final List<_WindowMindMapNode> _nodes = [];

  // ============================================================
  // ESTADO
  // ============================================================

  String? _selectedNodeId;

  String? _hoveredNodeId;

  bool _isReady = false;

  // ============================================================
  // CONEXÃO EM ANDAMENTO
  // ============================================================

  String? _connectingFromNodeId;

  _WindowMindMapPort? _connectingFromPort;

  Offset? _connectionStart;

  Offset? _connectionCurrent;

  String? _hoveredTargetNodeId;

  _WindowMindMapPort? _hoveredTargetPort;

  // ============================================================
  // CANVAS
  // ============================================================

  final GlobalKey _canvasKey = GlobalKey();

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadArguments(widget.arguments);

    _configureChannel();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isReady = true;
      });

      _requestLatestMap();
    });
  }

  // ============================================================
  // ARGUMENTOS INICIAIS
  // ============================================================

  void _loadArguments(String raw) {
    final data = _parseArguments(raw);

    _projectId = data['project_id']?.toString() ?? '';

    final rawNodes = data['nodes'];

    if (rawNodes is List) {
      _replaceNodes(rawNodes, notify: false);
    }
  }

  // ============================================================
  // CONFIGURAR CANAL
  // ============================================================

  Future<void> _configureChannel() async {
    try {
      await _channel.setMethodCallHandler((call) async {
        switch (call.method) {
          // ==================================================
          // SUBSTITUIR MAPA COMPLETO
          // ==================================================

          case 'setMindMap':
            final arguments = call.arguments;

            if (arguments is Map) {
              final data = Map<String, dynamic>.from(arguments);

              _projectId = data['project_id']?.toString() ?? _projectId;

              final rawNodes = data['nodes'];

              if (rawNodes is List) {
                _replaceNodes(rawNodes);
              }
            }

            return true;

          // ==================================================
          // ATUALIZAR SOMENTE NÓS
          // ==================================================

          case 'setNodes':
            final arguments = call.arguments;

            if (arguments is List) {
              _replaceNodes(arguments);
            }

            return true;

          // ==================================================
          // SELEÇÃO VINDO DO STUDIO
          // ==================================================

          case 'selectNode':
            final nodeId = call.arguments?.toString();

            if (!mounted) {
              return false;
            }

            setState(() {
              _selectedNodeId = nodeId;
            });

            return true;

          // ==================================================
          // FOCO
          // ==================================================

          case 'focusMap':
            return true;

          default:
            return null;
        }
      });
    } catch (e) {
      debugPrint('[MIND MAP WINDOW] Erro ao configurar canal: $e');
    }
  }

  // ============================================================
  // PEDIR MAPA MAIS RECENTE
  // ============================================================

  Future<void> _requestLatestMap() async {
    try {
      await _channel.invokeMethod('requestMindMap', {'project_id': _projectId});
    } catch (e) {
      debugPrint('[MIND MAP WINDOW] Não foi possível solicitar o mapa: $e');
    }
  }

  // ============================================================
  // SUBSTITUIR NÓS LOCAIS
  // ============================================================

  void _replaceNodes(List<dynamic> rawNodes, {bool notify = true}) {
    final parsed = <_WindowMindMapNode>[];

    for (final raw in rawNodes) {
      if (raw is! Map) {
        continue;
      }

      try {
        parsed.add(_WindowMindMapNode.fromMap(Map<String, dynamic>.from(raw)));
      } catch (e) {
        debugPrint('[MIND MAP WINDOW] Nó inválido ignorado: $e');
      }
    }

    _nodes
      ..clear()
      ..addAll(parsed);

    if (_selectedNodeId != null &&
        !_nodes.any((node) => node.id == _selectedNodeId)) {
      _selectedNodeId = null;
    }

    if (notify && mounted) {
      setState(() {});
    }
  }

  // ============================================================
  // MAP → JSON
  // ============================================================

  Map<String, dynamic> _parseArguments(String raw) {
    if (raw.trim().isEmpty) {
      return {};
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }

      return {};
    } catch (e) {
      debugPrint('[MIND MAP WINDOW] Argumentos inválidos: $e');

      return {};
    }
  }

  // ============================================================
  // GLOBAL → CANVAS
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
  // SELECIONAR NÓ
  // ============================================================

  void _selectNode(String? nodeId) {
    if (_selectedNodeId == nodeId) {
      return;
    }

    setState(() {
      _selectedNodeId = nodeId;
    });

    _sendToMain('selectMindMapNode', {
      'project_id': _projectId,
      'node_id': nodeId,
    });
  }

  // ============================================================
  // MOVER NÓ
  // ============================================================

  void _moveNode(_WindowMindMapNode node, Offset delta, Size canvasSize) {
    final newX = _safeX(node.x + delta.dx, canvasSize.width);

    final newY = _safeY(node.y + delta.dy, canvasSize.height);

    setState(() {
      node.x = newX;

      node.y = newY;
    });

    _sendToMain('setMindMapNodePosition', {
      'project_id': _projectId,
      'node_id': node.id,
      'x': newX,
      'y': newY,
    });
  }

  // ============================================================
  // REMOVER NÓ
  // ============================================================

  Future<void> _removeNode(_WindowMindMapNode node) async {
    setState(() {
      _nodes.removeWhere((item) => item.id == node.id);

      for (final other in _nodes) {
        other.connections.remove(node.id);
      }

      if (_selectedNodeId == node.id) {
        _selectedNodeId = null;
      }
    });

    await _sendToMain('removeMindMapNode', {
      'project_id': _projectId,
      'node_id': node.id,
    });
  }

  // ============================================================
  // ENVIAR NÓ PARA TIMELINE
  // ============================================================

  Future<void> _addNodeToTimeline(_WindowMindMapNode node) async {
    await _sendToMain('addMindMapNodeToTimeline', {
      'project_id': _projectId,
      'node_id': node.id,
      'text': node.text,
    });
  }

  // ============================================================
  // POSIÇÃO DA PORTA
  // ============================================================

  Offset _portPosition(
    _WindowMindMapNode node,
    _WindowMindMapPort port,
    Size canvasSize,
  ) {
    final x = _safeX(node.x, canvasSize.width);

    final y = _safeY(node.y, canvasSize.height);

    switch (port) {
      case _WindowMindMapPort.top:
        return Offset(x + _nodeWidth / 2, y);

      case _WindowMindMapPort.right:
        return Offset(x + _nodeWidth, y + _nodeHeight / 2);

      case _WindowMindMapPort.bottom:
        return Offset(x + _nodeWidth / 2, y + _nodeHeight);

      case _WindowMindMapPort.left:
        return Offset(x, y + _nodeHeight / 2);
    }
  }

  // ============================================================
  // INICIAR CONEXÃO
  // ============================================================

  void _startConnection({
    required _WindowMindMapNode node,
    required _WindowMindMapPort port,
    required DragStartDetails details,
    required Size canvasSize,
  }) {
    setState(() {
      _connectingFromNodeId = node.id;

      _connectingFromPort = port;

      _connectionStart = _portPosition(node, port, canvasSize);

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
    final pointer = _globalToCanvas(details.globalPosition);

    final target = _findNearestTarget(pointer, canvasSize);

    setState(() {
      _connectionCurrent = pointer;

      _hoveredTargetNodeId = target?.node.id;

      _hoveredTargetPort = target?.port;
    });
  }

  // ============================================================
  // FINALIZAR CONEXÃO
  // ============================================================

  Future<void> _finishConnection() async {
    final fromId = _connectingFromNodeId;

    final targetId = _hoveredTargetNodeId;

    if (fromId != null && targetId != null && fromId != targetId) {
      final from = _findNode(fromId);

      final target = _findNode(targetId);

      if (from != null && target != null) {
        setState(() {
          if (!from.connections.contains(target.id)) {
            from.connections.add(target.id);
          }

          if (!target.connections.contains(from.id)) {
            target.connections.add(from.id);
          }
        });

        await _sendToMain('connectMindMapNodes', {
          'project_id': _projectId,
          'first_node_id': fromId,
          'second_node_id': targetId,
        });
      }
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
  // TARGET MAIS PRÓXIMO
  // ============================================================

  _WindowPortTarget? _findNearestTarget(Offset pointer, Size canvasSize) {
    _WindowPortTarget? nearest;

    double nearestDistance = double.infinity;

    for (final node in _nodes) {
      if (node.id == _connectingFromNodeId) {
        continue;
      }

      for (final port in _WindowMindMapPort.values) {
        final position = _portPosition(node, port, canvasSize);

        final distance = (pointer - position).distance;

        if (distance <= _connectionSnapDistance && distance < nearestDistance) {
          nearestDistance = distance;

          nearest = _WindowPortTarget(
            node: node,
            port: port,
            position: position,
          );
        }
      }
    }

    return nearest;
  }

  // ============================================================
  // PREVIEW END
  // ============================================================

  Offset? _previewEnd(Size canvasSize) {
    final targetId = _hoveredTargetNodeId;

    final targetPort = _hoveredTargetPort;

    if (targetId != null && targetPort != null) {
      final target = _findNode(targetId);

      if (target != null) {
        return _portPosition(target, targetPort, canvasSize);
      }
    }

    return _connectionCurrent;
  }

  // ============================================================
  // FIND NODE
  // ============================================================

  _WindowMindMapNode? _findNode(String id) {
    for (final node in _nodes) {
      if (node.id == id) {
        return node;
      }
    }

    return null;
  }

  // ============================================================
  // HANDLES VISÍVEIS
  // ============================================================

  bool _showHandles(String nodeId) {
    if (_connectingFromNodeId != null) {
      return nodeId == _connectingFromNodeId || nodeId == _hoveredTargetNodeId;
    }

    return nodeId == _hoveredNodeId || nodeId == _selectedNodeId;
  }

  // ============================================================
  // ENCAIXAR
  // ============================================================

  Future<void> _dockWindow() async {
    try {
      await _sendToMain('dockMindMap', {
        'project_id': _projectId,
        'nodes': _nodes.map((node) => node.toMap()).toList(),
      });
    } catch (e) {
      debugPrint('[MIND MAP WINDOW] Erro ao encaixar: $e');
    }
  }

  // ============================================================
  // ENVIAR PARA PRINCIPAL
  // ============================================================

  Future<void> _sendToMain(String method, dynamic arguments) async {
    try {
      await _channel.invokeMethod(method, arguments);
    } catch (e) {
      debugPrint('[MIND MAP WINDOW] $method falhou: $e');
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(
        backgroundColor: const Color(0xFF0D0D0D),
        body: SafeArea(
          child: Column(
            children: [
              // =================================================
              // HEADER
              // =================================================
              _buildHeader(),

              // =================================================
              // MAPA
              // =================================================
              Expanded(
                child: _isReady
                    ? _buildMap()
                    : const Center(
                        child: CircularProgressIndicator(color: _activeColor),
                      ),
              ),

              // =================================================
              // STATUS
              // =================================================
              _buildStatusBar(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.account_tree_outlined,
            size: 18,
            color: _activeColor,
          ),

          const SizedBox(width: 8),

          const Text(
            'MAPA',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),

          if (_connectingFromNodeId != null) ...[
            const SizedBox(width: 14),

            const Text(
              'Conectando...',
              style: TextStyle(color: Colors.white38, fontSize: 10),
            ),

            IconButton(
              tooltip: 'Cancelar conexão',
              onPressed: _cancelConnection,
              icon: const Icon(
                Icons.close_rounded,
                color: Colors.white38,
                size: 17,
              ),
            ),
          ],

          const Spacer(),

          if (_projectId.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Text(
                _projectId,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white24, fontSize: 9),
              ),
            ),

          Tooltip(
            message: 'Atualizar mapa',
            child: IconButton(
              onPressed: _requestLatestMap,
              icon: const Icon(
                Icons.refresh_rounded,
                color: Colors.white38,
                size: 18,
              ),
            ),
          ),

          Tooltip(
            message: 'Encaixar no Studio',
            child: IconButton(
              onPressed: _dockWindow,
              icon: const Icon(
                Icons.call_merge_rounded,
                color: _activeColor,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MAPA
  // ============================================================

  Widget _buildMap() {
    if (_nodes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_tree_outlined, size: 36, color: Colors.white24),

            SizedBox(height: 12),

            Text(
              'Nenhum nó no mapa.',
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
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

                _selectNode(null);
              },
              child: ClipRect(
                child: Stack(
                  key: _canvasKey,
                  clipBehavior: Clip.none,
                  children: [
                    // =========================================
                    // CONEXÕES
                    // =========================================
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _WindowConnectionsPainter(
                            nodes: _nodes,
                            activeColor: _activeColor,
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
                    for (final node in _nodes)
                      Positioned(
                        left: _safeX(node.x, constraints.maxWidth),
                        top: _safeY(node.y, constraints.maxHeight),
                        child: _WindowNodeWithHandles(
                          node: node,
                          width: _nodeWidth,
                          height: _nodeHeight,
                          activeColor: _activeColor,
                          selected: node.id == _selectedNodeId,
                          showHandles: _showHandles(node.id),
                          isConnectionSource: node.id == _connectingFromNodeId,
                          highlightedTargetPort: node.id == _hoveredTargetNodeId
                              ? _hoveredTargetPort
                              : null,
                          onHoverChanged: (hovered) {
                            if (_connectingFromNodeId != null) {
                              return;
                            }

                            setState(() {
                              _hoveredNodeId = hovered ? node.id : null;
                            });
                          },
                          onTap: () {
                            _selectNode(node.id);
                          },
                          onMove: (delta) {
                            if (_connectingFromNodeId != null) {
                              return;
                            }

                            _moveNode(node, delta, canvasSize);
                          },
                          onRemove: () {
                            _removeNode(node);
                          },
                          onAddToTimeline: () {
                            _addNodeToTimeline(node);
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
    );
  }

  // ============================================================
  // STATUS
  // ============================================================

  Widget _buildStatusBar() {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF00FF66),
              shape: BoxShape.circle,
            ),
          ),

          const SizedBox(width: 6),

          const Text(
            'MAPA EXTERNO',
            style: TextStyle(
              color: Colors.white30,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),

          const Spacer(),

          Text(
            '${_nodes.length} nó${_nodes.length == 1 ? '' : 's'}',
            style: const TextStyle(color: Colors.white24, fontSize: 9),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PORTAS
// ============================================================

enum _WindowMindMapPort { top, right, bottom, left }

// ============================================================
// NÓ LOCAL
// ============================================================

class _WindowMindMapNode {
  final String id;

  String text;

  String type;

  double x;

  double y;

  final List<String> connections;

  _WindowMindMapNode({
    required this.id,
    required this.text,
    required this.type,
    required this.x,
    required this.y,
    required this.connections,
  });

  factory _WindowMindMapNode.fromMap(Map<String, dynamic> map) {
    final rawConnections = map['connections'];

    return _WindowMindMapNode(
      id: map['id']?.toString() ?? '',
      text: map['text']?.toString() ?? '',
      type: (map['type'] ?? 'idea').toString(),
      x: _asDouble(map['x']),
      y: _asDouble(map['y']),
      connections: rawConnections is List
          ? rawConnections
                .map((value) => value.toString())
                .where((value) => value.isNotEmpty)
                .toList()
          : <String>[],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'type': type,
      'x': x,
      'y': y,
      'connections': List<String>.from(connections),
    };
  }

  static double _asDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

// ============================================================
// TARGET
// ============================================================

class _WindowPortTarget {
  final _WindowMindMapNode node;

  final _WindowMindMapPort port;

  final Offset position;

  const _WindowPortTarget({
    required this.node,
    required this.port,
    required this.position,
  });
}

// ============================================================
// NÓ + HANDLES
// ============================================================

class _WindowNodeWithHandles extends StatelessWidget {
  final _WindowMindMapNode node;

  final double width;

  final double height;

  final Color activeColor;

  final bool selected;

  final bool showHandles;

  final bool isConnectionSource;

  final _WindowMindMapPort? highlightedTargetPort;

  final ValueChanged<bool> onHoverChanged;

  final VoidCallback onTap;

  final ValueChanged<Offset> onMove;

  final VoidCallback onRemove;

  final VoidCallback onAddToTimeline;

  final void Function(_WindowMindMapPort port, DragStartDetails details)
  onConnectionStart;

  final ValueChanged<DragUpdateDetails> onConnectionUpdate;

  final VoidCallback onConnectionEnd;

  const _WindowNodeWithHandles({
    required this.node,
    required this.width,
    required this.height,
    required this.activeColor,
    required this.selected,
    required this.showHandles,
    required this.isConnectionSource,
    required this.highlightedTargetPort,
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
              child: _WindowNodeCard(
                node: node,
                activeColor: activeColor,
                selected: selected,
                onTap: onTap,
                onMove: onMove,
                onRemove: onRemove,
                onAddToTimeline: onAddToTimeline,
              ),
            ),

            if (showHandles)
              for (final port in _WindowMindMapPort.values)
                _WindowConnectionHandle(
                  port: port,
                  activeColor: activeColor,
                  highlighted:
                      isConnectionSource || highlightedTargetPort == port,
                  onPanStart: (details) {
                    onConnectionStart(port, details);
                  },
                  onPanUpdate: onConnectionUpdate,
                  onPanEnd: (_) {
                    onConnectionEnd();
                  },
                ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// HANDLE
// ============================================================

class _WindowConnectionHandle extends StatelessWidget {
  static const double size = 12;

  final _WindowMindMapPort port;

  final Color activeColor;

  final bool highlighted;

  final GestureDragStartCallback onPanStart;

  final GestureDragUpdateCallback onPanUpdate;

  final GestureDragEndCallback onPanEnd;

  const _WindowConnectionHandle({
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
      right: _right,
      top: _top,
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
      case _WindowMindMapPort.top:
      case _WindowMindMapPort.bottom:
        return 70 - size / 2;

      case _WindowMindMapPort.left:
        return -size / 2;

      case _WindowMindMapPort.right:
        return null;
    }
  }

  double? get _right {
    switch (port) {
      case _WindowMindMapPort.right:
        return -size / 2;

      default:
        return null;
    }
  }

  double? get _top {
    switch (port) {
      case _WindowMindMapPort.top:
        return -size / 2;

      case _WindowMindMapPort.left:
      case _WindowMindMapPort.right:
        return 38 - size / 2;

      case _WindowMindMapPort.bottom:
        return null;
    }
  }

  double? get _bottom {
    switch (port) {
      case _WindowMindMapPort.bottom:
        return -size / 2;

      default:
        return null;
    }
  }
}

// ============================================================
// CARD DO NÓ
// ============================================================

class _WindowNodeCard extends StatelessWidget {
  final _WindowMindMapNode node;

  final Color activeColor;

  final bool selected;

  final VoidCallback onTap;

  final ValueChanged<Offset> onMove;

  final VoidCallback onRemove;

  final VoidCallback onAddToTimeline;

  const _WindowNodeCard({
    required this.node,
    required this.activeColor,
    required this.selected,
    required this.onTap,
    required this.onMove,
    required this.onRemove,
    required this.onAddToTimeline,
  });

  @override
  Widget build(BuildContext context) {
    final nodeColor = _nodeColor(node.type, activeColor);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onPanUpdate: (details) {
        onMove(details.delta);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? nodeColor.withValues(alpha: 0.16)
              : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? nodeColor.withValues(alpha: 0.65)
                : nodeColor.withValues(alpha: 0.20),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _nodeTypeLabel(node.type),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: nodeColor.withValues(alpha: 0.72),
                fontSize: 8,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),

            const SizedBox(height: 4),

            Flexible(
              child: Text(
                node.text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            if (selected) ...[
              const SizedBox(height: 4),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _SmallNodeAction(
                    icon: Icons.timeline_rounded,
                    tooltip: 'Enviar para Timeline',
                    color: nodeColor,
                    onTap: onAddToTimeline,
                  ),

                  const SizedBox(width: 5),

                  _SmallNodeAction(
                    icon: Icons.delete_outline_rounded,
                    tooltip: 'Remover nó',
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
}

// ============================================================
// AÇÃO PEQUENA
// ============================================================

class _SmallNodeAction extends StatelessWidget {
  final IconData icon;

  final String tooltip;

  final Color color;

  final VoidCallback onTap;

  const _SmallNodeAction({
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
        borderRadius: BorderRadius.circular(7),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 13, color: color.withValues(alpha: 0.85)),
        ),
      ),
    );
  }
}

// ============================================================
// CONEXÕES
// ============================================================

class _WindowConnectionsPainter extends CustomPainter {
  final List<_WindowMindMapNode> nodes;

  final Color activeColor;

  final double nodeWidth;

  final double nodeHeight;

  final Offset? previewStart;

  final Offset? previewCurrent;

  const _WindowConnectionsPainter({
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

    final drawn = <String>{};

    final linePaint = Paint()
      ..color = activeColor.withValues(alpha: 0.24)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final node in nodes) {
      for (final targetId in node.connections) {
        final target = nodeMap[targetId];

        if (target == null) {
          continue;
        }

        final ids = [node.id, target.id]..sort();

        final key = '${ids[0]}-${ids[1]}';

        if (!drawn.add(key)) {
          continue;
        }

        final start = _bestAnchor(from: node, to: target);

        final end = _bestAnchor(from: target, to: node);

        _drawCurve(canvas, start, end, linePaint);
      }
    }

    if (previewStart != null && previewCurrent != null) {
      final previewPaint = Paint()
        ..color = activeColor.withValues(alpha: 0.78)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      _drawCurve(canvas, previewStart!, previewCurrent!, previewPaint);

      canvas.drawCircle(previewCurrent!, 4, Paint()..color = activeColor);
    }
  }

  Offset _bestAnchor({
    required _WindowMindMapNode from,
    required _WindowMindMapNode to,
  }) {
    final fromCenter = Offset(from.x + nodeWidth / 2, from.y + nodeHeight / 2);

    final toCenter = Offset(to.x + nodeWidth / 2, to.y + nodeHeight / 2);

    final dx = toCenter.dx - fromCenter.dx;

    final dy = toCenter.dy - fromCenter.dy;

    if (dx.abs() >= dy.abs()) {
      return dx >= 0
          ? Offset(from.x + nodeWidth, from.y + nodeHeight / 2)
          : Offset(from.x, from.y + nodeHeight / 2);
    }

    return dy >= 0
        ? Offset(from.x + nodeWidth / 2, from.y + nodeHeight)
        : Offset(from.x + nodeWidth / 2, from.y);
  }

  void _drawCurve(Canvas canvas, Offset start, Offset end, Paint paint) {
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
  bool shouldRepaint(covariant _WindowConnectionsPainter oldDelegate) {
    return oldDelegate.nodes != nodes ||
        oldDelegate.previewStart != previewStart ||
        oldDelegate.previewCurrent != previewCurrent ||
        oldDelegate.activeColor != activeColor;
  }
}

// ============================================================
// TIPO → COR
// ============================================================

Color _nodeColor(String type, Color activeColor) {
  switch (type.toLowerCase()) {
    case 'scene':
      return Colors.blueAccent;

    case 'emotion':
      return Colors.pinkAccent;

    case 'image':
      return Colors.cyanAccent;

    case 'rhyme':
      return Colors.greenAccent;

    case 'concept':
      return Colors.orangeAccent;

    case 'idea':
    default:
      return activeColor;
  }
}

// ============================================================
// TIPO → LABEL
// ============================================================

String _nodeTypeLabel(String type) {
  switch (type.toLowerCase()) {
    case 'scene':
      return 'CENA';

    case 'emotion':
      return 'EMOÇÃO';

    case 'image':
      return 'IMAGEM';

    case 'rhyme':
      return 'RIMA';

    case 'concept':
      return 'CONCEITO';

    case 'idea':
    default:
      return 'IDEIA';
  }
}
