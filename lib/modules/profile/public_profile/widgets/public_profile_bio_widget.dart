import 'package:flutter/material.dart';

// ============================================================
// PUBLIC PROFILE BIO WIDGET
// ============================================================
//
// Exibe a bio pública profissional.
//
// Possui dois estados:
//
// - bio preenchida;
// - bio vazia.
//
// Quando o usuário é dono do perfil, podemos mostrar uma ação
// para adicionar/editar a bio.
//
// ============================================================

class PublicProfileBioWidget extends StatelessWidget {
  final String bio;

  final bool isOwner;

  final VoidCallback? onEdit;

  final int maxLines;

  const PublicProfileBioWidget({
    super.key,
    required this.bio,
    this.isOwner = false,
    this.onEdit,
    this.maxLines = 6,
  });

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final normalizedBio = bio.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ======================================================
        // HEADER
        // ======================================================
        Row(
          children: [
            const Expanded(
              child: Text(
                'Sobre',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            if (isOwner && onEdit != null)
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 14),
                label: const Text('Editar'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFE100FF),
                  textStyle: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 8),

        // ======================================================
        // BIO
        // ======================================================
        if (normalizedBio.isNotEmpty)
          Text(
            normalizedBio,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
              height: 1.55,
            ),
          )
        else
          _buildEmptyBio(),
      ],
    );
  }

  // ============================================================
  // BIO VAZIA
  // ============================================================

  Widget _buildEmptyBio() {
    if (!isOwner) {
      return const Text(
        'Este profissional ainda não adicionou uma bio.',
        style: TextStyle(color: Colors.white30, fontSize: 11, height: 1.5),
      );
    }

    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.025),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: const Row(
          children: [
            Icon(Icons.add_rounded, color: Color(0xFFE100FF), size: 18),

            SizedBox(width: 10),

            Expanded(
              child: Text(
                'Adicione uma bio para contar sobre você e seu trabalho.',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
