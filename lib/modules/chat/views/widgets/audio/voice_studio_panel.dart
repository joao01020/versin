import 'dart:math' as math;

import 'package:flutter/material.dart';

class VoiceStudioPanel
    extends
        StatefulWidget {
  final Color activeColor;
  final VoidCallback onFinished;

  const VoiceStudioPanel({
    super.key,
    required this.activeColor,
    required this.onFinished,
  });

  @override
  State<
    VoiceStudioPanel
  >
  createState() => _VoiceStudioPanelState();
}

class _VoiceStudioPanelState
    extends
        State<
          VoiceStudioPanel
        >
    with
        SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  bool _isRecording = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 2000,
      ),
    );
  }

  void _toggleRecording() {
    setState(
      () {
        _isRecording = !_isRecording;
      },
    );

    if (_isRecording) {
      _animationController.repeat();
      return;
    }

    _animationController
      ..stop()
      ..reset();

    widget.onFinished();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final activeColor = widget.activeColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 32,
        horizontal: 24,
      ),
      decoration: const BoxDecoration(
        color: Color(
          0xFF0F0F0F,
        ),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(
            24,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Gravando Áudio do Fluxo',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(
            height: 40,
          ),

          GestureDetector(
            onTap: _toggleRecording,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 200,
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_isRecording)
                    AnimatedBuilder(
                      animation: _animationController,
                      builder:
                          (
                            _,
                            _,
                          ) {
                            return CustomPaint(
                              size: const Size(
                                200,
                                200,
                              ),
                              painter: AudioWavePainter(
                                progress: _animationController.value,
                                waveColor: activeColor,
                              ),
                            );
                          },
                    ),

                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: _isRecording
                          ? activeColor
                          : const Color(
                              0xFF1A1A1A,
                            ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color:
                              (_isRecording
                                      ? activeColor
                                      : Colors.black)
                                  .withValues(
                                    alpha: 0.3,
                                  ),
                          blurRadius: 12,
                          offset: const Offset(
                            0,
                            4,
                          ),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isRecording
                          ? Icons.stop_rounded
                          : Icons.mic_none_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(
            height: 24,
          ),

          Text(
            _isRecording
                ? 'Toque para finalizar'
                : 'Toque no microfone para falar',
            style: TextStyle(
              color: _isRecording
                  ? activeColor
                  : Colors.white38,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(
            height: 16,
          ),
        ],
      ),
    );
  }
}

class AudioWavePainter
    extends
        CustomPainter {
  final double progress;
  final Color waveColor;

  const AudioWavePainter({
    required this.progress,
    required this.waveColor,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final center = Offset(
      size.width /
          2,
      size.height /
          2,
    );

    final maxRadius =
        size.width /
        2;

    for (
      int i = 0;
      i <
          3;
      i++
    ) {
      final waveProgress =
          (progress +
              (i /
                  3.0)) %
          1.0;

      final radius =
          38 +
          (maxRadius -
                  38) *
              waveProgress;

      final opacity = math.max(
        0.0,
        1.0 -
            waveProgress,
      );

      final paint = Paint()
        ..color = waveColor.withValues(
          alpha:
              opacity *
              0.4,
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;

      canvas.drawCircle(
        center,
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant AudioWavePainter oldDelegate,
  ) {
    return oldDelegate.progress !=
            progress ||
        oldDelegate.waveColor !=
            waveColor;
  }
}
