import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'package:versin/core/models/rhyme_model.dart';

import 'package:versin/modules/brain/controller/brain_controller.dart';
import 'package:versin/modules/studio/controllers/studio_controller.dart';
import 'package:versin/modules/studio/models/mind_map_node.dart';
import 'package:versin/modules/studio/widgets/lyric_editor.dart';
import 'package:versin/modules/studio/widgets/mind_map.dart';
import 'package:versin/modules/studio/widgets/song_word_timeline.dart';

import 'package:versin/modules/storage/controllers/storage_controller.dart';
import 'package:versin/modules/storage/data/models/stored_work_model.dart';
import 'package:versin/modules/storage/services/storage_hash_service.dart';

class StudioPage
    extends
        StatefulWidget {
  const StudioPage({
    super.key,
  });

  @override
  State<
    StudioPage
  >
  createState() => _StudioPageState();
}

class _StudioPageState
    extends
        State<
          StudioPage
        > {
  late final BrainController brainController;
  late final StudioController controller;

  final StorageController storageController =
      GetIt.I<
        StorageController
      >();

  final StorageHashService storageHashService =
      GetIt.I<
        StorageHashService
      >();

  final Color activeColor = const Color(
    0xFFE100FF,
  );

  static const String _temporaryUserId = 'user_123';

  @override
  void initState() {
    super.initState();

    // ==========================================================
    // BRAIN CONTROLLER GLOBAL
    // ==========================================================

    brainController =
        GetIt.I<
          BrainController
        >();

    // ==========================================================
    // STUDIO CONTROLLER PERSISTENTE
    // ==========================================================
    //
    // O StudioController passa a pertencer à sessão do app.
    //
    // Se ainda não existir no GetIt, criamos uma única instância.
    // Se já existir, reutilizamos exatamente a mesma.
    //
    // Isso mantém ao sair e voltar para o Studio:
    //
    // - letra;
    // - título;
    // - BPM;
    // - timeline;
    // - mapa mental;
    // - estado atual do projeto.
    //
    // ==========================================================

    if (!GetIt.I
        .isRegistered<
          StudioController
        >()) {
      GetIt.I.registerLazySingleton<
        StudioController
      >(
        () => StudioController(
          rhymesController: brainController,
        ),
      );
    }

    controller =
        GetIt.I<
          StudioController
        >();

    // ==========================================================
    // CARREGAR VOCABULÁRIO
    // ==========================================================

    WidgetsBinding.instance.addPostFrameCallback(
      (
        _,
      ) async {
        if (!mounted) {
          return;
        }

        await brainController.carregarDadosUsuario();
      },
    );
  }

  @override
  void dispose() {
    // ==========================================================
    // NÃO DESTRUIR O STUDIO CONTROLLER
    // ==========================================================
    //
    // O StudioController está registrado como singleton no GetIt.
    // Ele deve permanecer vivo mesmo quando esta página sair da
    // árvore de widgets.
    //
    // Isso é o que permite voltar para o Studio sem perder a
    // letra ou o restante do projeto.
    //
    // ==========================================================

    super.dispose();
  }

  Future<
    void
  >
  _showAddTimelineWordDialog() async {
    // ==========================================================
    // ATUALIZAR BIBLIOTECA
    // ==========================================================
    //
    // Usa exatamente o mesmo BrainController global utilizado
    // pela Biblioteca de Rimas.
    //
    // Isso garante que o Studio veja as palavras atualmente
    // salvas no vocabulário, e não uma cópia antiga mantida pelo
    // StudioController.
    //
    // ==========================================================

    await brainController.carregarDadosUsuario();

    if (!mounted) {
      return;
    }

    final librarySnapshot =
        List<
          Rhyme
        >.from(
          brainController.vocabulary,
        );

    final result =
        await showDialog<
          String
        >(
          context: context,
          barrierColor: Colors.black.withValues(
            alpha: 0.72,
          ),
          builder:
              (
                context,
              ) {
                return _TimelineWordPickerDialog(
                  activeColor: activeColor,
                  libraryEntries: librarySnapshot,
                  hasTimelineWord: controller.hasTimelineWord,
                );
              },
        );

    if (!mounted ||
        result ==
            null ||
        result.trim().isEmpty) {
      return;
    }

    controller.addTimelineWord(
      result.trim(),
    );
  }

  Future<
    void
  >
  _showAddMindMapNodeDialog({
    String initialText = '',
  }) async {
    final result =
        await showDialog<
          _MindMapDialogResult
        >(
          context: context,
          barrierColor: Colors.black.withValues(
            alpha: 0.76,
          ),
          builder:
              (
                context,
              ) {
                return _MindMapNodeDialog(
                  activeColor: activeColor,
                  initialText: initialText,
                );
              },
        );

    if (!mounted ||
        result ==
            null) {
      return;
    }

    final text = result.text.trim();

    if (text.isEmpty) {
      return;
    }

    final index = controller.mindMapNodes.length;

    final position = Offset(
      40 +
          (index %
                  3) *
              130,
      50 +
          (index ~/
                  3) *
              90,
    );

    controller.addMindMapNode(
      text: text,
      type: result.type,
      position: position,
    );
  }

  Future<
    void
  >
  _saveProject() async {
    final title = controller.title.trim();
    final lyrics = controller.lyricController.text.trim();

    if (lyrics.isEmpty) {
      _showSaveError(
        'Escreva uma letra antes de salvar.',
      );

      return;
    }

    try {
      await storageController.ensureInitialized(
        userId: _temporaryUserId,
      );

      final contentHash = storageHashService.hashLyrics(
        lyrics,
      );

      final existingWork = await storageController.getWorkByHash(
        contentHash,
      );

      if (!mounted) {
        return;
      }

      if (existingWork !=
          null) {
        controller.markAsSaved();

        _showSaveSuccess(
          title: 'Projeto salvo',
          message: 'Esta versão da letra já está no armazenamento.',
        );

        return;
      }

      final now = DateTime.now().toUtc();

      final userId = storageController.currentUserId;

      if (userId ==
              null ||
          userId.trim().isEmpty) {
        _showSaveError(
          'Não foi possível identificar o usuário do armazenamento.',
        );

        return;
      }

      final work = StoredWorkModel(
        id: 'lyrics_${now.microsecondsSinceEpoch}',
        originalAuthorUserId: userId,
        ownerUserId: userId,
        type: StoredWorkType.lyrics,
        title: title.isEmpty
            ? 'Sem título'
            : title,
        contentHash: contentHash,
        hashAlgorithm: StorageHashService.algorithm,
        lyricsContent: lyrics,
        version: 1,
        integrityVerified: true,
        createdAt: now,
        updatedAt: now,
      );

      final saved = await storageController.saveWork(
        work,
      );

      if (!mounted) {
        return;
      }

      if (!saved) {
        _showSaveError(
          storageController.errorMessage ??
              'Não foi possível salvar a letra no armazenamento.',
        );

        return;
      }

      controller.markAsSaved();

      final data = controller.exportProject();

      debugPrint(
        '================ STUDIO SAVE ================',
      );

      debugPrint(
        data.toString(),
      );

      debugPrint(
        '=============================================',
      );

      _showSaveSuccess(
        title: 'Projeto salvo',
        message: 'Letra adicionada ao armazenamento.',
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[STUDIO] Erro ao salvar no armazenamento: $error',
      );

      debugPrint(
        '[STUDIO] StackTrace: $stackTrace',
      );

      if (!mounted) {
        return;
      }

      _showSaveError(
        'Não foi possível salvar a letra no armazenamento.',
      );
    }
  }

  void _showSaveSuccess({
    required String title,
    required String message,
  }) {
    if (!mounted) {
      return;
    }

    final now = DateTime.now();

    final hour = now.hour.toString().padLeft(
      2,
      '0',
    );

    final minute = now.minute.toString().padLeft(
      2,
      '0',
    );

    ScaffoldMessenger.of(
        context,
      )
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(
            left: 24,
            right: 24,
            bottom: 24,
          ),
          duration: const Duration(
            seconds: 3,
          ),
          padding: EdgeInsets.zero,
          content: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: const Color(
                0xFF171717,
              ),
              borderRadius: BorderRadius.circular(
                14,
              ),
              border: Border.all(
                color: activeColor.withValues(
                  alpha: 0.22,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: 0.35,
                  ),
                  blurRadius: 18,
                  offset: const Offset(
                    0,
                    8,
                  ),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: activeColor.withValues(
                      alpha: 0.12,
                    ),
                    borderRadius: BorderRadius.circular(
                      10,
                    ),
                  ),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    color: activeColor,
                    size: 20,
                  ),
                ),
                const SizedBox(
                  width: 12,
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(
                        height: 3,
                      ),
                      Text(
                        '$message • $hour:$minute',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.check_circle_rounded,
                  color: activeColor.withValues(
                    alpha: 0.85,
                  ),
                  size: 19,
                ),
              ],
            ),
          ),
        ),
      );
  }

  void _showSaveError(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
        context,
      )
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(
            left: 24,
            right: 24,
            bottom: 24,
          ),
          padding: EdgeInsets.zero,
          content: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: const Color(
                0xFF211216,
              ),
              borderRadius: BorderRadius.circular(
                14,
              ),
              border: Border.all(
                color: Colors.redAccent.withValues(
                  alpha: 0.25,
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.redAccent,
                  size: 21,
                ),
                const SizedBox(
                  width: 12,
                ),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }

  void _askChat(
    String text,
  ) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: Text(
          'Trecho preparado para consultar no Chat: "$text"',
        ),
      ),
    );
  }

  Future<
    void
  >
  _editTitle() async {
    final textController = TextEditingController();

    final result =
        await showDialog<
          String
        >(
          context: context,
          builder:
              (
                context,
              ) {
                return AlertDialog(
                  backgroundColor: const Color(
                    0xFF1A1A1A,
                  ),
                  title: const Text(
                    'Nome da Música',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  content: TextField(
                    controller: textController,
                    autofocus: true,
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'MINHA MUSICA',
                      hintStyle: TextStyle(
                        color: Colors.white30,
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(
                          context,
                        );
                      },
                      child: const Text(
                        'CANCELAR',
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(
                          context,
                          textController.text.trim(),
                        );
                      },
                      child: Text(
                        'SALVAR',
                        style: TextStyle(
                          color: activeColor,
                        ),
                      ),
                    ),
                  ],
                );
              },
        );

    textController.dispose();

    if (result ==
            null ||
        result.isEmpty) {
      return;
    }

    controller.updateTitle(
      result,
    );
  }

  Future<
    void
  >
  _editBpm() async {
    final textController = TextEditingController(
      text: controller.bpm.toString(),
    );

    final result =
        await showDialog<
          int
        >(
          context: context,
          builder:
              (
                context,
              ) {
                return AlertDialog(
                  backgroundColor: const Color(
                    0xFF1A1A1A,
                  ),
                  title: const Text(
                    'BPM',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  content: TextField(
                    controller: textController,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                    decoration: const InputDecoration(
                      hintText: '120',
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(
                          context,
                        );
                      },
                      child: const Text(
                        'CANCELAR',
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        final value = int.tryParse(
                          textController.text,
                        );

                        Navigator.pop(
                          context,
                          value,
                        );
                      },
                      child: Text(
                        'SALVAR',
                        style: TextStyle(
                          color: activeColor,
                        ),
                      ),
                    ),
                  ],
                );
              },
        );

    textController.dispose();

    if (result ==
            null ||
        result <=
            0) {
      return;
    }

    controller.updateBpm(
      result,
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return AnimatedBuilder(
      animation: controller,
      builder:
          (
            context,
            _,
          ) {
            return Scaffold(
              backgroundColor: const Color(
                0xFF0D0D0D,
              ),
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(
                    14,
                  ),
                  child: Column(
                    children: [
                      _buildHeader(),

                      const SizedBox(
                        height: 12,
                      ),

                      Expanded(
                        child: LayoutBuilder(
                          builder:
                              (
                                context,
                                constraints,
                              ) {
                                final compact =
                                    constraints.maxWidth <
                                    850;

                                if (compact) {
                                  return Column(
                                    children: [
                                      Expanded(
                                        child: LyricEditor(
                                          controller: controller.lyricController,
                                          activeColor: activeColor,
                                          onSelectionChanged: controller.updateSelectedText,
                                          onAddToMap:
                                              (
                                                text,
                                              ) {
                                                _showAddMindMapNodeDialog(
                                                  initialText: text,
                                                );
                                              },
                                          onAddToTimeline: controller.addTimelineWord,
                                          onAskChat: _askChat,
                                        ),
                                      ),

                                      const SizedBox(
                                        height: 12,
                                      ),

                                      Expanded(
                                        child: MindMap(
                                          nodes: controller.mindMapNodes,
                                          selectedNodeId: controller.selectedNodeId,
                                          activeColor: activeColor,
                                          onSelectNode: controller.selectMindMapNode,
                                          onMoveNode: controller.moveMindMapNode,
                                          onRemoveNode: controller.removeMindMapNode,
                                          onAddNodeToTimeline: controller.addNodeToTimeline,
                                          onAddNode: () => _showAddMindMapNodeDialog(),
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
                                        onSelectionChanged: controller.updateSelectedText,
                                        onAddToMap:
                                            (
                                              text,
                                            ) {
                                              _showAddMindMapNodeDialog(
                                                initialText: text,
                                              );
                                            },
                                        onAddToTimeline: controller.addTimelineWord,
                                        onAskChat: _askChat,
                                      ),
                                    ),

                                    const SizedBox(
                                      width: 12,
                                    ),

                                    Expanded(
                                      flex: 2,
                                      child: MindMap(
                                        nodes: controller.mindMapNodes,
                                        selectedNodeId: controller.selectedNodeId,
                                        activeColor: activeColor,
                                        onSelectNode: controller.selectMindMapNode,
                                        onMoveNode: controller.moveMindMapNode,
                                        onRemoveNode: controller.removeMindMapNode,
                                        onAddNodeToTimeline: controller.addNodeToTimeline,
                                        onAddNode: () => _showAddMindMapNodeDialog(),
                                      ),
                                    ),
                                  ],
                                );
                              },
                        ),
                      ),

                      const SizedBox(
                        height: 12,
                      ),

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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: const Color(
          0xFF111111,
        ),
        borderRadius: BorderRadius.circular(
          16,
        ),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.05,
          ),
        ),
      ),
      child: Row(
        children: [
          // ====================================================
          // VOLTAR
          // ====================================================
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.of(
                  context,
                ).maybePop();
              },
              borderRadius: BorderRadius.circular(
                10,
              ),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: 0.04,
                  ),
                  borderRadius: BorderRadius.circular(
                    10,
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(
                      alpha: 0.06,
                    ),
                  ),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white70,
                  size: 19,
                ),
              ),
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(
                8,
              ),
              onTap: _editTitle,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 6,
                  horizontal: 4,
                ),
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

                    const SizedBox(
                      width: 8,
                    ),

                    const Icon(
                      Icons.edit_outlined,
                      color: Colors.white30,
                      size: 14,
                    ),

                    if (controller.hasUnsavedChanges) ...[
                      const SizedBox(
                        width: 8,
                      ),

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

          const SizedBox(
            width: 12,
          ),

          InkWell(
            borderRadius: BorderRadius.circular(
              10,
            ),
            onTap: _editBpm,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: activeColor.withValues(
                  alpha: 0.08,
                ),
                borderRadius: BorderRadius.circular(
                  10,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.speed_rounded,
                    color: activeColor,
                    size: 16,
                  ),

                  const SizedBox(
                    width: 6,
                  ),

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

          const SizedBox(
            width: 10,
          ),

          ElevatedButton.icon(
            onPressed: _saveProject,
            style: ElevatedButton.styleFrom(
              backgroundColor: activeColor,
              foregroundColor: Colors.black,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  10,
                ),
              ),
            ),
            icon: const Icon(
              Icons.save_outlined,
              size: 17,
            ),
            label: const Text(
              'SALVAR',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _nodeTypeLabel(
    MindMapNodeType type,
  ) {
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
// TIMELINE WORD PICKER DIALOG
// ============================================================
//
// Exibe diretamente os dados salvos na Biblioteca de Rimas.
//
// - usa List<Rhyme>;
// - mostra todas as palavras;
// - mantém palavras já usadas visíveis;
// - marca palavras que já estão na Timeline;
// - pesquisa ignorando acentos;
// - permite criar uma nova palavra;
// - Scrollbar e ListView compartilham o mesmo controller.
//
// ============================================================

class _TimelineWordPickerDialog
    extends
        StatefulWidget {
  final Color activeColor;

  final List<
    Rhyme
  >
  libraryEntries;

  final bool Function(
    String word,
  )
  hasTimelineWord;

  const _TimelineWordPickerDialog({
    required this.activeColor,
    required this.libraryEntries,
    required this.hasTimelineWord,
  });

  @override
  State<
    _TimelineWordPickerDialog
  >
  createState() => _TimelineWordPickerDialogState();
}

class _TimelineWordPickerDialogState
    extends
        State<
          _TimelineWordPickerDialog
        > {
  final TextEditingController _searchController = TextEditingController();

  final ScrollController _scrollController = ScrollController();

  String _search = '';

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _searchController.dispose();

    _scrollController.dispose();

    super.dispose();
  }

  // ============================================================
  // NORMALIZAÇÃO
  // ============================================================

  String _normalize(
    String value,
  ) {
    var normalized = value.trim().toLowerCase();

    const replacements = {
      'á': 'a',
      'à': 'a',
      'â': 'a',
      'ã': 'a',
      'ä': 'a',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'í': 'i',
      'ì': 'i',
      'î': 'i',
      'ï': 'i',
      'ó': 'o',
      'ò': 'o',
      'ô': 'o',
      'õ': 'o',
      'ö': 'o',
      'ú': 'u',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'ç': 'c',
    };

    replacements.forEach(
      (
        accented,
        plain,
      ) {
        normalized = normalized.replaceAll(
          accented,
          plain,
        );
      },
    );

    return normalized;
  }

  // ============================================================
  // ENTRADAS FILTRADAS
  // ============================================================

  List<
    Rhyme
  >
  get _filteredEntries {
    final query = _normalize(
      _search,
    );

    final unique =
        <
          String
        >{};

    final result =
        <
          Rhyme
        >[];

    for (final rhyme in widget.libraryEntries) {
      final word = rhyme.word.trim();

      if (word.isEmpty) {
        continue;
      }

      final normalized = _normalize(
        word,
      );

      if (!unique.add(
        normalized,
      )) {
        continue;
      }

      if (query.isNotEmpty &&
          !normalized.contains(
            query,
          )) {
        continue;
      }

      result.add(
        rhyme,
      );
    }

    result.sort(
      (
        a,
        b,
      ) {
        final aText = _normalize(
          a.word,
        );

        final bText = _normalize(
          b.word,
        );

        final aStarts =
            query.isNotEmpty &&
            aText.startsWith(
              query,
            );

        final bStarts =
            query.isNotEmpty &&
            bText.startsWith(
              query,
            );

        if (aStarts &&
            !bStarts) {
          return -1;
        }

        if (!aStarts &&
            bStarts) {
          return 1;
        }

        return aText.compareTo(
          bText,
        );
      },
    );

    return result;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final entries = _filteredEntries;

    final createValue = _search.trim();

    final total = widget.libraryEntries
        .where(
          (
            rhyme,
          ) => rhyme.word.trim().isNotEmpty,
        )
        .length;

    final usedCount = widget.libraryEntries
        .where(
          (
            rhyme,
          ) =>
              rhyme.word
                  .trim()
                  .isNotEmpty &&
              widget.hasTimelineWord(
                rhyme.word,
              ),
        )
        .length;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(
        24,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 600,
          maxHeight: 650,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(
              0xFF141217,
            ),
            borderRadius: BorderRadius.circular(
              24,
            ),
            border: Border.all(
              color: widget.activeColor.withValues(
                alpha: 0.16,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: 0.48,
                ),
                blurRadius: 38,
                offset: const Offset(
                  0,
                  18,
                ),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(
                context,
                total,
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  0,
                  20,
                  12,
                ),
                child: _buildStats(
                  total: total,
                  visible: entries.length,
                  used: usedCount,
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  0,
                  20,
                  14,
                ),
                child: _buildSearchField(),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                ),
                child: Row(
                  children: [
                    const Text(
                      'BIBLIOTECA DE RIMAS',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),

                    const Spacer(),

                    Text(
                      '${entries.length} exibidas',
                      style: const TextStyle(
                        color: Colors.white24,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 9,
              ),

              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                  ),
                  child: entries.isEmpty
                      ? _buildEmpty()
                      : Scrollbar(
                          controller: _scrollController,
                          thumbVisibility: true,
                          interactive: true,
                          child: ListView.separated(
                            controller: _scrollController,
                            primary: false,
                            padding: const EdgeInsets.only(
                              left: 6,
                              right: 12,
                              bottom: 12,
                            ),
                            itemCount: entries.length,
                            separatorBuilder:
                                (
                                  _,
                                  __,
                                ) => const SizedBox(
                                  height: 6,
                                ),
                            itemBuilder:
                                (
                                  context,
                                  index,
                                ) {
                                  final rhyme = entries[index];

                                  return _buildWordTile(
                                    context,
                                    rhyme,
                                    index,
                                  );
                                },
                          ),
                        ),
                ),
              ),

              if (createValue.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    4,
                    20,
                    12,
                  ),
                  child: _buildCreateButton(
                    context,
                    createValue,
                  ),
                ),

              Padding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  0,
                  20,
                  18,
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(
                      context,
                    ),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(
                        color: Colors.white38,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(
    BuildContext context,
    int total,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        14,
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.activeColor.withValues(
                    alpha: 0.20,
                  ),
                  const Color(
                    0xFF7C4DFF,
                  ).withValues(
                    alpha: 0.08,
                  ),
                ],
              ),
              borderRadius: BorderRadius.circular(
                14,
              ),
              border: Border.all(
                color: widget.activeColor.withValues(
                  alpha: 0.16,
                ),
              ),
            ),
            child: Icon(
              Icons.library_music_rounded,
              color: widget.activeColor,
              size: 22,
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Biblioteca de Rimas',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  total ==
                          1
                      ? '1 palavra salva na sua biblioteca'
                      : '$total palavras salvas na sua biblioteca',
                  style: const TextStyle(
                    color: Colors.white30,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            tooltip: 'Fechar',
            onPressed: () => Navigator.pop(
              context,
            ),
            icon: const Icon(
              Icons.close_rounded,
              color: Colors.white38,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ESTATÍSTICAS
  // ============================================================

  Widget _buildStats({
    required int total,
    required int visible,
    required int used,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.library_books_outlined,
            value: '$total',
            label: 'salvas',
          ),
        ),

        const SizedBox(
          width: 8,
        ),

        Expanded(
          child: _buildStatCard(
            icon: Icons.visibility_outlined,
            value: '$visible',
            label: 'visíveis',
          ),
        ),

        const SizedBox(
          width: 8,
        ),

        Expanded(
          child: _buildStatCard(
            icon: Icons.check_circle_outline_rounded,
            value: '$used',
            label: 'na timeline',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.025,
        ),
        borderRadius: BorderRadius.circular(
          12,
        ),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.045,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: widget.activeColor.withValues(
              alpha: 0.70,
            ),
            size: 15,
          ),

          const SizedBox(
            width: 7,
          ),

          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(
            width: 4,
          ),

          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white30,
                fontSize: 8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PESQUISA
  // ============================================================

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      autofocus: true,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 13,
      ),
      onChanged:
          (
            value,
          ) {
            setState(
              () {
                _search = value;
              },
            );
          },
      onSubmitted:
          (
            value,
          ) {
            final normalized = value.trim();

            if (normalized.isEmpty) {
              return;
            }

            Rhyme? match;

            for (final rhyme in widget.libraryEntries) {
              if (_normalize(
                    rhyme.word,
                  ) ==
                  _normalize(
                    normalized,
                  )) {
                match = rhyme;

                break;
              }
            }

            if (match !=
                    null &&
                !widget.hasTimelineWord(
                  match.word,
                )) {
              Navigator.pop(
                context,
                match.word,
              );

              return;
            }

            if (match ==
                null) {
              Navigator.pop(
                context,
                normalized,
              );
            }
          },
      decoration: InputDecoration(
        hintText: 'Pesquisar na biblioteca...',
        hintStyle: const TextStyle(
          color: Colors.white24,
          fontSize: 12,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: Colors.white30,
          size: 19,
        ),
        suffixIcon: _search.trim().isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  _searchController.clear();

                  setState(
                    () {
                      _search = '';
                    },
                  );
                },
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.white30,
                  size: 17,
                ),
              ),
        filled: true,
        fillColor: Colors.white.withValues(
          alpha: 0.04,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            14,
          ),
          borderSide: BorderSide(
            color: Colors.white.withValues(
              alpha: 0.06,
            ),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            14,
          ),
          borderSide: BorderSide(
            color: widget.activeColor.withValues(
              alpha: 0.60,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ITEM
  // ============================================================

  Widget _buildWordTile(
    BuildContext context,
    Rhyme rhyme,
    int index,
  ) {
    final word = rhyme.word.trim();

    final alreadyUsed = widget.hasTimelineWord(
      word,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: alreadyUsed
            ? null
            : () => Navigator.pop(
                context,
                word,
              ),
        borderRadius: BorderRadius.circular(
          13,
        ),
        child: AnimatedContainer(
          duration: const Duration(
            milliseconds: 150,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: alreadyUsed
                ? Colors.white.withValues(
                    alpha: 0.015,
                  )
                : Colors.white.withValues(
                    alpha: 0.030,
                  ),
            borderRadius: BorderRadius.circular(
              13,
            ),
            border: Border.all(
              color: alreadyUsed
                  ? Colors.white.withValues(
                      alpha: 0.03,
                    )
                  : Colors.white.withValues(
                      alpha: 0.05,
                    ),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 26,
                child: Text(
                  '${index + 1}'.padLeft(
                    2,
                    '0',
                  ),
                  style: const TextStyle(
                    color: Colors.white24,
                    fontSize: 9,
                    fontFamily: 'monospace',
                  ),
                ),
              ),

              Container(
                width: 33,
                height: 33,
                decoration: BoxDecoration(
                  color: alreadyUsed
                      ? Colors.greenAccent.withValues(
                          alpha: 0.06,
                        )
                      : widget.activeColor.withValues(
                          alpha: 0.08,
                        ),
                  borderRadius: BorderRadius.circular(
                    9,
                  ),
                ),
                child: Icon(
                  alreadyUsed
                      ? Icons.check_rounded
                      : Icons.add_rounded,
                  color: alreadyUsed
                      ? Colors.greenAccent.withValues(
                          alpha: 0.65,
                        )
                      : widget.activeColor,
                  size: 16,
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      word,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: alreadyUsed
                            ? Colors.white38
                            : Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(
                      height: 2,
                    ),

                    Text(
                      alreadyUsed
                          ? 'Já está na Timeline'
                          : rhyme.isPriority
                          ? 'Prioritária'
                          : 'Disponível para adicionar',
                      style: TextStyle(
                        color: alreadyUsed
                            ? Colors.greenAccent.withValues(
                                alpha: 0.45,
                              )
                            : rhyme.isPriority
                            ? widget.activeColor.withValues(
                                alpha: 0.65,
                              )
                            : Colors.white24,
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
              ),

              if (rhyme.isPriority &&
                  !alreadyUsed)
                Container(
                  margin: const EdgeInsets.only(
                    right: 8,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: widget.activeColor.withValues(
                      alpha: 0.08,
                    ),
                    borderRadius: BorderRadius.circular(
                      20,
                    ),
                  ),
                  child: Text(
                    'PRIORIDADE',
                    style: TextStyle(
                      color: widget.activeColor.withValues(
                        alpha: 0.75,
                      ),
                      fontSize: 7,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),

              Icon(
                alreadyUsed
                    ? Icons.lock_outline_rounded
                    : Icons.arrow_forward_ios_rounded,
                color: alreadyUsed
                    ? Colors.white12
                    : Colors.white24,
                size: 12,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // VAZIO
  // ============================================================

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(
          28,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              color: widget.activeColor.withValues(
                alpha: 0.32,
              ),
              size: 34,
            ),

            const SizedBox(
              height: 10,
            ),

            const Text(
              'Nenhuma palavra encontrada',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(
              height: 4,
            ),

            const Text(
              'Tente outro termo ou crie uma palavra nova.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white24,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CRIAR NOVA
  // ============================================================

  Widget _buildCreateButton(
    BuildContext context,
    String value,
  ) {
    final normalized = _normalize(
      value,
    );

    final alreadyExists = widget.libraryEntries.any(
      (
        rhyme,
      ) =>
          _normalize(
            rhyme.word,
          ) ==
          normalized,
    );

    if (alreadyExists) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => Navigator.pop(
          context,
          value,
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: widget.activeColor,
          side: BorderSide(
            color: widget.activeColor.withValues(
              alpha: 0.26,
            ),
          ),
          backgroundColor: widget.activeColor.withValues(
            alpha: 0.05,
          ),
          padding: const EdgeInsets.symmetric(
            vertical: 13,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              13,
            ),
          ),
        ),
        icon: const Icon(
          Icons.add_rounded,
          size: 17,
        ),
        label: Text(
          'Criar "$value"',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// MIND MAP DIALOG RESULT
// ============================================================

class _MindMapDialogResult {
  final String text;
  final MindMapNodeType type;

  const _MindMapDialogResult({
    required this.text,
    required this.type,
  });
}

// ============================================================
// MODERN MIND MAP NODE DIALOG
// ============================================================

class _MindMapNodeDialog
    extends
        StatefulWidget {
  final Color activeColor;
  final String initialText;

  const _MindMapNodeDialog({
    required this.activeColor,
    required this.initialText,
  });

  @override
  State<
    _MindMapNodeDialog
  >
  createState() => _MindMapNodeDialogState();
}

class _MindMapNodeDialogState
    extends
        State<
          _MindMapNodeDialog
        > {
  late final TextEditingController _textController;

  MindMapNodeType _selectedType = MindMapNodeType.idea;

  @override
  void initState() {
    super.initState();

    _textController = TextEditingController(
      text: widget.initialText.trim(),
    );

    _textController.addListener(
      _handleTextChanged,
    );
  }

  @override
  void dispose() {
    _textController.removeListener(
      _handleTextChanged,
    );

    _textController.dispose();

    super.dispose();
  }

  void _handleTextChanged() {
    setState(
      () {},
    );
  }

  bool get _canSubmit => _textController.text.trim().isNotEmpty;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(
        24,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 580,
        ),
        child: Container(
          padding: const EdgeInsets.all(
            22,
          ),
          decoration: BoxDecoration(
            color: const Color(
              0xFF141217,
            ),
            borderRadius: BorderRadius.circular(
              26,
            ),
            border: Border.all(
              color: widget.activeColor.withValues(
                alpha: 0.16,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: 0.50,
                ),
                blurRadius: 42,
                offset: const Offset(
                  0,
                  20,
                ),
              ),
              BoxShadow(
                color: widget.activeColor.withValues(
                  alpha: 0.05,
                ),
                blurRadius: 34,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(
                context,
              ),

              const SizedBox(
                height: 20,
              ),

              _buildTextField(),

              const SizedBox(
                height: 18,
              ),

              const Text(
                'TIPO DO NÓ',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              _buildTypeGrid(),

              const SizedBox(
                height: 18,
              ),

              _buildPreview(),

              const SizedBox(
                height: 20,
              ),

              _buildActions(
                context,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
  ) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.activeColor.withValues(
                  alpha: 0.18,
                ),
                widget.activeColor.withValues(
                  alpha: 0.06,
                ),
              ],
            ),
            borderRadius: BorderRadius.circular(
              15,
            ),
          ),
          child: Icon(
            Icons.hub_rounded,
            color: widget.activeColor,
            size: 23,
          ),
        ),

        const SizedBox(
          width: 13,
        ),

        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Adicionar ao Mapa',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              SizedBox(
                height: 3,
              ),
              Text(
                'Transforme uma palavra, imagem ou sentimento em um nó visual.',
                style: TextStyle(
                  color: Colors.white30,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),

        IconButton(
          tooltip: 'Fechar',
          onPressed: () => Navigator.pop(
            context,
          ),
          icon: const Icon(
            Icons.close_rounded,
            color: Colors.white38,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField() {
    return TextField(
      controller: _textController,
      autofocus: true,
      minLines: 1,
      maxLines: 3,
      textInputAction: TextInputAction.done,
      onSubmitted:
          (
            _,
          ) {
            if (_canSubmit) {
              _submit();
            }
          },
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        height: 1.35,
      ),
      decoration: InputDecoration(
        labelText: 'Conteúdo do nó',
        labelStyle: const TextStyle(
          color: Colors.white38,
          fontSize: 11,
        ),
        hintText: 'Ex: madrugada, saudade, reflexo...',
        hintStyle: const TextStyle(
          color: Colors.white24,
          fontSize: 12,
        ),
        prefixIcon: Icon(
          _typeIcon(
            _selectedType,
          ),
          color: widget.activeColor.withValues(
            alpha: 0.80,
          ),
          size: 19,
        ),
        filled: true,
        fillColor: Colors.white.withValues(
          alpha: 0.035,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            15,
          ),
          borderSide: BorderSide(
            color: Colors.white.withValues(
              alpha: 0.055,
            ),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            15,
          ),
          borderSide: BorderSide(
            color: widget.activeColor.withValues(
              alpha: 0.55,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: MindMapNodeType.values.map(
        (
          type,
        ) {
          final selected =
              type ==
              _selectedType;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(
                  () {
                    _selectedType = type;
                  },
                );
              },
              borderRadius: BorderRadius.circular(
                12,
              ),
              child: AnimatedContainer(
                duration: const Duration(
                  milliseconds: 160,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? widget.activeColor.withValues(
                          alpha: 0.11,
                        )
                      : Colors.white.withValues(
                          alpha: 0.025,
                        ),
                  borderRadius: BorderRadius.circular(
                    12,
                  ),
                  border: Border.all(
                    color: selected
                        ? widget.activeColor.withValues(
                            alpha: 0.42,
                          )
                        : Colors.white.withValues(
                            alpha: 0.05,
                          ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _typeIcon(
                        type,
                      ),
                      color: selected
                          ? widget.activeColor
                          : Colors.white38,
                      size: 15,
                    ),

                    const SizedBox(
                      width: 6,
                    ),

                    Text(
                      _typeLabel(
                        type,
                      ),
                      style: TextStyle(
                        color: selected
                            ? Colors.white
                            : Colors.white54,
                        fontSize: 10,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ).toList(),
    );
  }

  Widget _buildPreview() {
    final value = _textController.text.trim();

    return AnimatedContainer(
      duration: const Duration(
        milliseconds: 180,
      ),
      width: double.infinity,
      padding: const EdgeInsets.all(
        14,
      ),
      decoration: BoxDecoration(
        color: widget.activeColor.withValues(
          alpha: 0.045,
        ),
        borderRadius: BorderRadius.circular(
          15,
        ),
        border: Border.all(
          color: widget.activeColor.withValues(
            alpha: 0.10,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: widget.activeColor.withValues(
                alpha: 0.10,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _typeIcon(
                _selectedType,
              ),
              color: widget.activeColor,
              size: 18,
            ),
          ),

          const SizedBox(
            width: 11,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value.isEmpty
                      ? 'Pré-visualização do nó'
                      : value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: value.isEmpty
                        ? Colors.white30
                        : Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  _typeLabel(
                    _selectedType,
                  ),
                  style: TextStyle(
                    color: widget.activeColor.withValues(
                      alpha: 0.72,
                    ),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(
    BuildContext context,
  ) {
    return Row(
      children: [
        TextButton(
          onPressed: () => Navigator.pop(
            context,
          ),
          child: const Text(
            'Cancelar',
            style: TextStyle(
              color: Colors.white38,
            ),
          ),
        ),

        const Spacer(),

        AnimatedOpacity(
          duration: const Duration(
            milliseconds: 150,
          ),
          opacity: _canSubmit
              ? 1
              : 0.38,
          child: FilledButton.icon(
            onPressed: _canSubmit
                ? _submit
                : null,
            style: FilledButton.styleFrom(
              backgroundColor: widget.activeColor,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(
                horizontal: 17,
                vertical: 13,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  13,
                ),
              ),
            ),
            icon: const Icon(
              Icons.add_rounded,
              size: 17,
            ),
            label: const Text(
              'Adicionar ao mapa',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _submit() {
    final text = _textController.text.trim();

    if (text.isEmpty) {
      return;
    }

    Navigator.pop(
      context,
      _MindMapDialogResult(
        text: text,
        type: _selectedType,
      ),
    );
  }

  static String _typeLabel(
    MindMapNodeType type,
  ) {
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

  static IconData _typeIcon(
    MindMapNodeType type,
  ) {
    switch (type) {
      case MindMapNodeType.idea:
        return Icons.lightbulb_outline_rounded;

      case MindMapNodeType.scene:
        return Icons.movie_filter_outlined;

      case MindMapNodeType.emotion:
        return Icons.favorite_border_rounded;

      case MindMapNodeType.image:
        return Icons.image_outlined;

      case MindMapNodeType.rhyme:
        return Icons.music_note_rounded;

      case MindMapNodeType.concept:
        return Icons.account_tree_outlined;
    }
  }
}
