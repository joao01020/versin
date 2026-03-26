import 'package:flutter/material.dart';

class ThermometerFeedback extends StatelessWidget {
  final double starProgress; // 0.0 a 3.0 (ex: 1.5 preenche uma estrela e meia)
  final double fireProgress; // 0.0 a 3.0
  final String mentorFeedback;

  const ThermometerFeedback({
    super.key,
    required this.starProgress,
    required this.fireProgress,
    required this.mentorFeedback,
  });

  @override
  Widget build(BuildContext context) {
    // Se o progresso de fogos começou, as estrelas são ocultadas
    bool isFirePhase = fireProgress > 0.1;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: isFirePhase 
              ? List.generate(3, (index) => _GradualIcon(
                  icon: Icons.local_fire_department,
                  percentage: (fireProgress - index).clamp(0.0, 1.0),
                  color: Colors.deepOrangeAccent,
                  isAnimating: (fireProgress - index) > 0.0 && (fireProgress - index) <= 1.0,
                ))
              : List.generate(3, (index) => _GradualIcon(
                  icon: Icons.star,
                  percentage: (starProgress - index).clamp(0.0, 1.0),
                  color: Colors.yellowAccent,
                  isAnimating: false,
                )),
          ),
          const SizedBox(height: 8),
          Text(
            mentorFeedback,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70, 
              fontSize: 12, 
              fontStyle: FontStyle.italic
            ),
          ),
        ],
      ),
    );
  }
}

class _GradualIcon extends StatelessWidget {
  final IconData icon;
  final double percentage; // 0.0 a 1.0
  final Color color;
  final bool isAnimating;

  const _GradualIcon({
    required this.icon,
    required this.percentage,
    required this.color,
    this.isAnimating = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ShaderMask(
        shaderCallback: (rect) {
          return LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            stops: [percentage, percentage],
            colors: [color, Colors.white10], // Cor preenchida e cor vazia
          ).createShader(rect);
        },
        child: Icon(
          icon,
          size: 30,
          color: Colors.white, // O ShaderMask aplica a cor por cima
        ),
      ),
    );
  }
}