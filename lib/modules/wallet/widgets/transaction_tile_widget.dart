import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:versin/modules/wallet/controllers/wallet_controller.dart';
import 'package:versin/modules/wallet/models/transaction_entity.dart';

class TransactionTileWidget extends StatelessWidget {
  final WalletController controller;
  final TransactionEntity transaction;

  const TransactionTileWidget({
    super.key,
    required this.controller,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dateFormat = DateFormat('dd MMM', 'pt_BR');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: controller.accentNeon.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(transaction.icon, color: controller.accentNeon, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  dateFormat.format(transaction.createdAt),
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            "${transaction.isPositive ? '+' : '-'} ${currencyFormat.format(transaction.amount.abs())}",
            style: TextStyle(
              color: transaction.isPositive ? Colors.greenAccent : Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}