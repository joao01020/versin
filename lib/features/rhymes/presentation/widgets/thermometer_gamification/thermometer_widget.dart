import 'package:flutter/material.dart';

class ThermometerFeedback extends StatelessWidget {
  final double starProgress; // 0.0 a 3.0
  final double fireProgress; // 0.0 a 3.0
  final String feedbackText; // Adicionei para exibir o comentário abaixo dos ícones

  const ThermometerFeedback({
    super.key,
    required this.starProgress,
    required this.fireProgress,
    required this.feedbackText,
  });

  @override
  Widget build(BuildContext context) {
    // Se o progresso de fogo começou, as estrelas são ocultadas
    bool isFirePhase = fireProgress > 0.05;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: isFirePhase
                ? List.generate(3, (index) {
                    double iconProgress = (fireProgress - index).clamp(0.0, 1.0);
                    return _GradualIcon(
                      icon: Icons.local_fire_department_rounded,
                      percentage: iconProgress,
                      color: Colors.deepOrangeAccent,
                    );
                  })
                : List.generate(3, (index) {
                    double iconProgress = (starProgress - index).clamp(0.0, 1.0);
                    return _GradualIcon(
                      icon: Icons.star_rounded,
                      percentage: iconProgress,
                      color: Colors.purpleAccent,
                    );
                  }),
          ),
        ),
        const SizedBox(height: 12),
        // Exibição do feedback técnico
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            feedbackText,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isFirePhase ? Colors.orangeAccent : Colors.white70,
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

class _GradualIcon extends StatelessWidget {
  final IconData icon;
  final double percentage; // 0.0 a 1.0
  final Color color;

  const _GradualIcon({
    required this.icon,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (rect) {
          return LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            stops: [percentage, percentage],
            colors: [color, Colors.white.withOpacity(0.2)], 
          ).createShader(rect);
        },
        child: Icon(
          icon,
          size: 32,
          color: Colors.white,
        ),
      ),
    );
  }
}