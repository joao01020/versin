import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

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

    brainController =
        GetIt.I<
          BrainController
        >();

    controller = StudioController(
      rhymesController: brainController,
    );

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
    controller.dispose();

    super.dispose();
  }

  Future<
    void
  >
  _showAddTimelineWordDialog() async {
    final searchController = TextEditingController();

    String search = '';

    final result =
        await showDialog<
          String
        >(
          context: context,
          builder:
              (
                context,
              ) {
                return StatefulBuilder(
                  builder:
                      (
                        context,
                        setDialogState,
                      ) {
                        final query = search.trim().toLowerCase();

                        final libraryWords = controller.rhymeLibrary
                            .where(
                              (
                                word,
                              ) {
                                if (query.isEmpty) {
                                  return true;
                                }

                                return word.toLowerCase().contains(
                                  query,
                                );
                              },
                            )
                            .where(
                              (
                                word,
                              ) => !controller.hasTimelineWord(
                                word,
                              ),
                            )
                            .toList();

                        return AlertDialog(
                          backgroundColor: const Color(
                            0xFF1A1A1A,
                          ),
                          title: const Text(
                            'Adicionar à Timeline',
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                          content: SizedBox(
                            width: 520,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextField(
                                  controller: searchController,
                                  autofocus: true,
                                  style: const TextStyle(
                                    color: Colors.white,
                                  ),
                                  onChanged:
                                      (
                                        value,
                                      ) {
                                        setDialogState(
                                          () {
                                            search = value;
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

                                        Navigator.pop(
                                          context,
                                          normalized,
                                        );
                                      },
                                  decoration: InputDecoration(
                                    hintText: 'Buscar na biblioteca ou criar uma palavra...',
                                    hintStyle: const TextStyle(
                                      color: Colors.white30,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.search_rounded,
                                      color: Colors.white30,
                                    ),
                                    suffixIcon: search.trim().isEmpty
                                        ? null
                                        : IconButton(
                                            onPressed: () {
                                              searchController.clear();

                                              setDialogState(
                                                () {
                                                  search = '';
                                                },
                                              );
                                            },
                                            icon: const Icon(
                                              Icons.close_rounded,
                                              color: Colors.white30,
                                            ),
                                          ),
                                    filled: true,
                                    fillColor: Colors.white.withValues(
                                      alpha: 0.04,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        12,
                                      ),
                                      borderSide: const BorderSide(
                                        color: Colors.white10,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        12,
                                      ),
                                      borderSide: BorderSide(
                                        color: activeColor,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(
                                  height: 18,
                                ),

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

                                    const SizedBox(
                                      width: 8,
                                    ),

                                    Text(
                                      '${libraryWords.length}',
                                      style: const TextStyle(
                                        color: Colors.white24,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(
                                  height: 10,
                                ),

                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxHeight: 260,
                                  ),
                                  child: libraryWords.isEmpty
                                      ? Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 24,
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.library_books_outlined,
                                                color: Colors.white24,
                                                size: 28,
                                              ),

                                              const SizedBox(
                                                height: 10,
                                              ),

                                              Text(
                                                search.trim().isEmpty
                                                    ? 'Nenhuma palavra disponível na biblioteca.'
                                                    : 'Nenhuma palavra encontrada.',
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  color: Colors.white30,
                                                  fontSize: 11,
                                                ),
                                              ),

                                              if (search.trim().isNotEmpty) ...[
                                                const SizedBox(
                                                  height: 6,
                                                ),

                                                Text(
                                                  'Você pode criar "${search.trim()}" usando o botão abaixo.',
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    color: Colors.white24,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        )
                                      : SingleChildScrollView(
                                          child: Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: libraryWords.map(
                                              (
                                                word,
                                              ) {
                                                return InkWell(
                                                  borderRadius: BorderRadius.circular(
                                                    12,
                                                  ),
                                                  onTap: () {
                                                    Navigator.pop(
                                                      context,
                                                      word,
                                                    );
                                                  },
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
                                                        12,
                                                      ),
                                                      border: Border.all(
                                                        color: activeColor.withValues(
                                                          alpha: 0.20,
                                                        ),
                                                      ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          Icons.add_rounded,
                                                          color: activeColor,
                                                          size: 15,
                                                        ),

                                                        const SizedBox(
                                                          width: 5,
                                                        ),

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
                                              },
                                            ).toList(),
                                          ),
                                        ),
                                ),

                                if (search.trim().isNotEmpty) ...[
                                  const SizedBox(
                                    height: 16,
                                  ),

                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        Navigator.pop(
                                          context,
                                          search.trim(),
                                        );
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: activeColor,
                                        side: BorderSide(
                                          color: activeColor.withValues(
                                            alpha: 0.35,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.add_rounded,
                                        size: 17,
                                      ),
                                      label: Text(
                                        'CRIAR "${search.trim()}"',
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
                                Navigator.pop(
                                  context,
                                );
                              },
                              child: const Text(
                                'CANCELAR',
                              ),
                            ),
                          ],
                        );
                      },
                );
              },
        );

    searchController.dispose();

    if (result ==
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
  _showAddMindMapNodeDialog() async {
    final textController = TextEditingController();

    MindMapNodeType selectedType = MindMapNodeType.idea;

    final result =
        await showDialog<
          Map<
            String,
            dynamic
          >
        >(
          context: context,
          builder:
              (
                context,
              ) {
                return StatefulBuilder(
                  builder:
                      (
                        context,
                        setDialogState,
                      ) {
                        return AlertDialog(
                          backgroundColor: const Color(
                            0xFF1A1A1A,
                          ),
                          title: const Text(
                            'Adicionar ao Mapa',
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                controller: textController,
                                autofocus: true,
                                style: const TextStyle(
                                  color: Colors.white,
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'Ex: madrugada, saudade, reflexo...',
                                  hintStyle: TextStyle(
                                    color: Colors.white30,
                                  ),
                                ),
                              ),

                              const SizedBox(
                                height: 18,
                              ),

                              DropdownButtonFormField<
                                MindMapNodeType
                              >(
                                initialValue: selectedType,
                                dropdownColor: const Color(
                                  0xFF1A1A1A,
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'Tipo',
                                  labelStyle: TextStyle(
                                    color: Colors.white54,
                                  ),
                                ),
                                style: const TextStyle(
                                  color: Colors.white,
                                ),
                                items: MindMapNodeType.values.map(
                                  (
                                    type,
                                  ) {
                                    return DropdownMenuItem<
                                      MindMapNodeType
                                    >(
                                      value: type,
                                      child: Text(
                                        _nodeTypeLabel(
                                          type,
                                        ),
                                      ),
                                    );
                                  },
                                ).toList(),
                                onChanged:
                                    (
                                      value,
                                    ) {
                                      if (value ==
                                          null) {
                                        return;
                                      }

                                      setDialogState(
                                        () {
                                          selectedType = value;
                                        },
                                      );
                                    },
                              ),
                            ],
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
                                  {
                                    'text': textController.text.trim(),
                                    'type': selectedType,
                                  },
                                );
                              },
                              child: Text(
                                'ADICIONAR',
                                style: TextStyle(
                                  color: activeColor,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                );
              },
        );

    textController.dispose();

    if (result ==
        null) {
      return;
    }

    final text = result['text']?.toString().trim();

    final type =
        result['type']
            as MindMapNodeType?;

    if (text ==
            null ||
        text.isEmpty ||
        type ==
            null) {
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
      type: type,
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
                                                controller.addMindMapNode(
                                                  text: text,
                                                  position: const Offset(
                                                    40,
                                                    40,
                                                  ),
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
                                        onSelectionChanged: controller.updateSelectedText,
                                        onAddToMap:
                                            (
                                              text,
                                            ) {
                                              controller.addMindMapNode(
                                                text: text,
                                                position: const Offset(
                                                  40,
                                                  40,
                                                ),
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
                                        onAddNode: _showAddMindMapNodeDialog,
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
