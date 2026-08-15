import 'package:flutter/material.dart';

import 'package:versin/features/rhymes/presentation/controller/rhymes_controller.dart';
import 'package:versin/modules/studio/controllers/studio_mind_map_controller.dart';
import 'package:versin/modules/studio/controllers/studio_timeline_controller.dart';
import 'package:versin/modules/studio/models/mind_map_node.dart';
import 'package:versin/modules/studio/models/song_project.dart';

// ============================================================
// STUDIO CONTROLLER
// ============================================================
//
// Controller principal/orquestrador do Studio.
//
// Responsabilidades mantidas aqui:
//
// - projeto atual;
// - editor de letra;
// - texto selecionado;
// - título/BPM/vibe/técnica;
// - estado dos painéis;
// - criação/carregamento/exportação.
//
// Timeline e Mind Map são delegados para controllers próprios.
//
// ============================================================

class StudioController
    extends
        ChangeNotifier {
  // ============================================================
  // BANCO GLOBAL DE RIMAS
  // ============================================================

  final RhymesController rhymesController;

  // ============================================================
  // PROJETO
  // ============================================================

  SongProject _project;

  SongProject get project => _project;

  // ============================================================
  // SUBCONTROLLERS
  // ============================================================

  late final StudioTimelineController timelineController;

  late final StudioMindMapController mindMapController;

  // ============================================================
  // EDITOR DA LETRA
  // ============================================================

  late final TextEditingController lyricController;

  // ============================================================
  // SELEÇÃO DE TEXTO
  // ============================================================

  String _selectedText = '';

  String get selectedText => _selectedText;

  bool get hasSelectedText => _selectedText.trim().isNotEmpty;

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

    timelineController = StudioTimelineController(
      rhymesController: rhymesController,
      projectProvider: () => _project,
      markChanged: _markChanged,
    );

    mindMapController = StudioMindMapController(
      projectProvider: () => _project,
      markChanged: _markChanged,
    );

    timelineController.addListener(
      _onChildChanged,
    );

    mindMapController.addListener(
      _onChildChanged,
    );
  }

  // ============================================================
  // ALTERAÇÃO DOS SUBCONTROLLERS
  // ============================================================

  void _onChildChanged() {
    if (_isDisposed) {
      return;
    }

    notifyListeners();
  }

  // ============================================================
  // GETTERS DO PROJETO
  // ============================================================

  String get title => _project.title;

  String get lyrics => _project.lyrics;

  int get bpm => _project.bpm;

  String? get vibe => _project.vibe;

  String? get technique => _project.technique;

  bool get hasLyrics => _project.hasLyrics;

  // ============================================================
  // TIMELINE - GETTERS COMPATÍVEIS
  // ============================================================

  List<
    String
  >
  get timelineWords => timelineController.timelineWords;

  bool get hasTimelineWords => timelineController.hasTimelineWords;

  List<
    String
  >
  get rhymeLibrary => timelineController.rhymeLibrary;

  // ============================================================
  // MIND MAP - GETTERS COMPATÍVEIS
  // ============================================================

  String? get selectedNodeId => mindMapController.selectedNodeId;

  MindMapNode? get selectedNode => mindMapController.selectedNode;

  bool get isMapVisible => mindMapController.isMapVisible;

  List<
    MindMapNode
  >
  get mindMapNodes => mindMapController.mindMapNodes;

  bool get hasMindMap => mindMapController.hasMindMap;

  // ============================================================
  // BIBLIOTECA GLOBAL
  // ============================================================

  bool hasLibraryWord(
    String word,
  ) {
    return timelineController.hasLibraryWord(
      word,
    );
  }

  void syncGlobalRhymesToTimeline() {
    timelineController.syncGlobalRhymesToTimeline();
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
  // TIMELINE - FACHADA
  // ============================================================

  bool addTimelineWord(
    String word,
  ) {
    return timelineController.addTimelineWord(
      word,
    );
  }

  bool addLibraryWordToTimeline(
    String word,
  ) {
    return timelineController.addLibraryWordToTimeline(
      word,
    );
  }

  bool removeTimelineWord(
    String word,
  ) {
    return timelineController.removeTimelineWord(
      word,
    );
  }

  bool hasTimelineWord(
    String word,
  ) {
    return timelineController.hasTimelineWord(
      word,
    );
  }

  bool isTimelineWordUsed(
    String word,
  ) {
    return timelineController.isTimelineWordUsed(
      word,
    );
  }

  void clearTimeline() {
    timelineController.clearTimeline();
  }

  void addSelectedTextToTimeline() {
    final text = _selectedText.trim();

    if (text.isEmpty) {
      return;
    }

    timelineController.addTimelineWord(
      text,
    );
  }

  // ============================================================
  // MIND MAP - ADICIONAR
  // ============================================================

  MindMapNode addMindMapNode({
    required String text,
    MindMapNodeType type = MindMapNodeType.idea,
    Offset position = Offset.zero,
  }) {
    return mindMapController.addMindMapNode(
      text: text,
      type: type,
      position: position,
    );
  }

  MindMapNode? addSelectedTextToMap({
    MindMapNodeType type = MindMapNodeType.idea,
    Offset position = Offset.zero,
  }) {
    final text = _selectedText.trim();

    if (text.isEmpty) {
      return null;
    }

    return mindMapController.addMindMapNode(
      text: text,
      type: type,
      position: position,
    );
  }

  // ============================================================
  // MIND MAP - FACHADA
  // ============================================================

  bool removeMindMapNode(
    String nodeId,
  ) {
    return mindMapController.removeMindMapNode(
      nodeId,
    );
  }

  void selectMindMapNode(
    String? nodeId,
  ) {
    mindMapController.selectMindMapNode(
      nodeId,
    );
  }

  void clearMindMapSelection() {
    mindMapController.clearMindMapSelection();
  }

  void moveMindMapNode(
    String nodeId,
    Offset delta,
  ) {
    mindMapController.moveMindMapNode(
      nodeId,
      delta,
    );
  }

  void setMindMapNodePosition(
    String nodeId,
    Offset position,
  ) {
    mindMapController.setMindMapNodePosition(
      nodeId,
      position,
    );
  }

  void updateMindMapNodeText(
    String nodeId,
    String text,
  ) {
    mindMapController.updateMindMapNodeText(
      nodeId,
      text,
    );
  }

  void updateMindMapNodeType(
    String nodeId,
    MindMapNodeType type,
  ) {
    mindMapController.updateMindMapNodeType(
      nodeId,
      type,
    );
  }

  bool connectMindMapNodes(
    String firstNodeId,
    String secondNodeId,
  ) {
    return mindMapController.connectMindMapNodes(
      firstNodeId,
      secondNodeId,
    );
  }

  bool disconnectMindMapNodes(
    String firstNodeId,
    String secondNodeId,
  ) {
    return mindMapController.disconnectMindMapNodes(
      firstNodeId,
      secondNodeId,
    );
  }

  bool connectSelectedNodeTo(
    String secondNodeId,
  ) {
    return mindMapController.connectSelectedNodeTo(
      secondNodeId,
    );
  }

  void clearMindMap() {
    mindMapController.clearMindMap();
  }

  // ============================================================
  // PAINEL LETRA
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
  // PAINEL MAPA
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
    mindMapController.toggleMapVisibility();
  }

  void setMapVisible(
    bool value,
  ) {
    mindMapController.setMapVisible(
      value,
    );
  }

  // ============================================================
  // MAPA -> TIMELINE
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

    return timelineController.addTimelineWord(
      node.text,
    );
  }

  bool addSelectedNodeToTimeline() {
    final node = selectedNode;

    if (node ==
        null) {
      return false;
    }

    return timelineController.addTimelineWord(
      node.text,
    );
  }

  // ============================================================
  // TIMELINE -> MAPA
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

    return mindMapController.addMindMapNode(
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

    mindMapController.resetLocalState(
      notify: false,
    );

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

    mindMapController.resetLocalState(
      notify: false,
    );

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
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _isDisposed = true;

    timelineController.removeListener(
      _onChildChanged,
    );

    mindMapController.removeListener(
      _onChildChanged,
    );

    lyricController.removeListener(
      _onLyricsChanged,
    );

    timelineController.dispose();

    mindMapController.dispose();

    lyricController.dispose();

    super.dispose();
  }
}
