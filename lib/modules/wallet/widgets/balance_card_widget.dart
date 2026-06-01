import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:versin/modules/wallet/controllers/wallet_controller.dart';

class BalanceCardWidget extends StatelessWidget {
  final WalletController controller;

  const BalanceCardWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [controller.primaryPurple, const Color(0xFF4A148C)],
        ),
        boxShadow: [
          BoxShadow(
            color: controller.accentNeon.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Saldo Total", style: TextStyle(color: Colors.white70, fontSize: 14)),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  controller.isBalanceVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: Colors.white70,
                  size: 20,
                ),
                onPressed: () => controller.toggleBalanceVisibility(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            controller.isBalanceVisible 
                ? currencyFormat.format(controller.totalBalance)
                : "R\$ ••••••",
            style: const TextStyle(
              color: Colors.white, 
              fontSize: 32, 
              fontWeight: FontWeight.bold, 
              letterSpacing: 1
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.trending_up, color: Colors.greenAccent, size: 16),
                const SizedBox(width: 8),
                Text(
                  "${controller.monthlyGrowthPercentage} este mês",
                  style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}