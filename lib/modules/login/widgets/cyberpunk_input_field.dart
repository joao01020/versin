import 'package:flutter/material.dart';

class CyberpunkInputField
    extends
        StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String label;
  final IconData icon;
  final Widget? suffixIcon;
  final bool isReadOnly;
  final Color? customTextColor;
  final Color accentNeon;
  final String? Function(
    String?,
  )?
  validator;

  const CyberpunkInputField({
    super.key,
    required this.controller,
    required this.hint,
    required this.label,
    required this.icon,
    this.suffixIcon,
    this.isReadOnly = false,
    this.customTextColor,
    required this.accentNeon,
    this.validator,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: 4,
            bottom: 6,
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          readOnly: isReadOnly,
          validator: validator,
          style: TextStyle(
            color:
                customTextColor ??
                Colors.white,
            fontSize: 14,
            fontFamily: isReadOnly
                ? 'monospace'
                : null,
            fontWeight: isReadOnly
                ? FontWeight.bold
                : FontWeight.normal,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: isReadOnly
                ? Colors.black.withValues(
                    alpha: 0.3,
                  )
                : Colors.white.withValues(
                    alpha: 0.02,
                  ),
            hintText: hint,
            hintStyle: const TextStyle(
              color: Colors.white12,
              fontSize: 13,
            ),
            prefixIcon: Icon(
              icon,
              color: isReadOnly
                  ? accentNeon.withValues(
                      alpha: 0.5,
                    )
                  : Colors.white30,
              size: 18,
            ),
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                14,
              ),
              borderSide: BorderSide(
                color: isReadOnly
                    ? accentNeon.withValues(
                        alpha: 0.15,
                      )
                    : Colors.white.withValues(
                        alpha: 0.05,
                      ),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                14,
              ),
              borderSide: BorderSide(
                color: accentNeon.withValues(
                  alpha: 0.4,
                ),
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                14,
              ),
              borderSide: const BorderSide(
                color: Colors.redAccent,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                14,
              ),
              borderSide: const BorderSide(
                color: Colors.redAccent,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
