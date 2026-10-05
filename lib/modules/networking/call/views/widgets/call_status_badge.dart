import 'package:flutter/material.dart';

import '../../types/call_status.dart';

// ============================================================
// CALL STATUS BADGE
// ============================================================

class CallStatusBadge
    extends
        StatelessWidget {
  static const Color _purple = Color(
    0xFF8B5CF6,
  );

  static const Color _green = Color(
    0xFF34D399,
  );

  static const Color _red = Color(
    0xFFEF4444,
  );

  static const Color _orange = Color(
    0xFFF59E0B,
  );

  final CallStatus status;

  final bool compact;

  const CallStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final color = _statusColor;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact
            ? 7
            : 9,

        vertical: compact
            ? 4
            : 5,
      ),

      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.10,
        ),

        borderRadius: BorderRadius.circular(
          30,
        ),

        border: Border.all(
          color: color.withValues(
            alpha: 0.20,
          ),
        ),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,

        children: [
          Container(
            width: compact
                ? 5
                : 6,

            height: compact
                ? 5
                : 6,

            decoration: BoxDecoration(
              color: color,

              shape: BoxShape.circle,

              boxShadow:
                  status.isActive ||
                      status.isRinging
                  ? [
                      BoxShadow(
                        color: color.withValues(
                          alpha: 0.45,
                        ),

                        blurRadius: 6,
                      ),
                    ]
                  : null,
            ),
          ),

          const SizedBox(
            width: 6,
          ),

          Text(
            status.label,

            style: TextStyle(
              color: color,

              fontSize: compact
                  ? 8
                  : 9,

              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Color get _statusColor {
    switch (status) {
      case CallStatus.ringing:
        return _orange;

      case CallStatus.active:
        return _green;

      case CallStatus.ended:
        return Colors.white38;

      case CallStatus.rejected:
        return _red;

      case CallStatus.cancelled:
        return Colors.white38;

      case CallStatus.missed:
        return _purple;
    }
  }
}
