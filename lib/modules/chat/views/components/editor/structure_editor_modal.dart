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
    List<String> estruturaLista = initialStructure
        .split(', ')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
        
    if (estruturaLista.isEmpty) {
      estruturaLista = ["Intro", "Verso 1", "Refrão", "Verso 2", "Final"];
    }

    final List<String> blocosDisponiveis = ["Intro", "Verso", "Refrão", "Ponte", "Solo", "Hook", "Outro"];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF110E26),
      isScrollControlled: true,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFF110E26),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
              ),
              padding: EdgeInsets.fromLTRB(
                16, 
                12, 
                16, 
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  const Text(
                    "Estrutura do Beat",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Arraste para reordenar os blocks do seu som",
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  const SizedBox(height: 20),

                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.35),
                    child: Theme(
                      data: ThemeData(canvasColor: Colors.transparent),
                      child: ReorderableListView(
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        children: [
                          for (int i = 0; i < estruturaLista.length; i++)
                            Container(
                              key: ValueKey("$i-${estruturaLista[i]}"),
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.03),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withOpacity(0.05)),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                                leading: Icon(Icons.drag_indicator_rounded, color: activeColor.withOpacity(0.6), size: 20),
                                title: Text(
                                  estruturaLista[i],
                                  // CORREÇÃO: Removido o caractere fantasma e aplicado branco com opacidade estável
                                  style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.close_rounded, color: Colors.white38, size: 18),
                                  onPressed: () => setModalState(() => estruturaLista.removeAt(i)),
                                  hoverColor: Colors.redAccent.withOpacity(0.1),
                                  splashRadius: 20,
                                ),
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
                  ),
                  
                  const SizedBox(height: 16),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Injetar novo bloco:",
                      style: TextStyle(color: Colors.white30, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 8),

                  SizedBox(
                    height: 34,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: blocosDisponiveis.length,
                      itemBuilder: (context, index) {
                        final bloco = blocosDisponiveis[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ActionChip(
                            backgroundColor: Colors.white.withOpacity(0.04),
                            side: BorderSide(color: Colors.white.withOpacity(0.06)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            label: Text(bloco, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            onPressed: () {
                              final contagem = estruturaLista.where((b) => b.startsWith(bloco)).length;
                              final nomeFinal = contagem > 0 ? "$bloco ${contagem + 1}" : bloco;
                              setModalState(() => estruturaLista.add(nomeFinal));
                            },
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Divider(color: Colors.white10, height: 1),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: activeColor.withOpacity(0.4)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () {
                            onSendToChat(estruturaLista);
                            Navigator.pop(context);
                          },
                          child: const Text(
                            "Enviar pro Chat",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: activeColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 8,
                            shadowColor: activeColor.withOpacity(0.3),
                          ),
                          onPressed: () {
                            onSave(estruturaLista.join(', '));
                            Navigator.pop(context);
                          },
                          child: const Text(
                            "Salvar Arranjo",
                            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ),
                    ],
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