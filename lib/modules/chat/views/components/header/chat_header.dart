import 'package:flutter/material.dart';

import 'package:versin/features/rhymes/presentation/controller/rhymes_controller.dart';

// ============================================================
// CHAT HEADER
// ============================================================

class ChatHeader
    extends
        StatelessWidget {
  // ============================================================
  // PROPRIEDADES
  // ============================================================

  final Color activeColor;

  final RhymesController rhymesController;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  const ChatHeader({
    super.key,
    required this.activeColor,
    required this.rhymesController,
  });

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: const BoxDecoration(
        color: Color(
          0xFF0F0F0F,
        ),
      ),
      child: _buildBranding(),
    );
  }

  // ============================================================
  // BRANDING
  // ============================================================

  Widget _buildBranding() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ======================================================
        // VERSIN
        // ======================================================
        Text(
          'VERSIN',
          style: TextStyle(
            color: activeColor,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
          ),
        ),

        // ======================================================
        // GENESIS
        // ======================================================
        const Text(
          'GENESIS',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 8,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}
