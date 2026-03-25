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
        allowedExtensions: ['txt'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final String conteudo = await file.readAsString();
        
        // Suporta separação por vírgula, ponto e vírgula ou nova linha
        final List<String> rimasImportadas = conteudo.split(RegExp(r'[,\n;]'));
        
        int contagem = 0;
        for (var rima in rimasImportadas) {
          String rimaLimpa = rima.trim().toLowerCase();
          if (rimaLimpa.isNotEmpty) {
            widget.controller.adicionarPalavra(rimaLimpa, false);
            contagem++;
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.cyanAccent,
              content: Text("Sucesso! $contagem rimas integradas ao Versin.", 
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
  Future<void> _exportarParaTxt() async {
    try {
      final Directory? downloadsDir = await getDownloadsDirectory();
      if (downloadsDir == null) return;

      final String path = "${downloadsDir.path}/versin_backup_${DateTime.now().millisecondsSinceEpoch}.txt";
      final File file = File(path);

      StringBuffer buffer = StringBuffer();
      buffer.writeln("--- BACKUP VERSIN: VOCABULÁRIO ---");
      buffer.writeln("Exportado em: ${DateTime.now()}\n");
      
      for (var rima in widget.controller.vocabulario) {
        buffer.writeln("${rima.palavra}${rima.isPrioridade ? ' [PRIORIDADE]' : ''}");
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
          IconButton(icon: const Icon(Icons.upload_file, color: Colors.cyanAccent), onPressed: _importarArquivoTxt),
          IconButton(icon: const Icon(Icons.download_for_offline, color: Colors.greenAccent), onPressed: _exportarParaTxt),
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
                final vocab = widget.controller.vocabulario;
                
                // Se a lista estiver realmente vazia no controller
                if (vocab.isEmpty) {
                  return const Center(child: Text("Sua biblioteca está vazia.\nImporte um .txt ou adicione rimas!", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)));
                }

                final prioridades = vocab.where((r) => r.isPrioridade).toList();
                final gerais = vocab.where((r) => !r.isPrioridade).toList();

                return CustomScrollView(
                  slivers: [
                    if (prioridades.isNotEmpty) ...[
                      SliverToBoxAdapter(child: _buildSectionHeader("PRIORIDADE MÁXIMA", "O Versin prioriza estas rimas no balão de sugestão.", Colors.orangeAccent)),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildRimaTile(prioridades[index]),
                          childCount: prioridades.length,
                        ),
                      ),
                    ],
                    if (gerais.isNotEmpty) ...[
                      SliverToBoxAdapter(child: _buildSectionHeader("DICIONÁRIO GERAL", "Banco de dados secundário para expansão de vocabulário.", Colors.purpleAccent)),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildRimaTile(gerais[index]),
                          childCount: gerais.length,
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
            icon: Icon(_proximaEhPrioridade ? Icons.star : Icons.star_border, color: _proximaEhPrioridade ? Colors.yellow : Colors.grey),
            onPressed: () => setState(() => _proximaEhPrioridade = !_proximaEhPrioridade),
          ),
          Expanded(
            child: TextField(
              controller: _textController,
              style: const TextStyle(color: Colors.white),
              onSubmitted: (_) => _confirmarAdicao(),
              decoration: const InputDecoration(hintText: "Adicionar rima ao banco...", hintStyle: TextStyle(color: Colors.grey, fontSize: 14), border: InputBorder.none),
            ),
          ),
          IconButton(icon: const Icon(Icons.add_circle, color: Colors.purpleAccent, size: 30), onPressed: _confirmarAdicao),
        ],
      ),
    );
  }

  void _confirmarAdicao() {
    if (_textController.text.isNotEmpty) {
      widget.controller.adicionarPalavra(_textController.text, _proximaEhPrioridade);
      _textController.clear();
      setState(() => _proximaEhPrioridade = false);
    }
  }

  Widget _buildRimaTile(Rima rima) {
    // Busca o index real no vocabulário completo para as funções do controller
    final int realIndex = widget.controller.vocabulario.indexWhere((element) => element.palavra == rima.palavra);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        title: Text(rima.palavra, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(rima.isPrioridade ? Icons.star : Icons.star_border, color: rima.isPrioridade ? Colors.yellow : Colors.white24, size: 20),
              onPressed: () => widget.controller.alternarPrioridade(realIndex),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.redAccent, size: 18),
              onPressed: () => widget.controller.removerPalavra(realIndex),
            ),
          ],
        ),
      ),
    );
  }
}