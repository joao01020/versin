import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:versin/features/rhymes/presentation/controller/rhymes_controller.dart';
import 'package:versin/core/models/rhyme_model.dart';

class VocabularioPage extends StatefulWidget {
  final RhymesController controller;
  const VocabularioPage({super.key, required this.controller});

  @override
  State<VocabularioPage> createState() => PageVocabulary();
}

class PageVocabulary extends State<VocabularioPage> {
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  // --- LÓGICA: IMPORTAR ARQUIVO (.txt ou .md) ---
  Future<void> _importFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'md'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final String content = await file.readAsString();
        final List<String> importedRhymes = content.split(RegExp(r'[,\n;]'));

        int count = 0;
        for (var rhyme in importedRhymes) {
          String cleanRhyme = rhyme.trim().toLowerCase();
          if (cleanRhyme.isNotEmpty) {
            widget.controller.addWord(cleanRhyme, false);
            count++;
          }
        }
        if (mounted) _showSnackBar("Sucesso! $count rimas importadas.", Colors.purpleAccent);
      }
    } catch (e) {
      if (mounted) _showSnackBar("Erro ao ler o arquivo.", Colors.redAccent);
    }
  }

  // --- LÓGICA: EXPORTAR PARA BACKUP ---
  Future<void> _exportToTxt() async {
    try {
      final Directory? downloadsDir = await getDownloadsDirectory();
      if (downloadsDir == null) return;

      final String path = "${downloadsDir.path}/versin_backup_${DateTime.now().millisecondsSinceEpoch}.txt";
      final File file = File(path);

      StringBuffer buffer = StringBuffer();
      buffer.writeln("--- BACKUP VERSIN: VOCABULÁRIO ---\n");
      for (var rhyme in widget.controller.vocabulary) {
        buffer.writeln(rhyme.word);
      }

      await file.writeAsString(buffer.toString());
      if (mounted) _showSnackBar("Arquivo salvo em: $path", Colors.greenAccent);
    } catch (e) {
      if (mounted) _showSnackBar("Erro na exportação.", Colors.redAccent);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        content: Text(message, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _confirmAddition() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      widget.controller.addWord(text, false);
      _textController.clear();
      FocusScope.of(context).unfocus(); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_for_offline, color: Colors.white24),
            onPressed: _exportToTxt,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // CABEÇALHO E ÁREA DE IMPORTAÇÃO ROXA
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const Text(
                  "BIBLIOTECA DE RIMAS",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 24),
                
                // ÁREA DE IMPORTAÇÃO EM ROXO
                GestureDetector(
                  onTap: _importFile,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    decoration: BoxDecoration(
                      color: Colors.purpleAccent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.purpleAccent.withOpacity(0.4),
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
                        const SizedBox(height: 12),
                        const Text(
                          "IMPORTAR BANCO DE RIMAS",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Clique aqui para enviar .txt ou .md",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
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

          // LISTA DE RIMAS
          Expanded(
            child: ListenableBuilder(
              listenable: widget.controller,
              builder: (context, _) {
                final vocab = widget.controller.vocabulary;
                if (vocab.isEmpty) {
                  return Center(
                    child: Text(
                      "Sua lista está vazia.",
                      style: TextStyle(color: Colors.white.withOpacity(0.1)),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 20, bottom: 130),
                  itemCount: vocab.length,
                  itemBuilder: (context, index) => _buildRhymeTile(vocab[index], index),
                );
              },
            ),
          ),

          // ÁREA DE INPUT FIXA NA BASE
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 16,
        left: 16,
        right: 16,
        top: 12,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF141414),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text(
                "+ ADICIONAR À LISTA",
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _textController,
              onSubmitted: (_) => _confirmAddition(),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Digite uma nova rima...",
                hintStyle: TextStyle(color: Colors.white24, fontSize: 14),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRhymeTile(Rhyme rhyme, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        title: Text(
          rhyme.word,
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: Colors.white.withOpacity(0.1), size: 20),
          onPressed: () => widget.controller.removeWord(index),
        ),
      ),
    );
  }
}