import 'package:flutter/material.dart';

class TypingIndicator
    extends
        StatefulWidget {
  final Color color;

  const TypingIndicator({
    super.key,
    required this.color,
  });

  @override
  State<
    TypingIndicator
  >
  createState() => _TypingIndicatorState();
}

class _TypingIndicatorState
    extends
        State<
          TypingIndicator
        >
    with
        SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 900,
      ),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return AnimatedBuilder(
      animation: _controller,
      builder:
          (
            context,
            _,
          ) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                3,
                (
                  index,
                ) {
                  final phase =
                      (_controller.value -
                          (index *
                              0.16)) %
                      1.0;

                  final pulse =
                      phase <
                          0.5
                      ? phase *
                            2
                      : (1 -
                                phase) *
                            2;

                  return Padding(
                    padding: EdgeInsets.only(
                      right:
                          index ==
                              2
                          ? 0
                          : 5,
                    ),
                    child: Transform.translate(
                      offset: Offset(
                        0,
                        -3 *
                            pulse,
                      ),
                      child: Opacity(
                        opacity:
                            0.35 +
                            (0.65 *
                                pulse),
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: widget.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
    );
  }
}
