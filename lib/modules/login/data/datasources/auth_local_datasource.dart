import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:versin/core/database/database_helper.dart';

abstract class AuthLocalDatasource {
  Future<void> saveLocalProfile({
    required String userId,
    required String username,
    required String wallet,
  });
}

class AuthLocalDatasourceImpl implements AuthLocalDatasource {
  @override
  Future<void> saveLocalProfile({
    required String userId,
    required String username,
    required String wallet,
  }) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.insert(
        'user_profile',
        {
          'id': userId,
          'name': username,
          'wallet': wallet.startsWith('wallet@') ? wallet : "wallet@$wallet",
          'synced': 1,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint("Versin-auth: Chassi gravado no SQLite.");
    } catch (e) {
      debugPrint("Versin-auth [Error]: Erro SQLite na Infra: $e");
      rethrow;
    }
  }
}