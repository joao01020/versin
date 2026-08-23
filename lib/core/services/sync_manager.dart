import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/database_helper.dart';

// ============================================================
// SYNC MANAGER
// ============================================================
//
// Responsável pela sincronização do cache SQLite com Supabase.
//
// DESKTOP / MOBILE:
// SQLite → Supabase.
//
// WEB:
// Não utiliza o SQLite desta implementação.
//
// ============================================================

class SyncManager {
  final _dbHelper = DatabaseHelper.instance;

  final _supabase = Supabase.instance.client;

  // ==========================================================
  // SUPORTE A BANCO LOCAL
  // ==========================================================

  bool get _supportsLocalDatabase {
    return !kIsWeb;
  }

  // ==========================================================
  // SALVAR E SINCRONIZAR
  // ==========================================================

  Future<void> saveAndSync(String word) async {
    // ========================================================
    // WEB
    // ========================================================

    if (!_supportsLocalDatabase) {
      await _saveDirectlyToCloud(word);

      return;
    }

    // ========================================================
    // SQLITE
    // ========================================================

    final db = await _dbHelper.database;

    final id = DateTime.now().microsecondsSinceEpoch.toString();

    await db.insert('offline_rhymes', {'id': id, 'word': word, 'synced': 0});

    pushToCloud().ignore();
  }

  // ==========================================================
  // SALVAR DIRETAMENTE NA NUVEM
  // ==========================================================

  Future<void> _saveDirectlyToCloud(String word) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      return;
    }

    try {
      await _supabase.from('user_vocabulary').insert({
        'word': word,
        'user_id': user.id,
      });
    } catch (error) {
      debugPrint(
        '[SYNC] '
        'Falha ao salvar diretamente '
        'na nuvem: $error',
      );

      rethrow;
    }
  }

  // ==========================================================
  // PUSH PARA NUVEM
  // ==========================================================

  Future<void> pushToCloud() async {
    // Web não possui fila SQLite nesta implementação.
    if (!_supportsLocalDatabase) {
      return;
    }

    final results = await Connectivity().checkConnectivity();

    if (results.contains(ConnectivityResult.none)) {
      return;
    }

    final user = _supabase.auth.currentUser;

    if (user == null) {
      return;
    }

    final db = await _dbHelper.database;

    final unsynced = await db.query('offline_rhymes', where: 'synced = 0');

    for (final item in unsynced) {
      try {
        await _supabase.from('user_vocabulary').insert({
          'word': item['word'],
          'user_id': user.id,
        });

        await db.update(
          'offline_rhymes',
          {'synced': 1},
          where: 'id = ?',
          whereArgs: [item['id']],
        );
      } catch (error) {
        debugPrint(
          '[SYNC] '
          'Falha na sincronização '
          'do item ${item['id']}: '
          '$error',
        );
      }
    }
  }

  // ==========================================================
  // OBSERVAR CONEXÃO
  // ==========================================================

  void watchConnection() {
    // Não existe fila SQLite para sincronizar no Web.
    if (!_supportsLocalDatabase) {
      debugPrint(
        '[SYNC] '
        'Monitor de SQLite desativado no Web.',
      );

      return;
    }

    Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      if (results.any((result) => result != ConnectivityResult.none)) {
        pushToCloud();
      }
    });
  }
}
