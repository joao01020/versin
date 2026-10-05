import 'package:flutter/material.dart';

class ActionButtonWidget
    extends
        StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const ActionButtonWidget({
    super.key,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        splashColor: color.withValues(
          alpha: 0.1,
        ),
        highlightColor: color.withValues(
          alpha: 0.05,
        ),
        child: Container(
          padding: const EdgeInsets.all(
            10,
          ),
          decoration: BoxDecoration(
            color: color.withValues(
              alpha: 0.2,
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withValues(
                alpha: 0.5,
              ),
            ),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
      ),
    );
  }
}
