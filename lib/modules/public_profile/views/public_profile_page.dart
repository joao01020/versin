import 'package:flutter/material.dart';

import 'package:versin/modules/public_profile/controllers/public_profile_controller.dart';
import 'package:versin/modules/public_profile/models/profile_track_model.dart';
import 'package:versin/modules/public_profile/views/edit_public_profile_page.dart';
import 'package:versin/modules/public_profile/widgets/add_profile_track_sheet.dart';
import 'package:versin/modules/public_profile/widgets/public_profile_bio_widget.dart';
import 'package:versin/modules/public_profile/widgets/public_profile_header_widget.dart';
import 'package:versin/modules/public_profile/widgets/public_profile_tracks_widget.dart';

// ============================================================
// PUBLIC PROFILE PAGE
// ============================================================
//
// Página pública do perfil usado pelo modo Conectar.
//
// Responsabilidades:
//
// - carregar perfil;
// - exibir identidade;
// - exibir bio;
// - exibir músicas;
// - adicionar demo;
// - remover demo;
// - permitir edição quando for o dono;
// - permitir voltar em qualquer estado;
// - atualizar interface pelo controller.
//
// ============================================================

class PublicProfilePage extends StatefulWidget {
  final String userId;

  final PublicProfileController controller;

  const PublicProfilePage({
    super.key,
    required this.userId,
    required this.controller,
  });

  @override
  State<PublicProfilePage> createState() => _PublicProfilePageState();
}

// ============================================================
// STATE
// ============================================================

class _PublicProfilePageState extends State<PublicProfilePage> {
  // ============================================================
  // CONTROLLER
  // ============================================================

  PublicProfileController get controller => widget.controller;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    controller.addListener(_onControllerChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      controller.load(userId: widget.userId);
    });
  }

  // ============================================================
  // UPDATE WIDGET
  // ============================================================

  @override
  void didUpdateWidget(covariant PublicProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);

      widget.controller.addListener(_onControllerChanged);
    }

    if (oldWidget.userId != widget.userId) {
      widget.controller.load(userId: widget.userId);
    }
  }

  // ============================================================
  // CONTROLLER CHANGE
  // ============================================================

  void _onControllerChanged() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  // ============================================================
  // VOLTAR
  // ============================================================

  void _goBack() {
    if (!Navigator.of(context).canPop()) {
      return;
    }

    Navigator.of(context).pop();
  }

  // ============================================================
  // EDITAR PERFIL
  // ============================================================

  Future<void> _openEditProfile() async {
    final profile = controller.profile;

    if (profile == null || !controller.isOwner) {
      return;
    }

    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) {
          return EditPublicProfilePage(controller: controller);
        },
      ),
    );

    if (!mounted || updated != true) {
      return;
    }

    await controller.refresh();
  }

  // ============================================================
  // ADICIONAR DEMO
  // ============================================================

  Future<void> _openAddTrack() async {
    if (!controller.isOwner || controller.isUploadingTrack) {
      return;
    }

    final result = await AddProfileTrackSheet.show(
      context: context,
      accentColor: const Color(0xFFE100FF),
    );

    if (!mounted || result == null) {
      return;
    }

    final created = await controller.addTrack(
      title: result.title,
      fileName: result.file.fileName,
      bytes: result.file.bytes,
      mimeType: result.file.mimeType,
      audienceRoles: result.audience.roles,
    );

    if (!mounted) {
      return;
    }

    if (created == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            controller.errorMessage ?? 'Não foi possível publicar a demo.',
          ),
        ),
      );

      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${created.title} foi publicada no seu perfil.')),
    );
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> _refresh() async {
    await controller.refresh();
  }

  // ============================================================
  // PLAY TRACK
  // ============================================================

  Future<void> _playTrack(ProfileTrackModel track) async {
    final url = await controller.getTrackPlaybackUrl(track);

    if (!mounted) {
      return;
    }

    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível carregar a música.')),
      );

      return;
    }

    debugPrint(
      '[PUBLIC PROFILE] '
      'Playback URL: '
      '$url',
    );

    // ==========================================================
    // PLAYER
    // ==========================================================
    //
    // Na próxima etapa conectaremos:
    //
    // ProfileTrackPlayerController
    //
    // ==========================================================
  }

  // ============================================================
  // DELETE TRACK
  // ============================================================

  Future<void> _deleteTrack(ProfileTrackModel track) async {
    final deleted = await controller.deleteTrack(track);

    if (!mounted) {
      return;
    }

    if (deleted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Demo removida.')));

      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          controller.errorMessage ?? 'Não foi possível remover a música.',
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090F),

      // ========================================================
      // APP BAR
      // ========================================================
      appBar: AppBar(
        backgroundColor: const Color(0xFF09090F),
        surfaceTintColor: Colors.transparent,
        elevation: 0,

        // ======================================================
        // VOLTAR
        // ======================================================
        leading: IconButton(
          tooltip: 'Voltar',
          onPressed: _goBack,
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        ),

        // ======================================================
        // TÍTULO
        // ======================================================
        title: const Text(
          'Perfil',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),

        // ======================================================
        // AÇÕES
        // ======================================================
        actions: [
          // ====================================================
          // EDITAR
          // ====================================================
          if (controller.isOwner && controller.profile != null)
            IconButton(
              tooltip: 'Editar perfil',
              onPressed: controller.isSaving ? null : _openEditProfile,
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
            ),

          // ====================================================
          // REFRESH
          // ====================================================
          IconButton(
            tooltip: 'Atualizar',
            onPressed: controller.isLoading ? null : _refresh,
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          ),

          const SizedBox(width: 8),
        ],
      ),

      // ========================================================
      // BODY
      // ========================================================
      body: SafeArea(top: false, child: _buildBody()),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    // ==========================================================
    // LOADING INICIAL
    // ==========================================================

    if (controller.isLoading && controller.profile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // ==========================================================
    // ERRO
    // ==========================================================

    if (controller.hasError && controller.profile == null) {
      return _buildError();
    }

    // ==========================================================
    // PERFIL
    // ==========================================================

    final profile = controller.profile;

    if (profile == null) {
      return _buildEmpty();
    }

    // ==========================================================
    // PERFIL CARREGADO
    // ==========================================================

    return RefreshIndicator(
      onRefresh: _refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ============================================
                // HEADER
                // ============================================
                PublicProfileHeaderWidget(
                  profile: profile,
                  isOwner: controller.isOwner,
                  onEdit: controller.isOwner ? _openEditProfile : null,
                ),

                const SizedBox(height: 24),

                // ============================================
                // BIO
                // ============================================
                PublicProfileBioWidget(
                  bio: profile.bio,
                  isOwner: controller.isOwner,
                  onEdit: controller.isOwner ? _openEditProfile : null,
                ),

                const SizedBox(height: 28),

                // ============================================
                // MÚSICAS
                // ============================================
                PublicProfileTracksWidget(
                  tracks: controller.tracks,

                  isOwner: controller.isOwner,

                  isUploading: controller.isUploadingTrack,

                  // ==========================================
                  // ADICIONAR
                  // ==========================================
                  onAddTrack: controller.isOwner ? _openAddTrack : null,

                  // ==========================================
                  // PLAY
                  // ==========================================
                  onPlayTrack: _playTrack,

                  // ==========================================
                  // DELETE
                  // ==========================================
                  onDeleteTrack: controller.isOwner ? _deleteTrack : null,
                ),

                // ============================================
                // UPLOAD
                // ============================================
                if (controller.isUploadingTrack) ...[
                  const SizedBox(height: 18),

                  _buildUploadingCard(),
                ],

                // ============================================
                // LOADING SECUNDÁRIO
                // ============================================
                if (controller.isLoading) ...[
                  const SizedBox(height: 24),

                  const Center(child: CircularProgressIndicator()),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // UPLOADING CARD
  // ============================================================

  Widget _buildUploadingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE100FF).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE100FF).withValues(alpha: 0.16),
        ),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFFE100FF),
            ),
          ),

          SizedBox(width: 12),

          Expanded(
            child: Text(
              'Enviando demo para o seu perfil...',
              style: TextStyle(color: Colors.white60, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERRO
  // ============================================================

  Widget _buildError() {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.22),

          const Icon(
            Icons.error_outline_rounded,
            color: Colors.redAccent,
            size: 46,
          ),

          const SizedBox(height: 16),

          Text(
            controller.errorMessage ?? 'Não foi possível carregar o perfil.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 15),
          ),

          const SizedBox(height: 20),

          Center(
            child: FilledButton.icon(
              onPressed: controller.isLoading ? null : _refresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PERFIL NÃO ENCONTRADO
  // ============================================================

  Widget _buildEmpty() {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.22),

          const Icon(
            Icons.person_off_outlined,
            color: Colors.white38,
            size: 48,
          ),

          const SizedBox(height: 16),

          const Text(
            'Perfil não encontrado.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Não encontramos um perfil público associado a esta conta.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),

          const SizedBox(height: 20),

          Center(
            child: OutlinedButton.icon(
              onPressed: controller.isLoading ? null : _refresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Atualizar'),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    controller.removeListener(_onControllerChanged);

    super.dispose();
  }
}
