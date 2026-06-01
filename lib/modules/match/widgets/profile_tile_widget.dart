import 'package:flutter/material.dart';
// EN: Updated import to match your physical plural filename
// PT: Atualizado o import para bater com o seu arquivo físico no plural
import '../controllers/match_controllers.dart';
import '../models/match_user_entity.dart';

class ProfileTileWidget extends StatelessWidget {
  final MatchUserEntity user;
  final MatchController controller;

  const ProfileTileWidget({
    super.key,
    required this.user,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: controller.primaryPurple,
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '', 
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                ),
              ),
              if (user.isOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: controller.accentNeon, 
                      shape: BoxShape.circle, 
                      border: Border.all(color: Colors.black, width: 2)
                    ),
                  ),
                )
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(user.bio, style: const TextStyle(color: Colors.white38, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: user.tags.map((tag) => Text(
                    "#$tag", 
                    // EN: Fixed invalid w640 to valid w600 weight
                    // PT: Corrigido o peso inválido w640 para o peso válido w600
                    style: TextStyle(color: controller.accentNeon, fontSize: 10, fontWeight: FontWeight.w600)
                  )).toList(),
                )
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios, color: Colors.white12, size: 14),
        ],
      ),
    );
  }
}