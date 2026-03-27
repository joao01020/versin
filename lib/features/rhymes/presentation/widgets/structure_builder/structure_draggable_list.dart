import 'package:flutter/material.dart';

class StructureDraggableList extends StatefulWidget {
  final List<String> initialStructure;
  final Color activeColor;
  final Function(List<String>) onStructureChanged;

  const StructureDraggableList({
    super.key,
    required this.initialStructure,
    required this.activeColor,
    required this.onStructureChanged,
  });

  @override
  State<StructureDraggableList> createState() => _StructureDraggableListState();
}

class _StructureDraggableListState extends State<StructureDraggableList> {
  late List<String> _structure;

  @override
  void initState() {
    super.initState();
    _structure = List.from(widget.initialStructure);
  }

  void _addNewBlock() {
    final TextEditingController _newBlockController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text("Novo Bloco", style: TextStyle(color: widget.activeColor)),
        content: TextField(
          controller: _newBlockController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Ex: Ponte do João",
            hintStyle: TextStyle(color: widget.activeColor.withOpacity(0.5)),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: widget.activeColor)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: widget.activeColor, width: 2)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCELAR", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              if (_newBlockController.text.trim().isNotEmpty) {
                setState(() {
                  _structure.add(_newBlockController.text.trim());
                });
                widget.onStructureChanged(_structure);
                Navigator.pop(context);
              }
            },
            child: Text("ADICIONAR", style: TextStyle(color: widget.activeColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Lista Arrastável
        Container(
          height: 250, // Altura para a área de arraste
          child: ReorderableListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              for (int index = 0; index < _structure.length; index++)
                _buildBlockTile(_structure[index], index),
            ],
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) {
                  newIndex -= 1;
                }
                final String item = _structure.removeAt(oldIndex);
                _structure.insert(newIndex, item);
              });
              widget.onStructureChanged(_structure);
            },
          ),
        ),
        
        // Botão "+" para adicionar novos blocos personalizados
        Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: FloatingActionButton(
            mini: true,
            backgroundColor: widget.activeColor,
            onPressed: _addNewBlock,
            child: const Icon(Icons.add, color: Colors.black),
          ),
        ),
      ],
    );
  }

  Widget _buildBlockTile(String title, int index) {
    // Usamos um ListTile como base, mas com visual de "botão arredondado"
    return Card(
      key: ValueKey('$title$index'), // Chave única para o ReorderableListView
      color: const Color(0xFF1A1A1A),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 3,
      shadowColor: widget.activeColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: widget.activeColor.withOpacity(0.3), width: 0.5),
      ),
      child: ListTile(
        title: Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            fontSize: 13,
          ),
        ),
        trailing: Icon(Icons.drag_handle, color: widget.activeColor),
        onTap: () {
          // Opcional: Permitir renomear ou excluir o bloco ao clicar?
        },
      ),
    );
  }
}