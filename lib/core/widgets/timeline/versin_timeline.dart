import 'package:flutter/material.dart';

class VersinTimeline
    extends
        StatefulWidget {
  final int currentStep;
  final Color activeColor;

  final List<
    String
  >
  savedRhymes;

  final ValueChanged<
    String
  >
  onAddRhyme;
  final ValueChanged<
    String
  >
  onRemoveRhyme;
  final ValueChanged<
    String
  >?
  onTextChanged;

  const VersinTimeline({
    super.key,
    required this.currentStep,
    required this.activeColor,
    required this.savedRhymes,
    required this.onAddRhyme,
    required this.onRemoveRhyme,
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
    _RimaItem
  >
  _rimas = [];

  int _idCounter = 0;

  static const int _maxRimas = 17;

  @override
  void initState() {
    super.initState();

    _syncFromSavedRhymes();
  }

  @override
  void didUpdateWidget(
    covariant VersinTimeline oldWidget,
  ) {
    super.didUpdateWidget(
      oldWidget,
    );

    if (!_sameList(
      oldWidget.savedRhymes,
      widget.savedRhymes,
    )) {
      _syncFromSavedRhymes();
    }
  }

  bool _sameList(
    List<
      String
    >
    a,
    List<
      String
    >
    b,
  ) {
    if (a.length !=
        b.length) {
      return false;
    }

    for (
      int i = 0;
      i <
          a.length;
      i++
    ) {
      if (a[i] !=
          b[i]) {
        return false;
      }
    }

    return true;
  }

  void _syncFromSavedRhymes() {
    final saved = widget.savedRhymes
        .map(
          (
            rima,
          ) => rima.trim(),
        )
        .where(
          (
            rima,
          ) => rima.isNotEmpty,
        )
        .take(
          _maxRimas,
        )
        .toList();

    for (final item in _rimas) {
      item.controller.dispose();
      item.focusNode.dispose();
    }

    _rimas.clear();

    for (final rhyme in saved) {
      _rimas.add(
        _RimaItem(
          id: _idCounter++,
          controller: TextEditingController(
            text: rhyme,
          ),
          focusNode: FocusNode(),
          isAdded: true,
        ),
      );
    }

    if (_rimas.length <
        _maxRimas) {
      _rimas.add(
        _createPendingRhyme(),
      );
    }

    if (mounted) {
      setState(
        () {},
      );
    }

    WidgetsBinding.instance.addPostFrameCallback(
      (
        _,
      ) {
        if (!mounted) {
          return;
        }

        final pending = _rimas
            .where(
              (
                item,
              ) => !item.isAdded,
            )
            .firstOrNull;

        pending?.focusNode.requestFocus();
      },
    );
  }

  _RimaItem _createPendingRhyme() {
    return _RimaItem(
      id: _idCounter++,
      controller: TextEditingController(),
      focusNode: FocusNode(),
      isNew: true,
    );
  }

  void _confirmarRima(
    int id,
  ) {
    final index = _rimas.indexWhere(
      (
        rima,
      ) =>
          rima.id ==
          id,
    );

    if (index ==
        -1) {
      return;
    }

    final item = _rimas[index];

    final text = item.controller.text.trim();

    if (text.isEmpty) {
      return;
    }

    final alreadyExists = widget.savedRhymes.any(
      (
        saved,
      ) =>
          saved.trim().toLowerCase() ==
          text.toLowerCase(),
    );

    if (alreadyExists) {
      item.controller.clear();
      return;
    }

    widget.onAddRhyme(
      text,
    );
  }

  void _removerRima(
    _RimaItem item,
  ) {
    if (!item.isAdded) {
      item.controller.clear();
      return;
    }

    final text = item.controller.text.trim();

    if (text.isEmpty) {
      return;
    }

    widget.onRemoveRhyme(
      text,
    );
  }

  int get _completedCount {
    return _rimas
        .where(
          (
            rima,
          ) => rima.isAdded,
        )
        .length;
  }

  @override
  void dispose() {
    for (final rima in _rimas) {
      rima.controller.dispose();
      rima.focusNode.dispose();
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
          width: double.infinity,
          height: 40,
          padding: const EdgeInsets.symmetric(
            horizontal: 40,
          ),
          child: CustomPaint(
            painter: TimelinePainter(
              itemCount: _completedCount,
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
            itemCount: _rimas.length,
            itemBuilder:
                (
                  context,
                  index,
                ) {
                  final rima = _rimas[index];

                  final bgColor = rima.isAdded
                      ? Colors.white.withValues(
                          alpha: 0.03,
                        )
                      : widget.activeColor.withValues(
                          alpha: rima.isNew
                              ? 0.15
                              : 0.05,
                        );

                  final borderColor = rima.isAdded
                      ? Colors.white.withValues(
                          alpha: 0.1,
                        )
                      : widget.activeColor.withValues(
                          alpha: rima.isNew
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
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 8,
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
                          rima.isNew &&
                              !rima.isAdded
                          ? [
                              BoxShadow(
                                color: widget.activeColor.withValues(
                                  alpha: 0.2,
                                ),
                                blurRadius: 6,
                              ),
                            ]
                          : const [],
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IntrinsicWidth(
                            child: TextField(
                              controller: rima.controller,
                              focusNode: rima.focusNode,
                              enabled: !rima.isAdded,
                              onChanged: widget.onTextChanged,
                              onSubmitted:
                                  (
                                    _,
                                  ) {
                                    _confirmarRima(
                                      rima.id,
                                    );
                                  },
                              style: TextStyle(
                                color: rima.isAdded
                                    ? Colors.white54
                                    : Colors.white,
                                fontSize: 13,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Rima...',
                                hintStyle: TextStyle(
                                  color: rima.isAdded
                                      ? Colors.transparent
                                      : Colors.white24,
                                ),
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),

                          if (rima.isAdded ||
                              _rimas.length >
                                  1) ...[
                            const SizedBox(
                              width: 8,
                            ),

                            GestureDetector(
                              onTap: () {
                                _removerRima(
                                  rima,
                                );
                              },
                              child: Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: rima.isAdded
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

class _RimaItem {
  final int id;
  final TextEditingController controller;
  final FocusNode focusNode;

  bool isNew;
  bool isAdded;

  _RimaItem({
    required this.id,
    required this.controller,
    required this.focusNode,
    this.isNew = false,
    this.isAdded = false,
  });
}

class TimelinePainter
    extends
        CustomPainter {
  final int itemCount;
  final Color activeColor;
  final int maxItems;

  const TimelinePainter({
    required this.itemCount,
    required this.activeColor,
    required this.maxItems,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    if (maxItems <=
        1) {
      return;
    }

    final spacing =
        size.width /
        (maxItems -
            1);

    final y =
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

    final reachedItems =
        itemCount >
            0
        ? itemCount -
              1
        : 0;

    final progressWidth =
        (reachedItems *
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
      final x =
          i *
          spacing;

      final isReached =
          i <
          itemCount;

      final position = Offset(
        x,
        y,
      );

      if (isReached) {
        canvas.drawCircle(
          position,
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
        position,
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
        position,
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
  bool shouldRepaint(
    covariant TimelinePainter oldDelegate,
  ) {
    return oldDelegate.itemCount !=
            itemCount ||
        oldDelegate.maxItems !=
            maxItems ||
        oldDelegate.activeColor !=
            activeColor;
  }
}

extension _IterableFirstOrNull<
  T
>
    on
        Iterable<
          T
        > {
  T? get firstOrNull {
    final iterator = this.iterator;

    if (!iterator.moveNext()) {
      return null;
    }

    return iterator.current;
  }
}
