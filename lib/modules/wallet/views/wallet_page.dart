import 'package:flutter/material.dart';

import 'package:versin/app/locator.dart';
import 'package:versin/app/routes/app_routes.dart';

import 'package:versin/modules/wallet/controllers/wallet_controller.dart';
import 'package:versin/modules/wallet/controllers/withdraw_controller.dart';

import 'package:versin/modules/wallet/models/transaction_entity.dart';

import 'package:versin/modules/wallet/views/royalties_page.dart';

import 'package:versin/modules/wallet/widgets/balance_card_widget.dart';
import 'package:versin/modules/wallet/widgets/quick_action_button_widget.dart';
import 'package:versin/modules/wallet/widgets/transaction_tile_widget.dart';

import 'package:versin/modules/wallet/widgets/sheets/statement_sheet.dart';
import 'package:versin/modules/wallet/widgets/sheets/withdraw_sheet.dart';

// ============================================================
// WALLET PAGE
// ============================================================
//
// Página principal da carteira.
//
// Responsabilidades:
//
// - exibir saldo;
// - exibir ações rápidas;
// - exibir atividade recente;
// - abrir saque;
// - abrir extrato;
// - abrir royalties.
//
// Regras de saque ficam em:
//
// WithdrawController.
//
// Interface do saque:
//
// WithdrawSheet.
//
// Interface do extrato:
//
// StatementSheet.
//
// ============================================================

class WalletPage
    extends
        StatefulWidget {
  // ============================================================
  // ROTA
  // ============================================================

  static const String routeName = AppRoutes.wallet;

  // ============================================================
  // CONSTRUTOR
  // ============================================================

  const WalletPage({
    super.key,
  });

  @override
  State<
    WalletPage
  >
  createState() => _WalletPageState();
}

// ============================================================
// STATE
// ============================================================

class _WalletPageState
    extends
        State<
          WalletPage
        > {
  // ============================================================
  // CORES
  // ============================================================

  static const Color _backgroundColor = Color(
    0xFF0D0B1F,
  );

  static const Color _purple = Color(
    0xFF9D6CFF,
  );

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final WalletController _walletController =
      sl<
        WalletController
      >();

  final WithdrawController _withdrawController = WithdrawController();

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _walletController.addListener(
      _onWalletControllerUpdate,
    );

    // ==========================================================
    // FALLBACK DE LOADING
    // ==========================================================
    //
    // Mantém o comportamento que você já tinha:
    //
    // se o controller continuar em loading por muito tempo,
    // força o estado vazio.
    //
    // ==========================================================

    Future.delayed(
      const Duration(
        milliseconds: 1500,
      ),
      () {
        if (!mounted) {
          return;
        }

        if (_walletController.isLoading) {
          _walletController.setEmptyState();
        }
      },
    );
  }

  // ============================================================
  // WALLET UPDATE
  // ============================================================

  void _onWalletControllerUpdate() {
    if (!mounted) {
      return;
    }

    setState(
      () {},
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _walletController.removeListener(
      _onWalletControllerUpdate,
    );

    _withdrawController.dispose();

    super.dispose();
  }

  // ============================================================
  // ABRIR SAQUE
  // ============================================================

  Future<
    void
  >
  _openWithdraw() async {
    // ==========================================================
    // SALDO DISPONÍVEL
    // ==========================================================
    //
    // IMPORTANTE:
    //
    // Aqui estamos usando totalBalance como saldo disponível.
    //
    // Se o seu WalletController usar outro getter, como:
    //
    // availableBalance
    //
    // basta trocar abaixo.
    //
    // ==========================================================

    final availableBalance = _walletController.totalBalance;

    final success = await WithdrawSheet.show(
      context: context,

      controller: _withdrawController,

      availableBalance: availableBalance,

      // ========================================================
      // BACKEND FUTURO
      // ========================================================
      //
      // Quando o WithdrawService estiver pronto:
      //
      // onSubmit: (amount) async {
      //   await withdrawService.requestWithdraw(
      //     amount: amount,
      //   );
      // },
      //
      // ========================================================
      onSubmit:
          (
            amount,
          ) async {
            debugPrint(
              '[WALLET PAGE] '
              'Solicitação de saque: R\$ $amount',
            );
          },
    );

    if (!mounted ||
        success !=
            true) {
      return;
    }

    _showMessage(
      'Solicitação de saque preparada.',
    );
  }

  // ============================================================
  // ABRIR EXTRATO
  // ============================================================

  Future<
    void
  >
  _openStatement() async {
    await StatementSheet.show(
      context: context,

      controller: _walletController,
    );
  }

  // ============================================================
  // ABRIR ROYALTIES
  // ============================================================

  Future<
    void
  >
  _openRoyalties() async {
    await Navigator.of(
      context,
    ).push(
      MaterialPageRoute<
        void
      >(
        builder:
            (
              context,
            ) {
              return const RoyaltiesPage();
            },
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
    return Scaffold(
      backgroundColor: _backgroundColor,

      body: _walletController.isLoading
          ? _buildLoading()
          : _buildContent(),
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,

        children: [
          CircularProgressIndicator(
            color: _purple,

            strokeWidth: 2,
          ),

          SizedBox(
            height: 12,
          ),

          Text(
            'Carregando carteira...',

            style: TextStyle(
              color: Colors.white38,

              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CONTEÚDO
  // ============================================================

  Widget _buildContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),

      padding: const EdgeInsets.symmetric(
        horizontal: 20,

        vertical: 20,
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          // ======================================================
          // SALDO
          // ======================================================
          BalanceCardWidget(
            controller: _walletController,
          ),

          const SizedBox(
            height: 24,
          ),

          // ======================================================
          // AÇÕES RÁPIDAS
          // ======================================================
          _buildQuickActions(),

          const SizedBox(
            height: 32,
          ),

          // ======================================================
          // ATIVIDADE RECENTE
          // ======================================================
          _buildRecentActivity(),

          const SizedBox(
            height: 30,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // AÇÕES RÁPIDAS
  // ============================================================

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,

      children: [
        // ======================================================
        // SACAR
        // ======================================================
        QuickActionButtonWidget(
          controller: _walletController,

          icon: Icons.account_balance_wallet,

          label: 'Sacar',

          onTap: _openWithdraw,
        ),

        // ======================================================
        // ROYALTIES
        // ======================================================
        QuickActionButtonWidget(
          controller: _walletController,

          icon: Icons.add_chart,

          label: 'Royalties',

          onTap: _openRoyalties,
        ),

        // ======================================================
        // EXTRATO
        // ======================================================
        QuickActionButtonWidget(
          controller: _walletController,

          icon: Icons.history,

          label: 'Extrato',

          onTap: _openStatement,
        ),
      ],
    );
  }

  // ============================================================
  // ATIVIDADE RECENTE
  // ============================================================

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        // ======================================================
        // HEADER
        // ======================================================
        Row(
          children: [
            const Expanded(
              child: Text(
                'Atividade Recente',

                style: TextStyle(
                  color: Colors.white,

                  fontSize: 18,

                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            if (_walletController.transactions.isNotEmpty)
              TextButton(
                onPressed: _openStatement,

                child: const Text(
                  'VER EXTRATO',

                  style: TextStyle(
                    color: _purple,

                    fontSize: 9,

                    fontWeight: FontWeight.bold,

                    letterSpacing: 0.6,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(
          height: 16,
        ),

        // ======================================================
        // TRANSAÇÕES
        // ======================================================
        if (_walletController.transactions.isNotEmpty) _buildTransactionList() else _buildEmptyTransactions(),
      ],
    );
  }

  // ============================================================
  // LISTA DE TRANSAÇÕES
  // ============================================================

  Widget _buildTransactionList() {
    return Column(
      children: _walletController.transactions.map(
        (
          tx,
        ) {
          final TransactionEntity transaction = tx;

          return Padding(
            padding: const EdgeInsets.only(
              bottom: 8,
            ),

            child: TransactionTileWidget(
              controller: _walletController,

              transaction: transaction,
            ),
          );
        },
      ).toList(),
    );
  }

  // ============================================================
  // SEM TRANSAÇÕES
  // ============================================================

  Widget _buildEmptyTransactions() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.symmetric(
        vertical: 40,

        horizontal: 20,
      ),

      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.01,
        ),

        borderRadius: BorderRadius.circular(
          16,
        ),

        border: Border.all(
          color: Colors.white10,
        ),
      ),

      child: const Column(
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,

            color: Colors.white24,

            size: 36,
          ),

          SizedBox(
            height: 12,
          ),

          Text(
            'Nenhuma movimentação financeira encontrada.',

            textAlign: TextAlign.center,

            style: TextStyle(
              color: Colors.white38,

              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MENSAGEM
  // ============================================================

  void _showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
        context,
      )
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
          ),

          backgroundColor: const Color(
            0xFF1B1730,
          ),

          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}
