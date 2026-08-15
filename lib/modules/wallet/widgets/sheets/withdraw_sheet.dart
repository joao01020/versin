import 'package:flutter/material.dart';

import '../../controllers/withdraw_controller.dart';
import 'wallet_bottom_sheet.dart';

// ============================================================
// WITHDRAW SHEET
// ============================================================
//
// Painel de saque.
//
// Responsável somente pela interface.
//
// Estado:
//
// WithdrawController.
//
// ============================================================

class WithdrawSheet
    extends
        StatefulWidget {
  // ============================================================
  // CONTROLLER
  // ============================================================

  final WithdrawController controller;

  // ============================================================
  // CALLBACK
  // ============================================================

  final Future<
    void
  >
  Function(
    double amount,
  )?
  onSubmit;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  const WithdrawSheet({
    super.key,
    required this.controller,
    this.onSubmit,
  });

  // ============================================================
  // CORES
  // ============================================================

  static const Color green = Color(
    0xFF00E676,
  );

  static const Color purple = Color(
    0xFF9D6CFF,
  );

  // ============================================================
  // ABRIR
  // ============================================================

  static Future<
    bool?
  >
  show({
    required BuildContext context,
    required WithdrawController controller,
    required double availableBalance,
    Future<
      void
    >
    Function(
      double amount,
    )?
    onSubmit,
  }) {
    controller.reset(
      availableBalance: availableBalance,
    );

    return WalletBottomSheet.show<
      bool
    >(
      context: context,

      title: 'SACAR',

      subtitle: 'Solicite a retirada do seu saldo disponível',

      icon: Icons.account_balance_wallet_outlined,

      accentColor: green,

      heightFactor: 0.82,

      child: WithdrawSheet(
        controller: controller,

        onSubmit: onSubmit,
      ),
    );
  }

  @override
  State<
    WithdrawSheet
  >
  createState() => _WithdrawSheetState();
}

// ============================================================
// STATE
// ============================================================

class _WithdrawSheetState
    extends
        State<
          WithdrawSheet
        > {
  // ============================================================
  // TEXT CONTROLLER
  // ============================================================

  late final TextEditingController _amountController;

  // ============================================================
  // FOCUS
  // ============================================================

  late final FocusNode _amountFocusNode;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _amountController = TextEditingController();

    _amountFocusNode = FocusNode();

    widget.controller.addListener(
      _onControllerChanged,
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    widget.controller.removeListener(
      _onControllerChanged,
    );

    _amountController.dispose();

    _amountFocusNode.dispose();

    super.dispose();
  }

  // ============================================================
  // CONTROLLER ALTERADO
  // ============================================================

  void _onControllerChanged() {
    if (!mounted) {
      return;
    }

    setState(
      () {},
    );
  }

  // ============================================================
  // USAR SALDO TOTAL
  // ============================================================

  void _useFullBalance() {
    widget.controller.useFullBalance();

    final amount = widget.controller.amount;

    _amountController.text = amount.toStringAsFixed(
      2,
    );

    _amountController.selection = TextSelection.collapsed(
      offset: _amountController.text.length,
    );
  }

  // ============================================================
  // ENVIAR
  // ============================================================

  Future<
    void
  >
  _submit() async {
    _amountFocusNode.unfocus();

    final success = await widget.controller.submit(
      onSubmit: widget.onSubmit,
    );

    if (!mounted ||
        !success) {
      return;
    }

    Navigator.of(
      context,
    ).pop(
      true,
    );
  }

  // ============================================================
  // FORMATAR DINHEIRO
  // ============================================================

  String _formatMoney(
    double value,
  ) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final controller = widget.controller;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),

      padding: EdgeInsets.fromLTRB(
        22,
        20,
        22,
        24 +
            MediaQuery.viewInsetsOf(
              context,
            ).bottom,
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          // ======================================================
          // SALDO DISPONÍVEL
          // ======================================================
          Container(
            width: double.infinity,

            padding: const EdgeInsets.all(
              18,
            ),

            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,

                end: Alignment.bottomRight,

                colors: [
                  WithdrawSheet.green.withValues(
                    alpha: 0.11,
                  ),

                  WithdrawSheet.purple.withValues(
                    alpha: 0.06,
                  ),
                ],
              ),

              borderRadius: BorderRadius.circular(
                16,
              ),

              border: Border.all(
                color: WithdrawSheet.green.withValues(
                  alpha: 0.15,
                ),
              ),
            ),

            child: Row(
              children: [
                Container(
                  width: 44,

                  height: 44,

                  decoration: BoxDecoration(
                    color: WithdrawSheet.green.withValues(
                      alpha: 0.08,
                    ),

                    borderRadius: BorderRadius.circular(
                      12,
                    ),
                  ),

                  child: const Icon(
                    Icons.savings_outlined,

                    color: WithdrawSheet.green,

                    size: 22,
                  ),
                ),

                const SizedBox(
                  width: 14,
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      const Text(
                        'SALDO DISPONÍVEL',

                        style: TextStyle(
                          color: Colors.white38,

                          fontSize: 9,

                          fontWeight: FontWeight.w700,

                          letterSpacing: 0.8,
                        ),
                      ),

                      const SizedBox(
                        height: 4,
                      ),

                      Text(
                        _formatMoney(
                          controller.availableBalance,
                        ),

                        style: const TextStyle(
                          color: Colors.white,

                          fontSize: 22,

                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 24,
          ),

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
            controller: _amountController,

            focusNode: _amountFocusNode,

            enabled: !controller.isSubmitting,

            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),

            onChanged: controller.setAmountFromText,

            cursorColor: WithdrawSheet.green,

            style: const TextStyle(
              color: Colors.white,

              fontSize: 22,

              fontWeight: FontWeight.w700,
            ),

            decoration: InputDecoration(
              prefixText: 'R\$ ',

              prefixStyle: const TextStyle(
                color: WithdrawSheet.green,

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

              focusedBorder: _inputBorder(
                WithdrawSheet.green,
              ),

              errorBorder: _inputBorder(
                Colors.redAccent,
              ),
            ),
          ),

          // ======================================================
          // USAR TUDO
          // ======================================================
          Align(
            alignment: Alignment.centerRight,

            child: TextButton(
              onPressed: controller.isSubmitting
                  ? null
                  : _useFullBalance,

              child: const Text(
                'USAR SALDO TOTAL',

                style: TextStyle(
                  color: WithdrawSheet.green,

                  fontSize: 9,

                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // ======================================================
          // ERRO
          // ======================================================
          if (controller.hasError) ...[
            const SizedBox(
              height: 4,
            ),

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

          const SizedBox(
            height: 18,
          ),

          // ======================================================
          // INFORMAÇÃO
          // ======================================================
          Container(
            width: double.infinity,

            padding: const EdgeInsets.all(
              14,
            ),

            decoration: BoxDecoration(
              color: WithdrawSheet.purple.withValues(
                alpha: 0.06,
              ),

              borderRadius: BorderRadius.circular(
                13,
              ),

              border: Border.all(
                color: WithdrawSheet.purple.withValues(
                  alpha: 0.13,
                ),
              ),
            ),

            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Icon(
                  Icons.info_outline_rounded,

                  color: WithdrawSheet.purple,

                  size: 18,
                ),

                SizedBox(
                  width: 10,
                ),

                Expanded(
                  child: Text(
                    'Antes da retirada ser concluída, você poderá revisar o valor e os dados de recebimento.',

                    style: TextStyle(
                      color: Colors.white54,

                      fontSize: 11,

                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 26,
          ),

          // ======================================================
          // CONTINUAR
          // ======================================================
          SizedBox(
            width: double.infinity,

            height: 48,

            child: FilledButton(
              onPressed: controller.isSubmitting
                  ? null
                  : _submit,

              style: FilledButton.styleFrom(
                backgroundColor: WithdrawSheet.green,

                foregroundColor: Colors.black,

                disabledBackgroundColor: WithdrawSheet.green.withValues(
                  alpha: 0.20,
                ),

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    13,
                  ),
                ),
              ),

              child: controller.isSubmitting
                  ? const SizedBox(
                      width: 19,

                      height: 19,

                      child: CircularProgressIndicator(
                        strokeWidth: 2,

                        color: Colors.black,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,

                      children: [
                        Text(
                          'CONTINUAR',

                          style: TextStyle(
                            fontSize: 11,

                            fontWeight: FontWeight.bold,

                            letterSpacing: 0.8,
                          ),
                        ),

                        SizedBox(
                          width: 7,
                        ),

                        Icon(
                          Icons.arrow_forward_rounded,

                          size: 17,
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
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
