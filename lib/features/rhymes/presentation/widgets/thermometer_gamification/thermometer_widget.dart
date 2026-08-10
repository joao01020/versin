import 'package:flutter/material.dart';

class ThermometerFeedback
    extends
        StatelessWidget {
  final double starProgress;
  final double fireProgress;
  final String feedbackText;

  const ThermometerFeedback({
    super.key,
    required this.starProgress,
    required this.fireProgress,
    required this.feedbackText,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final isFirePhase =
        fireProgress >
        0.05;
    final progress = isFirePhase
        ? fireProgress
        : starProgress;
    final icon = isFirePhase
        ? Icons.local_fire_department_rounded
        : Icons.star_rounded;
    final color = isFirePhase
        ? Colors.deepOrangeAccent
        : Colors.purpleAccent;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            vertical: 10,
            horizontal: 18,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withValues(
              alpha: 0.5,
            ),
            borderRadius: BorderRadius.circular(
              30,
            ),
            border: Border.all(
              color: Colors.white.withValues(
                alpha: 0.1,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              3,
              (
                index,
              ) => _GradualIcon(
                icon: icon,
                percentage:
                    (progress -
                            index)
                        .clamp(
                          0.0,
                          1.0,
                        ),
                color: color,
              ),
            ),
          ),
        ),

        const SizedBox(
          height: 12,
        ),

        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 40,
          ),
          child: Text(
            feedbackText,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isFirePhase
                  ? Colors.orangeAccent
                  : Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }
}

class _GradualIcon
    extends
        StatelessWidget {
  final IconData icon;
  final double percentage;
  final Color color;

  const _GradualIcon({
    required this.icon,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 4,
      ),
      child: ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback:
            (
              rect,
            ) =>
                LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  stops: [
                    percentage,
                    percentage,
                  ],
                  colors: [
                    color,
                    Colors.white.withValues(
                      alpha: 0.2,
                    ),
                  ],
                ).createShader(
                  rect,
                ),
        child: const SizedBox(
          width: 32,
          height: 32,
          child: Icon(
            Icons.star,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
