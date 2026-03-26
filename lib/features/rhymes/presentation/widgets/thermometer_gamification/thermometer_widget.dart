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
    // Se o progresso de fogos começou (acima do nível 3), as estrelas são ocultadas
    bool isFirePhase = fireProgress > 0.1;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.05), width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: isFirePhase 
              ? List.generate(3, (index) {
                  double iconProgress = (fireProgress - index).clamp(0.0, 1.0);
                  return _GradualIcon(
                    icon: Icons.local_fire_department_rounded,
                    percentage: iconProgress,
                    color: Colors.orangeAccent,
                    isAnimating: iconProgress > 0.1,
                  );
                })
              : List.generate(3, (index) {
                  double iconProgress = (starProgress - index).clamp(0.0, 1.0);
                  return _GradualIcon(
                    icon: Icons.star_rounded,
                    percentage: iconProgress,
                    color: Colors.purpleAccent,
                    isAnimating: false,
                  );
                }),
          ),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              mentorFeedback.toUpperCase(),
              key: ValueKey<String>(mentorFeedback),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isFirePhase ? Colors.orangeAccent : Colors.white70, 
                fontSize: 11, 
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                fontFamily: 'monospace', // Estilo terminal para combinar com o Versin
              ),
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
        blendMode: BlendMode.srcIn,
        shaderCallback: (rect) {
          return LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            stops: [percentage, percentage],
            colors: [color, Colors.white.withOpacity(0.1)], // Preenchido vs Vazio
          ).createShader(rect);
        },
        child: Icon(
          icon,
          size: 28,
          // Cor base branca para o ShaderMask processar
          color: Colors.white, 
        ),
      ),
    );
  }
}