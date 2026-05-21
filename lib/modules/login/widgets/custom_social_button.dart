import 'package:flutter/material.dart';

class CustomSocialButton extends StatelessWidget {
  final String label;
  final bool isGoogle;
  final VoidCallback onTap;

  const CustomSocialButton({
    super.key,
    required this.label,
    required this.isGoogle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CustomPaint(
                painter: isGoogle ? _GoogleIconPainter() : _GitHubIconPainter(),
              ),
            ),
            const Expanded(child: SizedBox()),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const Expanded(child: SizedBox()),
            const Icon(Icons.chevron_right, color: Colors.white12, size: 16),
          ],
        ),
      ),
    );
  }
}

class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Paint paint = Paint()..style = PaintingStyle.fill;

    paint.color = const Color(0xFFEA4335);
    canvas.drawPath(Path()..moveTo(w * 0.5, h * 0.45)..lineTo(w * 0.5, 0)..cubicTo(w * 0.28, 0, w * 0.1, h * 0.15, w * 0.03, h * 0.35)..lineTo(w * 0.21, h * 0.49)..cubicTo(w * 0.26, h * 0.38, w * 0.37, h * 0.3, w * 0.5, h * 0.45), paint);

    paint.color = const Color(0xFF4285F4);
    canvas.drawPath(Path()..moveTo(w, h * 0.5)..cubicTo(w, h * 0.35, w * 0.94, h * 0.21, w * 0.84, h * 0.11)..lineTo(w * 0.5, h * 0.45)..lineTo(w * 0.5, h * 0.55)..lineTo(w * 0.82, h * 0.55)..cubicTo(w * 0.8, h * 0.65, w * 0.72, h * 0.73, w * 0.62, h * 0.78)..lineTo(w * 0.8, h * 0.92)..cubicTo(w * 0.92, h * 0.82, w, h * 0.67, w, h * 0.5), paint);

    paint.color = const Color(0xFFFBBC05);
    canvas.drawPath(Path()..moveTo(w * 0.03, h * 0.35)..cubicTo(0, h * 0.44, 0, h * 0.56, w * 0.03, h * 0.65)..lineTo(w * 0.21, h * 0.51)..cubicTo(w * 0.2, h * 0.47, w * 0.2, h * 0.43, w * 0.21, h * 0.49)..lineTo(w * 0.03, h * 0.35), paint);

    paint.color = const Color(0xFF34A853);
    canvas.drawPath(Path()..moveTo(w * 0.03, h * 0.65)..lineTo(w * 0.21, h * 0.51)..cubicTo(w * 0.26, h * 0.62, w * 0.37, h * 0.7, w * 0.5, h * 0.7)..cubicTo(w * 0.55, h * 0.7, w * 0.59, h * 0.69, w * 0.62, h * 0.67)..lineTo(w * 0.8, h * 0.92)..cubicTo(w * 0.72, h * 0.97, w * 0.61, h, w * 0.5, h)..cubicTo(w * 0.3, h, w * 0.12, h * 0.86, w * 0.03, h * 0.65), paint);
  }
  @override bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _GitHubIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Paint paint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    canvas.drawPath(Path()..moveTo(w * 0.5, 0)..cubicTo(w * 0.22, 0, 0, h * 0.22, 0, h * 0.5)..cubicTo(0, h * 0.72, w * 0.14, h * 0.91, w * 0.34, h * 0.98)..cubicTo(w * 0.37, h * 0.98, w * 0.38, h * 0.97, w * 0.38, h * 0.95)..lineTo(w * 0.38, h * 0.88)..cubicTo(w * 0.24, h * 0.91, w * 0.21, h * 0.81, w * 0.21, h * 0.81)..cubicTo(w * 0.19, h * 0.76, w * 0.15, h * 0.74, w * 0.15, h * 0.74)..cubicTo(w * 0.11, h * 0.71, w * 0.15, h * 0.71, w * 0.15, h * 0.71)..cubicTo(w * 0.2, h * 0.72, w * 0.22, h * 0.76, w * 0.22, h * 0.76)..cubicTo(w * 0.26, h * 0.82, w * 0.32, h * 0.8, w * 0.34, h * 0.79)..cubicTo(w * 0.34, h * 0.75, w * 0.36, h * 0.73, w * 0.38, h * 0.71)..cubicTo(w * 0.27, h * 0.7, w * 0.15, h * 0.65, w * 0.15, h * 0.46)..cubicTo(w * 0.15, h * 0.4, w * 0.17, h * 0.36, w * 0.21, h * 0.32)..cubicTo(w * 0.2, h * 0.3, w * 0.18, h * 0.24, w * 0.21, h * 0.17)..cubicTo(w * 0.21, h * 0.17, w * 0.25, h * 0.15, w * 0.34, h * 0.22)..cubicTo(w * 0.38, h * 0.21, w * 0.42, h * 0.2, w * 0.5, h * 0.2)..cubicTo(w * 0.58, h * 0.2, w * 0.62, h * 0.21, w * 0.66, h * 0.22)..cubicTo(w * 0.75, h * 0.15, w * 0.79, h * 0.17, w * 0.79, h * 0.17)..cubicTo(w * 0.82, h * 0.24, w * 0.8, h * 0.3, w * 0.79, h * 0.32)..cubicTo(w * 0.83, h * 0.36, w * 0.85, h * 0.4, w * 0.85, h * 0.46)..cubicTo(w * 0.85, h * 0.65, w * 0.73, h * 0.7, w * 0.62, h * 0.71)..cubicTo(w * 0.64, h * 0.73, w * 0.66, h * 0.76, w * 0.66, h * 0.8)..lineTo(w * 0.66, h * 0.95)..cubicTo(w * 0.66, h * 0.97, w * 0.67, h * 0.98, w * 0.7, h * 0.98)..cubicTo(w * 0.86, h * 0.91, w, h * 0.72, w, h * 0.5)..cubicTo(w, h * 0.22, w * 0.78, 0, w * 0.5, 0)..close(), paint);
  }
  @override bool shouldRepaint(CustomPainter oldDelegate) => false;
}