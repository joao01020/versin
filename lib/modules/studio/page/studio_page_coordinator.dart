import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'package:versin/modules/brain/controller/brain_controller.dart';
import 'package:versin/modules/dashboard/production/services/creative_activity_service.dart';
import 'package:versin/modules/studio/controllers/studio_controller.dart';
import 'package:versin/modules/studio/mind_map/dialogs/studio_add_mind_map_node_dialog.dart';
import 'package:versin/modules/studio/page/dialogs/studio_project_settings_dialogs.dart';
import 'package:versin/modules/studio/services/studio_window_service.dart';
import 'package:versin/modules/studio/timeline/dialogs/studio_timeline_library_dialog.dart';

// ============================================================
// STUDIO PAGE COORDINATOR
// ============================================================
//
// Orquestra a página sem possuir a lógica interna do
// StudioController.
//
// Ownership:
//
// - BrainController: GetIt singleton -> NÃO dispose.
// - StudioController: GetIt singleton -> NÃO dispose.
// - CreativeActivityService: stateless/local.
// - listeners da página: coordinator registra/remove.
//
// ============================================================

class StudioPageCoordinator extends ChangeNotifier {
  static const Color activeColor = Color(0xFFE100FF);

  late final BrainController brainController;

  late final StudioController controller;

  final CreativeActivityService _creativeActivityService =
      CreativeActivityService();

  bool _initialized = false;
  bool _disposed = false;

  bool _wasUnsaved = false;
  bool _isRegisteringCompositionSession = false;

  int _compositionSessionSequence = 0;
  int? _lastVocabularySignature;

  StudioPageCoordinator() {
    brainController = GetIt.I<BrainController>();

    controller = GetIt.I<StudioController>();

    _wasUnsaved = controller.hasUnsavedChanges;

    controller.addListener(_handleStudioControllerChanged);

    brainController.addListener(_handleBrainControllerChanged);
  }

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> initialize() async {
    if (_disposed || _initialized) {
      return;
    }

    _initialized = true;

    try {
      await brainController.carregarDadosUsuario();

      if (_disposed) {
        return;
      }

      _syncVocabularyState(force: true);
    } catch (error, stackTrace) {
      debugPrint(
        '[STUDIO PAGE COORDINATOR] '
        'Erro ao carregar Brain: $error',
      );

      debugPrint(
        '[STUDIO PAGE COORDINATOR] '
        '$stackTrace',
      );
    }
  }

  // ============================================================
  // STUDIO STATE
  // ============================================================

  void _handleStudioControllerChanged() {
    if (_disposed) {
      return;
    }

    final hasUnsavedChanges = controller.hasUnsavedChanges;

    if (hasUnsavedChanges && !_wasUnsaved) {
      _wasUnsaved = true;

      _registerCompositionSessionSafely();
    } else if (!hasUnsavedChanges && _wasUnsaved) {
      _wasUnsaved = false;
    }

    notifyListeners();
  }

  // ============================================================
  // CREATIVE ACTIVITY
  // ============================================================

  Future<void> _registerCompositionSessionSafely() async {
    if (_isRegisteringCompositionSession ||
        !_creativeActivityService.isAuthenticated) {
      return;
    }

    _isRegisteringCompositionSession = true;

    final sequence = ++_compositionSessionSequence;

    final startedAt = DateTime.now().toUtc();

    final sessionId =
        'studio_'
        '${startedAt.microsecondsSinceEpoch}_'
        '$sequence';

    try {
      await _creativeActivityService.recordCompositionSession(
        sessionId: sessionId,
        metadata: <String, dynamic>{
          'origin': 'studio',
          'started_at': startedAt.toIso8601String(),
          'studio_title': controller.title,
          'bpm': controller.bpm,
          'sequence': sequence,
        },
      );

      debugPrint(
        '[STUDIO] '
        'Sessão de composição registrada: '
        '$sessionId',
      );
    } catch (error, stackTrace) {
      debugPrint(
        '[STUDIO] '
        'Não foi possível registrar composition_session: '
        '$error',
      );

      debugPrint(
        '[STUDIO] '
        '$stackTrace',
      );
    } finally {
      _isRegisteringCompositionSession = false;
    }
  }

  // ============================================================
  // BRAIN / VOCABULARY
  // ============================================================

  void _handleBrainControllerChanged() {
    if (_disposed) {
      return;
    }

    _syncVocabularyState();
  }

  void _syncVocabularyState({bool force = false}) {
    final normalizedWords = brainController.vocabularyWords
        .map((word) => word.trim().toLowerCase())
        .where((word) => word.isNotEmpty)
        .toList();

    final signature = Object.hashAll(normalizedWords);

    if (!force && signature == _lastVocabularySignature) {
      return;
    }

    _lastVocabularySignature = signature;

    debugPrint(
      '[STUDIO] '
      'Vocabulário sincronizado: '
      '${normalizedWords.length} palavra(s).',
    );

    notifyListeners();
  }

  // ============================================================
  // TIMELINE
  // ============================================================

  Future<void> addTimelineWord(BuildContext context) async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) {
        return StudioTimelineLibraryDialog(
          timelineController: controller.timelineController,
          activeColor: activeColor,
        );
      },
    );

    if (_disposed ||
        !context.mounted ||
        result == null ||
        result.trim().isEmpty) {
      return;
    }

    controller.addTimelineWord(result.trim());
  }

  // ============================================================
  // MIND MAP
  // ============================================================

  Future<void> addMindMapNode(BuildContext context) async {
    final draft = await StudioAddMindMapNodeDialog.show(
      context: context,
      activeColor: activeColor,
    );

    if (_disposed || !context.mounted || draft == null) {
      return;
    }

    final index = controller.mindMapNodes.length;

    final position = Offset(40 + (index % 3) * 130, 50 + (index ~/ 3) * 90);

    controller.addMindMapNode(
      text: draft.text,
      type: draft.type,
      position: position,
    );
  }

  // ============================================================
  // PROJECT SETTINGS
  // ============================================================

  Future<void> editTitle(BuildContext context) async {
    final title = await StudioProjectSettingsDialogs.editTitle(
      context: context,
      currentTitle: controller.title,
      activeColor: activeColor,
    );

    if (_disposed || !context.mounted || title == null) {
      return;
    }

    controller.updateTitle(title);
  }

  Future<void> editBpm(BuildContext context) async {
    final bpm = await StudioProjectSettingsDialogs.editBpm(
      context: context,
      currentBpm: controller.bpm,
      activeColor: activeColor,
    );

    if (_disposed || !context.mounted || bpm == null) {
      return;
    }

    controller.updateBpm(bpm);
  }

  // ============================================================
  // SAVE
  // ============================================================

  void saveProject(BuildContext context) {
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

  void askChat(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Trecho preparado para consultar no Chat: "$text"'),
      ),
    );
  }

  // ============================================================
  // EXTERNAL WINDOWS
  // ============================================================

  Future<void> detachLyrics(BuildContext context) async {
    if (controller.isLyricsDetached) {
      await StudioWindowService.instance.showLyricsWindow();

      return;
    }

    controller.detachLyrics();

    try {
      await StudioWindowService.instance.openLyricsWindow(
        projectId: controller.title,
      );
    } catch (error) {
      controller.dockLyrics();

      if (!context.mounted) {
        return;
      }

      _showMessage(context, 'Não foi possível abrir a janela da letra: $error');
    }
  }

  Future<void> detachMindMap(BuildContext context) async {
    if (controller.isMindMapDetached) {
      await StudioWindowService.instance.showMindMapWindow();

      return;
    }

    controller.detachMindMap();

    try {
      await StudioWindowService.instance.openMindMapWindow(
        projectId: controller.title,
      );
    } catch (error) {
      controller.dockMindMap();

      if (!context.mounted) {
        return;
      }

      _showMessage(context, 'Não foi possível abrir a janela do mapa: $error');
    }
  }

  Future<void> dockAllPanels() async {
    await Future.wait([
      StudioWindowService.instance.dockLyricsWindow(),
      StudioWindowService.instance.dockMindMapWindow(),
    ]);

    if (_disposed) {
      return;
    }

    controller.dockAllPanels();
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    if (_disposed) {
      return;
    }

    _disposed = true;

    brainController.removeListener(_handleBrainControllerChanged);

    controller.removeListener(_handleStudioControllerChanged);

    // IMPORTANTE:
    //
    // BrainController e StudioController pertencem ao GetIt.
    // Não chamamos dispose() neles aqui.

    super.dispose();
  }
}
