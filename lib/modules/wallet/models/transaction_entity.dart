import 'package:flutter/material.dart';

// EN: Data entity representing structured financial transactions from ledger
// PT: Entidade de dados representando transações financeiras estruturadas da ledger
class TransactionEntity {
  final String id;
  final String title;
  final DateTime createdAt;
  final double amount;
  final bool isPositive;
  final IconData icon;

  const TransactionEntity({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.amount,
    required this.isPositive,
    required this.icon,
  });
}