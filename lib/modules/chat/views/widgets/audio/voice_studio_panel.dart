import 'package:flutter/material.dart';
import 'dart:math' as math;

class VoiceStudioPanel extends StatefulWidget {
  final Color activeColor;
  final VoidCallback onFinished;

  const VoiceStudioPanel({
    super.key,
    required this.activeColor,
    required this.onFinished,
  });

  @override
  State<VoiceStudioPanel> createState() => _VoiceStudioPanelState();
}

class _VoiceStudioPanelState extends State<VoiceStudioPanel> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
  }

  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
      if (_isRecording) {
        _animationController.repeat();
      } else {
        _animationController.stop();
        _animationController.reset();
        widget.onFinished();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F0F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Gravando Áudio do Fluxo",
            style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 40),
          
          GestureDetector(
            onTap: _toggleRecording,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              height: 200,
              width: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_isRecording)
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return CustomPaint(
                          size: const Size(200, 200),
                          painter: AudioWavePainter(
                            progress: _animationController.value,
                            waveColor: widget.activeColor,
                          ),
                        );
                      },
                    ),
                  
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: _isRecording ? widget.activeColor : const Color(0xFF1A1A1A),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_isRecording ? widget.activeColor : Colors.black).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Icon(
                      _isRecording ? Icons.stop_rounded : Icons.mic_none_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          Text(
            _isRecording ? "Toque para finalizar" : "Toque no microfone para falar",
            style: TextStyle(
              color: _isRecording ? widget.activeColor : Colors.white38,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class AudioWavePainter extends CustomPainter {
  final double progress;
  final Color waveColor;

  AudioWavePainter({required this.progress, required this.waveColor});

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double maxRadius = size.width / 2;

    for (int i = 0; i < 3; i++) {
      double waveProgress = (progress + (i / 3.0)) % 1.0;
      double radius = 38 + (maxRadius - 38) * waveProgress;
      double opacity = math.max(0.0, 1.0 - waveProgress);

      final paint = Paint()
        ..color = waveColor.withOpacity(opacity * 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant AudioWavePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.waveColor != waveColor;
  }
}