import 'package:flutter/material.dart';

// ============================================================
// DETACHED WORKSPACE PLACEHOLDER
// ============================================================

class StudioDetachedWorkspacePlaceholder extends StatelessWidget {
  final Color activeColor;
  final VoidCallback onDockAll;

  const StudioDetachedWorkspacePlaceholder({
    super.key,
    required this.activeColor,
    required this.onDockAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.dashboard_customize_outlined,
              size: 28,
              color: activeColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 10),
            const Text(
              'LETRA e MAPA estão destacados',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: onDockAll,
              icon: Icon(
                Icons.call_merge_rounded,
                size: 16,
                color: activeColor,
              ),
              label: Text(
                'ENCAIXAR PAINÉIS',
                style: TextStyle(
                  color: activeColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
