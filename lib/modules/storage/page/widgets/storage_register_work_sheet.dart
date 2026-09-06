import 'dart:async';

import 'package:flutter/material.dart';

abstract final class StorageRegisterWorkSheet {
  static Future<void> show({
    required BuildContext context,
    required Color accentColor,
    required Color surfaceColor,
    required Future<void> Function() onRegisterLyrics,
    required Future<void> Function() onRegisterBeat,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Registrar obra',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Escolha o tipo de conteúdo.',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
                const SizedBox(height: 20),
                _RegisterOption(
                  icon: Icons.description_outlined,
                  title: 'Letra',
                  subtitle: 'Cole sua letra e gere SHA-256',
                  accentColor: accentColor,
                  onTap: () {
                    Navigator.of(sheetContext).pop();

                    unawaited(onRegisterLyrics());
                  },
                ),
                const SizedBox(height: 10),
                _RegisterOption(
                  icon: Icons.graphic_eq_rounded,
                  title: 'Beat',
                  subtitle: 'Selecione seu áudio e gere SHA-256',
                  accentColor: accentColor,
                  onTap: () {
                    Navigator.of(sheetContext).pop();

                    unawaited(onRegisterBeat());
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RegisterOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;

  const _RegisterOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.035),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            _IconBox(icon: icon, accentColor: accentColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white38, fontSize: 10),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white24,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color accentColor;

  const _IconBox({required this.icon, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accentColor.withValues(alpha: 0.15)),
      ),
      child: Icon(icon, color: accentColor, size: 20),
    );
  }
}
