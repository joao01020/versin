import 'package:flutter/material.dart';

import 'package:versin/modules/studio/models/mind_map_node.dart';

// ============================================================
// ADD MIND MAP NODE DIALOG
// ============================================================

class StudioMindMapNodeDraft {
  final String text;
  final MindMapNodeType type;

  const StudioMindMapNodeDraft({required this.text, required this.type});
}

class StudioAddMindMapNodeDialog {
  const StudioAddMindMapNodeDialog._();

  static Future<StudioMindMapNodeDraft?> show({
    required BuildContext context,
    required Color activeColor,
  }) async {
    final textController = TextEditingController();

    var selectedType = MindMapNodeType.idea;

    final result = await showDialog<StudioMindMapNodeDraft>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1A1A),
              title: const Text(
                'Adicionar ao Mapa',
                style: TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: textController,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Ex: madrugada, saudade, reflexo...',
                      hintStyle: TextStyle(color: Colors.white30),
                    ),
                  ),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<MindMapNodeType>(
                    initialValue: selectedType,
                    dropdownColor: const Color(0xFF1A1A1A),
                    decoration: const InputDecoration(
                      labelText: 'Tipo',
                      labelStyle: TextStyle(color: Colors.white54),
                    ),
                    style: const TextStyle(color: Colors.white),
                    items: MindMapNodeType.values.map((type) {
                      return DropdownMenuItem<MindMapNodeType>(
                        value: type,
                        child: Text(_labelForType(type)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }

                      setDialogState(() {
                        selectedType = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('CANCELAR'),
                ),
                TextButton(
                  onPressed: () {
                    final text = textController.text.trim();

                    if (text.isEmpty) {
                      return;
                    }

                    Navigator.of(dialogContext).pop(
                      StudioMindMapNodeDraft(text: text, type: selectedType),
                    );
                  },
                  child: Text(
                    'ADICIONAR',
                    style: TextStyle(color: activeColor),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    textController.dispose();

    return result;
  }

  static String _labelForType(MindMapNodeType type) {
    switch (type) {
      case MindMapNodeType.idea:
        return 'Ideia';
      case MindMapNodeType.scene:
        return 'Cena';
      case MindMapNodeType.emotion:
        return 'Emoção';
      case MindMapNodeType.image:
        return 'Imagem';
      case MindMapNodeType.rhyme:
        return 'Rima';
      case MindMapNodeType.concept:
        return 'Conceito';
    }
  }
}
