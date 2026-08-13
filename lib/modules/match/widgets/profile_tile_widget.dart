import 'package:flutter/material.dart';

import '../controllers/match_controllers.dart';
import '../models/match_user_entity.dart';

// ============================================================
// PROFILE TILE WIDGET
// ============================================================
//
// Card compacto usado na lista de recomendados.
//
// Exibe:
//
// - avatar;
// - nome artístico;
// - username;
// - função principal;
// - bio;
// - tags;
// - profissionais procurados;
// - status online.
//
// ============================================================

class ProfileTileWidget
    extends
        StatelessWidget {
  final MatchUserEntity user;

  final MatchController controller;

  const ProfileTileWidget({
    super.key,
    required this.user,
    required this.controller,
  });

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      padding: const EdgeInsets.all(
        16,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.05,
        ),
        borderRadius: BorderRadius.circular(
          16,
        ),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.05,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ====================================================
          // AVATAR
          // ====================================================
          _buildAvatar(),

          const SizedBox(
            width: 16,
          ),

          // ====================================================
          // CONTEÚDO
          // ====================================================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==================================================
                // NOME
                // ==================================================
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),

                    if (user.isOnline) ...[
                      const SizedBox(
                        width: 6,
                      ),

                      const Text(
                        'ONLINE',
                        style: TextStyle(
                          color: Colors.white24,
                          fontSize: 7,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ],
                ),

                // ==================================================
                // USERNAME
                // ==================================================
                if (user.hasUsername) ...[
                  const SizedBox(
                    height: 2,
                  ),

                  Text(
                    user.usernameLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],

                const SizedBox(
                  height: 4,
                ),

                // ==================================================
                // FUNÇÃO PRINCIPAL
                // ==================================================
                Text(
                  user.primaryRoleLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: controller.accentNeon,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),

                // ==================================================
                // BIO
                // ==================================================
                Text(
                  user.bio.trim().isEmpty
                      ? 'Sem bio informada.'
                      : user.bio,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                  ),
                ),

                // ==================================================
                // QUEM PROCURA
                // ==================================================
                if (user.lookingForRoles.isNotEmpty) ...[
                  const SizedBox(
                    height: 7,
                  ),

                  _buildLookingFor(),
                ],

                // ==================================================
                // TAGS
                // ==================================================
                if (user.tags.isNotEmpty) ...[
                  const SizedBox(
                    height: 7,
                  ),

                  _buildTags(),
                ],
              ],
            ),
          ),

          const SizedBox(
            width: 8,
          ),

          // ====================================================
          // SETA
          // ====================================================
          const Icon(
            Icons.arrow_forward_ios,
            color: Colors.white12,
            size: 14,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // AVATAR
  // ============================================================

  Widget _buildAvatar() {
    final initial = user.name.trim().isNotEmpty
        ? user.name.trim()[0].toUpperCase()
        : user.username.trim().isNotEmpty
        ? user.username.trim()[0].toUpperCase()
        : '?';

    return Stack(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: controller.primaryPurple,
          child: Text(
            initial,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // ======================================================
        // ONLINE
        // ======================================================
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
                border: Border.all(
                  color: Colors.black,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // QUEM PROCURA
  // ============================================================

  Widget _buildLookingFor() {
    final visibleRoles = user.lookingForRoles.take(
      2,
    );

    return Row(
      children: [
        const Icon(
          Icons.person_search_outlined,
          color: Colors.white24,
          size: 12,
        ),

        const SizedBox(
          width: 5,
        ),

        const Text(
          'Procura:',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 9,
          ),
        ),

        const SizedBox(
          width: 5,
        ),

        Expanded(
          child: Text(
            visibleRoles
                .map(
                  (
                    role,
                  ) => role.label,
                )
                .join(
                  ' • ',
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        if (user.lookingForRoles.length >
            2)
          Padding(
            padding: const EdgeInsets.only(
              left: 4,
            ),
            child: Text(
              '+${user.lookingForRoles.length - 2}',
              style: TextStyle(
                color: controller.accentNeon,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // TAGS
  // ============================================================

  Widget _buildTags() {
    final visibleTags = user.tags.take(
      4,
    );

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        ...visibleTags.map(
          (
            tag,
          ) => Text(
            '#$tag',
            style: TextStyle(
              color: controller.accentNeon,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        if (user.tags.length >
            4)
          Text(
            '+${user.tags.length - 4}',
            style: const TextStyle(
              color: Colors.white24,
              fontSize: 9,
            ),
          ),
      ],
    );
  }
}
