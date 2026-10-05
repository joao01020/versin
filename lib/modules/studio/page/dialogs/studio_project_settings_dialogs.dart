import 'package:flutter/material.dart';

// ============================================================
// STUDIO PROJECT SETTINGS DIALOGS
// ============================================================

class StudioProjectSettingsDialogs {
  const StudioProjectSettingsDialogs._();

  static Future<String?> editTitle({
    required BuildContext context,
    required String currentTitle,
    required Color activeColor,
  }) async {
    final textController = TextEditingController(text: currentTitle);

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Nome da Música',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: textController,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
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
                Navigator.of(dialogContext).pop(textController.text.trim());
              },
              child: Text('SALVAR', style: TextStyle(color: activeColor)),
            ),
          ],
        );
      },
    );

    textController.dispose();

    final normalized = result?.trim();

    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    return normalized;
  }

  static Future<int?> editBpm({
    required BuildContext context,
    required int currentBpm,
    required Color activeColor,
  }) async {
    final textController = TextEditingController(text: currentBpm.toString());

    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text('BPM', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: textController,
            autofocus: true,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(hintText: '120'),
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
                Navigator.of(
                  dialogContext,
                ).pop(int.tryParse(textController.text));
              },
              child: Text('SALVAR', style: TextStyle(color: activeColor)),
            ),
          ],
        );
      },
    );

    textController.dispose();

    if (result == null || result <= 0) {
      return null;
    }

    return result;
  }
}
