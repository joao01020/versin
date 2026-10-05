import 'dart:async';

import 'package:flutter/material.dart';

import 'package:versin/modules/storage/data/models/stored_work_model.dart';

abstract final class StorageWorkActionsSheet {
  static Future<void> show({
    required BuildContext context,
    required StoredWorkModel work,
    required Color accentColor,
    required Color surfaceColor,
    required VoidCallback onOpenDetails,
    required VoidCallback onVerifyHash,
    required Future<void> Function() onTransferAuthorship,
    required Future<void> Function() onDelete,
  }) {
    final isBeat = work.type == StoredWorkType.beat;

    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ActionTile(
                  icon: Icons.visibility_outlined,
                  title: 'Ver detalhes',
                  color: accentColor,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    onOpenDetails();
                  },
                ),
                _ActionTile(
                  icon: Icons.verified_outlined,
                  title: 'Verificar hash',
                  color: accentColor,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    onVerifyHash();
                  },
                ),
                _ActionTile(
                  icon: Icons.swap_horiz_rounded,
                  title: 'Transferir autoria',
                  color: accentColor,
                  onTap: () {
                    Navigator.of(sheetContext).pop();

                    unawaited(onTransferAuthorship());
                  },
                ),
                const Divider(color: Colors.white10),
                _ActionTile(
                  icon: Icons.delete_outline_rounded,
                  title: isBeat ? 'Apagar beat' : 'Apagar letra',
                  color: Colors.redAccent,
                  onTap: () {
                    Navigator.of(sheetContext).pop();

                    unawaited(onDelete());
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(
          color: color == Colors.redAccent ? Colors.redAccent : Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
