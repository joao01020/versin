import 'package:flutter/material.dart';

class StructureEditorModal {
  static void show({
    required BuildContext context,
    required String initialStructure,
    required Color activeColor,
    required ValueChanged<
      String
    >
    onSave,
    required ValueChanged<
      List<
        String
      >
    >
    onSendToChat,
    required void Function(
      String title,
      List<
        String
      >
      options,
      ValueChanged<
        String
      >
      onSelect,
    )
    showQuickMenu,
  }) {
    List<
      String
    >
    structure = initialStructure
        .split(
          ', ',
        )
        .where(
          (
            item,
          ) => item.isNotEmpty,
        )
        .toList();

    if (structure.isEmpty) {
      structure = [
        'Intro',
        'Verso 1',
        'Refrão',
        'Verso 2',
        'Final',
      ];
    }

    showModalBottomSheet<
      void
    >(
      context: context,
      backgroundColor: const Color(
        0xFF1A1A1A,
      ),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(
            20,
          ),
        ),
      ),
      builder:
          (
            sheetContext,
          ) {
            return StatefulBuilder(
              builder:
                  (
                    context,
                    setModalState,
                  ) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Organizar Estrutura',
                            style: TextStyle(
                              color: Colors.white54,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          const Text(
                            'Arraste os itens para mudar a ordem da letra',
                            style: TextStyle(
                              color: Colors.white24,
                              fontSize: 11,
                            ),
                          ),

                          const SizedBox(
                            height: 15,
                          ),

                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight:
                                  MediaQuery.sizeOf(
                                    context,
                                  ).height *
                                  0.4,
                            ),
                            child: ReorderableListView(
                              shrinkWrap: true,
                              children: [
                                for (
                                  int i = 0;
                                  i <
                                      structure.length;
                                  i++
                                )
                                  ListTile(
                                    key: ValueKey(
                                      '$i-${structure[i]}',
                                    ),
                                    leading: Icon(
                                      Icons.drag_handle_rounded,
                                      color: activeColor.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                    title: Text(
                                      structure[i],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                        color: Colors.white10,
                                        size: 18,
                                      ),
                                      onPressed: () {
                                        setModalState(
                                          () {
                                            structure.removeAt(
                                              i,
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),
                              ],
                              onReorder:
                                  (
                                    oldIndex,
                                    newIndex,
                                  ) {
                                    setModalState(
                                      () {
                                        if (newIndex >
                                            oldIndex) {
                                          newIndex--;
                                        }

                                        final item = structure.removeAt(
                                          oldIndex,
                                        );
                                        structure.insert(
                                          newIndex,
                                          item,
                                        );
                                      },
                                    );
                                  },
                            ),
                          ),

                          const Divider(
                            color: Colors.white10,
                          ),

                          TextButton.icon(
                            onPressed: () {
                              showQuickMenu(
                                'Adicionar Bloco',
                                const [
                                  'Intro',
                                  'Verso',
                                  'Refrão',
                                  'Ponte',
                                  'Solo',
                                  'Final',
                                ],
                                (
                                  value,
                                ) {
                                  setModalState(
                                    () {
                                      structure.add(
                                        value,
                                      );
                                    },
                                  );
                                },
                              );
                            },
                            icon: Icon(
                              Icons.add,
                              color: activeColor,
                              size: 18,
                            ),
                            label: Text(
                              'ADICIONAR BLOCO',
                              style: TextStyle(
                                color: activeColor,
                              ),
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: activeColor,
                                    ),
                                    onPressed: () {
                                      onSave(
                                        structure.join(
                                          ', ',
                                        ),
                                      );

                                      Navigator.pop(
                                        sheetContext,
                                      );
                                    },
                                    child: const Text(
                                      'SALVAR NOVA ORDEM',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(
                                  height: 10,
                                ),

                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                        color: activeColor.withValues(
                                          alpha: 0.5,
                                        ),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          8,
                                        ),
                                      ),
                                    ),
                                    onPressed: () {
                                      onSendToChat(
                                        List<
                                          String
                                        >.from(
                                          structure,
                                        ),
                                      );

                                      Navigator.pop(
                                        sheetContext,
                                      );
                                    },
                                    child: const Text(
                                      'ENVIAR PARA O CHAT',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
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
