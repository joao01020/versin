import 'package:flutter/material.dart';

import '../models/profile_track_model.dart';
import 'profile_track_card_widget.dart';

// ============================================================
// PUBLIC PROFILE TRACKS WIDGET
// ============================================================
//
// Seção responsável pelas músicas do perfil público.
//
// Responsabilidades:
//
// - exibir título;
// - exibir quantidade de músicas;
// - exibir lista de músicas;
// - exibir estado vazio;
// - permitir adicionar música;
// - encaminhar ações de play;
// - encaminhar ações de edição;
// - encaminhar ações de exclusão.
//
// NÃO:
//
// - acessa Supabase;
// - faz upload;
// - reproduz áudio;
// - remove músicas;
// - possui regra de negócio.
//
// ============================================================

class PublicProfileTracksWidget extends StatelessWidget {
  // ============================================================
  // TRACKS
  // ============================================================

  final List<ProfileTrackModel> tracks;

  // ============================================================
  // USUÁRIO
  // ============================================================

  final bool isOwner;

  // ============================================================
  // ESTADOS
  // ============================================================

  final bool isUploading;

  final String? playingTrackId;

  final String? loadingTrackId;

  // ============================================================
  // CALLBACKS
  // ============================================================

  final VoidCallback? onAddTrack;

  final ValueChanged<ProfileTrackModel>? onPlayTrack;

  final ValueChanged<ProfileTrackModel>? onDeleteTrack;

  final ValueChanged<ProfileTrackModel>? onEditTrack;

  // ============================================================
  // TEMA
  // ============================================================

  final Color accentColor;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  const PublicProfileTracksWidget({
    super.key,
    required this.tracks,
    required this.isOwner,
    this.isUploading = false,
    this.playingTrackId,
    this.loadingTrackId,
    this.onAddTrack,
    this.onPlayTrack,
    this.onDeleteTrack,
    this.onEditTrack,
    this.accentColor = const Color(0xFFE100FF),
  });

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ======================================================
        // HEADER
        // ======================================================
        _buildHeader(),

        const SizedBox(height: 12),

        // ======================================================
        // CONTEÚDO
        // ======================================================
        if (tracks.isEmpty) _buildEmptyState() else _buildTracks(),
      ],
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Row(
      children: [
        // ======================================================
        // TÍTULO
        // ======================================================
        const Expanded(
          child: Text(
            'Músicas',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // ======================================================
        // CONTADOR
        // ======================================================
        if (tracks.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${tracks.length}',
              style: TextStyle(
                color: accentColor,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

        // ======================================================
        // ADICIONAR
        // ======================================================
        if (isOwner) ...[
          const SizedBox(width: 8),

          TextButton.icon(
            onPressed: isUploading ? null : onAddTrack,
            icon: isUploading
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: accentColor,
                    ),
                  )
                : const Icon(Icons.add_rounded, size: 15),
            label: Text(isUploading ? 'Enviando' : 'Adicionar'),
            style: TextButton.styleFrom(
              foregroundColor: accentColor,
              textStyle: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ============================================================
  // LISTA DE MÚSICAS
  // ============================================================

  Widget _buildTracks() {
    return Column(
      children: [
        for (var index = 0; index < tracks.length; index++) ...[
          _buildTrackCard(tracks[index]),

          if (index < tracks.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }

  // ============================================================
  // TRACK CARD
  // ============================================================

  Widget _buildTrackCard(ProfileTrackModel track) {
    return ProfileTrackCardWidget(
      track: track,

      isOwner: isOwner,

      isPlaying: playingTrackId == track.id,

      isLoading: loadingTrackId == track.id,

      // ========================================================
      // PLAY
      // ========================================================
      onPlay: onPlayTrack == null
          ? null
          : () {
              onPlayTrack!(track);
            },

      // ========================================================
      // DELETE
      // ========================================================
      onDelete: onDeleteTrack == null
          ? null
          : () {
              onDeleteTrack!(track);
            },

      // ========================================================
      // EDIT
      // ========================================================
      onEdit: onEditTrack == null
          ? null
          : () {
              onEditTrack!(track);
            },
    );
  }

  // ============================================================
  // ESTADO VAZIO
  // ============================================================

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.025),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          // ====================================================
          // ÍCONE
          // ====================================================
          Icon(
            Icons.library_music_outlined,
            color: accentColor.withValues(alpha: 0.55),
            size: 32,
          ),

          const SizedBox(height: 10),

          // ====================================================
          // MENSAGEM
          // ====================================================
          Text(
            isOwner
                ? 'Você ainda não adicionou músicas ao seu perfil.'
                : 'Este profissional ainda não publicou músicas.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 11,
              height: 1.4,
            ),
          ),

          // ====================================================
          // ADICIONAR PRIMEIRA MÚSICA
          // ====================================================
          if (isOwner && onAddTrack != null) ...[
            const SizedBox(height: 14),

            OutlinedButton.icon(
              onPressed: isUploading ? null : onAddTrack,
              style: OutlinedButton.styleFrom(
                foregroundColor: accentColor,
                side: BorderSide(color: accentColor.withValues(alpha: 0.25)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: isUploading
                  ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: accentColor,
                      ),
                    )
                  : const Icon(Icons.add_rounded, size: 16),
              label: Text(
                isUploading ? 'ENVIANDO...' : 'ADICIONAR PRIMEIRA MÚSICA',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
