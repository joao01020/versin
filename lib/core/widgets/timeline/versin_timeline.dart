import 'package:flutter/material.dart';

class VersinTimeline extends StatefulWidget {
  final int currentStep;
  final double stepProgress;
  final Color activeColor;
  final Function(List<String> rimas)? onRimaFinalizada;

  const VersinTimeline({
    super.key,
    required this.currentStep,
    required this.stepProgress,
    required this.activeColor,
    this.onRimaFinalizada,
  });

  @override
  State<VersinTimeline> createState() => _VersinTimelineState();
}

class _VersinTimelineState extends State<VersinTimeline> {
  final List<Map<String, dynamic>> _rimasData = [];
  int _idCounter = 0;

  @override
  void initState() {
    super.initState();
    // SÊNIOR: Se a página acabou de abrir, já injeta a estrutura da primeira rima de imediato
    if (widget.currentStep == 1) {
      _inicializarPrimeiraRima();
    }
  }

  // Retorna uma lista de strings limpa contendo apenas os textos válidos
  List<String> _obterListaDeRimasLimpa() {
    return _rimasData
        .map((r) => (r['controller'] as TextEditingController).text.trim())
        .where((text) => text.isNotEmpty)
        .toList();
  }

  // Inicialização síncrona segura para o initState
  void _inicializarPrimeiraRima() {
    final int currentId = _idCounter++;
    final controller = TextEditingController();
    final focusNode = FocusNode();

    focusNode.addListener(() {
      if (!focusNode.hasFocus) {
        _validarEEnviarDados();
      }
    });

    _rimasData.add({
      'id': currentId,
      'controller': controller,
      'focusNode': focusNode,
    });

    // Garante que o foco seja chamado assim que o primeiro frame terminar de renderizar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (focusNode.canRequestFocus) {
        focusNode.requestFocus();
      }
    });
  }

  // Método usado para cliques subsequentes no botão "+" da UI
  void _injetarNovaRimaInline() {
    final int currentId = _idCounter++;
    final controller = TextEditingController();
    final focusNode = FocusNode();

    focusNode.addListener(() {
      if (!focusNode.hasFocus) {
        _validarEEnviarDados();
      }
    });

    setState(() {
      _rimasData.add({
        'id': currentId,
        'controller': controller,
        'focusNode': focusNode,
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (focusNode.canRequestFocus) {
        focusNode.requestFocus();
      }
    });
  }

  void _validarEEnviarDados() {
    final rimasValidas = _obterListaDeRimasLimpa();
    if (rimasValidas.isNotEmpty && widget.onRimaFinalizada != null) {
      widget.onRimaFinalizada!(rimasValidas);
    }
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
      crossAxisAlignment: CrossAxisAlignment.start, // ➔ CORRIGIDO: Sintaxe ajustada aqui
      children: [
        // 1. Linha do tempo com detecção nos micro-ícones (+ e Lápis)
        GestureDetector(
          onTapUp: (details) {
            if (widget.currentStep == 1) {
              final localX = details.localPosition.dx;
              if (localX >= 15 && localX <= 35) {
                _injetarNovaRimaInline();
              } else if (localX >= 45 && localX <= 65) {
                debugPrint("Gatilho CineFlow (Lápis)");
              }
            }
          },
          child: MouseRegion(
            cursor: widget.currentStep == 1 ? SystemMouseCursors.click : SystemMouseCursors.basic,
            child: Container(
              height: 40,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 40),
              color: Colors.transparent,
              child: CustomPaint(
                painter: TimelinePainter(
                  currentStep: widget.currentStep,
                  stepProgress: widget.stepProgress,
                  activeColor: widget.activeColor,
                ),
              ),
            ),
          ),
        ),

        // 2. Container de Tags Roxas (Modo Estúdio Inline)
        if (_rimasData.isNotEmpty && widget.currentStep == 1) ...[
          const Padding(
            padding: EdgeInsets.only(left: 42, top: 4, bottom: 6),
            child: Text(
              "Ordem do Fluxo (Toque para editar):",
              style: TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ),
          Container(
            height: 38,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Theme(
              data: ThemeData(canvasColor: Colors.transparent),
              child: ReorderableListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _rimasData.length,
                buildDefaultDragHandles: false, // Mantém o '=' desativado e limpo
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final item = _rimasData.removeAt(oldIndex);
                    _rimasData.insert(newIndex, item);
                  });
                  _validarEEnviarDados(); // Notifica mudança de ordem para o chatpage
                },
                itemBuilder: (context, index) {
                  final rima = _rimasData[index];
                  final TextEditingController controller = rima['controller'];
                  final FocusNode focusNode = rima['focusNode'];

                  return ReorderableDelayedDragStartListener(
                    key: ValueKey("rima-id-${rima['id']}"),
                    index: index,
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: widget.activeColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: widget.activeColor.withOpacity(0.3), width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: widget.activeColor.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IntrinsicWidth(
                            child: TextField(
                              controller: controller,
                              focusNode: focusNode,
                              style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                              cursorColor: widget.activeColor,
                              maxLines: 1,
                              textInputAction: TextInputAction.done,
                              decoration: const InputDecoration(
                                hintText: "Rima...",
                                hintStyle: TextStyle(color: Colors.white24, fontSize: 12),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onSubmitted: (value) {
                                if (value.trim().isEmpty) {
                                  setState(() => _rimasData.removeAt(index));
                                } else {
                                  focusNode.unfocus(); // Dispara o focus listener para inicializar o chat
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                controller.dispose();
                                focusNode.dispose();
                                _rimasData.removeAt(index);
                              });
                              _validarEEnviarDados();
                            },
                            child: Icon(Icons.close_rounded, size: 12, color: Colors.white.withOpacity(0.3)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
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

    final double spacing = size.width / 5; 
    final double y = size.height / 2;

    for (int i = 0; i < 5; i++) {
      double startX = i * spacing;
      double endX = (i + 1) * spacing;
      canvas.drawLine(Offset(startX, y), Offset(endX, y), paintLine);
      if (currentStep > i + 1) {
        canvas.drawLine(Offset(startX, y), Offset(endX, y), paintActiveLine);
      }
    }

    for (int i = 0; i < 6; i++) {
      double x = i * spacing;
      bool isCompleted = currentStep > i + 1;
      bool isCurrent = currentStep == i + 1;

      canvas.drawCircle(Offset(x, y), 6, Paint()..color = const Color(0xFF1A1A1A)..style = PaintingStyle.fill);
      canvas.drawCircle(Offset(x, y), 6, Paint()..color = Colors.white24..style = PaintingStyle.stroke..strokeWidth = 1);

      if (isCurrent || isCompleted) {
        double fillPercent = isCompleted ? 1.0 : stepProgress;
        canvas.drawCircle(Offset(x, y), 4 * fillPercent, Paint()..color = activeColor..style = PaintingStyle.fill);

        if (isCurrent) {
          canvas.drawCircle(Offset(x, y), 8, Paint()..color = activeColor.withOpacity(0.2)..style = PaintingStyle.fill);

          if (i == 0) {
            _drawMicroIcon(canvas, Offset(x - 15, y), Icons.add_rounded, activeColor);
            _drawMicroIcon(canvas, Offset(x + 15, y), Icons.edit_outlined, Colors.white38);
          }
        }
      }
    }
  }

  void _drawMicroIcon(Canvas canvas, Offset offset, IconData icon, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, offset - Offset(textPainter.width / 2, textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant TimelinePainter oldDelegate) {
    return oldDelegate.currentStep != currentStep ||
        oldDelegate.stepProgress != stepProgress ||
        oldDelegate.activeColor != activeColor;
  }
}