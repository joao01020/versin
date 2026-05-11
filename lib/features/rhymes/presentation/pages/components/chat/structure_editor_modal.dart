import 'package:flutter/material.dart';

class StructureEditorModal {
  static void show({
    required BuildContext context,
    required String initialStructure,
    required Color activeColor,
    required Function(String) onSave,
    required Function(List<String>) onSendToChat,
    required Function(String title, List<String> options, Function(String) onSelect) showQuickMenu,
  }) {
    List<String> estruturaLista = initialStructure.split(', ').where((s) => s.isNotEmpty).toList();
    if (estruturaLista.isEmpty) estruturaLista = ["Intro", "Verso 1", "Refrão", "Verso 2", "Final"];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Organizar Estrutura", style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text("Arraste os itens para mudar a ordem da letra", style: TextStyle(color: Colors.white24, fontSize: 11)),
                  const SizedBox(height: 15),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                    child: ReorderableListView(
                      shrinkWrap: true,
                      children: [
                        for (int i = 0; i < estruturaLista.length; i++)
                          ListTile(
                            key: ValueKey("$i-${estruturaLista[i]}"),
                            leading: Icon(Icons.drag_handle_rounded, color: activeColor.withOpacity(0.5)),
                            title: Text(estruturaLista[i], style: const TextStyle(color: Colors.white, fontSize: 14)),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.white10, size: 18),
                              onPressed: () => setModalState(() => estruturaLista.removeAt(i)),
                            ),
                          ),
                      ],
                      onReorder: (oldIdx, newIdx) {
                        setModalState(() {
                          if (newIdx > oldIdx) newIdx -= 1;
                          final item = estruturaLista.removeAt(oldIdx);
                          estruturaLista.insert(newIdx, item);
                        });
                      },
                    ),
                  ),
                  const Divider(color: Colors.white10),
                  TextButton.icon(
                    onPressed: () {
                      showQuickMenu("Adicionar Bloco", ["Intro", "Verso", "Refrão", "Ponte", "Solo", "Final"], (val) {
                        setModalState(() => estruturaLista.add(val));
                      });
                    },
                    icon: Icon(Icons.add, color: activeColor, size: 18),
                    label: Text("ADICIONAR BLOCO", style: TextStyle(color: activeColor)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: activeColor),
                            onPressed: () {
                              onSave(estruturaLista.join(', '));
                              Navigator.pop(context);
                            },
                            child: const Text("SALVAR NOVA ORDEM", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: activeColor.withOpacity(0.5)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {
                              onSendToChat(estruturaLista);
                              Navigator.pop(context);
                            },
                            child: const Text("ENVIAR PARA O CHAT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}