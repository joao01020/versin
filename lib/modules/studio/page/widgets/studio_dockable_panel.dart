import 'package:flutter/material.dart';

// ============================================================
// STUDIO DOCKABLE PANEL
// ============================================================

class StudioDockablePanel extends StatefulWidget {
  final Color activeColor;
  final String tooltip;
  final VoidCallback onDetach;
  final Widget child;

  const StudioDockablePanel({
    super.key,
    required this.activeColor,
    required this.tooltip,
    required this.onDetach,
    required this.child,
  });

  @override
  State<StudioDockablePanel> createState() => _StudioDockablePanelState();
}

class _StudioDockablePanelState extends State<StudioDockablePanel> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _hovered = true;
        });
      },
      onExit: (_) {
        setState(() {
          _hovered = false;
        });
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: widget.child),
          Positioned(
            top: 7,
            right: 42,
            child: IgnorePointer(
              ignoring: !_hovered,
              child: AnimatedOpacity(
                opacity: _hovered ? 1 : 0,
                duration: const Duration(milliseconds: 130),
                child: Tooltip(
                  message: widget.tooltip,
                  child: Material(
                    color: const Color(0xFF171717),
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: widget.onDetach,
                      child: Padding(
                        padding: const EdgeInsets.all(7),
                        child: Icon(
                          Icons.open_in_new_rounded,
                          size: 15,
                          color: widget.activeColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
