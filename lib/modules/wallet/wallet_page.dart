import 'package:flutter/material.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  // CORES DO TEMA
  final Color accentNeon = const Color(0xFFE040FB);
  final Color primaryPurple = const Color(0xFF6A1B9A);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CARD DE SALDO PRINCIPAL
          _buildBalanceCard(),

          const SizedBox(height: 24),

          // BOTÕES DE AÇÃO RÁPIDA
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildQuickAction(Icons.account_balance_wallet, "Sacar"),
              _buildQuickAction(Icons.add_chart, "Royalties"),
              _buildQuickAction(Icons.history, "Extrato"),
            ],
          ),

          const SizedBox(height: 32),

          // SEÇÃO DE TRANSAÇÕES RECENTES
          const Text(
            "Atividade Recente",
            style: TextStyle(
              color: Colors.white, 
              fontSize: 18, 
              fontWeight: FontWeight.bold
            ),
          ),
          const SizedBox(height: 16),

          // LISTA DE TRANSAÇÕES - CORREÇÃO DO ÍCONE AQUI
          _buildTransactionItem(
            title: "Royalties: Single 'Versin Flow'",
            date: "15 Mai",
            amount: "+ R\$ 1.240,00",
            isPositive: true,
            icon: Icons.music_note,
          ),
          _buildTransactionItem(
            title: "Colab: Beatmaker X",
            date: "12 Mai",
            amount: "- R\$ 350,00",
            isPositive: false,
            icon: Icons.layers, // CORRIGIDO: de 'Layers' para 'layers'
          ),
          _buildTransactionItem(
            title: "Assinatura Versin Pro",
            date: "01 Mai",
            amount: "- R\$ 49,90",
            isPositive: false,
            icon: Icons.star_outline,
          ),
          
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryPurple, const Color(0xFF4A148C)],
        ),
        boxShadow: [
          BoxShadow(
            color: accentNeon.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Saldo Total",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Icon(Icons.visibility_outlined, color: Colors.white70, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "R\$ 4.850,32",
            style: TextStyle(
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
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.trending_up, color: Colors.greenAccent, size: 16),
                SizedBox(width: 8),
                Text(
                  "+12% este mês",
                  style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Icon(icon, color: accentNeon, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildTransactionItem({
    required String title,
    required String date,
    required String amount,
    required bool isPositive,
    required IconData icon,
  }) {
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
              color: accentNeon.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accentNeon, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  date,
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              color: isPositive ? Colors.greenAccent : Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}