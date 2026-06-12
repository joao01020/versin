import 'package:flutter/foundation.dart'; // Necessário para debugPrint
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/database_helper.dart';

class SyncManager {
  final _dbHelper = DatabaseHelper.instance;
  final _supabase = Supabase.instance.client;

  Future<
    void
  >
  saveAndSync(
    String word,
  ) async {
    final db = await _dbHelper.database;
    final id = DateTime.now().microsecondsSinceEpoch.toString();

    // Salva no SQLite primeiro
    await db.insert(
      'offline_rhymes',
      {
        'id': id,
        'word': word,
        'synced': 0,
      },
    );

    // Dispara sincronização em background
    pushToCloud().ignore();
  }

  Future<
    void
  >
  pushToCloud() async {
    final results = await Connectivity().checkConnectivity();

    // Corrigido para incluir blocos de chaves conforme solicitado pelo linter
    if (results.contains(
      ConnectivityResult.none,
    )) {
      return;
    }

    final user = _supabase.auth.currentUser;
    if (user ==
        null) {
      return;
    }

    final db = await _dbHelper.database;
    final unsynced = await db.query(
      'offline_rhymes',
      where: 'synced = 0',
    );

    for (var item in unsynced) {
      try {
        await _supabase
            .from(
              'user_vocabulary',
            )
            .insert(
              {
                'word': item['word'],
                'user_id': user.id,
              },
            );

        await db.update(
          'offline_rhymes',
          {
            'synced': 1,
          },
          where: 'id = ?',
          whereArgs: [
            item['id'],
          ],
        );
      } catch (
        e
      ) {
        debugPrint(
          "Falha na sincronização do item ${item['id']}: $e",
        );
      }
    }
  }

  void watchConnection() {
    Connectivity().onConnectivityChanged.listen(
      (
        List<
          ConnectivityResult
        >
        results,
      ) {
        if (results.any(
          (
            r,
          ) =>
              r !=
              ConnectivityResult.none,
        )) {
          pushToCloud();
        }
      },
    );
  }
}
