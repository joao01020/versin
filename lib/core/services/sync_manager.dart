import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/database_helper.dart';

class SyncManager {
  final _dbHelper = DatabaseHelper.instance;
  final _supabase = Supabase.instance.client;

  // 1. Salva localmente e tenta subir pro Supabase
  Future<void> saveAndSync(String word) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final db = await _dbHelper.database;
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    // Salva no SQLite primeiro (segurança offline)
    await db.insert('offline_rhymes', {
      'id': id,
      'word': word,
      'synced': 0, // 0 = Não sincronizado
    });

    // Tenta sincronizar imediatamente
    await pushToCloud();
  }

  // 2. Função que empurra os dados locais para a nuvem
  Future<void> pushToCloud() async {
    final List<ConnectivityResult> connectivityResults = await Connectivity().checkConnectivity();
    
    // Se a lista contiver apenas 'none', não há conexão
    if (connectivityResults.contains(ConnectivityResult.none)) return;

    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> unsynced = await db.query(
      'offline_rhymes',
      where: 'synced = ?',
      whereArgs: [0],
    );

    for (var item in unsynced) {
      try {
        final user = _supabase.auth.currentUser;
        if (user != null) {
          await _supabase.from('user_vocabulary').insert({
            'word': item['word'],
            'user_id': user.id,
          });

          // Se deu certo, marca como sincronizado no local
          await db.update(
            'offline_rhymes',
            {'synced': 1},
            where: 'id = ?',
            whereArgs: [item['id']],
          );
        }
      } catch (e) {
        print("Erro ao sincronizar item ${item['id']}: $e");
      }
    }
  }

  // 3. Monitor de conexão: Escuta quando a internet volta
  // Atualizado para aceitar List<ConnectivityResult> conforme a nova API
  void watchConnection() {
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      // Verifica se existe alguma conexão ativa que não seja 'none'
      if (results.any((result) => result != ConnectivityResult.none)) {
        print("Internet restaurada! Iniciando sincronização...");
        pushToCloud();
      }
    });
  }
}