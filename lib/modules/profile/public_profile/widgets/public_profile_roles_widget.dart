import 'package:flutter/material.dart';

import 'package:versin/modules/profile/models/music_role.dart';

// ============================================================
// PUBLIC PROFILE ROLES WIDGET
// ============================================================
//
// Exibe as funções profissionais públicas do usuário.
//
// Exemplo:
//
// [ Produtor ] [ Artista ] [ Compositor ]
//
// Este widget NÃO:
//
// - carrega perfil;
// - acessa controller;
// - altera funções;
// - acessa banco.
//
// ============================================================

class PublicProfileRolesWidget extends StatelessWidget {
  final Iterable<MusicRole> roles;

  final MusicRole? primaryRole;

  final Color accentColor;

  final bool showTitle;

  const PublicProfileRolesWidget({
    super.key,
    required this.roles,
    this.primaryRole,
    this.accentColor = const Color(0xFFE100FF),
    this.showTitle = true,
  });

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final roleList = roles.toList();

    if (roleList.isEmpty && primaryRole == null) {
      return const SizedBox.shrink();
    }

    final normalizedRoles = <MusicRole>{
      if (primaryRole != null) primaryRole!,
      ...roleList,
    }.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ======================================================
        // TÍTULO
        // ======================================================
        if (showTitle) ...[
          const Text(
            'Funções profissionais',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),
        ],

        // ======================================================
        // ROLES
        // ======================================================
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: normalizedRoles.map((role) {
            final isPrimary = role == primaryRole;

            return _RoleChip(
              role: role,
              isPrimary: isPrimary,
              accentColor: accentColor,
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ============================================================
// ROLE CHIP
// ============================================================

class _RoleChip extends StatelessWidget {
  final MusicRole role;

  final bool isPrimary;

  final Color accentColor;

  const _RoleChip({
    required this.role,
    required this.isPrimary,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: isPrimary
            ? accentColor.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPrimary
              ? accentColor.withValues(alpha: 0.30)
              : Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isPrimary) ...[
            Icon(Icons.star_rounded, color: accentColor, size: 13),

            const SizedBox(width: 5),
          ],

          Text(
            role.label,
            style: TextStyle(
              color: isPrimary ? accentColor : Colors.white60,
              fontSize: 10,
              fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
