import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:versin/features/rimas/presentation/controller/rimas_controller.dart';
import 'package:versin/core/models/rima_model.dart';

class VocabularioPage extends StatefulWidget {
  final RimasController controller;
  const VocabularioPage({super.key, required this.controller});

  @override
  State<VocabularioPage> createState() => _VocabularioPageState();
}

class _VocabularioPageState extends State<VocabularioPage> {
  final _textController = TextEditingController();
  bool _proximaEhPrioridade = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  // --- LÓGICA: IMPORTAR ARQUIVO DE BLOCO DE NOTAS (.txt) ---
  Future<void> _importarArquivoTxt() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'], // RESTRITO: Só aceita bloco de notas
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final String conteudo = await file.readAsString();
        
        // Separa as rimas por linha ou por vírgula
        final List<String> rimasImportadas = conteudo.split(RegExp(r'[,\n]'));
        
        int contagem = 0;
        for (var rima in rimasImportadas) {
          String rimaLimpa = rima.trim();
          if (rimaLimpa.isNotEmpty) {
            widget.controller.adicionarPalavra(rimaLimpa, false);
            contagem++;
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Sucesso! $contagem rimas adicionadas.")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erro ao ler o arquivo de rimas.")),
        );
      }
    }
  }

  // --- LÓGICA: EXPORTAR PARA BLOCO DE NOTAS ---
  Future<void> _exportarParaTxt() async {
    try {
      final Directory? downloadsDir = await getDownloadsDirectory();
      if (downloadsDir == null) return;

      final String path = "${downloadsDir.path}/vocabulario_versin.txt";
      final File file = File(path);

      // Organiza o texto: Prioridades no topo
      String output = "--- PRIORIDADE MÁXIMA ---\n";
      output += widget.controller.vocabulario
          .where((r) => r.isPrioridade)
          .map((r) => r.palavra)
          .join("\n");
      
      output += "\n\n--- LISTA TOTAL ---\n";
      output += widget.controller.vocabulario
          .where((r) => !r.isPrioridade)
          .map((r) => r.palavra)
          .join("\n");

      await file.writeAsString(output);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Arquivo salvo em: $path"), duration: const Duration(seconds: 4)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erro ao exportar arquivo.")),
        );
      }
    }
  }

  Widget _buildSectionHeader(String title, String description, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt, color: color, size: 20),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 4),
          Text(description, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text("Gestão de Flow", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file, color: Colors.cyanAccent),
            tooltip: "Importar .txt",
            onPressed: _importarArquivoTxt,
          ),
          IconButton(
            icon: const Icon(Icons.download_for_offline, color: Colors.greenAccent),
            tooltip: "Exportar .txt",
            onPressed: _exportarParaTxt,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Nova rima...",
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFF1A1A1A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.star, color: _proximaEhPrioridade ? Colors.yellow : Colors.grey, size: 28),
                  onPressed: () => setState(() => _proximaEhPrioridade = !_proximaEhPrioridade),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purpleAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  onPressed: () {
                    if (_textController.text.isNotEmpty) {
                      widget.controller.adicionarPalavra(_textController.text, _proximaEhPrioridade);
                      _textController.clear();
                      setState(() => _proximaEhPrioridade = false);
                    }
                  },
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: widget.controller,
              builder: (context, _) {
                final prioridades = widget.controller.vocabulario.where((r) => r.isPrioridade).toList();
                final gerais = widget.controller.vocabulario.where((r) => !r.isPrioridade).toList();

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: _buildSectionHeader("PRIORIDADE MÁXIMA", "Rimas que o Versin buscará primeiro.", Colors.orangeAccent),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildRimaTile(prioridades[index]),
                        childCount: prioridades.length,
                      ),
                    ),
                    const SliverToBoxAdapter(child: Divider(color: Colors.white10, height: 40)),
                    SliverToBoxAdapter(
                      child: _buildSectionHeader("LISTA TOTAL", "Seu banco de dados geral.", Colors.purpleAccent),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildRimaTile(gerais[index]),
                        childCount: gerais.length,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRimaTile(Rima rima) {
    final int realIndex = widget.controller.vocabulario.indexOf(rima);
    return ListTile(
      leading: Icon(Icons.music_note, color: rima.isPrioridade ? Colors.orangeAccent : Colors.grey),
      title: Text(rima.palavra, style: const TextStyle(color: Colors.white, fontSize: 16)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(rima.isPrioridade ? Icons.star : Icons.star_border, color: rima.isPrioridade ? Colors.yellow : Colors.grey),
            onPressed: () => widget.controller.alternarPrioridade(realIndex),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => widget.controller.removerPalavra(realIndex),
          ),
        ],
      ),
    );
  }
}