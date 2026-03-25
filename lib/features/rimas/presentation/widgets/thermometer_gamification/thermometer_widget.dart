import 'package:flutter/material.dart';

class TermometroFeedback extends StatelessWidget {
  final double progressoEstrelas; // 0.0 a 3.0 (ex: 1.5 preenche uma estrela e meia)
  final double progressoFogos;    // 0.0 a 3.0
  final String feedbackMentor;

  const TermometroFeedback({
    super.key,
    required this.progressoEstrelas,
    required this.progressoFogos,
    required this.feedbackMentor,
  });

  @override
  Widget build(BuildContext context) {
    // Se o progresso de fogos começou, escondemos as estrelas
    bool faseFogo = progressoFogos > 0.1;

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
            children: faseFogo 
              ? List.generate(3, (index) => _IconeGradual(
                  icon: Icons.local_fire_department,
                  percentual: (progressoFogos - index).clamp(0.0, 1.0),
                  cor: Colors.deepOrangeAccent,
                  animar: (progressoFogos - index) > 0.0 && (progressoFogos - index) <= 1.0,
                ))
              : List.generate(3, (index) => _IconeGradual(
                  icon: Icons.star,
                  percentual: (progressoEstrelas - index).clamp(0.0, 1.0),
                  cor: Colors.yellowAccent,
                  animar: false,
                )),
          ),
          const SizedBox(height: 8),
          Text(
            feedbackMentor,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 12, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}

class _IconeGradual extends StatelessWidget {
  final IconData icon;
  final double percentual; // 0.0 a 1.0
  final Color cor;
  final bool animar;

  const _IconeGradual({
    required this.icon,
    required this.percentual,
    required this.cor,
    this.animar = false,
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
            stops: [percentual, percentual],
            colors: [cor, Colors.white10], // Cor de preenchimento e cor de fundo (vazio)
          ).createShader(rect);
        },
        child: Icon(
          icon,
          size: 30,
          color: Colors.white, // O ShaderMask vai substituir essa cor
        ),
      ),
    );
  }
}