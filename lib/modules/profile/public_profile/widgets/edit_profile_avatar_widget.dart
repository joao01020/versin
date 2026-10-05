import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:versin/core/utils/network_image_url_helper.dart';

// ============================================================
// EDIT PROFILE AVATAR WIDGET
// ============================================================
//
// Avatar utilizado durante a edição do perfil.
//
// Responsabilidades:
//
// - mostrar avatar atual;
// - mostrar preview de uma nova imagem;
// - mostrar fallback;
// - permitir selecionar/trocar avatar;
// - mostrar loading.
//
// Não:
//
// - seleciona arquivo;
// - faz upload;
// - acessa Supabase.
//
// ============================================================

class EditProfileAvatarWidget
    extends
        StatelessWidget {
  final String? avatarUrl;

  final Uint8List? previewBytes;

  final String? displayName;

  final bool isLoading;

  final VoidCallback? onTap;

  final double size;

  const EditProfileAvatarWidget({
    super.key,
    this.avatarUrl,
    this.previewBytes,
    this.displayName,
    this.isLoading = false,
    this.onTap,
    this.size = 116,
  });

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Semantics(
      button:
          onTap !=
          null,
      label: 'Alterar foto do perfil',
      child: InkWell(
        onTap: isLoading
            ? null
            : onTap,
        borderRadius: BorderRadius.circular(
          size,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ==================================================
            // AVATAR
            // ==================================================
            Container(
              width: size,
              height: size,
              padding: const EdgeInsets.all(
                3,
              ),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      const Color(
                        0xFFE100FF,
                      ).withValues(
                        alpha: 0.45,
                      ),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: _buildAvatar(),
              ),
            ),

            // ==================================================
            // BOTÃO EDITAR
            // ==================================================
            if (!isLoading)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFFE100FF,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(
                        0xFF15122C,
                      ),
                      width: 3,
                    ),
                  ),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    color: Colors.black,
                    size: 17,
                  ),
                ),
              ),

            // ==================================================
            // LOADING
            // ==================================================
            if (isLoading)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(
                      alpha: 0.55,
                    ),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const SizedBox(
                    width: 25,
                    height: 25,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(
                        0xFFE100FF,
                      ),
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
    // ==========================================================
    // PREVIEW LOCAL
    // ==========================================================

    if (previewBytes !=
            null &&
        previewBytes!.isNotEmpty) {
      return Image.memory(
        previewBytes!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      );
    }

    // ==========================================================
    // URL
    // ==========================================================

    final normalizedUrl = NetworkImageUrlHelper.validUrlOrNull(
      avatarUrl,
    );

    if (normalizedUrl !=
        null) {
      return Image.network(
        normalizedUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder:
            (
              context,
              error,
              stackTrace,
            ) {
              return _buildFallback();
            },
      );
    }

    // ==========================================================
    // FALLBACK
    // ==========================================================

    return _buildFallback();
  }

  // ============================================================
  // FALLBACK
  // ============================================================

  Widget _buildFallback() {
    return Container(
      color: const Color(
        0xFF211A3D,
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(
          color: Colors.white,
          fontSize:
              size *
              0.27,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ============================================================
  // INICIAIS
  // ============================================================

  String get _initials {
    final name =
        displayName?.trim() ??
        '';

    if (name.isEmpty) {
      return '?';
    }

    final parts = name
        .split(
          RegExp(
            r'\s+',
          ),
        )
        .where(
          (
            part,
          ) => part.isNotEmpty,
        )
        .toList();

    if (parts.isEmpty) {
      return '?';
    }

    if (parts.length ==
        1) {
      return parts.first
          .substring(
            0,
            1,
          )
          .toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
