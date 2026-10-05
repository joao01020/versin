import 'package:flutter/material.dart';

import 'package:versin/modules/studio/models/mind_map_node.dart';
import 'package:versin/modules/studio/models/song_project.dart';

// ============================================================
// STUDIO MIND MAP CONTROLLER
// ============================================================
//
// Responsável exclusivamente pelo mapa mental:
//
// - nós;
// - seleção;
// - posição;
// - texto;
// - tipo;
// - conexões;
// - visibilidade;
// - limpeza.
//
// Não conhece Timeline nem widgets.
//
// ============================================================

class StudioMindMapController
    extends
        ChangeNotifier {
  // ============================================================
  // DEPENDÊNCIAS
  // ============================================================

  final SongProject Function() _projectProvider;

  final VoidCallback _markChanged;

  // ============================================================
  // SELEÇÃO
  // ============================================================

  String? _selectedNodeId;

  // ============================================================
  // VISIBILIDADE
  // ============================================================

  bool _isMapVisible = true;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  StudioMindMapController({
    required SongProject Function() projectProvider,
    required VoidCallback markChanged,
  }) : _projectProvider = projectProvider,
       _markChanged = markChanged;

  // ============================================================
  // PROJETO
  // ============================================================

  SongProject get _project => _projectProvider();

  // ============================================================
  // GETTERS
  // ============================================================

  String? get selectedNodeId => _selectedNodeId;

  MindMapNode? get selectedNode {
    final id = _selectedNodeId;

    if (id ==
        null) {
      return null;
    }

    return _project.findMindMapNode(
      id,
    );
  }

  bool get isMapVisible => _isMapVisible;

  List<
    MindMapNode
  >
  get mindMapNodes => List.unmodifiable(
    _project.mindMapNodes,
  );

  bool get hasMindMap => _project.mindMapNodes.isNotEmpty;

  // ============================================================
  // ADICIONAR
  // ============================================================

  MindMapNode addMindMapNode({
    required String text,
    MindMapNodeType type = MindMapNodeType.idea,
    Offset position = Offset.zero,
  }) {
    final normalized = text.trim();

    final node = MindMapNode(
      id: _generateNodeId(),
      text: normalized,
      type: type,
      x: position.dx,
      y: position.dy,
    );

    if (normalized.isEmpty) {
      return node;
    }

    _project.addMindMapNode(
      node,
    );

    _selectedNodeId = node.id;

    _markChanged();

    notifyListeners();

    return node;
  }

  // ============================================================
  // REMOVER
  // ============================================================

  bool removeMindMapNode(
    String nodeId,
  ) {
    final removed = _project.removeMindMapNode(
      nodeId,
    );

    if (!removed) {
      return false;
    }

    if (_selectedNodeId ==
        nodeId) {
      _selectedNodeId = null;
    }

    _markChanged();

    notifyListeners();

    return true;
  }

  // ============================================================
  // SELECIONAR
  // ============================================================

  void selectMindMapNode(
    String? nodeId,
  ) {
    if (nodeId ==
        null) {
      _selectedNodeId = null;

      notifyListeners();

      return;
    }

    final node = _project.findMindMapNode(
      nodeId,
    );

    if (node ==
        null) {
      return;
    }

    _selectedNodeId = nodeId;

    notifyListeners();
  }

  // ============================================================
  // LIMPAR SELEÇÃO
  // ============================================================

  void clearMindMapSelection({
    bool notify = true,
  }) {
    if (_selectedNodeId ==
        null) {
      return;
    }

    _selectedNodeId = null;

    if (notify) {
      notifyListeners();
    }
  }

  // ============================================================
  // MOVER
  // ============================================================

  void moveMindMapNode(
    String nodeId,
    Offset delta,
  ) {
    final node = _project.findMindMapNode(
      nodeId,
    );

    if (node ==
        null) {
      return;
    }

    node.move(
      delta,
    );

    _project.touch();

    _markChanged();

    notifyListeners();
  }

  // ============================================================
  // DEFINIR POSIÇÃO
  // ============================================================

  void setMindMapNodePosition(
    String nodeId,
    Offset position,
  ) {
    final node = _project.findMindMapNode(
      nodeId,
    );

    if (node ==
        null) {
      return;
    }

    node.setPosition(
      position,
    );

    _project.touch();

    _markChanged();

    notifyListeners();
  }

  // ============================================================
  // TEXTO
  // ============================================================

  void updateMindMapNodeText(
    String nodeId,
    String text,
  ) {
    final node = _project.findMindMapNode(
      nodeId,
    );

    if (node ==
        null) {
      return;
    }

    final normalized = text.trim();

    if (normalized.isEmpty ||
        normalized ==
            node.text) {
      return;
    }

    node.text = normalized;

    _project.touch();

    _markChanged();

    notifyListeners();
  }

  // ============================================================
  // TIPO
  // ============================================================

  void updateMindMapNodeType(
    String nodeId,
    MindMapNodeType type,
  ) {
    final node = _project.findMindMapNode(
      nodeId,
    );

    if (node ==
            null ||
        node.type ==
            type) {
      return;
    }

    node.type = type;

    _project.touch();

    _markChanged();

    notifyListeners();
  }

  // ============================================================
  // CONECTAR
  // ============================================================

  bool connectMindMapNodes(
    String firstNodeId,
    String secondNodeId,
  ) {
    final connected = _project.connectMindMapNodes(
      firstNodeId,
      secondNodeId,
    );

    if (!connected) {
      return false;
    }

    _markChanged();

    notifyListeners();

    return true;
  }

  // ============================================================
  // DESCONECTAR
  // ============================================================

  bool disconnectMindMapNodes(
    String firstNodeId,
    String secondNodeId,
  ) {
    final disconnected = _project.disconnectMindMapNodes(
      firstNodeId,
      secondNodeId,
    );

    if (!disconnected) {
      return false;
    }

    _markChanged();

    notifyListeners();

    return true;
  }

  // ============================================================
  // CONECTAR SELECIONADO
  // ============================================================

  bool connectSelectedNodeTo(
    String secondNodeId,
  ) {
    final firstNodeId = _selectedNodeId;

    if (firstNodeId ==
        null) {
      return false;
    }

    return connectMindMapNodes(
      firstNodeId,
      secondNodeId,
    );
  }

  // ============================================================
  // LIMPAR MAPA
  // ============================================================

  void clearMindMap() {
    if (_project.mindMapNodes.isEmpty) {
      return;
    }

    _project.clearMindMap();

    _selectedNodeId = null;

    _markChanged();

    notifyListeners();
  }

  // ============================================================
  // VISIBILIDADE
  // ============================================================

  void toggleMapVisibility() {
    _isMapVisible = !_isMapVisible;

    notifyListeners();
  }

  void setMapVisible(
    bool value,
  ) {
    if (_isMapVisible ==
        value) {
      return;
    }

    _isMapVisible = value;

    notifyListeners();
  }

  // ============================================================
  // RESET DE ESTADO LOCAL
  // ============================================================

  void resetLocalState({
    bool notify = false,
  }) {
    _selectedNodeId = null;

    if (notify) {
      notifyListeners();
    }
  }

  // ============================================================
  // GERADOR DE ID
  // ============================================================

  String _generateNodeId() {
    return 'node-'
        '${DateTime.now().microsecondsSinceEpoch}';
  }
}
