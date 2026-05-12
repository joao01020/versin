import 'package:flutter/material.dart';

class ProjectCheckModal extends StatelessWidget {
  final Map<String, dynamic> projectData;
  final VoidCallback onResume;
  final VoidCallback onDiscard;

  const ProjectCheckModal({
    super.key,
    required this.projectData,
    required this.onResume,
    required this.onDiscard,
  });

  static void show(
    BuildContext context, {
    required Map<String, dynamic> project,
    required VoidCallback onResume,
    required VoidCallback onDiscard,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ProjectCheckModal(
        projectData: project,
        onResume: onResume,
        onDiscard: onDiscard,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0A0A0A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.purpleAccent.withOpacity(0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history_edu_rounded, color: Colors.purpleAccent, size: 48),
            const SizedBox(height: 16),
            const Text(
              "SESSÃO ENCONTRADA",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Você tem um projeto de ${projectData['genre'] ?? 'Trap'} iniciado. Deseja continuar de onde parou?",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white10),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      onDiscard();
                    },
                    child: const Text("NÃO, NOVO", style: TextStyle(color: Colors.white60)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purpleAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      onResume();
                    },
                    child: const Text("SIM, CONTINUAR", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}