import 'package:flutter/material.dart';

import '../../controllers/withdraw_controller.dart';

// ============================================================
// WITHDRAW AMOUNT FIELD
// ============================================================
//
// Campo responsável exclusivamente pela entrada do valor
// solicitado para saque.
//
// Responsabilidades:
//
// - exibir campo monetário;
// - atualizar WithdrawController;
// - permitir usar o saldo total;
// - exibir erro de validação.
//
// Não executa o saque.
//
// ============================================================

class WithdrawAmountField
    extends
        StatelessWidget {
  // ============================================================
  // CONTROLLER
  // ============================================================

  final WithdrawController controller;

  // ============================================================
  // TEXT CONTROLLER
  // ============================================================

  final TextEditingController textController;

  // ============================================================
  // FOCUS
  // ============================================================

  final FocusNode? focusNode;

  // ============================================================
  // CORES
  // ============================================================

  final Color accentColor;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  const WithdrawAmountField({
    super.key,
    required this.controller,
    required this.textController,
    this.focusNode,
    this.accentColor = const Color(
      0xFF00E676,
    ),
  });

  // ============================================================
  // USAR SALDO TOTAL
  // ============================================================

  void _useFullBalance() {
    controller.useFullBalance();

    final value = controller.amount
        .toStringAsFixed(
          2,
        )
        .replaceAll(
          '.',
          ',',
        );

    textController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(
        offset: value.length,
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        // ======================================================
        // LABEL
        // ======================================================
        const Text(
          'VALOR DO SAQUE',

          style: TextStyle(
            color: Colors.white54,

            fontSize: 10,

            fontWeight: FontWeight.w700,

            letterSpacing: 1,
          ),
        ),

        const SizedBox(
          height: 9,
        ),

        // ======================================================
        // CAMPO
        // ======================================================
        TextField(
          controller: textController,

          focusNode: focusNode,

          enabled: !controller.isSubmitting,

          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
          ),

          textInputAction: TextInputAction.done,

          onChanged: controller.setAmountFromText,

          cursorColor: accentColor,

          style: const TextStyle(
            color: Colors.white,

            fontSize: 22,

            fontWeight: FontWeight.w700,
          ),

          decoration: InputDecoration(
            prefixText: 'R\$ ',

            prefixStyle: TextStyle(
              color: accentColor,

              fontSize: 22,

              fontWeight: FontWeight.w700,
            ),

            hintText: '0,00',

            hintStyle: const TextStyle(
              color: Colors.white24,
            ),

            filled: true,

            fillColor: Colors.black.withValues(
              alpha: 0.18,
            ),

            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 17,
            ),

            border: _inputBorder(
              Colors.white.withValues(
                alpha: 0.08,
              ),
            ),

            enabledBorder: _inputBorder(
              Colors.white.withValues(
                alpha: 0.08,
              ),
            ),

            disabledBorder: _inputBorder(
              Colors.white.withValues(
                alpha: 0.04,
              ),
            ),

            focusedBorder: _inputBorder(
              accentColor,
            ),

            errorBorder: _inputBorder(
              Colors.redAccent,
            ),
          ),
        ),

        // ======================================================
        // USAR SALDO TOTAL
        // ======================================================
        Align(
          alignment: Alignment.centerRight,

          child: TextButton(
            onPressed: controller.isSubmitting
                ? null
                : _useFullBalance,

            child: Text(
              'USAR SALDO TOTAL',

              style: TextStyle(
                color: accentColor,

                fontSize: 9,

                fontWeight: FontWeight.bold,

                letterSpacing: 0.4,
              ),
            ),
          ),
        ),

        // ======================================================
        // ERRO
        // ======================================================
        if (controller.hasError)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              const Icon(
                Icons.error_outline_rounded,

                color: Colors.redAccent,

                size: 16,
              ),

              const SizedBox(
                width: 7,
              ),

              Expanded(
                child: Text(
                  controller.errorMessage ??
                      'Valor inválido.',

                  style: const TextStyle(
                    color: Colors.redAccent,

                    fontSize: 10,

                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  // ============================================================
  // BORDA
  // ============================================================

  OutlineInputBorder _inputBorder(
    Color color,
  ) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(
        14,
      ),

      borderSide: BorderSide(
        color: color,
      ),
    );
  }
}
