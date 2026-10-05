import 'package:flutter/material.dart';

import 'package:versin/modules/storage/data/models/stored_work_model.dart';

abstract final class StorageDeleteWorkDialog {
  static Future<bool> show({
    required BuildContext context,
    required StoredWorkModel work,
    required Color surfaceColor,
  }) async {
    final isBeat = work.type == StoredWorkType.beat;

    final type = isBeat ? 'beat' : 'letra';

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Apagar $type?',
            style: const TextStyle(color: Colors.white),
          ),
          content: Text(
            '"${work.title}" será removido do armazenamento. '
            'Esta ação não pode ser desfeita.',
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text(
                'CANCELAR',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.delete_forever_outlined, size: 17),
              label: const Text('APAGAR'),
            ),
          ],
        );
      },
    );

    return result == true;
  }
}
