import 'package:flutter/material.dart';

class AnimatedChatMessage
    extends
        StatefulWidget {
  final Widget child;
  final bool isUser;

  const AnimatedChatMessage({
    super.key,
    required this.child,
    required this.isUser,
  });

  @override
  State<
    AnimatedChatMessage
  >
  createState() => _AnimatedChatMessageState();
}

class _AnimatedChatMessageState
    extends
        State<
          AnimatedChatMessage
        >
    with
        SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final Animation<
    double
  >
  _opacity;

  late final Animation<
    Offset
  >
  _slide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 320,
      ),
    );

    _opacity = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slide =
        Tween<
              Offset
            >(
              begin: Offset(
                widget.isUser
                    ? 0.08
                    : -0.08,
                0.04,
              ),
              end: Offset.zero,
            )
            .animate(
              CurvedAnimation(
                parent: _controller,
                curve: Curves.easeOutCubic,
              ),
            );

    _controller.forward();
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
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}
