import 'package:flutter/material.dart';

import 'package:versin/core/models/rhyme_model.dart';
import 'package:versin/features/rhymes/presentation/controller/rhymes_controller.dart';

import '../data/rhyme_library_manager.dart';

class RhymeLibraryPage
    extends
        StatefulWidget {
  final RhymesController controller;

  const RhymeLibraryPage({
    super.key,
    required this.controller,
  });

  @override
  State<
    RhymeLibraryPage
  >
  createState() => _RhymeLibraryPageState();
}

class _RhymeLibraryPageState
    extends
        State<
          RhymeLibraryPage
        > {
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<
    void
  >
  _importLibrary() async {
    try {
      final importedWords = await RhymeLibraryManager.importFromFile();

      if (importedWords.isEmpty) {
        if (!mounted) {
          return;
        }

        _showSnackBar(
          'Nenhuma rima encontrada no arquivo.',
          Colors.redAccent,
        );

        return;
      }

      int importedCount = 0;

      for (final word in importedWords) {
        final normalized = word.trim().toLowerCase();

        if (normalized.isEmpty) {
          continue;
        }

        final alreadyExists = widget.controller.vocabulary.any(
          (
            rhyme,
          ) =>
              rhyme.word.trim().toLowerCase() ==
              normalized,
        );

        if (alreadyExists) {
          continue;
        }

        await widget.controller.addWord(
          normalized,
          false,
        );

        importedCount++;
      }

      if (!mounted) {
        return;
      }

      _showSnackBar(
        '$importedCount rimas importadas.',
        Colors.purpleAccent,
      );
    } catch (
      e
    ) {
      debugPrint(
        'Erro ao importar biblioteca: $e',
      );

      if (!mounted) {
        return;
      }

      _showSnackBar(
        'Erro ao ler o arquivo.',
        Colors.redAccent,
      );
    }
  }

  Future<
    void
  >
  _exportLibrary() async {
    try {
      final path = await RhymeLibraryManager.exportToBackup(
        widget.controller.vocabulary,
      );

      if (!mounted) {
        return;
      }

      if (path ==
          null) {
        _showSnackBar(
          'Erro na exportação.',
          Colors.redAccent,
        );

        return;
      }

      _showSnackBar(
        'Arquivo salvo em: $path',
        Colors.greenAccent,
      );
    } catch (
      e
    ) {
      debugPrint(
        'Erro ao exportar biblioteca: $e',
      );

      if (!mounted) {
        return;
      }

      _showSnackBar(
        'Erro na exportação.',
        Colors.redAccent,
      );
    }
  }

  void _showSnackBar(
    String message,
    Color color,
  ) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        backgroundColor: color,
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<
    void
  >
  _confirmAddition() async {
    final text = _textController.text.trim();

    if (text.isEmpty) {
      return;
    }

    final normalized = text.toLowerCase();

    final alreadyExists = widget.controller.vocabulary.any(
      (
        rhyme,
      ) =>
          rhyme.word.trim().toLowerCase() ==
          normalized,
    );

    if (alreadyExists) {
      if (!mounted) {
        return;
      }

      _showSnackBar(
        'Essa rima já está na lista.',
        Colors.orangeAccent,
      );

      return;
    }

    await widget.controller.addWord(
      normalized,
      false,
    );

    if (!mounted) {
      return;
    }

    _textController.clear();

    FocusScope.of(
      context,
    ).unfocus();
  }

  Future<
    void
  >
  _removeRhyme(
    int index,
  ) async {
    if (index <
            0 ||
        index >=
            widget.controller.vocabulary.length) {
      return;
    }

    await widget.controller.removeWord(
      index,
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: const Color(
        0xFF0F0F0F,
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(
              context,
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.construction,
              color: Colors.grey,
            ),
            onPressed: null,
            tooltip: 'Funcionalidade em construção',
          ),
          IconButton(
            icon: const Icon(
              Icons.download_for_offline,
              color: Colors.white24,
            ),
            onPressed: _exportLibrary,
          ),
          const SizedBox(
            width: 8,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
            ),
            child: Column(
              children: [
                const Text(
                  'BIBLIOTECA DE RIMAS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),

                const SizedBox(
                  height: 24,
                ),

                GestureDetector(
                  onTap: _importLibrary,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 30,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purpleAccent.withValues(
                        alpha: 0.08,
                      ),
                      borderRadius: BorderRadius.circular(
                        20,
                      ),
                      border: Border.all(
                        color: Colors.purpleAccent.withValues(
                          alpha: 0.4,
                        ),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.drive_folder_upload,
                          color: Colors.purpleAccent,
                          size: 38,
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        const Text(
                          'IMPORTAR BANCO DE RIMAS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),

                        const SizedBox(
                          height: 6,
                        ),

                        Text(
                          'Clique aqui para enviar .txt ou .md',
                          style: TextStyle(
                            color: Colors.white.withValues(
                              alpha: 0.4,
                            ),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListenableBuilder(
              listenable: widget.controller,
              builder:
                  (
                    context,
                    _,
                  ) {
                    final vocab = widget.controller.vocabulary;

                    if (vocab.isEmpty) {
                      return Center(
                        child: Text(
                          'Sua lista está vazia.',
                          style: TextStyle(
                            color: Colors.white.withValues(
                              alpha: 0.1,
                            ),
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.only(
                        top: 20,
                        bottom: 130,
                      ),
                      itemCount: vocab.length,
                      itemBuilder:
                          (
                            context,
                            index,
                          ) {
                            return _buildRhymeTile(
                              vocab[index],
                              index,
                            );
                          },
                    );
                  },
            ),
          ),

          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom:
            MediaQuery.paddingOf(
              context,
            ).bottom +
            16,
      ),
      decoration: const BoxDecoration(
        color: Color(
          0xFF141414,
        ),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(
            24,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _confirmAddition,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purpleAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    14,
                  ),
                ),
              ),
              child: const Text(
                '+ ADICIONAR À LISTA',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.05,
              ),
              borderRadius: BorderRadius.circular(
                12,
              ),
            ),
            child: TextField(
              controller: _textController,
              onSubmitted:
                  (
                    _,
                  ) {
                    _confirmAddition();
                  },
              style: const TextStyle(
                color: Colors.white,
              ),
              decoration: const InputDecoration(
                hintText: 'Digite uma nova rima...',
                hintStyle: TextStyle(
                  color: Colors.white24,
                  fontSize: 14,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRhymeTile(
    Rhyme rhyme,
    int index,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.02,
        ),
        borderRadius: BorderRadius.circular(
          12,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
        ),
        title: Text(
          rhyme.word,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(
            Icons.delete_outline,
            color: Colors.redAccent,
            size: 22,
          ),
          onPressed: () {
            _removeRhyme(
              index,
            );
          },
        ),
      ),
    );
  }
}
