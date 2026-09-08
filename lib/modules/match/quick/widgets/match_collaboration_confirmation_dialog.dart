import 'package:flutter/material.dart';

/// Confirma a decisão calculada pelo servidor, sem decidir pelo cliente.
abstract final class MatchCollaborationConfirmationDialog {
  static Future<bool> show({
    required BuildContext context,
    required Map<String, dynamic> preview,
  }) async {
    final members = (preview['member_count'] as num?)?.toInt() ?? 0;
    final hasWork = preview['has_work'] == true;
    final canFinish = preview['can_finish'] == true;
    final leaveOnly = preview['action'] == 'leave';
    final reason = preview['reason']?.toString() ?? '';
    final title = leaveOnly
        ? 'Sair desta Studio Session?'
        : hasWork
            ? 'Encerrar esta colaboração?'
            : 'Encerrar esta conexão?';
    final fallbackDescription = leaveOnly
        ? 'Apenas você sairá. Os demais participantes continuarão no projeto.'
        : hasWork
            ? 'O projeto será encerrado para ambos e deixará de aparecer nos '
                'projetos ativos. O histórico e as contribuições serão preservados.'
            : 'Esta tentativa será encerrada para ambos e deixará de aparecer '
                'nos projetos ativos. O tempo restante do Agora poderá ser retomado.';
    final description = reason.isNotEmpty ? reason : fallbackDescription;
    var confirmed = false;
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
              backgroundColor: const Color(0xFF17171E),
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(description),

                  if (canFinish) ...[
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      value: confirmed,
                      onChanged: (value) => setDialogState(
                        () => confirmed = value ?? false,
                      ),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text('Estou ciente e quero continuar.',
                        style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancelar'),
                ),
                if (canFinish)
                  FilledButton(
                    onPressed: confirmed
                        ? () => Navigator.pop(dialogContext, true)
                        : null,
                    child: Text(leaveOnly ? 'Sair do projeto' : 'Encerrar colaboração'),
                  ),
              ],
            ),
          ),
        ) ?? false;
  }
}
