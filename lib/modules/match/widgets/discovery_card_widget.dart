import 'package:flutter/material.dart';
import '../controllers/match_controllers.dart';
import '../models/match_user_entity.dart';
import 'action_button_widget.dart';

class DiscoveryCardWidget extends StatelessWidget {
  final MatchController controller;
  final MatchUserEntity user;

  const DiscoveryCardWidget({
    super.key,
    required this.controller,
    required this.user,
  });

  IconData _getConnectionIcon(ConnectionType type) {
    switch (type) {
      case ConnectionType.chat:
        return Icons.chat_bubble_outline;
      case ConnectionType.video:
        return Icons.videocam_outlined;
      case ConnectionType.proximity:
        return Icons.location_on_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final minutes = (controller.remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (controller.remainingSeconds % 60).toString().padLeft(2, '0');

    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.bottomRight,
          colors: [controller.primaryPurple.withOpacity(0.8), Colors.black54],
        ),
        image: DecorationImage(
          image: NetworkImage(user.showcaseMediaUrl.isNotEmpty 
              ? user.showcaseMediaUrl 
              : "https://images.unsplash.com/photo-1514525253361-bee8718a7439?q=80&w=500"),
          fit: BoxFit.cover,
          opacity: 0.4,
        ),
        border: Border.all(color: Colors.white10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      Icon(_getConnectionIcon(user.preferredConnection), color: Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        user.preferredConnection.name.toUpperCase(), 
                        style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.86), borderRadius: BorderRadius.circular(8)),
                  child: Text("$minutes:$seconds", style: TextStyle(color: controller.accentNeon, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Text(
                  user.name,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Icon(Icons.verified, color: controller.accentNeon, size: 18),
              ],
            ),
            Text(
              user.bio,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // EN: Action buttons now linked to controller triggers using the updated onTap parameter
                // PT: Botões de ação agora vinculados aos gatilhos do controller usando o parâmetro onTap atualizado
                ActionButtonWidget(
                  icon: Icons.close, 
                  color: Colors.white24,
                  onTap: () {
                    // PT: Lógica para pular/recusar o card atual e buscar o próximo no pipeline
                    // EN: Logic to skip/decline the current card and fetch the next from pipeline
                  },
                ),
                const SizedBox(width: 12),
                ActionButtonWidget(
                  icon: Icons.favorite, 
                  color: controller.accentNeon,
                  onTap: () {
                    // PT: Dispara a geração de hash de contrato provisório e inicia fluxo de match guiado por IA
                    // EN: Triggers provisional contract hash generation and starts AI-guided match flow
                    final hash = controller.generateProvisionalContractHash("current_user", user.id);
                    debugPrint("Contrato provisório gerado: $hash");
                  },
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () => controller.listenDemo(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: controller.accentNeon,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("OUVIR DEMO", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}