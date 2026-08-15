import 'package:flutter/material.dart';

import 'package:versin/modules/match/widgets/profile_track_player_sheet.dart';

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
// Página pública do perfil.
//
// Responsabilidades:
//
// - carregar perfil;
// - exibir identidade;
// - exibir bio;
// - exibir músicas;
// - adicionar demo;
// - remover demo;
// - editar perfil;
// - reproduzir demo;
// - alterar ONLINE / OFFLINE;
// - atualizar interface.
//
// Reprodução:
//
// ícone PLAY
//      ↓
// getTrackPlaybackUrl()
//      ↓
// create-track-playback-url
//      ↓
// Cloudflare R2
//      ↓
// ProfileTrackPlayerSheet
//
// ============================================================

class PublicProfilePage
    extends
        StatefulWidget {
  // ============================================================
  // USER
  // ============================================================

  final String userId;

  // ============================================================
  // CONTROLLER
  // ============================================================

  final PublicProfileController controller;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  const PublicProfilePage({
    super.key,
    required this.userId,
    required this.controller,
  });

  @override
  State<
    PublicProfilePage
  >
  createState() => _PublicProfilePageState();
}

// ============================================================
// STATE
// ============================================================

class _PublicProfilePageState
    extends
        State<
          PublicProfilePage
        > {
  // ============================================================
  // CONSTANTES
  // ============================================================

  static const Color _accentColor = Color(
    0xFFE100FF,
  );

  // ============================================================
  // CONTROLLER
  // ============================================================

  PublicProfileController get controller => widget.controller;

  // ============================================================
  // PLAYBACK
  // ============================================================

  final Set<
    String
  >
  _loadingTrackIds =
      <
        String
      >{};

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    controller.addListener(
      _onControllerChanged,
    );

    WidgetsBinding.instance.addPostFrameCallback(
      (
        _,
      ) {
        if (!mounted) {
          return;
        }

        controller.load(
          userId: widget.userId,
        );
      },
    );
  }

  // ============================================================
  // UPDATE WIDGET
  // ============================================================

  @override
  void didUpdateWidget(
    covariant PublicProfilePage oldWidget,
  ) {
    super.didUpdateWidget(
      oldWidget,
    );

    // ==========================================================
    // CONTROLLER ALTERADO
    // ==========================================================

    if (oldWidget.controller !=
        widget.controller) {
      oldWidget.controller.removeListener(
        _onControllerChanged,
      );

      widget.controller.addListener(
        _onControllerChanged,
      );
    }

    // ==========================================================
    // USER ALTERADO
    // ==========================================================

    if (oldWidget.userId !=
        widget.userId) {
      widget.controller.load(
        userId: widget.userId,
      );
    }
  }

  // ============================================================
  // CONTROLLER CHANGE
  // ============================================================

  void _onControllerChanged() {
    if (!mounted) {
      return;
    }

    setState(
      () {},
    );
  }

  // ============================================================
  // VOLTAR
  // ============================================================

  void _goBack() {
    if (!Navigator.of(
      context,
    ).canPop()) {
      return;
    }

    Navigator.of(
      context,
    ).pop();
  }

  // ============================================================
  // EDITAR PERFIL
  // ============================================================

  Future<
    void
  >
  _openEditProfile() async {
    final profile = controller.profile;

    if (profile ==
            null ||
        !controller.isOwner) {
      return;
    }

    final updated =
        await Navigator.of(
          context,
        ).push<
          bool
        >(
          MaterialPageRoute(
            builder:
                (
                  _,
                ) {
                  return EditPublicProfilePage(
                    controller: controller,
                  );
                },
          ),
        );

    if (!mounted ||
        updated !=
            true) {
      return;
    }

    await controller.refresh();
  }

  // ============================================================
  // ADICIONAR DEMO
  // ============================================================

  Future<
    void
  >
  _openAddTrack() async {
    if (!controller.isOwner ||
        controller.isUploadingTrack) {
      return;
    }

    final result = await AddProfileTrackSheet.show(
      context: context,

      accentColor: _accentColor,
    );

    if (!mounted ||
        result ==
            null) {
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

    // ==========================================================
    // ERRO
    // ==========================================================

    if (created ==
        null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            controller.errorMessage ??
                'Não foi possível publicar a demo.',
          ),
        ),
      );

      return;
    }

    // ==========================================================
    // SUCESSO
    // ==========================================================

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: Text(
          '${created.title} foi publicada no seu perfil.',
        ),
      ),
    );
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<
    void
  >
  _refresh() async {
    await controller.refresh();
  }

  Future<
    void
  >
  _toggleOnlineStatus() async {
    if (!controller.isOwner ||
        controller.isUpdatingOnlineStatus) {
      return;
    }

    final currentProfile = controller.profile;

    if (currentProfile ==
        null) {
      return;
    }

    final wasOnline = currentProfile.isOnline;

    final changed = await controller.toggleOnline();

    if (!mounted) {
      return;
    }

    if (!changed) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            controller.errorMessage ??
                'Não foi possível alterar a visibilidade do perfil.',
          ),
        ),
      );

      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: Text(
          wasOnline
              ? 'Seu perfil agora está offline.'
              : 'Seu perfil agora está online.',
        ),
      ),
    );
  }

  // ============================================================
  // PLAY TRACK
  // ============================================================
  //
  // Este fluxo agora é o MESMO utilizado em:
  //
  // Match
  // → OUVIR DEMO
  //
  // Aqui:
  //
  // botão roxo de play
  //      ↓
  // getTrackPlaybackUrl
  //      ↓
  // signed GET URL
  //      ↓
  // ProfileTrackPlayerSheet
  //
  // ============================================================

  Future<
    void
  >
  _playTrack(
    ProfileTrackModel track,
  ) async {
    final trackId = track.id.trim();

    // ==========================================================
    // VALIDAR
    // ==========================================================

    if (trackId.isEmpty ||
        !mounted) {
      return;
    }

    // ==========================================================
    // EVITAR CLIQUE DUPLO
    // ==========================================================

    if (_loadingTrackIds.contains(
      trackId,
    )) {
      debugPrint(
        '[PUBLIC PROFILE PLAYER] '
        'Track já está carregando.',
      );

      return;
    }

    // ==========================================================
    // LOADING
    // ==========================================================

    setState(
      () {
        _loadingTrackIds.add(
          trackId,
        );
      },
    );

    try {
      debugPrint(
        '[PUBLIC PROFILE PLAYER] '
        'Abrindo demo: '
        '${track.title}',
      );

      // ========================================================
      // PLAYBACK URL
      // ========================================================

      final url = await controller.getTrackPlaybackUrl(
        track,
      );

      if (!mounted) {
        return;
      }

      // ========================================================
      // URL INVÁLIDA
      // ========================================================

      if (url.trim().isEmpty) {
        debugPrint(
          '[PUBLIC PROFILE PLAYER] '
          'URL de reprodução indisponível.',
        );

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível carregar a música.',
            ),
          ),
        );

        return;
      }

      // ========================================================
      // PERFIL
      // ========================================================

      final profile = controller.profile;

      final displayName =
          profile?.resolvedDisplayName ??
          'Profissional';

      // ========================================================
      // PLAYER
      // ========================================================

      debugPrint(
        '[PUBLIC PROFILE PLAYER] '
        'Playback URL disponível.',
      );

      await ProfileTrackPlayerSheet.show(
        context: context,

        track: track,

        playbackUrl: url,

        displayName: displayName,

        accentColor: _accentColor,
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[PUBLIC PROFILE PLAYER] '
        'Erro ao reproduzir demo: '
        '$error',
      );

      debugPrint(
        '[PUBLIC PROFILE PLAYER] '
        'Stack trace: '
        '$stackTrace',
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível reproduzir a música.',
          ),
        ),
      );
    } finally {
      if (!mounted) {
        return;
      }

      setState(
        () {
          _loadingTrackIds.remove(
            trackId,
          );
        },
      );
    }
  }

  // ============================================================
  // DELETE TRACK
  // ============================================================

  Future<
    void
  >
  _deleteTrack(
    ProfileTrackModel track,
  ) async {
    final deleted = await controller.deleteTrack(
      track,
    );

    if (!mounted) {
      return;
    }

    // ==========================================================
    // SUCCESS
    // ==========================================================

    if (deleted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Demo removida.',
          ),
        ),
      );

      return;
    }

    // ==========================================================
    // ERROR
    // ==========================================================

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: Text(
          controller.errorMessage ??
              'Não foi possível remover a música.',
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: const Color(
        0xFF09090F,
      ),

      // ========================================================
      // APP BAR
      // ========================================================
      appBar: AppBar(
        backgroundColor: const Color(
          0xFF09090F,
        ),

        surfaceTintColor: Colors.transparent,

        elevation: 0,

        // ======================================================
        // VOLTAR
        // ======================================================
        leading: IconButton(
          tooltip: 'Voltar',

          onPressed: _goBack,

          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
          ),
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
          if (controller.isOwner &&
              controller.profile !=
                  null)
            IconButton(
              tooltip: 'Editar perfil',

              onPressed: controller.isSaving
                  ? null
                  : _openEditProfile,

              icon: const Icon(
                Icons.edit_outlined,
                color: Colors.white,
              ),
            ),

          // ====================================================
          // REFRESH
          // ====================================================
          IconButton(
            tooltip: 'Atualizar',

            onPressed: controller.isLoading
                ? null
                : _refresh,

            icon: const Icon(
              Icons.refresh_rounded,
              color: Colors.white,
            ),
          ),

          const SizedBox(
            width: 8,
          ),
        ],
      ),

      // ========================================================
      // BODY
      // ========================================================
      body: SafeArea(
        top: false,

        child: _buildBody(),
      ),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    // ==========================================================
    // LOADING INICIAL
    // ==========================================================

    if (controller.isLoading &&
        controller.profile ==
            null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // ==========================================================
    // ERRO
    // ==========================================================

    if (controller.hasError &&
        controller.profile ==
            null) {
      return _buildError();
    }

    // ==========================================================
    // PERFIL
    // ==========================================================

    final profile = controller.profile;

    if (profile ==
        null) {
      return _buildEmpty();
    }

    // ==========================================================
    // CONTEÚDO
    // ==========================================================

    return RefreshIndicator(
      onRefresh: _refresh,

      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),

        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              20,
              20,
              20,
              40,
            ),

            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  // ============================================
                  // HEADER
                  // ============================================
                  PublicProfileHeaderWidget(
                    profile: profile,

                    isOwner: controller.isOwner,

                    isUpdatingOnlineStatus: controller.isUpdatingOnlineStatus,

                    onEdit: controller.isOwner
                        ? _openEditProfile
                        : null,

                    onToggleOnline: controller.isOwner
                        ? _toggleOnlineStatus
                        : null,
                  ),

                  const SizedBox(
                    height: 24,
                  ),

                  // ============================================
                  // BIO
                  // ============================================
                  PublicProfileBioWidget(
                    bio: profile.bio,

                    isOwner: controller.isOwner,

                    onEdit: controller.isOwner
                        ? _openEditProfile
                        : null,
                  ),

                  const SizedBox(
                    height: 28,
                  ),

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
                    onAddTrack: controller.isOwner
                        ? _openAddTrack
                        : null,

                    // ==========================================
                    // PLAY
                    // ==========================================
                    //
                    // ESTE É O ÍCONE ROXO.
                    //
                    // Agora usa exatamente o mesmo modal
                    // utilizado pelo OUVIR DEMO do Match.
                    //
                    // ==========================================
                    onPlayTrack: _playTrack,

                    // ==========================================
                    // DELETE
                    // ==========================================
                    onDeleteTrack: controller.isOwner
                        ? _deleteTrack
                        : null,
                  ),

                  // ============================================
                  // UPLOAD
                  // ============================================
                  if (controller.isUploadingTrack) ...[
                    const SizedBox(
                      height: 18,
                    ),

                    _buildUploadingCard(),
                  ],

                  // ============================================
                  // LOADING SECUNDÁRIO
                  // ============================================
                  if (controller.isLoading) ...[
                    const SizedBox(
                      height: 24,
                    ),

                    const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // UPLOADING
  // ============================================================

  Widget _buildUploadingCard() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(
        14,
      ),

      decoration: BoxDecoration(
        color: _accentColor.withValues(
          alpha: 0.06,
        ),

        borderRadius: BorderRadius.circular(
          14,
        ),

        border: Border.all(
          color: _accentColor.withValues(
            alpha: 0.16,
          ),
        ),
      ),

      child: const Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _accentColor,
            ),
          ),

          SizedBox(
            width: 12,
          ),

          Expanded(
            child: Text(
              'Enviando demo para o seu perfil...',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError() {
    return RefreshIndicator(
      onRefresh: _refresh,

      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),

        padding: const EdgeInsets.all(
          24,
        ),

        children: [
          SizedBox(
            height:
                MediaQuery.of(
                  context,
                ).size.height *
                0.22,
          ),

          const Icon(
            Icons.error_outline_rounded,
            color: Colors.redAccent,
            size: 46,
          ),

          const SizedBox(
            height: 16,
          ),

          Text(
            controller.errorMessage ??
                'Não foi possível carregar o perfil.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
            ),
          ),

          const SizedBox(
            height: 20,
          ),

          Center(
            child: FilledButton.icon(
              onPressed: controller.isLoading
                  ? null
                  : _refresh,

              icon: const Icon(
                Icons.refresh_rounded,
              ),

              label: const Text(
                'Tentar novamente',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmpty() {
    return RefreshIndicator(
      onRefresh: _refresh,

      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),

        padding: const EdgeInsets.all(
          24,
        ),

        children: [
          SizedBox(
            height:
                MediaQuery.of(
                  context,
                ).size.height *
                0.22,
          ),

          const Icon(
            Icons.person_off_outlined,
            color: Colors.white38,
            size: 48,
          ),

          const SizedBox(
            height: 16,
          ),

          const Text(
            'Perfil não encontrado.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          const Text(
            'Não encontramos um perfil público associado a esta conta.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white38,
              fontSize: 12,
            ),
          ),

          const SizedBox(
            height: 20,
          ),

          Center(
            child: OutlinedButton.icon(
              onPressed: controller.isLoading
                  ? null
                  : _refresh,

              icon: const Icon(
                Icons.refresh_rounded,
              ),

              label: const Text(
                'Atualizar',
              ),
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
    controller.removeListener(
      _onControllerChanged,
    );

    _loadingTrackIds.clear();

    super.dispose();
  }
}
