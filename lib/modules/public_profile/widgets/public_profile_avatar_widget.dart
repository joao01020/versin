import 'package:flutter/material.dart';

// ============================================================
// PUBLIC PROFILE AVATAR WIDGET
// ============================================================
//
// Avatar reutilizável do perfil público.
//
// Pode ser usado em:
//
// - header do Match;
// - PublicProfilePage;
// - cards;
// - resultados de pesquisa;
// - recomendações;
// - chat futuramente.
//
// ============================================================

class PublicProfileAvatarWidget extends StatelessWidget {
  final String? avatarUrl;

  final String? displayName;

  final double size;

  final bool showOnlineIndicator;

  final bool isOnline;

  final VoidCallback? onTap;

  final Color accentColor;

  const PublicProfileAvatarWidget({
    super.key,
    this.avatarUrl,
    this.displayName,
    this.size = 42,
    this.showOnlineIndicator = false,
    this.isOnline = false,
    this.onTap,
    this.accentColor = const Color(0xFFE100FF),
  });

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: displayName?.trim().isNotEmpty == true
          ? 'Perfil de ${displayName!.trim()}'
          : 'Perfil',
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ==================================================
            // AVATAR
            // ==================================================
            Container(
              width: size,
              height: size,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: accentColor.withValues(alpha: 0.35)),
              ),
              child: ClipOval(child: _buildAvatar()),
            ),

            // ==================================================
            // ONLINE
            // ==================================================
            if (showOnlineIndicator && isOnline)
              Positioned(
                right: 0,
                bottom: 1,
                child: Container(
                  width: size * 0.25,
                  height: size * 0.25,
                  decoration: BoxDecoration(
                    color: Colors.greenAccent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF0D0B1F),
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // AVATAR
  // ============================================================

  Widget _buildAvatar() {
    final normalizedUrl = avatarUrl?.trim();

    if (normalizedUrl != null && normalizedUrl.isNotEmpty) {
      return Image.network(
        normalizedUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallback();
        },
      );
    }

    return _buildFallback();
  }

  // ============================================================
  // FALLBACK
  // ============================================================

  Widget _buildFallback() {
    return Container(
      color: const Color(0xFF211A3D),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.30,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ============================================================
  // INICIAIS
  // ============================================================

  String get _initials {
    final name = displayName?.trim() ?? '';

    if (name.isEmpty) {
      return '?';
    }

    final parts = name
        .split(RegExp(r'\s+'))
        .where((value) => value.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return '?';
    }

    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
