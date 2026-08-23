import 'package:flutter/material.dart';

import '../models/profile_track_model.dart';

// ============================================================
// PROFILE TRACK CARD WIDGET
// ============================================================
//
// Representa uma música publicada no perfil.
//
// Não executa reprodução diretamente.
//
// A página/controller fornece:
//
// - onPlay;
// - onDelete;
// - onEdit.
//
// ============================================================

class ProfileTrackCardWidget extends StatelessWidget {
  final ProfileTrackModel track;

  final bool isOwner;

  final bool isPlaying;

  final bool isLoading;

  final VoidCallback? onPlay;

  final VoidCallback? onDelete;

  final VoidCallback? onEdit;

  const ProfileTrackCardWidget({
    super.key,
    required this.track,
    this.isOwner = false,
    this.isPlaying = false,
    this.isLoading = false,
    this.onPlay,
    this.onDelete,
    this.onEdit,
  });

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPlaying
              ? const Color(0xFFE100FF).withValues(alpha: 0.30)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          // ====================================================
          // PLAY
          // ====================================================
          _buildPlayButton(),

          const SizedBox(width: 12),

          // ====================================================
          // INFORMAÇÕES
          // ====================================================
          Expanded(child: _buildInformation()),

          const SizedBox(width: 12),

          // ====================================================
          // DURAÇÃO
          // ====================================================
          Text(
            track.formattedDuration,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 10,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),

          // ====================================================
          // MENU DO DONO
          // ====================================================
          if (isOwner) ...[const SizedBox(width: 4), _buildOwnerMenu()],
        ],
      ),
    );
  }

  // ============================================================
  // PLAY
  // ============================================================

  Widget _buildPlayButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onPlay,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFE100FF).withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: isLoading
              ? const SizedBox(
                  width: 17,
                  height: 17,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFFE100FF),
                  ),
                )
              : Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: const Color(0xFFE100FF),
                  size: 24,
                ),
        ),
      ),
    );
  }

  // ============================================================
  // INFORMAÇÕES
  // ============================================================

  Widget _buildInformation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          track.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),

        if (_metadata.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            _metadata,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white30, fontSize: 9),
          ),
        ],
      ],
    );
  }

  // ============================================================
  // MENU
  // ============================================================

  Widget _buildOwnerMenu() {
    return PopupMenuButton<_TrackAction>(
      tooltip: 'Opções',
      color: const Color(0xFF211A3D),
      icon: const Icon(
        Icons.more_vert_rounded,
        color: Colors.white38,
        size: 19,
      ),
      onSelected: (action) {
        switch (action) {
          case _TrackAction.edit:
            onEdit?.call();
            break;

          case _TrackAction.delete:
            onDelete?.call();
            break;
        }
      },
      itemBuilder: (context) {
        return [
          if (onEdit != null)
            const PopupMenuItem(
              value: _TrackAction.edit,
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, color: Colors.white54, size: 17),
                  SizedBox(width: 10),
                  Text('Editar', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),

          if (onDelete != null)
            const PopupMenuItem(
              value: _TrackAction.delete,
              child: Row(
                children: [
                  Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.redAccent,
                    size: 17,
                  ),
                  SizedBox(width: 10),
                  Text('Remover', style: TextStyle(color: Colors.redAccent)),
                ],
              ),
            ),
        ];
      },
    );
  }

  // ============================================================
  // METADATA
  // ============================================================

  String get _metadata {
    final values = <String>[];

    final mimeType = track.mimeType?.trim();

    if (mimeType != null && mimeType.isNotEmpty) {
      final format = mimeType.contains('/')
          ? mimeType.split('/').last
          : mimeType;

      values.add(format.toUpperCase());
    }

    if (track.formattedFileSize.isNotEmpty) {
      values.add(track.formattedFileSize);
    }

    return values.join(' • ');
  }
}

// ============================================================
// ACTION
// ============================================================

enum _TrackAction { edit, delete }
