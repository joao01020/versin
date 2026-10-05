import 'package:flutter/material.dart';

class MetronomePlayer
    extends
        StatelessWidget {
  final bool isPlaying;
  final VoidCallback onTap;
  final Color activeColor;

  const MetronomePlayer({
    super.key,
    required this.isPlaying,
    required this.onTap,
    required this.activeColor,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(
          right: 8,
        ),
        padding: const EdgeInsets.all(
          8,
        ),
        decoration: BoxDecoration(
          color: isPlaying
              ? activeColor.withValues(
                  alpha: 0.2,
                )
              : Colors.transparent,
          borderRadius: BorderRadius.circular(
            8,
          ),
        ),
        child: Icon(
          Icons.change_history_rounded,
          color: isPlaying
              ? activeColor
              : Colors.white54,
          size: 20,
        ),
      ),
    );
  }
}
