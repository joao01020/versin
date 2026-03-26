import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:versin/features/rimas/presentation/controller/rhymes_controller.dart';
import 'package:versin/core/models/rhyme_model.dart';

class VocabularioPage extends StatefulWidget {
  final RhymesController controller;
  const VocabularioPage({super.key, required this.controller});

  @override
  State<VocabularioPage> createState() => PageVocabulary();
}

class PageVocabulary extends State<VocabularioPage> {
  final _textController = TextEditingController();
  bool _isNextPriority = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  // --- LÓGICA: IMPORTAR ARQUIVO DE BLOCO DE NOTAS (.txt) ---
  Future<void> _importTxtFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final String content = await file.readAsString();
        
        // Suporta separação por vírgula, ponto e vírgula ou nova linha
        final List<String> importedRhymes = content.split(RegExp(r'[,\n;]'));
        
        int count = 0;
        for (var rhyme in importedRhymes) {
          String cleanRhyme = rhyme.trim().toLowerCase();
          if (cleanRhyme.isNotEmpty) {
            widget.controller.addWord(cleanRhyme, false);
            count++;
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.cyanAccent,
              content: Text("Sucesso! $count rimas integradas ao Versin.", 
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erro ao ler o arquivo. Verifique o formato.")),
        );
      }
    }
  }

  // --- LÓGICA: EXPORTAR PARA BLOCO DE NOTAS ---
  Future<void> _exportToTxt() async {
    try {
      final Directory? downloadsDir = await getDownloadsDirectory();
      if (downloadsDir == null) return;

      final String path = "${downloadsDir.path}/versin_backup_${DateTime.now().millisecondsSinceEpoch}.txt";
      final File file = File(path);

      StringBuffer buffer = StringBuffer();
      buffer.writeln("--- BACKUP VERSIN: VOCABULÁRIO ---");
      buffer.writeln("Exportado em: ${DateTime.now()}\n");
      
      for (var rhyme in widget.controller.vocabulary) {
        buffer.writeln("${rhyme.word}${rhyme.isPriority ? ' [PRIORIDADE]' : ''}");
      }

      await file.writeAsString(buffer.toString());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.greenAccent,
            content: Text("Arquivo salvo: $path"), 
            duration: const Duration(seconds: 5)
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erro na exportação.")),
        );
      }
    }
  }

  Widget _buildSectionHeader(String title, String description, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 4, height: 18, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 10),
              Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.2)),
            ],
          ),
          const SizedBox(height: 4),
          Text(description, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text("BIBLIOTECA DE RIMAS", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.upload_file, color: Colors.cyanAccent), onPressed: _importTxtFile),
          IconButton(icon: const Icon(Icons.download_for_offline, color: Colors.greenAccent), onPressed: _exportToTxt),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildInputArea(),
          Expanded(
            child: ListenableBuilder(
              listenable: widget.controller,
              builder: (context, _) {
                final vocab = widget.controller.vocabulary;
                
                if (vocab.isEmpty) {
                  return const Center(child: Text("Sua biblioteca está vazia.\nImporte um .txt ou adicione rimas!", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)));
                }

                final priorities = vocab.where((r) => r.isPriority).toList();
                final general = vocab.where((r) => !r.isPriority).toList();

                return CustomScrollView(
                  slivers: [
                    if (priorities.isNotEmpty) ...[
                      SliverToBoxAdapter(child: _buildSectionHeader("PRIORIDADE MÁXIMA", "O Versin prioriza estas rimas no balão de sugestão.", Colors.orangeAccent)),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildRhymeTile(priorities[index]),
                          childCount: priorities.length,
                        ),
                      ),
                    ],
                    if (general.isNotEmpty) ...[
                      SliverToBoxAdapter(child: _buildSectionHeader("DICIONÁRIO GERAL", "Banco de dados secundário para expansão de vocabulário.", Colors.purpleAccent)),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildRhymeTile(general[index]),
                          childCount: general.length,
                        ),
                      ),
                    ],
                    const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          IconButton(
            icon: Icon(_isNextPriority ? Icons.star : Icons.star_border, color: _isNextPriority ? Colors.yellow : Colors.grey),
            onPressed: () => setState(() => _isNextPriority = !_isNextPriority),
          ),
          Expanded(
            child: TextField(
              controller: _textController,
              style: const TextStyle(color: Colors.white),
              onSubmitted: (_) => _confirmAddition(),
              decoration: const InputDecoration(hintText: "Adicionar rima ao banco...", hintStyle: TextStyle(color: Colors.grey, fontSize: 14), border: InputBorder.none),
            ),
          ),
          IconButton(icon: const Icon(Icons.add_circle, color: Colors.purpleAccent, size: 30), onPressed: _confirmAddition),
        ],
      ),
    );
  }

  void _confirmAddition() {
    if (_textController.text.isNotEmpty) {
      widget.controller.addWord(_textController.text, _isNextPriority);
      _textController.clear();
      setState(() => _isNextPriority = false);
    }
  }

  Widget _buildRhymeTile(Rhyme rhyme) {
    final int realIndex = widget.controller.vocabulary.indexWhere((element) => element.word == rhyme.word);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        title: Text(rhyme.word, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(rhyme.isPriority ? Icons.star : Icons.star_border, color: rhyme.isPriority ? Colors.yellow : Colors.white24, size: 20),
              onPressed: () => widget.controller.togglePriority(realIndex),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.redAccent, size: 18),
              onPressed: () => widget.controller.removeWord(realIndex),
            ),
          ],
        ),
      ),
    );
  }
}