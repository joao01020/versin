import 'package:flutter/material.dart';

import 'package:versin/modules/profile/public_profile/controllers/profile_track_player_controller.dart';
import 'package:versin/modules/profile/public_profile/models/profile_track_model.dart';

// ============================================================
// PROFILE TRACK PLAYER SHEET
// ============================================================
//
// Player utilizado pelo Match para reproduzir a demo pública.
//
// Recebe:
//
// - track;
// - signed playback URL;
// - nome do profissional;
// - cor de destaque.
//
// NÃO:
//
// - busca usuário;
// - consulta Supabase;
// - gera signed URL;
// - procura a primeira track;
// - conhece MatchController;
// - conhece MatchDemoController.
//
// Toda obtenção da demo acontece antes, através do:
//
// MatchDemoController.
//
// ============================================================

class ProfileTrackPlayerSheet
    extends
        StatefulWidget {
  // ============================================================
  // TRACK
  // ============================================================

  final ProfileTrackModel? track;

  // ============================================================
  // PLAYBACK URL
  // ============================================================

  final String? playbackUrl;

  // ============================================================
  // DISPLAY NAME
  // ============================================================

  final String displayName;

  // ============================================================
  // ACCENT
  // ============================================================

  final Color accentColor;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  const ProfileTrackPlayerSheet({
    super.key,
    required this.track,
    required this.playbackUrl,
    required this.displayName,
    this.accentColor = const Color(
      0xFFE100FF,
    ),
  });

  // ============================================================
  // SHOW
  // ============================================================

  static Future<
    void
  >
  show({
    required BuildContext context,
    required ProfileTrackModel? track,
    required String? playbackUrl,
    required String displayName,
    Color accentColor = const Color(
      0xFFE100FF,
    ),
  }) {
    return showModalBottomSheet<
      void
    >(
      context: context,

      isScrollControlled: true,

      useSafeArea: true,

      backgroundColor: Colors.transparent,

      builder:
          (
            _,
          ) {
            return ProfileTrackPlayerSheet(
              track: track,

              playbackUrl: playbackUrl,

              displayName: displayName,

              accentColor: accentColor,
            );
          },
    );
  }

  // ============================================================
  // CREATE STATE
  // ============================================================

  @override
  State<
    ProfileTrackPlayerSheet
  >
  createState() {
    return _ProfileTrackPlayerSheetState();
  }
}

// ============================================================
// STATE
// ============================================================

class _ProfileTrackPlayerSheetState
    extends
        State<
          ProfileTrackPlayerSheet
        > {
  // ============================================================
  // PLAYER
  // ============================================================

  late final ProfileTrackPlayerController _playerController;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _playerController = ProfileTrackPlayerController();

    _playerController.addListener(
      _onPlayerChanged,
    );

    WidgetsBinding.instance.addPostFrameCallback(
      (
        _,
      ) {
        _loadTrack();
      },
    );
  }

  // ============================================================
  // PLAYER CHANGED
  // ============================================================

  void _onPlayerChanged() {
    if (!mounted) {
      return;
    }

    setState(
      () {},
    );
  }

  // ============================================================
  // LOAD TRACK
  // ============================================================

  Future<
    void
  >
  _loadTrack() async {
    final track = widget.track;

    final url = widget.playbackUrl?.trim();

    if (track ==
        null) {
      return;
    }

    if (url ==
            null ||
        url.isEmpty) {
      return;
    }

    await _playerController.load(
      track: track,

      url: url,
    );
  }

  // ============================================================
  // TOGGLE
  // ============================================================

  Future<
    void
  >
  _togglePlayback() async {
    if (_playerController.isLoading) {
      return;
    }

    await _playerController.toggle();
  }

  // ============================================================
  // RETRY
  // ============================================================

  Future<
    void
  >
  _retry() async {
    final track = widget.track;

    final url = widget.playbackUrl?.trim();

    if (track ==
            null ||
        url ==
            null ||
        url.isEmpty) {
      return;
    }

    await _playerController.load(
      track: track,

      url: url,
    );
  }

  // ============================================================
  // CLOSE
  // ============================================================

  Future<
    void
  >
  _close() async {
    await _playerController.pause();

    if (!mounted) {
      return;
    }

    Navigator.of(
      context,
    ).pop();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final track = widget.track;

    final url = widget.playbackUrl?.trim();

    final hasUrl =
        url !=
            null &&
        url.isNotEmpty;

    return Container(
      constraints: BoxConstraints(
        maxHeight:
            MediaQuery.of(
              context,
            ).size.height *
            0.80,
      ),

      padding: const EdgeInsets.fromLTRB(
        20,
        14,
        20,
        28,
      ),

      decoration: const BoxDecoration(
        color: Color(
          0xFF151126,
        ),

        borderRadius: BorderRadius.vertical(
          top: Radius.circular(
            24,
          ),
        ),
      ),

      child: SafeArea(
        top: false,

        child:
            track ==
                null
            ? _buildNoDemo()
            : !hasUrl
            ? _buildUnavailable(
                track,
              )
            : _buildPlayer(
                track,
              ),
      ),
    );
  }

  // ============================================================
  // NO DEMO
  // ============================================================

  Widget _buildNoDemo() {
    return Column(
      mainAxisSize: MainAxisSize.min,

      children: [
        _buildHandle(),

        const SizedBox(
          height: 26,
        ),

        Icon(
          Icons.music_off_outlined,

          color: widget.accentColor.withValues(
            alpha: 0.55,
          ),

          size: 46,
        ),

        const SizedBox(
          height: 18,
        ),

        Text(
          widget.displayName,

          textAlign: TextAlign.center,

          style: const TextStyle(
            color: Colors.white,

            fontSize: 17,

            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(
          height: 8,
        ),

        const Text(
          'Este usuário ainda não publicou nenhuma demo.',

          textAlign: TextAlign.center,

          style: TextStyle(
            color: Colors.white38,

            fontSize: 12,

            height: 1.4,
          ),
        ),

        const SizedBox(
          height: 26,
        ),

        OutlinedButton.icon(
          onPressed: _close,

          icon: const Icon(
            Icons.close_rounded,
          ),

          label: const Text(
            'Fechar',
          ),
        ),
      ],
    );
  }

  // ============================================================
  // UNAVAILABLE
  // ============================================================

  Widget _buildUnavailable(
    ProfileTrackModel track,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,

      children: [
        _buildHandle(),

        const SizedBox(
          height: 26,
        ),

        Icon(
          Icons.cloud_off_outlined,

          color: widget.accentColor.withValues(
            alpha: 0.55,
          ),

          size: 46,
        ),

        const SizedBox(
          height: 18,
        ),

        Text(
          track.title,

          textAlign: TextAlign.center,

          style: const TextStyle(
            color: Colors.white,

            fontSize: 17,

            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(
          height: 6,
        ),

        Text(
          widget.displayName,

          style: const TextStyle(
            color: Colors.white38,

            fontSize: 11,
          ),
        ),

        const SizedBox(
          height: 14,
        ),

        const Text(
          'A demo existe, mas não foi possível obter '
          'o áudio para reprodução.',

          textAlign: TextAlign.center,

          style: TextStyle(
            color: Colors.white38,

            fontSize: 12,

            height: 1.4,
          ),
        ),

        const SizedBox(
          height: 26,
        ),

        OutlinedButton.icon(
          onPressed: _close,

          icon: const Icon(
            Icons.close_rounded,
          ),

          label: const Text(
            'Fechar',
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PLAYER
  // ============================================================

  Widget _buildPlayer(
    ProfileTrackModel track,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,

      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        _buildHandle(),

        const SizedBox(
          height: 20,
        ),

        // ======================================================
        // HEADER
        // ======================================================
        Row(
          children: [
            Container(
              width: 46,

              height: 46,

              decoration: BoxDecoration(
                color: widget.accentColor.withValues(
                  alpha: 0.10,
                ),

                borderRadius: BorderRadius.circular(
                  14,
                ),

                border: Border.all(
                  color: widget.accentColor.withValues(
                    alpha: 0.22,
                  ),
                ),
              ),

              child: Icon(
                Icons.graphic_eq_rounded,

                color: widget.accentColor,
              ),
            ),

            const SizedBox(
              width: 12,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    track.title,

                    maxLines: 1,

                    overflow: TextOverflow.ellipsis,

                    style: const TextStyle(
                      color: Colors.white,

                      fontSize: 16,

                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  Text(
                    widget.displayName,

                    maxLines: 1,

                    overflow: TextOverflow.ellipsis,

                    style: const TextStyle(
                      color: Colors.white38,

                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            IconButton(
              tooltip: 'Fechar',

              onPressed: _close,

              icon: const Icon(
                Icons.close_rounded,

                color: Colors.white54,
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 28,
        ),

        // ======================================================
        // ERROR
        // ======================================================
        if (_playerController.hasError) ...[
          _buildError(),

          const SizedBox(
            height: 20,
          ),
        ],

        // ======================================================
        // PLAY / PAUSE
        // ======================================================
        Center(
          child: InkWell(
            onTap: _togglePlayback,

            borderRadius: BorderRadius.circular(
              100,
            ),

            child: Container(
              width: 72,

              height: 72,

              alignment: Alignment.center,

              decoration: BoxDecoration(
                color: widget.accentColor,

                shape: BoxShape.circle,

                boxShadow: [
                  BoxShadow(
                    color: widget.accentColor.withValues(
                      alpha: 0.25,
                    ),

                    blurRadius: 22,

                    spreadRadius: 2,
                  ),
                ],
              ),

              child: _playerController.isLoading
                  ? const SizedBox(
                      width: 24,

                      height: 24,

                      child: CircularProgressIndicator(
                        strokeWidth: 2,

                        color: Colors.black,
                      ),
                    )
                  : Icon(
                      _playerController.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,

                      color: Colors.black,

                      size: 40,
                    ),
            ),
          ),
        ),

        const SizedBox(
          height: 26,
        ),

        // ======================================================
        // PROGRESS
        // ======================================================
        SliderTheme(
          data:
              SliderTheme.of(
                context,
              ).copyWith(
                activeTrackColor: widget.accentColor,

                inactiveTrackColor: Colors.white12,

                thumbColor: widget.accentColor,

                overlayColor: widget.accentColor.withValues(
                  alpha: 0.10,
                ),

                trackHeight: 3,
              ),

          child: Slider(
            value: _playerController.progress,

            min: 0,

            max: 1,

            onChanged: _playerController.isLoading
                ? null
                : (
                    value,
                  ) {
                    _playerController.seekToProgress(
                      value,
                    );
                  },
          ),
        ),

        // ======================================================
        // TIME
        // ======================================================
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 4,
          ),

          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            children: [
              Text(
                _playerController.formattedPosition,

                style: const TextStyle(
                  color: Colors.white38,

                  fontSize: 10,
                ),
              ),

              Text(
                _playerController.formattedDuration,

                style: const TextStyle(
                  color: Colors.white38,

                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(
          height: 22,
        ),

        // ======================================================
        // METADATA
        // ======================================================
        _buildTrackInfo(
          track,
        ),

        const SizedBox(
          height: 20,
        ),

        // ======================================================
        // PREVIEW
        // ======================================================
        Container(
          width: double.infinity,

          padding: const EdgeInsets.all(
            12,
          ),

          decoration: BoxDecoration(
            color: Colors.white.withValues(
              alpha: 0.025,
            ),

            borderRadius: BorderRadius.circular(
              12,
            ),

            border: Border.all(
              color: Colors.white.withValues(
                alpha: 0.05,
              ),
            ),
          ),

          child: const Row(
            children: [
              Icon(
                Icons.info_outline_rounded,

                color: Colors.white30,

                size: 16,
              ),

              SizedBox(
                width: 8,
              ),

              Expanded(
                child: Text(
                  'Você está ouvindo uma prévia de até 60 segundos.',

                  style: TextStyle(
                    color: Colors.white38,

                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // TRACK INFO
  // ============================================================

  Widget _buildTrackInfo(
    ProfileTrackModel track,
  ) {
    final labels =
        <
          String
        >[];

    if (track.formatLabel.isNotEmpty) {
      labels.add(
        track.formatLabel,
      );
    }

    if (track.formattedFileSize.isNotEmpty) {
      labels.add(
        track.formattedFileSize,
      );
    }

    if (track.hasDuration) {
      labels.add(
        track.formattedDuration,
      );
    }

    if (labels.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,

      runSpacing: 8,

      children: labels.map(
        (
          label,
        ) {
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,

              vertical: 6,
            ),

            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.035,
              ),

              borderRadius: BorderRadius.circular(
                20,
              ),

              border: Border.all(
                color: Colors.white.withValues(
                  alpha: 0.05,
                ),
              ),
            ),

            child: Text(
              label,

              style: const TextStyle(
                color: Colors.white38,

                fontSize: 9,
              ),
            ),
          );
        },
      ).toList(),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(
        12,
      ),

      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(
          alpha: 0.07,
        ),

        borderRadius: BorderRadius.circular(
          12,
        ),

        border: Border.all(
          color: Colors.redAccent.withValues(
            alpha: 0.18,
          ),
        ),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Icon(
            Icons.error_outline_rounded,

            color: Colors.redAccent,

            size: 18,
          ),

          const SizedBox(
            width: 10,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  _playerController.errorMessage ??
                      'Não foi possível reproduzir a demo.',

                  style: const TextStyle(
                    color: Colors.white70,

                    fontSize: 11,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                TextButton.icon(
                  onPressed: _retry,

                  icon: const Icon(
                    Icons.refresh_rounded,

                    size: 16,
                  ),

                  label: const Text(
                    'Tentar novamente',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HANDLE
  // ============================================================

  Widget _buildHandle() {
    return Center(
      child: Container(
        width: 42,

        height: 4,

        decoration: BoxDecoration(
          color: Colors.white12,

          borderRadius: BorderRadius.circular(
            100,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _playerController.removeListener(
      _onPlayerChanged,
    );

    _playerController.dispose();

    super.dispose();
  }
}
