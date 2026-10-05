import 'package:flutter/material.dart';

enum MatchSoloChoice { find, continueSolo, archive }

abstract final class MatchSoloProjectDialog {
  static Future<MatchSoloChoice> show({
    required BuildContext context,
    required String title,
  }) async {
    return (await showDialog<MatchSoloChoice>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: const Color(0xFF17171E),
            title: const Text(
              'Você está sozinho neste projeto',
              style: TextStyle(fontSize: 16),
            ),
            content: Text(
              'O outro participante saiu de "$title". '
              'O Networking e o conteúdo continuam disponíveis. '
              'Você pode procurar outro colaborador, continuar sozinho '
              'ou arquivar o grupo.',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(dialogContext, MatchSoloChoice.continueSolo),
                child: const Text('Continuar sozinho'),
              ),
              OutlinedButton(
                onPressed: () =>
                    Navigator.pop(dialogContext, MatchSoloChoice.archive),
                child: const Text('Encerrar grupo'),
              ),
              FilledButton(
                onPressed: () =>
                    Navigator.pop(dialogContext, MatchSoloChoice.find),
                child: const Text('Procurar conexão'),
              ),
            ],
          ),
        )) ??
        MatchSoloChoice.continueSolo;
  }
}
