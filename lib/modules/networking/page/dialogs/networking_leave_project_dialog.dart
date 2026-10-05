import 'package:flutter/material.dart';
import 'package:versin/modules/match/quick/widgets/match_collaboration_confirmation_dialog.dart';

abstract final class NetworkingLeaveProjectDialog {
  static Future<bool> show({
    required BuildContext context,
    Map<String, dynamic>? preview,
  }) async {
    if (preview != null) {
      return MatchCollaborationConfirmationDialog.show(
        context: context, preview: preview,
      );
    }
    var confirmed = false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF17171E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Row(
                children: [
                  Icon(Icons.logout_rounded, color: Colors.redAccent, size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Sair desta Studio Session?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ao continuar, você deixará de fazer parte '
                    'deste projeto e ele não aparecerá mais entre '
                    'os seus projetos ativos.',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.redAccent.withValues(alpha: 0.14),
                      ),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: Colors.redAccent,
                          size: 17,
                        ),
                        SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            'Você perderá o acesso à sessão, '
                            'ao chat, às tarefas e aos recursos '
                            'compartilhados deste projeto.',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 10,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  CheckboxListTile(
                    value: confirmed,
                    onChanged: (value) {
                      setDialogState(() {
                        confirmed = value ?? false;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: Colors.redAccent,
                    title: const Text(
                      'Estou ciente e quero sair deste projeto.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(false);
                  },
                  child: const Text('Cancelar'),
                ),
                FilledButton.icon(
                  onPressed: confirmed
                      ? () {
                          Navigator.of(dialogContext).pop(true);
                        }
                      : null,
                  icon: const Icon(Icons.logout_rounded, size: 16),
                  label: const Text('Sair do projeto'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.white12,
                    disabledForegroundColor: Colors.white24,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    return result == true;
  }
}
