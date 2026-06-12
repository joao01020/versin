import 'package:flutter/material.dart';
import 'package:versin/app/locator.dart';
import 'package:versin/app/routes/app_routes.dart';

// Importações de controle e entidades
import 'package:versin/modules/wallet/controllers/wallet_controller.dart';
import 'package:versin/modules/wallet/models/transaction_entity.dart'; // Usado para tipagem explícita

// Widgets
import 'package:versin/modules/wallet/widgets/balance_card_widget.dart';
import 'package:versin/modules/wallet/widgets/quick_action_button_widget.dart';
import 'package:versin/modules/wallet/widgets/transaction_tile_widget.dart';

// Importação direta da página de Royalties
import 'package:versin/modules/wallet/views/royalties_page.dart';

class WalletPage
    extends
        StatefulWidget {
  static const String routeName = AppRoutes.wallet;

  const WalletPage({
    super.key,
  });

  @override
  State<
    WalletPage
  >
  createState() => _WalletPageState();
}

class _WalletPageState
    extends
        State<
          WalletPage
        > {
  final WalletController _walletController =
      sl<
        WalletController
      >();

  @override
  void initState() {
    super.initState();
    _walletController.addListener(
      _onControllerUpdate,
    );

    Future.delayed(
      const Duration(
        milliseconds: 1500,
      ),
      () {
        if (mounted &&
            _walletController.isLoading) {
          _walletController.setEmptyState();
        }
      },
    );
  }

  void _onControllerUpdate() {
    if (mounted)
      setState(
        () {},
      );
  }

  @override
  void dispose() {
    _walletController.removeListener(
      _onControllerUpdate,
    );
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: const Color(
        0xFF0D0B1F,
      ),
      body: _walletController.isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.purple,
              ),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BalanceCardWidget(
                    controller: _walletController,
                  ),

                  const SizedBox(
                    height: 24,
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      QuickActionButtonWidget(
                        controller: _walletController,
                        icon: Icons.account_balance_wallet,
                        label: "Sacar",
                        onTap: () {},
                      ),
                      QuickActionButtonWidget(
                        controller: _walletController,
                        icon: Icons.add_chart,
                        label: "Royalties",
                        onTap: () {
                          // Aqui agora você pode usar a classe RoyaltiesPage explicitamente se quiser
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (
                                    context,
                                  ) => const RoyaltiesPage(),
                            ),
                          );
                        },
                      ),
                      QuickActionButtonWidget(
                        controller: _walletController,
                        icon: Icons.history,
                        label: "Extrato",
                        onTap: () {},
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 32,
                  ),

                  const Text(
                    "Atividade Recente",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(
                    height: 16,
                  ),

                  if (_walletController.transactions.isNotEmpty)
                    Column(
                      children: _walletController.transactions.map(
                        (
                          tx,
                        ) {
                          // Aqui usamos explicitamente a tipagem TransactionEntity importada
                          final TransactionEntity transaction = tx;
                          return TransactionTileWidget(
                            controller: _walletController,
                            transaction: transaction,
                          );
                        },
                      ).toList(),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 40,
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
                            "Nenhuma movimentação financeira encontrada.",
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(
                    height: 30,
                  ),
                ],
              ),
            ),
    );
  }
}
