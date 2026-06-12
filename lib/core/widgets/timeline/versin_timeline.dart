import 'package:flutter/material.dart';

class VersinTimeline
    extends
        StatefulWidget {
  final int currentStep;
  final Color activeColor;
  final Function(
    List<
      String
    >
    rimas,
  )?
  onRimaFinalizada;
  // NOVO: Callback disparado a cada letra digitada no bloco atual
  final Function(
    String texto,
  )?
  onTextChanged;

  const VersinTimeline({
    super.key,
    required this.currentStep,
    required this.activeColor,
    this.onRimaFinalizada,
    this.onTextChanged,
  });

  @override
  State<
    VersinTimeline
  >
  createState() => _VersinTimelineState();
}

class _VersinTimelineState
    extends
        State<
          VersinTimeline
        > {
  final List<
    Map<
      String,
      dynamic
    >
  >
  _rimasData = [];
  int _idCounter = 0;
  final int _maxRimas = 17;

  @override
  void initState() {
    super.initState();
    if (_rimasData.isEmpty) _injetarNovaRimaInline();
  }

  void _injetarNovaRimaInline() {
    if (_rimasData.length >=
        _maxRimas)
      return;

    final int currentId = _idCounter++;
    final controller = TextEditingController();
    final focusNode = FocusNode();

    setState(
      () {
        _rimasData.add(
          {
            'id': currentId,
            'controller': controller,
            'focusNode': focusNode,
            'isNew': true,
            'isAdded': false,
          },
        );
      },
    );

    Future.delayed(
      const Duration(
        milliseconds: 600,
      ),
      () {
        if (mounted) {
          setState(
            () {
              final index = _rimasData.indexWhere(
                (
                  e,
                ) =>
                    e['id'] ==
                    currentId,
              );
              if (index !=
                  -1)
                _rimasData[index]['isNew'] = false;
            },
          );
        }
      },
    );

    WidgetsBinding.instance.addPostFrameCallback(
      (
        _,
      ) => focusNode.requestFocus(),
    );
  }

  void _confirmarRima(
    int id,
  ) {
    setState(
      () {
        final index = _rimasData.indexWhere(
          (
            e,
          ) =>
              e['id'] ==
              id,
        );
        if (index !=
                -1 &&
            _rimasData[index]['controller'].text.isNotEmpty) {
          _rimasData[index]['isAdded'] = true;
        }
      },
    );

    _injetarNovaRimaInline();
    _notificarParent();
  }

  void _removerRima(
    int id,
  ) {
    setState(
      () {
        final index = _rimasData.indexWhere(
          (
            e,
          ) =>
              e['id'] ==
              id,
        );
        if (index !=
            -1) {
          _rimasData[index]['controller'].dispose();
          _rimasData[index]['focusNode'].dispose();
          _rimasData.removeAt(
            index,
          );
        }

        if (_rimasData
                .where(
                  (
                    e,
                  ) => !e['isAdded'],
                )
                .isEmpty &&
            _rimasData.length <
                _maxRimas) {
          _injetarNovaRimaInline();
        }
      },
    );
    _notificarParent();
  }

  void _notificarParent() {
    if (widget.onRimaFinalizada !=
        null) {
      final rimasConcluidas = _rimasData
          .where(
            (
              e,
            ) => e['isAdded'],
          )
          .map<
            String
          >(
            (
              e,
            ) => e['controller'].text,
          )
          .toList();
      widget.onRimaFinalizada!(
        rimasConcluidas,
      );
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
  Widget build(
    BuildContext context,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 40,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 40,
          ),
          child: CustomPaint(
            painter: TimelinePainter(
              itemCount: _rimasData.length,
              activeColor: widget.activeColor,
              maxItems: _maxRimas,
            ),
          ),
        ),
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(
            horizontal: 32,
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _rimasData.length,
            itemBuilder:
                (
                  context,
                  index,
                ) {
                  final rima = _rimasData[index];
                  final bool isNew =
                      rima['isNew'] ??
                      false;
                  final bool isAdded =
                      rima['isAdded'] ??
                      false;

                  final bgColor = isAdded
                      ? Colors.white.withValues(
                          alpha: 0.03,
                        )
                      : widget.activeColor.withValues(
                          alpha: isNew
                              ? 0.15
                              : 0.05,
                        );

                  final borderColor = isAdded
                      ? Colors.white.withValues(
                          alpha: 0.1,
                        )
                      : widget.activeColor.withValues(
                          alpha: isNew
                              ? 0.5
                              : 0.15,
                        );

                  return AnimatedContainer(
                    duration: const Duration(
                      milliseconds: 400,
                    ),
                    margin: const EdgeInsets.only(
                      right: 8,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 70,
                    ),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(
                        12,
                      ),
                      border: Border.all(
                        color: borderColor,
                        width: 1.2,
                      ),
                      boxShadow:
                          (isNew &&
                              !isAdded)
                          ? [
                              BoxShadow(
                                color: widget.activeColor.withValues(
                                  alpha: 0.2,
                                ),
                                blurRadius: 6,
                                spreadRadius: 0,
                              ),
                            ]
                          : [],
                    ),
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 8,
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IntrinsicWidth(
                            child: TextField(
                              controller: rima['controller'],
                              focusNode: rima['focusNode'],
                              enabled: !isAdded,
                              // AQUI: Conecta a escrita do usuário com o callback
                              onChanged: widget.onTextChanged,
                              style: TextStyle(
                                color: isAdded
                                    ? Colors.white54
                                    : Colors.white,
                                fontSize: 13,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: "Rima...",
                                hintStyle: TextStyle(
                                  color: isAdded
                                      ? Colors.transparent
                                      : Colors.white24,
                                ),
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onSubmitted:
                                  (
                                    _,
                                  ) => _confirmarRima(
                                    rima['id'],
                                  ),
                            ),
                          ),

                          if (isAdded ||
                              _rimasData.length >
                                  1) ...[
                            const SizedBox(
                              width: 8,
                            ),
                            GestureDetector(
                              onTap: () => _removerRima(
                                rima['id'],
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: isAdded
                                    ? Colors.white30
                                    : widget.activeColor.withValues(
                                        alpha: 0.5,
                                      ),
                              ),
                            ),
                          ],
                        ],
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

class TimelinePainter
    extends
        CustomPainter {
  final int itemCount;
  final Color activeColor;
  final int maxItems;

  TimelinePainter({
    required this.itemCount,
    required this.activeColor,
    required this.maxItems,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final double spacing =
        size.width /
        (maxItems -
            1);
    final double y =
        size.height /
        2;

    final paintLine = Paint()
      ..color = Colors.white10
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final paintActive = Paint()
      ..color = activeColor
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(
        0,
        y,
      ),
      Offset(
        size.width,
        y,
      ),
      paintLine,
    );

    double progressWidth =
        ((itemCount >
                        0
                    ? itemCount -
                          1
                    : 0) *
                spacing)
            .clamp(
              0.0,
              size.width,
            );
    canvas.drawLine(
      Offset(
        0,
        y,
      ),
      Offset(
        progressWidth,
        y,
      ),
      paintActive,
    );

    for (
      int i = 0;
      i <
          maxItems;
      i++
    ) {
      double x =
          i *
          spacing;
      bool isReached =
          i <
          itemCount;

      if (isReached) {
        canvas.drawCircle(
          Offset(
            x,
            y,
          ),
          8,
          Paint()
            ..color = activeColor.withValues(
              alpha: 0.1,
            )
            ..maskFilter = const MaskFilter.blur(
              BlurStyle.normal,
              3,
            ),
        );
      }

      canvas.drawCircle(
        Offset(
          x,
          y,
        ),
        5,
        Paint()
          ..color = isReached
              ? activeColor
              : const Color(
                  0xFF1A1A1A,
                )
          ..style = PaintingStyle.fill,
      );

      canvas.drawCircle(
        Offset(
          x,
          y,
        ),
        5,
        Paint()
          ..color = isReached
              ? activeColor
              : Colors.white24
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
  }

  @override
  bool
  shouldRepaint(
    covariant TimelinePainter oldDelegate,
  ) =>
      oldDelegate.itemCount !=
          itemCount ||
      oldDelegate.maxItems !=
          maxItems;
}
