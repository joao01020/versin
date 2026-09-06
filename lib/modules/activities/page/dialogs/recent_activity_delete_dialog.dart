import 'package:flutter/material.dart';

import 'package:versin/modules/activities/models/recent_activity_model.dart';

abstract final class RecentActivityDeleteDialog {
  static Future<bool> show({
    required BuildContext context,
    required RecentActivityModel activity,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF17132D),
          title: const Text(
            'Excluir atividade?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            activity.title,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('CANCELAR'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text(
                'EXCLUIR',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );

    return result == true;
  }
}
