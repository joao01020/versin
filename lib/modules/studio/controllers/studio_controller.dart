import 'dart:async';

import 'package:flutter/material.dart';

import 'package:versin/features/rhymes/presentation/controller/rhymes_controller.dart';
import 'package:versin/modules/studio/models/mind_map_node.dart';
import 'package:versin/modules/studio/models/song_project.dart';

class StudioController
    extends
        ChangeNotifier {
  // ============================================================
  // BANCO GLOBAL DE RIMAS
  // ============================================================

  final RhymesController rhymesController;

  // ============================================================
  // PROJETO ATUAL
  // ============================================================

  SongProject _project;

  SongProject get project => _project;

  // ============================================================
  // EDITOR DA LETRA
  // ============================================================

  late final TextEditingController lyricController;

  // ============================================================
  // SELEÇÃO ATUAL
  // ============================================================

  String _selectedText = '';

  String get selectedText => _selectedText;

  bool get hasSelectedText => _selectedText.trim().isNotEmpty;

  // ============================================================
  // MAPA
  // ============================================================

  String? _selectedNodeId;

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

  bool _isMapVisible = true;

  bool get isMapVisible => _isMapVisible;

  // ============================================================
  // PAINÉIS DESTACÁVEIS
  // ============================================================

  bool _isLyricsDetached = false;

  bool _isMindMapDetached = false;

  bool get isLyricsDetached => _isLyricsDetached;

  bool get isMindMapDetached => _isMindMapDetached;

  // ============================================================
  // ALTERAÇÕES
  // ============================================================

  bool _hasUnsavedChanges = false;

  bool get hasUnsavedChanges => _hasUnsavedChanges;

  bool _isDisposed = false;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  StudioController({
    required this.rhymesController,
    SongProject? initialProject,
  }) : _project =
           initialProject ??
           SongProject.create() {
    lyricController = TextEditingController(
      text: _project.lyrics,
    );

    lyricController.addListener(
      _onLyricsChanged,
    );

    rhymesController.addListener(
      _onRhymesChanged,
    );

    // ==========================================================
    // SINCRONIZAÇÃO INICIAL
    // ==========================================================
    //
    // Se a biblioteca já estiver carregada quando o Studio abrir,
    // as palavras entram imediatamente na Timeline do projeto.
    //
    // Se ainda não estiver carregada, _onRhymesChanged() fará
    // essa sincronização assim que o BrainController terminar
    // de buscar os dados.
    //
    // ==========================================================

    _syncGlobalRhymesToTimeline(
      notify: false,
      markChanged: false,
    );
  }

  // ============================================================
  // GETTERS RÁPIDOS
  // ============================================================

  String get title => _project.title;

  String get lyrics => _project.lyrics;

  int get bpm => _project.bpm;

  String? get vibe => _project.vibe;

  String? get technique => _project.technique;

  List<
    String
  >
  get timelineWords => List.unmodifiable(
    _project.timelineWords,
  );

  List<
    MindMapNode
  >
  get mindMapNodes => List.unmodifiable(
    _project.mindMapNodes,
  );

  bool get hasLyrics => _project.hasLyrics;

  bool get hasTimelineWords => _project.timelineWords.isNotEmpty;

  bool get hasMindMap => _project.mindMapNodes.isNotEmpty;

  // ============================================================
  // BANCO GLOBAL DE RIMAS
  // ============================================================

  List<
    String
  >
  get rhymeLibrary {
    return List<
      String
    >.unmodifiable(
      rhymesController.vocabulary
          .map(
            (
              rhyme,
            ) => rhyme.word.trim(),
          )
          .where(
            (
              word,
            ) => word.isNotEmpty,
          ),
    );
  }

  bool hasLibraryWord(
    String word,
  ) {
    final normalized = _normalizeWord(
      word,
    );

    if (normalized.isEmpty) {
      return false;
    }

    return rhymesController.vocabulary.any(
      (
        rhyme,
      ) =>
          _normalizeWord(
            rhyme.word,
          ) ==
          normalized,
    );
  }

  void _onRhymesChanged() {
    final changed = _syncGlobalRhymesToTimeline(
      notify: false,
      markChanged: false,
    );

    // Mesmo quando nenhuma palavra nova entrou na Timeline,
    // a Biblioteca pode ter mudado e a UI precisa refletir isso.
    if (changed ||
        !_isDisposed) {
      notifyListeners();
    }
  }

  // ============================================================
  // SINCRONIZAR BANCO GLOBAL → TIMELINE DO STUDIO
  // ============================================================

  bool _syncGlobalRhymesToTimeline({
    bool notify = true,
    bool markChanged = true,
  }) {
    bool changed = false;

    for (final rhyme in rhymesController.vocabulary) {
      final word = rhyme.word.trim();

      if (word.isEmpty) {
        continue;
      }

      if (_project.hasTimelineWord(
        word,
      )) {
        continue;
      }

      final added = _project.addTimelineWord(
        word,
      );

      if (added) {
        changed = true;
      }
    }

    if (!changed) {
      return false;
    }

    if (markChanged) {
      _markChanged();
    }

    if (notify &&
        !_isDisposed) {
      notifyListeners();
    }

    return true;
  }

  // ============================================================
  // SINCRONIZAR MANUALMENTE
  // ============================================================

  void syncGlobalRhymesToTimeline() {
    _syncGlobalRhymesToTimeline();
  }

  // ============================================================
  // LETRA
  // ============================================================

  void _onLyricsChanged() {
    _project.updateLyrics(
      lyricController.text,
    );

    _markChanged();

    notifyListeners();
  }

  void setLyrics(
    String text,
  ) {
    if (lyricController.text ==
        text) {
      return;
    }

    lyricController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(
        offset: text.length,
      ),
    );
  }

  void clearLyrics() {
    if (lyricController.text.isEmpty) {
      return;
    }

    lyricController.clear();
  }

  // ============================================================
  // TEXTO SELECIONADO
  // ============================================================

  void updateSelectedText(
    String text,
  ) {
    _selectedText = text.trim();

    notifyListeners();
  }

  void clearSelectedText() {
    if (_selectedText.isEmpty) {
      return;
    }

    _selectedText = '';

    notifyListeners();
  }

  String getSelectedTextFromEditor() {
    final selection = lyricController.selection;

    if (!selection.isValid ||
        selection.isCollapsed) {
      return '';
    }

    final text = lyricController.text;

    if (selection.start <
            0 ||
        selection.end >
            text.length) {
      return '';
    }

    return text
        .substring(
          selection.start,
          selection.end,
        )
        .trim();
  }

  void captureCurrentSelection() {
    updateSelectedText(
      getSelectedTextFromEditor(),
    );
  }

  // ============================================================
  // TÍTULO
  // ============================================================

  void updateTitle(
    String value,
  ) {
    final normalized = value.trim();

    if (normalized.isEmpty ||
        normalized ==
            _project.title) {
      return;
    }

    _project.updateTitle(
      normalized,
    );

    _markChanged();

    notifyListeners();
  }

  // ============================================================
  // BPM
  // ============================================================

  void updateBpm(
    int value,
  ) {
    if (value <=
            0 ||
        value ==
            _project.bpm) {
      return;
    }

    _project.updateBpm(
      value,
    );

    _markChanged();

    notifyListeners();
  }

  void increaseBpm() {
    updateBpm(
      _project.bpm +
          1,
    );
  }

  void decreaseBpm() {
    if (_project.bpm <=
        1) {
      return;
    }

    updateBpm(
      _project.bpm -
          1,
    );
  }

  // ============================================================
  // VIBE
  // ============================================================

  void updateVibe(
    String? value,
  ) {
    final normalized = value?.trim();

    if (_project.vibe ==
        normalized) {
      return;
    }

    _project.vibe = normalized;

    _project.touch();

    _markChanged();

    notifyListeners();
  }

  // ============================================================
  // TÉCNICA
  // ============================================================

  void updateTechnique(
    String? value,
  ) {
    final normalized = value?.trim();

    if (_project.technique ==
        normalized) {
      return;
    }

    _project.technique = normalized;

    _project.touch();

    _markChanged();

    notifyListeners();
  }

  // ============================================================
  // TIMELINE
  // ============================================================

  bool addTimelineWord(
    String word,
  ) {
    final normalized = word.trim();

    if (normalized.isEmpty) {
      return false;
    }

    final added = _project.addTimelineWord(
      normalized,
    );

    // Toda palavra usada no Studio também passa a fazer parte
    // do banco global compartilhado com Chat/Biblioteca.
    unawaited(
      _ensureWordInGlobalLibrary(
        normalized,
      ),
    );

    if (!added) {
      return false;
    }

    _markChanged();

    notifyListeners();

    return true;
  }

  Future<
    void
  >
  _ensureWordInGlobalLibrary(
    String word,
  ) async {
    final normalized = word.trim();

    if (normalized.isEmpty ||
        hasLibraryWord(
          normalized,
        )) {
      return;
    }

    try {
      await rhymesController.addWord(
        normalized,
        false,
      );
    } catch (
      e
    ) {
      debugPrint(
        'Erro ao sincronizar palavra do Studio com a biblioteca: $e',
      );
    }
  }

  bool addLibraryWordToTimeline(
    String word,
  ) {
    return addTimelineWord(
      word,
    );
  }

  bool removeTimelineWord(
    String word,
  ) {
    final removed = _project.removeTimelineWord(
      word,
    );

    if (!removed) {
      return false;
    }

    _markChanged();

    notifyListeners();

    return true;
  }

  bool hasTimelineWord(
    String word,
  ) {
    return _project.hasTimelineWord(
      word,
    );
  }

  bool isTimelineWordUsed(
    String word,
  ) {
    return _project.isTimelineWordUsed(
      word,
    );
  }

  void clearTimeline() {
    if (_project.timelineWords.isEmpty) {
      return;
    }

    _project.clearTimeline();

    _markChanged();

    notifyListeners();
  }

  void addSelectedTextToTimeline() {
    final text = _selectedText.trim();

    if (text.isEmpty) {
      return;
    }

    addTimelineWord(
      text,
    );
  }

  // ============================================================
  // MAPA — ADICIONAR
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

  MindMapNode? addSelectedTextToMap({
    MindMapNodeType type = MindMapNodeType.idea,
    Offset position = Offset.zero,
  }) {
    final text = _selectedText.trim();

    if (text.isEmpty) {
      return null;
    }

    return addMindMapNode(
      text: text,
      type: type,
      position: position,
    );
  }

  // ============================================================
  // MAPA — REMOVER
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
  // MAPA — SELEÇÃO
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

  void clearMindMapSelection() {
    if (_selectedNodeId ==
        null) {
      return;
    }

    _selectedNodeId = null;

    notifyListeners();
  }

  // ============================================================
  // MAPA — MOVER
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
  // MAPA — TEXTO
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
  // MAPA — TIPO
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
  // MAPA — CONEXÕES
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
  // MAPA — LIMPAR
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
  // PAINEL LETRA — DESTACAR / ENCAIXAR
  // ============================================================

  void detachLyrics() {
    if (_isLyricsDetached) {
      return;
    }

    _isLyricsDetached = true;

    notifyListeners();
  }

  void dockLyrics() {
    if (!_isLyricsDetached) {
      return;
    }

    _isLyricsDetached = false;

    notifyListeners();
  }

  void toggleLyricsDetached() {
    _isLyricsDetached = !_isLyricsDetached;

    notifyListeners();
  }

  // ============================================================
  // PAINEL MAPA — DESTACAR / ENCAIXAR
  // ============================================================

  void detachMindMap() {
    if (_isMindMapDetached) {
      return;
    }

    _isMindMapDetached = true;

    notifyListeners();
  }

  void dockMindMap() {
    if (!_isMindMapDetached) {
      return;
    }

    _isMindMapDetached = false;

    notifyListeners();
  }

  void toggleMindMapDetached() {
    _isMindMapDetached = !_isMindMapDetached;

    notifyListeners();
  }

  // ============================================================
  // ENCAIXAR TODOS OS PAINÉIS
  // ============================================================

  void dockAllPanels() {
    if (!_isLyricsDetached &&
        !_isMindMapDetached) {
      return;
    }

    _isLyricsDetached = false;
    _isMindMapDetached = false;

    notifyListeners();
  }

  // ============================================================
  // MAPA VISÍVEL
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
  // MAPA → TIMELINE
  // ============================================================

  bool addNodeToTimeline(
    String nodeId,
  ) {
    final node = _project.findMindMapNode(
      nodeId,
    );

    if (node ==
        null) {
      return false;
    }

    return addTimelineWord(
      node.text,
    );
  }

  bool addSelectedNodeToTimeline() {
    final node = selectedNode;

    if (node ==
        null) {
      return false;
    }

    return addTimelineWord(
      node.text,
    );
  }

  // ============================================================
  // TIMELINE → MAPA
  // ============================================================

  MindMapNode? addTimelineWordToMap(
    String word, {
    MindMapNodeType type = MindMapNodeType.rhyme,
    Offset position = Offset.zero,
  }) {
    final normalized = word.trim();

    if (normalized.isEmpty) {
      return null;
    }

    return addMindMapNode(
      text: normalized,
      type: type,
      position: position,
    );
  }

  // ============================================================
  // NOVO PROJETO
  // ============================================================

  void createNewProject({
    String title = 'MINHA MÚSICA',
    int bpm = 120,
  }) {
    _project = SongProject.create(
      title: title,
      bpm: bpm,
    );

    lyricController.value = const TextEditingValue(
      text: '',
    );

    _selectedText = '';
    _selectedNodeId = null;

    _isLyricsDetached = false;
    _isMindMapDetached = false;

    _hasUnsavedChanges = false;

    notifyListeners();
  }

  // ============================================================
  // CARREGAR PROJETO
  // ============================================================

  void loadProject(
    SongProject project,
  ) {
    _project = project;

    lyricController.value = TextEditingValue(
      text: project.lyrics,
      selection: TextSelection.collapsed(
        offset: project.lyrics.length,
      ),
    );

    _selectedText = '';
    _selectedNodeId = null;

    _hasUnsavedChanges = false;

    notifyListeners();
  }

  // ============================================================
  // EXPORTAÇÃO
  // ============================================================

  Map<
    String,
    dynamic
  >
  exportProject() {
    return _project.toJson();
  }

  // ============================================================
  // MARCAR COMO SALVO
  // ============================================================

  void markAsSaved() {
    if (!_hasUnsavedChanges) {
      return;
    }

    _hasUnsavedChanges = false;

    notifyListeners();
  }

  // ============================================================
  // ALTERAÇÃO INTERNA
  // ============================================================

  void _markChanged() {
    _hasUnsavedChanges = true;
  }

  // ============================================================
  // GERADOR DE ID
  // ============================================================

  String _generateNodeId() {
    return 'node-${DateTime.now().microsecondsSinceEpoch}';
  }

  String _normalizeWord(
    String value,
  ) {
    return value.trim().toLowerCase();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _isDisposed = true;

    rhymesController.removeListener(
      _onRhymesChanged,
    );

    lyricController.removeListener(
      _onLyricsChanged,
    );

    lyricController.dispose();

    super.dispose();
  }
}
