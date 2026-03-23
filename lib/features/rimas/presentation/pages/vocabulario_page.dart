import 'package:flutter/material.dart';
import 'package:versin/features/rimas/presentation/controller/rimas_controller.dart';

class VocabularioPage extends StatefulWidget {
  final RimasController controller;
  const VocabularioPage({super.key, required this.controller});

  @override
  State<VocabularioPage> createState() => _VocabularioPageState();
}

class _VocabularioPageState extends State<VocabularioPage> {
  final _controller = TextEditingController();
  bool _proximaEhPrioridade = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text("Meu Vocabulário", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Nova rima...",
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFF1A1A1A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.star, color: _proximaEhPrioridade ? Colors.yellow : Colors.grey),
                  onPressed: () => setState(() => _proximaEhPrioridade = !_proximaEhPrioridade),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent),
                  onPressed: () {
                    widget.controller.adicionarPalavra(_controller.text, _proximaEhPrioridade);
                    _controller.clear();
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
                return ListView.builder(
                  itemCount: widget.controller.vocabulario.length,
                  itemBuilder: (context, index) {
                    final rima = widget.controller.vocabulario[index];
                    return ListTile(
                      leading: Icon(Icons.music_note, color: rima.isPrioridade ? Colors.purpleAccent : Colors.grey),
                      title: Text(rima.palavra, style: const TextStyle(color: Colors.white)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.star, color: rima.isPrioridade ? Colors.yellow : Colors.grey),
                            onPressed: () => widget.controller.alternarPrioridade(index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () => widget.controller.removerPalavra(index),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}