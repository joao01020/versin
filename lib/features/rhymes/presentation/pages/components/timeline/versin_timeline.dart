import 'package:flutter/material.dart';
import 'dart:math' as math;

class VersinTimeline extends StatefulWidget {
  final int currentStep;
  final double stepProgress;
  final Color activeColor;

  const VersinTimeline({
    super.key,
    required this.currentStep,
    required this.stepProgress,
    required this.activeColor,
  });

  @override
  State<VersinTimeline> createState() => _VersinTimelineState();
}

class _VersinTimelineState extends State<VersinTimeline> with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // A Linha do Tempo Animada
        Container(
          height: 50, // Reduzi levemente de 60 para 50 para ganhar espaço no mobile
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: CustomPaint(
            painter: TimelinePainter(
              currentStep: widget.currentStep,
              stepProgress: widget.stepProgress,
              activeColor: widget.activeColor,
            ),
          ),
        ),
        // Removido o SizedBox e o Text "versin" que causavam a duplicidade e ocupavam espaço extra
      ],
    );
  }
}

class TimelinePainter extends CustomPainter {
  final int currentStep;
  final double stepProgress;
  final Color activeColor;

  TimelinePainter({
    required this.currentStep,
    required this.stepProgress,
    required this.activeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = Colors.white10
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final paintActiveLine = Paint()
      ..color = activeColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final double spacing = size.width / 5; // Espaçamento entre os 6 pontos
    final double y = size.height / 2;

    // 1. Desenhar as linhas de fundo (cinza) e as linhas ativas (coloridas)
    for (int i = 0; i < 5; i++) {
      double startX = i * spacing;
      double endX = (i + 1) * spacing;
      
      canvas.drawLine(Offset(startX, y), Offset(endX, y), paintLine);
      
      if (currentStep > i + 1) {
        canvas.drawLine(Offset(startX, y), Offset(endX, y), paintActiveLine);
      }
    }

    // 2. Desenhar os Pontos (Nodes)
    for (int i = 0; i < 6; i++) {
      double x = i * spacing;
      bool isCompleted = currentStep > i + 1;
      bool isCurrent = currentStep == i + 1;

      canvas.drawCircle(
        Offset(x, y),
        6,
        Paint()..color = const Color(0xFF1A1A1A)..style = PaintingStyle.fill,
      );
      
      canvas.drawCircle(
        Offset(x, y),
        6,
        Paint()..color = Colors.white24..style = PaintingStyle.stroke..strokeWidth = 1,
      );

      if (isCurrent || isCompleted) {
        double fillPercent = isCompleted ? 1.0 : stepProgress;
        
        canvas.drawCircle(
          Offset(x, y),
          4 * fillPercent,
          Paint()..color = activeColor..style = PaintingStyle.fill,
        );

        if (isCurrent) {
          canvas.drawCircle(
            Offset(x, y),
            8,
            Paint()
              ..color = activeColor.withOpacity(0.2)
              ..style = PaintingStyle.fill,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant TimelinePainter oldDelegate) {
    return oldDelegate.currentStep != currentStep || 
           oldDelegate.stepProgress != stepProgress ||
           oldDelegate.activeColor != activeColor;
  }
}