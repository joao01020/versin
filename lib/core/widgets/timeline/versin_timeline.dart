import 'package:flutter/material.dart';

class VersinTimeline extends StatefulWidget {
  final int currentStep;
  final Color activeColor;
  final Function(List<String> rimas)? onRimaFinalizada;

  const VersinTimeline({
    super.key,
    required this.currentStep,
    required this.activeColor,
    this.onRimaFinalizada,
  });

  @override
  State<VersinTimeline> createState() => _VersinTimelineState();
}

class _VersinTimelineState extends State<VersinTimeline> {
  final List<Map<String, dynamic>> _rimasData = [];
  int _idCounter = 0;
  // Variável para armazenar a largura do card para sincronizar a timeline
  double _cardWidth = 80.0; 

  @override
  void initState() {
    super.initState();
    if (_rimasData.isEmpty) _injetarNovaRimaInline();
  }

  void _injetarNovaRimaInline() {
    final int currentId = _idCounter++;
    final controller = TextEditingController();
    final focusNode = FocusNode();

    setState(() {
      _rimasData.add({
        'id': currentId,
        'controller': controller,
        'focusNode': focusNode,
        'isNew': true,
      });
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _rimasData.firstWhere((e) => e['id'] == currentId)['isNew'] = false);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => focusNode.requestFocus());
  }

  @override
  void dispose() {
    for (var rima in _rimasData) {
      rima['controller'].dispose();
      rima['focusNode'].dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // TIMELINE SINCRONIZADA
        Container(
          height: 40,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: CustomPaint(
            painter: TimelinePainter(
              itemCount: _rimasData.length,
              activeColor: widget.activeColor,
            ),
          ),
        ),
        
        // LISTA DE CARDS
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _rimasData.length,
            itemBuilder: (context, index) {
              final rima = _rimasData[index];
              final bool isNew = rima['isNew'] ?? false;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                margin: const EdgeInsets.only(right: 8),
                constraints: const BoxConstraints(minWidth: 70),
                decoration: BoxDecoration(
                  color: widget.activeColor.withOpacity(isNew ? 0.15 : 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.activeColor.withOpacity(isNew ? 0.5 : 0.15), 
                    width: 1.2
                  ),
                  boxShadow: isNew 
                      ? [BoxShadow(color: widget.activeColor.withOpacity(0.2), blurRadius: 6, spreadRadius: 0)] 
                      : [],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: IntrinsicWidth(
                    child: TextField(
                      controller: rima['controller'],
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(
                        border: InputBorder.none, 
                        hintText: "Rima...", 
                        hintStyle: TextStyle(color: Colors.white24)
                      ),
                      onSubmitted: (_) => _injetarNovaRimaInline(),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class TimelinePainter extends CustomPainter {
  final int itemCount;
  final Color activeColor;

  TimelinePainter({required this.itemCount, required this.activeColor});

  @override
  void paint(Canvas canvas, Size size) {
    // Calculamos o espaçamento baseando no número de cards potenciais
    final double spacing = size.width / 4;
    final double y = size.height / 2;
    
    final paintLine = Paint()..color = Colors.white10..strokeWidth = 2..strokeCap = StrokeCap.round;
    final paintActive = Paint()..color = activeColor..strokeWidth = 2..strokeCap = StrokeCap.round;

    // Linha base
    canvas.drawLine(Offset(0, y), Offset(size.width, y), paintLine);

    // O progresso agora avança de acordo com o índice do card (itemCount - 1)
    double progressWidth = ((itemCount - 1) * spacing).clamp(0.0, size.width);
    
    // Animação visual da linha ativa
    canvas.drawLine(Offset(0, y), Offset(progressWidth, y), paintActive);

    // Nós da timeline
    for (int i = 0; i < 5; i++) {
      double x = i * spacing;
      bool isReached = i < itemCount;

      if (isReached) {
        // Brilho neon sutil no ponto atingido
        canvas.drawCircle(Offset(x, y), 8, Paint()..color = activeColor.withOpacity(0.1)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
      }

      canvas.drawCircle(Offset(x, y), 5, Paint()..color = isReached ? activeColor : const Color(0xFF1A1A1A)..style = PaintingStyle.fill);
      canvas.drawCircle(Offset(x, y), 5, Paint()..color = isReached ? activeColor : Colors.white24..style = PaintingStyle.stroke..strokeWidth = 1.2);
    }
  }

  @override
  bool shouldRepaint(covariant TimelinePainter oldDelegate) => oldDelegate.itemCount != itemCount;
}